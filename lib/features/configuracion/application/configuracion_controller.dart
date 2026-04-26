import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final configuracionRepositoryProvider = Provider<ConfiguracionRepository>((
  ref,
) {
  return SupabaseConfiguracionRepository(ref.watch(supabaseClientProvider));
});

final empresaPerfilControllerProvider = FutureProvider<EmpresaPerfil>((
  ref,
) async {
  return ref.watch(configuracionRepositoryProvider).getEmpresa();
});

final usuarioActualControllerProvider = FutureProvider<UsuarioActual>((
  ref,
) async {
  return ref.watch(configuracionRepositoryProvider).getUsuarioActual();
});

final empresasCatalogoControllerProvider =
    FutureProvider<List<EmpresaCatalogItem>>((ref) async {
  return ref.watch(configuracionRepositoryProvider).getEmpresasCatalog();
});
