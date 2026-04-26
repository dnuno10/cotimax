import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recordatoriosRepositoryProvider = Provider<RecordatoriosRepository>((
  ref,
) {
  return SupabaseRecordatoriosRepository(ref.watch(supabaseClientProvider));
});

final recordatoriosControllerProvider = FutureProvider<List<Recordatorio>>((
  ref,
) async {
  return ref.watch(recordatoriosRepositoryProvider).getAll();
});
