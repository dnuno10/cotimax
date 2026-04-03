import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final planesRepositoryProvider = Provider<PlanesRepository>((ref) {
  return SupabasePlanesRepository(ref.watch(supabaseClientProvider));
});

final planesControllerProvider = FutureProvider<List<Plan>>((ref) async {
  return ref.watch(planesRepositoryProvider).getPlanes();
});

final suscripcionControllerProvider = FutureProvider<Suscripcion>((ref) async {
  return ref.watch(planesRepositoryProvider).getSuscripcion();
});
