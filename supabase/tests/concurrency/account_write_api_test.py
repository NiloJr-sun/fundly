"""S2.2B overlapping budget, archival and custom-type races; local only.

Run: python3 supabase/tests/concurrency/account_write_api_test.py
Reuses the S2.2A runner's independent-session/advisory-wait instrumentation.
"""

import json
import uuid

from write_api_test import authenticated, decode_result, execute, literal, overlap, rpc


def main():
    actor, category, custom = [str(uuid.uuid4()) for _ in range(3)]
    accounts = [str(uuid.uuid4()) for _ in range(5)]
    run_name = 'fundly_s22b_' + uuid.uuid4().hex[:12]

    def call(item):
        return decode_result(execute(authenticated(actor, run_name + '_seed') +
                                     rpc(str(uuid.uuid4()), item) + 'COMMIT;'))

    def create_account(record_id, name, base='savingsCash', custom_id=None):
        data = {'name': name, 'type': base, 'entered_opening_amount_minor': '0'}
        if custom_id is not None:
            data['custom_type_id'] = custom_id
        return {'operation': 'account.create', 'id': record_id, 'data': data}

    def budget(target, revision, previous):
        return {'operation': 'account.set_budget', 'id': target,
                'expected_revision': str(revision), 'data': {'previous_budget': previous}}

    def archive(target):
        return {'operation': 'account.set_archived', 'id': target,
                'expected_revision': '1', 'data': {'archived': True}}

    def spending(source, record_id):
        return {'operation': 'transaction.create', 'id': record_id, 'data': {
            'type': 'spending', 'amount_minor': '100', 'date': '2026-11-18',
            'payee': 'Race', 'source_account_id': source, 'category_id': category}}

    try:
        execute(f"INSERT INTO auth.users(id,email) VALUES({literal(actor)},'account-race@example.invalid'); "
                'INSERT INTO public.categories(id,owner_id,name,kind) VALUES '
                f"({literal(category)},{literal(actor)},'Food','spending');")
        for record_id, name in zip(accounts, ['Original budget', 'Second budget', 'Third budget',
                                              'Archive first', 'Spend first']):
            call(create_account(record_id, name))
        call({'operation': 'custom_type.create', 'id': custom,
              'data': {'name': 'Race type', 'base_type': 'savingsCash'}})

        overlap(actor, rpc(str(uuid.uuid4()), budget(accounts[0], 1, None)), actor,
                rpc(str(uuid.uuid4()), budget(accounts[1], 1, None)), run_name + '_none', 'budget_conflict')
        assert execute(f'SELECT id FROM public.accounts WHERE owner_id={literal(actor)} AND is_budget_account;') == accounts[0]
        print('PASS: competing budget selections from none have one winner', flush=True)

        previous = {'id': accounts[0], 'revision': '2'}
        overlap(actor, rpc(str(uuid.uuid4()), budget(accounts[1], 1, previous)), actor,
                rpc(str(uuid.uuid4()), budget(accounts[2], 1, previous)), run_name + '_switch', 'budget_conflict')
        assert execute(f'SELECT id FROM public.accounts WHERE owner_id={literal(actor)} AND is_budget_account;') == accounts[1]
        print('PASS: stale previous-budget snapshot cannot overwrite a concurrent switch', flush=True)

        entry = str(uuid.uuid4())
        overlap(actor, rpc(str(uuid.uuid4()), archive(accounts[3])), actor,
                rpc(str(uuid.uuid4()), spending(accounts[3], entry)), run_name + '_archive', 'invalid_transaction')
        assert execute(f'SELECT count(*) FROM public.transactions WHERE id={literal(entry)};') == '0'
        print('PASS: archive committed first prevents concurrent new spending', flush=True)

        entry = str(uuid.uuid4())
        overlap(actor, rpc(str(uuid.uuid4()), spending(accounts[4], entry)), actor,
                rpc(str(uuid.uuid4()), archive(accounts[4])), run_name + '_spend')
        assert execute(f'SELECT count(*) FROM public.transactions WHERE id={literal(entry)};') == '1'
        assert execute(f'SELECT is_archived FROM public.accounts WHERE id={literal(accounts[4])};') == 't'
        print('PASS: spending committed first retains history when the account is archived', flush=True)

        candidate = str(uuid.uuid4())
        change_base = {'operation': 'custom_type.update', 'id': custom,
                       'expected_revision': '1', 'data': {'base_type': 'loan'}}
        overlap(actor, rpc(str(uuid.uuid4()), change_base), actor,
                rpc(str(uuid.uuid4()), create_account(candidate, 'Stale base', custom_id=custom)),
                run_name + '_base', 'invalid_account')
        assert execute(f'SELECT count(*) FROM public.accounts WHERE id={literal(candidate)};') == '0'
        print('PASS: a custom-base change prevents creating an account with the stale base', flush=True)

        candidate = str(uuid.uuid4())
        change_base = {'operation': 'custom_type.update', 'id': custom,
                       'expected_revision': '2', 'data': {'base_type': 'credit'}}
        overlap(actor, rpc(str(uuid.uuid4()), create_account(candidate, 'Uses loan', 'loan', custom)), actor,
                rpc(str(uuid.uuid4()), change_base), run_name + '_usage', 'custom_type_in_use')
        assert execute(f'SELECT base_type FROM public.custom_account_types WHERE id={literal(custom)};') == 'loan'
        print('PASS: account creation committed first blocks a concurrent custom-base change', flush=True)

        candidate, batch = str(uuid.uuid4()), str(uuid.uuid4())
        item = create_account(candidate, 'Retry card', 'credit')
        first, second = overlap(actor, rpc(batch, item), actor, rpc(batch, item), run_name + '_linked')
        assert first == second, 'Linked row response changed on concurrent retry'
        assert execute(f'SELECT count(*) FROM public.categories WHERE linked_account_id={literal(candidate)};') == '1'
        assert first['results'][0]['changes'][0]['record']['linked_account_id'] == candidate
        print('PASS: concurrent account retries generate exactly one stable linked category', flush=True)
    finally:
        execute(f'BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.transactions WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.categories WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.accounts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.custom_account_types WHERE owner_id={literal(actor)}; '
                f'DELETE FROM auth.users WHERE id={literal(actor)}; COMMIT;')
    print('All 7 account concurrency checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
