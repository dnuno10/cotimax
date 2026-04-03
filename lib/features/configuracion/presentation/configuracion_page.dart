import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/features/configuracion/application/configuracion_controller.dart';
import 'package:cotimax/features/planes/application/planes_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const List<({String value, String label})> localizationCurrencyOptions = [
  (value: 'MXN', label: 'MXN - Peso mexicano'),
  (value: 'USD', label: 'USD - Dólar estadounidense'),
  (value: 'EUR', label: 'EUR - Euro'),
  (value: 'GBP', label: 'GBP - Libra esterlina'),
  (value: 'CAD', label: 'CAD - Dólar canadiense'),
  (value: 'BRL', label: 'BRL - Real brasileño'),
  (value: 'ARS', label: 'ARS - Peso argentino'),
  (value: 'CLP', label: 'CLP - Peso chileno'),
  (value: 'COP', label: 'COP - Peso colombiano'),
  (value: 'PEN', label: 'PEN - Sol peruano'),
  (value: 'UYU', label: 'UYU - Peso uruguayo'),
  (value: 'PYG', label: 'PYG - Guaraní paraguayo'),
  (value: 'BOB', label: 'BOB - Boliviano'),
  (value: 'GTQ', label: 'GTQ - Quetzal guatemalteco'),
  (value: 'CRC', label: 'CRC - Colón costarricense'),
  (value: 'DOP', label: 'DOP - Peso dominicano'),
  (value: 'JPY', label: 'JPY - Yen japonés'),
  (value: 'CNY', label: 'CNY - Yuan chino'),
  (value: 'INR', label: 'INR - Rupia india'),
  (value: 'AUD', label: 'AUD - Dólar australiano'),
  (value: 'NZD', label: 'NZD - Dólar neozelandés'),
  (value: 'CHF', label: 'CHF - Franco suizo'),
  (value: 'SEK', label: 'SEK - Corona sueca'),
  (value: 'NOK', label: 'NOK - Corona noruega'),
  (value: 'DKK', label: 'DKK - Corona danesa'),
  (value: 'SGD', label: 'SGD - Dólar de Singapur'),
  (value: 'HKD', label: 'HKD - Dólar de Hong Kong'),
  (value: 'KRW', label: 'KRW - Won surcoreano'),
  (value: 'ZAR', label: 'ZAR - Rand sudafricano'),
  (value: 'AED', label: 'AED - Dírham de Emiratos'),
];

const List<({String value, String label})> localizationLanguageOptions = [
  (value: 'es-MX', label: 'Español (México)'),
  (value: 'es-ES', label: 'Español (España)'),
  (value: 'en-US', label: 'Inglés (Estados Unidos)'),
  (value: 'en-GB', label: 'Inglés (Reino Unido)'),
  (value: 'pt-BR', label: 'Portugués (Brasil)'),
  (value: 'fr-FR', label: 'Francés (Francia)'),
  (value: 'de-DE', label: 'Alemán (Alemania)'),
  (value: 'it-IT', label: 'Italiano (Italia)'),
];

const List<({String value, String label})> localizationTimezoneOptions = [
  (value: 'America/Tijuana', label: 'América/Tijuana (UTC-08:00)'),
  (value: 'America/Hermosillo', label: 'América/Hermosillo (UTC-07:00)'),
  (value: 'America/Mazatlan', label: 'América/Mazatlán (UTC-07:00)'),
  (value: 'America/Mexico_City', label: 'América/Ciudad de México (UTC-06:00)'),
  (value: 'America/Monterrey', label: 'América/Monterrey (UTC-06:00)'),
  (value: 'America/Bogota', label: 'América/Bogotá (UTC-05:00)'),
  (value: 'America/Lima', label: 'América/Lima (UTC-05:00)'),
  (value: 'America/Santiago', label: 'América/Santiago (UTC-04:00)'),
  (value: 'America/Caracas', label: 'América/Caracas (UTC-04:00)'),
  (
    value: 'America/Argentina/Buenos_Aires',
    label: 'América/Buenos Aires (UTC-03:00)',
  ),
  (value: 'Europe/Madrid', label: 'Europa/Madrid (UTC+01:00)'),
  (value: 'UTC', label: 'UTC (UTC+00:00)'),
];

const List<({String value, String label})> localizationDateFormatOptions = [
  (value: 'dd/MM/yyyy', label: 'dd/MM/yyyy'),
  (value: 'dd-MM-yyyy', label: 'dd-MM-yyyy'),
  (value: 'MM/dd/yyyy', label: 'MM/dd/yyyy'),
  (value: 'yyyy-MM-dd', label: 'yyyy-MM-dd'),
  (value: 'dd MMM yyyy', label: 'dd MMM yyyy'),
  (value: 'MMMM dd, yyyy', label: 'MMMM dd, yyyy'),
];

const List<({String value, String label})> localizationMoneyFormatOptions = [
  (value: 'symbol_before', label: 'Símbolo antes del monto'),
  (value: 'symbol_after', label: 'Símbolo después del monto'),
  (value: 'code_before', label: 'Código antes del monto'),
  (value: 'code_after', label: 'Código después del monto'),
  (value: 'symbol_space_before', label: 'Símbolo antes con espacio'),
  (value: 'code_space_before', label: 'Código antes con espacio'),
];

String _resolveLocalizationValue(
  String current,
  List<({String value, String label})> options,
) {
  final trimmed = current.trim();
  if (trimmed.isEmpty) return options.first.value;
  for (final option in options) {
    if (option.value == trimmed || option.label == trimmed) {
      return option.value;
    }
  }
  return options.first.value;
}

class ConfiguracionPage extends ConsumerStatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  ConsumerState<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends ConsumerState<ConfiguracionPage> {
  int _mainTabIndex = 0;
  int _accountTabIndex = 0;
  int _invoiceTabIndex = 0;

  final Map<String, bool> _enabledModules = {
    'Facturas': true,
    'Facturas recurrentes': true,
    'Cotizaciones': true,
    'Creditos': false,
    'Proyectos': false,
    'Tareas': false,
    'Vendedores': false,
    'Gastos': true,
    'Ordenes de compra': true,
    'Gastos recurrentes': true,
    'Actas': false,
  };

  String _invoiceDesign = 'Clean';
  String _quoteDesign = 'Clean';
  String _creditDesign = 'Clean';
  String _purchaseOrderDesign = 'Clean';
  String _pageOrientation = 'Retrato';
  String _pageSize = 'A4';
  String _fontSize = '18';
  String _logoSizeMode = 'Porcentaje';
  String _primaryFont = 'Arimo';
  String _secondaryFont = 'Arimo';
  String _emptyColumnsMode = 'Espectaculo';
  bool _showPaidStamp = false;
  bool _showShippingAddress = false;
  bool _embedAttachments = false;
  bool _showPageNumber = false;

  late final TextEditingController _logoSizeController;
  late final TextEditingController _primaryColorController;
  late final TextEditingController _secondaryColorController;

  static const _mainTabs = [
    'Gestión de cuenta',
    'Empresa',
    'Localización',
    'Diseño de factura',
    'Impuestos',
  ];

  static const _accountTabs = [
    'Plan',
    'Descripción general',
    'Módulos habilitados',
    'Zona peligrosa',
  ];

  static const _invoiceTabs = [
    'Configuración General',
    'Diseños Personalizados',
    'Cliente',
  ];

  @override
  void initState() {
    super.initState();
    _logoSizeController = TextEditingController(text: '24');
    _primaryColorController = TextEditingController(text: '000000');
    _secondaryColorController = TextEditingController(text: 'F8B142');
  }

  @override
  void dispose() {
    _logoSizeController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(empresaPerfilControllerProvider);

    return ListView(
      children: [
        const PageHeader(title: 'Configuración', subtitle: ''),
        const SizedBox(height: 12),
        perfil.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No se pudo cargar la configuración.',
            onRetry: () => ref.invalidate(empresaPerfilControllerProvider),
          ),
          data: (empresa) => SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      _mainTabs.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                          right: index == _mainTabs.length - 1 ? 0 : 26,
                        ),
                        child: _TopConfigTab(
                          label: _mainTabs[index],
                          selected: _mainTabIndex == index,
                          onTap: () => setState(() => _mainTabIndex = index),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 18),
                if (_mainTabIndex == 0)
                  _AccountManagementSection(
                    empresa: empresa,
                    tabIndex: _accountTabIndex,
                    tabs: _accountTabs,
                    enabledModules: _enabledModules,
                    onTabChanged: (index) =>
                        setState(() => _accountTabIndex = index),
                    onModuleChanged: (label, value) {
                      setState(() => _enabledModules[label] = value);
                    },
                  ),
                if (_mainTabIndex == 1)
                  _CompanySettingsSection(
                    key: ValueKey(
                      'company-${empresa.updatedAt.microsecondsSinceEpoch}',
                    ),
                    empresa: empresa,
                  ),
                if (_mainTabIndex == 2)
                  _LocalizationSettingsSection(
                    key: ValueKey(
                      'localizacion-${empresa.updatedAt.microsecondsSinceEpoch}',
                    ),
                    empresa: empresa,
                  ),
                if (_mainTabIndex == 3)
                  _InvoiceDesignSection(
                    empresa: empresa,
                    tabIndex: _invoiceTabIndex,
                    tabs: _invoiceTabs,
                    invoiceDesign: _invoiceDesign,
                    quoteDesign: _quoteDesign,
                    creditDesign: _creditDesign,
                    purchaseOrderDesign: _purchaseOrderDesign,
                    pageOrientation: _pageOrientation,
                    pageSize: _pageSize,
                    fontSize: _fontSize,
                    logoSizeMode: _logoSizeMode,
                    logoSizeController: _logoSizeController,
                    primaryColorController: _primaryColorController,
                    secondaryColorController: _secondaryColorController,
                    primaryFont: _primaryFont,
                    secondaryFont: _secondaryFont,
                    emptyColumnsMode: _emptyColumnsMode,
                    showPaidStamp: _showPaidStamp,
                    showShippingAddress: _showShippingAddress,
                    embedAttachments: _embedAttachments,
                    showPageNumber: _showPageNumber,
                    onTabChanged: (index) =>
                        setState(() => _invoiceTabIndex = index),
                    onInvoiceDesignChanged: (value) =>
                        setState(() => _invoiceDesign = value),
                    onQuoteDesignChanged: (value) =>
                        setState(() => _quoteDesign = value),
                    onCreditDesignChanged: (value) =>
                        setState(() => _creditDesign = value),
                    onPurchaseOrderDesignChanged: (value) =>
                        setState(() => _purchaseOrderDesign = value),
                    onPageOrientationChanged: (value) =>
                        setState(() => _pageOrientation = value),
                    onPageSizeChanged: (value) =>
                        setState(() => _pageSize = value),
                    onFontSizeChanged: (value) =>
                        setState(() => _fontSize = value),
                    onLogoSizeModeChanged: (value) =>
                        setState(() => _logoSizeMode = value),
                    onPrimaryFontChanged: (value) =>
                        setState(() => _primaryFont = value),
                    onSecondaryFontChanged: (value) =>
                        setState(() => _secondaryFont = value),
                    onEmptyColumnsModeChanged: (value) =>
                        setState(() => _emptyColumnsMode = value),
                    onShowPaidStampChanged: (value) =>
                        setState(() => _showPaidStamp = value),
                    onShowShippingAddressChanged: (value) =>
                        setState(() => _showShippingAddress = value),
                    onEmbedAttachmentsChanged: (value) =>
                        setState(() => _embedAttachments = value),
                    onShowPageNumberChanged: (value) =>
                        setState(() => _showPageNumber = value),
                  ),
                if (_mainTabIndex == 4)
                  _TaxSettingsSection(
                    key: ValueKey(
                      'impuestos-${empresa.updatedAt.microsecondsSinceEpoch}',
                    ),
                    empresa: empresa,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopConfigTab extends StatelessWidget {
  const _TopConfigTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SectionPillTab extends StatelessWidget {
  const _SectionPillTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AccountManagementSection extends ConsumerWidget {
  const _AccountManagementSection({
    required this.empresa,
    required this.tabIndex,
    required this.tabs,
    required this.enabledModules,
    required this.onTabChanged,
    required this.onModuleChanged,
  });

  final EmpresaPerfil empresa;
  final int tabIndex;
  final List<String> tabs;
  final Map<String, bool> enabledModules;
  final ValueChanged<int> onTabChanged;
  final void Function(String label, bool value) onModuleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suscripcionAsync = ref.watch(suscripcionControllerProvider);
    final planesAsync = ref.watch(planesControllerProvider);

    return suscripcionAsync.when(
      loading: LoadingSkeleton.new,
      error: (_, __) => ErrorStateWidget(
        message: 'No se pudo cargar la suscripción.',
        onRetry: () {
          ref.invalidate(suscripcionControllerProvider);
          ref.invalidate(planesControllerProvider);
        },
      ),
      data: (suscripcion) => planesAsync.when(
        loading: LoadingSkeleton.new,
        error: (_, __) => ErrorStateWidget(
          message: 'No se pudo cargar el plan.',
          onRetry: () => ref.invalidate(planesControllerProvider),
        ),
        data: (planes) {
          final currentPlan = planes.firstWhere(
            (plan) => plan.id == suscripcion.planId,
            orElse: () => planes.first,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account Management',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    tabs.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        right: index == tabs.length - 1 ? 0 : 10,
                      ),
                      child: _SectionPillTab(
                        label: tabs[index],
                        selected: tabIndex == index,
                        onTap: () => onTabChanged(index),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (tabIndex == 0)
                _PlanAndBillingPanel(
                  empresa: empresa,
                  plan: currentPlan,
                  suscripcion: suscripcion,
                  allPlans: planes,
                ),
              if (tabIndex == 1)
                _GeneralAccountPanel(empresa: empresa, plan: currentPlan),
              if (tabIndex == 2)
                _EnabledModulesPanel(
                  enabledModules: enabledModules,
                  onChanged: onModuleChanged,
                ),
              if (tabIndex == 3) const _DangerZonePanel(),
            ],
          );
        },
      ),
    );
  }
}

class _PlanAndBillingPanel extends StatelessWidget {
  const _PlanAndBillingPanel({
    required this.empresa,
    required this.plan,
    required this.suscripcion,
    required this.allPlans,
  });

  final EmpresaPerfil empresa;
  final Plan plan;
  final Suscripcion suscripcion;
  final List<Plan> allPlans;

  @override
  Widget build(BuildContext context) {
    final upgradePlans = allPlans.where((item) => item.id != plan.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigSectionTitle(title: 'Your Plan'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.nombre,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.descripcion,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Renueva ${DateFormat('dd MMM yyyy').format(suscripcion.fechaFin)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _planPriceLabel(plan),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 920;
              final content = [
                for (final item in upgradePlans)
                  Expanded(child: _PlanUpgradeColumn(plan: item)),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: FilledButton(
                    onPressed: () => ToastHelper.show(
                      context,
                      'Gestión de actualización disponible pronto.',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Plan de actualización'),
                  ),
                ),
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actualiza a los planes Pro o Enterprise para funciones avanzadas.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  stacked
                      ? Column(
                          children: [
                            for (
                              var index = 0;
                              index < upgradePlans.length;
                              index++
                            ) ...[
                              _PlanUpgradeColumn(plan: upgradePlans[index]),
                              const SizedBox(height: 12),
                            ],
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton(
                                onPressed: () => ToastHelper.show(
                                  context,
                                  'Gestión de actualización disponible pronto.',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.textPrimary,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('Plan de actualización'),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: content,
                        ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(child: _ConfigSectionTitle(title: 'Payment method')),
            TextButton.icon(
              onPressed: () => ToastHelper.show(
                context,
                'Agregar metodo de pago disponible pronto.',
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Payment Method'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 840;
            final paymentCard = _PaymentMethodCard(
              empresa: empresa,
              plan: plan,
            );
            final addCard = _PaymentMethodAddCard(
              onTap: () => ToastHelper.show(
                context,
                'Agregar metodo de pago disponible pronto.',
              ),
            );

            if (stacked) {
              return Column(
                children: [paymentCard, const SizedBox(height: 12), addCard],
              );
            }

            return Row(
              children: [
                Expanded(child: paymentCard),
                const SizedBox(width: 12),
                SizedBox(width: 250, child: addCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GeneralAccountPanel extends StatelessWidget {
  const _GeneralAccountPanel({required this.empresa, required this.plan});

  final EmpresaPerfil empresa;
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          title: 'Resumen de cuenta',
          children: [
            _InfoLine(label: 'Empresa', value: empresa.nombreComercial),
            _InfoLine(label: 'Plan activo', value: plan.nombre),
            _InfoLine(label: 'Correo principal', value: empresa.correo),
            _InfoLine(label: 'Teléfono', value: empresa.telefono),
            _InfoLine(label: 'Sitio web', value: empresa.sitioWeb),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Capacidad actual',
          children: [
            _InfoLine(
              label: 'Clientes',
              value: plan.limiteClientes < 0
                  ? 'Ilimitados'
                  : '${plan.limiteClientes}',
            ),
            _InfoLine(
              label: 'Productos',
              value: plan.limiteProductos < 0
                  ? 'Ilimitados'
                  : '${plan.limiteProductos}',
            ),
            _InfoLine(
              label: 'Cotizaciones mensuales',
              value: plan.limiteCotizacionesMensuales < 0
                  ? 'Ilimitadas'
                  : '${plan.limiteCotizacionesMensuales}',
            ),
            _InfoLine(label: 'Usuarios', value: _planUsersLabel(plan)),
          ],
        ),
      ],
    );
  }
}

class _EnabledModulesPanel extends StatelessWidget {
  const _EnabledModulesPanel({
    required this.enabledModules,
    required this.onChanged,
  });

  final Map<String, bool> enabledModules;
  final void Function(String label, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = enabledModules.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Módulos habilitados',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          for (var index = 0; index < entries.length; index++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: index == 0
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entries[index].key,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch(
                    value: entries[index].value,
                    onChanged: (value) => onChanged(entries[index].key, value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DangerZonePanel extends StatelessWidget {
  const _DangerZonePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DangerActionCard(
          icon: Icons.auto_delete_outlined,
          label: 'Purgar Datos',
          onTap: () =>
              ToastHelper.show(context, 'Purgar datos disponible pronto.'),
        ),
        const SizedBox(height: 12),
        _DangerActionCard(
          icon: Icons.delete_outline_rounded,
          label: 'Eliminar cuenta',
          onTap: () => ToastHelper.show(
            context,
            'Eliminación de cuenta disponible pronto.',
          ),
        ),
      ],
    );
  }
}

class _CompanySettingsSection extends ConsumerStatefulWidget {
  const _CompanySettingsSection({super.key, required this.empresa});

  final EmpresaPerfil empresa;

  @override
  ConsumerState<_CompanySettingsSection> createState() =>
      _CompanySettingsSectionState();
}

class _CompanySettingsSectionState
    extends ConsumerState<_CompanySettingsSection> {
  late final TextEditingController _nombreComercialController;
  late final TextEditingController _nombreFiscalController;
  late final TextEditingController _rfcController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _sitioWebController;
  late final TextEditingController _direccionController;
  bool _isSaving = false;

  EmpresaPerfil get _empresa => widget.empresa;

  @override
  void initState() {
    super.initState();
    _nombreComercialController = TextEditingController(
      text: _empresa.nombreComercial,
    );
    _nombreFiscalController = TextEditingController(
      text: _empresa.nombreFiscal,
    );
    _rfcController = TextEditingController(text: _empresa.rfc);
    _correoController = TextEditingController(text: _empresa.correo);
    _telefonoController = TextEditingController(text: _empresa.telefono);
    _sitioWebController = TextEditingController(text: _empresa.sitioWeb);
    _direccionController = TextEditingController(text: _empresa.direccion);
  }

  @override
  void dispose() {
    _nombreComercialController.dispose();
    _nombreFiscalController.dispose();
    _rfcController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _sitioWebController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nombreComercial = _nombreComercialController.text.trim();
    final nombreFiscal = _nombreFiscalController.text.trim();

    if (nombreComercial.isEmpty || nombreFiscal.isEmpty) {
      ToastHelper.show(
        context,
        'Nombre comercial y nombre fiscal son obligatorios.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(configuracionRepositoryProvider)
          .updateEmpresa(
            _empresa.copyWith(
              nombreComercial: nombreComercial,
              nombreFiscal: nombreFiscal,
              rfc: _rfcController.text.trim(),
              correo: _correoController.text.trim(),
              telefono: _telefonoController.text.trim(),
              sitioWeb: _sitioWebController.text.trim(),
              direccion: _direccionController.text.trim(),
            ),
          );
      ref.invalidate(empresaPerfilControllerProvider);

      if (!mounted) return;
      ToastHelper.show(context, 'Datos de empresa guardados.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FormShellCard(
          title: 'Detalles de empresa',
          child: Column(
            children: [
              _EditableFieldRow(
                label: 'Nombre comercial',
                controller: _nombreComercialController,
              ),
              _EditableFieldRow(
                label: 'Nombre fiscal',
                controller: _nombreFiscalController,
              ),
              _EditableFieldRow(label: 'RFC', controller: _rfcController),
              _EditableFieldRow(
                label: 'Correo',
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
              ),
              _EditableFieldRow(
                label: 'Teléfono',
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
              ),
              _EditableFieldRow(
                label: 'Sitio web',
                controller: _sitioWebController,
                keyboardType: TextInputType.url,
              ),
              _EditableFieldRow(
                label: 'Dirección',
                controller: _direccionController,
                maxLines: 3,
              ),
              _SettingsActionBar(
                label: 'Guardar empresa',
                isSaving: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Logo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              if (_empresa.logoUrl.trim().isNotEmpty)
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _LogoPreviewCard(
                      background: AppColors.border,
                      imagePath: _empresa.logoUrl,
                    ),
                    _LogoPreviewCard(
                      background: const Color(0xFF1A2434),
                      imagePath: _empresa.logoUrl,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocalizationSettingsSection extends ConsumerStatefulWidget {
  const _LocalizationSettingsSection({super.key, required this.empresa});

  final EmpresaPerfil empresa;

  @override
  ConsumerState<_LocalizationSettingsSection> createState() =>
      _LocalizationSettingsSectionState();
}

class _LocalizationSettingsSectionState
    extends ConsumerState<_LocalizationSettingsSection> {
  late String _moneda;
  late String _idioma;
  late String _husoHorario;
  late String _formatoFecha;
  late String _formatoMoneda;
  bool _isSaving = false;

  ConfiguracionLocalizacion get _localizacion => widget.empresa.localizacion;

  @override
  void initState() {
    super.initState();
    _moneda = _resolveLocalizationValue(
      _localizacion.moneda,
      localizationCurrencyOptions,
    );
    _idioma = _resolveLocalizationValue(
      _localizacion.idioma,
      localizationLanguageOptions,
    );
    _husoHorario = _resolveLocalizationValue(
      _localizacion.husoHorario,
      localizationTimezoneOptions,
    );
    _formatoFecha = _resolveLocalizationValue(
      _localizacion.formatoFecha,
      localizationDateFormatOptions,
    );
    _formatoMoneda = _resolveLocalizationValue(
      _localizacion.formatoMoneda,
      localizationMoneyFormatOptions,
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await ref
          .read(configuracionRepositoryProvider)
          .updateEmpresa(
            widget.empresa.copyWith(
              localizacion: _localizacion.copyWith(
                moneda: _moneda,
                idioma: _idioma,
                husoHorario: _husoHorario,
                formatoFecha: _formatoFecha,
                formatoMoneda: _formatoMoneda,
              ),
            ),
          );
      ref.invalidate(empresaPerfilControllerProvider);

      if (!mounted) return;
      ToastHelper.show(context, 'Configuración de localización guardada.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormShellCard(
      title: 'Localización',
      child: Column(
        children: [
          _SelectableFieldRow(
            label: 'Moneda',
            value: _moneda,
            options: localizationCurrencyOptions,
            onChanged: (value) => setState(() => _moneda = value),
          ),
          _SelectableFieldRow(
            label: 'Idioma',
            value: _idioma,
            options: localizationLanguageOptions,
            onChanged: (value) => setState(() => _idioma = value),
          ),
          _SelectableFieldRow(
            label: 'Huso horario',
            value: _husoHorario,
            options: localizationTimezoneOptions,
            onChanged: (value) => setState(() => _husoHorario = value),
          ),
          _SelectableFieldRow(
            label: 'Formato de fecha',
            value: _formatoFecha,
            options: localizationDateFormatOptions,
            onChanged: (value) => setState(() => _formatoFecha = value),
          ),
          _SelectableFieldRow(
            label: 'Formato de moneda',
            value: _formatoMoneda,
            options: localizationMoneyFormatOptions,
            onChanged: (value) => setState(() => _formatoMoneda = value),
          ),
          _SettingsActionBar(
            label: 'Guardar localización',
            isSaving: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _InvoiceDesignSection extends StatelessWidget {
  const _InvoiceDesignSection({
    required this.empresa,
    required this.tabIndex,
    required this.tabs,
    required this.invoiceDesign,
    required this.quoteDesign,
    required this.creditDesign,
    required this.purchaseOrderDesign,
    required this.pageOrientation,
    required this.pageSize,
    required this.fontSize,
    required this.logoSizeMode,
    required this.logoSizeController,
    required this.primaryColorController,
    required this.secondaryColorController,
    required this.primaryFont,
    required this.secondaryFont,
    required this.emptyColumnsMode,
    required this.showPaidStamp,
    required this.showShippingAddress,
    required this.embedAttachments,
    required this.showPageNumber,
    required this.onTabChanged,
    required this.onInvoiceDesignChanged,
    required this.onQuoteDesignChanged,
    required this.onCreditDesignChanged,
    required this.onPurchaseOrderDesignChanged,
    required this.onPageOrientationChanged,
    required this.onPageSizeChanged,
    required this.onFontSizeChanged,
    required this.onLogoSizeModeChanged,
    required this.onPrimaryFontChanged,
    required this.onSecondaryFontChanged,
    required this.onEmptyColumnsModeChanged,
    required this.onShowPaidStampChanged,
    required this.onShowShippingAddressChanged,
    required this.onEmbedAttachmentsChanged,
    required this.onShowPageNumberChanged,
  });

  final EmpresaPerfil empresa;
  final int tabIndex;
  final List<String> tabs;
  final String invoiceDesign;
  final String quoteDesign;
  final String creditDesign;
  final String purchaseOrderDesign;
  final String pageOrientation;
  final String pageSize;
  final String fontSize;
  final String logoSizeMode;
  final TextEditingController logoSizeController;
  final TextEditingController primaryColorController;
  final TextEditingController secondaryColorController;
  final String primaryFont;
  final String secondaryFont;
  final String emptyColumnsMode;
  final bool showPaidStamp;
  final bool showShippingAddress;
  final bool embedAttachments;
  final bool showPageNumber;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onInvoiceDesignChanged;
  final ValueChanged<String> onQuoteDesignChanged;
  final ValueChanged<String> onCreditDesignChanged;
  final ValueChanged<String> onPurchaseOrderDesignChanged;
  final ValueChanged<String> onPageOrientationChanged;
  final ValueChanged<String> onPageSizeChanged;
  final ValueChanged<String> onFontSizeChanged;
  final ValueChanged<String> onLogoSizeModeChanged;
  final ValueChanged<String> onPrimaryFontChanged;
  final ValueChanged<String> onSecondaryFontChanged;
  final ValueChanged<String> onEmptyColumnsModeChanged;
  final ValueChanged<bool> onShowPaidStampChanged;
  final ValueChanged<bool> onShowShippingAddressChanged;
  final ValueChanged<bool> onEmbedAttachmentsChanged;
  final ValueChanged<bool> onShowPageNumberChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Diseño de factura',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ToastHelper.show(
                context,
                'Gestionar plan disponible pronto.',
              ),
              child: const Text('Gestionar plan'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              tabs.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  right: index == tabs.length - 1 ? 0 : 18,
                ),
                child: _TopConfigTab(
                  label: tabs[index],
                  selected: tabIndex == index,
                  onTap: () => onTabChanged(index),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFACC15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Comience su prueba GRATUITA de 14 días del Plan Pro',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ToastHelper.show(
                  context,
                  'Gestionar plan disponible pronto.',
                ),
                child: const Text('Gestionar plan'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1240;
            final controls = _InvoiceControlsPanel(
              tabIndex: tabIndex,
              invoiceDesign: invoiceDesign,
              quoteDesign: quoteDesign,
              creditDesign: creditDesign,
              purchaseOrderDesign: purchaseOrderDesign,
              pageOrientation: pageOrientation,
              pageSize: pageSize,
              fontSize: fontSize,
              logoSizeMode: logoSizeMode,
              logoSizeController: logoSizeController,
              primaryColorController: primaryColorController,
              secondaryColorController: secondaryColorController,
              primaryFont: primaryFont,
              secondaryFont: secondaryFont,
              emptyColumnsMode: emptyColumnsMode,
              showPaidStamp: showPaidStamp,
              showShippingAddress: showShippingAddress,
              embedAttachments: embedAttachments,
              showPageNumber: showPageNumber,
              onInvoiceDesignChanged: onInvoiceDesignChanged,
              onQuoteDesignChanged: onQuoteDesignChanged,
              onCreditDesignChanged: onCreditDesignChanged,
              onPurchaseOrderDesignChanged: onPurchaseOrderDesignChanged,
              onPageOrientationChanged: onPageOrientationChanged,
              onPageSizeChanged: onPageSizeChanged,
              onFontSizeChanged: onFontSizeChanged,
              onLogoSizeModeChanged: onLogoSizeModeChanged,
              onPrimaryFontChanged: onPrimaryFontChanged,
              onSecondaryFontChanged: onSecondaryFontChanged,
              onEmptyColumnsModeChanged: onEmptyColumnsModeChanged,
              onShowPaidStampChanged: onShowPaidStampChanged,
              onShowShippingAddressChanged: onShowShippingAddressChanged,
              onEmbedAttachmentsChanged: onEmbedAttachmentsChanged,
              onShowPageNumberChanged: onShowPageNumberChanged,
            );
            final preview = _InvoicePreviewPanel(
              empresa: empresa,
              pageOrientation: pageOrientation,
              pageSize: pageSize,
              fontSize: fontSize,
              logoSizeController: logoSizeController,
              primaryColorHex: primaryColorController.text,
              secondaryColorHex: secondaryColorController.text,
              primaryFont: primaryFont,
              secondaryFont: secondaryFont,
              showPaidStamp: showPaidStamp,
              showShippingAddress: showShippingAddress,
              embedAttachments: embedAttachments,
              showPageNumber: showPageNumber,
            );

            if (stacked) {
              return Column(
                children: [
                  controls,
                  const SizedBox(height: 14),
                  SizedBox(height: 820, child: preview),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 520, child: controls),
                const SizedBox(width: 16),
                Expanded(child: SizedBox(height: 980, child: preview)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InvoiceControlsPanel extends StatelessWidget {
  const _InvoiceControlsPanel({
    required this.tabIndex,
    required this.invoiceDesign,
    required this.quoteDesign,
    required this.creditDesign,
    required this.purchaseOrderDesign,
    required this.pageOrientation,
    required this.pageSize,
    required this.fontSize,
    required this.logoSizeMode,
    required this.logoSizeController,
    required this.primaryColorController,
    required this.secondaryColorController,
    required this.primaryFont,
    required this.secondaryFont,
    required this.emptyColumnsMode,
    required this.showPaidStamp,
    required this.showShippingAddress,
    required this.embedAttachments,
    required this.showPageNumber,
    required this.onInvoiceDesignChanged,
    required this.onQuoteDesignChanged,
    required this.onCreditDesignChanged,
    required this.onPurchaseOrderDesignChanged,
    required this.onPageOrientationChanged,
    required this.onPageSizeChanged,
    required this.onFontSizeChanged,
    required this.onLogoSizeModeChanged,
    required this.onPrimaryFontChanged,
    required this.onSecondaryFontChanged,
    required this.onEmptyColumnsModeChanged,
    required this.onShowPaidStampChanged,
    required this.onShowShippingAddressChanged,
    required this.onEmbedAttachmentsChanged,
    required this.onShowPageNumberChanged,
  });

  final int tabIndex;
  final String invoiceDesign;
  final String quoteDesign;
  final String creditDesign;
  final String purchaseOrderDesign;
  final String pageOrientation;
  final String pageSize;
  final String fontSize;
  final String logoSizeMode;
  final TextEditingController logoSizeController;
  final TextEditingController primaryColorController;
  final TextEditingController secondaryColorController;
  final String primaryFont;
  final String secondaryFont;
  final String emptyColumnsMode;
  final bool showPaidStamp;
  final bool showShippingAddress;
  final bool embedAttachments;
  final bool showPageNumber;
  final ValueChanged<String> onInvoiceDesignChanged;
  final ValueChanged<String> onQuoteDesignChanged;
  final ValueChanged<String> onCreditDesignChanged;
  final ValueChanged<String> onPurchaseOrderDesignChanged;
  final ValueChanged<String> onPageOrientationChanged;
  final ValueChanged<String> onPageSizeChanged;
  final ValueChanged<String> onFontSizeChanged;
  final ValueChanged<String> onLogoSizeModeChanged;
  final ValueChanged<String> onPrimaryFontChanged;
  final ValueChanged<String> onSecondaryFontChanged;
  final ValueChanged<String> onEmptyColumnsModeChanged;
  final ValueChanged<bool> onShowPaidStampChanged;
  final ValueChanged<bool> onShowShippingAddressChanged;
  final ValueChanged<bool> onEmbedAttachmentsChanged;
  final ValueChanged<bool> onShowPageNumberChanged;

  @override
  Widget build(BuildContext context) {
    if (tabIndex == 1) {
      return _FormShellCard(
        title: 'Diseños personalizados',
        child: Column(
          children: [
            _PresetDesignCard(
              title: 'Clean',
              subtitle: 'Diseño claro, corporativo y centrado en lectura.',
            ),
            const SizedBox(height: 10),
            _PresetDesignCard(
              title: 'Bold',
              subtitle:
                  'Encabezados más contrastados y tabla con más presencia.',
            ),
            const SizedBox(height: 10),
            _PresetDesignCard(
              title: 'Minimal',
              subtitle:
                  'Más aire visual y densidad reducida para cliente final.',
            ),
          ],
        ),
      );
    }

    if (tabIndex == 2) {
      return _FormShellCard(
        title: 'Cliente',
        child: Column(
          children: [
            const _DesignToggleRow(
              label: 'Mostrar resumen para cliente',
              value: true,
              enabled: true,
            ),
            _DesignToggleRow(
              label: 'Mostrar direccion de envio',
              value: showShippingAddress,
              onChanged: onShowShippingAddressChanged,
            ),
            _DesignToggleRow(
              label: 'Incrustar imagenes/documentos',
              value: embedAttachments,
              onChanged: onEmbedAttachmentsChanged,
              helper:
                  'Incluya imágenes/pdf adjuntos en la factura o cotización.',
            ),
          ],
        ),
      );
    }

    return _FormShellCard(
      title: 'Configuración General',
      child: Column(
        children: [
          _DesignSelectRow(
            label: 'Diseño de factura',
            value: invoiceDesign,
            options: const ['Clean', 'Bold', 'Minimal'],
            onChanged: onInvoiceDesignChanged,
          ),
          _DesignSelectRow(
            label: 'Diseño de Cotización',
            value: quoteDesign,
            options: const ['Clean', 'Bold', 'Minimal'],
            onChanged: onQuoteDesignChanged,
          ),
          _DesignSelectRow(
            label: 'Diseño de Créditos',
            value: creditDesign,
            options: const ['Clean', 'Bold', 'Minimal'],
            onChanged: onCreditDesignChanged,
          ),
          _DesignSelectRow(
            label: 'Diseño de orden de compra',
            value: purchaseOrderDesign,
            options: const ['Clean', 'Bold', 'Minimal'],
            onChanged: onPurchaseOrderDesignChanged,
          ),
          _DesignSelectRow(
            label: 'Diseño de página',
            value: pageOrientation,
            options: const ['Retrato', 'Horizontal'],
            onChanged: onPageOrientationChanged,
          ),
          _DesignSelectRow(
            label: 'Page Size',
            value: pageSize,
            options: const ['A4', 'Letter', 'Legal'],
            onChanged: onPageSizeChanged,
          ),
          _DesignSelectRow(
            label: 'Tamaño de Letra',
            value: fontSize,
            options: const ['12', '14', '16', '18', '20'],
            onChanged: onFontSizeChanged,
          ),
          _DesignDoubleInputRow(
            label: 'Tamaño del logotipo',
            leftValue: logoSizeMode,
            leftOptions: const ['Porcentaje', 'Px'],
            rightController: logoSizeController,
            onLeftChanged: onLogoSizeModeChanged,
          ),
          const _DesignDivider(),
          _DesignSelectRow(
            label: 'Fuente principal',
            value: primaryFont,
            options: const ['Arimo', 'Montserrat', 'Lora'],
            onChanged: onPrimaryFontChanged,
          ),
          _DesignColorRow(
            label: 'Color Primario',
            controller: primaryColorController,
          ),
          const _DesignDivider(),
          _DesignSelectRow(
            label: 'Fuente secundaria',
            value: secondaryFont,
            options: const ['Arimo', 'Montserrat', 'Lora'],
            onChanged: onSecondaryFontChanged,
          ),
          _DesignColorRow(
            label: 'Color Secundario',
            controller: secondaryColorController,
          ),
          const _DesignDivider(),
          _DesignToggleRow(
            label: 'Mostrar sello pagado',
            value: showPaidStamp,
            onChanged: onShowPaidStampChanged,
          ),
          _DesignToggleRow(
            label: 'Mostrar dirección de envío',
            value: showShippingAddress,
            onChanged: onShowShippingAddressChanged,
          ),
          _DesignToggleRow(
            label: 'Incrustar imágenes/documentos',
            value: embedAttachments,
            onChanged: onEmbedAttachmentsChanged,
            helper: 'Incluya imágenes/pdf adjuntos en la factura.',
          ),
          _DesignRadioRow(
            label: 'Columnas vacías',
            value: emptyColumnsMode,
            options: const ['Ocultar', 'Espectaculo'],
            onChanged: onEmptyColumnsModeChanged,
          ),
          _DesignToggleRow(
            label: 'Numeración de páginas',
            value: showPageNumber,
            onChanged: onShowPageNumberChanged,
          ),
        ],
      ),
    );
  }
}

class _InvoicePreviewPanel extends StatelessWidget {
  const _InvoicePreviewPanel({
    required this.empresa,
    required this.pageOrientation,
    required this.pageSize,
    required this.fontSize,
    required this.logoSizeController,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.primaryFont,
    required this.secondaryFont,
    required this.showPaidStamp,
    required this.showShippingAddress,
    required this.embedAttachments,
    required this.showPageNumber,
  });

  final EmpresaPerfil empresa;
  final String pageOrientation;
  final String pageSize;
  final String fontSize;
  final TextEditingController logoSizeController;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String primaryFont;
  final String secondaryFont;
  final bool showPaidStamp;
  final bool showShippingAddress;
  final bool embedAttachments;
  final bool showPageNumber;

  @override
  Widget build(BuildContext context) {
    final primary = _hexToColor(
      primaryColorHex,
      fallback: AppColors.textPrimary,
    );
    final secondary = _hexToColor(
      secondaryColorHex,
      fallback: AppColors.warning,
    );
    final logoSize = parseNumericText(logoSizeController.text) ?? 24;
    final hasLogo = empresa.logoUrl.trim().isNotEmpty;
    final portrait = pageOrientation == 'Retrato';
    final previewWidth = portrait ? 720.0 : 940.0;
    final previewPadding = portrait ? 34.0 : 28.0;
    final headerFontSize = double.tryParse(fontSize) ?? 18;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B8B8B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: previewWidth,
              padding: EdgeInsets.all(previewPadding),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasLogo) ...[
                            _OptionalAssetImage(
                              imagePath: empresa.logoUrl,
                              height: logoSize * 2.5,
                            ),
                            const SizedBox(width: 22),
                          ],
                          Expanded(
                            child: Wrap(
                              spacing: 24,
                              runSpacing: 18,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        empresa.nombreComercial,
                                        style: TextStyle(
                                          color: primary,
                                          fontSize: headerFontSize + 6,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        empresa.rfc,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: headerFontSize - 3,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        empresa.sitioWeb,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: headerFontSize - 4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        empresa.correo,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: headerFontSize - 4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        empresa.telefono,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: headerFontSize - 4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 240,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        empresa.direccion,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: headerFontSize - 3,
                                          fontWeight: FontWeight.w700,
                                          height: 1.45,
                                        ),
                                      ),
                                      if (showShippingAddress) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          'Enviar a: Blvd. Agua Caliente 1444, Tijuana, BC',
                                          style: TextStyle(
                                            color: secondary,
                                            fontSize: headerFontSize - 4,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'FACTURA',
                        style: TextStyle(
                          color: primary,
                          fontSize: headerFontSize + 2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(height: 1, color: AppColors.border),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 18,
                        runSpacing: 14,
                        children: const [
                          _PreviewMeta(label: 'Número', value: '0029'),
                          _PreviewMeta(
                            label: 'Número de Orden',
                            value: 'PO12345',
                          ),
                          _PreviewMeta(
                            label: 'Fecha de Factura',
                            value: '25/04/2026',
                          ),
                          _PreviewMeta(
                            label: 'Fecha de Vencimiento',
                            value: '02/05/2026',
                          ),
                          _PreviewMeta(
                            label: 'Total Facturado',
                            value: '\$330.00',
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Concepto',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: headerFontSize - 3,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Descripción',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: headerFontSize - 3,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Coste unitario',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: headerFontSize - 3,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Cantidad',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: headerFontSize - 3,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Impuesto',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: headerFontSize - 3,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: headerFontSize - 3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(flex: 2, child: Text('ab')),
                            const Expanded(
                              flex: 3,
                              child: Text('For you see, as.'),
                            ),
                            const Expanded(flex: 2, child: Text('453.55 MXN')),
                            const Expanded(child: Text('5')),
                            const Expanded(child: Text('10%')),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '2,267.75 MXN',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: portrait ? 260 : 300,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              _PreviewSummaryRow(
                                label: 'Subtotal',
                                value: '\$1,955.00',
                                color: primary,
                              ),
                              const SizedBox(height: 8),
                              _PreviewSummaryRow(
                                label: 'IVA',
                                value: '\$312.75',
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(height: 8),
                              _PreviewSummaryRow(
                                label: 'Total',
                                value: '\$2,267.75',
                                color: secondary,
                                strong: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (embedAttachments) ...[
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Adjuntos incluidos: ficha-tecnica.pdf, evidencia-obra.jpg',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: secondaryFont,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (showPageNumber) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Página 1 / 1 • $pageSize',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: secondaryFont,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (showPaidStamp)
                    Positioned(
                      right: 18,
                      top: 160,
                      child: Transform.rotate(
                        angle: -0.18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: secondary),
                          ),
                          child: Text(
                            'PAGADO',
                            style: TextStyle(
                              color: secondary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaxSettingsSection extends ConsumerStatefulWidget {
  const _TaxSettingsSection({super.key, required this.empresa});

  final EmpresaPerfil empresa;

  @override
  ConsumerState<_TaxSettingsSection> createState() =>
      _TaxSettingsSectionState();
}

class _TaxSettingsSectionState extends ConsumerState<_TaxSettingsSection> {
  late final TextEditingController _tasasLineaController;
  late final TextEditingController _impuestosGastosController;
  late final TextEditingController _impuestosInclusivosController;
  late final TextEditingController _tasaPredeterminadaController;
  bool _isSaving = false;

  ConfiguracionImpuestos get _impuestos => widget.empresa.impuestos;

  @override
  void initState() {
    super.initState();
    _tasasLineaController = TextEditingController(text: _impuestos.tasasLinea);
    _impuestosGastosController = TextEditingController(
      text: _impuestos.impuestosSobreGastos,
    );
    _impuestosInclusivosController = TextEditingController(
      text: _impuestos.impuestosInclusivos,
    );
    _tasaPredeterminadaController = TextEditingController(
      text: _impuestos.tasaPredeterminada,
    );
  }

  @override
  void dispose() {
    _tasasLineaController.dispose();
    _impuestosGastosController.dispose();
    _impuestosInclusivosController.dispose();
    _tasaPredeterminadaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await ref
          .read(configuracionRepositoryProvider)
          .updateEmpresa(
            widget.empresa.copyWith(
              impuestos: _impuestos.copyWith(
                tasasLinea: _tasasLineaController.text.trim(),
                impuestosSobreGastos: _impuestosGastosController.text.trim(),
                impuestosInclusivos: _impuestosInclusivosController.text.trim(),
                tasaPredeterminada: _tasaPredeterminadaController.text.trim(),
              ),
            ),
          );
      ref.invalidate(empresaPerfilControllerProvider);

      if (!mounted) return;
      ToastHelper.show(context, 'Configuración de impuestos guardada.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormShellCard(
      title: 'Impuestos',
      child: Column(
        children: [
          _EditableFieldRow(
            label: 'Tasas de linea',
            controller: _tasasLineaController,
          ),
          _EditableFieldRow(
            label: 'Impuestos sobre gastos',
            controller: _impuestosGastosController,
          ),
          _EditableFieldRow(
            label: 'Impuestos inclusivos',
            controller: _impuestosInclusivosController,
          ),
          _EditableFieldRow(
            label: 'Tasa predeterminada',
            controller: _tasaPredeterminadaController,
          ),
          _SettingsActionBar(
            label: 'Guardar impuestos',
            isSaving: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ConfigSectionTitle extends StatelessWidget {
  const _ConfigSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PlanUpgradeColumn extends StatelessWidget {
  const _PlanUpgradeColumn({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      if (!plan.incluyeMarcaAgua) 'Remove Invoice Ninja logo',
      if (plan.limiteClientes < 0) 'Unlimited Clients',
      if (plan.incluyePersonalizacionPdf) 'Advanced Customization',
      if (plan.id == 'empresa') 'Additional Account Users',
      if (plan.id == 'empresa') 'Attach Files to Emails (pdf, jpg, xls..)',
      if (plan.id == 'empresa') 'Custom URL “invoice.company.com”',
      if (plan.id == 'empresa') 'Auto-sync Bank Transactions',
      if (plan.id == 'pro') 'REST API Access',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.nombre,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.empresa, required this.plan});

  final EmpresaPerfil empresa;
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visa terminación 4242',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Facturación automática activada',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _planPriceLabel(plan),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(label: 'Titular', value: empresa.nombreComercial),
          _InfoLine(label: 'Correo de facturación', value: empresa.correo),
        ],
      ),
    );
  }
}

class _PaymentMethodAddCard extends StatelessWidget {
  const _PaymentMethodAddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 188,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 34, color: AppColors.textPrimary),
            SizedBox(height: 18),
            Text(
              'Add Payment Method',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerActionCard extends StatelessWidget {
  const _DangerActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.error, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormShellCard extends StatelessWidget {
  const _FormShellCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _EditableFieldRow extends StatelessWidget {
  const _EditableFieldRow({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final input = TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: maxLines > 1 ? maxLines : 1,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                input,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 190,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(child: input),
            ],
          );
        },
      ),
    );
  }
}

class _SelectableFieldRow extends StatelessWidget {
  const _SelectableFieldRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<({String value, String label})> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final input = DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            menuMaxHeight: 320,
            borderRadius: cotimaxMenuBorderRadius,
            dropdownColor: AppColors.white,
            icon: cotimaxDropdownIcon,
            style: cotimaxDropdownTextStyle,
            decoration: cotimaxDropdownDecoration(),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(
                      option.label,
                      overflow: TextOverflow.ellipsis,
                      style: cotimaxDropdownTextStyle,
                    ),
                  ),
                )
                .toList(),
            onChanged: (newValue) {
              if (newValue == null) return;
              onChanged(newValue);
            },
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                input,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 190,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(child: input),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsActionBar extends StatelessWidget {
  const _SettingsActionBar({
    required this.label,
    required this.isSaving,
    required this.onPressed,
  });

  final String label;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: isSaving ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          child: Text(isSaving ? 'Guardando...' : label),
        ),
      ),
    );
  }
}

class _DesignSelectRow extends StatelessWidget {
  const _DesignSelectRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              menuMaxHeight: 320,
              borderRadius: cotimaxMenuBorderRadius,
              dropdownColor: AppColors.white,
              icon: cotimaxDropdownIcon,
              style: cotimaxDropdownTextStyle,
              decoration: cotimaxDropdownDecoration(),
              items: options
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                        style: cotimaxDropdownTextStyle,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue == null) return;
                onChanged(newValue);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignDoubleInputRow extends StatelessWidget {
  const _DesignDoubleInputRow({
    required this.label,
    required this.leftValue,
    required this.leftOptions,
    required this.rightController,
    required this.onLeftChanged,
  });

  final String label;
  final String leftValue;
  final List<String> leftOptions;
  final TextEditingController rightController;
  final ValueChanged<String> onLeftChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: leftValue,
                    isExpanded: true,
                    menuMaxHeight: 320,
                    borderRadius: cotimaxMenuBorderRadius,
                    dropdownColor: AppColors.white,
                    icon: cotimaxDropdownIcon,
                    style: cotimaxDropdownTextStyle,
                    decoration: cotimaxDropdownDecoration(),
                    items: leftOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(
                              option,
                              overflow: TextOverflow.ellipsis,
                              style: cotimaxDropdownTextStyle,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue == null) return;
                      onLeftChanged(newValue);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: rightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [
                      NumericTextInputFormatter(maxDecimalDigits: 2),
                    ],
                    decoration: const InputDecoration(hintText: '24'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignColorRow extends StatelessWidget {
  const _DesignColorRow({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _hexToColor(
                        controller.text,
                        fallback: Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(6),
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
}

class _DesignToggleRow extends StatelessWidget {
  const _DesignToggleRow({
    required this.label,
    required this.value,
    this.onChanged,
    this.helper,
    this.enabled = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? helper;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final interactive = onChanged != null || enabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    helper!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: interactive
                ? (newValue) => onChanged?.call(newValue)
                : null,
          ),
        ],
      ),
    );
  }
}

class _DesignRadioRow extends StatelessWidget {
  const _DesignRadioRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: options
                  .map(
                    (option) => InkWell(
                      onTap: () => onChanged(option),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            option == value
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: option == value
                                ? AppColors.textPrimary
                                : AppColors.border,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            option,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignDivider extends StatelessWidget {
  const _DesignDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 1,
      color: AppColors.border,
    );
  }
}

class _PresetDesignCard extends StatelessWidget {
  const _PresetDesignCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMeta extends StatelessWidget {
  const _PreviewMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSummaryRow extends StatelessWidget {
  const _PreviewSummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: strong ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _LogoPreviewCard extends StatelessWidget {
  const _LogoPreviewCard({required this.background, required this.imagePath});

  final Color background;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.trim().isNotEmpty;
    return Container(
      width: 250,
      height: 102,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: hasImage
          ? _OptionalAssetImage(imagePath: imagePath, fit: BoxFit.contain)
          : const SizedBox.shrink(),
    );
  }
}

class _OptionalAssetImage extends StatelessWidget {
  const _OptionalAssetImage({
    required this.imagePath,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String imagePath;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty) {
      return const SizedBox.shrink();
    }

    return Image.asset(
      normalizedPath,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

Color _hexToColor(String value, {required Color fallback}) {
  final normalized = value.replaceAll('#', '').trim();
  if (normalized.length != 6) return fallback;
  final parsed = int.tryParse('FF$normalized', radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}

String _planPriceLabel(Plan plan) {
  if (plan.billingMode == 'per_user_monthly') {
    return '\$${plan.precioPorUsuario.toStringAsFixed(0)} MXN/usuario/mes';
  }
  if (plan.precioMensual <= 0) {
    return 'Gratis';
  }
  return '\$${plan.precioMensual.toStringAsFixed(0)} MXN/mes';
}

String _planUsersLabel(Plan plan) {
  if (plan.usuariosMinimos > 0 && plan.usuariosMaximos > 0) {
    return '${plan.usuariosMinimos}-${plan.usuariosMaximos}';
  }
  if (plan.limiteUsuarios < 0) {
    return 'Ilimitados';
  }
  return '${plan.limiteUsuarios}';
}
