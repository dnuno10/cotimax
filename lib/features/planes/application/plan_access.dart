import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/planes/application/planes_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActivePlanAccess {
  ActivePlanAccess({required this.plan, required this.suscripcion});

  final Plan plan;
  final Suscripcion suscripcion;
}

final activePlanAccessProvider = FutureProvider<ActivePlanAccess>((ref) async {
  final suscripcion = await ref.watch(suscripcionControllerProvider.future);
  final planes = await ref.watch(planesControllerProvider.future);
  final fallbackPlan = planes.isEmpty
      ? Plan(
          id: 'starter',
          nombre: 'Starter',
          precioMensual: 0,
          billingMode: 'flat_monthly',
          precioPorUsuario: 0,
          descripcion: '',
          limiteClientes: 0,
          limiteProductos: 0,
          limiteMateriales: 0,
          limiteCotizacionesMensuales: 0,
          limiteUsuarios: 1,
          limiteEmpresas: 1,
          usuariosMinimos: 0,
          usuariosMaximos: 0,
          incluyeIngresosGastos: false,
          incluyeDashboard: true,
          incluyeAnalitica: false,
          incluyePersonalizacionPdf: false,
          incluyeNotasPrivadas: false,
          incluyeEstadosCotizacion: false,
          incluyeMarcaAgua: true,
          activo: true,
        )
      : planes.first;
  Plan? plan;
  for (final item in planes) {
    if (item.id == suscripcion.planId) {
      plan = item;
      break;
    }
  }
  return ActivePlanAccess(plan: plan ?? fallbackPlan, suscripcion: suscripcion);
});

({DateTime start, DateTime end}) monthlyQuoteWindow(DateTime anchor) {
  final now = DateTime.now();
  var start = DateTime(anchor.year, anchor.month, anchor.day);

  while (!_isSameOrBefore(now, _nextMonthlyAnchor(start))) {
    start = _nextMonthlyAnchor(start);
  }

  return (start: start, end: _nextMonthlyAnchor(start));
}

int monthlyQuoteUsage(Iterable<Cotizacion> quotes, DateTime anchor) {
  final window = monthlyQuoteWindow(anchor);
  return quotes.where((quote) {
    return !quote.fechaEmision.isBefore(window.start) &&
        quote.fechaEmision.isBefore(window.end);
  }).length;
}

bool hasReachedPlanLimit({
  required int limit,
  required int used,
}) {
  return limit >= 0 && used >= limit;
}

Future<void> showPlanUpgradeDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final goToPlans = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('Ver planes'),
          ),
        ],
      );
    },
  );

  if (goToPlans == true && context.mounted) {
    context.go(RoutePaths.planes);
  }
}

Future<void> showAnalyticsUpgradeDialog(BuildContext context) {
  return showPlanUpgradeDialog(
    context,
    title: 'Analítica disponible en Pro',
    message:
        'Necesitas el plan Pro o Empresa para acceder a Analítica.',
  );
}

DateTime _nextMonthlyAnchor(DateTime source) {
  final targetMonthDate = DateTime(source.year, source.month + 2, 0);
  final clampedDay = source.day.clamp(1, targetMonthDate.day);
  return DateTime(source.year, source.month + 1, clampedDay);
}

bool _isSameOrBefore(DateTime left, DateTime right) {
  return left.isAtSameMomentAs(right) || left.isBefore(right);
}
