import 'dart:async';

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/features/configuracion/application/configuracion_controller.dart';
import 'package:cotimax/features/workspace/application/workspace_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeamInvitesDialog extends ConsumerStatefulWidget {
  const TeamInvitesDialog({super.key});

  @override
  ConsumerState<TeamInvitesDialog> createState() => _TeamInvitesDialogState();
}

class _TeamInvitesDialogState extends ConsumerState<TeamInvitesDialog> {
  final Set<String> _busyInviteIds = <String>{};

  Future<void> _respond({
    required TeamMemberInvite invite,
    required bool accept,
  }) async {
    if (_busyInviteIds.contains(invite.id)) return;
    setState(() => _busyInviteIds.add(invite.id));
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .respondToTeamInvite(inviteId: invite.id, accept: accept);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        accept
            ? tr(
                'Invitación aceptada. Ya puedes usar la empresa: ${invite.empresaNombre}.',
                'Invite accepted. You can now use: ${invite.empresaNombre}.',
              )
            : tr('Invitación rechazada.', 'Invite declined.'),
      );
      ref.invalidate(pendingTeamInvitesProvider);
      ref.invalidate(workspaceStatusProvider);
      ref.invalidate(empresasCatalogoControllerProvider);
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo responder la invitación.'),
      );
    } finally {
      if (mounted) {
        setState(() => _busyInviteIds.remove(invite.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(pendingTeamInvitesProvider);

    return AlertDialog(
      title: Text(trText('Notificaciones')),
      content: SizedBox(
        width: 520,
        child: invitesAsync.when(
          loading: () => Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              buildActionErrorMessage(
                error,
                tr(
                  'No se pudieron cargar notificaciones.',
                  'Could not load notifications.',
                ),
              ),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          data: (invites) {
            if (invites.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr(
                          'No tienes notificaciones por ahora.',
                          'No notifications right now.',
                        ),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: invites.length,
              separatorBuilder: (_, __) => Divider(height: 18),
              itemBuilder: (context, index) {
                final invite = invites[index];
                final busy = _busyInviteIds.contains(invite.id);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.group_add_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              'Invitación a ${invite.empresaNombre}',
                              'Invite to ${invite.empresaNombre}',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            tr(
                              'De ${invite.invitedByNombre}',
                              'From ${invite.invitedByNombre}',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => unawaited(
                                        _respond(invite: invite, accept: false),
                                      ),
                                child: busy
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(trText('Rechazar')),
                              ),
                              FilledButton(
                                onPressed: busy
                                    ? null
                                    : () => unawaited(
                                        _respond(invite: invite, accept: true),
                                      ),
                                child: busy
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(trText('Aceptar')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(trText('Cerrar')),
        ),
      ],
    );
  }
}
