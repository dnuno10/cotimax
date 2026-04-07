import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/constants/app_spacing.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/auth/application/auth_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static final Uri _termsUri = Uri.parse(
    'https://cotimax.com/terminos-y-condiciones.html',
  );
  static final Uri _privacyUri = Uri.parse(
    'https://cotimax.com/politica-de-privacidad.html',
  );

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  String _otpCode = '';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final otpSent = auth.otpEmail != null;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ToastHelper.showError(context, next.error!);
      }
      if (next.otpEmail != null &&
          next.otpEmail != previous?.otpEmail &&
          !next.isAuthenticated) {
        ToastHelper.showSuccess(context, 'Código enviado a ${next.otpEmail}.');
      }
      if (next.isAuthenticated) {
        ToastHelper.showSuccess(context, 'Sesión iniciada correctamente.');
        context.go(RoutePaths.workspaceSetup);
      }
    });

    return Scaffold(
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
            child: _Glow(
              size: 220,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: -70,
            bottom: -40,
            child: _Glow(
              size: 240,
              color: AppColors.accent.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radius + 2,
                      ),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.10),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/img/cotimax-logo.png',
                                  height: 52,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Gestión comercial y financiera en un solo lugar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Text(
                              otpSent ? 'Validar código' : 'Iniciar sesión',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              otpSent
                                  ? 'Ingresa el código enviado a tu correo.'
                                  : 'Te enviaremos un código a tu correo.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (!otpSent)
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.go,
                              onFieldSubmitted: auth.isLoading
                                  ? null
                                  : (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Correo',
                                prefixIconConstraints: BoxConstraints(
                                  minWidth: 42,
                                  minHeight: 42,
                                ),
                                prefixIcon: Align(
                                  widthFactor: 1,
                                  heightFactor: 1,
                                  child: FaIcon(
                                    FontAwesomeIcons.envelope,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  (value == null || !value.contains('@'))
                                  ? 'Correo inválido'
                                  : null,
                            ),
                          if (otpSent) ...[
                            const SizedBox(height: 18),
                            const Text(
                              'Correo',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.envelope,
                                    size: 13,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      auth.otpEmail ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const digits = 8;
                                const gap = 6.0;
                                const maxFieldWidth = 46.0;
                                const minFieldWidth = 34.0;
                                final availableWidth =
                                    constraints.maxWidth - (gap * (digits - 1));
                                final fieldWidth = (availableWidth / digits)
                                    .clamp(minFieldWidth, maxFieldWidth);
                                final fieldHeight = (fieldWidth * 1.26).clamp(
                                  46.0,
                                  58.0,
                                );
                                final fontSize = (fieldWidth * 0.42).clamp(
                                  16.0,
                                  20.0,
                                );

                                return PinCodeTextField(
                                  appContext: context,
                                  autoFocus: true,
                                  keyboardType: TextInputType.number,
                                  length: digits,
                                  animationType: AnimationType.fade,
                                  enableActiveFill: true,
                                  autoDisposeControllers: false,
                                  textStyle: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  cursorColor: AppColors.primary,
                                  pastedTextStyle: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  pinTheme: PinTheme(
                                    shape: PinCodeFieldShape.box,
                                    borderRadius: BorderRadius.circular(10),
                                    fieldHeight: fieldHeight,
                                    fieldWidth: fieldWidth,
                                    inactiveColor: AppColors.border,
                                    selectedColor: AppColors.primary,
                                    activeColor: AppColors.primary,
                                    inactiveFillColor: AppColors.white,
                                    selectedFillColor: AppColors.white,
                                    activeFillColor: AppColors.white,
                                  ),
                                  beforeTextPaste: (_) => true,
                                  onChanged: (value) => _otpCode = value,
                                  onCompleted: (_) => _verifyCode(),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : (otpSent ? _verifyCode : _submit),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (auth.isLoading) ...[
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Text(
                                    auth.isLoading
                                        ? (otpSent
                                              ? 'Verificando...'
                                              : 'Enviando código...')
                                        : (otpSent
                                              ? 'Verificar código'
                                              : 'Iniciar sesión'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (otpSent) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _submit(resend: true),
                                child: Text(trText('Reenviar código')),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: auth.isLoading ? null : _changeEmail,
                                child: Text(trText('Cambiar correo')),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  trText('Al continuar aceptas nuestros'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _openLegalUrl(_termsUri),
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(trText('Términos y condiciones')),
                                ),
                                Text(
                                  trText('y'),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _openLegalUrl(_privacyUri),
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(trText('Politica de privacidad')),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit({bool resend = false}) async {
    if (ref.read(authControllerProvider).isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider);
    final email = (resend ? (auth.otpEmail ?? '') : _email.text).trim();
    if (email.isEmpty) {
      ToastHelper.showError(
        context,
        'No se encontró el correo para reenviar el código.',
      );
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestOtp(email);
    if (!resend) {
      _otpCode = '';
    }
    if (resend && ok && mounted) {
      ToastHelper.showSuccess(context, 'Código reenviado a $email.');
    }
  }

  Future<void> _verifyCode() async {
    if (_otpCode.trim().length != 8) return;
    final email = (ref.read(authControllerProvider).otpEmail ?? _email.text)
        .trim();
    if (email.isEmpty) {
      ToastHelper.showError(
        context,
        'No se encontró el correo para validar el código.',
      );
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(email, _otpCode.trim());
  }

  void _changeEmail() {
    _otpCode = '';
    ref.read(authControllerProvider.notifier).resetOtpFlow();
  }

  Future<void> _openLegalUrl(Uri uri) async {
    final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!mounted || opened) return;
    ToastHelper.showError(context, 'No se pudo abrir el enlace.');
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
