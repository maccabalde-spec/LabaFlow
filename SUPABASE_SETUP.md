# LabaFlow backend setup

Supabase is the source of truth for authentication, profiles, roles, loyalty points, and in-app notifications. Firebase is configured only to host the Flutter Web build. The Supabase migration and Edge Functions are deployed to project `ooycccupvxdfpnmqeims`.

## First administrator

Create an account from the app's Register screen (or Supabase Dashboard → Authentication → Users → Add user). In Supabase Dashboard → SQL Editor, promote that account using its email:

```sql
update public.profiles
set role = 'admin'
where email = 'your-admin-email@example.com';
```

The database role enum uses lowercase values: `admin`, `seller`, and `customer`. The app displays uppercase labels automatically. Firebase Auth users are not copied into Supabase; each person needs a Supabase Auth account.

## Hosting the web app

From the repository root, build the Flutter web app and deploy the resulting `flutter_mobile/build/web` directory with Firebase Hosting. `firebase.json` and `.firebaserc` are configured for Firebase project `labaflow-ebaa4`.

## Google sign-in

The sign-in and registration forms support Google OAuth. The Google provider is enabled in Supabase with the `LabaFlow Web` OAuth client. Its authorized redirect URI is `https://ooycccupvxdfpnmqeims.supabase.co/auth/v1/callback`. Supabase's Site URL is `https://labaflow-ebaa4.web.app`; its allowed return URLs are `https://labaflow-ebaa4.web.app/` and `com.labaday.labaflow_mobile://login-callback/`.

After Google returns to the app, the Supabase auth trigger creates the customer profile. The app fills in the Google name, email, and avatar from the signed-in Google identity and shows a Google-connected badge in the profile. Android uses the registered callback scheme in `AndroidManifest.xml`.

## Notifications

The app stores and syncs notifications through Supabase Realtime and the `send-notification` Edge Function. These are in-app notifications. Lock-screen/background push delivery needs a separate push delivery service; Firebase Cloud Messaging has been removed from the app because Firebase is now hosting-only.

## Data currently stored on-device

The existing Flutter and standalone HTML workflows still keep orders, inventory, RFID tags, messages, sales, promo codes, and reviews in local device/browser storage. The Supabase schema currently covers accounts, roles, points, and notifications; those business records are not yet synchronized across devices.
