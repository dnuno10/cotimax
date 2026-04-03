import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientesRepositoryProvider = Provider<ClientesRepository>((ref) {
  return SupabaseClientesRepository(ref.watch(supabaseClientProvider));
});
final clientesSearchProvider = StateProvider<String>((ref) => '');

final clientesControllerProvider = FutureProvider<List<Cliente>>((ref) async {
  final query = ref.watch(clientesSearchProvider);
  return ref.watch(clientesRepositoryProvider).getAll(query: query);
});
