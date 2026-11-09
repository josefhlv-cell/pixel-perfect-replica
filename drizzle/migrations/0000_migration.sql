
-- ============ ENUMS ============
create type public.org_role as enum ('owner','admin','member','viewer');
create type public.invitation_status as enum ('pending','accepted','revoked','expired');
create type public.subscription_status as enum ('trialing','active','past_due','canceled','incomplete');
create type public.agent_status as enum ('draft','active','paused','archived');
create type public.call_direction as enum ('inbound','outbound');
create type public.call_status as enum ('queued','ringing','in_progress','completed','failed','no_answer','busy','canceled');
create type public.integration_status as enum ('not_connected','pending','connected','error','disabled');
create type public.workflow_status as enum ('draft','active','paused','archived');
create type public.execution_status as enum ('pending','running','succeeded','failed','canceled');
create type public.phone_number_status as enum ('pending_verification','active','suspended','released');

-- ============ GENERIC HELPERS ============
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin new.updated_at = now(); return new; end; $$;

-- ============ PROFILES ============
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text check (char_length(full_name) <= 120),
  avatar_url text check (char_length(avatar_url) <= 500),
  locale text not null default 'en' check (locale in ('en','cs')),
  timezone text not null default 'UTC' check (char_length(timezone) <= 64),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select, update on public.profiles to authenticated;
grant all on public.profiles to service_role;
alter table public.profiles enable row level security;
create trigger trg_profiles_updated before update on public.profiles for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, left(coalesce(new.raw_user_meta_data->>'full_name',''), 120));
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- ============ ORGANIZATIONS ============
create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{1,62}$'),
  country_code text not null default 'US' check (country_code ~ '^[A-Z]{2}$'),
  default_currency text not null default 'USD' check (default_currency ~ '^[A-Z]{3}$'),
  default_timezone text not null default 'UTC' check (char_length(default_timezone) <= 64),
  default_locale text not null default 'en' check (default_locale in ('en','cs')),
  created_by uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select, update, delete on public.organizations to authenticated;
grant all on public.organizations to service_role;
alter table public.organizations enable row level security;
create trigger trg_org_updated before update on public.organizations for each row execute function public.set_updated_at();

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.org_role not null default 'member',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);
create index idx_members_user on public.organization_members(user_id);
grant select, update, delete on public.organization_members to authenticated;
grant all on public.organization_members to service_role;
alter table public.organization_members enable row level security;
create trigger trg_members_updated before update on public.organization_members for each row execute function public.set_updated_at();

-- Authorization helpers (security definer => no RLS recursion)
create or replace function public.org_role_rank(_r public.org_role)
returns int language sql immutable set search_path = public as $$
  select case _r when 'owner' then 4 when 'admin' then 3 when 'member' then 2 else 1 end $$;

create or replace function public.is_org_member(_org uuid, _user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.organization_members where organization_id = _org and user_id = _user) $$;

create or replace function public.has_org_role(_org uuid, _user uuid, _min public.org_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.organization_members
    where organization_id = _org and user_id = _user
      and public.org_role_rank(role) >= public.org_role_rank(_min)) $$;

create or replace function public.shares_org_with(_other uuid, _user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.organization_members a
    join public.organization_members b on a.organization_id = b.organization_id
    where a.user_id = _user and b.user_id = _other) $$;

revoke execute on function public.is_org_member(uuid,uuid), public.has_org_role(uuid,uuid,public.org_role), public.shares_org_with(uuid,uuid) from anon, public;
grant execute on function public.is_org_member(uuid,uuid), public.has_org_role(uuid,uuid,public.org_role), public.shares_org_with(uuid,uuid) to authenticated, service_role;

-- profiles policies
create policy "profiles: read self or org peers" on public.profiles for select to authenticated
  using (id = auth.uid() or public.shares_org_with(id, auth.uid()));
create policy "profiles: update self" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- organizations policies (insert only through create_organization RPC)
create policy "orgs: members read" on public.organizations for select to authenticated
  using (public.is_org_member(id, auth.uid()));
create policy "orgs: admins update" on public.organizations for update to authenticated
  using (public.has_org_role(id, auth.uid(), 'admin')) with check (public.has_org_role(id, auth.uid(), 'admin'));
create policy "orgs: owners delete" on public.organizations for delete to authenticated
  using (public.has_org_role(id, auth.uid(), 'owner'));

-- members policies (insert only via RPC: create org / accept invitation)
create policy "members: members read" on public.organization_members for select to authenticated
  using (public.is_org_member(organization_id, auth.uid()));
create policy "members: admins update non-owner" on public.organization_members for update to authenticated
  using (public.has_org_role(organization_id, auth.uid(), 'admin') and (role <> 'owner' or public.has_org_role(organization_id, auth.uid(), 'owner')))
  with check (public.has_org_role(organization_id, auth.uid(), 'admin') and (role <> 'owner' or public.has_org_role(organization_id, auth.uid(), 'owner')));
create policy "members: admins remove non-owner or self leave" on public.organization_members for delete to authenticated
  using ((public.has_org_role(organization_id, auth.uid(), 'admin') and role <> 'owner') or (user_id = auth.uid() and role <> 'owner'));

-- protect last owner
create or replace function public.protect_last_owner()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'DELETE' and old.role = 'owner') or (tg_op = 'UPDATE' and old.role = 'owner' and new.role <> 'owner') then
    if (select count(*) from public.organization_members where organization_id = old.organization_id and role = 'owner') <= 1
       and exists (select 1 from public.organizations where id = old.organization_id) then
      raise exception 'Organization must keep at least one owner';
    end if;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end; $$;
create trigger trg_protect_last_owner before update or delete on public.organization_members
  for each row execute function public.protect_last_owner();

-- ============ INVITATIONS ============
create table public.organization_invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 254),
  role public.org_role not null default 'member' check (role <> 'owner'),
  token_hash text not null unique,
  status public.invitation_status not null default 'pending',
  invited_by uuid not null references public.profiles(id) on delete cascade,
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_invites_org on public.organization_invitations(organization_id);
create index idx_invites_email on public.organization_invitations(lower(email));
grant select, insert, update, delete on public.organization_invitations to authenticated;
revoke select (token_hash) on public.organization_invitations from authenticated;
grant all on public.organization_invitations to service_role;
alter table public.organization_invitations enable row level security;
create trigger trg_invites_updated before update on public.organization_invitations for each row execute function public.set_updated_at();
create policy "invites: admins read" on public.organization_invitations for select to authenticated
  using (public.has_org_role(organization_id, auth.uid(), 'admin'));
create policy "invites: admins create" on public.organization_invitations for insert to authenticated
  with check (public.has_org_role(organization_id, auth.uid(), 'admin') and invited_by = auth.uid());
create policy "invites: admins update" on public.organization_invitations for update to authenticated
  using (public.has_org_role(organization_id, auth.uid(), 'admin')) with check (public.has_org_role(organization_id, auth.uid(), 'admin'));
create policy "invites: admins delete" on public.organization_invitations for delete to authenticated
  using (public.has_org_role(organization_id, auth.uid(), 'admin'));

-- ============ SETTINGS ============
create table public.organization_settings (
  organization_id uuid primary key references public.organizations(id) on delete cascade,
  supported_locales text[] not null default array['en'],
  business_hours jsonb not null default '{}'::jsonb,
  data_retention_days int not null default 365 check (data_retention_days between 7 and 3650),
  record_calls boolean not null default false,
  transcribe_calls boolean not null default false,
  allowed_countries text[] not null default array[]::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select, update on public.organization_settings to authenticated;
grant all on public.organization_settings to service_role;
alter table public.organization_settings enable row level security;
create trigger trg_settings_updated before update on public.organization_settings for each row execute function public.set_updated_at();
create policy "settings: members read" on public.organization_settings for select to authenticated
  using (public.is_org_member(organization_id, auth.uid()));
create policy "settings: admins update" on public.organization_settings for update to authenticated
  using (public.has_org_role(organization_id, auth.uid(), 'admin')) with check (public.has_org_role(organization_id, auth.uid(), 'admin'));

-- ============ BILLING ============
create table public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[a-z0-9_]{2,40}$'),
  name text not null,
  description text,
  price_cents int check (price_cents >= 0),
  currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  billing_interval text not null default 'month' check (billing_interval in ('month','year')),
  included_minutes int not null default 0 check (included_minutes >= 0),
  max_agents int not null default 1 check (max_agents >= 0),
  max_phone_numbers int not null default 0 check (max_phone_numbers >= 0),
  max_members int not null default 1 check (max_members >= 1),
  is_public boolean not null default true,
  is_available boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select on public.subscription_plans to authenticated;
grant all on public.subscription_plans to service_role;
alter table public.subscription_plans enable row level security;
create trigger trg_plans_updated before update on public.subscription_plans for each row execute function public.set_updated_at();
create policy "plans: authenticated read public" on public.subscription_plans for select to authenticated using (is_public);

insert into public.subscription_plans (code,name,description,price_cents,included_minutes,max_agents,max_phone_numbers,max_members,is_available) values
 ('free','Free','Foundation workspace. No paid usage.',0,0,1,0,3,true),
 ('growth','Growth','Not yet available — billing provider not connected.',null,0,5,3,10,false),
 ('enterprise','Enterprise','Not yet available — contact sales.',null,0,100,100,500,false);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null unique references public.organizations(id) on delete cascade,
  plan_id uuid not null references public.subscription_plans(id) on delete restrict,
  status public.subscription_status not null default 'active',
  current_period_start timestamptz not null default now(),
  current_period_end timestamptz,
  external_provider text,
  external_subscription_id text,
  cancel_at_period_end boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select on public.subscriptions to authenticated;
grant all on public.subscriptions to service_role;
alter table public.subscriptions enable row level security;
create trigger trg_subs_updated before update on public.subscriptions for each row execute function public.set_updated_at();
create policy "subs: members read" on public.subscriptions for select to authenticated using (public.is_org_member(organization_id, auth.uid()));

create table public.usage_records (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  metric text not null check (metric in ('call_minutes','llm_tokens','tts_characters','stt_seconds','api_requests','workflow_runs')),
  quantity numeric(18,4) not null check (quantity >= 0),
  unit text not null,
  source_type text,
  source_id uuid,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_usage_org_time on public.usage_records(organization_id, occurred_at desc);
grant select on public.usage_records to authenticated;
grant all on public.usage_records to service_role;
alter table public.usage_records enable row level security;
create policy "usage: members read" on public.usage_records for select to authenticated using (public.is_org_member(organization_id, auth.uid()));

-- ============ AUDIT ============
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  actor_id uuid,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_audit_org_time on public.audit_logs(organization_id, created_at desc);
grant select on public.audit_logs to authenticated;
grant all on public.audit_logs to service_role;
alter table public.audit_logs enable row level security;
create policy "audit: admins read" on public.audit_logs for select to authenticated using (public.has_org_role(organization_id, auth.uid(), 'admin'));

create or replace function public.audit_row_change()
returns trigger language plpgsql security definer set search_path = public as $$
declare r record; org uuid; rid uuid;
begin
  if tg_op = 'DELETE' then r := old; else r := new; end if;
  org := (to_jsonb(r)->>'organization_id')::uuid;
  rid := coalesce((to_jsonb(r)->>'id')::uuid, org);
  if org is null and tg_table_name = 'organizations' then org := rid; end if;
  insert into public.audit_logs(organization_id, actor_id, action, entity_type, entity_id, metadata)
  values (case when tg_table_name='organizations' and tg_op='DELETE' then null else org end,
          auth.uid(), lower(tg_op), tg_table_name, rid,
          jsonb_build_object('changed', case when tg_op='UPDATE' then (select coalesce(jsonb_agg(k),'[]'::jsonb) from jsonb_object_keys(to_jsonb(new)) k where to_jsonb(new)->k is distinct from to_jsonb(old)->k and k not in ('updated_at')) else null end));
  return null;
end; $$;

-- ============ API KEYS ============
create table public.api_keys (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  key_prefix text not null check (char_length(key_prefix) between 8 and 20),
  key_hash text not null unique,
  scopes text[] not null default array['read']::text[],
  rate_limit_per_minute int not null default 60 check (rate_limit_per_minute between 1 and 10000),
  created_by uuid not null references public.profiles(id) on delete cascade,
  last_used_at timestamptz,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_api_keys_org on public.api_keys(organization_id);
grant select, insert, update on public.api_keys to authenticated;
revoke select (key_hash) on public.api_keys from authenticated;
grant all on public.api_keys to service_role;
alter table public.api_keys enable row level security;
create trigger trg_api_keys_updated before update on public.api_keys for each row execute function public.set_updated_at();
create policy "api_keys: admins read" on public.api_keys for select to authenticated using (public.has_org_role(organization_id, auth.uid(), 'admin'));
create policy "api_keys: admins create" on public.api_keys for insert to authenticated with check (public.has_org_role(organization_id, auth.uid(), 'admin') and created_by = auth.uid());
create policy "api_keys: admins update" on public.api_keys for update to authenticated using (public.has_org_role(organization_id, auth.uid(), 'admin')) with check (public.has_org_role(organization_id, auth.uid(), 'admin'));

-- ============ INTEGRATIONS ============
create table public.integrations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  provider text not null check (provider ~ '^[a-z0-9_]{2,40}$'),
  category text not null check (category in ('telephony','voice','llm','crm','calendar','messaging','webhook','other')),
  display_name text not null check (char_length(display_name) <= 80),
  status public.integration_status not null default 'not_connected',
  config jsonb not null default '{}'::jsonb,
  secret_ref text,
  connected_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, provider)
);
grant select, insert, update, delete on public.integrations to authenticated;
grant all on public.integrations to service_role;
alter table public.integrations enable row level security;
create trigger trg_integrations_updated before update on public.integrations for each row execute function public.set_updated_at();
create policy "integrations: members read" on public.integrations for select to authenticated using (public.is_org_member(organization_id, auth.uid()));
create policy "integrations: admins insert" on public.integrations for insert to authenticated with check (public.has_org_role(organization_id, auth.uid(), 'admin') and status in ('not_connected','disabled'));
create policy "integrations: admins update" on public.integrations for update to authenticated using (public.has_org_role(organization_id, auth.uid(), 'admin')) with check (public.has_org_role(organization_id, auth.uid(), 'admin') and status in ('not_connected','disabled'));
create policy "integrations: admins delete" on public.integrations for delete to authenticated using (public.has_org_role(organization_id, auth.uid(), 'admin'));

-- ============ AGENTS ============
create table public.agents (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 80),
  description text check (char_length(description) <= 1000),
  status public.agent_status not null default 'draft',
  primary_language text not null default 'en-US' check (primary_language ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  supported_languages text[] not null default array['en-US']::text[],
  timezone text not null default 'UTC',
  voice_provider text not null default 'unassigned' check (voice_provider ~ '^[a-z0-9_]{2,40}$'),
  voice_id text,
  llm_provider text not null default 'unassigned' check (llm_provider ~ '^[a-z0-9_]{2,40}$'),
  llm_model text,
  system_instructions text not null default '' check (char_length(system_instructions) <= 20000),
  greeting_message text not null default '' check (char_length(greeting_message) <= 1000),
  business_info jsonb not null default '{}'::jsonb,
  operating_hours jsonb not null default '{}'::jsonb,
  call_behavior jsonb not null default '{}'::jsonb,
  transfer_rules jsonb not null default '[]'::jsonb,
  current_version int not null default 0,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_agents_org on public.agents(organization_id);
grant select, insert, update, delete on public.agents to authenticated;
grant all on public.agents to service_role;
alter table public.agents enable row level security;
create trigger trg_agents_updated before update on public.agents for each row execute function public.set_updated_at();
create policy "agents: members read" on public.agents for select to authenticated using (public.is_org_member(organization_id, auth.uid()));
create policy "agents: editors insert" on public.agents for insert to authenticated with check (public.has_org_role(organization_id, auth.uid(), 'member'));
create policy "agents: editors update" on public.agents for update to authenticated using (public.has_org_role(organization_id, auth.uid(), 'member')) with check (public.has_org_role(organization_id, auth.uid(), 'member'));
create policy "agents: admins delete" on public.agents for delete to authenticated using (public.has_org_role(organization_id, auth.uid(), 'admin'));

create table public.agent_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  agent_id uuid not null references public.agents(id) on delete cascade,
  version int not null,
  snapshot jsonb not null,
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (agent_id, version)
);
create index idx_agent_versions_agent on public.agent_versions(agent_id, version desc);
grant select on public.agent_versions to authenticated;
grant all on public.agent_versions to service_role;
alter table public.agent_versions enable row level security;
create policy "agent_versions: members read" on public.agent_versions for select to authenticated using (public.is_org_member(organization_id, auth.uid()));

create or replace function public.snapshot_agent_version()
returns trigger language plpgsql security definer set search_path = public as $$
declare snap jsonb;
begin
  snap := to_jsonb(new) - 'current_version' - 'updated_at' - 'created_at';
  if tg_op = 'UPDATE' and (to_jsonb(old) - 'current_version' - 'updated_at' - 'created_at') = snap then
    return new;
  end if;
  new.current_version := coalesce(old.current_version, 0) + 1;
  insert into public.agent_versions(organization_id, agent_id, version, snapshot, created_by)
  values (new.organization_id, new.id, new.current_version, snap, auth.uid());
  return new;
end; $$;
-- Forbid moving rows between orgs
create or replace function public.forbid_org_change()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.organization_id is distinct from old.organization_id then
    raise exception 'organization_id is immutable';
  end if;
  return new;
end; $$;
create trigger trg_agents_org_immutable before update on public.agents for each row execute function public.forbid_org_change();
create trigger trg_agents_version_ins after insert on public.agents for each row execute function public.audit_row_change();

-- version snapshot needs BEFORE trigger to set current_version but agent row must exist for FK on insert -> handle insert in AFTER
create or replace function public.snapshot_agent_version_after_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.agent_versions(organization_id, agent_id, version, snapshot, created_by)
  values (new.organization_id, new.id, 1, to_jsonb(new) - 'current_version' - 'updated_at' - 'created_at', auth.uid());
  update public.agents set current_version = 1 where id = new.id;
  return null;
end; $$;
create or replace function public.snapshot_agent_version_before_update()
returns trigger language plpgsql security definer set search_path = public as $$
declare snap jsonb;
begin
  snap := to_jsonb(new) - 'current_version' - 'updated_at' - 'created_at';
  if (to_jsonb(old) - 'current_version' - 'updated_at' - 'created_at') = snap then
    return new;
  end if;
  new.current_version := old.current_version + 1;
  insert into public.agent_versions(organization_id, agent_id, version, snapshot, created_by)
  values (new.organization_id, new.id, new.current_version, snap, auth.uid());
  return new;
end; $$;
drop function public.snapshot_agent_version();
create trigger trg_agents_snapshot_ins after insert on public.agents for each row execute function public.snapshot_agent_version_after_insert();
create trigger trg_agents_snapshot_upd before update on public.agents for each row execute function public.snapshot_agent_version_before_update();

-- ============ PHONE NUMBERS ============
create table public.phone_numbers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  e164_number text not null unique check (e164_number ~ '^\+[1-9][0-9]{6,14}$'),
  country_code text not null check (country_code ~ '^[A-Z]{2}$'),
  label text check (char_length(label) <= 80),
  provider text not null default 'unassigned',
  provider_number_id text,
  status public.phone_number_status not null default 'pending_verification',
  capabilities text[] not null default array['voice']::text[],
  assigned_agent_id uuid references public.agents(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_phone_org on public.phone_numbers(organization_id);
grant select, update on public.phone_numbers to authenticated;
grant all on public.phone_numbers to service_role;
alter table public.phone_numbers enable row level security;
create trigger trg_phone_updated before update on public.phone_numbers for each row execute function public.set_updated_at();
create trigger trg_phone_org_immutable before update on public.phone_numbers for each row execute function public.forbid_org_change();
create policy "phone: members read" on public.phone_numbers for select to authenticated using (public.is_org_member(organization_id, auth.uid()));
create policy "phone: admins update" on public.phone_numbers for update to authenticated using (public.has_org_role(organization_id, auth.uid(), 'admin')) with check (public.has_org_role(organization_id, auth.uid(), 'admin'));

-- agent assigned to phone must be same org
create or replace function public.check_same_org_refs()
returns trigger language plpgsql set search_path = public as $$
begin
  if tg_table_name = 'phone_numbers' and new.assigned_agent_id is not null then
    if not exists (select 1 from public.agents where id = new.assigned_agent_id and organization_id = new.organization_id) then
      raise exception 'Agent belongs to another organization';
    end if;
  elsif tg_table_name = 'call_sessions' then
    if new.agent_id is not null and not exists (select 1 from public.agents where id = new.agent_id and organization_id = new.organization_id) then
      raise exception 'Agent belongs to another organization'; end if;
    if new.phone_number_id is not null and not exists (select 1 from public.phone_numbers where id = new.phone_number_id and organization_id = new.organization_id) then
      raise exception 'Phone number belongs to another organization'; end if;
  elsif tg_table_name in ('call_events','call_transcripts') then
    if not exists (select 1 from public.call_sessions where id = new.call_session_id and organization_id = new.organization_id) then
      raise exception 'Call session belongs to another organization'; end if;
  elsif tg_table_name = 'workflow_executions' then
    if not exists (select 1 from public.workflows where id = new.workflow_id and organization_id = new.organization_id) then
      raise exception 'Workflow belongs to another organization'; end if;
  end if;
  return new;
end; $$;
create trigger trg_phone_same_org before insert or update on public.phone_numbers for each row execute function public.check_same_org_refs();

-- ============ CALLS ============
create table public.call_sessions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  agent_id uuid references public.agents(id) on delete set null,
  agent_version int,
  phone_number_id uuid references public.phone_numbers(id) on delete set null,
  direction public.call_direction not null,
  status public.call_status not null default 'queued',
  from_number text check (from_number ~ '^\+[1-9][0-9]{6,14}$'),
  to_number text check (to_number ~ '^\+[1-9][0-9]{6,14}$'),
  language text,
  provider text,
  provider_call_id text,
  started_at timestamptz,
  answered_at timestamptz,
  ended_at timestamptz,
  duration_seconds int check (duration_seconds >= 0),
  end_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_calls_org_time on public.call_sessions(organization_id, created_at desc);
create index idx_calls_agent on public.call_sessions(agent_id);
create unique index idx_calls_provider on public.call_sessions(provider, provider_call_id) where provider_call_id is not null;
grant select on public.call_sessions to authenticated;
grant all on public.call_sessions to service_role;
alter table public.call_sessions enable row level security;
create trigger trg_calls_updated before update on public.call_sessions for each row execute function public.set_updated_at();
create trigger trg_calls_same_org before insert or update on public.call_sessions for each row execute function public.check_same_org_refs();
create policy "calls: members read" on public.call_sessions for select to authenticated using (public.is_org_member(organization_id, auth.uid()));

create table public.call_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  call_session_id uuid not null references public.call_sessions(id) on delete cascade,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_call_events_session on public.call_events(call_session_id, occurred_at);
grant select on public.call_events to authenticated;
grant all on public.call_events to service_role;
alter table public.call_events enable row level security;
create trigger trg_call_events_same_org before insert or update on public.call_events for each row execute function public.check_same_org_refs();
create policy "call_events: members read" on public.call_events for select to authenticated using (public.is_org_member(organization_id, auth.uid()));

create table public.call_transcripts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  call_session_id uuid not null references public.call_sessions(id) on delete cascade,
  sequence int not null check (sequence >= 0),
  speaker text not null check (speaker in ('agent','caller','system')),
  content text not null,
  language text,
  start_ms int check (start_ms >= 0),
  end_ms int check (end_ms >= 0),
  confidence numeric(5,4) check (confidence between 0 and 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (call_session_id, sequence)
);
grant select on public.call_transcripts to authenticated;
grant all on public.call_transcripts to service_role;
alter table public.call_transcripts enable row level security;
create trigger trg_transcripts_same_org before insert or update on public.call_transcripts for each row execute function public.check_same_org_refs();
create policy "transcripts: members read" on public.call_transcripts for select to authenticated using (public.is_org_member(organization_id, auth.uid()));

-- ============ WORKFLOWS ============
create table public.workflows (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 80),
  description text check (char_length(description) <= 1000),
  trigger_type text not null check (trigger_type in ('call_completed','call_started','missed_call','manual','schedule','webhook')),
  trigger_config jsonb not null default '{}'::jsonb,
  steps jsonb not null default '[]'::jsonb,
  status public.workflow_status not null default 'draft',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_workflows_org on public.workflows(organization_id);
grant select, insert, update, delete on public.workflows to authenticated;
grant all on public.workflows to service_role;
alter table public.workflows enable row level security;
create trigger trg_workflows_updated before update on public.workflows for each row execute function public.set_updated_at();
create trigger trg_workflows_org_immutable before update on public.workflows for each row execute function public.forbid_org_change();
create policy "workflows: members read" on public.workflows for select to authenticated using (public.is_org_member(organization_id, auth.uid()));
create policy "workflows: editors insert" on public.workflows for insert to authenticated with check (public.has_org_role(organization_id, auth.uid(), 'member'));
create policy "workflows: editors update" on public.workflows for update to authenticated using (public.has_org_role(organization_id, auth.uid(), 'member')) with check (public.has_org_role(organization_id, auth.uid(), 'member'));
create policy "workflows: admins delete" on public.workflows for delete to authenticated using (public.has_org_role(organization_id, auth.uid(), 'admin'));

create table public.workflow_executions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  workflow_id uuid not null references public.workflows(id) on delete cascade,
  call_session_id uuid references public.call_sessions(id) on delete set null,
  status public.execution_status not null default 'pending',
  input jsonb not null default '{}'::jsonb,
  output jsonb,
  error text,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_wf_exec_org on public.workflow_executions(organization_id, created_at desc);
grant select on public.workflow_executions to authenticated;
grant all on public.workflow_executions to service_role;
alter table public.workflow_executions enable row level security;
create trigger trg_wf_exec_updated before update on public.workflow_executions for each row execute function public.set_updated_at();
create trigger trg_wf_exec_same_org before insert or update on public.workflow_executions for each row execute function public.check_same_org_refs();
create policy "wf_exec: members read" on public.workflow_executions for select to authenticated using (public.is_org_member(organization_id, auth.uid()));

-- org_id immutability on other editable tables
create trigger trg_integrations_org_immutable before update on public.integrations for each row execute function public.forbid_org_change();
create trigger trg_api_keys_org_immutable before update on public.api_keys for each row execute function public.forbid_org_change();
create trigger trg_members_org_immutable before update on public.organization_members for each row execute function public.forbid_org_change();
create trigger trg_invites_org_immutable before update on public.organization_invitations for each row execute function public.forbid_org_change();

-- members cannot change own user_id
create or replace function public.forbid_member_user_change()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.user_id is distinct from old.user_id then raise exception 'user_id is immutable'; end if;
  return new;
end; $$;
create trigger trg_members_user_immutable before update on public.organization_members for each row execute function public.forbid_member_user_change();

-- audit triggers
create trigger trg_audit_orgs after update or delete on public.organizations for each row execute function public.audit_row_change();
create trigger trg_audit_members after insert or update or delete on public.organization_members for each row execute function public.audit_row_change();
create trigger trg_audit_invites after insert or update or delete on public.organization_invitations for each row execute function public.audit_row_change();
create trigger trg_audit_settings after update on public.organization_settings for each row execute function public.audit_row_change();
create trigger trg_audit_api_keys after insert or update on public.api_keys for each row execute function public.audit_row_change();
create trigger trg_audit_integrations after insert or update or delete on public.integrations for each row execute function public.audit_row_change();
create trigger trg_audit_agents after update or delete on public.agents for each row execute function public.audit_row_change();
create trigger trg_audit_workflows after insert or update or delete on public.workflows for each row execute function public.audit_row_change();
create trigger trg_audit_phone after insert or update or delete on public.phone_numbers for each row execute function public.audit_row_change();

-- ============ RPCs ============
create or replace function public.create_organization(_name text, _slug text, _country text default 'US', _currency text default 'USD', _timezone text default 'UTC', _locale text default 'en')
returns uuid language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); org_id uuid; free_plan uuid;
begin
  if uid is null then raise exception 'Not authenticated'; end if;
  if (select count(*) from public.organization_members where user_id = uid and role = 'owner') >= 10 then
    raise exception 'Organization limit reached';
  end if;
  insert into public.organizations(name, slug, country_code, default_currency, default_timezone, default_locale, created_by)
  values (trim(_name), lower(trim(_slug)), upper(_country), upper(_currency), _timezone, _locale, uid)
  returning id into org_id;
  insert into public.organization_members(organization_id, user_id, role) values (org_id, uid, 'owner');
  insert into public.organization_settings(organization_id, supported_locales) values (org_id, array[_locale]);
  select id into free_plan from public.subscription_plans where code = 'free';
  insert into public.subscriptions(organization_id, plan_id, status) values (org_id, free_plan, 'active');
  insert into public.audit_logs(organization_id, actor_id, action, entity_type, entity_id) values (org_id, uid, 'insert', 'organizations', org_id);
  return org_id;
end; $$;

create or replace function public.accept_invitation(_token_hash text)
returns uuid language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); inv public.organization_invitations; user_email text;
begin
  if uid is null then raise exception 'Not authenticated'; end if;
  select email into user_email from auth.users where id = uid and email_confirmed_at is not null;
  if user_email is null then raise exception 'Email not verified'; end if;
  select * into inv from public.organization_invitations where token_hash = _token_hash for update;
  if inv.id is null or inv.status <> 'pending' then raise exception 'Invitation not valid'; end if;
  if inv.expires_at < now() then
    update public.organization_invitations set status = 'expired' where id = inv.id;
    raise exception 'Invitation expired';
  end if;
  if lower(inv.email) <> lower(user_email) then raise exception 'Invitation was issued to a different email'; end if;
  insert into public.organization_members(organization_id, user_id, role) values (inv.organization_id, uid, inv.role)
    on conflict (organization_id, user_id) do nothing;
  update public.organization_invitations set status = 'accepted', accepted_at = now() where id = inv.id;
  return inv.organization_id;
end; $$;

revoke execute on function public.create_organization(text,text,text,text,text,text), public.accept_invitation(text) from anon, public;
grant execute on function public.create_organization(text,text,text,text,text,text), public.accept_invitation(text) to authenticated;
revoke execute on function public.handle_new_user(), public.audit_row_change(), public.protect_last_owner(), public.snapshot_agent_version_after_insert(), public.snapshot_agent_version_before_update() from anon, authenticated, public;
