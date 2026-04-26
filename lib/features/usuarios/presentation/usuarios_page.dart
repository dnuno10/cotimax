import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/features/planes/application/planes_controller.dart';
import 'package:cotimax/features/usuarios/application/usuarios_controller.dart';
import 'package:cotimax/features/workspace/application/workspace_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportEmail = 'support@cotimax.com';

Future<void> _contactSupportByEmail(BuildContext context) async {
  final emailUri = Uri(
    scheme: 'mailto',
    path: _supportEmail,
    queryParameters: {'subject': 'Cotimax Enterprise > 50 miembros'},
  );
  final opened = await launchUrl(emailUri);
  if (!opened && context.mounted) {
    ToastHelper.show(
      context,
      'No se pudo abrir tu cliente de correo. Escribe a $_supportEmail.',
    );
  }
}

class UsuariosPage extends ConsumerWidget {
  UsuariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = ref.watch(usuariosControllerProvider);
    final plan = ref.watch(suscripcionControllerProvider);

    return ListView(
      children: [
        PageHeader(
          title: 'Usuarios',
          subtitle: 'Administracion de usuarios, roles y empresas asignadas.',
        ),
        SizedBox(height: 12),
        plan.when(
          data: (sub) {
            if (sub.planId == 'starter' || sub.planId == 'pro') {
              return SectionCard(
                title: 'Bloqueo por plan',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu plan actual limita a 1 usuario. Haz upgrade para gestionar multiusuario.',
                      ),
                    ),
                  ],
                ),
              );
            }

            if (sub.usuariosActivos >= 50) {
              return SectionCard(
                title: tr(
                  'Equipo al límite del plan',
                  'Team plan limit reached',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr(
                              'Tu equipo llegó al límite de 50 miembros en el plan Empresa. Si necesitas más de 50 miembros, escríbenos a support@cotimax.com.',
                              'Your team reached the 50-member Enterprise limit. If you need more than 50 members, email us at support@cotimax.com.',
                            ),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _contactSupportByEmail(context),
                      icon: Icon(Icons.email_rounded, size: 18),
                      label: Text(
                        tr(
                          'Escribir a support@cotimax.com',
                          'Email support@cotimax.com',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final invitation = ref.watch(companyInvitationCodeProvider);
            return invitation.when(
              loading: () => SizedBox.shrink(),
              error: (_, __) => SectionCard(
                title: tr('Invitaciones de equipo', 'Team invitations'),
                child: Text(
                  tr(
                    'No se pudo generar el código de invitación en este momento.',
                    'Could not generate the invitation code right now.',
                  ),
                ),
              ),
              data: (code) => SectionCard(
                title: tr(
                  'Invitaciones de equipo (2 a 50)',
                  'Team invites (2 to 50)',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.key_outlined),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            code.codigo,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: code.codigo),
                            );
                            if (!context.mounted) return;
                            ToastHelper.showSuccess(
                              context,
                              tr(
                                'Código de invitación copiado.',
                                'Invitation code copied.',
                              ),
                            );
                          },
                          icon: Icon(Icons.copy_rounded, size: 16),
                          label: Text(tr('Copiar', 'Copy')),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      tr(
                        'Si tu equipo necesita más de 50 miembros, escríbenos a support@cotimax.com.',
                        'If your team needs more than 50 members, email us at support@cotimax.com.',
                      ),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _contactSupportByEmail(context),
                      icon: Icon(Icons.email_rounded, size: 18),
                      label: Text(
                        tr(
                          'Escribir a support@cotimax.com',
                          'Email support@cotimax.com',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => SizedBox.shrink(),
          error: (_, __) => SizedBox.shrink(),
        ),
        SizedBox(height: 12),
        usuarios.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No se pudieron cargar usuarios.',
            onRetry: () => ref.invalidate(usuariosControllerProvider),
          ),
          data: (rows) => CotimaxDataTable(
            columns: [
              DataColumn(label: Text(trText('Nombre'))),
              DataColumn(label: Text(trText('Correo'))),
              DataColumn(label: Text(trText('Rol'))),
              DataColumn(label: Text(trText('Empresas'))),
              DataColumn(label: Text(trText('Activo'))),
            ],
            rows: rows
                .map(
                  (u) => DataRow(
                    cells: [
                      DataCell(Text(u.nombre)),
                      DataCell(Text(u.correo)),
                      DataCell(
                        Text(
                          trText(u.rol == UserRole.admin ? 'Admin' : 'Usuario'),
                        ),
                      ),
                      DataCell(Text(u.empresaIds.join(', '))),
                      DataCell(Text(trText(u.activo ? 'Si' : 'No'))),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
