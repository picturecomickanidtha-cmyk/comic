-- My Comic Cloud / Supabase setup
-- Run this entire file in Supabase > SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  chapter_count integer not null default 0,
  cover_url text default '',
  chapters jsonb not null default '[]'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists books_created_at_idx on public.books(created_at desc);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles(id,email,display_name,role)
  values(new.id,new.email,coalesce(new.raw_user_meta_data->>'display_name',''), 'student')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.books enable row level security;

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles
for select to authenticated using (id = auth.uid());

drop policy if exists "books public read" on public.books;
create policy "books public read" on public.books
for select to anon, authenticated using (true);

drop policy if exists "books admin insert" on public.books;
create policy "books admin insert" on public.books
for insert to authenticated
with check (exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "books admin update" on public.books;
create policy "books admin update" on public.books
for update to authenticated
using (exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check (exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "books admin delete" on public.books;
create policy "books admin delete" on public.books
for delete to authenticated
using (exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

-- Storage buckets: public read, admin-only uploads/deletes.
insert into storage.buckets (id,name,public)
values ('covers','covers',true),('pdfs','pdfs',true)
on conflict (id) do update set public=true;

drop policy if exists "covers public read" on storage.objects;
create policy "covers public read" on storage.objects
for select to anon, authenticated using (bucket_id='covers');

drop policy if exists "covers admin upload" on storage.objects;
create policy "covers admin upload" on storage.objects
for insert to authenticated
with check (bucket_id='covers' and exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "covers admin update" on storage.objects;
create policy "covers admin update" on storage.objects
for update to authenticated
using (bucket_id='covers' and exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check (bucket_id='covers' and exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "covers admin delete" on storage.objects;
create policy "covers admin delete" on storage.objects
for delete to authenticated
using (bucket_id='covers' and exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "pdfs public read" on storage.objects;
create policy "pdfs public read" on storage.objects
for select to anon, authenticated using (bucket_id='pdfs');

drop policy if exists "pdfs admin upload" on storage.objects;
create policy "pdfs admin upload" on storage.objects
for insert to authenticated
with check (bucket_id='pdfs' and exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "pdfs admin update" on storage.objects;
create policy "pdfs admin update" on storage.objects
for update to authenticated
using (bucket_id='pdfs' and exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check (bucket_id='pdfs' and exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists "pdfs admin delete" on storage.objects;
create policy "pdfs admin delete" on storage.objects
for delete to authenticated
using (bucket_id='pdfs' and exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

-- After creating the teacher account, run this with the teacher's actual Auth UID:
-- update public.profiles set role='admin' where id='PASTE-TEACHER-UID-HERE';
