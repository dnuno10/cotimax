import 'package:cotimax/core/services/app_repositories.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/features/auth/application/auth_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return SupabaseWorkspaceRepository(ref.watch(supabaseClientProvider));
});

final workspaceStatusProvider = FutureProvider<WorkspaceStatus>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return const WorkspaceStatus(hasCompany: false);
  }
  return ref.watch(workspaceRepositoryProvider).getStatus();
});

final companyInvitationCodeProvider = FutureProvider<CompanyInvitationCode>((
  ref,
) async {
  return ref.watch(workspaceRepositoryProvider).getInvitationCode();
});
