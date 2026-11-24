"""Shared spaces C3.1: membership changes racing each other; local only.

Run: python3 supabase/tests/concurrency/sharing_test.py
Reuses the S2.2A runner: the first session changes membership and holds its
transaction open; the second is observed waiting on the space's lock.
"""

import json
import uuid

from write_api_test import execute, literal, overlap


def as_user(actor, sql):
    return execute(f"BEGIN; SET LOCAL ROLE authenticated; "
                   f"SELECT set_config('request.jwt.claim.sub', {literal(actor)}, true) \\g /dev/null\n"
                   f"{sql} COMMIT;")


def ok(call):
    """[call] (a function returning nothing) as a query printing one JSON line,
    which the shared overlap runner reads."""
    return f"SELECT '{{\"ok\": true}}' FROM (SELECT {call}) done;"


def main():
    owner, second, member, invitee = (str(uuid.uuid4()) for _ in range(4))
    space = str(uuid.uuid4())
    run = 'fundly_c31_' + uuid.uuid4().hex[:12]
    emails = {owner: 'c31-owner', second: 'c31-second', member: 'c31-member', invitee: 'c31-invitee'}
    try:
        execute('INSERT INTO auth.users(id, email) VALUES ' + ', '.join(
            f"({literal(user)}, '{name}@example.invalid')" for user, name in emails.items()) + ';')
        as_user(owner, f"SELECT public.fundly_create_space({literal(space)}, 'Race');")
        execute(f"INSERT INTO public.space_members(space_id, user_id, role) VALUES "
                f"({literal(space)}, {literal(second)}, 'owner'), ({literal(space)}, {literal(member)}, 'editor');")

        secret = json.loads(as_user(owner, f"SELECT public.fundly_create_invite({literal(space)}, "
                                           f"'c31-invitee@example.invalid', 'viewer');"))['secret']
        invite_id = execute(f"SELECT id FROM public.space_invites WHERE space_id = {literal(space)};")
        overlap(owner, ok(f"public.fundly_revoke_invite({literal(invite_id)})"),
                invitee, f"SELECT public.fundly_accept_invite({literal(secret)});",
                run + '_revoke', expected_error='invite_unavailable')
        assert execute(f"SELECT count(*) FROM public.space_members WHERE user_id = {literal(invitee)};") == '0'
        print('PASS: an accept waiting behind a revoke of the same invite is refused; nobody joined', flush=True)

        overlap(owner, ok(f"public.fundly_set_member_role({literal(space)}, {literal(member)}, 'viewer')"),
                second, ok(f"public.fundly_remove_member({literal(space)}, {literal(member)})"),
                run + '_owners')
        assert execute(f"SELECT count(*) FROM public.space_members WHERE user_id = {literal(member)};") == '0'
        print('PASS: two owners changing one member are applied one after the other', flush=True)

        overlap(owner, ok(f"public.fundly_leave_space({literal(space)})"),
                second, ok(f"public.fundly_leave_space({literal(space)})"),
                run + '_last_owner', expected_error='last_owner')
        assert execute(f"SELECT string_agg(user_id::text, ',') FROM public.space_members "
                       f"WHERE space_id = {literal(space)} AND role = 'owner';") == second
        print('PASS: two owners leaving at once: the second is refused, so the space keeps an owner', flush=True)
    finally:
        execute(f"BEGIN; DELETE FROM public.spaces WHERE id = {literal(space)}; "
                f"DELETE FROM public.categories WHERE space_id IN ({', '.join(literal(u) for u in emails)}); "
                f"DELETE FROM public.fundly_deleted_records WHERE space_id IN ({', '.join(literal(u) for u in emails)}); "
                f"DELETE FROM auth.users WHERE id IN ({', '.join(literal(u) for u in emails)}); COMMIT;")
    print('All 3 sharing concurrency checks passed; disposable fixtures removed.', flush=True)


if __name__ == '__main__':
    main()
