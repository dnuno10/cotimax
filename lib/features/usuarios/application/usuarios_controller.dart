import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usuariosRepositoryProvider = Provider<UsuariosRepository>((ref) {
  return SupabaseUsuariosRepository(ref.watch(supabaseClientProvider));
});

final usuariosControllerProvider = FutureProvider<List<Usuario>>((ref) async {
  return ref.watch(usuariosRepositoryProvider).getAll();
});
