import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gastosRepositoryProvider = Provider<GastosRepository>((ref) {
  return SupabaseGastosRepository(ref.watch(supabaseClientProvider));
});

final gastosControllerProvider = FutureProvider<List<Gasto>>((ref) async {
  return ref.watch(gastosRepositoryProvider).getAll();
});

final gastoCategoriasControllerProvider = FutureProvider<List<GastoCategoria>>((
  ref,
) async {
  return ref.watch(gastosRepositoryProvider).getCategorias();
});

final gastosRecurrentesControllerProvider =
    FutureProvider<List<GastoRecurrente>>((ref) async {
      return ref.watch(gastosRepositoryProvider).getRecurrentes();
    });
