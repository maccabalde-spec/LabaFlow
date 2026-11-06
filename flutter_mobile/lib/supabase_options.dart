abstract final class LabaFlowSupabaseOptions {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://sesiygonrbthnwjlpggf.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_JeaEwOh7HldE8TTqfeDrnw_26Ph1-CB',
  );

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.startsWith('sb_publishable_');

  static const setupMessage =
      'Supabase is not configured. Add the project URL and publishable key.';
}
