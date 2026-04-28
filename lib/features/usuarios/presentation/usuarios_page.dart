import 'dart:async';

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/features/configuracion/application/configuracion_controller.dart';
import 'package:cotimax/features/planes/application/planes_controller.dart';
import 'package:cotimax/features/usuarios/application/usuarios_controller.dart';
import 'package:cotimax/features/workspace/application/workspace_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
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
    final usuarioActual = ref
        .watch(usuarioActualControllerProvider)
        .valueOrNull;

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

            if (usuarioActual?.rol != UserRole.admin) {
              return SectionCard(
                title: tr('Invitaciones de equipo', 'Team invitations'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textMuted),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr(
                          'Solo los administradores pueden invitar miembros. Pide a un admin que te invite.',
                          'Only admins can invite members. Ask an admin to invite you.',
                        ),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
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
                        'Recuerda: tu equipo no puede exceder los asientos comprados en Stripe.',
                        'Reminder: your team cannot exceed the seats purchased in Stripe.',
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
        plan.when(
          loading: () => SizedBox.shrink(),
          error: (_, __) => SizedBox.shrink(),
          data: (sub) => InviteMemberByEmailCard(
            enabled:
                sub.planId == 'empresa' && usuarioActual?.rol == UserRole.admin,
          ),
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
              DataColumn(label: Text(trText('Principal'))),
            ],
            rows: rows
                .map(
                  (u) => DataRow(
                    cells: [
                      DataCell(
                        Text(u.nombre.trim().isNotEmpty ? u.nombre : u.correo),
                      ),
                      DataCell(Text(u.correo)),
                      DataCell(
                        _MemberRoleCell(
                          member: u,
                          canEdit:
                              (usuarioActual?.rol == UserRole.admin) &&
                              !u.esPrincipal,
                        ),
                      ),
                      DataCell(Text(trText(u.esPrincipal ? 'Si' : 'No'))),
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

class _MemberRoleCell extends ConsumerStatefulWidget {
  const _MemberRoleCell({required this.member, required this.canEdit});

  final CompanyMember member;
  final bool canEdit;

  @override
  ConsumerState<_MemberRoleCell> createState() => _MemberRoleCellState();
}

class _MemberRoleCellState extends ConsumerState<_MemberRoleCell> {
  bool _saving = false;

  Future<void> _setRole(UserRole role) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(usuariosRepositoryProvider)
          .updateMemberRole(userId: widget.member.id, role: role);
      ref.invalidate(usuariosControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(context, trText('Rol actualizado.'));
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo actualizar el rol.'),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canEdit) {
      return Text(userRoleLabel(widget.member.rol));
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<UserRole>(
        value: widget.member.rol,
        onChanged: _saving
            ? null
            : (value) => value == null ? null : unawaited(_setRole(value)),
        items: UserRole.values
            .map(
              (role) => DropdownMenuItem<UserRole>(
                value: role,
                child: Text(userRoleLabel(role)),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class InviteMemberByEmailCard extends ConsumerStatefulWidget {
  const InviteMemberByEmailCard({required this.enabled, super.key});

  final bool enabled;

  @override
  ConsumerState<InviteMemberByEmailCard> createState() =>
      _InviteMemberByEmailCardState();
}

class _InviteMemberByEmailCardState
    extends ConsumerState<InviteMemberByEmailCard> {
  final TextEditingController _emailController = TextEditingController();
  InviteUserCandidate? _candidate;
  bool _searching = false;
  bool _inviting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _searching = true;
      _candidate = null;
    });
    try {
      final user = await ref
          .read(workspaceRepositoryProvider)
          .findUserCandidateForTeamInvite(email);
      if (!mounted) return;
      setState(() => _candidate = user);
      if (user == null) {
        ToastHelper.show(
          context,
          tr(
            'No encontramos un usuario con ese correo.',
            'No user found for that email.',
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo buscar el usuario.'),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _inviting = true);
    try {
      await ref.read(workspaceRepositoryProvider).inviteMemberByEmail(email);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        tr(
          'Invitación enviada. Le aparecerá al usuario en la campana.',
          'Invite sent. The user will see it in the bell.',
        ),
      );
      ref.invalidate(pendingTeamInvitesProvider);
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo enviar la invitación.'),
      );
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: tr('Invitar miembro por correo', 'Invite member by email'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              'Busca por correo y envía una invitación. El invitado la verá en la campana.',
              'Search by email and send an invite. The recipient will see it in the bell.',
            ),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  enabled: widget.enabled && !_inviting && !_searching,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: trText('Correo'),
                    hintText: 'usuario@correo.com',
                  ),
                  onSubmitted: (_) => unawaited(_search()),
                ),
              ),
              SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: widget.enabled && !_searching && !_inviting
                    ? () => unawaited(_search())
                    : null,
                icon: _searching
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.search_rounded, size: 16),
                label: Text(trText('Buscar')),
              ),
              SizedBox(width: 10),
              FilledButton.icon(
                onPressed: widget.enabled && !_inviting && !_searching
                    ? () => unawaited(_invite())
                    : null,
                icon: _inviting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Icon(Icons.send_rounded, size: 16),
                label: Text(trText('Invitar')),
              ),
            ],
          ),
          if (!widget.enabled) ...[
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(
                      'Disponible solo para admins con plan Empresa.',
                      'Only available for admins on the Enterprise plan.',
                    ),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_candidate != null) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _candidate!.nombre.trim().isEmpty
                              ? _candidate!.correo
                              : _candidate!.nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _candidate!.correo,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
