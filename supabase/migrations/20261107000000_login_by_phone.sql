-- Allow customers to sign in with their mobile number.
-- The web/mobile client looks up the e-mail that belongs to a mobile number,
-- then signs in with e-mail + password. Only the e-mail is returned.
create or replace function public.login_email_for_phone(p_phone text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.email
  from public.profiles p
  where length(regexp_replace(coalesce(p_phone, ''), '\D', '', 'g')) >= 10
    and right(regexp_replace(coalesce(p.phone, ''), '\D', '', 'g'), 10)
        = right(regexp_replace(p_phone, '\D', '', 'g'), 10)
  limit 1;
$$;

revoke all on function public.login_email_for_phone(text) from public;
grant execute on function public.login_email_for_phone(text) to anon, authenticated;
