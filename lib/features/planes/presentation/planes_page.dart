import 'dart:async';

import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/platform/url_navigator.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/planes/application/planes_controller.dart';
import 'package:cotimax/features/planes/application/stripe_checkout_service.dart';
import 'package:cotimax/features/planes/presentation/plan_cards.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class PlanesPage extends ConsumerStatefulWidget {
  PlanesPage({super.key});

  @override
  ConsumerState<PlanesPage> createState() => _PlanesPageState();
}

class _PlanesPageState extends ConsumerState<PlanesPage> {
  bool _handledCheckoutRoute = false;

  Future<void> _openStripePortal({
    required Plan plan,
    required String action, // portal | cancel
  }) async {
    try {
      final response = await ref
          .read(stripeCheckoutServiceProvider)
          .createCheckout(plan: plan, action: action);
      final url = Uri.tryParse(response.url);
      if (url == null) {
        throw 'URL inválida.';
      }
      final opened = await navigateToUrl(url.toString());
      if (!opened && mounted) {
        ToastHelper.show(context, 'No se pudo abrir Stripe.');
      }
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo abrir Stripe.'),
      );
    }
  }

  Future<void> _startPlanCheckout({
    required Plan plan,
    required Suscripcion? suscripcion,
  }) async {
    try {
      int? seats;
      if (plan.id == 'empresa') {
        final min = plan.usuariosMinimos > 0 ? plan.usuariosMinimos : 2;
        final max = plan.usuariosMaximos > 0 ? plan.usuariosMaximos : 50;
        final initial = (suscripcion?.usuariosActivos ?? min).clamp(min, max);
        seats = await _promptSeatCount(context, initial: initial, min: min, max: max);
        if (!mounted || seats == null) return;
      }

      final response = await ref
          .read(stripeCheckoutServiceProvider)
          .createCheckout(plan: plan, seats: seats);

      final checkoutUrl = Uri.tryParse(response.url);
      if (checkoutUrl == null) {
        throw 'URL de checkout inválida.';
      }

      final opened = await navigateToUrl(checkoutUrl.toString());
      if (!opened && mounted) {
        ToastHelper.show(context, 'No se pudo abrir el checkout.');
      }
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo iniciar el checkout.'),
      );
    }
  }

  Future<int?> _promptSeatCount(
    BuildContext context, {
    required int initial,
    required int min,
    required int max,
  }) async {
    final controller = TextEditingController(text: '$initial');
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(trText('Asientos del plan Empresa')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    'Selecciona cuántos asientos necesitas (mínimo $min, máximo $max).',
                    'Select how many seats you need (min $min, max $max).',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: trText('Asientos'),
                    hintText: '$min-$max',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(trText('Cancelar')),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < min || value > max) {
                  ToastHelper.show(
                    dialogContext,
                    'Ingresa un número entre $min y $max.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(trText('Continuar')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCheckoutReturn() async {
    if (_handledCheckoutRoute) return;
    _handledCheckoutRoute = true;

    final started = DateTime.now();
    final initial = ref.read(suscripcionControllerProvider).valueOrNull;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        unawaited(() async {
          while (DateTime.now().difference(started).inSeconds < 35) {
            ref.invalidate(suscripcionControllerProvider);
            final current = await ref.read(suscripcionControllerProvider.future).catchError((_) => null);
            if (current != null &&
                (initial == null ||
                    current.planId != initial.planId ||
                    current.updatedAt.isAfter(initial.updatedAt))) {
              break;
            }
            await Future.delayed(const Duration(seconds: 2));
          }
          if (mounted) Navigator.of(dialogContext).pop();
        }());

        return AlertDialog(
          title: Text(trText('Procesando tu compra')),
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  trText('Actualizando tu suscripción...'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    ref.invalidate(suscripcionControllerProvider);
    ToastHelper.showSuccess(context, trText('Suscripción actualizada.'));
    if (mounted) {
      context.go(RoutePaths.planes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planes = ref.watch(planesControllerProvider);
    final suscripcionAsync = ref.watch(suscripcionControllerProvider);
    final activePlanId = suscripcionAsync.valueOrNull?.planId;
    final planesItems = planes.valueOrNull ?? const <Plan>[];
    Plan? activePlan;
    for (final item in planesItems) {
      if (item.id == activePlanId) {
        activePlan = item;
        break;
      }
    }
    final canManageStripe = activePlanId == 'pro' || activePlanId == 'empresa';

    final checkoutStatus =
        GoRouterState.of(context).uri.queryParameters['checkout'];
    if (checkoutStatus == 'success' || checkoutStatus == 'portal') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_handleCheckoutReturn());
      });
    } else {
      _handledCheckoutRoute = false;
    }

    return ListView(
      children: [
        PageHeader(
          title: 'Planes / Suscripcion',
          subtitle:
              'Compara planes, revisa límites y elige la opción ideal para tu equipo.',
        ),
        SizedBox(height: 12),
        suscripcionAsync.when(
          data: (sub) => SectionCard(
            title: 'Plan actual',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PlanBadge(planName: sub.planId.toUpperCase()),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${trText('Estatus')}: ${trText(sub.estado)} · ${tr('Usuarios activos', 'Active users')}: ${sub.usuariosActivos}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (canManageStripe && activePlan != null) ...[
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => unawaited(
                          _openStripePortal(plan: activePlan!, action: 'portal'),
                        ),
                        icon: Icon(Icons.manage_accounts_rounded, size: 16),
                        label: Text(trText('Administrar suscripción')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          unawaited(() async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: Text(trText('Cancelar plan')),
                                  content: Text(
                                    trText(
                                      'Serás redirigido a Stripe para cancelar tu suscripción. ¿Continuar?',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext)
                                          .pop(false),
                                      child: Text(trText('Volver')),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.of(dialogContext)
                                          .pop(true),
                                      child: Text(trText('Continuar')),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (!mounted) return;
                            if (confirm == true) {
                              await _openStripePortal(
                                plan: activePlan!,
                                action: 'cancel',
                              );
                            }
                          }());
                        },
                        icon: Icon(Icons.cancel_rounded, size: 16),
                        label: Text(trText('Cancelar plan')),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          loading: LoadingSkeleton.new,
          error: (_, __) => SizedBox.shrink(),
        ),
        SizedBox(height: 12),
        planes.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No se pudieron cargar planes.',
            onRetry: () => ref.invalidate(planesControllerProvider),
          ),
          data: (items) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1120;
              final suscripcion = suscripcionAsync.valueOrNull;

              Widget buildCard(Plan plan) {
                final canBuy = plan.id == 'pro' || plan.id == 'empresa';
                final isActive = activePlanId == plan.id;
                return PlanFeatureCard(
                  plan: plan,
                  isActive: isActive,
                  onChangePlan: (!canBuy || isActive)
                      ? null
                      : () => unawaited(
                            _startPlanCheckout(
                              plan: plan,
                              suscripcion: suscripcion,
                            ),
                          ),
                );
              }

              if (compact) {
                return Column(
                  children: [
                    for (final plan in items) ...[
                      buildCard(plan),
                      SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      Expanded(child: buildCard(items[index])),
                      if (index < items.length - 1) SizedBox(width: 12),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12),
        SectionCard(
          title: '¿Tu equipo supera los 50 miembros?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Si tu equipo es de más de 50 miembros, escríbenos directamente a support@cotimax.com y te ayudamos con un plan Enterprise a medida.',
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
                label: Text('Escribir a $_supportEmail'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
