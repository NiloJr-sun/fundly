"""S5.3 two devices initialize one dataset at the same time; local only.

Run: python3 supabase/tests/concurrency/dataset_initialize_test.py
Reuses the S2.2A runner's independent-session/advisory-wait instrumentation.
"""

import uuid

from write_api_test import execute, literal, overlap, rpc


def main():
    actor = str(uuid.uuid4())
    run_name = 'fundly_s53_' + uuid.uuid4().hex[:12]

    def initialize():
        return rpc(str(uuid.uuid4()), {'operation': 'dataset.initialize', 'id': str(uuid.uuid4())})

    try:
        execute(f"INSERT INTO auth.users(id,email) VALUES({literal(actor)},'init-race@example.invalid');")
        overlap(actor, initialize(), actor, initialize(), run_name + '_init')
        count = execute(f'SELECT count(*) FROM public.categories WHERE owner_id={literal(actor)};')
        assert count == '9', count
        print('PASS: a second initialization waiting behind the first creates no duplicates', flush=True)
    finally:
        execute(f'BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.categories WHERE owner_id={literal(actor)}; '
                f'DELETE FROM public.fundly_deleted_records WHERE owner_id={literal(actor)}; '
                f'DELETE FROM auth.users WHERE id={literal(actor)}; COMMIT;')
    print('All 1 dataset-initialize concurrency checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
