"""Banks rollback rehearsal (docs/BANKS_PLAN.md, step B.1).

Run from the repository root against the LOCAL stack only:

    python3 supabase/tests/migration/banks_rollback_test.py

Unlike the C1-C3 rehearsals it does not reset the database: everything runs
in one transaction that is rolled back at the end, so the local data is left
as it was. Inside it, it writes custom banks, accounts with a bank, a deleted
bank (tombstone) and a receipt; applies supabase/rollback/20261126_banks_rollback.sql;
checks every other record, tombstone and receipt is unchanged, the bank table,
columns and functions are gone, and that 1.4.0 writes and imports work (an
import's counts are the five tables again, bank operations are unsupported).
Then it applies the migration again and checks bank writes work once more.
"""

import subprocess
import sys
from pathlib import Path

CONTAINER = 'supabase_db_fundly-schema-dev'
MIGRATION = Path('supabase/migrations/20261126010000_banks.sql')
ROLLBACK = Path('supabase/rollback/20261126_banks_rollback.sql')
USER = 'a5900000-0000-4000-8000-000000000001'
FRESH = 'b5900000-0000-4000-8000-000000000001'

SETUP = f"""
\\set ON_ERROR_STOP 1
BEGIN;
INSERT INTO auth.users(id, email) VALUES ('{USER}', 'bk-rollback@example.invalid'),
  ('{FRESH}', 'bk-rollback-fresh@example.invalid');
SELECT fundly_private.ensure_personal_space('{USER}') \\g /dev/null
SELECT fundly_private.ensure_personal_space('{FRESH}') \\g /dev/null

CREATE FUNCTION pg_temp.write(actor uuid, items jsonb) RETURNS jsonb LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  RETURN public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1, 'items', items));
END;
$$;
CREATE FUNCTION pg_temp.refusal(actor uuid, items jsonb) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.write(actor, items);
  RETURN 'accepted';
EXCEPTION WHEN others THEN RETURN sqlerrm;
END;
$$;
-- One fingerprint per table of everything but the bank fields.
CREATE FUNCTION pg_temp.fingerprint() RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object(
    'custom_account_types', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), ''))
      FROM public.custom_account_types t),
    'accounts', (SELECT md5(coalesce(string_agg((to_jsonb(t) - 'bank_key' - 'custom_bank_id')::text, ','
      ORDER BY id), '')) FROM public.accounts t),
    'categories', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), '')) FROM public.categories t),
    'transactions', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), ''))
      FROM public.transactions t),
    'monthly_plans', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), ''))
      FROM public.monthly_plans t),
    'tombstones', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY entity, id), ''))
      FROM public.fundly_deleted_records t WHERE entity <> 'custom_banks'),
    'write_receipts', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY batch_id), ''))
      FROM public.fundly_write_receipts t),
    'spaces', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), '')) FROM public.spaces t))
$$;
CREATE FUNCTION pg_temp.check(passed boolean, label text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  IF passed IS NOT TRUE THEN RAISE EXCEPTION 'FAIL: %', label; END IF;
  RETURN 'PASS: ' || label;
END;
$$;

SELECT pg_temp.write('{USER}', jsonb_build_array(
  jsonb_build_object('operation', 'bank.create', 'id', '15900000-0000-4000-8000-000000000001',
    'data', jsonb_build_object('name', 'Coop')),
  jsonb_build_object('operation', 'bank.create', 'id', '15900000-0000-4000-8000-000000000002',
    'data', jsonb_build_object('name', 'Old bank')),
  jsonb_build_object('operation', 'bank.delete', 'id', '15900000-0000-4000-8000-000000000002',
    'expected_revision', '1'),
  jsonb_build_object('operation', 'account.create', 'id', '25900000-0000-4000-8000-000000000001',
    'data', jsonb_build_object('name', 'Coop Savings', 'type', 'savingsCash', 'entered_opening_amount_minor', '1000',
      'custom_bank_id', '15900000-0000-4000-8000-000000000001')),
  jsonb_build_object('operation', 'account.create', 'id', '25900000-0000-4000-8000-000000000002',
    'data', jsonb_build_object('name', 'BDO Card', 'type', 'credit', 'entered_opening_amount_minor', '500',
      'bank_key', 'bdo')))) \\g /dev/null
CREATE TEMPORARY TABLE before AS SELECT pg_temp.fingerprint() AS value;
"""

AFTER_ROLLBACK = f"""
SELECT pg_temp.check(pg_temp.fingerprint() = (SELECT value FROM before),
  'every other record, tombstone, receipt and space is unchanged');
SELECT pg_temp.check(to_regclass('public.custom_banks') IS NULL
  AND NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = 'public'
    AND table_name = 'accounts' AND column_name IN ('bank_key', 'custom_bank_id'))
  AND NOT EXISTS(SELECT 1 FROM pg_proc WHERE proname IN ('apply_custom_bank', 'check_custom_bank', 'bank_key',
    'builtin_bank_name'))
  AND NOT EXISTS(SELECT 1 FROM public.fundly_deleted_records WHERE entity = 'custom_banks'),
  'the bank table, columns, functions and tombstones are gone');
SELECT pg_temp.check((SELECT opening_balance_minor FROM public.accounts
    WHERE id = '25900000-0000-4000-8000-000000000002') = -500, 'accounts keep their balances');
SELECT pg_temp.check(pg_temp.refusal('{USER}', jsonb_build_array(
    jsonb_build_object('operation', 'account.update', 'id', '25900000-0000-4000-8000-000000000001',
      'expected_revision', '1', 'data', jsonb_build_object('name', 'Coop Savings 2')),
    jsonb_build_object('operation', 'account.create', 'id', '25900000-0000-4000-8000-000000000003',
      'data', jsonb_build_object('name', 'Wallet', 'type', 'savingsCash', 'entered_opening_amount_minor', '0'))))
  = 'accepted', 'a 1.4.0 account update and create are accepted');
SELECT pg_temp.check(pg_temp.refusal('{USER}', jsonb_build_array(
    jsonb_build_object('operation', 'bank.create', 'id', '15900000-0000-4000-8000-000000000003',
      'data', jsonb_build_object('name', 'New')))) = 'unsupported_operation', 'bank operations are unsupported');
SELECT set_config('request.jwt.claims', jsonb_build_object('sub', '{FRESH}', 'role', 'authenticated')::text, true)
  \\g /dev/null
SELECT pg_temp.check((SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(public.fundly_import_dataset(
    gen_random_uuid(), jsonb_build_object('version', 1, 'mode', 'into_empty', 'dataset', jsonb_build_object(
      'custom_account_types', '[]'::jsonb, 'accounts', '[]'::jsonb, 'categories', '[]'::jsonb,
      'transactions', '[]'::jsonb, 'monthly_plans', '[]'::jsonb)))->'counts') k)
  = array['accounts', 'categories', 'custom_account_types', 'monthly_plans', 'transactions'],
  'a 1.4.0 import is accepted and reports the five tables');
"""

AFTER_REAPPLY = f"""
SELECT pg_temp.check(pg_temp.refusal('{USER}', jsonb_build_array(
    jsonb_build_object('operation', 'bank.create', 'id', '15900000-0000-4000-8000-000000000003',
      'data', jsonb_build_object('name', 'Coop')),
    jsonb_build_object('operation', 'account.update', 'id', '25900000-0000-4000-8000-000000000003',
      'expected_revision', '1', 'data', jsonb_build_object('bank_key', 'gcash')))) = 'accepted',
  'after applying the migration again, bank writes work');
ROLLBACK;
"""


def main():
    script = (SETUP + ROLLBACK.read_text() + AFTER_ROLLBACK + MIGRATION.read_text() + AFTER_REAPPLY)
    result = subprocess.run(['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres',
                             '-q', '-At'], input=script, capture_output=True, text=True, timeout=300)
    passes = [line for line in result.stdout.splitlines() if line.startswith('PASS: ')]
    for line in passes:
        print(line)
    if result.returncode or len(passes) != 7 or 'ERROR' in result.stderr:
        sys.exit('Rehearsal failed:\n' + result.stderr[-3000:])
    print('Banks rollback rehearsal passed; everything was rolled back, the local data is unchanged.')


if __name__ == '__main__':
    main()
