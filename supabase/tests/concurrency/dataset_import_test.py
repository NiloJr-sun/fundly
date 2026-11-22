"""S6.1 imports racing uploads and other imports; local only.

Run: python3 supabase/tests/concurrency/dataset_import_test.py
Reuses the S2.2A runner's independent-session/advisory-wait instrumentation.
"""

import json
import uuid

from write_api_test import execute, literal, overlap, rpc


def dataset(transactions=1):
    """A small valid dataset with fresh IDs (also used by the timing check)."""
    cash, card, food, salary, debt = [str(uuid.uuid4()) for _ in range(5)]
    account = {'currency_code': 'PHP', 'is_archived': False, 'custom_type_id': None,
               'is_budget_account': False}
    category = {'is_archived': False, 'is_plan_archived': False, 'is_plan_deleted': False,
                'plan_group': 'spending', 'linked_account_id': None}
    return {
        'custom_account_types': [],
        'accounts': [
            {**account, 'id': cash, 'name': 'Cash', 'type': 'savingsCash',
             'opening_balance_minor': '100000', 'is_budget_account': True},
            {**account, 'id': card, 'name': 'Card', 'type': 'credit', 'opening_balance_minor': '0'},
        ],
        'categories': [
            {**category, 'id': food, 'name': 'Food', 'kind': 'spending'},
            {**category, 'id': salary, 'name': 'Salary', 'kind': 'inflow'},
            {**category, 'id': debt, 'name': 'Card debt', 'kind': 'spending',
             'plan_group': 'liability', 'linked_account_id': card},
        ],
        'transactions': [
            {'id': str(uuid.uuid4()), 'type': 'spending', 'amount_minor': str(100 + n % 900),
             'currency_code': 'PHP', 'date': f'2026-{1 + n % 12:02d}-{1 + n % 28:02d}',
             'payee': f'Shop {n}', 'category_id': food,
             'source_account_id': cash if n % 2 else card, 'destination_account_id': None,
             'note': 'Imported', 'created_at': '2026-11-22T01:02:03.123456Z',
             'updated_at': '2026-11-22T01:02:03.123456Z'}
            for n in range(transactions)
        ],
        'monthly_plans': [
            {'id': str(uuid.uuid4()), 'month': f'2026-{m:02d}', 'category_id': food,
             'target_amount_minor': '500000', 'assigned_amount_minor': '400000', 'currency_code': 'PHP'}
            for m in range(1, 13)
        ],
    }


def counts(data):
    return {table: len(rows) for table, rows in data.items()}


def import_call(import_id, mode, data, expected=None):
    request = {'version': 1, 'mode': mode, 'dataset': data}
    if expected is not None:
        request['expected'] = expected
    return (f'SELECT public.fundly_import_dataset({literal(import_id)}::uuid,'
            f'{literal(json.dumps(request))}::jsonb);')


def count(table, actor):
    return int(execute(f'SELECT count(*) FROM public.{table} WHERE owner_id={literal(actor)};'))


def cleanup(actors):
    owners = ','.join(literal(actor) for actor in actors)
    statements = [f'DELETE FROM public.{table} WHERE owner_id IN ({owners});' for table in (
        'fundly_import_receipts', 'fundly_write_receipts', 'monthly_plans', 'transactions',
        'categories', 'accounts', 'custom_account_types', 'fundly_deleted_records')]
    execute('BEGIN; ' + ' '.join(statements) + f' DELETE FROM auth.users WHERE id IN ({owners}); COMMIT;')


def main():
    actors = [str(uuid.uuid4()) for _ in range(4)]
    upload_first, import_first, replacer, retrier = actors
    run_name = 'fundly_s61_' + uuid.uuid4().hex[:12]
    try:
        execute('INSERT INTO auth.users(id,email) VALUES ' + ','.join(
            f'({literal(actor)},{literal(f"import-race-{n}@example.invalid")})'
            for n, actor in enumerate(actors)) + ';')

        # An upload waiting behind an import lands on top of the imported dataset.
        data = dataset()
        account = {'operation': 'account.create', 'id': str(uuid.uuid4()),
                   'data': {'name': 'Wallet', 'type': 'savingsCash', 'entered_opening_amount_minor': '0'}}
        overlap(import_first, import_call(str(uuid.uuid4()), 'into_empty', data), import_first,
                rpc(str(uuid.uuid4()), account), run_name + '_import_then_upload')
        assert count('accounts', import_first) == 3, count('accounts', import_first)
        assert count('transactions', import_first) == 1
        print('PASS: an upload waiting behind an import is applied after it, on the new dataset', flush=True)

        # An import waiting behind an upload sees the account is no longer empty.
        overlap(upload_first, rpc(str(uuid.uuid4()), account | {'id': str(uuid.uuid4())}), upload_first,
                import_call(str(uuid.uuid4()), 'into_empty', dataset()), run_name + '_upload_then_import',
                expected_error='dataset_not_empty')
        assert count('accounts', upload_first) == 1
        print('PASS: an import waiting behind an upload is refused as dataset_not_empty', flush=True)

        # Two replaces confirmed against the same counts: only the first applies.
        first = dataset()
        execute(f"BEGIN; SET LOCAL ROLE authenticated; "
                f"SELECT set_config('request.jwt.claim.sub',{literal(replacer)},true); "
                + import_call(str(uuid.uuid4()), 'into_empty', first) + ' COMMIT;')
        seen = counts(first)
        overlap(replacer, import_call(str(uuid.uuid4()), 'replace', dataset(2), seen), replacer,
                import_call(str(uuid.uuid4()), 'replace', dataset(3), seen), run_name + '_two_replaces',
                expected_error='dataset_changed')
        assert count('transactions', replacer) == 2, count('transactions', replacer)
        print('PASS: a second replace confirmed against old counts is refused as dataset_changed', flush=True)

        # The same import sent twice at once (a retry racing the original).
        import_id = str(uuid.uuid4())
        same = import_call(import_id, 'into_empty', dataset(4))
        first_result, second_result = overlap(retrier, same, retrier, same, run_name + '_same_import')
        assert first_result == second_result, (first_result, second_result)
        assert count('transactions', retrier) == 4, count('transactions', retrier)
        print('PASS: the same import sent twice at once imports once and returns one result', flush=True)
    finally:
        cleanup(actors)
    print('All 4 dataset-import concurrency checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
