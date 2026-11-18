"""Real overlapping-session tests against the disposable local database only.

Run from the repo root: python3 supabase/tests/concurrency/write_api_test.py
Requires Docker, the local fundly-schema-dev DB, Dart, and Python stdlib only.
Never reads .env, credentials, or a hosted connection string.
"""

import json
from pathlib import Path
import subprocess
import tempfile
import time
import uuid


COMMAND = [
    'docker', 'exec', '-i', 'supabase_db_fundly-schema-dev', 'psql',
    '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose',
    '-U', 'postgres', '-d', 'postgres',
]


def literal(value):
    return "'" + value.replace("'", "''") + "'"


def execute(sql):
    result = subprocess.run(COMMAND, input=sql, capture_output=True, text=True, timeout=20)
    if result.returncode:
        raise AssertionError(result.stderr)
    return result.stdout.strip()


def rpc(batch, item):
    envelope = json.dumps({'version': 1, 'items': [item]})
    return f'SELECT public.fundly_apply_operations({literal(batch)}::uuid,{literal(envelope)}::jsonb);'


def authenticated(actor, name):
    return (f"SET application_name={literal(name)}; SET statement_timeout='10s'; BEGIN; "
            f"SET LOCAL ROLE authenticated; SELECT set_config('request.jwt.claim.sub',{literal(actor)},true); ")


def decode_result(output):
    return next(json.loads(line) for line in output.splitlines() if line.startswith('{'))


def overlap(actor, first_query, second_actor, second_query, name, expected_error=None, independent=False):
    """First writes and holds its transaction open; second must genuinely wait.

    For different owners, the second must finish while the first is still open.
    No sequential stand-in or timing-only sleep is used to assert overlap.
    """
    first = subprocess.Popen(COMMAND, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, text=True)
    second = None
    try:
        first.stdin.write(authenticated(actor, name + '_first') + first_query + "SELECT 'READY';\n")
        first.stdin.flush()
        lines = []
        while True:
            line = first.stdout.readline()
            if not line:
                raise AssertionError('First session failed: ' + first.stderr.read())
            if line.strip() == 'READY':
                break
            lines.append(line)
        first_result = decode_result(''.join(lines))
        second = subprocess.Popen(COMMAND, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, text=True)
        second.stdin.write(authenticated(second_actor, name + '_second') + second_query + 'COMMIT;\n')
        second.stdin.close()
        second.stdin = None
        if independent:
            second_out, second_error = second.communicate(timeout=5)
            assert second.returncode == 0, second_error
        else:
            deadline = time.monotonic() + 5
            while True:
                waiting = execute('SELECT count(*) FROM pg_stat_activity WHERE '
                                  f'application_name={literal(name + "_second")} '
                                  "AND wait_event_type='Lock' AND wait_event='advisory';")
                if waiting == '1':
                    break
                if second.poll() is not None:
                    raise AssertionError('Second session did not wait on the per-user lock')
                if time.monotonic() > deadline:
                    raise AssertionError('Timed out observing advisory-lock contention')
                time.sleep(0.05)
        first.stdin.write('COMMIT;\n')
        first.stdin.close()
        first.stdin = None
        _, first_error = first.communicate(timeout=5)
        assert first.returncode == 0, first_error
        if not independent:
            second_out, second_error = second.communicate(timeout=5)
        if expected_error:
            assert second.returncode != 0 and expected_error in second_error, second_error
        else:
            assert second.returncode == 0, second_error
        return first_result, None if expected_error else decode_result(second_out)
    finally:
        # Kill only this test's local sessions, even if an assertion failed while
        # a SQL transaction was open. Rollback releases all its locks and writes.
        execute('SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE '
                f'application_name IN ({literal(name + "_first")},{literal(name + "_second")});')
        for process in (first, second):
            if process is not None and process.poll() is None:
                process.kill()
                process.communicate(timeout=5)


def text_contract():
    whitespace = [*range(9, 14), 32, 133, 160, 5760, *range(8192, 8203),
                  8232, 8233, 8239, 8287, 12288, 65279]
    values = [chr(code) + '😀 Café' + chr(code) for code in whitespace]
    values += ['', '😀', 'a\u0301', '\u180e text \u180e', '\u200b text \u200b']
    with tempfile.TemporaryDirectory(prefix='fundly-text-contract-') as scratch:
        script = Path(scratch) / 'contract.dart'
        script.write_text("""import 'dart:convert';
import 'dart:io';
void main() {
  final values = (jsonDecode(stdin.readLineSync()!) as List).cast<String>();
  stdout.write(jsonEncode([for (final s in values)
    {'trimmed': s.trim(), 'length': s.trim().length}]));
}
""")
        dart = subprocess.run(['dart', str(script)], input=json.dumps(values),
                              capture_output=True, text=True, timeout=30, check=True)
    sql_values = literal(json.dumps(values))
    actual = execute("SELECT jsonb_agg(jsonb_build_object('trimmed',fundly_private.trim_text(value),"
                     "'length',fundly_private.utf16_length(fundly_private.trim_text(value))) ORDER BY ordinal) "
                     f'FROM jsonb_array_elements_text({sql_values}::jsonb) WITH ORDINALITY AS t(value,ordinal);')
    assert json.loads(actual) == json.loads(dart.stdout), 'SQL text rules differ from current Dart runtime'
    print(f'PASS: Dart/SQL trim and UTF-16 length agree for {len(values)} samples', flush=True)


def main():
    actor, other, cash, other_cash, category, other_category = [str(uuid.uuid4()) for _ in range(6)]
    run_name = 'fundly_s22a_' + uuid.uuid4().hex[:12]
    owners = f'{literal(actor)}::uuid,{literal(other)}::uuid'

    def create(record_id=None, owner_is_other=False, amount='100'):
        return {'operation': 'transaction.create', 'id': record_id or str(uuid.uuid4()), 'data': {
            'type': 'spending', 'amount_minor': amount, 'date': '2026-11-18', 'payee': 'Concurrency test',
            'source_account_id': other_cash if owner_is_other else cash,
            'category_id': other_category if owner_is_other else category,
        }}

    try:
        execute(f"BEGIN; INSERT INTO auth.users(id,email) VALUES ({literal(actor)},'race-a@example.invalid'),"
                f"({literal(other)},'race-b@example.invalid'); "
                'INSERT INTO public.accounts(id,owner_id,name,type,opening_balance_minor) VALUES '
                f"({literal(cash)},{literal(actor)},'Cash','savingsCash',0),"
                f"({literal(other_cash)},{literal(other)},'Cash','savingsCash',0); "
                'INSERT INTO public.categories(id,owner_id,name,kind) VALUES '
                f"({literal(category)},{literal(actor)},'Food','spending'),"
                f"({literal(other_category)},{literal(other)},'Food','spending'); COMMIT;")

        batch, item = str(uuid.uuid4()), create()
        first, second = overlap(actor, rpc(batch, item), actor, rpc(batch, item), run_name + '_retry')
        assert first == second, 'Concurrent retry did not return the original response'
        assert execute(f'SELECT count(*) FROM public.transactions WHERE id={literal(item["id"])};') == '1'
        print('PASS: overlapping identical batch retries commit exactly once', flush=True)

        batch, item = str(uuid.uuid4()), create()
        changed = json.loads(json.dumps(item))
        changed['data']['amount_minor'] = '200'
        overlap(actor, rpc(batch, item), actor, rpc(batch, changed), run_name + '_key', 'batch_key_reused')
        assert execute(f'SELECT amount_minor FROM public.transactions WHERE id={literal(item["id"])};') == '100'
        print('PASS: overlapping key reuse with changed payload is rejected', flush=True)

        transaction_id = str(uuid.uuid4())
        execute(authenticated(actor, run_name + '_seed') + rpc(str(uuid.uuid4()), create(transaction_id)) + 'COMMIT;')
        update = {'operation': 'transaction.update', 'id': transaction_id,
                  'expected_revision': '1', 'data': {'note': 'first'}}
        competing = {**update, 'data': {'note': 'second'}}
        overlap(actor, rpc(str(uuid.uuid4()), update), actor, rpc(str(uuid.uuid4()), competing),
                run_name + '_revision', 'revision_conflict')
        assert execute(f'SELECT revision::text || note FROM public.transactions WHERE id={literal(transaction_id)};') == '2first'
        print('PASS: overlapping edits with one expected revision have one winner', flush=True)

        batch = str(uuid.uuid4())
        overlap(actor, rpc(batch, create()), other, rpc(batch, create(owner_is_other=True)),
                run_name + '_owners', independent=True)
        assert execute(f'SELECT count(*) FROM public.fundly_write_receipts WHERE batch_id={literal(batch)};') == '2'
        print('PASS: different users can commit independently using the same batch key', flush=True)
        text_contract()
    finally:
        execute(f'BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id IN ({owners}); '
                f'DELETE FROM public.transactions WHERE owner_id IN ({owners}); '
                f'DELETE FROM public.categories WHERE owner_id IN ({owners}); '
                f'DELETE FROM public.accounts WHERE owner_id IN ({owners}); '
                f'DELETE FROM auth.users WHERE id IN ({owners}); COMMIT;')
    print('All 5 concurrency/text-contract checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
