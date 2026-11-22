"""S5.3/S5.4 client contract: the app's queued batches on the real server; local only.

Run from the repository root: python3 supabase/tests/client_contract_test.py
Runs test/core/sync/client_contract_test.dart, which performs every kind of
synchronized write offline and records the queued batches and the rows the
device shows. Every batch is then applied in order to the disposable local
database as a new user, the first batch is retried (idempotent), and the
server's rows must equal the device's, revisions included. Then a stale edit
and an edit of a deleted record are replayed as new batches: the refusals must
carry the SQLSTATE, message and JSON detail the app's uploader classifies and
logs (S5.4). Never reads .env or hosted credentials.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
import uuid
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
    finally:
        execute(f'BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.transactions WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.monthly_plans WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.categories WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.accounts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.custom_account_types WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.fundly_deleted_records WHERE owner_id={literal(actor)}; '
                f'DELETE FROM auth.users WHERE id={literal(actor)}; COMMIT;')
    print('All 5 client-contract checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
