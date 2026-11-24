-- Shared spaces C3 ROLLBACK (docs/SHARED_SPACES_C3_PLAN.md). NOT a migration:
-- kept outside supabase/migrations so it is never applied by accident. Run
-- only on the owner's decision, after the usual backups, as one transaction
-- (psql -1 / SQL editor); then redeploy powersync/sync-config.yaml from before
-- C3 (without the members' email and display_name).
--
-- Removes invites and every sharing RPC, back to the C2 server. Memberships
-- already made by accepting invites stay (no data is removed): members keep
-- seeing and, as editors, writing the spaces they joined; nobody can invite,
-- change roles, remove, leave or delete until C3 is deployed again. The
-- members' email and display_name columns stay, unused.

drop function public.fundly_create_invite(uuid, text, text);
drop function public.fundly_list_invites(uuid);
drop function public.fundly_revoke_invite(uuid);
drop function public.fundly_preview_invite(text);
drop function public.fundly_accept_invite(text);
drop function public.fundly_decline_invite(text);
drop function public.fundly_set_member_role(uuid, uuid, text);
drop function public.fundly_remove_member(uuid, uuid);
drop function public.fundly_leave_space(uuid);
drop function public.fundly_delete_space(uuid, text);
drop function fundly_private.claim_invite(text, uuid);
drop function fundly_private.invite_hash(text);
drop function fundly_private.require_other_owner(uuid, uuid);
drop function fundly_private.manage_space(uuid, uuid, boolean);
drop trigger space_members_profile on public.space_members;
drop function fundly_private.fill_member_profile();
drop table public.space_invites;
