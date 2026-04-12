import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ingresosRepositoryProvider = Provider<IngresosRepository>((ref) {
  return SupabaseIngresosRepository(ref.watch(supabaseClientProvider));
});

final ingresosControllerProvider = FutureProvider<List<Ingreso>>((ref) async {
  return ref.watch(ingresosRepositoryProvider).getAll();
});

final ingresoCategoriasControllerProvider =
    FutureProvider<List<IngresoCategoria>>((ref) async {
      return ref.watch(ingresosRepositoryProvider).getCategorias();
    });
