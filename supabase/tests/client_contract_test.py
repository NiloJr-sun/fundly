"""S5.3/S5.4 client contract: the app's queued batches on the real server; local only.

Run from the repository root: python3 supabase/tests/client_contract_test.py
Runs test/core/sync/client_contract_test.dart, which performs every kind of
synchronized write offline and records the queued batches and the rows the
device shows. Every batch is then applied in order to the disposable local
database as a new user, the first batch is retried (idempotent), and the
server's rows must equal the device's, revisions included. Then a stale edit
and an edit of a deleted record are replayed as new batches: the refusals must
carry the SQLSTATE, message and JSON detail the app's uploader classifies and
logs (S5.4). Finally the app's Reset all data request (reset plan B2) is sent
to fundly_import_dataset: it must leave only untouched default categories,
tombstone every earlier record, return the stored result when resent, refuse
stale counts, and leave an account that a later into_empty import accepts.
Then the requests that copy a device's data (S6.2) go to a second new user:
into_empty must store every field as sent, and a replace with fresh IDs must
swap the whole dataset and tombstone the first copy. Last, requests built
from a parsed format 7 backup and an old format 3 backup (S6.3) must each be
accepted into an empty account.
Never reads .env or hosted credentials.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
import uuid
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / 'concurrency'))
from write_api_test import authenticated, execute, literal  # noqa: E402

COLUMNS = {
    'custom_account_types': 'id,name,base_type,revision',
    'accounts': 'id,name,type,opening_balance_minor,is_archived,custom_type_id,is_budget_account,revision',
    'categories': 'id,name,kind,is_archived,is_plan_archived,is_plan_deleted,plan_group,linked_account_id,revision',
    'transactions': 'id,type,amount_minor,date,payee,category_id,source_account_id,destination_account_id,note,revision',
    'monthly_plans': 'id,month,category_id,target_amount_minor,assigned_amount_minor,revision',
}


def record():
    with tempfile.TemporaryDirectory() as directory:
        out = os.path.join(directory, 'contract.json')
        subprocess.run(['flutter', 'test', 'test/core/sync/client_contract_test.dart'],
                       env={**os.environ, 'FUNDLY_CONTRACT_OUT': out}, check=True,
                       stdout=subprocess.DEVNULL)
        with open(out) as file:
            return json.load(file)


def apply(actor, batch):
    envelope = json.dumps(batch['envelope'])
    return execute(authenticated(actor, 'fundly_client_contract') +
                   f"SELECT public.fundly_apply_operations({literal(batch['id'])}::uuid,"
                   f'{literal(envelope)}::jsonb); COMMIT;')


def refusal(actor, item):
    """Sends [item] as a new batch; returns (SQLSTATE, message, detail)."""
    envelope = json.dumps({'version': 1, 'items': [item]})
    try:
        execute('\\set VERBOSITY verbose\n' + authenticated(actor, 'fundly_client_contract') +
                f'SELECT public.fundly_apply_operations({literal(str(uuid.uuid4()))}::uuid,'
                f'{literal(envelope)}::jsonb); COMMIT;')
    except AssertionError as error:
        text = str(error)
        state, message = re.search(r'ERROR:\s+(\w+): (\w+)', text).groups()
        detail = re.search(r'DETAIL:\s+(\{.*\})', text)
        return state, message, json.loads(detail.group(1)) if detail else None
    raise AssertionError(f'{item["operation"]} was accepted')


def check_refusals(actor, batches):
    items = [item for batch in batches for item in batch['envelope']['items']]
    deleted = {item['id'] for item in items if item['operation'].endswith('.delete')}
    stale = next(item for item in items if item['operation'] == 'transaction.update'
                 and item['id'] not in deleted)
    state, message, detail = refusal(actor, stale)
    assert (state, message) == ('P0001', 'revision_conflict'), (state, message)
    assert detail['index'] == 0 and detail['operation'] == 'transaction.update', detail
    assert int(detail['current_revision']) > int(stale['expected_revision']), detail
    print('PASS: a stale edit is refused as revision_conflict with current_revision', flush=True)
    deleted_transaction = next(item['id'] for item in items
                               if item['operation'] == 'transaction.delete')
    gone = {**stale, 'id': deleted_transaction, 'expected_revision': '1'}
    state, message, detail = refusal(actor, gone)
    assert (state, message) == ('P0001', 'record_deleted'), (state, message)
    assert detail['deleted_id'] == gone['id'] and detail['entity'] == 'transactions', detail
    print('PASS: an edit of a deleted record is refused as record_deleted', flush=True)


def import_dataset(actor, import_id, request):
    """Calls fundly_import_dataset as [actor]; returns the JSON result."""
    body = json.dumps(request)
    output = execute(authenticated(actor, 'fundly_client_contract') +
                     f'SELECT public.fundly_import_dataset({literal(import_id)}::uuid,'
                     f'{literal(body)}::jsonb); COMMIT;')
    return next(json.loads(line) for line in output.splitlines() if line.startswith('{'))


def import_refusal(actor, import_id, request):
    """Sends an import that must be refused; returns (SQLSTATE, message)."""
    try:
        import_dataset(actor, import_id, request)
    except AssertionError as error:
        return re.search(r'ERROR:\s+(\w+): (\w+)', str(error)).groups()
    raise AssertionError('the import was accepted')


def server_rows(actor, table):
    return json.loads(execute(
        f"SELECT coalesce(json_agg(t),'[]') FROM (SELECT * FROM public.{table} "
        f'WHERE owner_id={literal(actor)}) t;'))


def check_reset(actor, data):
    reset = data['reset']
    fresh = {'custom_account_types': 0, 'accounts': 0, 'categories': 9,
             'transactions': 0, 'monthly_plans': 0}
    before = {table: {row['id'] for row in data['state'][table]} for table in COLUMNS}
    expected = reset['request']['expected']
    assert expected == {table: len(ids) for table, ids in before.items()}, expected

    result = import_dataset(actor, reset['importId'], reset['request'])
    assert result['mode'] == 'replace' and result['counts'] == fresh, result
    categories = server_rows(actor, 'categories')
    assert sorted((c['name'], c['kind']) for c in categories) == sorted(
        (c['name'], c['kind']) for c in reset['request']['dataset']['categories'])
    assert all(c['revision'] == 1 and not c['is_archived'] and not c['is_plan_archived']
               and not c['is_plan_deleted'] and c['plan_group'] == 'spending'
               and c['linked_account_id'] is None for c in categories), categories
    for table in COLUMNS:
        if table != 'categories':
            assert server_rows(actor, table) == [], table
    print('PASS: the reset request leaves only the 9 untouched default categories', flush=True)

    tombstones = json.loads(execute(
        "SELECT coalesce(json_agg(t),'[]') FROM (SELECT entity, id FROM "
        f'public.fundly_deleted_records WHERE owner_id={literal(actor)}) t;'))
    deleted = {(t['entity'], t['id']) for t in tombstones}
    missing = [(table, record) for table, ids in before.items() for record in ids
               if (table, record) not in deleted]
    assert not missing, missing
    print('PASS: every record from before the reset has a tombstone', flush=True)

    again = import_dataset(actor, reset['importId'], reset['request'])
    assert again == result, (again, result)
    assert len(server_rows(actor, 'categories')) == 9
    print('PASS: resending the same reset returns the stored result and changes nothing',
          flush=True)

    stale = import_refusal(actor, str(uuid.uuid4()), reset['request'])
    assert stale == ('P0001', 'dataset_changed'), stale
    print('PASS: a reset with stale counts is refused as dataset_changed', flush=True)

    account = str(uuid.uuid4())
    copied = import_dataset(actor, str(uuid.uuid4()), {
        'version': 1, 'mode': 'into_empty',
        'dataset': {'custom_account_types': [], 'categories': [], 'transactions': [],
                    'monthly_plans': [],
                    'accounts': [{'id': account, 'name': 'After reset', 'type': 'savingsCash',
                                  'opening_balance_minor': '0', 'currency_code': 'PHP',
                                  'is_archived': False, 'custom_type_id': None,
                                  'is_budget_account': False}]}})
    assert copied['counts']['accounts'] == 1, copied
    print('PASS: after a reset the account counts as empty for an into_empty import',
          flush=True)


def wire_value(key, value):
    """A server row value in the import request's wire shape."""
    if value is None or isinstance(value, bool):
        return value
    if key.endswith('_minor'):
        return str(value)
    if key == 'date' and value.endswith(' BC'):
        return '0000' + value[4:-3]
    if key in ('created_at', 'updated_at'):
        return datetime.fromisoformat(value).astimezone(timezone.utc)
    return value


def check_copy(data):
    copy = data['copy']
    actor = str(uuid.uuid4())
    execute(f"INSERT INTO auth.users(id,email) VALUES({literal(actor)},'client-copy@example.invalid');")
    try:
        dataset = copy['request']['dataset']
        result = import_dataset(actor, copy['importId'], copy['request'])
        assert result['mode'] == 'into_empty', result
        assert result['counts'] == {t: len(rows) for t, rows in dataset.items()}, result
        for table, rows in dataset.items():
            stored = {row['id']: row for row in server_rows(actor, table)}
            for row in rows:
                server = stored[row['id']]
                for key, value in row.items():
                    expected = (datetime.fromisoformat(value.replace('Z', '+00:00'))
                                if key in ('created_at', 'updated_at') else value)
                    assert wire_value(key, server[key]) == expected, (table, key, server[key], value)
        print("PASS: the app's copy request is accepted into an empty account, every field as sent",
              flush=True)

        again = import_dataset(actor, copy['againId'], copy['again'])
        assert again['mode'] == 'replace', again
        first_ids = {(t, row['id']) for t, rows in dataset.items() for row in rows}
        for table, rows in copy['again']['dataset'].items():
            assert {row['id'] for row in server_rows(actor, table)} == {row['id'] for row in rows}
        tombstones = json.loads(execute(
            "SELECT coalesce(json_agg(t),'[]') FROM (SELECT entity, id FROM "
            f'public.fundly_deleted_records WHERE owner_id={literal(actor)}) t;'))
        assert first_ids <= {(t['entity'], t['id']) for t in tombstones}
        print('PASS: copying again with replace swaps the dataset and tombstones the first copy',
              flush=True)
    finally:
        cleanup(actor)


def check_restores(data):
    for name, request in data['copy']['restores'].items():
        actor = str(uuid.uuid4())
        execute(f"INSERT INTO auth.users(id,email) VALUES({literal(actor)},'client-restore@example.invalid');")
        try:
            result = import_dataset(actor, str(uuid.uuid4()), request)
            expected = {t: len(rows) for t, rows in request['dataset'].items()}
            assert result['counts'] == expected, (name, result)
            for table in expected:
                assert len(server_rows(actor, table)) == expected[table], (name, table)
        finally:
            cleanup(actor)
        print(f'PASS: a restore request from a {name} backup is accepted into an empty account',
              flush=True)


def cleanup(actor):
    execute(f'BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id={literal(actor)}; '
            f'DELETE FROM public.fundly_import_receipts WHERE owner_id={literal(actor)}; '
            f'DELETE FROM public.transactions WHERE owner_id={literal(actor)}; '
            f'DELETE FROM public.monthly_plans WHERE owner_id={literal(actor)}; '
            f'DELETE FROM public.categories WHERE owner_id={literal(actor)}; '
            f'DELETE FROM public.accounts WHERE owner_id={literal(actor)}; '
            f'DELETE FROM public.custom_account_types WHERE owner_id={literal(actor)}; '
            f'DELETE FROM public.fundly_deleted_records WHERE owner_id={literal(actor)}; '
            f'DELETE FROM auth.users WHERE id={literal(actor)}; COMMIT;')


def normalized(rows, columns):
    return sorted(({key: int(row[key]) if isinstance(row[key], bool) else row[key]
                    for key in columns} for row in rows), key=lambda row: row['id'])


def main():
    data = record()
    actor = str(uuid.uuid4())
    try:
        execute(f"INSERT INTO auth.users(id,email) VALUES({literal(actor)},'client-contract@example.invalid');")
        for index, batch in enumerate(data['batches']):
            try:
                apply(actor, batch)
            except AssertionError as error:
                raise AssertionError(f'batch {index} refused: {error}') from None
        print(f"PASS: the server accepted all {len(data['batches'])} queued batches in order", flush=True)
        apply(actor, data['batches'][0])
        print('PASS: retrying an uploaded batch changes nothing', flush=True)
        for table, columns in COLUMNS.items():
            keys = columns.split(',')
            server = json.loads(execute(
                f"SELECT coalesce(json_agg(t),'[]') FROM (SELECT {columns} FROM public.{table} "
                f'WHERE owner_id={literal(actor)}) t;'))
            assert normalized(server, keys) == normalized(data['state'][table], keys), table
        print('PASS: the server rows equal the rows the device showed, revisions included', flush=True)
        check_refusals(actor, data['batches'])
        check_reset(actor, data)
        check_copy(data)
        check_restores(data)
    finally:
        cleanup(actor)
    print('All 14 client-contract checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
