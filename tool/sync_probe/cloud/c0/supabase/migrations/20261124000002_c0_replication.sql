-- Shared spaces C0, local only: replication for the self-hosted PowerSync
-- service. The password is a fixed local-stack value like postgres:postgres;
-- this stack is never exposed beyond the Mac.
create role powersync_role with replication bypassrls login password 'c0-local-powersync';
grant select on public.c0_spaces, public.c0_space_members, public.c0_entries
  to powersync_role;

-- Exactly the three synced tables; c0_receipts is backend only.
create publication powersync for table
  public.c0_spaces,
  public.c0_space_members,
  public.c0_entries;
