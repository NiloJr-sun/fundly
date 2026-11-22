"""S6.1 timing check: a large import under Supabase's default 8 s limit; local only.

Run: python3 supabase/tests/performance/dataset_import_timing.py [transactions]
Imports one dataset (default 10,000 transactions) as an authenticated user with
statement_timeout = 8s, prints the request size and duration, and removes the
disposable fixtures. A statement timeout fails the check.
"""

import json
from pathlib import Path
import sys
import time
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / 'concurrency'))
from dataset_import_test import cleanup, count, dataset, import_call  # noqa: E402
from write_api_test import execute, literal  # noqa: E402


def main():
    size = int(sys.argv[1]) if len(sys.argv) > 1 else 10000
    actor = str(uuid.uuid4())
    data = dataset(size)
    request_bytes = len(json.dumps({'version': 1, 'mode': 'into_empty', 'dataset': data}).encode())
    try:
        execute(f"INSERT INTO auth.users(id,email) VALUES({literal(actor)},'import-timing@example.invalid');")
        sql = (f"SET statement_timeout='8s'; BEGIN; SET LOCAL ROLE authenticated; "
               f"SELECT set_config('request.jwt.claim.sub',{literal(actor)},true); "
               "SELECT clock_timestamp(); " + import_call(str(uuid.uuid4()), 'into_empty', data)
               + " SELECT clock_timestamp(); COMMIT;")
        started = time.monotonic()
        lines = execute(sql).splitlines()
        wall = time.monotonic() - started
        assert count('transactions', actor) == size, count('transactions', actor)
        server = execute(f"SELECT extract(epoch FROM {literal(lines[-1])}::timestamptz "
                         f"- {literal(lines[1])}::timestamptz);")
        print(f'PASS: imported {size} transactions ({request_bytes / 1_000_000:.1f} MB) in '
              f'{float(server):.2f} s on the server ({wall:.2f} s including the local client)', flush=True)
    finally:
        cleanup([actor])


if __name__ == '__main__':
    main()
