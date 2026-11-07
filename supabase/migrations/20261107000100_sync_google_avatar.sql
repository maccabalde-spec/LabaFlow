-- Clean any placeholder unavatar.io URLs and backfill real Google/Gmail avatars
update public.profiles
set avatar_url = null
where avatar_url ilike '%unavatar.io%';

-- Backfill avatar_url from auth.users raw_user_meta_data or auth.identities identity_data
update public.profiles p
set avatar_url = coalesce(
  (
    select coalesce(
      u.raw_user_meta_data ->> 'avatar_url',
      u.raw_user_meta_data ->> 'picture'
    )
    from auth.users u
    where (u.id = p.id or (p.email <> '' and lower(u.email) = lower(p.email)))
      and coalesce(u.raw_user_meta_data ->> 'avatar_url', u.raw_user_meta_data ->> 'picture') is not null
    limit 1
  ),
  (
    select coalesce(
      i.identity_data ->> 'avatar_url',
      i.identity_data ->> 'picture'
    )
    from auth.identities i
    where (i.user_id = p.id or (p.email <> '' and lower(i.identity_data ->> 'email') = lower(p.email)))
      and coalesce(i.identity_data ->> 'avatar_url', i.identity_data ->> 'picture') is not null
    limit 1
  ),
  p.avatar_url
)
where p.avatar_url is null or p.avatar_url = '';

-- Keep profile avatar_url synced when auth.users metadata updates (e.g. Google OAuth login)
create or replace function public.create_profile_for_auth_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, email, phone, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1), ''),
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture')
  )
  on conflict (id) do update
  set
    email = coalesce(excluded.email, public.profiles.email),
    avatar_url = coalesce(public.profiles.avatar_url, excluded.avatar_url),
    updated_at = now();
  return new;
end;
$$;

create or replace function public.sync_profile_email()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_pic text;
begin
  v_pic := coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture');
  update public.profiles
  set
    email = coalesce(new.email, email, ''),
    avatar_url = case
      when avatar_url is null or avatar_url = '' or avatar_url ilike '%unavatar.io%' then coalesce(v_pic, null)
      else avatar_url
    end,
    updated_at = now()
  where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_updated on auth.users;
create trigger on_auth_user_email_updated
  after update of email, raw_user_meta_data on auth.users
  for each row execute procedure public.sync_profile_email();

-- RPC to fetch or sync a user's real Google avatar from auth.users / auth.identities by uid or email
create or replace function public.sync_my_google_avatar()
returns text
language plpgsql security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_email text;
  v_pic text;
begin
  if v_uid is null then
    return null;
  end if;

  select lower(coalesce(p.email, u.email, ''))
  into v_email
  from auth.users u
  left join public.profiles p on p.id = u.id
  where u.id = v_uid;

  select coalesce(
    u.raw_user_meta_data ->> 'avatar_url',
    u.raw_user_meta_data ->> 'picture'
  )
  into v_pic
  from auth.users u
  where (u.id = v_uid or (v_email <> '' and lower(u.email) = v_email))
    and coalesce(u.raw_user_meta_data ->> 'avatar_url', u.raw_user_meta_data ->> 'picture') is not null
  limit 1;

  if v_pic is null then
    select coalesce(
      i.identity_data ->> 'avatar_url',
      i.identity_data ->> 'picture'
    )
    into v_pic
    from auth.identities i
    where (i.user_id = v_uid or (v_email <> '' and lower(i.identity_data ->> 'email') = v_email))
      and coalesce(i.identity_data ->> 'avatar_url', i.identity_data ->> 'picture') is not null
    limit 1;
  end if;

  if v_pic is not null then
    update public.profiles
    set avatar_url = v_pic, updated_at = now()
    where id = v_uid;
  else
    update public.profiles
    set avatar_url = null, updated_at = now()
    where id = v_uid and avatar_url ilike '%unavatar.io%';
  end if;

  return v_pic;
end;
$$;

grant execute on function public.sync_my_google_avatar() to authenticated;
