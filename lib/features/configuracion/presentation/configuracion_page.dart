import 'dart:async';
import 'dart:typed_data';

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/platform/logo_picker.dart';
import 'package:cotimax/features/configuracion/application/configuracion_controller.dart';
import 'package:cotimax/features/clientes/application/clientes_controller.dart';
import 'package:cotimax/features/planes/application/planes_controller.dart';
import 'package:cotimax/features/cotizaciones/application/cotizacion_pdf_service.dart';
import 'package:cotimax/features/cotizaciones/application/cotizaciones_controller.dart';
import 'package:cotimax/features/productos/application/productos_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_rich_text_editor.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

List<({String value, String label})> localizationCurrencyOptions = [
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

List<({String value, String label})> localizationLanguageOptions = [
  (value: 'es-MX', label: 'Español'),
  (value: 'en-US', label: 'Inglés'),
];

List<({String value, String label})> localizationTimezoneOptions = [
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

List<({String value, String label})> localizationDateFormatOptions = [
  (value: 'dd/MM/yyyy', label: 'dd/MM/yyyy'),
  (value: 'dd-MM-yyyy', label: 'dd-MM-yyyy'),
  (value: 'MM/dd/yyyy', label: 'MM/dd/yyyy'),
  (value: 'yyyy-MM-dd', label: 'yyyy-MM-dd'),
  (value: 'dd MMM yyyy', label: 'dd MMM yyyy'),
  (value: 'MMMM dd, yyyy', label: 'MMMM dd, yyyy'),
];

List<({String value, String label})> localizationMoneyFormatOptions = [
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
  ConfiguracionPage({super.key});

  @override
  ConsumerState<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends ConsumerState<ConfiguracionPage> {
  int _mainTabIndex = 0;
  int _accountTabIndex = 0;
  int _invoiceTabIndex = 0;
  int _companyTabIndex = 0;

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
  String _quoteDesign = 'corporativo';
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
  bool _showPageNumber = false;

  late final TextEditingController _logoSizeController;
  late final TextEditingController _primaryColorController;
  late final TextEditingController _secondaryColorController;
  late final TextEditingController _backgroundColorController;
  late final TextEditingController _neutralColorController;
  bool _isSavingDesign = false;
  String? _designSeedVersion;

  static const _mainTabs = [
    'Gestión de cuenta',
    'Empresa',
    'Localización',
    'Diseño de cotización',
    'Impuestos',
  ];

  static const _accountTabs = [
    'Plan',
    'Descripción general',
    'Apariencia',
    'Módulos habilitados',
    'Zona peligrosa',
  ];

  static const _invoiceTabs = ['Configuración General', 'Cliente'];

  @override
  void initState() {
    super.initState();
    _logoSizeController = TextEditingController(text: '24');
    _primaryColorController = TextEditingController(text: '000000');
    _secondaryColorController = TextEditingController(text: 'F8B142');
    _backgroundColorController = TextEditingController(text: 'F7F9FC');
    _neutralColorController = TextEditingController(text: '1F2937');
  }

  @override
  void dispose() {
    _logoSizeController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _backgroundColorController.dispose();
    _neutralColorController.dispose();
    super.dispose();
  }

  void _seedDesignStateFromEmpresa(EmpresaPerfil empresa) {
    final version = '${empresa.id}-${empresa.updatedAt.microsecondsSinceEpoch}';
    if (_designSeedVersion == version) return;
    _designSeedVersion = version;
    _quoteDesign = _normalizeQuoteDesignOption(
      empresa.themeSeleccionado.trim().isEmpty
          ? 'corporativo'
          : empresa.themeSeleccionado.trim(),
    );
    _pageOrientation = empresa.quotePageOrientation;
    _pageSize = empresa.quotePageSize;
    _fontSize = empresa.quoteFontSize.toString();
    _logoSizeMode = empresa.quoteLogoSizeMode;
    _logoSizeController.text = empresa.quoteLogoSizeValue.toStringAsFixed(0);
    _primaryFont = empresa.quotePrimaryFont;
    _secondaryFont = empresa.quoteSecondaryFont;
    _emptyColumnsMode = empresa.quoteEmptyColumnsMode;
    _showPaidStamp = empresa.quoteShowPaidStamp;
    _showShippingAddress = empresa.quoteShowShippingAddress;
    _showPageNumber = empresa.quoteShowPageNumber;
    _primaryColorController.text = empresa.colorPrimario.replaceAll('#', '');
    _secondaryColorController.text = empresa.colorSecundario.replaceAll(
      '#',
      '',
    );
    _backgroundColorController.text = empresa.colorFondo.replaceAll('#', '');
    _neutralColorController.text = empresa.colorNeutro.replaceAll('#', '');
  }

  Future<void> _saveQuoteDesign(
    EmpresaPerfil empresa, {
    bool showToast = true,
  }) async {
    if (_isSavingDesign) return;
    setState(() => _isSavingDesign = true);
    try {
      await ref
          .read(configuracionRepositoryProvider)
          .updateEmpresa(
            empresa.copyWith(
              colorPrimario:
                  '#${_primaryColorController.text.replaceAll('#', '').trim()}',
              colorSecundario:
                  '#${_secondaryColorController.text.replaceAll('#', '').trim()}',
              colorFondo:
                  '#${_backgroundColorController.text.replaceAll('#', '').trim()}',
              colorNeutro:
                  '#${_neutralColorController.text.replaceAll('#', '').trim()}',
              themeSeleccionado: _quoteDesign.trim().isEmpty
                  ? 'corporativo'
                  : _normalizeQuoteDesignOption(_quoteDesign.trim()),
              quotePageOrientation: _pageOrientation,
              quotePageSize: _pageSize,
              quoteFontSize: int.tryParse(_fontSize) ?? 18,
              quoteLogoSizeMode: _logoSizeMode,
              quoteLogoSizeValue:
                  double.tryParse(_logoSizeController.text.trim()) ?? 24,
              quotePrimaryFont: _primaryFont,
              quoteSecondaryFont: _secondaryFont,
              quoteEmptyColumnsMode: _emptyColumnsMode,
              quoteShowPaidStamp: _showPaidStamp,
              quoteShowShippingAddress: _showShippingAddress,
              quoteEmbedAttachments: false,
              quoteShowPageNumber: _showPageNumber,
            ),
          );
      ref.invalidate(empresaPerfilControllerProvider);
      await ref.read(empresaPerfilControllerProvider.future);
      if (!mounted) return;
      if (showToast) {
        ToastHelper.show(context, 'Diseño de cotización guardado.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingDesign = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final mainTabParam = uri.queryParameters['main'];
    final companyTabParam = uri.queryParameters['company'];
    if (mainTabParam == 'empresa' && _mainTabIndex != 1) {
      _mainTabIndex = 1;
    }
    if (companyTabParam == 'defaults' && _companyTabIndex != 2) {
      _companyTabIndex = 2;
    } else if (companyTabParam == 'logo' && _companyTabIndex != 1) {
      _companyTabIndex = 1;
    } else if (companyTabParam == 'details' && _companyTabIndex != 0) {
      _companyTabIndex = 0;
    }
    if (_invoiceTabIndex >= _invoiceTabs.length) {
      _invoiceTabIndex = _invoiceTabs.length - 1;
    }

    final perfil = ref.watch(empresaPerfilControllerProvider);
    final usuarioActual = ref.watch(usuarioActualControllerProvider);

    return ListView(
      children: [
        PageHeader(title: 'Configuración', subtitle: ''),
        SizedBox(height: 12),
        perfil.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No se pudo cargar la configuración.',
            onRetry: () {
              ref.invalidate(empresaPerfilControllerProvider);
              ref.invalidate(usuarioActualControllerProvider);
            },
          ),
          data: (empresa) => usuarioActual.when(
            loading: LoadingSkeleton.new,
            error: (_, __) => ErrorStateWidget(
              message: 'No se pudo cargar la configuración.',
              onRetry: () {
                ref.invalidate(empresaPerfilControllerProvider);
                ref.invalidate(usuarioActualControllerProvider);
              },
            ),
            data: (usuario) {
              _seedDesignStateFromEmpresa(empresa);
              return SectionCard(
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
                              onTap: () =>
                                  setState(() => _mainTabIndex = index),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(height: 1, color: AppColors.border),
                    SizedBox(height: 18),
                    if (_mainTabIndex == 0)
                      _AccountManagementSection(
                        empresa: empresa,
                        usuario: usuario,
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
                          'company-${empresa.updatedAt.microsecondsSinceEpoch}-${usuario.updatedAt.microsecondsSinceEpoch}-$_companyTabIndex',
                        ),
                        empresa: empresa,
                        initialTabIndex: _companyTabIndex,
                        onTabChanged: (index) =>
                            setState(() => _companyTabIndex = index),
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
                        backgroundColorController: _backgroundColorController,
                        neutralColorController: _neutralColorController,
                        primaryFont: _primaryFont,
                        secondaryFont: _secondaryFont,
                        emptyColumnsMode: _emptyColumnsMode,
                        showPaidStamp: _showPaidStamp,
                        showShippingAddress: _showShippingAddress,
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
                        onShowPageNumberChanged: (value) =>
                            setState(() => _showPageNumber = value),
                        isSaving: _isSavingDesign,
                        onColorApplied: () =>
                            _saveQuoteDesign(empresa, showToast: false),
                        onSave: () => _saveQuoteDesign(empresa),
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
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopConfigTab extends StatelessWidget {
  _TopConfigTab({
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
        padding: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          trText(label),
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

class _AccountManagementSection extends ConsumerWidget {
  _AccountManagementSection({
    required this.empresa,
    required this.usuario,
    required this.tabIndex,
    required this.tabs,
    required this.enabledModules,
    required this.onTabChanged,
    required this.onModuleChanged,
  });

  final EmpresaPerfil empresa;
  final UsuarioActual usuario;
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
              Text(
                trText('Gestión de cuenta'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14),
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
              SizedBox(height: 4),
              Container(height: 1, color: AppColors.border),
              SizedBox(height: 18),
              if (tabIndex == 0)
                _PlanAndBillingPanel(
                  empresa: empresa,
                  plan: currentPlan,
                  suscripcion: suscripcion,
                  allPlans: planes,
                ),
              if (tabIndex == 1)
                _GeneralAccountPanel(
                  empresa: empresa,
                  plan: currentPlan,
                  suscripcion: suscripcion,
                ),
              if (tabIndex == 2)
                _AppearanceAccountPanel(initialDarkMode: usuario.modoOscuro),
              if (tabIndex == 3)
                _EnabledModulesPanel(
                  enabledModules: enabledModules,
                  onChanged: onModuleChanged,
                ),
              if (tabIndex == 4) _DangerZonePanel(),
            ],
          );
        },
      ),
    );
  }
}

class _AppearanceAccountPanel extends ConsumerStatefulWidget {
  _AppearanceAccountPanel({required this.initialDarkMode});

  final bool initialDarkMode;

  @override
  ConsumerState<_AppearanceAccountPanel> createState() =>
      _AppearanceAccountPanelState();
}

class _AppearanceAccountPanelState
    extends ConsumerState<_AppearanceAccountPanel> {
  late bool _modoOscuro;

  @override
  void initState() {
    super.initState();
    _modoOscuro = widget.initialDarkMode;
  }

  @override
  void didUpdateWidget(covariant _AppearanceAccountPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDarkMode != widget.initialDarkMode &&
        !ref.read(themeChangeInProgressProvider)) {
      _modoOscuro = widget.initialDarkMode;
    }
  }

  Future<void> _handleDarkModeChanged(bool value) async {
    if (_modoOscuro == value || ref.read(themeChangeInProgressProvider)) {
      return;
    }

    final previousValue = _modoOscuro;
    final nextThemeMode = value ? ThemeMode.dark : ThemeMode.light;
    final previousThemeMode = previousValue ? ThemeMode.dark : ThemeMode.light;

    setState(() => _modoOscuro = value);
    ref.read(themeChangeInProgressProvider.notifier).state = true;
    await WidgetsBinding.instance.endOfFrame;
    ref.read(themeModeOverrideProvider.notifier).state = nextThemeMode;
    await WidgetsBinding.instance.endOfFrame;

    try {
      await ref
          .read(configuracionRepositoryProvider)
          .updateUsuarioActualThemeMode(value);
      ref.invalidate(usuarioActualControllerProvider);
      await ref.read(usuarioActualControllerProvider.future);
      ref.read(themeModeOverrideProvider.notifier).state = null;

      if (!mounted) return;
      ToastHelper.show(context, 'Modo oscuro actualizado.');
    } catch (_) {
      ref.read(themeModeOverrideProvider.notifier).state = previousThemeMode;
      if (mounted) {
        setState(() => _modoOscuro = previousValue);
        ToastHelper.show(context, 'No se pudo actualizar el modo oscuro.');
      }
    } finally {
      ref.read(themeChangeInProgressProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormShellCard(
      title: 'Apariencia',
      icon: Icons.dark_mode_outlined,
      child: Column(
        children: [
          _DesignToggleRow(
            label: 'Modo oscuro',
            value: _modoOscuro,
            helper:
                'Aplica la interfaz oscura en toda la aplicación para tu usuario.',
            onChanged: _handleDarkModeChanged,
          ),
        ],
      ),
    );
  }
}

class _PlanAndBillingPanel extends StatelessWidget {
  _PlanAndBillingPanel({
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
        _ConfigSectionTitle(title: 'Tu plan'),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(18),
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
                      trText(plan.nombre),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      trText(plan.descripcion),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${trText('Renueva')} ${DateFormat('dd MMM yyyy', currentIntlLocale()).format(suscripcion.fechaFin)}',
                      style: TextStyle(
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
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(18),
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
                  padding: EdgeInsets.only(left: 10),
                  child: FilledButton(
                    onPressed: () => ToastHelper.show(
                      context,
                      'Gestión de actualización disponible pronto.',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                    child: Text(trText('Plan de actualización')),
                  ),
                ),
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trText(
                      'Actualiza a los planes Pro o Enterprise para funciones avanzadas.',
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  stacked
                      ? Column(
                          children: [
                            for (
                              var index = 0;
                              index < upgradePlans.length;
                              index++
                            ) ...[
                              _PlanUpgradeColumn(plan: upgradePlans[index]),
                              SizedBox(height: 12),
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(trText('Plan de actualización')),
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
        SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: _ConfigSectionTitle(title: 'Método de pago')),
            TextButton.icon(
              onPressed: () => ToastHelper.show(
                context,
                'Agregar método de pago disponible pronto.',
              ),
              icon: Icon(Icons.add, size: 16),
              label: Text(trText('Agregar método de pago')),
            ),
          ],
        ),
        SizedBox(height: 12),
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
                'Agregar método de pago disponible pronto.',
              ),
            );

            if (stacked) {
              return Column(
                children: [paymentCard, SizedBox(height: 12), addCard],
              );
            }

            return Row(
              children: [
                Expanded(child: paymentCard),
                SizedBox(width: 12),
                SizedBox(width: 250, child: addCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GeneralAccountPanel extends ConsumerWidget {
  _GeneralAccountPanel({
    required this.empresa,
    required this.plan,
    required this.suscripcion,
  });

  final EmpresaPerfil empresa;
  final Plan plan;
  final Suscripcion suscripcion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientes =
        ref.watch(clientesControllerProvider).valueOrNull ?? const <Cliente>[];
    final productos =
        ref.watch(productosControllerProvider).valueOrNull ??
        const <ProductoServicio>[];
    final cotizaciones =
        ref.watch(cotizacionesControllerProvider).valueOrNull ??
        const <Cotizacion>[];
    final quoteWindow = _monthlyQuoteWindow(suscripcion.fechaInicio);
    final monthlyQuotesUsed = cotizaciones.where((quote) {
      return !quote.fechaEmision.isBefore(quoteWindow.start) &&
          quote.fechaEmision.isBefore(quoteWindow.end);
    }).length;
    final locale = currentIntlLocale();
    final renewalDate = DateFormat(
      'dd MMM yyyy',
      locale,
    ).format(suscripcion.fechaFin);
    final resetDate = DateFormat('dd MMM yyyy', locale).format(quoteWindow.end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormShellCard(
          title: 'Resumen de cuenta',
          icon: Icons.badge_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 860;
                  final metrics = Wrap(
                    spacing: 18,
                    runSpacing: 16,
                    children: [
                      _AccountMetricCard(
                        icon: Icons.apartment_rounded,
                        label: 'Plan activo',
                        value: plan.nombre,
                      ),
                      _AccountMetricCard(
                        icon: Icons.event_available_rounded,
                        label: 'Renovación',
                        value: renewalDate,
                        helper: _friendlyFutureDateLabel(suscripcion.fechaFin),
                      ),
                      _AccountMetricCard(
                        icon: Icons.group_rounded,
                        label: 'Usuarios activos',
                        value:
                            '${suscripcion.usuariosActivos} de ${_planUsersLabel(plan)}',
                      ),
                      _AccountMetricCard(
                        icon: Icons.sync_rounded,
                        label: 'Estado',
                        value: suscripcion.renovacionAutomatica
                            ? 'Renovación automática'
                            : 'Renovación manual',
                      ),
                    ],
                  );

                  final companySummary = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empresa.nombreComercial,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Cuenta principal y datos de contacto de la empresa.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      _AccountDetailLine(
                        icon: Icons.mail_outline_rounded,
                        label: 'Correo principal',
                        value: empresa.correo,
                      ),
                      _AccountDetailLine(
                        icon: Icons.call_outlined,
                        label: 'Teléfono',
                        value: empresa.telefono,
                      ),
                      _AccountDetailLine(
                        icon: Icons.language_rounded,
                        label: 'Sitio web',
                        value: empresa.sitioWeb,
                      ),
                    ],
                  );

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [companySummary, SizedBox(height: 16), metrics],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: companySummary),
                      SizedBox(width: 18),
                      Expanded(flex: 4, child: metrics),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _FormShellCard(
          title: 'Capacidad actual',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monitorea el uso actual de tu plan y la próxima recarga de cotizaciones mensuales.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              _CapacityUsageCard(
                icon: Icons.people_alt_rounded,
                label: 'Clientes',
                used: clientes.length,
                limit: plan.limiteClientes,
                accent: AppColors.primary,
              ),
              SizedBox(height: 14),
              _CapacityUsageCard(
                icon: Icons.inventory_2_rounded,
                label: 'Productos',
                used: productos.length,
                limit: plan.limiteProductos,
                accent: AppColors.accent,
              ),
              SizedBox(height: 14),
              _CapacityUsageCard(
                icon: Icons.request_quote_rounded,
                label: 'Cotizaciones mensuales',
                used: monthlyQuotesUsed,
                limit: plan.limiteCotizacionesMensuales,
                accent: AppColors.success,
                helper:
                    'Ciclo actual: ${DateFormat('dd MMM', locale).format(quoteWindow.start)} - $resetDate',
                footer:
                    'Se recargan ${_friendlyFutureDateLabel(quoteWindow.end).toLowerCase()} ($resetDate).',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EnabledModulesPanel extends StatelessWidget {
  _EnabledModulesPanel({required this.enabledModules, required this.onChanged});

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
          Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _ConfigSectionTitle(
                title: 'Módulos habilitados',
                icon: Icons.view_module_rounded,
              ),
            ),
          ),
          for (var index = 0; index < entries.length; index++)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: index == 0
                      ? BorderSide.none
                      : BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      trText(entries[index].key),
                      style: TextStyle(
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
  _DangerZonePanel();

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
        SizedBox(height: 12),
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
  _CompanySettingsSection({
    super.key,
    required this.empresa,
    required this.initialTabIndex,
    required this.onTabChanged,
  });

  final EmpresaPerfil empresa;
  final int initialTabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  ConsumerState<_CompanySettingsSection> createState() =>
      _CompanySettingsSectionState();
}

class _CompanySettingsSectionState
    extends ConsumerState<_CompanySettingsSection> {
  static const _tabs = ['Detalles de empresa', 'Logo', 'Valores por defecto'];

  int _tabIndex = 0;
  late final TextEditingController _nombreComercialController;
  late final TextEditingController _nombreFiscalController;
  late final TextEditingController _rfcController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _sitioWebController;
  late final TextEditingController _calleController;
  late final TextEditingController _apartamentoSuiteController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _estadoController;
  late final TextEditingController _codigoPostalController;
  late final TextEditingController _paisController;
  late final quill.QuillController _notasDefaultController;
  late final quill.QuillController _notasPrivadasDefaultController;
  late final quill.QuillController _terminosDefaultController;
  late final quill.QuillController _piePaginaDefaultController;
  late String _logoDataUrl;
  bool _isSaving = false;

  EmpresaPerfil get _empresa => widget.empresa;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
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
    _calleController = TextEditingController(text: _empresa.calle);
    _apartamentoSuiteController = TextEditingController(
      text: _empresa.apartamentoSuite,
    );
    _ciudadController = TextEditingController(text: _empresa.ciudad);
    _estadoController = TextEditingController(text: _empresa.estadoProvincia);
    _codigoPostalController = TextEditingController(
      text: _empresa.codigoPostal,
    );
    _paisController = TextEditingController(text: _empresa.pais);
    _notasDefaultController = buildRichTextController(_empresa.notasDefault);
    _notasPrivadasDefaultController = buildRichTextController(
      _empresa.notasPrivadasDefault,
    );
    _terminosDefaultController = buildRichTextController(
      _empresa.terminosDefault,
    );
    _piePaginaDefaultController = buildRichTextController(
      _empresa.piePaginaDefault,
    );
    _logoDataUrl = _empresa.logoUrl;
  }

  @override
  void didUpdateWidget(covariant _CompanySettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        widget.initialTabIndex != _tabIndex) {
      _tabIndex = widget.initialTabIndex;
    }
    if (oldWidget.empresa.logoUrl != widget.empresa.logoUrl &&
        _logoDataUrl == oldWidget.empresa.logoUrl) {
      _logoDataUrl = widget.empresa.logoUrl;
    }
  }

  @override
  void dispose() {
    _nombreComercialController.dispose();
    _nombreFiscalController.dispose();
    _rfcController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _sitioWebController.dispose();
    _calleController.dispose();
    _apartamentoSuiteController.dispose();
    _ciudadController.dispose();
    _estadoController.dispose();
    _codigoPostalController.dispose();
    _paisController.dispose();
    _notasDefaultController.dispose();
    _notasPrivadasDefaultController.dispose();
    _terminosDefaultController.dispose();
    _piePaginaDefaultController.dispose();
    super.dispose();
  }

  Future<void> _saveCompanyDetails() async {
    final nombreComercial = _nombreComercialController.text.trim();
    final nombreFiscal = _nombreFiscalController.text.trim();
    final calle = _calleController.text.trim();
    final apartamentoSuite = _apartamentoSuiteController.text.trim();
    final ciudad = _ciudadController.text.trim();
    final estadoProvincia = _estadoController.text.trim();
    final codigoPostal = _codigoPostalController.text.trim();
    final pais = _paisController.text.trim();
    final direccionCompuesta = [
      calle,
      if (apartamentoSuite.isNotEmpty) apartamentoSuite,
      if (ciudad.isNotEmpty) ciudad,
      if (estadoProvincia.isNotEmpty) estadoProvincia,
      if (codigoPostal.isNotEmpty) codigoPostal,
      if (pais.isNotEmpty) pais,
    ].where((part) => part.trim().isNotEmpty).join(', ');

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
              direccion: direccionCompuesta,
              calle: calle,
              apartamentoSuite: apartamentoSuite,
              ciudad: ciudad,
              estadoProvincia: estadoProvincia,
              codigoPostal: codigoPostal,
              pais: pais,
              logoUrl: _logoDataUrl.trim(),
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

  Future<void> _pickLogo() async {
    final selected = await pickLogoDataUrl();
    if (!mounted || selected == null || selected.trim().isEmpty) return;
    setState(() => _logoDataUrl = selected);
  }

  Future<void> _saveQuoteDefaults() async {
    setState(() => _isSaving = true);

    try {
      await ref
          .read(configuracionRepositoryProvider)
          .updateEmpresa(
            _empresa.copyWith(
              notasDefault: serializeRichTextController(
                _notasDefaultController,
              ),
              notasPrivadasDefault: serializeRichTextController(
                _notasPrivadasDefaultController,
              ),
              terminosDefault: serializeRichTextController(
                _terminosDefaultController,
              ),
              piePaginaDefault: serializeRichTextController(
                _piePaginaDefaultController,
              ),
            ),
          );
      ref.invalidate(empresaPerfilControllerProvider);

      if (!mounted) return;
      ToastHelper.show(context, 'Valores por defecto de cotización guardados.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildCompanyDetailsTab() {
    return _FormShellCard(
      title: 'Detalles de empresa',
      icon: Icons.apartment_rounded,
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
            label: 'Calle',
            controller: _calleController,
            maxLines: 2,
          ),
          _EditableFieldRow(
            label: 'Apartamento/Suite',
            controller: _apartamentoSuiteController,
          ),
          _EditableFieldRow(label: 'Ciudad', controller: _ciudadController),
          _EditableFieldRow(label: 'Estado', controller: _estadoController),
          _EditableFieldRow(
            label: 'Código postal',
            controller: _codigoPostalController,
          ),
          _EditableFieldRow(label: 'País', controller: _paisController),
          _SettingsActionBar(
            label: 'Guardar empresa',
            isSaving: _isSaving,
            onPressed: _saveCompanyDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoTab() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trText('Logo'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            trText(
              'Actualiza el logotipo y guárdalo junto con los datos de la empresa.',
            ),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _pickLogo,
                icon: Icon(Icons.upload_rounded, size: 16),
                label: Text(
                  trText(
                    _logoDataUrl.trim().isEmpty
                        ? 'Cargar logo'
                        : 'Cambiar logo',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (_logoDataUrl.trim().isNotEmpty)
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _LogoPreviewCard(
                  background: AppColors.border,
                  imagePath: _logoDataUrl,
                ),
                _LogoPreviewCard(
                  background: AppColors.darkPalette.container,
                  imagePath: _logoDataUrl,
                ),
              ],
            ),
          if (_logoDataUrl.trim().isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                trText('No has cargado un logo todavía.'),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuoteDefaultsTab() {
    return _FormShellCard(
      title: 'Valores por defecto de cotización',
      icon: Icons.text_snippet_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estos textos se cargarán automáticamente al crear una cotización nueva.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          _RichEditableFieldRow(
            label: 'Notas',
            controller: _notasDefaultController,
            placeholder: 'Escribe las notas predeterminadas',
          ),
          _RichEditableFieldRow(
            label: 'Notas privadas',
            controller: _notasPrivadasDefaultController,
            placeholder: 'Escribe las notas privadas predeterminadas',
          ),
          _RichEditableFieldRow(
            label: 'Términos',
            controller: _terminosDefaultController,
            placeholder: 'Escribe los términos predeterminados',
          ),
          _RichEditableFieldRow(
            label: 'Pie de página',
            controller: _piePaginaDefaultController,
            placeholder: 'Escribe el pie de página predeterminado',
          ),
          _SettingsActionBar(
            label: 'Guardar valores por defecto',
            isSaving: _isSaving,
            onPressed: _saveQuoteDefaults,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trText('Empresa'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              _tabs.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  right: index == _tabs.length - 1 ? 0 : 18,
                ),
                child: _TopConfigTab(
                  label: _tabs[index],
                  selected: _tabIndex == index,
                  onTap: () {
                    setState(() => _tabIndex = index);
                    widget.onTabChanged(index);
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 18),
        if (_tabIndex == 0) _buildCompanyDetailsTab(),
        if (_tabIndex == 1) _buildLogoTab(),
        if (_tabIndex == 2) _buildQuoteDefaultsTab(),
      ],
    );
  }
}

class _LocalizationSettingsSection extends ConsumerStatefulWidget {
  _LocalizationSettingsSection({super.key, required this.empresa});

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
    _idioma = normalizeSupportedLanguageTag(_localizacion.idioma);
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
      icon: Icons.public_rounded,
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

class _InvoiceDesignSection extends ConsumerWidget {
  _InvoiceDesignSection({
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
    required this.backgroundColorController,
    required this.neutralColorController,
    required this.primaryFont,
    required this.secondaryFont,
    required this.emptyColumnsMode,
    required this.showPaidStamp,
    required this.showShippingAddress,
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
    required this.onShowPageNumberChanged,
    required this.isSaving,
    required this.onColorApplied,
    required this.onSave,
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
  final TextEditingController backgroundColorController;
  final TextEditingController neutralColorController;
  final String primaryFont;
  final String secondaryFont;
  final String emptyColumnsMode;
  final bool showPaidStamp;
  final bool showShippingAddress;
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
  final ValueChanged<bool> onShowPageNumberChanged;
  final bool isSaving;
  final Future<void> Function() onColorApplied;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cotizaciones =
        ref.watch(cotizacionesControllerProvider).valueOrNull ??
        const <Cotizacion>[];
    Cotizacion? previewQuote;
    if (cotizaciones.isNotEmpty) {
      final ordered = [...cotizaciones]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      previewQuote = ordered.first;
    }
    final previewEmpresa = empresa.copyWith(
      colorPrimario:
          '#${primaryColorController.text.replaceAll('#', '').trim()}',
      colorSecundario:
          '#${secondaryColorController.text.replaceAll('#', '').trim()}',
      colorFondo:
          '#${backgroundColorController.text.replaceAll('#', '').trim()}',
      colorNeutro: '#${neutralColorController.text.replaceAll('#', '').trim()}',
      themeSeleccionado: quoteDesign.trim().isEmpty
          ? 'corporativo'
          : _normalizeQuoteDesignOption(quoteDesign.trim()),
      quotePageOrientation: pageOrientation,
      quotePageSize: pageSize,
      quoteFontSize: int.tryParse(fontSize) ?? 18,
      quoteLogoSizeMode: logoSizeMode,
      quoteLogoSizeValue: double.tryParse(logoSizeController.text.trim()) ?? 24,
      quotePrimaryFont: primaryFont,
      quoteSecondaryFont: secondaryFont,
      quoteEmptyColumnsMode: emptyColumnsMode,
      quoteShowPaidStamp: showPaidStamp,
      quoteShowShippingAddress: showShippingAddress,
      quoteEmbedAttachments: false,
      quoteShowPageNumber: showPageNumber,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigSectionTitle(
          title: 'Diseño de cotización',
          icon: Icons.palette_rounded,
        ),
        SizedBox(height: 14),
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
        SizedBox(height: 18),
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
              backgroundColorController: backgroundColorController,
              neutralColorController: neutralColorController,
              primaryFont: primaryFont,
              secondaryFont: secondaryFont,
              emptyColumnsMode: emptyColumnsMode,
              showPaidStamp: showPaidStamp,
              showShippingAddress: showShippingAddress,
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
              onShowPageNumberChanged: onShowPageNumberChanged,
              isSaving: isSaving,
              onColorApplied: onColorApplied,
              onSave: onSave,
            );
            final preview = _InvoicePreviewPanel(
              quote: previewQuote,
              empresa: previewEmpresa,
            );

            if (stacked) {
              return Column(
                children: [
                  controls,
                  SizedBox(height: 14),
                  SizedBox(height: 820, child: preview),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 520, child: controls),
                SizedBox(width: 16),
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
  _InvoiceControlsPanel({
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
    required this.backgroundColorController,
    required this.neutralColorController,
    required this.primaryFont,
    required this.secondaryFont,
    required this.emptyColumnsMode,
    required this.showPaidStamp,
    required this.showShippingAddress,
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
    required this.onShowPageNumberChanged,
    required this.isSaving,
    required this.onColorApplied,
    required this.onSave,
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
  final TextEditingController backgroundColorController;
  final TextEditingController neutralColorController;
  final String primaryFont;
  final String secondaryFont;
  final String emptyColumnsMode;
  final bool showPaidStamp;
  final bool showShippingAddress;
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
  final ValueChanged<bool> onShowPageNumberChanged;
  final bool isSaving;
  final Future<void> Function() onColorApplied;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (tabIndex == 1) {
      return _FormShellCard(
        title: 'Cliente',
        child: Column(
          children: [
            _DesignToggleRow(
              label: 'Mostrar resumen para cliente',
              value: true,
              enabled: true,
            ),
            _DesignToggleRow(
              label: 'Mostrar dirección de envío',
              value: showShippingAddress,
              onChanged: onShowShippingAddressChanged,
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
            label: 'Diseño de cotización',
            value: quoteDesign,
            options: const [
              'corporativo',
              'industrial',
              'minimal',
              'destacado',
              'editorial',
            ],
            optionLabelBuilder: _quoteDesignLabel,
            onChanged: onQuoteDesignChanged,
          ),
          _DesignSelectRow(
            label: 'Diseño de página',
            value: pageOrientation,
            options: const ['Retrato', 'Horizontal'],
            onChanged: onPageOrientationChanged,
          ),
          _DesignSelectRow(
            label: 'Tamaño de página',
            value: pageSize,
            options: const ['A4', 'Letter', 'Legal', 'Oficio', 'Tabloid'],
            onChanged: onPageSizeChanged,
          ),
          _DesignSelectRow(
            label: 'Tamaño de Letra',
            value: fontSize,
            options: const [
              '10',
              '11',
              '12',
              '13',
              '14',
              '16',
              '18',
              '20',
              '24',
            ],
            onChanged: onFontSizeChanged,
          ),
          _DesignDoubleInputRow(
            label: 'Tamaño del logotipo',
            leftValue: logoSizeMode,
            leftOptions: const ['Porcentaje', 'Px', 'Ancho fijo'],
            rightController: logoSizeController,
            onLeftChanged: onLogoSizeModeChanged,
          ),
          _DesignDivider(),
          _DesignSelectRow(
            label: 'Fuente principal',
            value: primaryFont,
            options: const [
              'Arimo',
              'Montserrat',
              'Lora',
              'Poppins',
              'Playfair Display',
              'Merriweather',
              'Open Sans',
            ],
            onChanged: onPrimaryFontChanged,
          ),
          _DesignColorRow(
            label: 'Color Primario',
            controller: primaryColorController,
            onApplied: onColorApplied,
          ),
          _DesignColorRow(
            label: 'Color de fondo',
            controller: backgroundColorController,
            onApplied: onColorApplied,
          ),
          _DesignDivider(),
          _DesignSelectRow(
            label: 'Fuente secundaria',
            value: secondaryFont,
            options: const [
              'Arimo',
              'Montserrat',
              'Lora',
              'Poppins',
              'Playfair Display',
              'Merriweather',
              'Open Sans',
            ],
            onChanged: onSecondaryFontChanged,
          ),
          _DesignColorRow(
            label: 'Color Secundario',
            controller: secondaryColorController,
            onApplied: onColorApplied,
          ),
          _DesignColorRow(
            label: 'Color neutro',
            controller: neutralColorController,
            onApplied: onColorApplied,
          ),
          _DesignDivider(),
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
          _SettingsActionBar(
            label: 'Guardar diseño de cotización',
            isSaving: isSaving,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _InvoicePreviewPanel extends StatefulWidget {
  _InvoicePreviewPanel({required this.empresa, required this.quote});

  final EmpresaPerfil empresa;
  final Cotizacion? quote;

  @override
  State<_InvoicePreviewPanel> createState() => _InvoicePreviewPanelState();
}

class _InvoicePreviewPanelState extends State<_InvoicePreviewPanel> {
  Future<Uint8List>? _pdfFuture;
  String? _previewSignature;
  Timer? _previewDebounce;
  bool _isDesignSwitching = false;

  @override
  void initState() {
    super.initState();
    _refreshPreview(force: true);
  }

  @override
  void didUpdateWidget(covariant _InvoicePreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final designChanged =
        oldWidget.empresa.themeSeleccionado != widget.empresa.themeSeleccionado;
    _refreshPreview(force: designChanged, designSwitched: designChanged);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
  }

  void _refreshPreview({bool force = false, bool designSwitched = false}) {
    final quote = widget.quote;
    if (quote == null) {
      if (force || _pdfFuture != null || _previewSignature != null) {
        setState(() {
          _pdfFuture = null;
          _previewSignature = null;
          _isDesignSwitching = false;
        });
      }
      return;
    }

    final signature = [
      quote.id,
      quote.updatedAt.microsecondsSinceEpoch,
      widget.empresa.themeSeleccionado,
      widget.empresa.quotePageOrientation,
      widget.empresa.quotePageSize,
      widget.empresa.quoteFontSize,
      widget.empresa.quoteLogoSizeValue,
      widget.empresa.quotePrimaryFont,
      widget.empresa.quoteSecondaryFont,
      widget.empresa.quoteShowPaidStamp,
      widget.empresa.quoteShowShippingAddress,
      widget.empresa.quoteEmbedAttachments,
      widget.empresa.quoteShowPageNumber,
      widget.empresa.colorPrimario,
      widget.empresa.colorSecundario,
      widget.empresa.colorFondo,
      widget.empresa.colorNeutro,
    ].join('|');

    if (!force && signature == _previewSignature) return;

    if (!force) {
      _previewDebounce?.cancel();
      _previewDebounce = Timer(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _applyPreview(signature, quote, designSwitched: designSwitched);
      });
      return;
    }

    _applyPreview(signature, quote, designSwitched: designSwitched);
  }

  void _applyPreview(
    String signature,
    Cotizacion quote, {
    bool designSwitched = false,
  }) {
    final future =
        CotizacionPdfService.generate(
          quote,
          useCache: true,
          empresaOverride: widget.empresa,
        ).timeout(
          const Duration(seconds: 25),
          onTimeout: () => throw TimeoutException(
            'La generación del PDF tardó demasiado. Intenta nuevamente.',
          ),
        );

    setState(() {
      _previewSignature = signature;
      _pdfFuture = future;
      _isDesignSwitching = designSwitched;
    });

    future.whenComplete(() {
      if (!mounted || _previewSignature != signature || !_isDesignSwitching) {
        return;
      }
      setState(() => _isDesignSwitching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quote == null) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          trText(
            'Crea al menos una cotización para ver una vista previa real del PDF.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final future = _pdfFuture;
    if (future == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: FutureBuilder<Uint8List>(
        future: future,
        builder: (context, snapshot) {
          if (_isDesignSwitching) {
            return Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorStateWidget(
              message: buildActionErrorMessage(
                snapshot.error ?? 'No se pudo generar el PDF.',
                'No se pudo generar la vista previa.',
              ),
              onRetry: () => _refreshPreview(force: true),
            );
          }
          final pdfBytes = snapshot.data!;
          return PdfPreview(
            build: (_) async => pdfBytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowSharing: false,
            allowPrinting: false,
            maxPageWidth: 420,
            pdfFileName: '${widget.quote!.folio}.pdf',
          );
        },
      ),
    );
  }
}

class _TaxSettingsSection extends ConsumerStatefulWidget {
  _TaxSettingsSection({super.key, required this.empresa});

  final EmpresaPerfil empresa;

  @override
  ConsumerState<_TaxSettingsSection> createState() =>
      _TaxSettingsSectionState();
}

class _TaxSettingsSectionState extends ConsumerState<_TaxSettingsSection> {
  late final List<_TaxRateDraft> _drafts;
  String _selectedDefaultDraftKey = '';
  int _draftSequence = 0;
  bool _isSaving = false;

  ConfiguracionImpuestos get _impuestos => widget.empresa.impuestos;

  @override
  void initState() {
    super.initState();
    _drafts = _impuestos.tasas
        .map(
          (item) => _TaxRateDraft(
            key: item.id,
            persistedId: item.id,
            nombre: item.nombre,
            porcentaje: _formatTaxRateValue(item.porcentaje),
          ),
        )
        .toList(growable: true);
    for (final draft in _drafts) {
      if (draft.nombreController.text.trim() == _impuestos.tasaPredeterminada) {
        _selectedDefaultDraftKey = draft.key;
        break;
      }
    }
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addDraft() {
    final draft = _TaxRateDraft(
      key: 'draft_${DateTime.now().microsecondsSinceEpoch}_${_draftSequence++}',
      persistedId: '',
      nombre: '',
      porcentaje: '',
    );
    setState(() {
      _drafts.add(draft);
      if (_selectedDefaultDraftKey.isEmpty) {
        _selectedDefaultDraftKey = draft.key;
      }
    });
  }

  void _removeDraft(_TaxRateDraft draft) {
    setState(() {
      _drafts.remove(draft);
      if (_selectedDefaultDraftKey == draft.key) {
        _selectedDefaultDraftKey = _drafts.isEmpty ? '' : _drafts.first.key;
      }
    });
    draft.dispose();
  }

  Future<void> _save() async {
    final cleanedRates = <EmpresaTasaImpuesto>[];
    final seenNames = <String>{};

    for (final draft in _drafts) {
      final nombre = draft.nombreController.text.trim();
      final rawPercentage = draft.porcentajeController.text.trim();
      if (nombre.isEmpty && rawPercentage.isEmpty) {
        continue;
      }
      if (nombre.isEmpty) {
        ToastHelper.show(context, 'Cada impuesto debe tener nombre.');
        return;
      }
      final normalizedName = nombre.toLowerCase();
      if (!seenNames.add(normalizedName)) {
        ToastHelper.show(
          context,
          'No puede haber impuestos con el mismo nombre.',
        );
        return;
      }
      final porcentaje = parseNumericText(rawPercentage);
      if (porcentaje == null) {
        ToastHelper.show(
          context,
          'La tasa de impuesto debe ser un número válido.',
        );
        return;
      }
      cleanedRates.add(
        EmpresaTasaImpuesto(
          id: draft.persistedId.trim(),
          nombre: nombre,
          porcentaje: porcentaje,
        ),
      );
    }

    String defaultTaxName = '';
    for (final draft in _drafts) {
      if (draft.key == _selectedDefaultDraftKey) {
        defaultTaxName = draft.nombreController.text.trim();
        break;
      }
    }
    if (_selectedDefaultDraftKey.isNotEmpty && defaultTaxName.isEmpty) {
      ToastHelper.show(
        context,
        'La tasa predeterminada debe corresponder a un impuesto con nombre.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(configuracionRepositoryProvider)
          .updateEmpresa(
            widget.empresa.copyWith(
              impuestos: _impuestos.copyWith(
                tasas: cleanedRates,
                tasaPredeterminada: defaultTaxName,
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
      icon: Icons.percent_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administra tus tasas de impuesto con nombre y porcentaje. La tasa predeterminada se usará como opción inicial en tus productos.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          if (_drafts.isEmpty)
            EmptyFieldState(
              hintText: 'Sin impuestos registrados.',
              message:
                  'Agrega tu primera tasa de impuesto para usarla en productos y cotizaciones.',
              buttonLabel: 'Agregar tasa de impuesto',
              onPressed: _addDraft,
            )
          else ...[
            _TaxDefaultSelector(
              value: _selectedDefaultDraftKey,
              options: _drafts
                  .map(
                    (draft) => (
                      value: draft.key,
                      label: draft.nombreController.text.trim().isEmpty
                          ? 'Impuesto sin nombre'
                          : draft.nombreController.text.trim(),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) =>
                  setState(() => _selectedDefaultDraftKey = value),
            ),
            SizedBox(height: 16),
            ..._drafts.map(
              (draft) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _TaxRateEditorCard(
                  draft: draft,
                  onChanged: () => setState(() {}),
                  onDelete: () => _removeDraft(draft),
                ),
              ),
            ),
          ],
          if (_drafts.isNotEmpty) ...[
            SizedBox(height: 4),
            TextButton.icon(
              onPressed: _addDraft,
              icon: Icon(Icons.add_rounded, size: 16),
              label: Text(trText('Agregar tasa de impuesto')),
            ),
          ],
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

class _TaxRateDraft {
  _TaxRateDraft({
    required this.key,
    required this.persistedId,
    required String nombre,
    required String porcentaje,
  }) : nombreController = TextEditingController(text: nombre),
       porcentajeController = TextEditingController(text: porcentaje);

  final String key;
  final String persistedId;
  final TextEditingController nombreController;
  final TextEditingController porcentajeController;

  void dispose() {
    nombreController.dispose();
    porcentajeController.dispose();
  }
}

class _TaxDefaultSelector extends StatelessWidget {
  _TaxDefaultSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<({String value, String label})> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = options.any((item) => item.value == value)
        ? value
        : (options.isEmpty ? '' : options.first.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 190,
          child: Text(
            trText('Tasa predeterminada'),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedValue.isEmpty ? null : selectedValue,
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
                      trText(option.label),
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
    );
  }
}

class _TaxRateEditorCard extends StatelessWidget {
  _TaxRateEditorCard({
    required this.draft,
    required this.onChanged,
    required this.onDelete,
  });

  final _TaxRateDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final nameField = TextFormField(
            controller: draft.nombreController,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(labelText: trText('Nombre')),
          );
          final rateField = TextFormField(
            controller: draft.porcentajeController,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(maxDecimalDigits: 2),
            ],
            decoration: InputDecoration(
              labelText: trText('Tasa de impuesto'),
              suffixText: '%',
            ),
          );
          final deleteButton = IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
            splashRadius: 18,
            tooltip: trText('Eliminar'),
          );

          if (stacked) {
            return Column(
              children: [
                nameField,
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: rateField),
                    SizedBox(width: 8),
                    deleteButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: nameField),
              SizedBox(width: 12),
              Expanded(flex: 2, child: rateField),
              SizedBox(width: 8),
              Padding(padding: EdgeInsets.only(top: 8), child: deleteButton),
            ],
          );
        },
      ),
    );
  }
}

class _ConfigSectionTitle extends StatelessWidget {
  _ConfigSectionTitle({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(
        trText(title),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        SizedBox(width: 10),
        Text(
          trText(title),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PlanUpgradeColumn extends StatelessWidget {
  _PlanUpgradeColumn({required this.plan});

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
      padding: EdgeInsets.all(14),
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
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trText(item),
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
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  _PaymentMethodCard({required this.empresa, required this.plan});

  final EmpresaPerfil empresa;
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
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
                child: Icon(Icons.credit_card_rounded, color: AppColors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trText('Visa terminación 4242'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      trText('Facturación automática activada'),
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
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _InfoLine(label: trText('Titular'), value: empresa.nombreComercial),
          _InfoLine(
            label: trText('Correo de facturación'),
            value: empresa.correo,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodAddCard extends StatelessWidget {
  _PaymentMethodAddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 188,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 34, color: AppColors.textPrimary),
            SizedBox(height: 18),
            Text(
              trText('Agregar método de pago'),
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

class _AccountMetricCard extends StatelessWidget {
  _AccountMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          SizedBox(height: 12),
          Text(
            trText(label),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (helper != null) ...[
            SizedBox(height: 6),
            Text(
              trText(helper!),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountDetailLine extends StatelessWidget {
  _AccountDetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trText(label),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
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

class _InfoLine extends StatelessWidget {
  _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              trText(label),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
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

class _CapacityUsageCard extends StatelessWidget {
  _CapacityUsageCard({
    required this.icon,
    required this.label,
    required this.used,
    required this.limit,
    required this.accent,
    this.helper,
    this.footer,
  });

  final IconData icon;
  final String label;
  final int used;
  final int limit;
  final Color accent;
  final String? helper;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final unlimited = limit < 0;
    final progress = unlimited
        ? 1.0
        : limit == 0
        ? 0.0
        : (used / limit).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
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
              Icon(icon, size: 20, color: accent),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trText(label),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (helper != null)
                      Text(
                        trText(helper!),
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
                unlimited
                    ? '$used / ${trText('Ilimitados')}'
                    : '$used / $limit',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (footer != null) ...[
            SizedBox(height: 10),
            Text(
              trText(footer!),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DangerActionCard extends StatelessWidget {
  _DangerActionCard({
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
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.error, size: 32),
            SizedBox(width: 16),
            Text(
              trText(label),
              style: TextStyle(
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
  _FormShellCard({required this.title, required this.child, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final helpText = resolveContainerHelpText(title);

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
            padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _ConfigSectionTitle(title: title, icon: icon),
                ),
                if (helpText != null) ...[
                  SizedBox(width: 10),
                  ContainerHelpTooltip(message: helpText),
                ],
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Padding(padding: EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _EditableFieldRow extends StatelessWidget {
  _EditableFieldRow({
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
      padding: EdgeInsets.only(bottom: 16),
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
                  trText(label),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
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
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    trText(label),
                    style: TextStyle(
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

class _RichEditableFieldRow extends StatelessWidget {
  _RichEditableFieldRow({
    required this.label,
    required this.controller,
    required this.placeholder,
  });

  final String label;
  final quill.QuillController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final input = CotimaxRichTextEditor(
            controller: controller,
            placeholder: placeholder,
            editorHeight: 220,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trText(label),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
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
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    trText(label),
                    style: TextStyle(
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
  _SelectableFieldRow({
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
      padding: EdgeInsets.only(bottom: 16),
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
                      trText(option.label),
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
                  trText(label),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
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
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    trText(label),
                    style: TextStyle(
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
  _SettingsActionBar({
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
      padding: EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: isSaving ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          child: Text(isSaving ? trText('Guardando...') : trText(label)),
        ),
      ),
    );
  }
}

String _quoteDesignLabel(String option) {
  switch (option.trim().toLowerCase()) {
    case 'corporativo':
      return 'Corporativo';
    case 'industrial':
      return 'Industrial';
    case 'minimal':
      return 'Minimalista';
    case 'destacado':
      return 'Destacado';
    case 'editorial':
      return 'Editorial';
    default:
      return option;
  }
}

String _normalizeQuoteDesignOption(String option) {
  switch (option.trim().toLowerCase()) {
    case 'corporativo':
    case 'corporate':
      return 'corporativo';
    case 'industrial':
      return 'industrial';
    case 'minimalista':
    case 'minimal':
      return 'minimal';
    case 'destacado':
    case 'highlight':
      return 'destacado';
    case 'editorial':
      return 'editorial';
    default:
      return 'corporativo';
  }
}

class _DesignSelectRow extends StatelessWidget {
  _DesignSelectRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.optionLabelBuilder,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String Function(String option)? optionLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              trText(label),
              style: TextStyle(
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
                        trText(optionLabelBuilder?.call(option) ?? option),
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
  _DesignDoubleInputRow({
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
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              trText(label),
              style: TextStyle(
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
                              trText(option),
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
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: rightController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [
                      NumericTextInputFormatter(maxDecimalDigits: 2),
                    ],
                    decoration: InputDecoration(hintText: '24'),
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
  _DesignColorRow({
    required this.label,
    required this.controller,
    required this.onApplied,
  });

  final String label;
  final TextEditingController controller;
  final Future<void> Function() onApplied;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Text(
              trText(label),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final nextValue = await showDialog<String>(
                  context: context,
                  builder: (_) => _DesignColorDialog(
                    label: label,
                    initialValue: controller.text,
                  ),
                );
                if (nextValue == null) return;
                assignControllerText(controller, nextValue);
                await onApplied();
              },
              child: IgnorePointer(
                child: TextFormField(
                  controller: controller,
                  readOnly: true,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 52,
                      maxWidth: 52,
                    ),
                    suffixIcon: Icon(
                      Icons.edit_rounded,
                      color: AppColors.textSecondary,
                    ),
                    suffixIconConstraints: BoxConstraints(
                      minWidth: 40,
                      maxWidth: 40,
                    ),
                    prefixIcon: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _hexToColor(
                            controller.text,
                            fallback: AppColors.textPrimary,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
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
}

class _DesignColorDialog extends StatefulWidget {
  _DesignColorDialog({required this.label, required this.initialValue});

  final String label;
  final String initialValue;

  @override
  State<_DesignColorDialog> createState() => _DesignColorDialogState();
}

class _DesignColorDialogState extends State<_DesignColorDialog> {
  late final TextEditingController _controller;
  late Color _pickerColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.replaceAll('#', '').trim(),
    );
    _pickerColor = _hexToColor(
      _controller.text,
      fallback: AppColors.textPrimary,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = _pickerColor;
    return AlertDialog(
      title: Text(trText(widget.label)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
          ),
          SizedBox(height: 12),
          Text(
            trText('Seleccionar color'),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 8),
          ColorPicker(
            pickerColor: _pickerColor,
            onColorChanged: (nextColor) {
              _pickerColor = nextColor;
              assignControllerText(_controller, _colorToHex(nextColor));
              setState(() {});
            },
            enableAlpha: false,
            displayThumbColor: true,
            portraitOnly: true,
            pickerAreaHeightPercent: 0.72,
            labelTypes: const [],
          ),
          SizedBox(height: 8),
          TextField(
            controller: _controller,
            onChanged: (value) {
              final parsed = _hexToColor(value, fallback: _pickerColor);
              _pickerColor = parsed;
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: trText('Color HEX'),
              prefixText: '#',
              helperText: trText('Ejemplo: 1E5BB8'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(trText('Cancelar')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(_controller.text.replaceAll('#', '').trim()),
          child: Text(trText('Aplicar')),
        ),
      ],
    );
  }
}

String _colorToHex(Color color) {
  final value = color.value.toRadixString(16).padLeft(8, '0');
  return value.substring(2).toUpperCase();
}

class _DesignToggleRow extends StatelessWidget {
  _DesignToggleRow({
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
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trText(label),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (helper != null) ...[
                  SizedBox(height: 6),
                  Text(
                    trText(helper!),
                    style: TextStyle(
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
  _DesignRadioRow({
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
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              trText(label),
              style: TextStyle(
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
                          SizedBox(width: 8),
                          Text(
                            trText(option),
                            style: TextStyle(
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
  _DesignDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 1,
      color: AppColors.border,
    );
  }
}

class _LogoPreviewCard extends StatelessWidget {
  _LogoPreviewCard({required this.background, required this.imagePath});

  final Color background;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.trim().isNotEmpty;
    return Container(
      width: 250,
      height: 102,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: hasImage
          ? _OptionalAssetImage(
              imagePath: imagePath,
              height: 64,
              fit: BoxFit.contain,
            )
          : SizedBox.shrink(),
    );
  }
}

class _OptionalAssetImage extends StatelessWidget {
  _OptionalAssetImage({
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
      return SizedBox.shrink();
    }

    final isAssetPath =
        normalizedPath.startsWith('assets/') ||
        (!normalizedPath.startsWith('http://') &&
            !normalizedPath.startsWith('https://') &&
            !normalizedPath.startsWith('data:') &&
            !normalizedPath.startsWith('blob:'));

    if (isAssetPath) {
      return Image.asset(
        normalizedPath,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => SizedBox.shrink(),
      );
    }

    return Image.network(
      normalizedPath,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => SizedBox.shrink(),
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

({DateTime start, DateTime end}) _monthlyQuoteWindow(DateTime anchor) {
  final now = DateTime.now();
  var start = DateTime(anchor.year, anchor.month, anchor.day);

  while (!_isSameOrBefore(now, _nextMonthlyAnchor(start))) {
    start = _nextMonthlyAnchor(start);
  }

  return (start: start, end: _nextMonthlyAnchor(start));
}

DateTime _nextMonthlyAnchor(DateTime source) {
  final targetMonthDate = DateTime(source.year, source.month + 2, 0);
  final clampedDay = source.day.clamp(1, targetMonthDate.day);
  return DateTime(source.year, source.month + 1, clampedDay);
}

bool _isSameOrBefore(DateTime left, DateTime right) {
  return left.isAtSameMomentAs(right) || left.isBefore(right);
}

String _friendlyFutureDateLabel(DateTime value) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfTarget = DateTime(value.year, value.month, value.day);
  final dayDiff = startOfTarget.difference(startOfToday).inDays;

  if (dayDiff <= 0) return trText('hoy');
  if (dayDiff == 1) return trText('mañana');
  if (dayDiff < 7) return tr('en $dayDiff días', 'in $dayDiff days');
  if (dayDiff < 30) {
    final weeks = (dayDiff / 7).ceil();
    return tr('en $weeks semanas', 'in $weeks weeks');
  }
  return trText('próximamente');
}

String _formatTaxRateValue(double value) {
  final decimalDigits = value == value.roundToDouble() ? 0 : 2;
  return value.toStringAsFixed(decimalDigits);
}

String _planPriceLabel(Plan plan) {
  if (plan.billingMode == 'per_user_monthly') {
    return '${formatMoney(plan.precioPorUsuario, decimalDigits: 0)}/${tr('usuario', 'user')}/${tr('mes', 'month')}';
  }
  if (plan.precioMensual <= 0) {
    return trText('Gratis');
  }
  return '${formatMoney(plan.precioMensual, decimalDigits: 0)}/${tr('mes', 'month')}';
}

String _planUsersLabel(Plan plan) {
  if (plan.usuariosMinimos > 0 && plan.usuariosMaximos > 0) {
    return '${plan.usuariosMinimos}-${plan.usuariosMaximos}';
  }
  if (plan.limiteUsuarios < 0) {
    return trText('Ilimitados');
  }
  return '${plan.limiteUsuarios}';
}
