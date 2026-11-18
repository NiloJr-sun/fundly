"""S2.3 overlapping delete/edit/re-create races; local only.

Run: python3 supabase/tests/concurrency/sync_protocol_test.py
Reuses the S2.2A runner's independent-session/advisory-wait instrumentation.
"""

import uuid

from write_api_test import authenticated, decode_result, execute, literal, overlap, rpc


def main():
    actor, account, category = [str(uuid.uuid4()) for _ in range(3)]
    run_name = 'fundly_s23_' + uuid.uuid4().hex[:12]

    def call(item):
        return decode_result(execute(authenticated(actor, run_name + '_seed') +
                                     rpc(str(uuid.uuid4()), item) + 'COMMIT;'))

    def create(record_id):
        return {'operation': 'transaction.create', 'id': record_id, 'data': {
            'type': 'spending', 'amount_minor': '100', 'date': '2026-11-18', 'payee': 'Race',
            'source_account_id': account, 'category_id': category}}

    def update(record_id):
        return {'operation': 'transaction.update', 'id': record_id,
                'expected_revision': '1', 'data': {'note': 'edited'}}

    def delete(record_id):
        return {'operation': 'transaction.delete', 'id': record_id, 'expected_revision': '1'}

    def rows(record_id):
        return execute(f'SELECT count(*) FROM public.transactions WHERE id={literal(record_id)};')

    def tombstones(record_id):
        return execute(f'SELECT count(*) FROM public.fundly_deleted_records WHERE id={literal(record_id)};')

    try:
        execute(f"INSERT INTO auth.users(id,email) VALUES({literal(actor)},'sync-race@example.invalid');")
        call({'operation': 'account.create', 'id': account, 'data': {
            'name': 'Race cash', 'type': 'savingsCash', 'entered_opening_amount_minor': '0'}})
        call({'operation': 'category.create', 'id': category,
              'data': {'name': 'Race food', 'kind': 'spending'}})

        entry = str(uuid.uuid4())
        call(create(entry))
        overlap(actor, rpc(str(uuid.uuid4()), delete(entry)), actor,
                rpc(str(uuid.uuid4()), update(entry)), run_name + '_delete', 'record_deleted')
        assert rows(entry) == '0' and tombstones(entry) == '1'
        print('PASS: an edit waiting behind a committed delete is reported as record_deleted', flush=True)

        entry = str(uuid.uuid4())
        call(create(entry))
        overlap(actor, rpc(str(uuid.uuid4()), update(entry)), actor,
                rpc(str(uuid.uuid4()), delete(entry)), run_name + '_edit', '"current_revision": "2"')
        assert rows(entry) == '1' and tombstones(entry) == '0'
        print('PASS: a stale delete waiting behind a committed edit conflicts with the current revision', flush=True)

        entry = str(uuid.uuid4())
        call(create(entry))
        overlap(actor, rpc(str(uuid.uuid4()), delete(entry)), actor,
                rpc(str(uuid.uuid4()), create(entry)), run_name + '_revive', 'record_deleted')
        assert rows(entry) == '0'
        print('PASS: re-creating a UUID behind its committed delete is refused', flush=True)
    finally:
        execute(f'BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.transactions WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.categories WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.accounts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.fundly_deleted_records WHERE owner_id={literal(actor)}; '
                f'DELETE FROM auth.users WHERE id={literal(actor)}; COMMIT;')
    print('All 3 sync-protocol concurrency checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
