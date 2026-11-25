"""Card purchases without a category: rollback rehearsal (R.18).

Run from the repository root against the LOCAL stack only:

    python3 supabase/tests/migration/card_purchases_rollback_test.py

Like the banks rehearsal it does not reset the database: everything runs in
one transaction that is rolled back at the end, so the local data is left as
it was. Inside it, it writes a card purchase without a category and checks a
cash purchase without one is still refused; checks the rollback refuses while
that purchase exists; gives it a category and applies
supabase/rollback/20261127_card_purchases_rollback.sql; checks every record is
unchanged and that a card purchase without a category is refused again (write
API, import and table). Then it applies the migration again and checks such a
purchase is accepted once more.
"""

import subprocess
import sys
from pathlib import Path

CONTAINER = 'supabase_db_fundly-schema-dev'
MIGRATION = Path('supabase/migrations/20261127010000_card_purchases.sql')
ROLLBACK = Path('supabase/rollback/20261127_card_purchases_rollback.sql')
USER = 'a5910000-0000-4000-8000-000000000001'
FRESH = 'b5910000-0000-4000-8000-000000000001'
CASH = '25910000-0000-4000-8000-000000000001'
CARD = '25910000-0000-4000-8000-000000000002'
FOOD = '35910000-0000-4000-8000-000000000001'
PURCHASE = '45910000-0000-4000-8000-000000000001'

SETUP = f"""
\\set ON_ERROR_STOP 1
BEGIN;
INSERT INTO auth.users(id, email) VALUES ('{USER}', 'cp-rollback@example.invalid'),
  ('{FRESH}', 'cp-rollback-fresh@example.invalid');
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
-- Runs a statement and reports its error message, or 'accepted'; never
-- leaves its changes behind.
CREATE FUNCTION pg_temp.attempt(statement text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE statement;
  RAISE EXCEPTION 'accepted';
EXCEPTION WHEN others THEN RETURN sqlerrm;
END;
$$;
CREATE FUNCTION pg_temp.purchase(id text, source text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_array(jsonb_build_object('operation', 'transaction.create', 'id', id,
    'data', jsonb_build_object('type', 'spending', 'amount_minor', '10000', 'date', '2026-11-25',
      'payee', '7/11', 'source_account_id', source)))
$$;
CREATE FUNCTION pg_temp.import_card_purchase(actor uuid) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  PERFORM public.fundly_import_dataset(gen_random_uuid(), jsonb_build_object('version', 1, 'mode', 'into_empty',
    'dataset', jsonb_build_object('custom_account_types', '[]'::jsonb,
      'accounts', jsonb_build_array(
        jsonb_build_object('id', '25910000-0000-4000-8000-000000000009', 'custom_type_id', null,
          'name', 'Card', 'type', 'credit', 'opening_balance_minor', '0', 'currency_code', 'PHP',
          'created_at', '2026-11-01T00:00:00Z', 'is_archived', false, 'is_budget_account', false,
          'bank_key', null, 'custom_bank_id', null)),
      'custom_banks', '[]'::jsonb,
      'categories', jsonb_build_array(
        jsonb_build_object('id', '35910000-0000-4000-8000-000000000009', 'name', 'Card', 'kind', 'spending',
          'is_archived', false, 'is_plan_archived', false, 'is_plan_deleted', false, 'plan_group', 'liability',
          'linked_account_id', '25910000-0000-4000-8000-000000000009', 'default_target_minor', null)),
      'transactions', jsonb_build_array(
        jsonb_build_object('id', '45910000-0000-4000-8000-000000000009', 'type', 'spending',
          'amount_minor', '100', 'currency_code', 'PHP', 'date', '2026-11-25', 'payee', '7/11', 'note', '',
          'category_id', null, 'source_account_id', '25910000-0000-4000-8000-000000000009',
          'destination_account_id', null, 'created_at', '2026-11-25T00:00:00Z',
          'updated_at', '2026-11-25T00:00:00Z')),
      'monthly_plans', '[]'::jsonb)));
  RAISE EXCEPTION 'accepted';
EXCEPTION WHEN others THEN RETURN sqlerrm;
END;
$$;
CREATE FUNCTION pg_temp.fingerprint() RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object(
    'accounts', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), '')) FROM public.accounts t),
    'categories', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), '')) FROM public.categories t),
    'transactions', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), ''))
      FROM public.transactions t),
    'monthly_plans', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), ''))
      FROM public.monthly_plans t))
$$;
CREATE FUNCTION pg_temp.check(passed boolean, label text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  IF passed IS NOT TRUE THEN RAISE EXCEPTION 'FAIL: %', label; END IF;
  RETURN 'PASS: ' || label;
END;
$$;

SELECT pg_temp.write('{USER}', jsonb_build_array(
  jsonb_build_object('operation', 'account.create', 'id', '{CASH}',
    'data', jsonb_build_object('name', 'Wallet', 'type', 'savingsCash', 'entered_opening_amount_minor', '100000')),
  jsonb_build_object('operation', 'account.create', 'id', '{CARD}',
    'data', jsonb_build_object('name', 'Card', 'type', 'credit', 'entered_opening_amount_minor', '0')),
  jsonb_build_object('operation', 'category.create', 'id', '{FOOD}',
    'data', jsonb_build_object('name', 'Food', 'kind', 'spending')))) \\g /dev/null
SELECT pg_temp.check(pg_temp.refusal('{USER}', pg_temp.purchase('{PURCHASE}', '{CARD}')) = 'accepted',
  'a card purchase without a category is accepted');
SELECT pg_temp.check(pg_temp.refusal('{USER}', pg_temp.purchase('45910000-0000-4000-8000-000000000002', '{CASH}'))
  = 'invalid_transaction', 'a cash purchase without a category is still refused');
SELECT pg_temp.check(pg_temp.attempt(convert_from(decode('{ROLLBACK.read_text().encode().hex()}', 'hex'), 'UTF8'))
  LIKE '%give them a category first%', 'the rollback refuses while such a purchase exists');
UPDATE public.transactions SET category_id = '{FOOD}' WHERE id = '{PURCHASE}';
CREATE TEMPORARY TABLE before AS SELECT pg_temp.fingerprint() AS value;
"""

AFTER_ROLLBACK = f"""
SELECT pg_temp.check(pg_temp.fingerprint() = (SELECT value FROM before), 'every record is unchanged');
SELECT pg_temp.check(pg_temp.refusal('{USER}', pg_temp.purchase('45910000-0000-4000-8000-000000000003', '{CARD}'))
  = 'invalid_transaction', 'after the rollback a card purchase needs a category (write API)');
SELECT pg_temp.check(pg_temp.import_card_purchase('{FRESH}') = 'invalid_import',
  'after the rollback a card purchase needs a category (import)');
SELECT pg_temp.check(pg_temp.attempt($$UPDATE public.transactions SET category_id = NULL
    WHERE id = '{PURCHASE}'$$) LIKE '%transactions_shape%',
  'after the rollback a card purchase needs a category (table)');
"""

AFTER_REAPPLY = f"""
SELECT pg_temp.check(pg_temp.refusal('{USER}', pg_temp.purchase('45910000-0000-4000-8000-000000000004', '{CARD}'))
  = 'accepted', 'after applying the migration again, a card purchase without a category is accepted');
SELECT pg_temp.check(pg_temp.import_card_purchase('{FRESH}') = 'accepted',
  'after applying the migration again, an import with one is accepted');
ROLLBACK;
"""


def main():
    script = SETUP + ROLLBACK.read_text() + AFTER_ROLLBACK + MIGRATION.read_text() + AFTER_REAPPLY
    result = subprocess.run(['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres',
                             '-q', '-At'], input=script, capture_output=True, text=True, timeout=300)
    passes = [line for line in result.stdout.splitlines() if line.startswith('PASS: ')]
    for line in passes:
        print(line)
    if result.returncode or len(passes) != 9 or 'ERROR' in result.stderr:
        sys.exit('Rehearsal failed:\n' + result.stderr[-3000:])
    print('Card purchases rollback rehearsal passed; everything was rolled back, the local data is unchanged.')


if __name__ == '__main__':
    main()
