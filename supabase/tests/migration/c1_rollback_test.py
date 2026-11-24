"""Shared spaces C1 rollback rehearsal (docs/SHARED_SPACES_C1_PLAN.md).

Run from the repository root against the LOCAL stack only:

    python3 supabase/tests/migration/c1_rollback_test.py

It RESETS the local database (fully migrated), writes data through the C1
write API, applies supabase/rollback/20261124_c1_rollback.sql in one
transaction, checks every existing value is unchanged, then runs the pre-C1
server tests against the rolled-back database. The database is reset again at
the end (fully migrated, empty).
"""

import subprocess
import sys
from pathlib import Path

from spaces_backfill_test import CONTAINER, RECORD_TABLES, execute, seed, snapshot, supabase

ROLLBACK = Path('supabase/rollback/20261124_c1_rollback.sql')
PRE_C1_PGTAP = ['account_write_api_test.sql', 'category_plan_write_api_test.sql', 'dataset_import_test.sql',
                'dataset_initialize_test.sql', 'schema_test.sql', 'sync_protocol_test.sql', 'write_api_test.sql']
PRE_C1_PYTHON = ['concurrency/write_api_test.py', 'concurrency/account_write_api_test.py',
                 'concurrency/category_plan_write_api_test.py', 'concurrency/sync_protocol_test.py',
                 'concurrency/dataset_import_test.py', 'concurrency/dataset_initialize_test.py',
                 'client_contract_test.py']


def run(command):
    result = subprocess.run(command, capture_output=True, text=True, timeout=900)
    if result.returncode:
        raise AssertionError(' '.join(command) + '\n' + result.stdout[-3000:] + result.stderr[-3000:])
    return result.stdout


def main():
    if CONTAINER != 'supabase_db_fundly-schema-dev':
        sys.exit('This rehearsal only runs on the default local stack.')
    supabase('db', 'reset')
    try:
        seed()
        before = snapshot(strip_new=True)
        result = subprocess.run(['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres',
                                 '-v', 'ON_ERROR_STOP=1', '-q', '-1'],
                                input=ROLLBACK.read_text(), capture_output=True, text=True, timeout=120)
        assert result.returncode == 0, result.stderr
        print('PASS: the rollback applied in one transaction')
        after = snapshot(strip_new=True)
        for table in before:
            assert after[table] == before[table], f'{table}: values changed by the rollback'
        print(f'PASS: every existing value unchanged in {len(before) - 1} tables')
        assert execute("SELECT count(*) FROM pg_policies WHERE schemaname = 'public' AND policyname = 'read_own';") == '5'
        assert execute("SELECT count(*) FROM pg_proc WHERE proname IN ('retired_space', 'require_writer', "
                       "'bridge_space_owner');") == '0'
        for table in RECORD_TABLES:
            assert execute(f"SELECT count(*) FROM pg_constraint WHERE conname = '{table}_owner_id_key';") == '1'
        print('PASS: per-owner read rules, keys and the pre-C1 functions are back')
        # The suites count whole tables: remove the seeded data first.
        execute("BEGIN; DELETE FROM public.monthly_plans; DELETE FROM public.transactions; "
                "DELETE FROM public.categories; DELETE FROM public.accounts; "
                "DELETE FROM public.custom_account_types; DELETE FROM public.fundly_write_receipts; "
                "DELETE FROM public.fundly_import_receipts; DELETE FROM public.fundly_deleted_records; "
                "DELETE FROM auth.users WHERE email LIKE 'c1-backfill-%'; COMMIT;")
        # The whole suite runs (files share an include); the two C1 files are
        # expected to fail after a rollback, every pre-C1 file must pass.
        result = subprocess.run(['npx', '--yes', 'supabase@3.2.0', 'test', 'db'],
                                capture_output=True, text=True, timeout=900)
        for name in PRE_C1_PGTAP:
            assert any(line.strip().endswith('ok') and name in line and 'not ok' not in line
                       for line in result.stdout.splitlines()), f'{name} did not pass:\n' + result.stdout[-3000:]
        print(f'PASS: all {len(PRE_C1_PGTAP)} pre-C1 pgTAP files pass on the rolled-back database')
        for test in PRE_C1_PYTHON:
            run(['python3', str(Path('supabase/tests') / test)])
        print(f'PASS: {len(PRE_C1_PYTHON)} pre-C1 concurrency and contract suites pass on the rolled-back database')
    finally:
        supabase('db', 'reset')
    print('C1 rollback rehearsal passed; the local database is reset and fully migrated.')


if __name__ == '__main__':
    main()
