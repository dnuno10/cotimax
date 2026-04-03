import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final materialesRepositoryProvider = Provider<MaterialesRepository>((ref) {
  return SupabaseMaterialesRepository(ref.watch(supabaseClientProvider));
});

final materialesSearchProvider = StateProvider<String>((ref) => '');

final materialesControllerProvider = FutureProvider<List<MaterialInsumo>>((
  ref,
) async {
  return ref
      .watch(materialesRepositoryProvider)
      .getAll(query: ref.watch(materialesSearchProvider));
});
