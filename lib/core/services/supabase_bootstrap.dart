import 'package:cotimax/core/config/backend_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  SupabaseBootstrap._();

  static Future<void> initialize() async {
    if (!BackendConfig.hasSupabase) {
      throw StateError(
        'Supabase no está configurado. Define SUPABASE_URL y SUPABASE_ANON_KEY.',
      );
    }
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      anonKey: BackendConfig.supabaseAnonKey,
    );
  }
}
