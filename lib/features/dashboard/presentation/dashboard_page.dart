import 'dart:math' as math;

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/clientes/application/clientes_controller.dart';
import 'package:cotimax/features/cotizaciones/application/cotizaciones_controller.dart';
import 'package:cotimax/features/gastos/application/gastos_controller.dart';
import 'package:cotimax/features/ingresos/application/ingresos_controller.dart';
import 'package:cotimax/features/productos/application/productos_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:cotimax/shared/widgets/finance_icon_picker.dart';
import 'package:cotimax/shared/widgets/recurrence_fields.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late DateTimeRange _selectedRange;
  bool _isRefreshing = true;
  int _contentVersion = 0;

  @override
  void initState() {
    super.initState();
    _selectedRange = _buildSuggestedRange();
    _simulateDashboardRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final ingresosCatalogo =
        ref.watch(ingresosControllerProvider).valueOrNull ?? const <Ingreso>[];
    final gastosCatalogo =
        ref.watch(gastosControllerProvider).valueOrNull ?? const <Gasto>[];
    final clientesCatalogo =
        ref.watch(clientesControllerProvider).valueOrNull ?? const <Cliente>[];
    final cotizacionesCatalogo =
        ref.watch(cotizacionesControllerProvider).valueOrNull ??
        const <Cotizacion>[];
    final detallesCatalogo =
        ref.watch(detalleCotizacionesControllerProvider).valueOrNull ??
        const <DetalleCotizacion>[];
    final productosCatalogo =
        ref.watch(productosControllerProvider).valueOrNull ??
        const <ProductoServicio>[];
    final ingresos =
        ingresosCatalogo
            .where((item) => _inDateRange(item.fecha, _selectedRange))
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final gastos =
        gastosCatalogo
            .where((item) => _inDateRange(item.fecha, _selectedRange))
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final clientes = clientesCatalogo;
    final cotizaciones =
        cotizacionesCatalogo
            .where((item) => _inDateRange(item.fechaEmision, _selectedRange))
            .toList()
          ..sort((a, b) => b.fechaEmision.compareTo(a.fechaEmision));
    final detalles = detallesCatalogo;
    final productos = productosCatalogo;
    final productosMap = {for (final item in productos) item.id: item};
    final clientesMap = {for (final item in clientes) item.id: item};
    final cotizacionesMap = {for (final item in cotizaciones) item.id: item};
    final categoriasGastoMap = {
      for (final item
          in (ref.watch(gastoCategoriasControllerProvider).valueOrNull ??
              const <GastoCategoria>[]))
        item.id: item,
    };
    final approvedQuoteIds = cotizaciones
        .where((item) => item.estatus == QuoteStatus.aprobada)
        .map((item) => item.id)
        .toSet();

    final totalIngresos = ingresos.fold<double>(
      0,
      (sum, item) => sum + item.monto,
    );
    final totalGastos = gastos.fold<double>(0, (sum, item) => sum + item.monto);
    final totalVentaCosto = detalles.fold<double>(0, (sum, item) {
      if (!approvedQuoteIds.contains(item.cotizacionId)) return sum;
      final producto = productosMap[item.productoServicioId];
      final costoLinea = (producto?.costo ?? 0) * item.cantidad;
      return sum + costoLinea;
    });
    final totalVentaBruta = detalles.fold<double>(
      0,
      (sum, item) => approvedQuoteIds.contains(item.cotizacionId)
          ? sum + item.importe
          : sum,
    );
    final utilidadReal = totalVentaBruta - totalVentaCosto;
    final margenReal = totalVentaBruta == 0
        ? 0.0
        : (utilidadReal / totalVentaBruta) * 100;
    final saludFinanciera = margenReal >= 35
        ? 'Sana'
        : margenReal >= 20
        ? 'Atencion'
        : 'Riesgo';

    final approvedQuotes = cotizaciones
        .where((item) => item.estatus == QuoteStatus.aprobada)
        .toList();

    final ingresosSerie = _buildWeeklySeries(
      ingresos.map((item) => (item.fecha, item.monto)).toList(),
      range: _selectedRange,
    );
    final gastosSerie = _buildWeeklySeries(
      gastos.map((item) => (item.fecha, item.monto)).toList(),
      range: _selectedRange,
    );
    final utilidadSerieData = _buildUtilitySeries(
      range: _selectedRange,
      detalles: detalles,
      cotizaciones: cotizacionesMap,
      productos: productosMap,
    );
    final utilidadSerie = utilidadSerieData.$1;
    final margenSerie = List<double>.generate(utilidadSerie.length, (index) {
      final venta = utilidadSerieData.$2[index];
      if (venta <= 0) return 0;
      return (utilidadSerie[index] / venta) * 100;
    });
    final topProductosUtilidad = _topProductsByUtility(
      detalles: detalles,
      productos: productosMap,
      cotizaciones: cotizacionesMap,
    );
    final approvedQuoteUtilityDetails = _buildApprovedQuoteUtilityDetails(
      detalles: detalles,
      cotizaciones: cotizacionesMap,
      productos: productosMap,
      clientes: clientesMap,
    );
    final quoteProbabilities = _buildQuoteProbabilityItems(
      cotizaciones: cotizaciones,
      clientes: clientesMap,
    );
    final clientProfitability = _buildClientProfitabilityItems(
      quotes: approvedQuoteUtilityDetails,
      clientes: clientesMap,
    );
    final incomeConcentration = _buildIncomeConcentrationSummary(
      ingresos: ingresos,
      clientes: clientesMap,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1320;
        final tablet = constraints.maxWidth >= 960;
        final dashboardContent = _isRefreshing
            ? _DashboardLoadingState(desktop: desktop, tablet: tablet)
            : Column(
                children: [
                  _DashboardReveal(
                    version: _contentVersion,
                    index: 0,
                    child: _KpiGrid(
                      ingresosSerie: ingresosSerie.$1,
                      gastosSerie: gastosSerie.$1,
                      utilidadSerie: utilidadSerie,
                      margenSerie: margenSerie,
                      totalIngresos: totalIngresos,
                      totalGastos: totalGastos,
                      utilidad: utilidadReal,
                      margen: margenReal,
                      ingresos: ingresos,
                      gastos: gastos,
                      approvedQuoteUtilityDetails: approvedQuoteUtilityDetails,
                      approvedQuotesCount: approvedQuotes.length,
                      clientes: clientesMap,
                      cotizaciones: cotizacionesMap,
                      categoriasGasto: categoriasGastoMap,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DashboardReveal(
                    version: _contentVersion,
                    index: 1,
                    child: const _QuickActionsPanel(),
                  ),
                  const SizedBox(height: 12),
                  _DashboardReveal(
                    version: _contentVersion,
                    index: 2,
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _IngresosPanel(
                                  labels: ingresosSerie.$2,
                                  values: ingresosSerie.$1,
                                  totalIngresos: totalIngresos,
                                  numeroVentas: approvedQuotes.length,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _GastosImpactPanel(
                                  labels: gastosSerie.$2,
                                  gastosSerie: gastosSerie.$1,
                                  totalGastos: totalGastos,
                                  margen: margenReal,
                                  saludFinanciera: saludFinanciera,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _IngresosPanel(
                                labels: ingresosSerie.$2,
                                values: ingresosSerie.$1,
                                totalIngresos: totalIngresos,
                                numeroVentas: approvedQuotes.length,
                              ),
                              const SizedBox(height: 12),
                              _GastosImpactPanel(
                                labels: gastosSerie.$2,
                                gastosSerie: gastosSerie.$1,
                                totalGastos: totalGastos,
                                margen: margenReal,
                                saludFinanciera: saludFinanciera,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  _DashboardReveal(
                    version: _contentVersion,
                    index: 3,
                    child: _TopProductsUtilityPanel(
                      items: topProductosUtilidad,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DashboardReveal(
                    version: _contentVersion,
                    index: 4,
                    child: (desktop || tablet)
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _ClientProfitabilityPanel(
                                  items: clientProfitability,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _IncomeConcentrationPanel(
                                  summary: incomeConcentration,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _ClientProfitabilityPanel(
                                items: clientProfitability,
                              ),
                              const SizedBox(height: 12),
                              _IncomeConcentrationPanel(
                                summary: incomeConcentration,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  _DashboardReveal(
                    version: _contentVersion,
                    index: 5,
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _PipelinePanel(
                                  items: quoteProbabilities,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RecentIncomePanel(
                                  ingresos: ingresos.take(6).toList(),
                                  clientes: clientesMap,
                                ),
                              ),
                            ],
                          )
                        : tablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _PipelinePanel(
                                  items: quoteProbabilities,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RecentIncomePanel(
                                  ingresos: ingresos.take(6).toList(),
                                  clientes: clientesMap,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _PipelinePanel(items: quoteProbabilities),
                              const SizedBox(height: 12),
                              _RecentIncomePanel(
                                ingresos: ingresos.take(6).toList(),
                                clientes: clientesMap,
                              ),
                            ],
                          ),
                  ),
                ],
              );

        return SingleChildScrollView(
          child: Column(
            children: [
              PageHeader(
                title: 'Inicio',
                subtitle:
                    'Prioridad financiera: ingresos, gastos, utilidad y cierre comercial del rango actual. Usa Ctrl/Cmd + K para navegar o crear sin salir del flujo.',
                actions: [
                  OutlinedButton.icon(
                    onPressed: _pickDashboardRange,
                    icon: const FaIcon(FontAwesomeIcons.calendarDays, size: 13),
                    label: Text(_rangeLabel(_selectedRange)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(
                    '${_isRefreshing ? 'loading' : 'content'}-$_contentVersion',
                  ),
                  child: dashboardContent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDashboardRange() async {
    final picked = await _showAppDateRangePicker(
      context,
      initialRange: _selectedRange,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedRange = DateTimeRange(
        start: _startOfDay(picked.start),
        end: _endOfDay(picked.end),
      );
    });
    await _simulateDashboardRefresh(
      toast: 'Dashboard actualizado para ${_rangeLabel(_selectedRange)}.',
    );
  }

  DateTimeRange _buildSuggestedRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: _startOfDay(now.subtract(const Duration(days: 49))),
      end: _endOfDay(now),
    );
  }

  Future<void> _simulateDashboardRefresh({String? toast}) async {
    if (mounted) {
      setState(() => _isRefreshing = true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 460));
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _contentVersion += 1;
    });
    if (toast != null) {
      ToastHelper.show(context, toast);
    }
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.ingresosSerie,
    required this.gastosSerie,
    required this.utilidadSerie,
    required this.margenSerie,
    required this.totalIngresos,
    required this.totalGastos,
    required this.utilidad,
    required this.margen,
    required this.ingresos,
    required this.gastos,
    required this.approvedQuoteUtilityDetails,
    required this.approvedQuotesCount,
    required this.clientes,
    required this.cotizaciones,
    required this.categoriasGasto,
  });

  final List<double> ingresosSerie;
  final List<double> gastosSerie;
  final List<double> utilidadSerie;
  final List<double> margenSerie;
  final double totalIngresos;
  final double totalGastos;
  final double utilidad;
  final double margen;
  final List<Ingreso> ingresos;
  final List<Gasto> gastos;
  final List<_ApprovedQuoteUtilityDetail> approvedQuoteUtilityDetails;
  final int approvedQuotesCount;
  final Map<String, Cliente> clientes;
  final Map<String, Cotizacion> cotizaciones;
  final Map<String, GastoCategoria> categoriasGasto;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1320
        ? 4
        : width >= 960
        ? 2
        : 1;
    final cardHeight = width >= 1320
        ? 236.0
        : width >= 960
        ? 224.0
        : 206.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: cardHeight,
      ),
      itemBuilder: (context, index) {
        final items = [
          _KpiCard(
            title: 'Ingresos',
            value: formatMxn(totalIngresos),
            accent: AppColors.primary,
            footer: _deltaLabel(ingresosSerie),
            series: ingresosSerie,
            percentMode: false,
            metaLabel: '${ingresos.length} ingresos',
            onViewMore: () => _openIncomeDetails(context),
          ),
          _KpiCard(
            title: 'Gastos',
            value: formatMxn(totalGastos),
            accent: AppColors.accent,
            footer: _deltaLabel(gastosSerie),
            series: gastosSerie,
            percentMode: false,
            metaLabel: '${gastos.length} gastos',
            onViewMore: () => _openExpenseDetails(context, categoriasGasto),
          ),
          _KpiCard(
            title: 'Utilidad real (basada en cotizaciones confirmadas)',
            value: formatMxn(utilidad),
            accent: AppColors.success,
            footer: _deltaLabel(utilidadSerie),
            series: utilidadSerie,
            percentMode: false,
            metaLabel: '$approvedQuotesCount cotizaciones aprobadas',
            onViewMore: () => _openApprovedQuoteDetails(context),
          ),
          _KpiCard(
            title: 'Margen real',
            value: '${margen.toStringAsFixed(1)}%',
            accent: margen >= 20 ? AppColors.success : AppColors.warning,
            footer: _deltaLabel(margenSerie),
            series: margenSerie,
            percentMode: true,
          ),
        ];
        return items[index];
      },
    );
  }

  void _openIncomeDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: 'Ultimos ingresos',
        child: _IncomeTimelineDialog(
          ingresos: ingresos,
          clientes: clientes,
          cotizaciones: cotizaciones,
        ),
      ),
    );
  }

  void _openExpenseDetails(
    BuildContext context,
    Map<String, GastoCategoria> categorias,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: 'Ultimos gastos',
        child: _ExpenseTimelineDialog(gastos: gastos, categorias: categorias),
      ),
    );
  }

  void _openApprovedQuoteDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: 'Cotizaciones aprobadas con utilidad',
        child: _ApprovedQuoteTimelineDialog(items: approvedQuoteUtilityDetails),
      ),
    );
  }
}

class _IngresosPanel extends StatelessWidget {
  const _IngresosPanel({
    required this.labels,
    required this.values,
    required this.totalIngresos,
    required this.numeroVentas,
  });

  final List<String> labels;
  final List<double> values;
  final double totalIngresos;
  final int numeroVentas;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Ingresos totales',
      trailing: const _TopChip(
        icon: FontAwesomeIcons.arrowTrendUp,
        label: 'Tendencia de ingresos',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              children: [
                const TextSpan(text: 'Total del rango '),
                TextSpan(
                  text: formatMxn(totalIngresos),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: '  |  '),
                const TextSpan(text: 'Cotizaciones aprobadas '),
                TextSpan(
                  text: '$numeroVentas',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (values.isEmpty)
            const SizedBox(
              height: 290,
              child: Center(child: InlineEmptyMessage()),
            )
          else
            SizedBox(
              height: 290,
              child: LineChart(
                _lineChartData(
                  labels: labels,
                  values: values,
                  color: AppColors.primary,
                  currency: true,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ritmo comercial: cotizaciones aprobadas convertidas a ingreso en el rango actual.',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Esta vista resume cuanto ingreso entro y que tan activo estuvo el cierre comercial durante el periodo.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.5,
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

class _GastosImpactPanel extends StatelessWidget {
  const _GastosImpactPanel({
    required this.labels,
    required this.gastosSerie,
    required this.totalGastos,
    required this.margen,
    required this.saludFinanciera,
  });

  final List<String> labels;
  final List<double> gastosSerie;
  final double totalGastos;
  final double margen;
  final String saludFinanciera;

  @override
  Widget build(BuildContext context) {
    final impactColor = margen >= 35
        ? AppColors.success
        : margen >= 20
        ? AppColors.warning
        : AppColors.error;

    return SectionCard(
      title: 'Gastos totales',
      trailing: const _TopChip(
        icon: FontAwesomeIcons.arrowTrendDown,
        label: 'Tendencia de gastos',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              children: [
                const TextSpan(text: 'Total del rango '),
                TextSpan(
                  text: formatMxn(totalGastos),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (gastosSerie.isEmpty)
            const SizedBox(
              height: 290,
              child: Center(child: InlineEmptyMessage()),
            )
          else
            SizedBox(
              height: 290,
              child: LineChart(
                _lineChartData(
                  labels: labels,
                  values: gastosSerie,
                  color: AppColors.accent,
                  currency: true,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado financiero: $saludFinanciera',
                  style: TextStyle(
                    color: impactColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Margen actual: ${margen.toStringAsFixed(1)}%. ${margen >= 20 ? 'El gasto se mantiene bajo control.' : 'Conviene revisar gastos para recuperar margen.'}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.5,
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

class _DashboardReveal extends StatelessWidget {
  const _DashboardReveal({
    required this.version,
    required this.index,
    required this.child,
  });

  final int version;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$version-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState({required this.desktop, required this.tablet});

  final bool desktop;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final kpiColumns = desktop
        ? 4
        : tablet
        ? 2
        : 1;
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kpiColumns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: desktop ? 228 : 208,
          ),
          itemBuilder: (_, __) => const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 14, radius: 8),
                SizedBox(height: 10),
                SkeletonBox(width: 160, height: 32, radius: 10),
                SizedBox(height: 8),
                SkeletonBox(width: 140, height: 12, radius: 8),
                SizedBox(height: 40),
                SkeletonBox(height: 72, radius: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const SectionCard(
          title: 'Acciones rápidas',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SkeletonBox(width: 150, height: 42, radius: 14),
              SkeletonBox(width: 160, height: 42, radius: 14),
              SkeletonBox(width: 170, height: 42, radius: 14),
              SkeletonBox(width: 170, height: 42, radius: 14),
            ],
          ),
        ),
        const SizedBox(height: 12),
        desktop
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LoadingPanel(height: 420)),
                  SizedBox(width: 12),
                  Expanded(child: _LoadingPanel(height: 420)),
                ],
              )
            : const Column(
                children: [
                  _LoadingPanel(height: 340),
                  SizedBox(height: 12),
                  _LoadingPanel(height: 340),
                ],
              ),
        const SizedBox(height: 12),
        const _LoadingPanel(height: 310),
        const SizedBox(height: 12),
        (desktop || tablet)
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LoadingPanel(height: 300)),
                  SizedBox(width: 12),
                  Expanded(child: _LoadingPanel(height: 300)),
                ],
              )
            : const Column(
                children: [
                  _LoadingPanel(height: 280),
                  SizedBox(height: 12),
                  _LoadingPanel(height: 280),
                ],
              ),
        const SizedBox(height: 12),
        (desktop || tablet)
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LoadingPanel(height: 310)),
                  SizedBox(width: 12),
                  Expanded(child: _LoadingPanel(height: 310)),
                ],
              )
            : const Column(
                children: [
                  _LoadingPanel(height: 280),
                  SizedBox(height: 12),
                  _LoadingPanel(height: 280),
                ],
              ),
      ],
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 180, height: 18, radius: 8),
          const SizedBox(height: 10),
          const SkeletonBox(width: 260, height: 12, radius: 8),
          const SizedBox(height: 18),
          SkeletonBox(height: height, radius: 20),
        ],
      ),
    );
  }
}

class _PipelinePanel extends StatelessWidget {
  const _PipelinePanel({required this.items});

  final List<_QuoteProbabilityItem> items;

  @override
  Widget build(BuildContext context) {
    final visibles = [...items]
      ..sort((a, b) {
        final byProbability = b.probability.compareTo(a.probability);
        if (byProbability != 0) return byProbability;
        return b.fecha.compareTo(a.fecha);
      });
    final prioritized = visibles.take(6).toList();
    final weightedRevenue = items.fold<double>(
      0,
      (sum, item) => sum + item.expectedRevenue,
    );
    final averageProbability = items.isEmpty
        ? 0.0
        : items.fold<double>(0, (sum, item) => sum + item.probability) /
              items.length;
    final approvedCount = items.where((item) => item.approved).length;
    final highConfidence = items
        .where((item) => item.probability >= 0.75)
        .length;

    return SectionCard(
      title: 'Cotizaciones prioritarias',
      trailing: const _TopChip(
        icon: FontAwesomeIcons.fileInvoiceDollar,
        label: 'Seguimiento',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CompactMetricPill(
                label: 'Cierre ponderado',
                value: formatMxn(weightedRevenue),
                accent: AppColors.primary,
              ),
              _CompactMetricPill(
                label: 'Prob. promedio',
                value: '${(averageProbability * 100).toStringAsFixed(0)}%',
                accent: averageProbability >= 0.7
                    ? AppColors.success
                    : AppColors.warning,
              ),
              _CompactMetricPill(
                label: 'Aprobadas',
                value: '$approvedCount/${items.length}',
                accent: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            items.isEmpty
                ? 'Todavia no hay pipeline para analizar en este rango.'
                : '$highConfidence cotizaciones vienen con confianza alta. La tabla solo deja visibles las mas accionables para no saturarte.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          if (prioritized.isEmpty)
            const InlineEmptyMessage()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        headingRowHeight: 44,
                        horizontalMargin: 14,
                        columnSpacing: 20,
                        dividerThickness: 1,
                        columns: const [
                          DataColumn(label: Text('Folio')),
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Probabilidad')),
                          DataColumn(label: Text('Estatus')),
                        ],
                        rows: prioritized
                            .map(
                              (item) => DataRow(
                                cells: [
                                  DataCell(Text(item.folio)),
                                  DataCell(Text(item.clientName)),
                                  DataCell(Text(formatMxn(item.total))),
                                  DataCell(
                                    SizedBox(
                                      width: 168,
                                      child: _ProbabilityIndicator(
                                        probability: item.probability,
                                      ),
                                    ),
                                  ),
                                  DataCell(StatusBadge(status: item.estatus)),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RecentIncomePanel extends StatelessWidget {
  const _RecentIncomePanel({required this.ingresos, required this.clientes});

  final List<Ingreso> ingresos;
  final Map<String, Cliente> clientes;

  @override
  Widget build(BuildContext context) {
    return CotimaxDataTable(
      title: 'Ultimos ingresos',
      trailing: const _TopChip(
        icon: FontAwesomeIcons.receipt,
        label: 'Cobranza',
      ),
      emptyTitle: 'Todavia no hay ingresos recientes en el rango.',
      emptySubtitle:
          'Cuando entren cobros, esta vista mostrara lo ultimo registrado sin saturar el dashboard.',
      columns: const [
        DataColumn(label: Text('Cliente')),
        DataColumn(label: Text('Fecha')),
        DataColumn(label: Text('Metodo')),
        DataColumn(label: Text('Monto')),
        DataColumn(label: Text('Referencia')),
      ],
      rows: ingresos
          .map(
            (item) => DataRow(
              cells: [
                DataCell(
                  Text(clientes[item.clienteId]?.nombre ?? item.clienteId),
                ),
                DataCell(Text(DateFormat('dd/MM/yyyy').format(item.fecha))),
                DataCell(Text(_paymentMethodLabel(item.metodoPago))),
                DataCell(Text(formatMxn(item.monto))),
                DataCell(Text(item.referencia)),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _CompactMetricPill extends StatelessWidget {
  const _CompactMetricPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbabilityIndicator extends StatelessWidget {
  const _ProbabilityIndicator({required this.probability});

  final double probability;

  @override
  Widget build(BuildContext context) {
    final clamped = probability.clamp(0.0, 1.0).toDouble();
    final color = clamped >= 0.8
        ? AppColors.success
        : clamped >= 0.55
        ? AppColors.warning
        : AppColors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${(clamped * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.footer,
    required this.series,
    required this.percentMode,
    this.metaLabel,
    this.onViewMore,
  });

  final String title;
  final String value;
  final Color accent;
  final String footer;
  final List<double> series;
  final bool percentMode;
  final String? metaLabel;
  final VoidCallback? onViewMore;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1180;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onViewMore != null)
                TextButton(
                  onPressed: onViewMore,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Ver mas'),
                ),
            ],
          ),
          if (metaLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              metaLabel!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: TextStyle(
              color: footer.startsWith('↑')
                  ? AppColors.success
                  : footer.startsWith('↓')
                  ? AppColors.error
                  : AppColors.textSecondary,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: compact ? 64 : 70,
            child: series.isEmpty
                ? const Center(child: InlineEmptyMessage())
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: LineChart(
                      LineChartData(
                        minY: percentMode ? 0 : null,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              series.length,
                              (index) =>
                                  FlSpot(index.toDouble(), series[index]),
                            ),
                            isCurved: true,
                            color: accent,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: accent.withValues(alpha: 0.10),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => AppColors.textPrimary,
                            getTooltipItems: (spots) => spots
                                .map(
                                  (spot) => LineTooltipItem(
                                    percentMode
                                        ? '${spot.y.toStringAsFixed(1)}%'
                                        : formatMxn(spot.y),
                                    const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                                .toList(),
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

class _TopChip extends StatelessWidget {
  const _TopChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Acciones rapidas',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: const [
          _QuickActionButton(
            icon: FontAwesomeIcons.users,
            label: 'Nuevo cliente',
            route: RoutePaths.clientes,
          ),
          _QuickActionButton(
            icon: FontAwesomeIcons.boxOpen,
            label: 'Nuevo producto',
            route: RoutePaths.productos,
          ),
          _QuickActionButton(
            icon: FontAwesomeIcons.fileInvoiceDollar,
            label: 'Nueva cotización',
            route: RoutePaths.cotizaciones,
          ),
          _QuickActionButton(
            icon: FontAwesomeIcons.wallet,
            label: 'Registrar ingreso',
            route: RoutePaths.ingresos,
          ),
          _QuickActionButton(
            icon: FontAwesomeIcons.receipt,
            label: 'Registrar gasto',
            route: RoutePaths.gastos,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go('$route?create=1'),
      icon: FaIcon(icon, size: 13),
      label: Text(label),
    );
  }
}

class _IncomeTimelineDialog extends StatelessWidget {
  const _IncomeTimelineDialog({
    required this.ingresos,
    required this.clientes,
    required this.cotizaciones,
  });

  final List<Ingreso> ingresos;
  final Map<String, Cliente> clientes;
  final Map<String, Cotizacion> cotizaciones;

  @override
  Widget build(BuildContext context) {
    return _FilterableIncomeTimelineDialog(
      ingresos: ingresos,
      clientes: clientes,
      cotizaciones: cotizaciones,
    );
  }
}

class _ExpenseTimelineDialog extends StatelessWidget {
  const _ExpenseTimelineDialog({
    required this.gastos,
    required this.categorias,
  });

  final List<Gasto> gastos;
  final Map<String, GastoCategoria> categorias;

  @override
  Widget build(BuildContext context) {
    return _FilterableExpenseTimelineDialog(
      gastos: gastos,
      categorias: categorias,
    );
  }
}

class _FilterableIncomeTimelineDialog extends StatefulWidget {
  const _FilterableIncomeTimelineDialog({
    required this.ingresos,
    required this.clientes,
    required this.cotizaciones,
  });

  final List<Ingreso> ingresos;
  final Map<String, Cliente> clientes;
  final Map<String, Cotizacion> cotizaciones;

  @override
  State<_FilterableIncomeTimelineDialog> createState() =>
      _FilterableIncomeTimelineDialogState();
}

class _FilterableIncomeTimelineDialogState
    extends State<_FilterableIncomeTimelineDialog> {
  String _query = '';
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.ingresos]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final filtered = sorted.where((item) {
      if (_selectedRange != null &&
          !_inDateRange(item.fecha, _selectedRange!)) {
        return false;
      }
      return _matchesQuery(_query, [
        widget.clientes[item.clienteId]?.nombre ?? item.clienteId,
        widget.cotizaciones[item.cotizacionId]?.folio ?? item.cotizacionId,
        _paymentMethodLabel(item.metodoPago),
        item.referencia,
        item.notas,
        _recurrenceSummary(item.recurrente, item.recurrencia, item.diasSemana),
      ]);
    }).toList();

    return _TimelineShell(
      searchHint: 'Filtra por cliente, folio, referencia o metodo',
      query: _query,
      onQueryChanged: (value) => setState(() => _query = value),
      rangeLabel: _selectedRange == null
          ? 'Todo el rango actual'
          : _rangeLabel(_selectedRange!),
      onPickRange: sorted.isEmpty ? null : () => _pickRange(sorted),
      onClearRange: _selectedRange == null
          ? null
          : () => setState(() => _selectedRange = null),
      summaryLabel: '${filtered.length} de ${sorted.length} ingresos',
      emptyLabel: 'No hay ingresos que coincidan con el filtro.',
      children: filtered
          .map(
            (item) => _TimelineRow(
              color: AppColors.success,
              leading: FinanceIconAvatar(
                iconKey: item.iconKey,
                size: 38,
                backgroundColor: AppColors.success.withValues(alpha: 0.10),
                iconColor: AppColors.success,
              ),
              title: widget.clientes[item.clienteId]?.nombre ?? item.clienteId,
              amount: formatMxn(item.monto),
              operationLabel:
                  'Ingreso por ${_paymentMethodLabel(item.metodoPago)}',
              timestampLabel: _dateTimeLabel(item.fecha),
              detailLines: [
                'Cotización ${widget.cotizaciones[item.cotizacionId]?.folio ?? item.cotizacionId}',
                'Referencia ${item.referencia.isEmpty ? 'sin referencia' : item.referencia}',
                _recurrenceSummary(
                  item.recurrente,
                  item.recurrencia,
                  item.diasSemana,
                ),
                if (item.notas.isNotEmpty) 'Notas ${item.notas}',
              ],
            ),
          )
          .toList(),
    );
  }

  Future<void> _pickRange(List<Ingreso> sorted) async {
    final picked = await _showAppDateRangePicker(
      context,
      initialRange:
          _selectedRange ??
          DateTimeRange(
            start: _startOfDay(sorted.last.fecha),
            end: _endOfDay(sorted.first.fecha),
          ),
      firstDate: _startOfDay(sorted.last.fecha),
      lastDate: _endOfDay(sorted.first.fecha),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedRange = DateTimeRange(
        start: _startOfDay(picked.start),
        end: _endOfDay(picked.end),
      );
    });
  }
}

class _FilterableExpenseTimelineDialog extends StatefulWidget {
  const _FilterableExpenseTimelineDialog({
    required this.gastos,
    required this.categorias,
  });

  final List<Gasto> gastos;
  final Map<String, GastoCategoria> categorias;

  @override
  State<_FilterableExpenseTimelineDialog> createState() =>
      _FilterableExpenseTimelineDialogState();
}

class _FilterableExpenseTimelineDialogState
    extends State<_FilterableExpenseTimelineDialog> {
  String _query = '';
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.gastos]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final filtered = sorted.where((item) {
      if (_selectedRange != null &&
          !_inDateRange(item.fecha, _selectedRange!)) {
        return false;
      }
      return _matchesQuery(_query, [
        widget.categorias[item.gastoCategoriaId]?.nombre ??
            item.gastoCategoriaId,
        item.proveedor,
        item.descripcion,
        item.referencia,
        item.notas,
        _recurrenceSummary(item.recurrente, item.recurrencia, item.diasSemana),
      ]);
    }).toList();

    return _TimelineShell(
      searchHint: 'Filtra por categoria, proveedor, referencia o descripcion',
      query: _query,
      onQueryChanged: (value) => setState(() => _query = value),
      rangeLabel: _selectedRange == null
          ? 'Todo el rango actual'
          : _rangeLabel(_selectedRange!),
      onPickRange: sorted.isEmpty ? null : () => _pickRange(sorted),
      onClearRange: _selectedRange == null
          ? null
          : () => setState(() => _selectedRange = null),
      summaryLabel: '${filtered.length} de ${sorted.length} gastos',
      emptyLabel: 'No hay gastos que coincidan con el filtro.',
      children: filtered
          .map(
            (item) => _TimelineRow(
              color: AppColors.error,
              leading: FinanceIconAvatar(
                iconKey: item.iconKey,
                size: 38,
                backgroundColor: AppColors.error.withValues(alpha: 0.10),
                iconColor: AppColors.error,
              ),
              title:
                  widget.categorias[item.gastoCategoriaId]?.nombre ??
                  item.gastoCategoriaId,
              amount: formatMxn(item.monto),
              operationLabel: item.proveedor.isEmpty
                  ? 'Gasto registrado'
                  : 'Gasto con ${item.proveedor}',
              timestampLabel: _dateTimeLabel(item.fecha),
              detailLines: [
                item.descripcion,
                'Referencia ${item.referencia.isEmpty ? 'sin referencia' : item.referencia}',
                _recurrenceSummary(
                  item.recurrente,
                  item.recurrencia,
                  item.diasSemana,
                ),
                if (item.notas.isNotEmpty) 'Notas ${item.notas}',
              ],
            ),
          )
          .toList(),
    );
  }

  Future<void> _pickRange(List<Gasto> sorted) async {
    final picked = await _showAppDateRangePicker(
      context,
      initialRange:
          _selectedRange ??
          DateTimeRange(
            start: _startOfDay(sorted.last.fecha),
            end: _endOfDay(sorted.first.fecha),
          ),
      firstDate: _startOfDay(sorted.last.fecha),
      lastDate: _endOfDay(sorted.first.fecha),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedRange = DateTimeRange(
        start: _startOfDay(picked.start),
        end: _endOfDay(picked.end),
      );
    });
  }
}

class _ApprovedQuoteTimelineDialog extends StatelessWidget {
  const _ApprovedQuoteTimelineDialog({required this.items});

  final List<_ApprovedQuoteUtilityDetail> items;

  @override
  Widget build(BuildContext context) {
    return _FilterableApprovedQuoteTimelineDialog(items: items);
  }
}

class _FilterableApprovedQuoteTimelineDialog extends StatefulWidget {
  const _FilterableApprovedQuoteTimelineDialog({required this.items});

  final List<_ApprovedQuoteUtilityDetail> items;

  @override
  State<_FilterableApprovedQuoteTimelineDialog> createState() =>
      _FilterableApprovedQuoteTimelineDialogState();
}

class _FilterableApprovedQuoteTimelineDialogState
    extends State<_FilterableApprovedQuoteTimelineDialog> {
  String _query = '';
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.items]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final filtered = sorted.where((item) {
      if (_selectedRange != null &&
          !_inDateRange(item.fecha, _selectedRange!)) {
        return false;
      }
      return _matchesQuery(_query, [
        item.folio,
        item.clientName,
        formatMxn(item.total),
        formatMxn(item.utility),
      ]);
    }).toList();

    return _TimelineShell(
      searchHint: 'Filtra por cliente, folio o monto',
      query: _query,
      onQueryChanged: (value) => setState(() => _query = value),
      rangeLabel: _selectedRange == null
          ? 'Todo el rango actual'
          : _rangeLabel(_selectedRange!),
      onPickRange: sorted.isEmpty ? null : () => _pickRange(sorted),
      onClearRange: _selectedRange == null
          ? null
          : () => setState(() => _selectedRange = null),
      summaryLabel:
          '${filtered.length} de ${sorted.length} cotizaciones aprobadas',
      emptyLabel: 'No hay cotizaciones aprobadas que coincidan con el filtro.',
      children: filtered
          .map(
            (item) => _TimelineRow(
              color: AppColors.primary,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.request_quote_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: item.clientName,
              amount: formatMxn(item.total),
              operationLabel: 'Cotización aprobada ${item.folio}',
              timestampLabel: _dateTimeLabel(item.fecha),
              detailLines: [
                'Utilidad ${formatMxn(item.utility)} • Margen ${item.margin.toStringAsFixed(1)}%',
                'Costo estimado ${formatMxn(item.cost)}',
                'Partidas ${item.lines}',
              ],
            ),
          )
          .toList(),
    );
  }

  Future<void> _pickRange(List<_ApprovedQuoteUtilityDetail> sorted) async {
    final picked = await _showAppDateRangePicker(
      context,
      initialRange:
          _selectedRange ??
          DateTimeRange(
            start: _startOfDay(sorted.last.fecha),
            end: _endOfDay(sorted.first.fecha),
          ),
      firstDate: _startOfDay(sorted.last.fecha),
      lastDate: _endOfDay(sorted.first.fecha),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedRange = DateTimeRange(
        start: _startOfDay(picked.start),
        end: _endOfDay(picked.end),
      );
    });
  }
}

class _TimelineShell extends StatelessWidget {
  const _TimelineShell({
    required this.searchHint,
    required this.query,
    required this.onQueryChanged,
    required this.rangeLabel,
    required this.onPickRange,
    required this.summaryLabel,
    required this.emptyLabel,
    required this.children,
    this.onClearRange,
  });

  final String searchHint;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final String rangeLabel;
  final VoidCallback? onPickRange;
  final VoidCallback? onClearRange;
  final String summaryLabel;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final listContent = children.isEmpty
        ? Center(
            child: Text(
              query.isEmpty ? emptyLabel : 'No hay resultados para "$query".',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : ListView.separated(
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => children[index],
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 860;
        final boundedHeight = constraints.maxHeight.isFinite;
        return Column(
          mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (narrow) ...[
              SearchField(hint: searchHint, onChanged: onQueryChanged),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPickRange,
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(rangeLabel),
                  ),
                  if (onClearRange != null)
                    TextButton(
                      onPressed: onClearRange,
                      child: const Text('Limpiar rango'),
                    ),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      hint: searchHint,
                      onChanged: onQueryChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onPickRange,
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(rangeLabel),
                  ),
                  if (onClearRange != null) const SizedBox(width: 6),
                  if (onClearRange != null)
                    TextButton(
                      onPressed: onClearRange,
                      child: const Text('Limpiar rango'),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              summaryLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            if (boundedHeight)
              Expanded(child: listContent)
            else
              SizedBox(height: 420, child: listContent),
          ],
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.color,
    required this.leading,
    required this.title,
    required this.amount,
    required this.operationLabel,
    required this.timestampLabel,
    required this.detailLines,
  });

  final Color color;
  final Widget leading;
  final String title;
  final String amount;
  final String operationLabel;
  final String timestampLabel;
  final List<String> detailLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            leading,
            Container(
              width: 2,
              height: 74,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.border,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            operationLabel,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timestampLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        amount,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...detailLines
                    .where((line) => line.trim().isNotEmpty)
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopProductsUtilityPanel extends StatelessWidget {
  const _TopProductsUtilityPanel({required this.items});

  final List<_ProductUtilityItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(4).toList();
    return SectionCard(
      title: 'Top productos por utilidad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visible.isEmpty)
            const InlineEmptyMessage()
          else
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY:
                      visible.map((item) => item.utility).reduce(math.max) *
                      1.18,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 94,
                        getTitlesWidget: (value, _) => Text(
                          formatMxn(value),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < 0 || index >= visible.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              visible[index].shortLabel,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    visible.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: visible[index].utility,
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.textPrimary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          formatMxn(rod.toY),
                          const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
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

class _ClientProfitabilityPanel extends StatelessWidget {
  const _ClientProfitabilityPanel({required this.items});

  final List<_ClientProfitabilityItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(4).toList();
    return SectionCard(
      title: 'Rentabilidad por cliente',
      trailing: const _TopChip(
        icon: FontAwesomeIcons.handshakeAngle,
        label: 'Clientes clave',
      ),
      child: visible.isEmpty
          ? const InlineEmptyMessage()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mostramos solo los clientes con mejor utilidad confirmada para que el analisis siga digerible.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                for (var index = 0; index < visible.length; index++) ...[
                  _ClientProfitabilityTile(item: visible[index], index: index),
                  if (index != visible.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _ClientProfitabilityTile extends StatelessWidget {
  const _ClientProfitabilityTile({required this.item, required this.index});

  final _ClientProfitabilityItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              rankingMedalIcon(index),
              if (index < 3) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.clientName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.marginColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.margin.toStringAsFixed(1)}% margen',
                  style: TextStyle(
                    color: item.marginColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ClientMetricTag(
                label: 'Ingresos',
                value: formatMxn(item.revenue),
              ),
              _ClientMetricTag(label: 'Costo', value: formatMxn(item.cost)),
              _ClientMetricTag(
                label: 'Frecuencia',
                value: item.frequencyLabel,
                accent: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Utilidad confirmada ${formatMxn(item.utility)} en ${item.purchaseCount} compras aprobadas.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientMetricTag extends StatelessWidget {
  const _ClientMetricTag({
    required this.label,
    required this.value,
    this.accent = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeConcentrationPanel extends StatelessWidget {
  const _IncomeConcentrationPanel({required this.summary});

  final _IncomeConcentrationSummary summary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Concentracion de ingresos',
      trailing: const _TopChip(
        icon: FontAwesomeIcons.chartPie,
        label: 'Dependencia',
      ),
      child: summary.totalIncome <= 0
          ? const InlineEmptyMessage()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumimos la exposicion a pocos clientes con dos indicadores claros para no abrumar la lectura.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _ShareIndicator(
                  label: 'Top 3 clientes',
                  share: summary.top3Share,
                  accent: summary.dependencyColor,
                ),
                const SizedBox(height: 12),
                _ShareIndicator(
                  label: 'Top 5 clientes',
                  share: summary.top5Share,
                  accent: AppColors.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  '${summary.dependencyLabel}. ${summary.dependencyNarrative}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                for (
                  var index = 0;
                  index < summary.leadingClients.length;
                  index++
                ) ...[
                  _IncomeShareRow(item: summary.leadingClients[index]),
                  if (index != summary.leadingClients.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _ShareIndicator extends StatelessWidget {
  const _ShareIndicator({
    required this.label,
    required this.share,
    required this.accent,
  });

  final String label;
  final double share;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final clamped = share.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '${(clamped * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 560),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IncomeShareRow extends StatelessWidget {
  const _IncomeShareRow({required this.item});

  final _IncomeShareClient item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.clientName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMxn(item.amount),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(item.share * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

LineChartData _lineChartData({
  required List<String> labels,
  required List<double> values,
  required Color color,
  required bool currency,
}) {
  final maxY = values.isEmpty ? 10.0 : values.reduce(math.max) * 1.18;

  return LineChartData(
    minY: 0,
    maxY: maxY <= 0 ? 10.0 : maxY.toDouble(),
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: AppColors.border, strokeWidth: 1),
    ),
    borderData: FlBorderData(show: false),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 94,
          getTitlesWidget: (value, _) => Text(
            currency ? formatMxn(value) : value.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, _) {
            final index = value.toInt();
            if (index < 0 || index >= labels.length) {
              return const SizedBox.shrink();
            }
            if (!shouldShowChartLabel(index, labels.length, maxLabels: 4)) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                labels[index],
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ),
    ),
    lineBarsData: [
      LineChartBarData(
        spots: List.generate(
          values.length,
          (index) => FlSpot(index.toDouble(), values[index]),
        ),
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.10),
        ),
      ),
    ],
    lineTouchData: LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => AppColors.textPrimary,
        getTooltipItems: (spots) => spots
            .map(
              (spot) => LineTooltipItem(
                currency ? formatMxn(spot.y) : spot.y.toStringAsFixed(1),
                const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}

(List<double>, List<String>) _buildWeeklySeries(
  List<(DateTime, double)> source, {
  required DateTimeRange range,
}) {
  final start = _startOfDay(range.start);
  final end = _endOfDay(range.end);
  final values = List<double>.filled(8, 0);
  final labels = List<String>.filled(8, '');
  final formatter = DateFormat('dd MMM');
  final totalDays = math.max(1, end.difference(start).inDays + 1);
  final bucketSize = math.max(1, (totalDays / values.length).ceil());

  for (var index = 0; index < 8; index++) {
    final bucketStart = start.add(Duration(days: index * bucketSize));
    labels[index] = formatter.format(
      bucketStart.isAfter(end) ? end : bucketStart,
    );
  }

  for (final item in source) {
    if (!_inDateRange(item.$1, range)) continue;
    final diff = item.$1.difference(start).inDays;
    if (diff < 0) continue;
    final bucket = math.min(values.length - 1, diff ~/ bucketSize);
    if (bucket >= 0 && bucket < values.length) {
      values[bucket] += item.$2;
    }
  }

  return (values, labels);
}

(List<double>, List<double>) _buildUtilitySeries({
  required DateTimeRange range,
  required List<DetalleCotizacion> detalles,
  required Map<String, Cotizacion> cotizaciones,
  required Map<String, ProductoServicio> productos,
}) {
  final start = _startOfDay(range.start);
  final end = _endOfDay(range.end);
  final utility = List<double>.filled(8, 0);
  final revenue = List<double>.filled(8, 0);
  final totalDays = math.max(1, end.difference(start).inDays + 1);
  final bucketSize = math.max(1, (totalDays / utility.length).ceil());

  for (final item in detalles) {
    final cotizacion = cotizaciones[item.cotizacionId];
    if (cotizacion == null) continue;
    if (cotizacion.estatus != QuoteStatus.aprobada) continue;
    if (!_inDateRange(cotizacion.fechaEmision, range)) continue;
    final diff = cotizacion.fechaEmision.difference(start).inDays;
    if (diff < 0) continue;
    final bucket = math.min(utility.length - 1, diff ~/ bucketSize);
    if (bucket < 0 || bucket >= utility.length) continue;
    final producto = productos[item.productoServicioId];
    final costo = (producto?.costo ?? 0) * item.cantidad;
    final utilidadLinea = item.importe - costo;
    utility[bucket] += utilidadLinea;
    revenue[bucket] += item.importe;
  }

  return (utility, revenue);
}

List<_ProductUtilityItem> _topProductsByUtility({
  required List<DetalleCotizacion> detalles,
  required Map<String, ProductoServicio> productos,
  required Map<String, Cotizacion> cotizaciones,
}) {
  final map = <String, _MutableProductUtility>{};
  for (final item in detalles) {
    final cotizacion = cotizaciones[item.cotizacionId];
    if (cotizacion == null || cotizacion.estatus != QuoteStatus.aprobada) {
      continue;
    }
    final producto = productos[item.productoServicioId];
    final key = item.productoServicioId;
    final current = map.putIfAbsent(
      key,
      () => _MutableProductUtility(name: producto?.nombre ?? item.concepto),
    );
    final costo = (producto?.costo ?? 0) * item.cantidad;
    current.utility += item.importe - costo;
  }

  return map.values
      .map(
        (item) => _ProductUtilityItem(name: item.name, utility: item.utility),
      )
      .toList()
    ..sort((a, b) => b.utility.compareTo(a.utility));
}

List<_ApprovedQuoteUtilityDetail> _buildApprovedQuoteUtilityDetails({
  required List<DetalleCotizacion> detalles,
  required Map<String, Cotizacion> cotizaciones,
  required Map<String, ProductoServicio> productos,
  required Map<String, Cliente> clientes,
}) {
  final grouped = <String, _MutableQuoteUtility>{};

  for (final item in detalles) {
    final cotizacion = cotizaciones[item.cotizacionId];
    if (cotizacion == null || cotizacion.estatus != QuoteStatus.aprobada) {
      continue;
    }

    final current = grouped.putIfAbsent(
      cotizacion.id,
      () => _MutableQuoteUtility(
        clientId: cotizacion.clienteId,
        folio: cotizacion.folio,
        clientName:
            clientes[cotizacion.clienteId]?.nombre ?? cotizacion.clienteId,
        fecha: cotizacion.fechaEmision,
      ),
    );

    final costo =
        (productos[item.productoServicioId]?.costo ?? 0) * item.cantidad;
    current.cost += costo;
    current.revenue += item.importe;
    current.lines += 1;
  }

  return grouped.values
      .map(
        (item) => _ApprovedQuoteUtilityDetail(
          clientId: item.clientId,
          folio: item.folio,
          clientName: item.clientName,
          fecha: item.fecha,
          total: item.revenue,
          cost: item.cost,
          utility: item.revenue - item.cost,
          lines: item.lines,
        ),
      )
      .toList()
    ..sort((a, b) => b.fecha.compareTo(a.fecha));
}

List<_QuoteProbabilityItem> _buildQuoteProbabilityItems({
  required List<Cotizacion> cotizaciones,
  required Map<String, Cliente> clientes,
}) {
  final now = DateTime.now();
  return cotizaciones
      .map(
        (cotizacion) => _QuoteProbabilityItem(
          folio: cotizacion.folio,
          clientName:
              clientes[cotizacion.clienteId]?.nombre ?? cotizacion.clienteId,
          fecha: cotizacion.fechaEmision,
          total: cotizacion.total,
          probability: _quoteCloseProbability(cotizacion, now),
          estatus: cotizacion.estatus,
        ),
      )
      .toList();
}

double _quoteCloseProbability(Cotizacion cotizacion, DateTime now) {
  switch (cotizacion.estatus) {
    case QuoteStatus.aprobada:
      return 1.0;
    case QuoteStatus.rechazada:
      return 0.06;
    case QuoteStatus.enviada:
      break;
    case QuoteStatus.borrador:
      break;
  }

  var probability = cotizacion.estatus == QuoteStatus.enviada ? 0.64 : 0.34;
  final daysSinceEmission = now.difference(cotizacion.fechaEmision).inDays;
  final daysUntilExpiration = cotizacion.fechaVencimiento
      .difference(now)
      .inDays;

  if (daysSinceEmission <= 4) probability += 0.08;
  if (daysSinceEmission >= 12) probability -= 0.06;
  if (daysUntilExpiration <= 3) probability += 0.05;
  if (daysUntilExpiration < 0) probability -= 0.18;
  if (cotizacion.total >= 6000 && cotizacion.total <= 16000) {
    probability += 0.03;
  }
  if (cotizacion.total > 22000) probability -= 0.04;
  if (cotizacion.retIsr) probability -= 0.02;

  return probability.clamp(0.08, 0.96).toDouble();
}

List<_ClientProfitabilityItem> _buildClientProfitabilityItems({
  required List<_ApprovedQuoteUtilityDetail> quotes,
  required Map<String, Cliente> clientes,
}) {
  final grouped = <String, _MutableClientProfitability>{};

  for (final quote in quotes) {
    final current = grouped.putIfAbsent(
      quote.clientId,
      () => _MutableClientProfitability(
        clientId: quote.clientId,
        clientName: clientes[quote.clientId]?.nombre ?? quote.clientName,
      ),
    );
    current.revenue += quote.total;
    current.cost += quote.cost;
    current.purchaseCount += 1;
  }

  return grouped.values
      .map(
        (item) => _ClientProfitabilityItem(
          clientId: item.clientId,
          clientName: item.clientName,
          revenue: item.revenue,
          cost: item.cost,
          purchaseCount: item.purchaseCount,
        ),
      )
      .toList()
    ..sort((a, b) => b.utility.compareTo(a.utility));
}

_IncomeConcentrationSummary _buildIncomeConcentrationSummary({
  required List<Ingreso> ingresos,
  required Map<String, Cliente> clientes,
}) {
  final totals = <String, double>{};
  var totalIncome = 0.0;

  for (final ingreso in ingresos) {
    totals.update(
      ingreso.clienteId,
      (value) => value + ingreso.monto,
      ifAbsent: () => ingreso.monto,
    );
    totalIncome += ingreso.monto;
  }

  final ranked = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final leadingClients = ranked
      .take(3)
      .map(
        (entry) => _IncomeShareClient(
          clientName: clientes[entry.key]?.nombre ?? entry.key,
          amount: entry.value,
          share: totalIncome == 0 ? 0 : entry.value / totalIncome,
        ),
      )
      .toList();
  final top3Share = totalIncome == 0
      ? 0.0
      : ranked.take(3).fold<double>(0, (sum, item) => sum + item.value) /
            totalIncome;
  final top5Share = totalIncome == 0
      ? 0.0
      : ranked.take(5).fold<double>(0, (sum, item) => sum + item.value) /
            totalIncome;

  return _IncomeConcentrationSummary(
    totalIncome: totalIncome,
    top3Share: top3Share,
    top5Share: top5Share,
    leadingClients: leadingClients,
  );
}

String _deltaLabel(List<double> series) {
  if (series.length < 2) return 'No hay datos del periodo anterior.';
  final current = series.last;
  final previous = series[series.length - 2];
  if (previous == 0) return 'No hay datos del periodo anterior.';
  final delta = ((current - previous) / previous) * 100;
  final arrow = delta >= 0 ? '↑' : '↓';
  final value = delta.abs().toStringAsFixed(0);
  return '$arrow ${delta >= 0 ? '+' : '-'}$value% vs periodo anterior';
}

String _paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.transferencia:
      return 'Transferencia';
    case PaymentMethod.efectivo:
      return 'Efectivo';
    case PaymentMethod.tarjeta:
      return 'Tarjeta';
    case PaymentMethod.deposito:
      return 'Deposito';
    case PaymentMethod.otro:
      return 'Otro';
  }
}

class _ProductUtilityItem {
  const _ProductUtilityItem({required this.name, required this.utility});

  final String name;
  final double utility;

  String get shortLabel =>
      name.length <= 10 ? name : '${name.substring(0, 10)}...';
}

class _MutableProductUtility {
  _MutableProductUtility({required this.name});

  final String name;
  double utility = 0;
}

class _ApprovedQuoteUtilityDetail {
  const _ApprovedQuoteUtilityDetail({
    required this.clientId,
    required this.folio,
    required this.clientName,
    required this.fecha,
    required this.total,
    required this.cost,
    required this.utility,
    required this.lines,
  });

  final String clientId;
  final String folio;
  final String clientName;
  final DateTime fecha;
  final double total;
  final double cost;
  final double utility;
  final int lines;

  double get margin => total == 0 ? 0 : (utility / total) * 100;
}

class _MutableQuoteUtility {
  _MutableQuoteUtility({
    required this.clientId,
    required this.folio,
    required this.clientName,
    required this.fecha,
  });

  final String clientId;
  final String folio;
  final String clientName;
  final DateTime fecha;
  double revenue = 0;
  double cost = 0;
  int lines = 0;
}

class _QuoteProbabilityItem {
  const _QuoteProbabilityItem({
    required this.folio,
    required this.clientName,
    required this.fecha,
    required this.total,
    required this.probability,
    required this.estatus,
  });

  final String folio;
  final String clientName;
  final DateTime fecha;
  final double total;
  final double probability;
  final QuoteStatus estatus;

  double get expectedRevenue => total * probability;
  bool get approved => estatus == QuoteStatus.aprobada;
}

class _MutableClientProfitability {
  _MutableClientProfitability({
    required this.clientId,
    required this.clientName,
  });

  final String clientId;
  final String clientName;
  double revenue = 0;
  double cost = 0;
  int purchaseCount = 0;
}

class _ClientProfitabilityItem {
  const _ClientProfitabilityItem({
    required this.clientId,
    required this.clientName,
    required this.revenue,
    required this.cost,
    required this.purchaseCount,
  });

  final String clientId;
  final String clientName;
  final double revenue;
  final double cost;
  final int purchaseCount;

  double get utility => revenue - cost;
  double get margin => revenue == 0 ? 0 : (utility / revenue) * 100;
  Color get marginColor => margin >= 35
      ? AppColors.success
      : margin >= 18
      ? AppColors.warning
      : AppColors.error;
  String get frequencyLabel {
    if (purchaseCount >= 4) return 'Alta';
    if (purchaseCount >= 2) return 'Media';
    return 'Ocasional';
  }
}

class _IncomeConcentrationSummary {
  const _IncomeConcentrationSummary({
    required this.totalIncome,
    required this.top3Share,
    required this.top5Share,
    required this.leadingClients,
  });

  final double totalIncome;
  final double top3Share;
  final double top5Share;
  final List<_IncomeShareClient> leadingClients;

  String get dependencyLabel {
    if (top3Share >= 0.68) return 'Dependencia alta';
    if (top3Share >= 0.5) return 'Dependencia moderada';
    return 'Dependencia saludable';
  }

  String get dependencyNarrative {
    if (top3Share >= 0.68) {
      return 'Conviene diversificar el pipeline para no quedar expuesto a pocos clientes.';
    }
    if (top3Share >= 0.5) {
      return 'Hay concentracion visible, pero aun con margen para equilibrar la cartera.';
    }
    return 'La distribucion se ve equilibrada y reduce el riesgo comercial.';
  }

  Color get dependencyColor => top3Share >= 0.68
      ? AppColors.error
      : top3Share >= 0.5
      ? AppColors.warning
      : AppColors.success;
}

class _IncomeShareClient {
  const _IncomeShareClient({
    required this.clientName,
    required this.amount,
    required this.share,
  });

  final String clientName;
  final double amount;
  final double share;
}

String _dateTimeLabel(DateTime value) {
  return DateFormat('dd/MM/yyyy • HH:mm').format(value);
}

String _rangeLabel(DateTimeRange range) {
  return '${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}';
}

String _recurrenceSummary(
  bool recurrente,
  RecurrenceFrequency frecuencia,
  List<int> diasSemana,
) {
  if (!recurrente || frecuencia == RecurrenceFrequency.ninguna) {
    return 'Operacion unica';
  }
  if (frecuencia == RecurrenceFrequency.diasDeLaSemana) {
    return 'Recurrente ${weekdaySummary(diasSemana)}';
  }
  return 'Recurrente ${frecuencia.label}';
}

bool _matchesQuery(String query, Iterable<String> values) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return values.any((value) => value.toLowerCase().contains(normalized));
}

bool _inDateRange(DateTime value, DateTimeRange range) {
  final current = value;
  return !current.isBefore(_startOfDay(range.start)) &&
      !current.isAfter(_endOfDay(range.end));
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

Future<DateTimeRange?> _showAppDateRangePicker(
  BuildContext context, {
  required DateTimeRange initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final now = DateTime.now();
  return showDateRangePicker(
    context: context,
    initialDateRange: DateTimeRange(
      start: _startOfDay(initialRange.start),
      end: _endOfDay(initialRange.end),
    ),
    firstDate: firstDate ?? DateTime(now.year - 5, 1, 1),
    lastDate: lastDate ?? DateTime(now.year + 2, 12, 31),
    helpText: 'Selecciona un rango',
    cancelText: 'Cancelar',
    confirmText: 'Aplicar',
    saveText: 'Aplicar',
  );
}
