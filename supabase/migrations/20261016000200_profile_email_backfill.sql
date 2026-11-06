-- The existing project had profiles before the email column was introduced.
-- Fill it from Supabase Auth so migrated accounts display their actual email.
update public.profiles as profile
set email = coalesce(auth_user.email, '')
from auth.users as auth_user
where auth_user.id = profile.id
  and profile.email = '';
