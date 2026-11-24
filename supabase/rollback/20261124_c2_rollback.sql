-- Shared spaces C2 ROLLBACK (docs/SHARED_SPACES_C2_PLAN.md, "Rollback").
-- NOT a migration: kept outside supabase/migrations so it is never applied by
-- accident. Run only on the owner's decision, after the usual backups, as one
-- transaction (psql -1 / SQL editor), then restore powersync/sync-config.yaml
-- and powersync/publication.sql from before C2 and redeploy them.
--
-- Possible only while no record lives outside a Personal space (true until
-- app 1.3.0 is used): it refuses otherwise and changes nothing. Empty
-- non-Personal spaces are deleted. The C1 rules come back: owner_id required
-- and equal to space_id, and the C1.2 bridge trigger. Tombstones keep a
-- nullable owner_id (the C1 functions only use their space).

do $$
begin
  if exists (select 1 from public.custom_account_types where owner_id is null)
    or exists (select 1 from public.accounts where owner_id is null)
    or exists (select 1 from public.categories where owner_id is null)
    or exists (select 1 from public.transactions where owner_id is null)
    or exists (select 1 from public.monthly_plans where owner_id is null) then
    raise exception 'C2 rollback refused: records exist outside Personal spaces';
  end if;
end;
$$;

delete from public.spaces where personal_of is null;

alter table public.custom_account_types drop constraint custom_account_types_owner_is_personal, alter column owner_id set not null,
  add constraint custom_account_types_owner_is_space check (owner_id = space_id);
alter table public.accounts drop constraint accounts_owner_is_personal, alter column owner_id set not null,
  add constraint accounts_owner_is_space check (owner_id = space_id);
alter table public.categories drop constraint categories_owner_is_personal, alter column owner_id set not null,
  add constraint categories_owner_is_space check (owner_id = space_id);
alter table public.transactions drop constraint transactions_owner_is_personal, alter column owner_id set not null,
  add constraint transactions_owner_is_space check (owner_id = space_id);
alter table public.monthly_plans drop constraint monthly_plans_owner_is_personal, alter column owner_id set not null,
  add constraint monthly_plans_owner_is_space check (owner_id = space_id);

-- The C1.2 bridge trigger, verbatim.
create or replace function fundly_private.bridge_space_owner()
returns trigger language plpgsql security definer set search_path = '' as $$
declare writer uuid := nullif(current_setting('fundly.actor', true), '')::uuid;
begin
  if tg_op = 'INSERT' then
    new.space_id := coalesce(new.space_id, new.owner_id);
    new.owner_id := coalesce(new.owner_id, new.space_id);
    new.created_by := coalesce(new.created_by, writer, new.owner_id);
    new.updated_by := coalesce(new.updated_by, new.created_by);
    if new.space_id = new.owner_id then
      perform fundly_private.ensure_personal_space(new.owner_id);
    end if;
  else
    new.updated_by := coalesce(writer, new.updated_by);
  end if;
  return new;
end;
$$;

drop function public.fundly_create_space(uuid, text);
drop function public.fundly_rename_space(uuid, text, text);
drop function fundly_private.space_wire(public.spaces);
drop function fundly_private.check_space_name(uuid, text, uuid);
drop function fundly_private.space_name(text);
drop function fundly_private.legacy_owner(uuid);
