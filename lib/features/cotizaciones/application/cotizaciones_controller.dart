import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cotizacionesRepositoryProvider = Provider<CotizacionesRepository>((ref) {
  return SupabaseCotizacionesRepository(ref.watch(supabaseClientProvider));
});
final cotizacionesSearchProvider = StateProvider<String>((ref) => '');

final cotizacionesControllerProvider = FutureProvider<List<Cotizacion>>((
  ref,
) async {
  return ref
      .watch(cotizacionesRepositoryProvider)
      .getAll(query: ref.watch(cotizacionesSearchProvider));
});

final detalleCotizacionesControllerProvider =
    FutureProvider<List<DetalleCotizacion>>((ref) async {
      return ref.watch(cotizacionesRepositoryProvider).getDetalles();
    });
