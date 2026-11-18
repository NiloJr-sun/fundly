"""S3 hosted API isolation check, using two disposable test users.

Run from the repository root after the S2 migrations are pushed:

    FUNDLY_TEST_A_EMAIL=... FUNDLY_TEST_A_PASSWORD=... \
    FUNDLY_TEST_B_EMAIL=... FUNDLY_TEST_B_PASSWORD=... \
    python3 tool/cloud_checks/api_isolation.py

Public endpoints come from the ignored tool/sync_probe/config.local.json, or the
file named by FUNDLY_CHECK_CONFIG (used to rehearse against the local stack). Only
the publishable key is used; never pass a service-role key. Credentials and
tokens are never printed. Records created here belong to test user A and are
deleted at the end (their tombstones remain, by design).
"""

import json
import os
from pathlib import Path
import sys
import urllib.error
import urllib.request
import uuid

# FUNDLY_CHECK_CONFIG may point at another config, e.g. a local-stack rehearsal.
CONFIG = Path(os.environ.get('FUNDLY_CHECK_CONFIG') or
              Path(__file__).resolve().parents[1] / 'sync_probe' / 'config.local.json')


def load_config():
    config = json.loads(CONFIG.read_text())
    names = ['FUNDLY_TEST_A_EMAIL', 'FUNDLY_TEST_A_PASSWORD', 'FUNDLY_TEST_B_EMAIL', 'FUNDLY_TEST_B_PASSWORD']
    missing = [name for name in names if not os.environ.get(name)]
    if missing:
        sys.exit('Set ' + ', '.join(missing) + ' (values are never printed).')
    return config['SUPABASE_URL'].rstrip('/'), config['SUPABASE_PUBLISHABLE_KEY']


URL, KEY = load_config()


def request(method, path, token=None, body=None):
    """Returns (HTTP status, decoded JSON or None)."""
    headers = {'apikey': KEY, 'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    data = None if body is None else json.dumps(body).encode()
    call = urllib.request.Request(URL + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(call, timeout=30) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        raw = error.read()
        try:
            return error.code, json.loads(raw) if raw else None
        except ValueError:
            return error.code, None


def sign_in(prefix):
    status, body = request('POST', '/auth/v1/token?grant_type=password', body={
        'email': os.environ[prefix + '_EMAIL'], 'password': os.environ[prefix + '_PASSWORD']})
    assert status == 200, f'{prefix} sign-in failed with HTTP {status}'
    return body['access_token'], body['user']['id']


def rpc(token, *items):
    return request('POST', '/rest/v1/rpc/fundly_apply_operations', token,
                   {'batch_id': str(uuid.uuid4()), 'operations': {'version': 1, 'items': list(items)}})


def denied(result, label):
    status, body = result
    assert status in (401, 403) and (body or {}).get('code') == '42501', f'{label}: HTTP {status} {body}'
    print('PASS:', label, flush=True)


def ids(token, table):
    status, body = request('GET', f'/rest/v1/{table}?select=id', token)
    assert status == 200, f'read {table}: HTTP {status} {body}'
    return {row['id'] for row in body}


TABLES = ['custom_account_types', 'accounts', 'categories', 'transactions', 'monthly_plans']


def main():
    token_a, user_a = sign_in('FUNDLY_TEST_A')
    token_b, user_b = sign_in('FUNDLY_TEST_B')
    assert user_a != user_b, 'Use two different test users'
    print('PASS: both test users signed in with the publishable key', flush=True)

    denied(request('GET', '/rest/v1/accounts?select=id'), 'anonymous table read denied')
    denied(request('POST', '/rest/v1/rpc/fundly_apply_operations',
                   body={'batch_id': str(uuid.uuid4()), 'operations': {'version': 1, 'items': []}}),
           'anonymous RPC denied')
    status, _ = request('GET', '/rest/v1/accounts?select=id', token_a + 'x')
    assert status == 401, f'tampered token: HTTP {status}'
    print('PASS: tampered token rejected', flush=True)

    tag = uuid.uuid4().hex[:8]
    record = {name: str(uuid.uuid4()) for name in ['type', 'account', 'category', 'transaction', 'plan']}
    status, body = rpc(token_a,
        {'operation': 'custom_type.create', 'id': record['type'],
         'data': {'name': f'S3 type {tag}', 'base_type': 'savingsCash'}},
        {'operation': 'account.create', 'id': record['account'],
         'data': {'name': f'S3 cash {tag}', 'type': 'savingsCash', 'entered_opening_amount_minor': '0',
                  'custom_type_id': record['type']}},
        {'operation': 'category.create', 'id': record['category'],
         'data': {'name': f'S3 food {tag}', 'kind': 'spending'}},
        {'operation': 'transaction.create', 'id': record['transaction'],
         'data': {'type': 'spending', 'amount_minor': '100', 'date': '2026-11-18', 'payee': 'S3 check',
                  'source_account_id': record['account'], 'category_id': record['category']}},
        {'operation': 'plan.save', 'id': record['plan'],
         'data': {'category_id': record['category'], 'month': '2026-11', 'target_amount_minor': None,
                  'assigned_amount_minor': '100', 'previous': None}})
    assert status == 200, f'A batch: HTTP {status} {body}'
    print('PASS: A wrote one record to each table through the RPC', flush=True)
    b_category = str(uuid.uuid4())
    status, body = rpc(token_b, {'operation': 'category.create', 'id': b_category,
                                 'data': {'name': f'S3 food {tag}', 'kind': 'spending'}})
    assert status == 200, f'B batch: HTTP {status} {body}'
    print('PASS: B wrote its own category, reusing A\'s name (names are per user)', flush=True)

    try:
        created = dict(zip(TABLES, [record['type'], record['account'], record['category'],
                                    record['transaction'], record['plan']]))
        for table in TABLES:
            seen_a, seen_b = ids(token_a, table), ids(token_b, table)
            assert created[table] in seen_a, f'A cannot read its {table}'
            assert created[table] not in seen_b, f'B can read A\'s {table}'
            assert not seen_a & seen_b, f'{table} rows visible to both users'
        assert b_category in ids(token_b, 'categories'), 'B cannot read its category'
        assert b_category not in ids(token_a, 'categories'), 'A can read B\'s category'
        print('PASS: each user reads only their own rows in all five tables', flush=True)

        status, body = rpc(token_b, {'operation': 'transaction.update', 'id': record['transaction'],
                                     'expected_revision': '1', 'data': {'note': 'B'}})
        assert status >= 400 and (body or {}).get('message') == 'record_not_accessible', f'B edit: {status} {body}'
        assert 'current_revision' not in ((body or {}).get('details') or ''), 'B learned a revision'
        print('PASS: B cannot edit A\'s record or learn its revision', flush=True)

        denied(request('POST', '/rest/v1/transactions', token_a, {'id': str(uuid.uuid4())}), 'direct insert denied')
        denied(request('PATCH', f'/rest/v1/accounts?id=eq.{record["account"]}', token_a, {'name': 'x'}),
               'direct update denied')
        denied(request('DELETE', f'/rest/v1/transactions?id=eq.{record["transaction"]}', token_a),
               'direct delete denied')
        denied(request('GET', '/rest/v1/fundly_write_receipts?select=batch_id', token_a), 'receipts unreadable')
        denied(request('GET', '/rest/v1/fundly_deleted_records?select=id', token_a), 'tombstones unreadable')
        status, _ = request('POST', '/rest/v1/rpc/apply_operation', token_a, {})
        assert status == 404, f'private function reachable: HTTP {status}'
        print('PASS: private functions are not exposed', flush=True)
    finally:
        status, body = rpc(token_a,
            {'operation': 'transaction.delete', 'id': record['transaction'], 'expected_revision': '1'},
            {'operation': 'plan.save', 'id': record['plan'],
             'data': {'category_id': record['category'], 'month': '2026-11', 'target_amount_minor': None,
                      'assigned_amount_minor': '0', 'previous': {'id': record['plan'], 'revision': '1'}}},
            {'operation': 'category.delete', 'id': record['category'], 'expected_revision': '1'},
            {'operation': 'account.set_archived', 'id': record['account'], 'expected_revision': '1',
             'data': {'archived': True}},
            {'operation': 'account.delete', 'id': record['account'], 'expected_revision': '2'},
            {'operation': 'custom_type.delete', 'id': record['type'], 'expected_revision': '1'})
        assert status == 200, f'cleanup: HTTP {status} {body}'
        status, body = rpc(token_b, {'operation': 'category.delete', 'id': b_category, 'expected_revision': '1'})
        assert status == 200, f'B cleanup: HTTP {status} {body}'
    assert b_category not in ids(token_b, 'categories'), 'B cleanup incomplete'
    for table in TABLES:
        assert not ids(token_a, table) & set(record.values()), f'{table} cleanup incomplete'
    print('PASS: check records removed', flush=True)
    print('All API isolation checks passed.', flush=True)


if __name__ == '__main__':
    main()
