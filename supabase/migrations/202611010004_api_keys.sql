create table public.api_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  key_prefix text not null,
  key_hash text not null unique check (key_hash ~ '^[a-f0-9]{64}$'),
  daily_limit integer not null default 100 check (daily_limit between 1 and 10000),
  requests_today integer not null default 0 check (requests_today >= 0),
  usage_date date not null default current_date,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  revoked_at timestamptz
);
create index api_keys_user_created_idx on public.api_keys(user_id, created_at desc);
alter table public.api_keys enable row level security;
revoke all on public.api_keys from anon, authenticated;
grant select, insert, delete on public.api_keys to authenticated;
create policy "Users read their own API keys" on public.api_keys for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users create their own API keys" on public.api_keys for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users revoke their own API keys" on public.api_keys for delete to authenticated using ((select auth.uid()) = user_id);
create or replace function public.validate_shaxai_api_key(p_key_hash text)
returns table(user_id uuid, allowed boolean)
language plpgsql security definer set search_path = ''
as $$
declare v_key_id uuid; v_user_id uuid;
begin
  select k.id, k.user_id into v_key_id, v_user_id
  from public.api_keys k where k.key_hash = p_key_hash and k.revoked_at is null;
  if v_key_id is null then return query select null::uuid, false; return; end if;
  update public.api_keys k
  set requests_today = case when k.usage_date < current_date then 1 else k.requests_today + 1 end,
      usage_date = current_date, last_used_at = now()
  where k.id = v_key_id and (k.usage_date < current_date or k.requests_today < k.daily_limit);
  if found then return query select v_user_id, true;
  else return query select v_user_id, false; end if;
end;
$$;
revoke all on function public.validate_shaxai_api_key(text) from public;
grant execute on function public.validate_shaxai_api_key(text) to anon, authenticated;