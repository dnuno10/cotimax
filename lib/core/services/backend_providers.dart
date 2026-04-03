import 'package:cotimax/core/config/backend_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!BackendConfig.hasSupabase) {
    throw StateError(
      'Supabase no está configurado. Define SUPABASE_URL y SUPABASE_ANON_KEY.',
    );
  }
  return Supabase.instance.client;
});
