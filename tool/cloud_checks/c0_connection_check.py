"""Shared spaces C0.1 connection check for the LOCAL C0 environment.

Run from the repository root after tool/sync_probe/cloud/c0/up.sh:

    set -a; . tool/sync_probe/cloud/c0/.env.local; set +a
    python3 tool/cloud_checks/c0_connection_check.py

Endpoints come from the git-ignored tool/sync_probe/cloud/c0/config.local.json
(written by up.sh), or the file named by C0_CHECK_CONFIG. It refuses to run
against Fundly's production project. Only the publishable key is used.
Credentials and tokens are never printed. The one space it creates is deleted
before it exits.
"""

import json
import os
from pathlib import Path
import sys
import urllib.error
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[2]
CONFIG = Path(os.environ.get('C0_CHECK_CONFIG') or
              ROOT / 'tool' / 'sync_probe' / 'cloud' / 'c0' / 'config.local.json')
PRODUCTION_CONFIG = ROOT / 'tool' / 'sync_probe' / 'config.local.json'
PRODUCTION_REF = 'jiiuukimazvcxautvmya'
USERS = ['C0_TEST_A', 'C0_TEST_B', 'C0_TEST_C']


def load_config():
    config = json.loads(CONFIG.read_text())
    url = config['SUPABASE_URL'].rstrip('/')
    if 'YOUR_' in json.dumps(config):
        sys.exit(f'Fill in {CONFIG.relative_to(ROOT)} first.')
    production = {}
    if PRODUCTION_CONFIG.exists():
        production = json.loads(PRODUCTION_CONFIG.read_text())
    if (PRODUCTION_REF in url
            or url == production.get('SUPABASE_URL', '').rstrip('/')
            or config['POWERSYNC_URL'].rstrip('/') == production.get('POWERSYNC_URL', '').rstrip('/')):
        sys.exit('Refusing: this config points at Fundly production, not the C0 project.')
    missing = [name for user in USERS for name in (user + '_EMAIL', user + '_PASSWORD')
               if not os.environ.get(name)]
    if missing:
        sys.exit('Set ' + ', '.join(missing) + ' (values are never printed).')
    return url, config['SUPABASE_PUBLISHABLE_KEY'], config['POWERSYNC_URL'].rstrip('/')


URL, KEY, POWERSYNC = load_config()


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


def powersync_status(path, token=None):
    headers = {'Authorization': 'Bearer ' + token} if token else {}
    call = urllib.request.Request(POWERSYNC + path, headers=headers)
    try:
        with urllib.request.urlopen(call, timeout=30) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code


def sign_in(prefix):
    status, body = request('POST', '/auth/v1/token?grant_type=password', body={
        'email': os.environ[prefix + '_EMAIL'], 'password': os.environ[prefix + '_PASSWORD']})
    assert status == 200, f'{prefix} sign-in failed with HTTP {status}'
    return body['access_token'], body['user']['id']


def passed(label):
    print('PASS:', label, flush=True)


def denied(result, label):
    status, body = result
    assert status in (401, 403) and (body or {}).get('code') == '42501', f'{label}: HTTP {status} {body}'
    passed(label)


def rows(token, table):
    status, body = request('GET', f'/rest/v1/{table}?select=id', token)
    assert status == 200, f'read {table}: HTTP {status} {body}'
    return {row['id'] for row in body}


def main():
    signed_in = {user: sign_in(user) for user in USERS}
    assert len({user_id for _, user_id in signed_in.values()}) == 3, 'Use three different test users'
    passed('test users A, B and C signed in with the publishable key')
    (token_a, _), (token_b, _), (token_c, _) = (signed_in[user] for user in USERS)

    assert powersync_status('/probes/readiness') == 200, 'PowerSync is not ready'
    checkpoint = '/write-checkpoint2.json?client_id=c0-connection-check'
    assert powersync_status(checkpoint, token_a) == 200, 'PowerSync refused a valid session'
    assert powersync_status(checkpoint, token_a[:-3] + 'abc') == 401, 'PowerSync accepted a tampered token'
    passed('PowerSync is ready, accepts a session and rejects a tampered token')

    denied(request('GET', '/rest/v1/c0_spaces?select=id'), 'anonymous read denied')
    denied(request('GET', '/rest/v1/c0_receipts?select=actor', token_a), 'receipts unreadable')

    space = str(uuid.uuid4())
    status, body = request('POST', '/rest/v1/rpc/c0_create_space', token_a,
                           {'p_id': space, 'p_name': 'C0 connection check'})
    assert status in (200, 204), f'create space: HTTP {status} {body}'
    try:
        assert space in rows(token_a, 'c0_spaces'), 'A cannot see its new space'
        passed('A created a space and reads it')
        for token, name in [(token_b, 'B'), (token_c, 'C')]:
            assert space not in rows(token, 'c0_spaces'), f'{name} can see A\'s space'
        passed('B and C cannot see it')
    finally:
        status, body = request('POST', '/rest/v1/rpc/c0_delete_space', token_a, {'p_space': space})
        assert status in (200, 204), f'delete space: HTTP {status} {body}'
    assert space not in rows(token_a, 'c0_spaces')
    passed('check space deleted')
    print('C0.1 connection check passed.')


if __name__ == '__main__':
    main()
