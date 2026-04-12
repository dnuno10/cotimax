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
              return  SectionCard(
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
            final invitation = ref.watch(companyInvitationCodeProvider);
            return invitation.when(
              loading: () =>  SizedBox.shrink(),
              error: (_, __) =>  SizedBox.shrink(),
              data: (code) => SectionCard(
                title: tr('Código de invitación', 'Invitation code'),
                child: Row(
                  children: [
                     Icon(Icons.key_outlined),
                     SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        code.codigo,
                        style:  TextStyle(
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
                      icon:  Icon(Icons.copy_rounded, size: 16),
                      label: Text(tr('Copiar', 'Copy')),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () =>  SizedBox.shrink(),
          error: (_, __) =>  SizedBox.shrink(),
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
