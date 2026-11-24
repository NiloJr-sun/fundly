"""Shared spaces C3 rollback rehearsal (docs/SHARED_SPACES_C3_PLAN.md).

Run from the repository root against the LOCAL stack only:

    python3 supabase/tests/migration/c3_rollback_test.py

It RESETS the local database (fully migrated), writes Personal data, shares a
space by invite (accepted) with records from both members, applies
supabase/rollback/20261124_c3_rollback.sql in one transaction, checks every
record, membership and what each user reads is unchanged and the sharing
functions are gone, then runs the C2-era server tests. The database is reset
at the end.
"""

import json
import subprocess
import sys
import uuid
from pathlib import Path

from spaces_backfill_test import CONTAINER, execute, literal, seed, snapshot, supabase

ROLLBACK = Path('supabase/rollback/20261124_c3_rollback.sql')
C2_PGTAP = ['account_write_api_test.sql', 'category_plan_write_api_test.sql', 'dataset_import_test.sql',
            'dataset_initialize_test.sql', 'private_spaces_test.sql', 'schema_test.sql',
            'space_write_api_test.sql', 'spaces_test.sql', 'sync_protocol_test.sql', 'write_api_test.sql']
C2_PYTHON = ['concurrency/write_api_test.py', 'concurrency/account_write_api_test.py',
             'concurrency/category_plan_write_api_test.py', 'concurrency/sync_protocol_test.py',
             'concurrency/dataset_import_test.py', 'concurrency/dataset_initialize_test.py',
             'concurrency/space_write_api_test.py', 'client_contract_test.py']


def as_user(actor, sql):
    claims = json.dumps({'sub': actor, 'role': 'authenticated'})
    return execute(f"BEGIN; SET LOCAL ROLE authenticated; "
                   f"SELECT set_config('request.jwt.claims', {literal(claims)}, true) \\g /dev/null\n{sql} COMMIT;")


def members():
    return execute("SELECT string_agg(space_id || ':' || user_id || ':' || role || ':' || coalesce(email, ''), ',' "
                   "ORDER BY space_id, user_id) FROM public.space_members;")


def main():
    if CONTAINER != 'supabase_db_fundly-schema-dev':
        sys.exit('This rehearsal only runs on the default local stack.')
    supabase('db', 'reset')
    try:
        a, b, _ = seed()
        space = str(uuid.uuid4())
        as_user(a, f"SELECT public.fundly_create_space({literal(space)}, 'Shared');")
        b_email = execute(f"SELECT email FROM auth.users WHERE id = {literal(b)};")
        secret = json.loads(as_user(a, f"SELECT public.fundly_create_invite({literal(space)}, "
                                       f"{literal(b_email)}, 'editor');"))['secret']
        as_user(b, f"SELECT public.fundly_accept_invite({literal(secret)});")
        for actor in (a, b):
            envelope = json.dumps({'version': 1, 'space_id': space, 'items': [
                {'operation': 'category.create', 'id': str(uuid.uuid4()),
                 'data': {'name': f'From {actor[:4]}', 'kind': 'spending'}}]})
            as_user(actor, f"SELECT public.fundly_apply_operations(gen_random_uuid(), {literal(envelope)}::jsonb);")
        before, members_before = snapshot(strip_new=True), members()

        result = subprocess.run(['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres',
                                 '-v', 'ON_ERROR_STOP=1', '-q', '-1'],
                                input=ROLLBACK.read_text(), capture_output=True, text=True, timeout=120)
        assert result.returncode == 0, result.stderr
        print('PASS: the rollback applied in one transaction')
        after = snapshot(strip_new=True)
        for table in before:
            assert after[table] == before[table], f'{table}: values changed by the rollback'
        assert members() == members_before, 'memberships changed'
        print('PASS: every record, tombstone, receipt, membership and what each user reads is unchanged')
        assert execute("SELECT count(*) FROM pg_proc WHERE proname IN ('fundly_create_invite', "
                       "'fundly_delete_space', 'claim_invite');") == '0'
        assert execute("SELECT count(*) FROM pg_class WHERE relname = 'space_invites';") == '0'
        print('PASS: invites and the sharing functions are gone')

        execute("BEGIN; DELETE FROM public.monthly_plans; DELETE FROM public.transactions; "
                "DELETE FROM public.categories; DELETE FROM public.accounts; "
                "DELETE FROM public.custom_account_types; DELETE FROM public.fundly_write_receipts; "
                "DELETE FROM public.fundly_import_receipts; DELETE FROM public.fundly_deleted_records; "
                f"DELETE FROM public.spaces WHERE id = {literal(space)}; "
                "DELETE FROM auth.users WHERE email LIKE 'c1-backfill-%'; COMMIT;")
        result = subprocess.run(['npx', '--yes', 'supabase@3.2.0', 'test', 'db'],
                                capture_output=True, text=True, timeout=900)
        for name in C2_PGTAP:
            assert any(line.strip().endswith('ok') and name in line and 'not ok' not in line
                       for line in result.stdout.splitlines()), f'{name} did not pass:\n' + result.stdout[-3000:]
        print(f'PASS: all {len(C2_PGTAP)} C2-era pgTAP files pass on the rolled-back database')
        for test in C2_PYTHON:
            run = subprocess.run(['python3', str(Path('supabase/tests') / test)], capture_output=True, text=True,
                                 timeout=900)
            assert run.returncode == 0, test + '\n' + run.stdout[-2000:] + run.stderr[-2000:]
        print(f'PASS: {len(C2_PYTHON)} C2-era concurrency and contract suites pass on the rolled-back database')
    finally:
        supabase('db', 'reset')
    print('C3 rollback rehearsal passed; the local database is reset and fully migrated.')


if __name__ == '__main__':
    main()
