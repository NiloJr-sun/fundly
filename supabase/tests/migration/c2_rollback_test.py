"""Shared spaces C2 rollback rehearsal (docs/SHARED_SPACES_C2_PLAN.md).

Run from the repository root against the LOCAL stack only:

    python3 supabase/tests/migration/c2_rollback_test.py

It RESETS the local database (fully migrated). First it checks the rollback
refuses, changing nothing, while a record lives outside a Personal space.
Then, with Personal data and an empty extra space, it applies
supabase/rollback/20261124_c2_rollback.sql in one transaction, checks every
existing value is unchanged and the empty space is gone, and runs the C1-era
server tests on the rolled-back database. The database is reset at the end.
"""

import json
import subprocess
import sys
import uuid
from pathlib import Path

from spaces_backfill_test import CONTAINER, execute, literal, seed, snapshot, supabase

ROLLBACK = Path('supabase/rollback/20261124_c2_rollback.sql')
C1_PGTAP = ['account_write_api_test.sql', 'category_plan_write_api_test.sql', 'dataset_import_test.sql',
            'dataset_initialize_test.sql', 'schema_test.sql', 'space_write_api_test.sql', 'spaces_test.sql',
            'sync_protocol_test.sql', 'write_api_test.sql']
C1_PYTHON = ['concurrency/write_api_test.py', 'concurrency/account_write_api_test.py',
             'concurrency/category_plan_write_api_test.py', 'concurrency/sync_protocol_test.py',
             'concurrency/dataset_import_test.py', 'concurrency/dataset_initialize_test.py',
             'concurrency/space_write_api_test.py', 'client_contract_test.py']


def rollback():
    return subprocess.run(['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres',
                           '-v', 'ON_ERROR_STOP=1', '-q', '-1'],
                          input=ROLLBACK.read_text(), capture_output=True, text=True, timeout=120)


def as_user(actor, sql):
    claims = json.dumps({'sub': actor, 'role': 'authenticated'})
    return execute(f"BEGIN; SET LOCAL ROLE authenticated; "
                   f"SELECT set_config('request.jwt.claims', {literal(claims)}, true) \\g /dev/null\n{sql} COMMIT;")


def main():
    if CONTAINER != 'supabase_db_fundly-schema-dev':
        sys.exit('This rehearsal only runs on the default local stack.')
    supabase('db', 'reset')
    try:
        a, _, _ = seed()
        extra, used = str(uuid.uuid4()), str(uuid.uuid4())
        as_user(a, f"SELECT public.fundly_create_space({literal(extra)}, 'Empty extra');")
        as_user(a, f"SELECT public.fundly_create_space({literal(used)}, 'Used extra');")
        envelope = json.dumps({'version': 1, 'space_id': used, 'items': [
            {'operation': 'category.create', 'id': str(uuid.uuid4()), 'data': {'name': 'Elsewhere', 'kind': 'spending'}}]})
        as_user(a, f"SELECT public.fundly_apply_operations(gen_random_uuid(), {literal(envelope)}::jsonb);")
        before = snapshot(strip_new=True)
        result = rollback()
        assert result.returncode != 0 and 'records exist outside Personal spaces' in result.stderr, result.stderr
        assert snapshot(strip_new=True) == before
        assert execute("SELECT count(*) FROM public.spaces WHERE personal_of IS NULL;") == '2'
        print('PASS: with a record outside Personal, the rollback refuses and changes nothing')

        envelope = json.dumps({'version': 1, 'space_id': used, 'items': [
            {'operation': 'category.delete', 'id': execute(
                f"SELECT id FROM public.categories WHERE space_id = {literal(used)} AND name = 'Elsewhere';"),
             'expected_revision': '1'}]})
        as_user(a, f"SELECT public.fundly_apply_operations(gen_random_uuid(), {literal(envelope)}::jsonb);")
        execute(f"DELETE FROM public.categories WHERE space_id = {literal(used)};")
        before = snapshot(strip_new=True)
        result = rollback()
        assert result.returncode == 0, result.stderr
        print('PASS: with only Personal records, the rollback applies in one transaction')
        after = snapshot(strip_new=True)
        for table in before:
            assert after[table] == before[table], f'{table}: values changed by the rollback'
        print('PASS: every existing record, tombstone, receipt and user unchanged; each user reads the same rows')
        assert execute("SELECT count(*) FROM public.spaces WHERE personal_of IS NULL;") == '0'
        assert execute("SELECT count(*) FROM pg_proc WHERE proname IN ('fundly_create_space', 'legacy_owner');") == '0'
        assert execute("SELECT count(*) FROM pg_constraint WHERE conname LIKE '%_owner_is_space';") == '5'
        print('PASS: empty extra spaces removed; the C1 rules and functions are back')
        execute("BEGIN; DELETE FROM public.monthly_plans; DELETE FROM public.transactions; "
                "DELETE FROM public.categories; DELETE FROM public.accounts; "
                "DELETE FROM public.custom_account_types; DELETE FROM public.fundly_write_receipts; "
                "DELETE FROM public.fundly_import_receipts; DELETE FROM public.fundly_deleted_records; "
                "DELETE FROM auth.users WHERE email LIKE 'c1-backfill-%'; COMMIT;")
        result = subprocess.run(['npx', '--yes', 'supabase@3.2.0', 'test', 'db'],
                                capture_output=True, text=True, timeout=900)
        for name in C1_PGTAP:
            assert any(line.strip().endswith('ok') and name in line and 'not ok' not in line
                       for line in result.stdout.splitlines()), f'{name} did not pass:\n' + result.stdout[-3000:]
        print(f'PASS: all {len(C1_PGTAP)} C1-era pgTAP files pass on the rolled-back database')
        for test in C1_PYTHON:
            run = subprocess.run(['python3', str(Path('supabase/tests') / test)], capture_output=True, text=True,
                                 timeout=900)
            assert run.returncode == 0, test + '\n' + run.stdout[-2000:] + run.stderr[-2000:]
        print(f'PASS: {len(C1_PYTHON)} C1-era concurrency and contract suites pass on the rolled-back database')
    finally:
        supabase('db', 'reset')
    print('C2 rollback rehearsal passed; the local database is reset and fully migrated.')


if __name__ == '__main__':
    main()
