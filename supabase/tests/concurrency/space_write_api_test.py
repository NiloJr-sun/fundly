"""Shared spaces C1.2: two members writing one space at once; local only.

Run: python3 supabase/tests/concurrency/space_write_api_test.py
Reuses the S2.2A runner: the first session writes and holds its transaction
open, and the second is observed waiting on the space's advisory lock.
"""

import json
import uuid

from write_api_test import execute, literal, overlap


def write(items, space=None):
    envelope = {'version': 1, 'items': items}
    if space:
        envelope['space_id'] = space
    return (f'SELECT public.fundly_apply_operations({literal(str(uuid.uuid4()))}::uuid,'
            f'{literal(json.dumps(envelope))}::jsonb);')


def category(record, name):
    return {'operation': 'category.create', 'id': record, 'data': {'name': name, 'kind': 'spending'}}


def main():
    owner, editor = str(uuid.uuid4()), str(uuid.uuid4())
    shared = owner  # In C1 records live only in Personal spaces; the editor joins the owner's.
    run_name = 'fundly_c12_' + uuid.uuid4().hex[:12]
    try:
        execute(f"INSERT INTO auth.users(id, email) VALUES ({literal(owner)}, 'c12-race-owner@example.invalid'), "
                f"({literal(editor)}, 'c12-race-editor@example.invalid'); "
                f"SELECT fundly_private.ensure_personal_space({literal(owner)}); "
                f"SELECT fundly_private.ensure_personal_space({literal(editor)}); "
                f"INSERT INTO public.space_members(space_id, user_id, role) "
                f"VALUES ({literal(shared)}, {literal(editor)}, 'editor');")

        first, second = str(uuid.uuid4()), str(uuid.uuid4())
        overlap(owner, write([category(first, 'Owner row')]),
                editor, write([category(second, 'Editor row')], shared), run_name + '_both')
        rows = execute(f'SELECT string_agg(created_by::text, \',\' ORDER BY name) FROM public.categories '
                       f'WHERE space_id = {literal(shared)};')
        assert rows == f'{editor},{owner}', rows
        print('PASS: an editor\'s write waits for the owner\'s open write to the same space, then both apply',
              flush=True)

        update = lambda name: {'operation': 'category.update', 'id': first, 'expected_revision': '1',
                               'data': {'name': name}}
        overlap(owner, write([update('Owner edit')]), editor, write([update('Editor edit')], shared),
                run_name + '_conflict', expected_error='revision_conflict')
        state = execute(f'SELECT name || \',\' || revision || \',\' || updated_by FROM public.categories '
                        f'WHERE id = {literal(first)};')
        assert state == f'Owner edit,2,{owner}', state
        print('PASS: two members editing the same revision: the first applies, the second waits and conflicts',
              flush=True)

        own = str(uuid.uuid4())
        overlap(owner, write([category(str(uuid.uuid4()), 'Owner again')]),
                editor, write([category(own, 'Editor own')]), run_name + '_independent', independent=True)
        assert execute(f'SELECT space_id FROM public.categories WHERE id = {literal(own)};') == editor
        print('PASS: a member\'s write to another space does not wait for this space\'s lock', flush=True)
    finally:
        for user in (owner, editor):
            execute(f'BEGIN; DELETE FROM public.fundly_write_receipts WHERE owner_id={literal(user)}; '
                    f'DELETE FROM public.categories WHERE space_id={literal(user)}; '
                    f'DELETE FROM public.fundly_deleted_records WHERE space_id={literal(user)}; COMMIT;')
        execute(f'DELETE FROM auth.users WHERE id IN ({literal(owner)}, {literal(editor)});')
    print('All 3 space concurrency checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
