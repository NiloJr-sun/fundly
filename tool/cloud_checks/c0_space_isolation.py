"""Shared spaces C0.2 API checks 3, 9 and 10 against the LOCAL C0 environment
(docs/SHARED_SPACES_C0_PLAN.md). Stream checks 1-2 and 4-8 are in
tool/sync_probe/test/c0_space_stream_test.dart.

Run from the repository root after tool/sync_probe/cloud/c0/up.sh:

    set -a; . tool/sync_probe/cloud/c0/.env.local; set +a
    python3 tool/cloud_checks/c0_space_isolation.py

Same configuration, production guard and secrecy rules as
c0_connection_check.py. Every space created here is deleted at the end.
"""

from concurrent.futures import ThreadPoolExecutor
import uuid

from c0_connection_check import USERS, denied, passed, request, rows, sign_in


def apply(token, space, ops, batch_id=None):
    return request('POST', '/rest/v1/rpc/c0_apply_batch', token, {
        'p_batch_id': batch_id or str(uuid.uuid4()), 'p_space_id': space, 'p_ops': ops})


def put(entry, label='C0 entry'):
    return {'op': 'PUT', 'id': entry, 'data': {'label': label, 'amount_minor': '100'}}


def rpc(token, name, **params):
    status, body = request('POST', f'/rest/v1/rpc/{name}', token, params)
    assert status in (200, 204), f'{name}: HTTP {status} {body}'


def entries(token, space):
    status, body = request('GET', f'/rest/v1/c0_entries?select=id,revision,updated_by&space_id=eq.{space}', token)
    assert status == 200, f'read entries: HTTP {status} {body}'
    return {row['id']: row for row in body}


def main():
    (token_a, user_a), (token_b, user_b), (token_c, user_c) = (sign_in(user) for user in USERS)
    space = str(uuid.uuid4())
    rpc(token_a, 'c0_create_space', p_id=space, p_name='C0 API checks')
    try:
        first = str(uuid.uuid4())
        status, body = apply(token_a, space, [put(first)])
        assert status in (200, 204), f'A write: HTTP {status} {body}'

        # 3: an outsider can neither read nor write the space through the API.
        assert space not in rows(token_c, 'c0_spaces')
        assert entries(token_c, space) == {}
        status, body = request('GET', f'/rest/v1/c0_space_members?select=id&space_id=eq.{space}', token_c)
        assert status == 200 and body == [], f'C members: HTTP {status} {body}'
        passed('3: outsider reads nothing from the space (spaces, members, entries)')
        denied(apply(token_c, space, [put(str(uuid.uuid4()))]), '3: outsider write refused')
        denied(request('POST', '/rest/v1/rpc/c0_set_member', token_c,
                       {'p_space': space, 'p_user': user_c, 'p_role': 'owner'}),
               '3: outsider cannot make itself a member')
        status, body = request('POST', '/rest/v1/c0_entries', token_c,
                               {'id': str(uuid.uuid4()), 'space_id': space, 'label': 'x',
                                'amount_minor': 1, 'created_by': user_c, 'updated_by': user_c})
        assert status in (401, 403), f'direct insert: HTTP {status} {body}'
        passed('3: direct table insert refused')

        # 9: the same batch sent twice is applied once.
        rpc(token_a, 'c0_set_member', p_space=space, p_user=user_b, p_role='editor')
        batch, entry = str(uuid.uuid4()), str(uuid.uuid4())
        for _ in range(2):
            status, body = apply(token_b, space, [put(entry, 'Retried')], batch)
            assert status in (200, 204), f'retry: HTTP {status} {body}'
        assert list(entries(token_a, space)).count(entry) == 1
        assert entries(token_a, space)[entry]['revision'] == 1
        passed('9: same batch sent twice is applied once')

        # 10a: two members writing at once: every batch applied.
        jobs = [(token, str(uuid.uuid4())) for token in (token_a, token_b) for _ in range(10)]
        with ThreadPoolExecutor(max_workers=20) as pool:
            results = list(pool.map(lambda job: apply(job[0], space, [put(job[1], 'Concurrent')]), jobs))
        assert all(status in (200, 204) for status, _ in results), results
        stored = entries(token_a, space)
        assert all(entry in stored for _, entry in jobs)
        assert {stored[entry]['updated_by'] for _, entry in jobs} == {user_a, user_b}
        passed('10: 20 concurrent batches from two members all applied, each attributed')

        # 10b: two members editing the same entry from the same revision.
        patch = lambda token, label: apply(token, space, [{
            'op': 'PATCH', 'id': first, 'data': {'label': label}, 'old': {'revision': 1}}])
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda job: patch(*job), [(token_a, 'From A'), (token_b, 'From B')]))
        statuses = sorted(status for status, _ in results)
        codes = [(body or {}).get('code') for status, body in results if status not in (200, 204)]
        assert len([s for s in statuses if s in (200, 204)]) == 1 and codes == ['40001'], results
        assert entries(token_a, space)[first]['revision'] == 2
        passed('10: concurrent edits of one revision: one applied, one refused as a conflict')
    finally:
        rpc(token_a, 'c0_delete_space', p_space=space)
    assert space not in rows(token_a, 'c0_spaces')
    print('C0.2 API checks passed.')


if __name__ == '__main__':
    main()
