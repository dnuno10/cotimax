import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final proveedoresRepositoryProvider = Provider<ProveedoresRepository>((ref) {
  ref.watch(authSessionUserIdProvider);
  return SupabaseProveedoresRepository(ref.watch(supabaseClientProvider));
});

final proveedoresSearchProvider = StateProvider<String>((ref) => '');

final proveedoresControllerProvider = FutureProvider<List<Proveedor>>((
  ref,
) async {
  final query = ref.watch(proveedoresSearchProvider);
  return ref.watch(proveedoresRepositoryProvider).getAll(query: query);
});

final proveedoresCatalogControllerProvider = FutureProvider<List<Proveedor>>((
  ref,
) async {
  return ref.watch(proveedoresRepositoryProvider).getAll();
});
