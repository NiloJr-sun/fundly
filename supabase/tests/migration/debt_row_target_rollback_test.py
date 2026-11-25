"""Default Target on debt rows: rollback rehearsal (2026-11-27).

Run from the repository root against the LOCAL stack only:

    python3 supabase/tests/migration/debt_row_target_rollback_test.py

Like the card purchases rehearsal it does not reset the database: everything
runs in one transaction that is rolled back at the end, so the local data is
left as it was. Inside it, it gives a debt row and an ordinary category a
default Target, applies supabase/rollback/20261127_debt_row_target_rollback.sql
and checks that only the debt row's Target is cleared, every other value is
unchanged, and that a debt row Target is refused again (write API and table).
Then it applies the migration again and checks it is accepted once more.
"""

import subprocess
import sys
from pathlib import Path

CONTAINER = 'supabase_db_fundly-schema-dev'
MIGRATION = Path('supabase/migrations/20261127020000_debt_row_target.sql')
ROLLBACK = Path('supabase/rollback/20261127_debt_row_target_rollback.sql')
USER = 'a5920000-0000-4000-8000-000000000001'
CARD = '25920000-0000-4000-8000-000000000001'
RENT = '35920000-0000-4000-8000-000000000001'

SETUP = f"""
\\set ON_ERROR_STOP 1
BEGIN;
INSERT INTO auth.users(id, email) VALUES ('{USER}', 'drt-rollback@example.invalid');
SELECT fundly_private.ensure_personal_space('{USER}') \\g /dev/null

CREATE FUNCTION pg_temp.refusal(actor uuid, items jsonb) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', actor, 'role', 'authenticated')::text, true);
  PERFORM public.fundly_apply_operations(gen_random_uuid(), jsonb_build_object('version', 1, 'items', items));
  RETURN 'accepted';
EXCEPTION WHEN others THEN RETURN sqlerrm;
END;
$$;
CREATE FUNCTION pg_temp.attempt(statement text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE statement;
  RAISE EXCEPTION 'accepted';
EXCEPTION WHEN others THEN RETURN sqlerrm;
END;
$$;
CREATE FUNCTION pg_temp.debt_row() RETURNS public.categories LANGUAGE sql AS $$
  SELECT c FROM public.categories c WHERE c.linked_account_id = '{CARD}'
$$;
CREATE FUNCTION pg_temp.set_debt_target(minor text) RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_array(jsonb_build_object('operation', 'category.update',
    'id', (pg_temp.debt_row()).id, 'expected_revision', (pg_temp.debt_row()).revision::text,
    'data', jsonb_build_object('default_target_minor', minor)))
$$;
-- Every record, with the debt row's default Target left out.
CREATE FUNCTION pg_temp.fingerprint() RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object(
    'accounts', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, ',' ORDER BY id), '')) FROM public.accounts t),
    'categories', (SELECT md5(coalesce(string_agg(
        (to_jsonb(t) - 'default_target_minor' - 'updated_at' - 'revision')::text
          || coalesce(CASE WHEN t.linked_account_id IS NULL THEN t.default_target_minor END::text, '-'),
        ',' ORDER BY id), '')) FROM public.categories t),
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

SELECT pg_temp.check(pg_temp.refusal('{USER}', jsonb_build_array(
  jsonb_build_object('operation', 'account.create', 'id', '{CARD}',
    'data', jsonb_build_object('name', 'Card', 'type', 'credit', 'entered_opening_amount_minor', '0')),
  jsonb_build_object('operation', 'category.create', 'id', '{RENT}',
    'data', jsonb_build_object('name', 'Rent', 'kind', 'spending', 'default_target_minor', '1500000'))))
  = 'accepted', 'a card and a category with a default Target');
SELECT pg_temp.check(pg_temp.refusal('{USER}', pg_temp.set_debt_target('260750')) = 'accepted',
  'the debt row takes a default Target');
CREATE TEMPORARY TABLE before AS SELECT pg_temp.fingerprint() AS value;
"""

AFTER_ROLLBACK = f"""
SELECT pg_temp.check((pg_temp.debt_row()).default_target_minor IS NULL,
  'the rollback clears the debt row''s default Target');
SELECT pg_temp.check((SELECT default_target_minor FROM public.categories WHERE id = '{RENT}') = 1500000,
  'an ordinary category keeps its default Target');
SELECT pg_temp.check(pg_temp.fingerprint() = (SELECT value FROM before), 'every other value is unchanged');
SELECT pg_temp.check(pg_temp.refusal('{USER}', pg_temp.set_debt_target('100')) = 'managed_category',
  'after the rollback a debt row Target is refused (write API)');
SELECT pg_temp.check(pg_temp.attempt($$UPDATE public.categories SET default_target_minor = 100
    WHERE linked_account_id = '{CARD}'$$) LIKE '%categories_default_target%',
  'after the rollback a debt row Target is refused (table)');
"""

AFTER_REAPPLY = """
SELECT pg_temp.check(pg_temp.refusal('a5920000-0000-4000-8000-000000000001', pg_temp.set_debt_target('100'))
  = 'accepted', 'after applying the migration again, a debt row Target is accepted');
ROLLBACK;
"""

EXPECTED = 8


def main():
    script = SETUP + ROLLBACK.read_text() + AFTER_ROLLBACK + MIGRATION.read_text() + AFTER_REAPPLY
    result = subprocess.run(['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres',
                             '-q', '-At'], input=script, capture_output=True, text=True, timeout=300)
    passes = [line for line in result.stdout.splitlines() if line.startswith('PASS: ')]
    for line in passes:
        print(line)
    if result.returncode or len(passes) != EXPECTED or 'ERROR' in result.stderr:
        sys.exit('Rehearsal failed:\n' + result.stderr[-3000:])
    print('Debt row Target rollback rehearsal passed; everything was rolled back, the local data is unchanged.')


if __name__ == '__main__':
    main()
