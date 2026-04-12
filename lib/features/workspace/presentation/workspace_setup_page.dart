import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/constants/app_spacing.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/platform/logo_picker.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/configuracion/application/configuracion_controller.dart';
import 'package:cotimax/features/workspace/application/workspace_controller.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkspaceSetupPage extends ConsumerStatefulWidget {
   WorkspaceSetupPage({super.key});

  @override
  ConsumerState<WorkspaceSetupPage> createState() => _WorkspaceSetupPageState();
}

class _WorkspaceSetupPageState extends ConsumerState<WorkspaceSetupPage> {
  final _companyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  int _tabIndex = 0;
  bool _isSubmitting = false;
  String _logoDataUrl = '';

  @override
  void dispose() {
    _companyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final selected = await pickLogoDataUrl();
    if (!mounted || selected == null || selected.trim().isEmpty) return;
    setState(() => _logoDataUrl = selected);
  }

  Future<void> _refreshWorkspace() async {
    ref.invalidate(workspaceStatusProvider);
    ref.invalidate(empresaPerfilControllerProvider);
    ref.invalidate(companyInvitationCodeProvider);
    await ref.read(workspaceStatusProvider.future);
  }

  Future<void> _createCompany() async {
    final nombreEmpresa = _companyNameController.text.trim();
    if (nombreEmpresa.isEmpty) {
      ToastHelper.showWarning(context, 'Ingresa el nombre de la empresa.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .createInitialCompany(
            nombreEmpresa: nombreEmpresa,
            logoUrl: _logoDataUrl,
          );
      await _refreshWorkspace();
      if (!mounted) return;
      ToastHelper.showSuccess(context, 'Empresa creada correctamente.');
      context.go(RoutePaths.dashboard);
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo crear la empresa.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _joinCompany() async {
    final code = _inviteCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ToastHelper.showWarning(context, 'Ingresa el código de invitación.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(workspaceRepositoryProvider).joinByInvitationCode(code);
      await _refreshWorkspace();
      if (!mounted) return;
      ToastHelper.showSuccess(context, 'Te uniste al equipo correctamente.');
      context.go(RoutePaths.dashboard);
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudo usar el código de invitación.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(workspaceStatusProvider);
    final isCreateMode = _tabIndex == 0;
    final shellRadius = BorderRadius.circular(AppSpacing.radius + 4);

    ref.listen(workspaceStatusProvider, (previous, next) {
      final status = next.valueOrNull;
      if (status != null && status.hasCompany && mounted) {
        context.go(RoutePaths.dashboard);
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/img/hero.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withValues(alpha: 0.78),
                      AppColors.background.withValues(alpha: 0.90),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -80,
              left: -80,
              child: _WorkspaceGlow(
                size: 220,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: -70,
              bottom: -40,
              child: _WorkspaceGlow(
                size: 240,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints:  BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding:  EdgeInsets.all(18),
                    child: ClipRRect(
                      borderRadius: shellRadius,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.93),
                          borderRadius: shellRadius,
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.10,
                              ),
                              blurRadius: 30,
                              offset:  Offset(0, 16),
                            ),
                          ],
                        ),
                        child: statusAsync.when(
                          loading: () =>  Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => Padding(
                            padding:  EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(
                                    'Configura tu empresa',
                                    'Set up your company',
                                  ),
                                  style:  TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                 SizedBox(height: 12),
                                Text(
                                  tr(
                                    'No se pudo validar el espacio de trabajo. Reintenta para continuar.',
                                    'Could not validate the workspace. Retry to continue.',
                                  ),
                                  style:  TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                 SizedBox(height: 20),
                                FilledButton(
                                  onPressed: () =>
                                      ref.invalidate(workspaceStatusProvider),
                                  child: Text(tr('Reintentar', 'Retry')),
                                ),
                              ],
                            ),
                          ),
                          data: (status) {
                            if (status.hasCompany) {
                              return  SizedBox(
                                height: 220,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked = constraints.maxWidth < 820;
                                final introPanel = _buildIntroPanel(
                                  stacked: stacked,
                                );
                                final formPanel = _buildFormPanel(
                                  isCreateMode: isCreateMode,
                                );

                                if (stacked) {
                                  return SingleChildScrollView(
                                    padding:  EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        introPanel,
                                         SizedBox(height: 18),
                                        formPanel,
                                      ],
                                    ),
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(flex: 9, child: introPanel),
                                    Container(
                                      width: 1,
                                      color: AppColors.border,
                                    ),
                                    Expanded(flex: 11, child: formPanel),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPanel({required bool stacked}) {
    return Container(
      padding:  EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: stacked
            ? BorderRadius.circular(14)
            :  BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.container,
            Color.alphaBlend(
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.background,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(
            Icons.apartment_rounded,
            color: AppColors.primary,
            size: 34,
          ),
           SizedBox(height: 18),
          Text(
            tr('Configura tu empresa', 'Set up your company'),
            style:  TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
           SizedBox(height: 10),
          Text(
            tr(
              'Este paso es obligatorio para activar el espacio de trabajo. Puedes registrar una empresa nueva o vincularte con un equipo existente.',
              'This step is required to activate the workspace. You can create a new company or connect to an existing team.',
            ),
            style:  TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
           SizedBox(height: 24),
          _WorkspaceBullet(
            icon: Icons.verified_user_outlined,
            text: tr(
              'El acceso queda bloqueado hasta terminar la configuración.',
              'Access stays locked until setup is completed.',
            ),
          ),
           SizedBox(height: 12),
          _WorkspaceBullet(
            icon: Icons.badge_outlined,
            text: tr(
              'El código de invitación se usa para unir miembros al equipo.',
              'The invitation code is used to link team members.',
            ),
          ),
           SizedBox(height: 12),
          _WorkspaceBullet(
            icon: Icons.image_outlined,
            text: tr(
              'Puedes cargar el logo desde este mismo paso.',
              'You can upload the logo from this step.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel({required bool isCreateMode}) {
    return Padding(
      padding:  EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Elige cómo continuar', 'Choose how to continue'),
            style:  TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
           SizedBox(height: 14),
          _WorkspaceModeButton(
            label: tr('Crear empresa', 'Create company'),
            description: tr(
              'Registra la empresa principal y comienza desde cero.',
              'Register the main company and start from scratch.',
            ),
            icon: Icons.add_business_rounded,
            selected: isCreateMode,
            fillColor: AppColors.primary,
            onTap: () => setState(() => _tabIndex = 0),
          ),
           SizedBox(height: 10),
          _WorkspaceModeButton(
            label: tr('Unirse por invitación', 'Join by invitation'),
            description: tr(
              'Vincúlate a una empresa existente con un código único.',
              'Connect to an existing company with a unique code.',
            ),
            icon: Icons.key_rounded,
            selected: !isCreateMode,
            fillColor: AppColors.accent,
            onTap: () => setState(() => _tabIndex = 1),
          ),
           SizedBox(height: 22),
          AnimatedSwitcher(
            duration:  Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: isCreateMode ? _buildCreateCard() : _buildJoinCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCard() {
    return Container(
      key:  ValueKey('create-company-card'),
      padding:  EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Nueva empresa', 'New company'),
            style:  TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
           SizedBox(height: 14),
          if (_logoDataUrl.isNotEmpty) ...[
            Center(
              child: Container(
                padding:  EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.network(
                    _logoDataUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>  SizedBox.shrink(),
                  ),
                ),
              ),
            ),
             SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _pickLogo,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              icon:  Icon(Icons.upload_file_rounded),
              label: Text(
                _logoDataUrl.isEmpty
                    ? tr('Cargar logo', 'Upload logo')
                    : tr('Cambiar logo', 'Change logo'),
              ),
            ),
          ),
           SizedBox(height: 16),
          Text(
            tr('Nombre de la empresa', 'Company name'),
            style:  TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
           SizedBox(height: 8),
          TextFormField(
            controller: _companyNameController,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: tr(
                'Escribe el nombre comercial',
                'Enter the trade name',
              ),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _createCompany(),
          ),
           SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _createCompany,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              icon: _isSubmitting
                  ?  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  :  Icon(Icons.add_rounded),
              label: Text(
                _isSubmitting
                    ? tr('Creando...', 'Creating...')
                    : tr('Crear empresa', 'Create company'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard() {
    return Container(
      key:  ValueKey('join-company-card'),
      padding:  EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Código de invitación', 'Invitation code'),
            style:  TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
           SizedBox(height: 14),
          Text(
            tr('Código único del equipo', 'Team invitation code'),
            style:  TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
           SizedBox(height: 8),
          TextFormField(
            controller: _inviteCodeController,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: tr('Ej. TEAM-4F8K2P', 'Example: TEAM-4F8K2P'),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _joinCompany(),
          ),
           SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _joinCompany,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
              ),
              icon: _isSubmitting
                  ?  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  :  Icon(Icons.group_add_rounded),
              label: Text(
                _isSubmitting
                    ? tr('Uniendo...', 'Joining...')
                    : tr('Unirse al equipo', 'Join team'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceModeButton extends StatelessWidget {
   _WorkspaceModeButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.fillColor,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final Color fillColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? fillColor : fillColor.withValues(alpha: 0.08);
    final foreground = selected ? AppColors.white : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration:  Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding:  EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? fillColor : fillColor.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.white : fillColor, size: 22),
             SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                   SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: selected
                          ? AppColors.white.withValues(alpha: 0.92)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceBullet extends StatelessWidget {
   _WorkspaceBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
         SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style:  TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceGlow extends StatelessWidget {
   _WorkspaceGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
