import 'dart:math' as math;

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/gastos/application/gastos_controller.dart';
import 'package:cotimax/features/ingresos/application/ingresos_controller.dart';
import 'package:cotimax/features/proveedores/application/proveedores_controller.dart';
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

class GastosPage extends ConsumerStatefulWidget {
  GastosPage({super.key});

  @override
  ConsumerState<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends ConsumerState<GastosPage> {
  bool _handledCreateRoute = false;
  bool _showProjection = false;
  bool _isProcessingRecurring = false;
  _ProjectionOption _selectedProjection = expenseProjectionOptions[2];
  DateTimeRange? _selectedDateRange;
  final Set<String> _selectedGastoIds = <String>{};

  Future<void> _pickDateRange(List<Gasto> gastos) async {
    if (gastos.isEmpty) return;
    final orderedDates = gastos.map((item) => item.fecha).toList()..sort();
    final firstDate = DateUtils.dateOnly(orderedDates.first);
    final lastDate = DateUtils.dateOnly(orderedDates.last);
    final defaultStart = DateUtils.dateOnly(
      lastDate.subtract(Duration(days: 49)),
    );
    final initialRange =
        _selectedDateRange ??
        DateTimeRange(
          start: defaultStart.isBefore(firstDate) ? firstDate : defaultStart,
          end: lastDate,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialRange,
      currentDate: lastDate,
      helpText: trText('Selecciona el rango'),
      saveText: trText('Aplicar'),
      locale: currentAppLocale(),
    );
    if (picked == null) return;
    setState(() => _selectedDateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    final gastosAsync = ref.watch(gastosControllerProvider);
    final recurrentesAsync = ref.watch(gastosRecurrentesControllerProvider);
    final shouldCreate =
        GoRouterState.of(context).uri.queryParameters['create'] == '1';

    if (!shouldCreate) {
      _handledCreateRoute = false;
    } else if (!_handledCreateRoute) {
      _handledCreateRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openForm(context);
        if (mounted) {
          context.go(RoutePaths.gastos);
        }
      });
    }

    return gastosAsync.when(
      loading: () => ListView(
        children: [
          PageHeader(
            title: 'Gastos',
            subtitle: '',
            actions: [
              ...buildImportExportHeaderActions(context, entityLabel: 'gastos'),
              OutlinedButton.icon(
                onPressed: _isProcessingRecurring
                    ? null
                    : () => _processRecurringExpenses(),
                icon: _isProcessingRecurring
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.sync_rounded),
                label: Text(trText('Procesar recurrencias')),
              ),
              ElevatedButton.icon(
                onPressed: () => _openForm(context),
                icon: Icon(Icons.add),
                label: Text(trText('Nuevo gasto')),
              ),
            ],
          ),
          SizedBox(height: 12),
          LoadingStateWidget(message: 'Cargando gastos...'),
        ],
      ),
      error: (_, __) => ListView(
        children: [
          PageHeader(
            title: 'Gastos',
            subtitle: '',
            actions: [
              ...buildImportExportHeaderActions(context, entityLabel: 'gastos'),
              OutlinedButton.icon(
                onPressed: _isProcessingRecurring
                    ? null
                    : () => _processRecurringExpenses(),
                icon: _isProcessingRecurring
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.sync_rounded),
                label: Text(trText('Procesar recurrencias')),
              ),
              ElevatedButton.icon(
                onPressed: () => _openForm(context),
                icon: Icon(Icons.add),
                label: Text(trText('Nuevo gasto')),
              ),
            ],
          ),
          SizedBox(height: 12),
          ErrorStateWidget(
            message: 'No se pudieron cargar gastos.',
            onRetry: () => ref.invalidate(gastosControllerProvider),
          ),
        ],
      ),
      data: (gastos) {
        if (gastos.isEmpty) {
          return ListView(
            children: [
              PageHeader(
                title: 'Gastos',
                subtitle: '',
                actions: [
                  ...buildImportExportHeaderActions(
                    context,
                    entityLabel: 'gastos',
                  ),
                  OutlinedButton.icon(
                    onPressed: _isProcessingRecurring
                        ? null
                        : () => _processRecurringExpenses(),
                    icon: _isProcessingRecurring
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.sync_rounded),
                    label: Text(trText('Procesar recurrencias')),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context),
                    icon: Icon(Icons.add),
                    label: Text(trText('Nuevo gasto')),
                  ),
                ],
              ),
              SizedBox(height: 12),
              EmptyStateWidget(
                title: 'Todavía no hay gastos',
                subtitle:
                    'Registra tu primer gasto para comenzar a ver resultados.',
                action: ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: Icon(Icons.add),
                  label: Text(trText('Nuevo gasto')),
                ),
              ),
            ],
          );
        }

        final categoriasCatalogo =
            ref.watch(gastoCategoriasControllerProvider).valueOrNull ??
            const <GastoCategoria>[];
        final ingresosCatalogo =
            ref.watch(ingresosControllerProvider).valueOrNull ??
            const <Ingreso>[];
        final linkedIncomeByExpense = _incomeByLinkedExpense(ingresosCatalogo);
        final categorias = {
          for (final item in categoriasCatalogo) item.id: item,
        };
        final orderedDates = gastos.map((item) => item.fecha).toList()..sort();
        final lastDate = DateUtils.dateOnly(orderedDates.last);
        final firstDate = DateUtils.dateOnly(orderedDates.first);
        final defaultRange = DateTimeRange(
          start: lastDate.subtract(Duration(days: 49)).isBefore(firstDate)
              ? firstDate
              : lastDate.subtract(Duration(days: 49)),
          end: lastDate,
        );
        final activeRange = _selectedDateRange ?? defaultRange;
        final filteredGastos = _filterGastosByRange(gastos, activeRange);
        final totalGastos = filteredGastos.fold<double>(
          0,
          (sum, item) => sum + item.monto,
        );
        final totalIngresos = ingresosCatalogo.fold<double>(
          0,
          (sum, item) => sum + item.monto,
        );
        final utilidad = totalIngresos - totalGastos;
        final margen = totalIngresos == 0
            ? 0.0
            : (utilidad / totalIngresos) * 100;
        final salud = margen >= 35
            ? 'Sana'
            : margen >= 20
            ? 'Atencion'
            : 'Riesgo';
        final serie = _buildExpenseSeriesForRange(filteredGastos, activeRange);
        final recurrentes =
            recurrentesAsync.valueOrNull ?? const <GastoRecurrente>[];
        final projectedSerie = _buildProjectedExpenseSeries(
          gastos: filteredGastos,
          recurrentes: recurrentes,
          option: _selectedProjection,
        );
        final chartValues = _showProjection ? projectedSerie.values : serie.$1;
        final chartLabels = _showProjection ? projectedSerie.labels : serie.$2;
        final chartTotal = _showProjection ? projectedSerie.total : totalGastos;
        final rango = _selectedDateRange == null
            ? trText('Ultimas 8 semanas')
            : _formatDateRange(activeRange);
        final baseLabel = _selectedDateRange == null
            ? trText('Base ultimas 8 semanas')
            : tr('Base $rango', 'Base $rango');
        final rankingCategorias = _expenseByCategory(gastos, categorias);
        final rankingProveedores = _expenseByProvider(gastos);
        final linkedExpenseTotal = gastos.fold<double>(
          0,
          (sum, gasto) =>
              sum +
              (linkedIncomeByExpense.containsKey(gasto.id) ? gasto.monto : 0),
        );
        final linkedIncomeTotal = linkedIncomeByExpense.values.fold<double>(
          0,
          (sum, value) => sum + value,
        );
        final linkedDelta = linkedIncomeTotal - linkedExpenseTotal;
        final linkedCoverage = linkedExpenseTotal == 0
            ? 0.0
            : linkedIncomeTotal / linkedExpenseTotal;

        return ListView(
          children: [
            PageHeader(
              title: 'Gastos',
              subtitle: '',
              actions: [
                ...buildImportExportHeaderActions(
                  context,
                  entityLabel: 'gastos',
                ),
                OutlinedButton.icon(
                  onPressed: _isProcessingRecurring
                      ? null
                      : () => _processRecurringExpenses(),
                  icon: _isProcessingRecurring
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.sync_rounded),
                  label: Text(trText('Procesar recurrencias')),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: Icon(Icons.add),
                  label: Text(trText('Nuevo gasto')),
                ),
              ],
            ),
            SizedBox(height: 14),
            SectionCard(
              title: 'Gastos totales',
              trailing: _RangeLabel(label: _showProjection ? baseLabel : rango),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 920;
                      final summary = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showProjection
                                ? trText('Escenario proyectado')
                                : trText('Historico real'),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            formatMxn(chartTotal),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 30,
                              height: 1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 14,
                            runSpacing: 8,
                            children: [
                              _ChartMetaItem(
                                icon: Icons.schedule_rounded,
                                label: _showProjection ? baseLabel : rango,
                                accent: AppColors.accent,
                              ),
                              _ChartMetaItem(
                                icon: Icons.receipt_long_outlined,
                                label: _showProjection
                                    ? 'Horizonte ${_selectedProjection.label}'
                                    : '${filteredGastos.length} gastos registrados',
                                accent: AppColors.accent,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            _showProjection
                                ? 'Estimado con el historial reciente y, principalmente, los gastos recurrentes activos.'
                                : 'Lectura historica de gastos registrados durante el periodo.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ],
                      );

                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            summary,
                            SizedBox(height: 16),
                            _ProjectionToolbar(
                              projected: _showProjection,
                              selectedOption: _selectedProjection,
                              options: expenseProjectionOptions,
                              accent: AppColors.accent,
                              rangeLabel: rango,
                              hasCustomRange: _selectedDateRange != null,
                              onToggleProjection: () {
                                setState(
                                  () => _showProjection = !_showProjection,
                                );
                              },
                              onOptionSelected: (value) {
                                setState(() => _selectedProjection = value);
                              },
                              onPickDateRange: () => _pickDateRange(gastos),
                              onClearDateRange: () {
                                setState(() => _selectedDateRange = null);
                              },
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: summary),
                          SizedBox(width: 18),
                          _ProjectionToolbar(
                            projected: _showProjection,
                            selectedOption: _selectedProjection,
                            options: expenseProjectionOptions,
                            accent: AppColors.accent,
                            rangeLabel: rango,
                            hasCustomRange: _selectedDateRange != null,
                            onToggleProjection: () {
                              setState(
                                () => _showProjection = !_showProjection,
                              );
                            },
                            onOptionSelected: (value) {
                              setState(() => _selectedProjection = value);
                            },
                            onPickDateRange: () => _pickDateRange(gastos),
                            onClearDateRange: () {
                              setState(() => _selectedDateRange = null);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 22),
                  SizedBox(
                    height: 280,
                    child: LineChart(
                      _expenseLineChartData(
                        labels: chartLabels,
                        values: chartValues,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (_showProjection) ...[
                    Text(
                      tr(
                        'Base recurrente estimada: ${formatMxn(_selectedProjection.isWeekly ? _weeklyRecurringExpenseEstimate(recurrentes) : _monthlyRecurringExpenseEstimate(recurrentes))} por ${_selectedProjection.isWeekly ? 'semana' : 'mes'}.',
                        'Estimated recurring base: ${formatMxn(_selectedProjection.isWeekly ? _weeklyRecurringExpenseEstimate(recurrentes) : _monthlyRecurringExpenseEstimate(recurrentes))} per ${_selectedProjection.isWeekly ? 'week' : 'month'}.',
                      ),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '${trText('Estado financiero')}: ${trText(salud)}',
                      style: TextStyle(
                        color: margen >= 35
                            ? AppColors.success
                            : margen >= 20
                            ? AppColors.warning
                            : AppColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${trText('Margen actual')}: ${margen.toStringAsFixed(1)}%. ${trText(margen >= 20 ? 'El gasto se mantiene bajo control.' : 'Conviene revisar gastos para recuperar margen.')}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10),
            SectionCard(
              title: 'Impacto de gastos vinculados',
              child: Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _ChartMetaItem(
                    icon: Icons.account_tree_outlined,
                    label:
                        'Ingresos vinculados: ${formatMxn(linkedIncomeTotal)}',
                    accent: AppColors.primary,
                  ),
                  _ChartMetaItem(
                    icon: Icons.compare_arrows_rounded,
                    label: 'Diferencia: ${formatMxn(linkedDelta)}',
                    accent: linkedDelta >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  _ChartMetaItem(
                    icon: Icons.track_changes_rounded,
                    label: 'Cobertura: ${linkedCoverage.toStringAsFixed(2)}x',
                    accent: AppColors.accent,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1180;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CategoryDistributionCard(
                          rows: rankingCategorias,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _RankingExpenseTable(
                          title: 'Ranking de gastos por proveedor',
                          rows: rankingProveedores,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SectionCard(
                          title: 'Gastos recurrentes',
                          child: recurrentesAsync.when(
                            loading: LoadingSkeleton.new,
                            error: (_, __) => Text(trText('Error')),
                            data: (rows) => Column(
                              children: rows
                                  .map(
                                    (row) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: FinanceIconAvatar(
                                        iconKey: row.iconKey,
                                      ),
                                      title: Text(row.nombre),
                                      subtitle: Text(
                                        _recurrenceDescription(
                                          row.frecuencia,
                                          row.diasSemana,
                                        ),
                                      ),
                                      trailing: Text(formatMxn(row.monto)),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _CategoryDistributionCard(rows: rankingCategorias),
                    SizedBox(height: 10),
                    _RankingExpenseTable(
                      title: 'Ranking de gastos por proveedor',
                      rows: rankingProveedores,
                    ),
                    SizedBox(height: 10),
                    SectionCard(
                      title: 'Gastos recurrentes',
                      child: recurrentesAsync.when(
                        loading: LoadingSkeleton.new,
                        error: (_, __) => Text(trText('Error')),
                        data: (rows) => Column(
                          children: rows
                              .map(
                                (row) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: FinanceIconAvatar(
                                    iconKey: row.iconKey,
                                  ),
                                  title: Text(row.nombre),
                                  subtitle: Text(
                                    _recurrenceDescription(
                                      row.frecuencia,
                                      row.diasSemana,
                                    ),
                                  ),
                                  trailing: Text(formatMxn(row.monto)),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 10),
            FilterBar(
              children: [
                SizedBox(
                  width: 220,
                  child: SelectField<String>(
                    label: 'Categoria',
                    value: 'Todas',
                    options: ['Todas', 'Operacion', 'Marketing'],
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: SelectField<String>(
                    label: 'Proveedor',
                    value: 'Todos',
                    options: ['Todos', 'Proveedor 1', 'Proveedor 2'],
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: SelectField<String>(
                    label: 'Fecha',
                    value: 'Ultimos 60 dias',
                    options: [
                      'Ultimos 7 dias',
                      'Ultimos 30 dias',
                      'Ultimos 60 dias',
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Builder(
              builder: (context) {
                final allSelected = _selectedGastoIds.length == gastos.length;
                final partiallySelected =
                    _selectedGastoIds.isNotEmpty && !allSelected;

                return CotimaxDataTable(
                  toolbar: _selectedGastoIds.isEmpty
                      ? null
                      : TableSelectionToolbar(
                          count: _selectedGastoIds.length,
                          entityLabel: 'gasto',
                          onEdit: _selectedGastoIds.length == 1
                              ? () {
                                  final gasto = gastos.firstWhere(
                                    (item) =>
                                        item.id == _selectedGastoIds.first,
                                  );
                                  _openForm(context, gasto);
                                }
                              : null,
                          onDelete: _deleteSelectedGastos,
                          onClear: () =>
                              setState(() => _selectedGastoIds.clear()),
                        ),
                  columns: [
                    DataColumn(
                      label: Checkbox(
                        value: allSelected
                            ? true
                            : partiallySelected
                            ? null
                            : false,
                        tristate: true,
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _selectedGastoIds
                                ..clear()
                                ..addAll(gastos.map((item) => item.id));
                            } else {
                              _selectedGastoIds.clear();
                            }
                          });
                        },
                      ),
                    ),
                    DataColumn(label: Text(trText('Categoria'))),
                    DataColumn(label: Text(trText('Monto'))),
                    DataColumn(label: Text(trText('Fecha'))),
                    DataColumn(label: Text(trText('Proveedor'))),
                    DataColumn(label: Text(trText('Referencia'))),
                    DataColumn(label: Text(trText('Ingreso vinculado'))),
                    DataColumn(label: Text(trText('Impacto'))),
                    DataColumn(label: Text(trText('Descripcion'))),
                    DataColumn(label: Text(trText('Notas'))),
                    DataColumn(label: Text(trText('Acciones'))),
                  ],
                  rows: gastos
                      .map(
                        (item) => DataRow(
                          selected: _selectedGastoIds.contains(item.id),
                          cells: [
                            DataCell(
                              Checkbox(
                                value: _selectedGastoIds.contains(item.id),
                                onChanged: (value) {
                                  setState(() {
                                    if (value ?? false) {
                                      _selectedGastoIds.add(item.id);
                                    } else {
                                      _selectedGastoIds.remove(item.id);
                                    }
                                  });
                                },
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FinanceIconAvatar(
                                    iconKey: item.iconKey,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    categorias[item.gastoCategoriaId]?.nombre ??
                                        item.gastoCategoriaId,
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              AmountBadge(amount: item.monto, positive: false),
                            ),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy',
                                  currentIntlLocale(),
                                ).format(item.fecha),
                              ),
                            ),
                            DataCell(Text(item.proveedor)),
                            DataCell(Text(item.referencia)),
                            DataCell(
                              Text(
                                formatMxn(linkedIncomeByExpense[item.id] ?? 0),
                              ),
                            ),
                            DataCell(
                              Text(
                                formatMxn(
                                  (linkedIncomeByExpense[item.id] ?? 0) -
                                      item.monto,
                                ),
                                style: TextStyle(
                                  color:
                                      ((linkedIncomeByExpense[item.id] ?? 0) -
                                              item.monto) >=
                                          0
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(Text(item.descripcion)),
                            DataCell(Text(item.notas)),
                            DataCell(
                              RowActionMenu(
                                onSelected: (action) => _onRowAction(
                                  context,
                                  item: item,
                                  action: action,
                                ),
                                actions: [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(trText('Editar')),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(trText('Eliminar')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRecurringExpenses() async {
    if (_isProcessingRecurring) return;
    setState(() => _isProcessingRecurring = true);
    try {
      final created = await ref
          .read(gastosRepositoryProvider)
          .processRecurrentes();
      if (!mounted) return;
      ref.invalidate(gastosControllerProvider);
      ref.invalidate(gastosRecurrentesControllerProvider);
      ToastHelper.showSuccess(
        context,
        created > 0
            ? '$created gastos recurrentes generados.'
            : 'No había gastos recurrentes pendientes.',
      );
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudieron procesar los gastos recurrentes.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingRecurring = false);
      }
    }
  }

  void _openForm(BuildContext context, [Gasto? item]) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: item == null ? 'Nuevo gasto' : 'Editar gasto',
        child: _GastoForm(item: item),
      ),
    );
  }

  Future<void> _onRowAction(
    BuildContext context, {
    required Gasto item,
    required String action,
  }) async {
    if (action == 'edit') {
      _openForm(context, item);
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDeleteConfirmation(
        context,
        entityLabel: 'gasto',
        dependencyEntityType: 'gasto',
        dependencyIds: [item.id],
        onConfirmAsync: () async {
          try {
            await ref.read(gastosRepositoryProvider).delete(item.id);
            if (!context.mounted) return;
            ref.invalidate(gastosControllerProvider);
            ref.invalidate(ingresosControllerProvider);
            ToastHelper.showSuccess(context, 'Gasto eliminado.');
          } catch (error) {
            if (!context.mounted) rethrow;
            ToastHelper.showError(
              context,
              buildActionErrorMessage(error, 'No se pudo eliminar el gasto.'),
            );
            rethrow;
          }
        },
      );
      if (!confirmed) return;
    }
  }

  Future<void> _deleteSelectedGastos() async {
    final count = _selectedGastoIds.length;
    if (count == 0) return;

    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: count == 1 ? 'gasto' : 'gastos seleccionados',
      title: count == 1 ? 'Eliminar gasto' : 'Eliminar gastos',
      message: count == 1
          ? '¿Estás seguro que quieres eliminar este gasto?'
          : '¿Estás seguro que quieres eliminar los $count gastos seleccionados?',
      dependencyEntityType: 'gasto',
      dependencyIds: _selectedGastoIds.toList(),
      onConfirmAsync: () async {
        try {
          final ids = _selectedGastoIds.toList();
          for (final id in ids) {
            await ref.read(gastosRepositoryProvider).delete(id);
          }
          if (!mounted) return;
          ref.invalidate(gastosControllerProvider);
          ref.invalidate(ingresosControllerProvider);
          setState(() => _selectedGastoIds.clear());
          ToastHelper.showSuccess(
            context,
            count == 1
                ? 'Gasto eliminado.'
                : '$count gastos eliminados correctamente.',
          );
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(
              error,
              'No se pudieron eliminar los gastos.',
            ),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }
}

class _GastoForm extends ConsumerStatefulWidget {
  _GastoForm({this.item});

  final Gasto? item;

  @override
  ConsumerState<_GastoForm> createState() => _GastoFormState();
}

class _GastoFormState extends ConsumerState<_GastoForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _tituloController;
  late final TextEditingController _montoController;
  late final TextEditingController _fechaController;
  late final TextEditingController _fechaInicioRecurrenciaController;
  late final TextEditingController _referenciaController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _notasController;
  late final FocusNode _tituloFocusNode;
  late final FocusNode _categoriaFocusNode;
  late final FocusNode _montoFocusNode;
  late final FocusNode _fechaFocusNode;
  late final FocusNode _proveedorFocusNode;
  late final FocusNode _referenciaFocusNode;
  late final FocusNode _descripcionFocusNode;
  late final FocusNode _notasFocusNode;
  String _categoriaValue = '';
  String _categoriaDisplayLabel = '';
  String _proveedorIdValue = '';
  String _proveedorDisplayLabel = '';
  bool _recurrente = false;
  RecurrenceFrequency _recurrencia = RecurrenceFrequency.ninguna;
  final Set<int> _diasSemana = <int>{};
  String _iconKey = 'shopping_cart';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tituloFocusNode = FocusNode();
    _categoriaFocusNode = FocusNode();
    _montoFocusNode = FocusNode();
    _fechaFocusNode = FocusNode();
    _proveedorFocusNode = FocusNode();
    _referenciaFocusNode = FocusNode();
    _descripcionFocusNode = FocusNode();
    _notasFocusNode = FocusNode();
    final item = widget.item;
    _categoriaValue = item?.gastoCategoriaId ?? '';
    _proveedorIdValue = item?.proveedorId ?? '';
    _proveedorDisplayLabel = item?.proveedor ?? '';
    _tituloController = seededTextController(item?.titulo ?? '');
    _montoController = seededTextController(
      item == null
          ? '0.00'
          : formatNumericValue(item.monto, decimalDigits: 2, useGrouping: true),
    );
    _fechaController = seededTextController(
      DateFormat('yyyy-MM-dd').format(item?.fecha ?? DateTime.now()),
    );
    _fechaInicioRecurrenciaController = seededTextController(
      DateFormat(
      'yyyy-MM-dd',
      ).format(item?.fechaInicioRecurrencia ?? item?.fecha ?? DateTime.now()),
    );
    _referenciaController = seededTextController(item?.referencia);
    _descripcionController = seededTextController(item?.descripcion ?? '');
    _notasController = seededTextController(item?.notas);
    _recurrente = item?.recurrente ?? false;
    _recurrencia = item?.recurrencia ?? RecurrenceFrequency.ninguna;
    _diasSemana
      ..clear()
      ..addAll(item?.diasSemana ?? const <int>[]);
    _iconKey = item?.iconKey ?? 'shopping_cart';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tituloController.dispose();
    _montoController.dispose();
    _fechaController.dispose();
    _fechaInicioRecurrenciaController.dispose();
    _referenciaController.dispose();
    _descripcionController.dispose();
    _notasController.dispose();
    _tituloFocusNode.dispose();
    _categoriaFocusNode.dispose();
    _montoFocusNode.dispose();
    _fechaFocusNode.dispose();
    _proveedorFocusNode.dispose();
    _referenciaFocusNode.dispose();
    _descripcionFocusNode.dispose();
    _notasFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriasCatalogo =
        ref.watch(gastoCategoriasControllerProvider).valueOrNull ??
        const <GastoCategoria>[];
    final proveedoresAsync = ref.watch(proveedoresCatalogControllerProvider);
    final categoriaOptions = categoriasCatalogo
        .map((item) => _CategoryOption(value: item.id, label: item.nombre))
        .toList();
    final categoriaSelectOptions = _ensureSelectedCategoryOption(
      options: categoriaOptions,
      currentValue: _categoriaValue,
      fallbackLabel: _categoriaDisplayLabel.isNotEmpty
          ? _categoriaDisplayLabel
          : _categoriaValue,
    );

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SectionCard(
                      title: 'Datos del gasto',
                      titleIcon: FontAwesomeIcons.receipt,
                      headerBackgroundColor: AppColors.background,
                      child: Column(
                        children: [
                          FormFieldWrapper(
                            label: 'Icono del gasto',
                            child: Focus(
                              canRequestFocus: false,
                              skipTraversal: true,
                              child: FinanceIconPicker(
                                selectedKey: _iconKey,
                                onChanged: (value) =>
                                    setState(() => _iconKey = value),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(1),
                            child: FormFieldWrapper(
                              label: 'Título',
                              child: TextField(
                                focusNode: _tituloFocusNode,
                                controller: _tituloController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: trText('Título del gasto'),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: NumericFocusOrder(2),
                                  child: FormFieldWrapper(
                                    label: 'Categoria',
                                    child: _CategoryLookupField(
                                      focusNode: _categoriaFocusNode,
                                      value: _categoriaValue,
                                      options: categoriaSelectOptions,
                                      emptyLabel: 'Sin categoria',
                                      hintText: 'Selecciona una categoria',
                                      emptyStateMessage:
                                          'No hay categorias de gasto registradas.',
                                      buttonLabel: 'Agregar categoria',
                                      onAddPressed: _createExpenseCategory,
                                      onChanged: (value) => setState(() {
                                        _categoriaValue = value;
                                        _categoriaDisplayLabel = '';
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: NumericFocusOrder(3),
                                  child: CurrencyInput(
                                    controller: _montoController,
                                    label: 'Monto',
                                    focusNode: _montoFocusNode,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_categoriaValue.trim().isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  Focus(
                                    canRequestFocus: false,
                                    skipTraversal: true,
                                    child: TextButton.icon(
                                      onPressed: _editExpenseCategory,
                                      icon: Icon(Icons.edit_rounded, size: 16),
                                      label: Text(trText('Editar categoria')),
                                    ),
                                  ),
                                  Focus(
                                    canRequestFocus: false,
                                    skipTraversal: true,
                                    child: TextButton.icon(
                                      onPressed: _deleteExpenseCategory,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                      ),
                                      label: Text(trText('Eliminar categoria')),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    SectionCard(
                      title: 'Seguimiento',
                      titleIcon: FontAwesomeIcons.calendarCheck,
                      headerBackgroundColor: AppColors.background,
                      child: Column(
                        children: [
                          _ResponsiveFormRow(
                            left: FocusTraversalOrder(
                              order: NumericFocusOrder(4),
                              child: FormFieldWrapper(
                                label: 'Fecha',
                                child: TextField(
                                  focusNode: _fechaFocusNode,
                                  controller: _fechaController,
                                  readOnly: true,
                                  onTap: _pickMovementDate,
                                  decoration: InputDecoration(
                                    hintText: trText('AAAA-MM-DD'),
                                    suffixIcon: const Icon(
                                      Icons.calendar_month_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            right: FocusTraversalOrder(
                              order: NumericFocusOrder(5),
                              child: FormFieldWrapper(
                                label: 'Proveedor',
                                child: proveedoresAsync.when(
                                  loading: () => SizedBox(
                                    height: 20,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  error: (_, __) => EmptyFieldState(
                                    hintText:
                                        'No fue posible cargar proveedores.',
                                    message:
                                        'Puedes dejar este campo vacío o intentar cargar los proveedores nuevamente.',
                                    buttonLabel: 'Agregar proveedor',
                                    onPressed: _goToCreateProvider,
                                  ),
                                  data: (proveedores) {
                                    if (proveedores.isEmpty) {
                                      return EmptyFieldState(
                                        hintText:
                                            'No hay proveedores registrados.',
                                        message:
                                            'Puedes dejar este campo vacío o registrar un proveedor para vincularlo a este gasto.',
                                        buttonLabel: 'Agregar proveedor',
                                        onPressed: _goToCreateProvider,
                                      );
                                    }

                                    final resolvedProveedorId =
                                        _resolveProveedorId(proveedores);
                                    return DropdownButtonFormField<String>(
                                      focusNode: _proveedorFocusNode,
                                      value: resolvedProveedorId ?? '',
                                      isExpanded: true,
                                      menuMaxHeight: 320,
                                      borderRadius: cotimaxMenuBorderRadius,
                                      dropdownColor: AppColors.white,
                                      icon: cotimaxDropdownIcon,
                                      style: cotimaxDropdownTextStyle,
                                      decoration: cotimaxDropdownDecoration(
                                        helperText: 'Campo opcional.',
                                      ),
                                      items: [
                                        DropdownMenuItem<String>(
                                          value: '',
                                          child: Text(
                                            tr('Ninguno', 'None'),
                                            overflow: TextOverflow.ellipsis,
                                            style: cotimaxDropdownTextStyle,
                                          ),
                                        ),
                                        ...proveedores.map(
                                          (proveedor) =>
                                              DropdownMenuItem<String>(
                                                value: proveedor.id,
                                                child: Text(
                                                  _providerOptionLabel(
                                                    proveedor,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      cotimaxDropdownTextStyle,
                                                ),
                                              ),
                                        ),
                                      ],
                                      onChanged: (value) => setState(() {
                                        final nextId = value ?? '';
                                        _proveedorIdValue = nextId;
                                        if (nextId.trim().isEmpty) {
                                          _proveedorDisplayLabel = '';
                                          return;
                                        }
                                        for (final proveedor in proveedores) {
                                          if (proveedor.id == nextId) {
                                            _proveedorDisplayLabel =
                                                _providerOptionLabel(proveedor);
                                            return;
                                          }
                                        }
                                        _proveedorDisplayLabel = '';
                                      }),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          _ResponsiveFormRow(
                            left: FocusTraversalOrder(
                              order: NumericFocusOrder(6),
                              child: FormFieldWrapper(
                                label: 'Referencia',
                                child: TextField(
                                  focusNode: _referenciaFocusNode,
                                  controller: _referenciaController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: trText('Folio o referencia'),
                                  ),
                                ),
                              ),
                            ),
                            right: FocusTraversalOrder(
                              order: NumericFocusOrder(7),
                              child: FormFieldWrapper(
                                label: 'Descripcion',
                                child: TextField(
                                  focusNode: _descripcionFocusNode,
                                  controller: _descripcionController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: trText('Descripcion breve'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(8),
                            child: FormFieldWrapper(
                              label: 'Notas',
                              child: TextField(
                                focusNode: _notasFocusNode,
                                controller: _notasController,
                                textInputAction: TextInputAction.next,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: trText('Notas internas del gasto'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    RecurrenceConfigurationCard(
                      title: 'Recurrencia del gasto',
                      titleIcon: FontAwesomeIcons.arrowsRotate,
                      isRecurring: _recurrente,
                      frequency: _recurrencia,
                      selectedWeekdays: _diasSemana,
                      startDateController: _fechaInicioRecurrenciaController,
                      startDateLabel: 'Fecha de inicio',
                      startDateHelperText:
                          'A partir de esta fecha se calculará la siguiente recurrencia.',
                      onStartDateTap: _pickRecurrenceStartDate,
                      onRecurringChanged: (value) {
                        setState(() {
                          _recurrente = value;
                          if (!value) {
                            _recurrencia = RecurrenceFrequency.ninguna;
                            _diasSemana.clear();
                          }
                        });
                      },
                      onFrequencyChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _recurrencia = value;
                          if (!value.supportsWeekdaySelection) {
                            _diasSemana.clear();
                          }
                        });
                      },
                      onToggleWeekday: (value) {
                        setState(() {
                          if (_diasSemana.contains(value)) {
                            _diasSemana.remove(value);
                          } else {
                            _diasSemana.add(value);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(trText('Cancelar')),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.item == null
                              ? Icons.add_rounded
                              : Icons.save_rounded,
                        ),
                  label: Text(
                    widget.item == null ? 'Registrar gasto' : 'Guardar gasto',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final now = DateTime.now();
    final movementDate = DateTime.tryParse(_fechaController.text.trim()) ?? now;
    final recurrenceStartDate =
        DateTime.tryParse(_fechaInicioRecurrenciaController.text.trim()) ??
        movementDate;
    final item = Gasto(
      id: widget.item?.id ?? 'gas-${now.microsecondsSinceEpoch}',
      titulo: _tituloController.text.trim(),
      gastoCategoriaId: _categoriaValue.trim(),
      monto: parseNumericText(_montoController.text) ?? 0,
      fecha: movementDate,
      fechaInicioRecurrencia: _recurrente ? recurrenceStartDate : null,
      descripcion: _descripcionController.text.trim(),
      proveedorId: _proveedorIdValue.trim(),
      proveedor: _resolveProviderLabelForSave(),
      referencia: _referenciaController.text.trim(),
      notas: _notasController.text.trim(),
      recurrente: _recurrente,
      recurrencia: _recurrente ? _recurrencia : RecurrenceFrequency.ninguna,
      diasSemana: _recurrente
          ? (() {
              final dias = _diasSemana.toList();
              dias.sort();
              return dias;
            })()
          : const [],
      iconKey: _iconKey,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(gastosRepositoryProvider).upsert(item);
      ref.invalidate(gastosControllerProvider);
      ref.invalidate(gastosRecurrentesControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.item == null
            ? 'Gasto registrado correctamente.'
            : 'Gasto actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo guardar el gasto.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _providerOptionLabel(Proveedor proveedor) {
    final nombre = proveedor.nombre.trim();
    if (nombre.isNotEmpty) return nombre;
    final empresa = proveedor.empresa.trim();
    if (empresa.isNotEmpty) return empresa;
    return proveedor.id;
  }

  String? _resolveProveedorId(List<Proveedor> proveedores) {
    final selected = _proveedorIdValue.trim();
    if (selected.isNotEmpty) {
      return proveedores.any((item) => item.id == selected) ? selected : null;
    }

    final existingLabel = _proveedorDisplayLabel.trim().toLowerCase();
    if (existingLabel.isEmpty) return null;
    for (final proveedor in proveedores) {
      if (_providerOptionLabel(proveedor).trim().toLowerCase() ==
          existingLabel) {
        return proveedor.id;
      }
    }
    return null;
  }

  String _resolveProviderLabelForSave() {
    final selected = _proveedorIdValue.trim();
    if (selected.isEmpty) return '';
    final proveedores =
        ref.read(proveedoresCatalogControllerProvider).valueOrNull ??
        const <Proveedor>[];
    for (final proveedor in proveedores) {
      if (proveedor.id == selected) {
        return _providerOptionLabel(proveedor);
      }
    }
    return _proveedorDisplayLabel.trim();
  }

  void _goToCreateProvider() {
    context.go('${RoutePaths.proveedores}?create=1');
  }

  Future<void> _pickMovementDate() async {
    final initialDate =
        DateTime.tryParse(_fechaController.text.trim()) ?? DateTime.now();
    final picked = await showCotimaxDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: initialDate,
      locale: currentAppLocale(),
      helpText: trText('Selecciona la fecha'),
      cancelText: trText('Cancelar'),
      confirmText: trText('Aceptar'),
    );
    if (picked == null || !mounted) return;
    assignControllerText(
      _fechaController,
      DateFormat('yyyy-MM-dd').format(picked),
    );
  }

  Future<void> _pickRecurrenceStartDate() async {
    final initialDate =
        DateTime.tryParse(_fechaInicioRecurrenciaController.text.trim()) ??
        DateTime.tryParse(_fechaController.text.trim()) ??
        DateTime.now();
    final picked = await showCotimaxDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: initialDate,
      locale: currentAppLocale(),
      helpText: trText('Selecciona la fecha'),
      cancelText: trText('Cancelar'),
      confirmText: trText('Aceptar'),
    );
    if (picked == null || !mounted) return;
    assignControllerText(
      _fechaInicioRecurrenciaController,
      DateFormat('yyyy-MM-dd').format(picked),
    );
  }

  List<_CategoryOption> _ensureSelectedCategoryOption({
    required List<_CategoryOption> options,
    required String currentValue,
    required String fallbackLabel,
  }) {
    final normalizedValue = currentValue.trim();
    if (normalizedValue.isEmpty) {
      return options;
    }
    for (final option in options) {
      if (option.value == normalizedValue) {
        return options;
      }
    }
    return [
      _CategoryOption(value: normalizedValue, label: fallbackLabel),
      ...options,
    ];
  }

  Future<void> _createExpenseCategory() async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(trText('Nueva categoria de gasto')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: trText('Nombre'),
                    hintText: trText('Ej. Operacion'),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descripcionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: trText('Descripcion'),
                    hintText: trText('Opcional'),
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
                Navigator.of(dialogContext).pop({
                  'nombre': nombreController.text.trim(),
                  'descripcion': descripcionController.text.trim(),
                });
              },
              child: Text(trText('Guardar')),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null) return;

    final nombre = (result['nombre'] ?? '').trim();
    final descripcion = (result['descripcion'] ?? '').trim();
    if (nombre.isEmpty) {
      ToastHelper.showWarning(context, 'Ingresa el nombre de la categoria.');
      return;
    }

    try {
      final categoriaId = await ref
          .read(gastosRepositoryProvider)
          .createCategoria(nombre: nombre, descripcion: descripcion);
      ref.invalidate(gastoCategoriasControllerProvider);
      if (!mounted) return;
      setState(() {
        _categoriaValue = categoriaId;
        _categoriaDisplayLabel = nombre;
      });
      ToastHelper.showSuccess(context, 'Categoria de gasto creada.');
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudo crear la categoria de gasto.',
        ),
      );
    }
  }

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  Future<void> _editExpenseCategory() async {
    final categoriaId = _categoriaValue.trim();
    if (!_looksLikeUuid(categoriaId)) {
      ToastHelper.showWarning(
        context,
        'Esta categoria no se puede editar porque no tiene ID valido.',
      );
      return;
    }

    final categorias =
        ref.read(gastoCategoriasControllerProvider).valueOrNull ??
        const <GastoCategoria>[];
    final actual = categorias.where((item) => item.id == categoriaId);
    if (actual.isEmpty) {
      ToastHelper.showWarning(
        context,
        'No se encontró la categoria seleccionada.',
      );
      return;
    }
    final categoria = actual.first;

    final nombreController = TextEditingController(text: categoria.nombre);
    final descripcionController = TextEditingController(
      text: categoria.descripcion,
    );
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(trText('Editar categoria de gasto')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  autofocus: true,
                  decoration: InputDecoration(labelText: trText('Nombre')),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descripcionController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: trText('Descripcion')),
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
                Navigator.of(dialogContext).pop({
                  'nombre': nombreController.text.trim(),
                  'descripcion': descripcionController.text.trim(),
                });
              },
              child: Text(trText('Guardar')),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null) return;

    final nombre = (result['nombre'] ?? '').trim();
    final descripcion = (result['descripcion'] ?? '').trim();
    if (nombre.isEmpty) {
      ToastHelper.showWarning(context, 'Ingresa el nombre de la categoria.');
      return;
    }

    try {
      await ref
          .read(gastosRepositoryProvider)
          .updateCategoria(
            id: categoriaId,
            nombre: nombre,
            descripcion: descripcion,
          );
      ref.invalidate(gastoCategoriasControllerProvider);
      if (!mounted) return;
      setState(() => _categoriaDisplayLabel = nombre);
      ToastHelper.showSuccess(context, 'Categoria de gasto actualizada.');
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudo actualizar la categoria de gasto.',
        ),
      );
    }
  }

  Future<void> _deleteExpenseCategory() async {
    final categoriaId = _categoriaValue.trim();
    if (!_looksLikeUuid(categoriaId)) {
      ToastHelper.showWarning(
        context,
        'Esta categoria no se puede eliminar porque no tiene ID valido.',
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(trText('Eliminar categoria')),
        content: Text(
          trText('¿Seguro que quieres eliminar esta categoria de gasto?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(trText('Cancelar')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(trText('Eliminar')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(gastosRepositoryProvider).deleteCategoria(categoriaId);
      ref.invalidate(gastoCategoriasControllerProvider);
      if (!mounted) return;
      setState(() {
        _categoriaValue = '';
        _categoriaDisplayLabel = '';
      });
      ToastHelper.showSuccess(context, 'Categoria de gasto eliminada.');
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudo eliminar la categoria de gasto.',
        ),
      );
    }
  }
}

class _ResponsiveFormRow extends StatelessWidget {
  _ResponsiveFormRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(children: [left, SizedBox(height: 12), right]);
        }

        return Row(
          children: [
            Expanded(child: left),
            SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _CategoryOption {
  _CategoryOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _CategoryLookupField extends StatelessWidget {
  _CategoryLookupField({
    this.focusNode,
    required this.value,
    required this.options,
    required this.emptyLabel,
    required this.hintText,
    required this.emptyStateMessage,
    required this.buttonLabel,
    required this.onAddPressed,
    required this.onChanged,
  });

  final FocusNode? focusNode;
  final String value;
  final List<_CategoryOption> options;
  final String emptyLabel;
  final String hintText;
  final String emptyStateMessage;
  final String buttonLabel;
  final VoidCallback onAddPressed;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return _CategoryLookupEmptyState(
        message: emptyStateMessage,
        buttonLabel: buttonLabel,
        onPressed: onAddPressed,
      );
    }

    final selectedValue = options.any((option) => option.value == value)
        ? value
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          focusNode: focusNode,
          initialValue: selectedValue,
          isExpanded: true,
          menuMaxHeight: 320,
          borderRadius: cotimaxMenuBorderRadius,
          dropdownColor: AppColors.white,
          icon: cotimaxDropdownIcon,
          style: cotimaxDropdownTextStyle,
          decoration: cotimaxDropdownDecoration(hintText: hintText),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(
                trText(emptyLabel),
                overflow: TextOverflow.ellipsis,
                style: cotimaxDropdownTextStyle,
              ),
            ),
            ...options.map(
              (option) => DropdownMenuItem(
                value: option.value,
                child: Text(
                  trText(option.label),
                  overflow: TextOverflow.ellipsis,
                  style: cotimaxDropdownTextStyle,
                ),
              ),
            ),
          ],
          onChanged: (nextValue) => onChanged(nextValue ?? ''),
        ),
        SizedBox(height: 8),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          child: TextButton.icon(
            onPressed: onAddPressed,
            icon: Icon(Icons.add_rounded, size: 16),
            label: Text(trText(buttonLabel)),
          ),
        ),
      ],
    );
  }
}

class _CategoryLookupEmptyState extends StatelessWidget {
  _CategoryLookupEmptyState({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trText(message),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 10),
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            child: TextButton.icon(
              onPressed: onPressed,
              icon: Icon(Icons.add_rounded, size: 16),
              label: Text(trText(buttonLabel)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeLabel extends StatelessWidget {
  _RangeLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      trText(label),
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ChartMetaItem extends StatelessWidget {
  _ChartMetaItem({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: accent),
        SizedBox(width: 6),
        Text(
          trText(label),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProjectionToolbar extends StatelessWidget {
  _ProjectionToolbar({
    required this.projected,
    required this.selectedOption,
    required this.options,
    required this.accent,
    required this.rangeLabel,
    required this.hasCustomRange,
    required this.onToggleProjection,
    required this.onOptionSelected,
    required this.onPickDateRange,
    required this.onClearDateRange,
  });

  final bool projected;
  final _ProjectionOption selectedOption;
  final List<_ProjectionOption> options;
  final Color accent;
  final String rangeLabel;
  final bool hasCustomRange;
  final VoidCallback onToggleProjection;
  final ValueChanged<_ProjectionOption> onOptionSelected;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateRange;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ProjectionModeButton(
          label: 'Historico',
          icon: Icons.show_chart_rounded,
          active: !projected,
          accent: accent,
          onPressed: projected ? onToggleProjection : null,
        ),
        _ProjectionModeButton(
          label: 'Proyeccion',
          icon: Icons.auto_graph_rounded,
          active: projected,
          accent: accent,
          onPressed: projected ? null : onToggleProjection,
        ),
        _DateRangeButton(
          label: rangeLabel,
          accent: accent,
          onPressed: onPickDateRange,
        ),
        if (hasCustomRange)
          _ProjectionResetButton(
            label: 'Limpiar rango',
            accent: accent,
            onPressed: onClearDateRange,
          ),
        if (projected)
          PopupMenuButton<_ProjectionOption>(
            tooltip: 'Cambiar proyección',
            offset: Offset(0, 8),
            onSelected: onOptionSelected,
            itemBuilder: (context) => options
                .map(
                  (option) => PopupMenuItem<_ProjectionOption>(
                    value: option,
                    child: Text(trText(option.label)),
                  ),
                )
                .toList(),
            child: _ProjectionOptionButton(
              label: selectedOption.label,
              accent: accent,
            ),
          ),
      ],
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  _DateRangeButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.textPrimary,
      ),
      icon: Icon(Icons.date_range_rounded, size: 16, color: accent),
      label: Text(
        trText(label),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProjectionModeButton extends StatelessWidget {
  _ProjectionModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed ?? () {},
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: active ? accent : AppColors.textSecondary,
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        trText(label),
        style: TextStyle(
          fontSize: 13,
          fontWeight: active ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectionResetButton extends StatelessWidget {
  _ProjectionResetButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: accent,
      ),
      child: Text(
        trText(label),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProjectionOptionButton extends StatelessWidget {
  _ProjectionOptionButton({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          trText(label),
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.expand_more_rounded, color: accent, size: 18),
      ],
    );
  }
}

class _ProjectionOption {
  const _ProjectionOption({
    required this.label,
    required this.periodCount,
    required this.isWeekly,
  });

  final String label;
  final int periodCount;
  final bool isWeekly;
}

class _ProjectedChartData {
  _ProjectedChartData({
    required this.labels,
    required this.values,
    required this.total,
  });

  final List<String> labels;
  final List<double> values;
  final double total;
}

const expenseProjectionOptions = <_ProjectionOption>[
  _ProjectionOption(label: '1 semana', periodCount: 1, isWeekly: true),
  _ProjectionOption(label: '2 semanas', periodCount: 2, isWeekly: true),
  _ProjectionOption(label: '1 mes', periodCount: 1, isWeekly: false),
  _ProjectionOption(label: '2 meses', periodCount: 2, isWeekly: false),
  _ProjectionOption(label: '3 meses', periodCount: 3, isWeekly: false),
  _ProjectionOption(label: '4 meses', periodCount: 4, isWeekly: false),
  _ProjectionOption(label: '5 meses', periodCount: 5, isWeekly: false),
  _ProjectionOption(label: '6 meses', periodCount: 6, isWeekly: false),
  _ProjectionOption(label: '1 año', periodCount: 12, isWeekly: false),
];

class _CategoryDistributionCard extends StatelessWidget {
  _CategoryDistributionCard({required this.rows});

  final List<_ExpenseRankingItem> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.take(4).toList();
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
    ];

    return SectionCard(
      title: 'Ranking de gastos por categoria',
      child: Column(
        children: [
          SizedBox(
            height: 188,
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      'Sin datos de categoria',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 42,
                      sectionsSpace: 3,
                      sections: List.generate(
                        visible.length,
                        (index) => PieChartSectionData(
                          value: visible[index].amount,
                          color: colors[index % colors.length],
                          title: '',
                          radius: 17,
                        ),
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 6),
          ...List.generate(visible.length, (index) {
            final item = visible[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (index < 3) ...[
                    rankingMedalIcon(index),
                    SizedBox(width: 8),
                  ],
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatMxn(item.amount),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RankingExpenseTable extends StatelessWidget {
  _RankingExpenseTable({required this.title, required this.rows});

  final String title;
  final List<_ExpenseRankingItem> rows;

  @override
  Widget build(BuildContext context) {
    return CotimaxDataTable(
      title: title,
      columns: [
        DataColumn(label: Text(trText('Nombre'))),
        DataColumn(label: Text(trText('Movs'))),
        DataColumn(label: Text(trText('Gasto'))),
      ],
      rows: rows
          .take(6)
          .toList()
          .asMap()
          .entries
          .map(
            (entry) => DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      if (entry.key < 3) ...[
                        rankingMedalIcon(entry.key),
                        SizedBox(width: 8),
                      ],
                      Expanded(child: Text(entry.value.name)),
                    ],
                  ),
                ),
                DataCell(Text('${entry.value.count}')),
                DataCell(Text(formatMxn(entry.value.amount))),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _ExpenseRankingItem {
  _ExpenseRankingItem({
    required this.name,
    required this.amount,
    required this.count,
  });

  final String name;
  final double amount;
  final int count;
}

LineChartData _expenseLineChartData({
  required List<String> labels,
  required List<double> values,
}) {
  final maxY = values.isEmpty ? 10.0 : values.reduce(math.max) * 1.18;
  final singleValue = values.length == 1;
  final spots = singleValue
      ? [FlSpot(0, values.first), FlSpot(1, values.first)]
      : List.generate(
          values.length,
          (index) => FlSpot(index.toDouble(), values[index]),
        );
  return LineChartData(
    minY: 0,
    minX: 0,
    maxX: spots.length <= 1 ? 1 : (spots.length - 1).toDouble(),
    maxY: maxY <= 0 ? 10.0 : maxY,
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: AppColors.border, strokeWidth: 1),
    ),
    borderData: FlBorderData(show: false),
    titlesData: FlTitlesData(
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 94,
          getTitlesWidget: (value, _) => Text(
            formatMxn(value),
            style: TextStyle(
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
              return SizedBox.shrink();
            }
            if (!shouldShowChartLabel(index, labels.length, maxLabels: 4)) {
              return SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                labels[index],
                style: TextStyle(
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
        spots: spots,
        isCurved: values.length > 2,
        color: AppColors.accent,
        barWidth: 3,
        dotData: FlDotData(
          show: singleValue,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4.5,
            color: AppColors.accent,
            strokeWidth: 2,
            strokeColor: AppColors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: !singleValue,
          color: AppColors.accent.withValues(alpha: 0.10),
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
                formatMxn(spot.y),
                TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
              ),
            )
            .toList(),
      ),
    ),
  );
}

(List<double>, List<String>) _buildExpenseSeriesForRange(
  List<Gasto> gastos,
  DateTimeRange range,
) {
  final start = DateUtils.dateOnly(range.start);
  final end = DateUtils.dateOnly(range.end);
  final totalDays = end.difference(start).inDays + 1;

  if (totalDays <= 14) {
    final labels = <String>[];
    final values = <double>[];
    for (var index = 0; index < totalDays; index++) {
      final currentDay = start.add(Duration(days: index));
      labels.add(DateFormat('dd MMM', currentIntlLocale()).format(currentDay));
      values.add(
        gastos
            .where((item) => DateUtils.isSameDay(item.fecha, currentDay))
            .fold<double>(0, (sum, item) => sum + item.monto),
      );
    }
    return (values, labels);
  }

  if (totalDays <= 120) {
    final labels = <String>[];
    final values = <double>[];
    final weekCount = (totalDays / 7).ceil();
    for (var index = 0; index < weekCount; index++) {
      final weekStart = start.add(Duration(days: index * 7));
      final weekEnd = weekStart.add(Duration(days: 6));
      labels.add(DateFormat('dd MMM', currentIntlLocale()).format(weekStart));
      values.add(
        gastos
            .where(
              (item) =>
                  !item.fecha.isBefore(weekStart) &&
                  !item.fecha.isAfter(end.isBefore(weekEnd) ? end : weekEnd),
            )
            .fold<double>(0, (sum, item) => sum + item.monto),
      );
    }
    return (values, labels);
  }

  final labels = <String>[];
  final values = <double>[];
  var currentMonth = DateTime(start.year, start.month);
  final lastMonth = DateTime(end.year, end.month);

  while (!currentMonth.isAfter(lastMonth)) {
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    labels.add(DateFormat('MMM yy', currentIntlLocale()).format(currentMonth));
    values.add(
      gastos
          .where(
            (item) =>
                !item.fecha.isBefore(start) &&
                item.fecha.isBefore(nextMonth) &&
                !item.fecha.isAfter(end),
          )
          .where((item) => _sameMonth(item.fecha, currentMonth))
          .fold<double>(0, (sum, item) => sum + item.monto),
    );
    currentMonth = nextMonth;
  }

  return (values, labels);
}

_ProjectedChartData _buildProjectedExpenseSeries({
  required List<Gasto> gastos,
  required List<GastoRecurrente> recurrentes,
  required _ProjectionOption option,
}) {
  return option.isWeekly
      ? _buildProjectedExpenseWeeks(gastos, recurrentes, option.periodCount)
      : _buildProjectedExpenseMonths(gastos, recurrentes, option.periodCount);
}

_ProjectedChartData _buildProjectedExpenseWeeks(
  List<Gasto> gastos,
  List<GastoRecurrente> recurrentes,
  int horizon,
) {
  final actual = _buildHistoricalExpenseWeeks(gastos, weeks: 8);
  final source = [...actual.values];
  final trend = _growthTrend(source);
  final recurringBase = _weeklyRecurringExpenseEstimate(recurrentes);
  final labels = <String>[];
  final values = <double>[];
  var currentWeek = _startOfWeek(DateTime.now());

  for (var index = 0; index < horizon; index++) {
    currentWeek = currentWeek.add(Duration(days: 7));
    final projected = math.max(
      recurringBase,
      _weightedAverage(source) * (1 + (trend * 0.14)),
    );
    source.add(projected);
    labels.add(DateFormat('dd MMM', currentIntlLocale()).format(currentWeek));
    values.add(projected.toDouble());
  }

  return _ProjectedChartData(
    labels: labels,
    values: values,
    total: values.fold<double>(0, (sum, item) => sum + item),
  );
}

_ProjectedChartData _buildProjectedExpenseMonths(
  List<Gasto> gastos,
  List<GastoRecurrente> recurrentes,
  int horizon,
) {
  final actual = _buildHistoricalExpenseMonths(gastos, months: 6);
  final source = [...actual.values];
  final trend = _growthTrend(source);
  final recurringBase = _monthlyRecurringExpenseEstimate(recurrentes);
  final labels = <String>[];
  final values = <double>[];
  var currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  for (var index = 0; index < horizon; index++) {
    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    final projected = math.max(
      recurringBase,
      _weightedAverage(source) * (1 + (trend * 0.25)),
    );
    source.add(projected);
    labels.add(DateFormat('MMM yy', currentIntlLocale()).format(currentMonth));
    values.add(projected.toDouble());
  }

  return _ProjectedChartData(
    labels: labels,
    values: values,
    total: values.fold<double>(0, (sum, item) => sum + item),
  );
}

_ProjectedChartData _buildHistoricalExpenseWeeks(
  List<Gasto> gastos, {
  required int weeks,
}) {
  final currentWeek = _startOfWeek(DateTime.now());
  final labels = <String>[];
  final values = <double>[];

  for (var index = 0; index < weeks; index++) {
    final weekStart = currentWeek.subtract(
      Duration(days: (weeks - 1 - index) * 7),
    );
    final weekEnd = weekStart.add(Duration(days: 6));
    labels.add(DateFormat('dd MMM', currentIntlLocale()).format(weekStart));
    values.add(
      gastos
          .where(
            (item) =>
                !item.fecha.isBefore(weekStart) && !item.fecha.isAfter(weekEnd),
          )
          .fold<double>(0, (sum, item) => sum + item.monto),
    );
  }

  return _ProjectedChartData(
    labels: labels,
    values: values,
    total: values.fold<double>(0, (sum, item) => sum + item),
  );
}

_ProjectedChartData _buildHistoricalExpenseMonths(
  List<Gasto> gastos, {
  required int months,
}) {
  if (gastos.isEmpty) {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    return _ProjectedChartData(
      labels: [DateFormat('MMM yy', currentIntlLocale()).format(currentMonth)],
      values: const [0],
      total: 0,
    );
  }

  final monthTotals = <DateTime, double>{};
  for (final item in gastos) {
    final key = DateTime(item.fecha.year, item.fecha.month);
    monthTotals.update(
      key,
      (value) => value + item.monto,
      ifAbsent: () => item.monto,
    );
  }

  final orderedMonths = monthTotals.keys.toList()..sort();
  final visibleMonths = orderedMonths.length > months
      ? orderedMonths.sublist(orderedMonths.length - months)
      : orderedMonths;
  final labels = <String>[];
  final values = <double>[];

  for (final monthKey in visibleMonths) {
    labels.add(DateFormat('MMM yy', currentIntlLocale()).format(monthKey));
    values.add(monthTotals[monthKey] ?? 0);
  }

  return _ProjectedChartData(
    labels: labels,
    values: values,
    total: values.fold<double>(0, (sum, item) => sum + item),
  );
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
  return ((last - previous) / previous).clamp(-0.18, 0.18);
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

List<Gasto> _filterGastosByRange(List<Gasto> gastos, DateTimeRange? range) {
  if (range == null) return gastos;
  final start = DateUtils.dateOnly(range.start);
  final end = DateUtils.dateOnly(
    range.end,
  ).add(Duration(hours: 23, minutes: 59, seconds: 59));
  return gastos
      .where((item) => !item.fecha.isBefore(start) && !item.fecha.isAfter(end))
      .toList();
}

String _formatDateRange(DateTimeRange range) {
  final formatter = DateFormat('dd MMM yyyy', currentIntlLocale());
  return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
}

DateTime _startOfWeek(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day,
  ).subtract(Duration(days: value.weekday - 1));
}

List<_ExpenseRankingItem> _expenseByCategory(
  List<Gasto> gastos,
  Map<String, GastoCategoria> categorias,
) {
  final map = <String, _ExpenseMutableRanking>{};
  for (final item in gastos) {
    final ranking = map.putIfAbsent(
      item.gastoCategoriaId,
      () => _ExpenseMutableRanking(
        name:
            categorias[item.gastoCategoriaId]?.nombre ?? item.gastoCategoriaId,
      ),
    );
    ranking.amount += item.monto;
    ranking.count += 1;
  }
  return map.values
      .map(
        (item) => _ExpenseRankingItem(
          name: item.name,
          amount: item.amount,
          count: item.count,
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

List<_ExpenseRankingItem> _expenseByProvider(List<Gasto> gastos) {
  final map = <String, _ExpenseMutableRanking>{};
  for (final item in gastos) {
    final ranking = map.putIfAbsent(
      item.proveedor,
      () => _ExpenseMutableRanking(name: item.proveedor),
    );
    ranking.amount += item.monto;
    ranking.count += 1;
  }
  return map.values
      .map(
        (item) => _ExpenseRankingItem(
          name: item.name,
          amount: item.amount,
          count: item.count,
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

Map<String, double> _incomeByLinkedExpense(List<Ingreso> ingresos) {
  final map = <String, double>{};
  for (final item in ingresos) {
    final gastoId = item.gastoFuenteId.trim();
    if (gastoId.isEmpty) continue;
    map[gastoId] = (map[gastoId] ?? 0) + item.monto;
  }
  return map;
}

String _recurrenceDescription(
  RecurrenceFrequency frequency,
  List<int> diasSemana,
) {
  if (frequency.supportsWeekdaySelection) {
    return '${frequency.label} • ${weekdaySummary(diasSemana)}';
  }
  return frequency.label;
}

class _ExpenseMutableRanking {
  _ExpenseMutableRanking({required this.name});

  final String name;
  double amount = 0;
  int count = 0;
}
