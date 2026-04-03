import 'package:cotimax/features/planes/application/planes_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanesPage extends ConsumerWidget {
  const PlanesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planes = ref.watch(planesControllerProvider);
    final suscripcion = ref.watch(suscripcionControllerProvider);

    return ListView(
      children: [
        const PageHeader(
          title: 'Planes / Suscripcion',
          subtitle: 'Pricing interno, comparativa y control de limites.',
        ),
        const SizedBox(height: 12),
        suscripcion.when(
          data: (sub) => SectionCard(
            title: 'Plan actual',
            child: Row(
              children: [
                PlanBadge(planName: sub.planId.toUpperCase()),
                const SizedBox(width: 8),
                Text(
                  'Estado: ${sub.estado} | Usuarios activos: ${sub.usuariosActivos}',
                ),
              ],
            ),
          ),
          loading: LoadingSkeleton.new,
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        planes.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No se pudieron cargar planes.',
            onRetry: () => ref.invalidate(planesControllerProvider),
          ),
          data: (items) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (plan) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SectionCard(
                        title: plan.nombre,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _planPriceLabel(plan),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(plan.descripcion),
                            const SizedBox(height: 10),
                            Text(
                              'Clientes: ${plan.limiteClientes <= 0 ? 'Ilimitados' : plan.limiteClientes}',
                            ),
                            Text(
                              'Productos: ${plan.limiteProductos <= 0 ? 'Ilimitados' : plan.limiteProductos}',
                            ),
                            Text(
                              'Cotizaciones mes: ${plan.limiteCotizacionesMensuales <= 0 ? 'Ilimitadas' : plan.limiteCotizacionesMensuales}',
                            ),
                            Text('Usuarios: ${_userLimitLabel(plan)}'),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                child: const Text('Cambiar plan'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        const SectionCard(
          title: 'Notas de roadmap',
          child: Text('Reportes por usuario: proximamente.'),
        ),
      ],
    );
  }
}

String _planPriceLabel(Plan plan) {
  if (plan.billingMode == 'per_user_monthly') {
    return '\$${plan.precioPorUsuario.toStringAsFixed(0)} / usuario / mes';
  }
  if (plan.precioMensual <= 0) {
    return 'Gratis';
  }
  return '\$${plan.precioMensual.toStringAsFixed(0)} / mes';
}

String _userLimitLabel(Plan plan) {
  if (plan.usuariosMinimos > 0 && plan.usuariosMaximos > 0) {
    return '${plan.usuariosMinimos}-${plan.usuariosMaximos}';
  }
  if (plan.limiteUsuarios <= 0) {
    return 'Ilimitados';
  }
  return '${plan.limiteUsuarios}';
}
