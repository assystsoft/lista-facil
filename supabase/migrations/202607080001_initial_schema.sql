-- Lista Facil - Supabase initial schema
-- Apply this file in Supabase SQL Editor or through Supabase CLI migrations.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  email text,
  plan text not null default 'free'
    check (plan in ('free', 'premium', 'plus', 'family', 'business')),
  custom_theme text not null default 'orange',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Lista principal',
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists shopping_lists_one_primary_per_owner
  on public.shopping_lists(owner_id)
  where is_primary;

create table if not exists public.shopping_items (
  id text not null,
  list_id uuid not null references public.shopping_lists(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  category text not null default '🛒 Categoria',
  quantity numeric not null default 0,
  done boolean not null default false,
  deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (list_id, id)
);

create index if not exists shopping_items_owner_id_idx
  on public.shopping_items(owner_id);

create index if not exists shopping_items_list_updated_idx
  on public.shopping_items(list_id, updated_at desc);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  icon text not null default '🛒',
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, name)
);

create table if not exists public.purchase_history (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text,
  total_items integer not null default 0,
  completed_items integer not null default 0,
  items jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  name text,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, email)
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger shopping_lists_set_updated_at
  before update on public.shopping_lists
  for each row execute function public.set_updated_at();

create trigger shopping_items_set_updated_at
  before update on public.shopping_items
  for each row execute function public.set_updated_at();

create trigger categories_set_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

create trigger family_members_set_updated_at
  before update on public.family_members
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.shopping_lists enable row level security;
alter table public.shopping_items enable row level security;
alter table public.categories enable row level security;
alter table public.purchase_history enable row level security;
alter table public.family_members enable row level security;

create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "shopping_lists_select_own"
  on public.shopping_lists for select
  using (auth.uid() = owner_id);

create policy "shopping_lists_insert_own"
  on public.shopping_lists for insert
  with check (auth.uid() = owner_id);

create policy "shopping_lists_update_own"
  on public.shopping_lists for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "shopping_lists_delete_own"
  on public.shopping_lists for delete
  using (auth.uid() = owner_id);

create policy "shopping_items_select_own"
  on public.shopping_items for select
  using (auth.uid() = owner_id);

create policy "shopping_items_insert_own"
  on public.shopping_items for insert
  with check (
    auth.uid() = owner_id
    and exists (
      select 1
      from public.shopping_lists lists
      where lists.id = shopping_items.list_id
        and lists.owner_id = auth.uid()
    )
  );

create policy "shopping_items_update_own"
  on public.shopping_items for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "shopping_items_delete_own"
  on public.shopping_items for delete
  using (auth.uid() = owner_id);

create policy "categories_manage_own"
  on public.categories for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "purchase_history_manage_own"
  on public.purchase_history for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "family_members_manage_own"
  on public.family_members for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do nothing;

  insert into public.shopping_lists (owner_id, name, is_primary)
  values (new.id, 'Lista principal', true)
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
