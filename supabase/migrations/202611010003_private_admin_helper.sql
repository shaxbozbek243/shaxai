create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create or replace function private.is_shaxai_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.admin_roles where user_id=(select auth.uid())); $$;
revoke all on function private.is_shaxai_admin() from public, anon;
grant execute on function private.is_shaxai_admin() to authenticated;
drop policy if exists "Admins review knowledge" on public.knowledge_entries;
drop policy if exists "Knowledge visible to approved authors and admins" on public.knowledge_entries;
create policy "Public can read approved knowledge" on public.knowledge_entries for select to anon using(status='approved');
create policy "Signed in users can read permitted knowledge" on public.knowledge_entries for select to authenticated using(status='approved' or author_id=(select auth.uid()) or (select private.is_shaxai_admin()));
create policy "Admins review knowledge" on public.knowledge_entries for update to authenticated using((select private.is_shaxai_admin())) with check((select private.is_shaxai_admin()));
drop policy if exists "Users and admins can read role records" on public.admin_roles;
create policy "Users and admins can read role records" on public.admin_roles for select to authenticated using(user_id=(select auth.uid()) or (select private.is_shaxai_admin()));
drop policy if exists "Admins insert role records" on public.admin_roles;
create policy "Admins insert role records" on public.admin_roles for insert to authenticated with check((select private.is_shaxai_admin()));
drop policy if exists "Admins update role records" on public.admin_roles;
create policy "Admins update role records" on public.admin_roles for update to authenticated using((select private.is_shaxai_admin())) with check((select private.is_shaxai_admin()));
drop policy if exists "Admins delete role records" on public.admin_roles;
create policy "Admins delete role records" on public.admin_roles for delete to authenticated using((select private.is_shaxai_admin()));
drop function if exists public.is_shaxai_admin();
