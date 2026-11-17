"""Create the disposable Auth user from the adjacent ignored .env file.

Run: python3 tool/sync_probe/create_test_user.py
Uses only Python's standard library. Never prints credentials or API bodies.
"""

import json
from pathlib import Path
import shlex
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen


def main():
    settings = {}
    for line in Path(__file__).with_name('.env').read_text().splitlines():
        tokens = shlex.split(line, comments=True)
        if not tokens:
            continue
        if len(tokens) != 1 or '=' not in tokens[0]:
            raise ValueError('Use NAME=value assignments; quote values with spaces.')
        name, value = tokens[0].split('=', 1)
        settings[name] = value

    required = ('SUPABASE_URL', 'SUPABASE_SECRET_KEY', 'TEST_USER_EMAIL', 'TEST_USER_PASSWORD')
    for name in required:
        if not settings.get(name):
            raise ValueError(f'Missing {name} in .env.')
    base = settings['SUPABASE_URL'].rstrip('/')
    parsed = urlsplit(base)
    if parsed.scheme != 'https' or not parsed.hostname or not parsed.hostname.endswith('.supabase.co'):
        raise ValueError('Expected an HTTPS hosted Supabase project URL.')
    if parsed.username or parsed.password or parsed.query or parsed.fragment or parsed.path:
        raise ValueError('Use the project base URL without credentials or a path.')
    secret = settings['SUPABASE_SECRET_KEY']
    headers = {'apikey': secret, 'Content-Type': 'application/json'}
    # New secret keys are handled by the API gateway, not used as bearer JWTs.
    if not secret.startswith('sb_secret_'):
        headers['Authorization'] = f'Bearer {secret}'

    def request(route, payload=None):
        body = None if payload is None else json.dumps(payload).encode()
        req = Request(base + '/auth/v1/' + route, data=body, headers=headers)
        with urlopen(req, timeout=30) as response:
            return json.load(response)

    email = settings['TEST_USER_EMAIL']
    page = 1
    while True:
        users = request(f'admin/users?page={page}&per_page=100').get('users', [])
        if any(user.get('email', '').casefold() == email.casefold() for user in users):
            print(f'Test user {email} already exists; no changes made.')
            return
        if len(users) < 100:
            break
        page += 1
    if len(settings['TEST_USER_PASSWORD']) < 6:
        raise ValueError('Set TEST_USER_PASSWORD to at least 6 characters.')
    user = request('admin/users', {
        'email': email,
        'password': settings['TEST_USER_PASSWORD'],
        'email_confirm': True,
    })
    if not user.get('id') or not user.get('email_confirmed_at'):
        raise ValueError('Unexpected creation result; check Supabase Authentication > Users.')
    print(f'Created test user {email}; email confirmed. No confirmation email sent.')


if __name__ == '__main__':
    try:
        main()
    except HTTPError as error:
        print(f'Supabase returned HTTP {error.code}. Check the admin key and password policy.', file=sys.stderr)
        sys.exit(1)
    except (OSError, ValueError, URLError):
        print('Unable to create user. Check the .env assignments, required values, URL and password (6+ characters).', file=sys.stderr)
        sys.exit(1)
