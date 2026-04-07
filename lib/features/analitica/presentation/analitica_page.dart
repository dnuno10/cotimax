import 'dart:math' as math;

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/features/clientes/application/clientes_controller.dart';
import 'package:cotimax/features/cotizaciones/application/cotizaciones_controller.dart';
import 'package:cotimax/features/gastos/application/gastos_controller.dart';
import 'package:cotimax/features/ingresos/application/ingresos_controller.dart';
import 'package:cotimax/features/productos/application/productos_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnaliticaPage extends ConsumerStatefulWidget {
  const AnaliticaPage({super.key});

  @override
  ConsumerState<AnaliticaPage> createState() => _AnaliticaPageState();
}

class _AnaliticaPageState extends ConsumerState<AnaliticaPage> {
  _ProjectionRangeOption _selectedProjection = projectionRangeOptions.last;

  @override
  Widget build(BuildContext context) {
    final ingresos =
        ref.watch(ingresosControllerProvider).valueOrNull ?? const <Ingreso>[];
    final gastos =
        ref.watch(gastosControllerProvider).valueOrNull ?? const <Gasto>[];
    final cotizaciones =
        ref.watch(cotizacionesControllerProvider).valueOrNull ??
        const <Cotizacion>[];
    final detalles =
        ref.watch(detalleCotizacionesControllerProvider).valueOrNull ??
        const <DetalleCotizacion>[];
    final clientes = {
      for (final item
          in (ref.watch(clientesControllerProvider).valueOrNull ??
              const <Cliente>[]))
        item.id: item,
    };
    final categorias = {
      for (final item
          in (ref.watch(gastoCategoriasControllerProvider).valueOrNull ??
              const <GastoCategoria>[]))
        item.id: item,
    };
    final productos = {
      for (final item
          in (ref.watch(productosControllerProvider).valueOrNull ??
              const <ProductoServicio>[]))
        item.id: item,
    };
    final recurrentes =
        ref.watch(gastosRecurrentesControllerProvider).valueOrNull ??
        const <GastoRecurrente>[];

    final actualMonths = _buildHistoricalMonths(
      ingresos: ingresos,
      gastos: gastos,
      cotizaciones: cotizaciones,
      detalles: detalles,
      clientes: clientes,
      categorias: categorias,
      productos: productos,
      months: 6,
    );
    final weeklyRows = _buildWeeklyRows(
      ingresos: ingresos,
      gastos: gastos,
      cotizaciones: cotizaciones,
      detalles: detalles,
      productos: productos,
      weeks: 8,
    );
    final forecastMonths = _buildForecastMonths(
      actualMonths: actualMonths,
      recurrentes: recurrentes,
      horizon: 12,
    );
    final forecastWeeks = _buildForecastWeeks(
      actualWeeks: weeklyRows,
      recurrentes: recurrentes,
      horizon: 2,
    );
    final projectionRows = _selectedProjection.isWeekly
        ? forecastWeeks.take(_selectedProjection.periodCount).toList()
        : forecastMonths.take(_selectedProjection.periodCount).toList();
    final totalForecastIngresos = projectionRows.fold<double>(
      0,
      (sum, item) => sum + item.ingresos,
    );
    final totalForecastGastos = projectionRows.fold<double>(
      0,
      (sum, item) => sum + item.gastos,
    );
    final totalForecastLibre = projectionRows.fold<double>(
      0,
      (sum, item) => sum + item.dineroLibre,
    );
    final recentCoverage = actualMonths.isEmpty
        ? 0.0
        : actualMonths.last.coverageRatio;
    final burnMultiple = actualMonths.isEmpty
        ? 0.0
        : actualMonths.last.burnMultiple;
    final annualRunRate = actualMonths.isEmpty
        ? 0.0
        : actualMonths.map((item) => item.ingresos).reduce((a, b) => a + b) /
              actualMonths.length *
              12;
    final averageFreeCash = actualMonths.isEmpty
        ? 0.0
        : actualMonths.map((item) => item.flujoCaja).reduce((a, b) => a + b) /
              actualMonths.length;
    final scenarioBase = projectionRows.isEmpty
        ? 0.0
        : totalForecastLibre / projectionRows.length;
    final scenarioConservative = scenarioBase * 0.88;
    final scenarioExpansion = scenarioBase * 1.12;

    return SingleChildScrollView(
      child: Column(
        children: [
          PageHeader(
            title: 'Analítica',
            subtitle:
                'Lectura financiera avanzada con flujo libre, cobertura, burn multiple y proyecciones operativas.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1180;
              if (stacked) {
                return Column(
                  children: [
                    _WeeklyPulseCard(rows: weeklyRows),
                    const SizedBox(height: 12),
                    _MonthlyBarCard(rows: actualMonths),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _WeeklyPulseCard(rows: weeklyRows)),
                  const SizedBox(width: 12),
                  Expanded(child: _MonthlyBarCard(rows: actualMonths)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Indicadores clave',
            child: _AnalyticsSummaryStrip(
              items: [
                _AnalyticsSummaryItem(
                  title: 'Cobertura operativa',
                  value: '${recentCoverage.toStringAsFixed(2)}x',
                  subtitle: 'Ingresos / gastos del ultimo mes',
                  accent: AppColors.primary,
                ),
                _AnalyticsSummaryItem(
                  title: 'Burn multiple',
                  value: burnMultiple.isFinite
                      ? '${burnMultiple.toStringAsFixed(2)}x'
                      : '0.00x',
                  subtitle: 'Gastos / utilidad confirmada',
                  accent: AppColors.accent,
                ),
                _AnalyticsSummaryItem(
                  title: 'Run rate anual',
                  value: formatMxn(annualRunRate),
                  subtitle: 'Promedio mensual anualizado',
                  accent: AppColors.success,
                ),
                _AnalyticsSummaryItem(
                  title: 'Flujo libre promedio',
                  value: formatMxn(averageFreeCash),
                  subtitle: 'Ingreso cobrado menos gasto mensual',
                  accent: AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ProjectionCard(
            rows: projectionRows,
            totalIngresos: totalForecastIngresos,
            totalGastos: totalForecastGastos,
            totalLibre: totalForecastLibre,
            selectedProjection: _selectedProjection,
            onProjectionChanged: (value) {
              setState(() => _selectedProjection = value);
            },
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Escenarios y lectura',
            child: _AnalyticsSummaryStrip(
              items: [
                _AnalyticsSummaryItem(
                  title: 'Escenario conservador',
                  value: formatMxn(scenarioConservative),
                  subtitle: '12% menos dinero libre promedio',
                  accent: AppColors.warning,
                ),
                _AnalyticsSummaryItem(
                  title: 'Escenario base',
                  value: formatMxn(scenarioBase),
                  subtitle: 'Promedio esperado por mes',
                  accent: AppColors.primary,
                ),
                _AnalyticsSummaryItem(
                  title: 'Escenario expansion',
                  value: formatMxn(scenarioExpansion),
                  subtitle: '12% mas dinero libre promedio',
                  accent: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ResultsBreakdownList(
            rows: [...actualMonths, ...projectionRows],
            selectedProjection: _selectedProjection,
            onProjectionChanged: (value) {
              setState(() => _selectedProjection = value);
            },
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSummaryItem {
  const _AnalyticsSummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
}

class _AnalyticsSummaryStrip extends StatelessWidget {
  const _AnalyticsSummaryStrip({required this.items});

  final List<_AnalyticsSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;
        if (stacked) {
          return Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _AnalyticsSummaryEntry(item: items[index]),
                if (index != items.length - 1)
                  const Divider(height: 24, color: AppColors.border),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(child: _AnalyticsSummaryEntry(item: items[index])),
              if (index != items.length - 1)
                Container(
                  width: 1,
                  height: 74,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.border,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _AnalyticsSummaryEntry extends StatelessWidget {
  const _AnalyticsSummaryEntry({required this.item});

  final _AnalyticsSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trText(item.title),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.value,
          style: TextStyle(
            color: item.accent,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          trText(item.subtitle),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _WeeklyPulseCard extends StatelessWidget {
  const _WeeklyPulseCard({required this.rows});

  final List<_AnalyticsRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SectionCard(
        title: 'Pulso semanal',
        trailing: _AnalyticsLegend(
          items: [
            ('Gastos', AppColors.accent),
            ('Utilidad confirmada', AppColors.primary),
            ('Dinero libre', AppColors.success),
          ],
        ),
        child: const InlineEmptyMessage(),
      );
    }

    final maxY = rows.isEmpty
        ? 10.0
        : rows
                  .expand(
                    (row) => [
                      row.gastos,
                      row.utilidadConfirmada,
                      row.dineroLibre,
                    ],
                  )
                  .reduce(math.max) *
              1.18;

    return SectionCard(
      title: 'Pulso semanal',
      trailing: _AnalyticsLegend(
        items: [
          ('Gastos', AppColors.accent),
          ('Utilidad confirmada', AppColors.primary),
          ('Dinero libre', AppColors.success),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compara el gasto semanal contra la utilidad confirmada por cotizaciones aprobadas para entender cuanto dinero queda realmente libre.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 10 : maxY,
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
                        if (index < 0 || index >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            rows[index].label,
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
                  _analyticsLine(
                    rows: rows,
                    selector: (row) => row.gastos,
                    color: AppColors.accent,
                    fillOpacity: 0.02,
                  ),
                  _analyticsLine(
                    rows: rows,
                    selector: (row) => row.utilidadConfirmada,
                    color: AppColors.primary,
                    fillOpacity: 0.08,
                  ),
                  _analyticsLine(
                    rows: rows,
                    selector: (row) => row.dineroLibre,
                    color: AppColors.success,
                    fillOpacity: 0.04,
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            formatMxn(spot.y),
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
        ],
      ),
    );
  }
}

class _MonthlyBarCard extends StatelessWidget {
  const _MonthlyBarCard({required this.rows});

  final List<_AnalyticsRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SectionCard(
        title: 'Cierre mensual',
        trailing: _AnalyticsLegend(
          items: [
            ('Ingresos', AppColors.primary),
            ('Gastos', AppColors.accent),
            ('Flujo de caja', AppColors.success),
          ],
        ),
        child: const InlineEmptyMessage(),
      );
    }

    final maxY = rows.isEmpty
        ? 10.0
        : rows
                  .expand((row) => [row.ingresos, row.gastos, row.flujoCaja])
                  .reduce(math.max) *
              1.18;

    return SectionCard(
      title: 'Cierre mensual',
      trailing: _AnalyticsLegend(
        items: [
          ('Ingresos', AppColors.primary),
          ('Gastos', AppColors.accent),
          ('Flujo de caja', AppColors.success),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lectura mensual mas directa: cuanto entro, cuanto salio y cuanto flujo quedo despues de operar.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 10 : maxY,
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
                        if (index < 0 || index >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            rows[index].label,
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
                barGroups: rows
                    .asMap()
                    .entries
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.key,
                        barsSpace: 6,
                        barRods: [
                          _barRod(entry.value.ingresos, AppColors.primary),
                          _barRod(entry.value.gastos, AppColors.accent),
                          _barRod(entry.value.flujoCaja, AppColors.success),
                        ],
                      ),
                    )
                    .toList(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final labels = ['Ingresos', 'Gastos', 'Flujo'];
                      return BarTooltipItem(
                        '${labels[rodIndex]} ${formatMxn(rod.toY)}',
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

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({
    required this.rows,
    required this.totalIngresos,
    required this.totalGastos,
    required this.totalLibre,
    required this.selectedProjection,
    required this.onProjectionChanged,
  });

  final List<_AnalyticsRow> rows;
  final double totalIngresos;
  final double totalGastos;
  final double totalLibre;
  final _ProjectionRangeOption selectedProjection;
  final ValueChanged<_ProjectionRangeOption> onProjectionChanged;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SectionCard(
        title: 'Proyeccion operativa',
        trailing: SizedBox(
          width: 170,
          child: _ProjectionRangeDropdown(
            value: selectedProjection,
            onChanged: onProjectionChanged,
          ),
        ),
        child: const InlineEmptyMessage(),
      );
    }

    final maxY = rows.isEmpty
        ? 10.0
        : rows
                  .expand(
                    (row) => [
                      row.ingresos,
                      row.gastos,
                      math.max(0, row.dineroLibre),
                    ],
                  )
                  .reduce(math.max) *
              1.18;

    return SectionCard(
      title: 'Proyeccion operativa',
      trailing: SizedBox(
        width: 170,
        child: _ProjectionRangeDropdown(
          value: selectedProjection,
          onChanged: onProjectionChanged,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnalyticsSummaryStrip(
            items: [
              _AnalyticsSummaryItem(
                title: 'Ingresos proyectados',
                value: formatMxn(totalIngresos),
                subtitle: 'Total en el horizonte seleccionado',
                accent: AppColors.primary,
              ),
              _AnalyticsSummaryItem(
                title: 'Gastos proyectados',
                value: formatMxn(totalGastos),
                subtitle: 'Base operativa esperada',
                accent: AppColors.accent,
              ),
              _AnalyticsSummaryItem(
                title: 'Dinero libre proyectado',
                value: formatMxn(totalLibre),
                subtitle: 'Resultado neto proyectado',
                accent: totalLibre >= 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 10 : maxY,
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
                        if (index < 0 || index >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        if (!shouldShowChartLabel(
                          index,
                          rows.length,
                          maxLabels: 6,
                        )) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            rows[index].label,
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
                  _analyticsLine(
                    rows: rows,
                    selector: (row) => row.ingresos,
                    color: AppColors.primary,
                    fillOpacity: 0.06,
                  ),
                  _analyticsLine(
                    rows: rows,
                    selector: (row) => row.gastos,
                    color: AppColors.accent,
                  ),
                  _analyticsLine(
                    rows: rows,
                    selector: (row) => math.max(0, row.dineroLibre),
                    color: AppColors.success,
                    fillOpacity: 0.04,
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            formatMxn(spot.y),
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
        ],
      ),
    );
  }
}

class _AnalyticsLegend extends StatelessWidget {
  const _AnalyticsLegend({required this.items});

  final List<(String, Color)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.$2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  trText(item.$1),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _ProjectionRangeDropdown extends StatelessWidget {
  const _ProjectionRangeDropdown({
    required this.value,
    required this.onChanged,
  });

  final _ProjectionRangeOption value;
  final ValueChanged<_ProjectionRangeOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<_ProjectionRangeOption>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 320,
      borderRadius: cotimaxMenuBorderRadius,
      dropdownColor: AppColors.white,
      icon: cotimaxDropdownIcon,
      style: cotimaxDropdownTextStyle,
      decoration: cotimaxDropdownDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
      items: projectionRangeOptions
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(
                trText(option.label),
                overflow: TextOverflow.ellipsis,
                style: cotimaxDropdownTextStyle,
              ),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next == null) return;
        onChanged(next);
      },
    );
  }
}

class _ResultsBreakdownList extends StatelessWidget {
  const _ResultsBreakdownList({
    required this.rows,
    required this.selectedProjection,
    required this.onProjectionChanged,
  });

  final List<_AnalyticsRow> rows;
  final _ProjectionRangeOption selectedProjection;
  final ValueChanged<_ProjectionRangeOption> onProjectionChanged;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SectionCard(
        title: 'Tabla de resultados',
        trailing: SizedBox(
          width: 170,
          child: _ProjectionRangeDropdown(
            value: selectedProjection,
            onChanged: onProjectionChanged,
          ),
        ),
        child: const InlineEmptyMessage(),
      );
    }

    return SectionCard(
      title: 'Tabla de resultados',
      trailing: SizedBox(
        width: 170,
        child: _ProjectionRangeDropdown(
          value: selectedProjection,
          onChanged: onProjectionChanged,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    trText('Periodo'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    trText('Ingresos'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    trText('Gastos'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    trText('Libre'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _ResultsExpansionRow(row: row),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsExpansionRow extends StatelessWidget {
  const _ResultsExpansionRow({required this.row});

  final _AnalyticsRow row;

  @override
  Widget build(BuildContext context) {
    final periodType = row.isProjected
        ? trText('Proyeccion')
        : trText('Actual');

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textSecondary,
          leading: Icon(
            row.isProjected
                ? Icons.auto_graph_rounded
                : Icons.calendar_month_rounded,
            color: row.isProjected
                ? AppColors.primary
                : AppColors.textSecondary,
            size: 20,
          ),
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trText(row.label),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      periodType,
                      style: TextStyle(
                        color: row.isProjected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  formatMxn(row.ingresos),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  formatMxn(row.gastos),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  formatMxn(row.dineroLibre),
                  style: TextStyle(
                    color: row.dineroLibre >= 0
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              tr(
                '$periodType • ${row.sections.length} secciones',
                '$periodType • ${row.sections.length} sections',
              ),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          children: [_PeriodBreakdownBody(row: row)],
        ),
      ),
    );
  }
}

class _PeriodBreakdownBody extends StatelessWidget {
  const _PeriodBreakdownBody({required this.row});

  final _AnalyticsRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PeriodMetricsStrip(row: row),
        if (row.sections.isNotEmpty) const SizedBox(height: 14),
        if (row.sections.isNotEmpty)
          Column(
            children: [
              for (var index = 0; index < row.sections.length; index++) ...[
                _BreakdownSectionCard(
                  section: row.sections[index],
                  isLast: index == row.sections.length - 1,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _PeriodMetricsStrip extends StatelessWidget {
  const _PeriodMetricsStrip({required this.row});

  final _AnalyticsRow row;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _PeriodMetricLine(
          label: trText('Ingresos'),
          value: formatMxn(row.ingresos),
          color: AppColors.primary,
        ),
        _PeriodMetricLine(
          label: trText('Gastos'),
          value: formatMxn(row.gastos),
          color: AppColors.accent,
        ),
        _PeriodMetricLine(
          label: trText('Utilidad confirmada'),
          value: formatMxn(row.utilidadConfirmada),
          color: AppColors.success,
        ),
        _PeriodMetricLine(
          label: trText('Flujo libre'),
          value: formatMxn(row.dineroLibre),
          color: row.dineroLibre >= 0 ? AppColors.success : AppColors.error,
        ),
        _PeriodMetricLine(
          label: trText('Cobertura'),
          value: '${row.coverageRatio.toStringAsFixed(2)}x',
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _PeriodMetricLine extends StatelessWidget {
  const _PeriodMetricLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: '${trText(label)}: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownSectionCard extends StatelessWidget {
  const _BreakdownSectionCard({required this.section, required this.isLast});

  final _AnalyticsSection section;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tone = section.total >= 0 ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trText(section.title),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatMxn(section.total),
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              '${section.items.length} movimientos',
              '${section.items.length} entries',
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          if (section.items.isNotEmpty) const SizedBox(height: 12),
          for (var index = 0; index < section.items.length; index++)
            _BreakdownSectionItemTile(
              item: section.items[index],
              isLast: index == section.items.length - 1,
              highlighted: index.isEven,
            ),
        ],
      ),
    );
  }
}

class _BreakdownSectionItemTile extends StatelessWidget {
  const _BreakdownSectionItemTile({
    required this.item,
    required this.isLast,
    required this.highlighted,
  });

  final _AnalyticsSectionItem item;
  final bool isLast;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final positive = item.amount >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trText(item.label),
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
                style: TextStyle(
                  color: positive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (item.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              trText(item.subtitle),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

LineChartBarData _analyticsLine({
  required List<_AnalyticsRow> rows,
  required double Function(_AnalyticsRow row) selector,
  required Color color,
  double fillOpacity = 0,
}) {
  return LineChartBarData(
    spots: List.generate(
      rows.length,
      (index) => FlSpot(index.toDouble(), selector(rows[index])),
    ),
    isCurved: false,
    color: color,
    barWidth: 2.5,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: fillOpacity > 0,
      color: color.withValues(alpha: fillOpacity),
    ),
  );
}

BarChartRodData _barRod(double value, Color color) {
  return BarChartRodData(
    toY: value,
    color: color,
    width: 12,
    borderRadius: BorderRadius.circular(5),
  );
}

List<_AnalyticsRow> _buildHistoricalMonths({
  required List<Ingreso> ingresos,
  required List<Gasto> gastos,
  required List<Cotizacion> cotizaciones,
  required List<DetalleCotizacion> detalles,
  required Map<String, Cliente> clientes,
  required Map<String, GastoCategoria> categorias,
  required Map<String, ProductoServicio> productos,
  required int months,
}) {
  final now = DateTime.now();
  final monthKeys = List.generate(
    months,
    (index) => DateTime(now.year, now.month - (months - 1 - index)),
  );
  final quoteUtilityByMonth = _approvedQuoteUtilityByMonth(
    cotizaciones: cotizaciones,
    detalles: detalles,
    productos: productos,
  );

  return monthKeys.map((monthKey) {
    final ingresosDelMes =
        ingresos.where((item) => _sameMonth(item.fecha, monthKey)).toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final gastosDelMes =
        gastos.where((item) => _sameMonth(item.fecha, monthKey)).toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final cotizacionesDelMes = _approvedQuoteItemsForMonth(
      monthKey: monthKey,
      cotizaciones: cotizaciones,
      detalles: detalles,
      clientes: clientes,
      productos: productos,
    );
    final ingresosMes = ingresosDelMes.fold<double>(
      0,
      (sum, item) => sum + item.monto,
    );
    final gastosMes = gastosDelMes.fold<double>(
      0,
      (sum, item) => sum + item.monto,
    );
    final utilidadMes = quoteUtilityByMonth[monthKey] ?? 0.0;

    return _AnalyticsRow(
      period: monthKey,
      label: DateFormat('MMM yy', currentIntlLocale()).format(monthKey),
      ingresos: ingresosMes,
      gastos: gastosMes,
      utilidadConfirmada: utilidadMes,
      flujoCaja: ingresosMes - gastosMes,
      dineroLibre: utilidadMes - gastosMes,
      isProjected: false,
      sections: [
        _AnalyticsSection(
          title: 'Cotizaciones aprobadas',
          total: cotizacionesDelMes.fold<double>(
            0,
            (sum, item) => sum + item.amount,
          ),
          items: cotizacionesDelMes,
        ),
        _AnalyticsSection(
          title: 'Ingresos cobrados',
          total: ingresosMes,
          items: ingresosDelMes
              .map(
                (item) => _AnalyticsSectionItem(
                  label:
                      clientes[item.clienteId]?.nombre ?? 'Ingreso registrado',
                  subtitle:
                      '${DateFormat('dd/MM/yyyy', currentIntlLocale()).format(item.fecha)} • ${trText(item.metodoPago.label)} • ${item.referencia}',
                  amount: item.monto,
                ),
              )
              .toList(),
        ),
        _AnalyticsSection(
          title: 'Gastos del periodo',
          total: -gastosMes,
          items: gastosDelMes
              .map(
                (item) => _AnalyticsSectionItem(
                  label:
                      categorias[item.gastoCategoriaId]?.nombre ??
                      item.gastoCategoriaId,
                  subtitle:
                      '${DateFormat('dd/MM/yyyy', currentIntlLocale()).format(item.fecha)} • ${item.proveedor} • ${item.descripcion}',
                  amount: -item.monto,
                ),
              )
              .toList(),
        ),
      ],
    );
  }).toList();
}

List<_AnalyticsRow> _buildForecastMonths({
  required List<_AnalyticsRow> actualMonths,
  required List<GastoRecurrente> recurrentes,
  required int horizon,
}) {
  final incomeSeries = actualMonths.map((item) => item.ingresos).toList();
  final expenseSeries = actualMonths.map((item) => item.gastos).toList();
  final utilitySeries = actualMonths
      .map((item) => item.utilidadConfirmada)
      .toList();
  final recurringExpense = _monthlyRecurringExpenseEstimate(recurrentes);
  final incomeTrend = _growthTrend(incomeSeries);
  final expenseTrend = _growthTrend(expenseSeries);
  final utilityTrend = _growthTrend(utilitySeries);
  final rows = <_AnalyticsRow>[];
  var currentMonth = actualMonths.isEmpty
      ? DateTime(DateTime.now().year, DateTime.now().month)
      : actualMonths.last.period;

  for (var index = 0; index < horizon; index++) {
    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    final projectedIngresos = math
        .max(0, _weightedAverage(incomeSeries) * (1 + (incomeTrend * 0.35)))
        .toDouble();
    final projectedGastos = math
        .max(
          recurringExpense,
          _weightedAverage(expenseSeries) * (1 + (expenseTrend * 0.25)),
        )
        .toDouble();
    final projectedUtility = math
        .max(0, _weightedAverage(utilitySeries) * (1 + (utilityTrend * 0.30)))
        .toDouble();

    final row = _AnalyticsRow(
      period: currentMonth,
      label: DateFormat('MMM yy', currentIntlLocale()).format(currentMonth),
      ingresos: projectedIngresos,
      gastos: projectedGastos,
      utilidadConfirmada: projectedUtility,
      flujoCaja: projectedIngresos - projectedGastos,
      dineroLibre: projectedUtility - projectedGastos,
      isProjected: true,
      sections: [
        _AnalyticsSection(
          title: 'Ingresos proyectados',
          total: projectedIngresos,
          items: [
            _AnalyticsSectionItem(
              label: 'Tendencia de ingresos cobrados',
              subtitle: 'Estimado con promedio ponderado y tendencia reciente',
              amount: projectedIngresos,
            ),
          ],
        ),
        _AnalyticsSection(
          title: 'Utilidad confirmada proyectada',
          total: projectedUtility,
          items: [
            _AnalyticsSectionItem(
              label: 'Cotizaciones aprobadas estimadas',
              subtitle: 'Modelo basado en aprobaciones y utilidad historica',
              amount: projectedUtility,
            ),
          ],
        ),
        _AnalyticsSection(
          title: 'Gastos proyectados',
          total: -projectedGastos,
          items: [
            _AnalyticsSectionItem(
              label: 'Base operativa y gasto recurrente',
              subtitle:
                  'Incluye tendencia de gasto y cargas recurrentes activas',
              amount: -projectedGastos,
            ),
          ],
        ),
      ],
    );
    rows.add(row);
    incomeSeries.add(projectedIngresos);
    expenseSeries.add(projectedGastos);
    utilitySeries.add(projectedUtility);
  }

  return rows;
}

List<_AnalyticsRow> _buildForecastWeeks({
  required List<_AnalyticsRow> actualWeeks,
  required List<GastoRecurrente> recurrentes,
  required int horizon,
}) {
  final incomeSeries = actualWeeks.map((item) => item.ingresos).toList();
  final expenseSeries = actualWeeks.map((item) => item.gastos).toList();
  final utilitySeries = actualWeeks
      .map((item) => item.utilidadConfirmada)
      .toList();
  final recurringExpense = _weeklyRecurringExpenseEstimate(recurrentes);
  final incomeTrend = _growthTrend(incomeSeries);
  final expenseTrend = _growthTrend(expenseSeries);
  final utilityTrend = _growthTrend(utilitySeries);
  final rows = <_AnalyticsRow>[];
  var currentWeek = actualWeeks.isEmpty
      ? _startOfWeek(DateTime.now())
      : actualWeeks.last.period;

  for (var index = 0; index < horizon; index++) {
    currentWeek = currentWeek.add(const Duration(days: 7));
    final projectedIngresos = math
        .max(0, _weightedAverage(incomeSeries) * (1 + (incomeTrend * 0.18)))
        .toDouble();
    final projectedGastos = math
        .max(
          recurringExpense,
          _weightedAverage(expenseSeries) * (1 + (expenseTrend * 0.14)),
        )
        .toDouble();
    final projectedUtility = math
        .max(0, _weightedAverage(utilitySeries) * (1 + (utilityTrend * 0.15)))
        .toDouble();

    final row = _AnalyticsRow(
      period: currentWeek,
      label: 'Sem ${index + 1}',
      ingresos: projectedIngresos,
      gastos: projectedGastos,
      utilidadConfirmada: projectedUtility,
      flujoCaja: projectedIngresos - projectedGastos,
      dineroLibre: projectedUtility - projectedGastos,
      isProjected: true,
      sections: [
        _AnalyticsSection(
          title: 'Ingresos proyectados',
          total: projectedIngresos,
          items: [
            _AnalyticsSectionItem(
              label: 'Tendencia semanal de ingresos',
              subtitle: 'Proyeccion basada en semanas recientes',
              amount: projectedIngresos,
            ),
          ],
        ),
        _AnalyticsSection(
          title: 'Utilidad confirmada proyectada',
          total: projectedUtility,
          items: [
            _AnalyticsSectionItem(
              label: 'Cotizaciones aprobadas esperadas',
              subtitle: 'Estimado con comportamiento reciente',
              amount: projectedUtility,
            ),
          ],
        ),
        _AnalyticsSection(
          title: 'Gastos proyectados',
          total: -projectedGastos,
          items: [
            _AnalyticsSectionItem(
              label: 'Carga operativa semanal',
              subtitle: 'Incluye recurrencias activas y tendencia de gasto',
              amount: -projectedGastos,
            ),
          ],
        ),
      ],
    );
    rows.add(row);
    incomeSeries.add(projectedIngresos);
    expenseSeries.add(projectedGastos);
    utilitySeries.add(projectedUtility);
  }

  return rows;
}

List<_AnalyticsRow> _buildWeeklyRows({
  required List<Ingreso> ingresos,
  required List<Gasto> gastos,
  required List<Cotizacion> cotizaciones,
  required List<DetalleCotizacion> detalles,
  required Map<String, ProductoServicio> productos,
  required int weeks,
}) {
  final currentWeek = _startOfWeek(DateTime.now());
  final quoteUtilityByWeek = _approvedQuoteUtilityByWeek(
    cotizaciones: cotizaciones,
    detalles: detalles,
    productos: productos,
  );

  return List.generate(weeks, (index) {
    final weekStart = currentWeek.subtract(
      Duration(days: (weeks - 1 - index) * 7),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    final ingresosSemana = ingresos
        .where(
          (item) =>
              !item.fecha.isBefore(weekStart) && !item.fecha.isAfter(weekEnd),
        )
        .fold<double>(0, (sum, item) => sum + item.monto);
    final gastosSemana = gastos
        .where(
          (item) =>
              !item.fecha.isBefore(weekStart) && !item.fecha.isAfter(weekEnd),
        )
        .fold<double>(0, (sum, item) => sum + item.monto);
    final utilidadSemana = quoteUtilityByWeek[weekStart] ?? 0.0;

    return _AnalyticsRow(
      period: weekStart,
      label: DateFormat('dd MMM', currentIntlLocale()).format(weekStart),
      ingresos: ingresosSemana,
      gastos: gastosSemana,
      utilidadConfirmada: utilidadSemana,
      flujoCaja: ingresosSemana - gastosSemana,
      dineroLibre: utilidadSemana - gastosSemana,
      isProjected: false,
      sections: const [],
    );
  });
}

Map<DateTime, double> _approvedQuoteUtilityByMonth({
  required List<Cotizacion> cotizaciones,
  required List<DetalleCotizacion> detalles,
  required Map<String, ProductoServicio> productos,
}) {
  final approved = {
    for (final item in cotizaciones.where(
      (item) => item.estatus == QuoteStatus.aprobada,
    ))
      item.id: item,
  };
  final map = <DateTime, double>{};

  for (final item in detalles) {
    final cotizacion = approved[item.cotizacionId];
    if (cotizacion == null) continue;
    final monthKey = DateTime(
      cotizacion.fechaEmision.year,
      cotizacion.fechaEmision.month,
    );
    final cost =
        (productos[item.productoServicioId]?.costo ?? 0) * item.cantidad;
    map.update(
      monthKey,
      (value) => value + (item.importe - cost),
      ifAbsent: () => item.importe - cost,
    );
  }

  return map;
}

List<_AnalyticsSectionItem> _approvedQuoteItemsForMonth({
  required DateTime monthKey,
  required List<Cotizacion> cotizaciones,
  required List<DetalleCotizacion> detalles,
  required Map<String, Cliente> clientes,
  required Map<String, ProductoServicio> productos,
}) {
  final approved = cotizaciones
      .where(
        (item) =>
            item.estatus == QuoteStatus.aprobada &&
            _sameMonth(item.fechaEmision, monthKey),
      )
      .toList();
  final items = <_AnalyticsSectionItem>[];

  for (final cotizacion in approved) {
    final lines = detalles
        .where((item) => item.cotizacionId == cotizacion.id)
        .toList();
    final utility = lines.fold<double>(0, (sum, line) {
      final cost =
          (productos[line.productoServicioId]?.costo ?? 0) * line.cantidad;
      return sum + (line.importe - cost);
    });
    items.add(
      _AnalyticsSectionItem(
        label: cotizacion.folio,
        subtitle:
            '${clientes[cotizacion.clienteId]?.nombre ?? cotizacion.clienteId} • ${DateFormat('dd/MM/yyyy', currentIntlLocale()).format(cotizacion.fechaEmision)}',
        amount: utility,
      ),
    );
  }

  return items;
}

Map<DateTime, double> _approvedQuoteUtilityByWeek({
  required List<Cotizacion> cotizaciones,
  required List<DetalleCotizacion> detalles,
  required Map<String, ProductoServicio> productos,
}) {
  final approved = {
    for (final item in cotizaciones.where(
      (item) => item.estatus == QuoteStatus.aprobada,
    ))
      item.id: item,
  };
  final map = <DateTime, double>{};

  for (final item in detalles) {
    final cotizacion = approved[item.cotizacionId];
    if (cotizacion == null) continue;
    final weekKey = _startOfWeek(cotizacion.fechaEmision);
    final cost =
        (productos[item.productoServicioId]?.costo ?? 0) * item.cantidad;
    map.update(
      weekKey,
      (value) => value + (item.importe - cost),
      ifAbsent: () => item.importe - cost,
    );
  }

  return map;
}

double _weightedAverage(List<double> source) {
  if (source.isEmpty) return 0;
  final recent = source.length >= 3
      ? source.sublist(source.length - 3)
      : [...source];
  if (recent.length == 1) return recent.first;
  if (recent.length == 2) return recent[1] * 0.6 + recent[0] * 0.4;
  return recent[2] * 0.5 + recent[1] * 0.3 + recent[0] * 0.2;
}

double _growthTrend(List<double> source) {
  if (source.length < 2) return 0;
  final last = source[source.length - 1];
  final previous = source[source.length - 2];
  if (previous == 0) return 0;
  final growth = (last - previous) / previous;
  return growth.clamp(-0.18, 0.18);
}

double _monthlyRecurringExpenseEstimate(List<GastoRecurrente> rows) {
  var total = 0.0;
  for (final item in rows.where((row) => row.activo)) {
    total += switch (item.frecuencia) {
      RecurrenceFrequency.ninguna => 0,
      RecurrenceFrequency.cadaDia => item.monto * 30,
      RecurrenceFrequency.diasDeLaSemana =>
        item.monto * item.diasSemana.length * 4.2,
      RecurrenceFrequency.finDeSemana => item.monto * 8.6,
      RecurrenceFrequency.cadaSemana => item.monto * 4.33,
      RecurrenceFrequency.cadaDosSemanas => item.monto * 2.16,
      RecurrenceFrequency.cadaCuatroSemanas => item.monto * 1.08,
      RecurrenceFrequency.cadaMes => item.monto,
      RecurrenceFrequency.cadaDosMeses => item.monto / 2,
      RecurrenceFrequency.cadaTresMeses => item.monto / 3,
      RecurrenceFrequency.cadaCuatroMeses => item.monto / 4,
      RecurrenceFrequency.cadaSeisMeses => item.monto / 6,
      RecurrenceFrequency.cadaAnio => item.monto / 12,
    };
  }
  return total;
}

double _weeklyRecurringExpenseEstimate(List<GastoRecurrente> rows) {
  return _monthlyRecurringExpenseEstimate(rows) / 4.33;
}

bool _sameMonth(DateTime value, DateTime month) {
  return value.year == month.year && value.month == month.month;
}

DateTime _startOfWeek(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day,
  ).subtract(Duration(days: value.weekday - 1));
}

class _AnalyticsRow {
  const _AnalyticsRow({
    required this.period,
    required this.label,
    required this.ingresos,
    required this.gastos,
    required this.utilidadConfirmada,
    required this.flujoCaja,
    required this.dineroLibre,
    required this.isProjected,
    required this.sections,
  });

  final DateTime period;
  final String label;
  final double ingresos;
  final double gastos;
  final double utilidadConfirmada;
  final double flujoCaja;
  final double dineroLibre;
  final bool isProjected;
  final List<_AnalyticsSection> sections;

  double get coverageRatio => gastos == 0 ? 0 : ingresos / gastos;
  double get burnMultiple =>
      utilidadConfirmada <= 0 ? 0 : gastos / utilidadConfirmada;
}

class _AnalyticsSection {
  const _AnalyticsSection({
    required this.title,
    required this.total,
    required this.items,
  });

  final String title;
  final double total;
  final List<_AnalyticsSectionItem> items;
}

class _AnalyticsSectionItem {
  const _AnalyticsSectionItem({
    required this.label,
    required this.subtitle,
    required this.amount,
  });

  final String label;
  final String subtitle;
  final double amount;
}

class _ProjectionRangeOption {
  const _ProjectionRangeOption({
    required this.label,
    required this.periodCount,
    required this.isWeekly,
  });

  final String label;
  final int periodCount;
  final bool isWeekly;
}

const projectionRangeOptions = <_ProjectionRangeOption>[
  _ProjectionRangeOption(label: '1 semana', periodCount: 1, isWeekly: true),
  _ProjectionRangeOption(label: '2 semanas', periodCount: 2, isWeekly: true),
  _ProjectionRangeOption(label: '1 mes', periodCount: 1, isWeekly: false),
  _ProjectionRangeOption(label: '2 meses', periodCount: 2, isWeekly: false),
  _ProjectionRangeOption(label: '3 meses', periodCount: 3, isWeekly: false),
  _ProjectionRangeOption(label: '4 meses', periodCount: 4, isWeekly: false),
  _ProjectionRangeOption(label: '5 meses', periodCount: 5, isWeekly: false),
  _ProjectionRangeOption(label: '6 meses', periodCount: 6, isWeekly: false),
  _ProjectionRangeOption(label: '1 año', periodCount: 12, isWeekly: false),
];
