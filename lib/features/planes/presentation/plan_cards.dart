import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

class PlanFeatureCard extends StatelessWidget {
  const PlanFeatureCard({
    super.key,
    required this.plan,
    required this.isActive,
    this.onChangePlan,
    this.showEnterpriseContactHint = true,
  });

  final Plan plan;
  final bool isActive;
  final VoidCallback? onChangePlan;
  final bool showEnterpriseContactHint;

  @override
  Widget build(BuildContext context) {
    final features = buildPlanFeatures(plan);
    final highlightColor = AppColors.primary;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? highlightColor : AppColors.border,
          width: isActive ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: onChangePlan == null
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.nombre,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive
                          ? highlightColor.withValues(alpha: 0.14)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isActive ? trText('Actual') : trText('Disponible'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                planPriceLabel(plan),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 6),
              Text(
                plan.descripcion,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 14),
              for (final feature in features)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        feature.enabled
                            ? Icons.check_circle_rounded
                            : Icons.remove_circle_outline_rounded,
                        size: 18,
                        color: feature.enabled
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature.label,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (showEnterpriseContactHint && plan.id == 'empresa') ...[
                SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Si tu equipo supera 50 miembros, contáctanos por correo.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (onChangePlan != null) ...[
            SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onChangePlan,
                icon: FaIcon(FontAwesomeIcons.gem, size: 14),
                label: Text(trText('Cambiar plan')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PlanFeatureItem {
  const PlanFeatureItem({required this.label, required this.enabled});

  final String label;
  final bool enabled;
}

List<PlanFeatureItem> buildPlanFeatures(Plan plan) {
  return <PlanFeatureItem>[
    PlanFeatureItem(
      label:
          '${trText('Clientes')}: ${_limitLabel(plan.limiteClientes, pluralEs: 'Ilimitados', pluralEn: 'Unlimited')}',
      enabled: true,
    ),
    PlanFeatureItem(
      label:
          '${trText('Productos')}: ${_limitLabel(plan.limiteProductos, pluralEs: 'Ilimitados', pluralEn: 'Unlimited')}',
      enabled: true,
    ),
    PlanFeatureItem(
      label:
          'Materiales: ${_limitLabel(plan.limiteMateriales, pluralEs: 'Ilimitados', pluralEn: 'Unlimited')}',
      enabled: true,
    ),
    PlanFeatureItem(
      label:
          '${tr('Cotizaciones mes', 'Monthly quotes')}: ${_limitLabel(plan.limiteCotizacionesMensuales, pluralEs: 'Ilimitadas', pluralEn: 'Unlimited')}',
      enabled: true,
    ),
    PlanFeatureItem(
      label:
          'Ingresos y gastos: ${plan.incluyeIngresosGastos ? trText('Incluido') : trText('Bloqueado')}',
      enabled: plan.incluyeIngresosGastos,
    ),
    PlanFeatureItem(
      label:
          'Analítica: ${plan.incluyeAnalitica ? trText('Incluida') : trText('Bloqueada')}',
      enabled: plan.incluyeAnalitica,
    ),
    PlanFeatureItem(
      label:
          'Personalización PDF: ${plan.incluyePersonalizacionPdf ? trText('Incluida') : trText('Bloqueada')}',
      enabled: plan.incluyePersonalizacionPdf,
    ),
    PlanFeatureItem(
      label: '${trText('Usuarios')}: ${_userLimitLabel(plan)}',
      enabled: true,
    ),
    PlanFeatureItem(
      label:
          '${trText('Empresas')}: ${_limitLabel(plan.limiteEmpresas, pluralEs: 'Ilimitadas', pluralEn: 'Unlimited')}',
      enabled: plan.limiteEmpresas != 0,
    ),
    PlanFeatureItem(
      label:
          'Marca de agua Cotimax: ${plan.incluyeMarcaAgua ? trText('Aplicada') : trText('Sin marca de agua')}',
      enabled: !plan.incluyeMarcaAgua,
    ),
  ];
}

String planPriceLabel(Plan plan) {
  if (plan.billingMode == 'per_user_monthly') {
    return '${formatMoney(plan.precioPorUsuario, decimalDigits: 0)} / ${tr('usuario', 'user')} / ${tr('mes', 'month')}';
  }
  if (plan.precioMensual <= 0) {
    return trText('Gratis');
  }
  return '${formatMoney(plan.precioMensual, decimalDigits: 0)} / ${tr('mes', 'month')}';
}

String _limitLabel(
  int limit, {
  required String pluralEs,
  required String pluralEn,
}) {
  if (limit <= 0) {
    return tr(pluralEs, pluralEn);
  }
  return '$limit';
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
