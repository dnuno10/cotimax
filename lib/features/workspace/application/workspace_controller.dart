import 'dart:async';

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
    return WorkspaceStatus(hasCompany: false);
  }
  return ref.watch(workspaceRepositoryProvider).getStatus();
});

final companyInvitationCodeProvider = FutureProvider<CompanyInvitationCode>((
  ref,
) async {
  return ref.watch(workspaceRepositoryProvider).getInvitationCode();
});

final pendingTeamInvitesProvider = FutureProvider<List<TeamMemberInvite>>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) return const <TeamMemberInvite>[];
  return ref.watch(workspaceRepositoryProvider).listMyPendingTeamInvites();
});

final pendingTeamInvitesCountProvider = StreamProvider<int>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return Stream.value(0);
  return client
      .from('empresa_invitaciones_miembros')
      .stream(primaryKey: ['id'])
      .eq('invited_user_id', userId)
      // Supabase stream solo permite 1 filtro (eq/neq/lt/gt...). Filtramos status en memoria.
      .map((rows) => rows.where((row) => row['status'] == 'pendiente').length);
});
