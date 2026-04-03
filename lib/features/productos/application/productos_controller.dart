import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productosRepositoryProvider = Provider<ProductosRepository>((ref) {
  return SupabaseProductosRepository(ref.watch(supabaseClientProvider));
});
final productosSearchProvider = StateProvider<String>((ref) => '');

final productosControllerProvider = FutureProvider<List<ProductoServicio>>((
  ref,
) async {
  return ref
      .watch(productosRepositoryProvider)
      .getAll(query: ref.watch(productosSearchProvider));
});
