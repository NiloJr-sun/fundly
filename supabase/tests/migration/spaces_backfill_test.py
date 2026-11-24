"""Shared spaces C1.1 backfill check: migrating a database that already holds
data changes no existing value, including revisions (docs/SHARED_SPACES_C1_PLAN.md).

Run from the repository root against the LOCAL stack only:

    python3 supabase/tests/migration/spaces_backfill_test.py

It RESETS the local database to the migration before C1.1, writes data through
the current write API (several users, edits, a delete, receipts), snapshots
every row, applies the remaining migrations, and compares. The local database
is then reset (empty, fully migrated).

C1.3 rehearsal on a copy of production (set FUNDLY_MIGRATION_DB_CONTAINER):
  --snapshot FILE      before migrating: write every row and what each user
                       can read to FILE (private data: keep it outside the
                       repository and delete it afterwards)
  --verify-only FILE   after migrating: check the copy against FILE
"""

import json
import os
import subprocess
import sys
import uuid

CONTAINER = os.environ.get('FUNDLY_MIGRATION_DB_CONTAINER', 'supabase_db_fundly-schema-dev')
BEFORE_C1 = '20261123020000'
SUPABASE = ['npx', '--yes', 'supabase@3.2.0']
NEW_COLUMNS = ['space_id', 'created_by', 'updated_by']

# Table → ordering key. Record tables gain space_id, created_by, updated_by;
# backend tables gain space_id.
TABLES = {
    'custom_account_types': 'id',
    'accounts': 'id',
    'categories': 'id',
    'transactions': 'id',
    'monthly_plans': 'id',
    'fundly_deleted_records': 'entity, id',
    'fundly_write_receipts': 'owner_id, batch_id',
    'fundly_import_receipts': 'owner_id, import_id',
}
RECORD_TABLES = list(TABLES)[:5]


def execute(sql):
    result = subprocess.run(['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres',
                             '-v', 'ON_ERROR_STOP=1', '-qtA'],
                            input=sql, capture_output=True, text=True, timeout=120)
    if result.returncode:
        raise AssertionError(result.stderr)
    return result.stdout.strip()


def literal(value):
    return "'" + str(value).replace("'", "''") + "'"


def supabase(*args):
    result = subprocess.run(SUPABASE + list(args), capture_output=True, text=True, timeout=600)
    if result.returncode:
        raise AssertionError(result.stdout + result.stderr)


def apply(actor, *items):
    envelope = json.dumps({'version': 1, 'items': list(items)})
    execute(f"BEGIN; SET LOCAL ROLE authenticated; "
            f"SELECT set_config('request.jwt.claims', {literal(json.dumps({'sub': actor, 'role': 'authenticated'}))}, true); "
            f"SELECT public.fundly_apply_operations({literal(uuid.uuid4())}::uuid, {literal(envelope)}::jsonb); COMMIT;")


def seed():
    a, b, c = (str(uuid.uuid4()) for _ in range(3))
    execute(f"INSERT INTO auth.users(id, email) VALUES ({literal(a)}, 'c1-backfill-a@example.invalid'), "
            f"({literal(b)}, 'c1-backfill-b@example.invalid'), ({literal(c)}, 'c1-backfill-c@example.invalid');")
    ids = {name: str(uuid.uuid4()) for name in
           ['init_a', 'init_b', 'type', 'cash', 'card', 'spend', 'pay', 'gone', 'plan', 'b_cash', 'b_in']}
    apply(a, {'operation': 'dataset.initialize', 'id': ids['init_a']})
    apply(a,
          {'operation': 'custom_type.create', 'id': ids['type'],
           'data': {'name': 'E-wallet', 'base_type': 'savingsCash'}},
          {'operation': 'account.create', 'id': ids['cash'],
           'data': {'name': 'Cash', 'type': 'savingsCash', 'entered_opening_amount_minor': '50000',
                    'custom_type_id': ids['type']}},
          {'operation': 'account.create', 'id': ids['card'],
           'data': {'name': 'Card', 'type': 'credit', 'entered_opening_amount_minor': '2000'}})
    food = execute(f"SELECT id FROM public.categories WHERE owner_id = {literal(a)} AND kind = 'spending' "
                   f"AND linked_account_id IS NULL ORDER BY name LIMIT 1;")
    apply(a,
          {'operation': 'transaction.create', 'id': ids['spend'],
           'data': {'type': 'spending', 'amount_minor': '1250', 'date': '2026-11-20', 'payee': 'Market',
                    'source_account_id': ids['cash'], 'category_id': food}},
          {'operation': 'transaction.create', 'id': ids['pay'],
           'data': {'type': 'creditCardPayment', 'amount_minor': '1000', 'date': '2026-11-21', 'payee': '',
                    'source_account_id': ids['cash'], 'destination_account_id': ids['card']}},
          {'operation': 'transaction.create', 'id': ids['gone'],
           'data': {'type': 'spending', 'amount_minor': '300', 'date': '2026-11-22', 'payee': 'Mistake',
                    'source_account_id': ids['cash'], 'category_id': food}},
          {'operation': 'plan.save', 'id': ids['plan'],
           'data': {'category_id': food, 'month': '2026-11', 'target_amount_minor': '5000',
                    'assigned_amount_minor': '4000', 'previous': None}})
    # Revisions above 1, and a tombstone.
    apply(a, {'operation': 'transaction.update', 'id': ids['spend'], 'expected_revision': '1',
              'data': {'payee': 'Market (edited)'}})
    apply(a, {'operation': 'transaction.update', 'id': ids['spend'], 'expected_revision': '2',
              'data': {'note': 'Second edit'}})
    apply(a, {'operation': 'transaction.delete', 'id': ids['gone'], 'expected_revision': '1'})
    apply(b, {'operation': 'dataset.initialize', 'id': ids['init_b']})
    apply(b, {'operation': 'account.create', 'id': ids['b_cash'],
              'data': {'name': 'Cash', 'type': 'savingsCash', 'entered_opening_amount_minor': '0'}})
    execute(f"INSERT INTO public.fundly_import_receipts(owner_id, import_id, request_fingerprint, mode, result) "
            f"VALUES ({literal(b)}, {literal(uuid.uuid4())}, decode(repeat('ab', 32), 'hex'), 'into_empty', '{{}}');")
    # User c has no records at all.
    return a, b, c


def snapshot(strip_new):
    rows = {}
    for table, key in TABLES.items():
        value = "to_jsonb(t)" + ''.join(f" - '{column}'" for column in NEW_COLUMNS) if strip_new else "to_jsonb(t)"
        rows[table] = json.loads(execute(
            f"SELECT coalesce(jsonb_agg({value} ORDER BY {key}), '[]') FROM public.{table} t;"))
    rows['auth.users'] = json.loads(execute("SELECT coalesce(jsonb_agg(id ORDER BY id), '[]') FROM auth.users;"))
    rows['visible'] = visible(rows['auth.users'])
    return rows


def visible(users):
    """Rows each user can read through the read rules, per record table."""
    counts = {}
    for user in users:
        claims = json.dumps({'sub': user, 'role': 'authenticated'})
        query = ' UNION ALL '.join(f"SELECT '{table}', count(*) FROM public.{table}" for table in RECORD_TABLES)
        output = execute(f"BEGIN; SET LOCAL ROLE authenticated; "
                         f"SELECT set_config('request.jwt.claims', {literal(claims)}, true) \\g /dev/null\n"
                         f"{query}; ROLLBACK;")
        counts[user] = dict(line.split('|') for line in output.splitlines() if '|' in line)
    return counts


def verify(before):
    after = snapshot(strip_new=True)
    for table in TABLES:
        assert after[table] == before[table], f'{table}: existing values changed'
        print(f'PASS: {table}: {len(before[table])} rows, every existing value identical (revisions included)')
    if 'visible' in before:
        assert after['visible'] == before['visible'], 'what users can read changed'
        print(f'PASS: each of {len(before["visible"])} users reads exactly the same rows as before')
    for table in RECORD_TABLES:
        mismatched = execute(f"SELECT count(*) FROM public.{table} WHERE space_id <> owner_id "
                             f"OR created_by <> owner_id OR updated_by <> owner_id;")
        assert mismatched == '0', f'{table}: {mismatched} rows with a different space or writer'
    for table in ['fundly_deleted_records', 'fundly_write_receipts', 'fundly_import_receipts']:
        assert execute(f"SELECT count(*) FROM public.{table} WHERE space_id <> owner_id;") == '0', table
    print('PASS: every record and backend row is in its owner\'s space, created and last changed by its owner')
    users = before['auth.users']
    personal = json.loads(execute(
        "SELECT coalesce(jsonb_agg(s.id ORDER BY s.id), '[]') FROM public.spaces s "
        "JOIN public.space_members m ON m.space_id = s.id AND m.user_id = s.id AND m.role = 'owner' "
        "WHERE s.personal_of = s.id AND s.created_by = s.id AND s.name = 'Personal';"))
    assert personal == users, 'not exactly one Personal space with its owner per user'
    assert execute("SELECT count(*) FROM public.spaces;") == str(len(users))
    assert execute("SELECT count(*) FROM public.space_members;") == str(len(users))
    print(f'PASS: {len(users)} users, each with exactly one Personal space (id = user id) and owner membership')
    invalid = execute("SELECT count(*) FROM pg_constraint WHERE NOT convalidated "
                      "AND connamespace = 'public'::regnamespace;")
    assert invalid == '0', f'{invalid} constraints not validated'
    print('PASS: every constraint is validated')


def main():
    if '--snapshot' in sys.argv:
        target = sys.argv[sys.argv.index('--snapshot') + 1]
        old = os.umask(0o077)
        with open(target, 'w') as handle:
            json.dump(snapshot(strip_new=False), handle)
        os.umask(old)
        print('Snapshot written (private data; delete it after the rehearsal).')
        return
    if '--verify-only' in sys.argv:
        before = json.loads(open(sys.argv[sys.argv.index('--verify-only') + 1]).read())
        verify(before)
        print('C1 backfill verification passed.')
        return
    if CONTAINER != 'supabase_db_fundly-schema-dev':
        sys.exit('The seeded check only runs on the default local stack.')
    supabase('db', 'reset', '--version', BEFORE_C1)
    seed()
    before = snapshot(strip_new=False)
    supabase('migration', 'up')
    try:
        verify(before)
    finally:
        # Leave an empty, fully migrated database: other tests count rows.
        supabase('db', 'reset')
    print('All C1 backfill checks passed; the local database is reset and fully migrated.')


if __name__ == '__main__':
    main()
