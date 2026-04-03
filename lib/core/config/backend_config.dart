class BackendConfig {
  BackendConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eepbwpngzbdeisyxkhop.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlcGJ3cG5nemJkZWlzeXhraG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyNDAzMzUsImV4cCI6MjA5MDgxNjMzNX0.9PlG8edNCNVP-WM2FGjDSJxevzAO5PYuQovdGgICHs0',
  );
  static const defaultEmpresaId = String.fromEnvironment(
    'DEFAULT_EMPRESA_ID',
    defaultValue: '00000000-0000-0000-0000-000000000001',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
