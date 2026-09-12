/// Supabase credentials from `--dart-define` or defaults for development.
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vjvxfpitlxxfnpvxmkse.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqdnhmcGl0bHh4Zm5wdnhta3NlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkyMDA5NjcsImV4cCI6MjEwNDc3Njk2N30.wia8pM_9Uq1vr7IOSZGNFDuc2bf0UGi2AEOSDdSSAho',
  );

  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR_PROJECT') &&
      !supabaseAnonKey.contains('YOUR_SUPABASE');
}
