"""S2.2C overlapping plan, archive and category races; local only.

Run: python3 supabase/tests/concurrency/category_plan_write_api_test.py
Reuses the S2.2A runner's independent-session/advisory-wait instrumentation.
The first session commits while the second waits on the per-user lock, so the
second always sees the first's committed state.
"""

import uuid

from write_api_test import authenticated, decode_result, execute, literal, overlap, rpc

MONTH = '2026-11'
FAR = '2099-12'  # Always a current/future month for the archive guard.


def main():
    actor, budget = str(uuid.uuid4()), str(uuid.uuid4())
    run_name = 'fundly_s22c_' + uuid.uuid4().hex[:12]

    def call(item):
        return decode_result(execute(authenticated(actor, run_name + '_seed') +
                                     rpc(str(uuid.uuid4()), item) + 'COMMIT;'))['results'][0]

    def category(name):
        record_id = str(uuid.uuid4())
        call({'operation': 'category.create', 'id': record_id,
              'data': {'name': name, 'kind': 'spending'}})
        return record_id

    def revision(category_id):
        return execute(f'SELECT revision FROM public.categories WHERE id={literal(category_id)};')

    def plan(category_id, month, assigned, previous=None, record_id=None):
        return {'operation': 'plan.save', 'id': record_id or str(uuid.uuid4()), 'data': {
            'category_id': category_id, 'month': month, 'target_amount_minor': None,
            'assigned_amount_minor': assigned, 'previous': previous}}

    def spending(category_id, month, amount='100', record_id=None):
        return {'operation': 'transaction.create', 'id': record_id or str(uuid.uuid4()), 'data': {
            'type': 'spending', 'amount_minor': amount, 'date': month + '-01', 'payee': 'Race',
            'source_account_id': budget, 'category_id': category_id}}

    def archive(category_id):
        return {'operation': 'plan.set_archived', 'id': category_id,
                'expected_revision': revision(category_id),
                'data': {'archived': True, 'timezone': 'Asia/Manila'}}

    def purge(category_id):
        return {'operation': 'plan.delete_permanently', 'id': category_id,
                'expected_revision': revision(category_id)}

    def plan_archived(category_id):
        return execute(f'SELECT is_plan_archived FROM public.categories WHERE id={literal(category_id)};') == 't'

    def count(sql):
        return execute(f'SELECT count(*) FROM {sql};')

    try:
        execute(f"INSERT INTO auth.users(id,email) VALUES({literal(actor)},'plan-race@example.invalid');")
        call({'operation': 'account.create', 'id': budget, 'data': {
            'name': 'Race budget', 'type': 'savingsCash', 'entered_opening_amount_minor': '100000'}})
        call({'operation': 'account.set_budget', 'id': budget, 'expected_revision': '1',
              'data': {'previous_budget': None}})

        target = category('Same month')
        first_id, second_id = str(uuid.uuid4()), str(uuid.uuid4())
        overlap(actor, rpc(str(uuid.uuid4()), plan(target, MONTH, '100', record_id=first_id)), actor,
                rpc(str(uuid.uuid4()), plan(target, MONTH, '200', record_id=second_id)),
                run_name + '_create', 'plan_conflict')
        assert execute(f'SELECT id::text||assigned_amount_minor FROM public.monthly_plans WHERE category_id={literal(target)};') \
            == first_id + '100'
        print('PASS: concurrent first saves for one category/month have one winner', flush=True)

        target = category('Spend then archive')
        call(plan(target, FAR, '100'))
        overlap(actor, rpc(str(uuid.uuid4()), spending(target, FAR)), actor,
                rpc(str(uuid.uuid4()), archive(target)), run_name + '_spend')
        assert plan_archived(target)
        print('PASS: budget spending committed first releases the allocation for a waiting archive', flush=True)

        target = category('Archive then refund')
        entry = str(uuid.uuid4())
        call(plan(target, FAR, '100'))
        call(spending(target, FAR, record_id=entry))
        overlap(actor, rpc(str(uuid.uuid4()), archive(target)), actor,
                rpc(str(uuid.uuid4()), {'operation': 'transaction.delete', 'id': entry,
                                        'expected_revision': '1'}), run_name + '_release')
        assert plan_archived(target) and count(f'public.transactions WHERE id={literal(entry)}') == '0'
        assert execute(f'SELECT assigned_amount_minor FROM public.monthly_plans WHERE category_id={literal(target)};') == '100'
        print('PASS: deleting spending after a committed archive keeps the row archived and its history', flush=True)

        target = category('Archive then assign')
        overlap(actor, rpc(str(uuid.uuid4()), archive(target)), actor,
                rpc(str(uuid.uuid4()), plan(target, FAR, '100')), run_name + '_assign', 'plan_archived')
        assert count(f'public.monthly_plans WHERE category_id={literal(target)}') == '0'
        print('PASS: an archive committed first prevents a concurrent assignment', flush=True)

        target = category('Assign then archive')
        overlap(actor, rpc(str(uuid.uuid4()), plan(target, FAR, '100')), actor,
                rpc(str(uuid.uuid4()), archive(target)), run_name + '_reserve', 'plan_allocation_remaining')
        assert not plan_archived(target)
        print('PASS: an assignment committed first blocks a waiting archive', flush=True)

        target = category('Delete then spend')
        call(archive(target))
        entry = str(uuid.uuid4())
        overlap(actor, rpc(str(uuid.uuid4()), purge(target)), actor,
                rpc(str(uuid.uuid4()), spending(target, MONTH, record_id=entry)), run_name + '_purge')
        assert execute(f'SELECT is_plan_deleted FROM public.categories WHERE id={literal(target)};') == 't'
        assert count(f'public.transactions WHERE id={literal(entry)}') == '1'
        print('PASS: spending after a committed plan deletion is recorded; the row stays deleted', flush=True)

        target = category('Spend then delete')
        call(archive(target))
        overlap(actor, rpc(str(uuid.uuid4()), spending(target, MONTH)), actor,
                rpc(str(uuid.uuid4()), purge(target)), run_name + '_activity', 'plan_delete_blocked')
        assert execute(f'SELECT is_plan_deleted FROM public.categories WHERE id={literal(target)};') == 'f'
        print('PASS: spending committed first blocks a waiting permanent deletion', flush=True)

        target = category('Remove then spend')
        entry = str(uuid.uuid4())
        overlap(actor, rpc(str(uuid.uuid4()), {'operation': 'category.delete', 'id': target,
                                               'expected_revision': '1'}), actor,
                rpc(str(uuid.uuid4()), spending(target, MONTH, record_id=entry)),
                run_name + '_remove', 'record_not_accessible')
        assert count(f'public.transactions WHERE id={literal(entry)}') == '0'
        print('PASS: a committed category deletion prevents concurrent spending in it', flush=True)

        target = category('Spend then remove')
        overlap(actor, rpc(str(uuid.uuid4()), spending(target, MONTH)), actor,
                rpc(str(uuid.uuid4()), {'operation': 'category.delete', 'id': target,
                                        'expected_revision': '1'}), run_name + '_used', 'category_in_use')
        assert count(f'public.categories WHERE id={literal(target)}') == '1'
        print('PASS: spending committed first blocks a waiting category deletion', flush=True)
    finally:
        execute(f'BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.transactions WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.monthly_plans WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.categories WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.accounts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM auth.users WHERE id={literal(actor)}; COMMIT;')
    print('All 9 category/plan concurrency checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
