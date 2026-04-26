import 'dart:math' as math;

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
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

class IngresosPage extends ConsumerStatefulWidget {
  IngresosPage({super.key});

  @override
  ConsumerState<IngresosPage> createState() => _IngresosPageState();
}

class _IngresosPageState extends ConsumerState<IngresosPage> {
  bool _handledCreateRoute = false;
  bool _showProjection = false;
  _ProjectionOption _selectedProjection = incomeProjectionOptions[2];
  DateTimeRange? _selectedDateRange;
  final Set<String> _selectedIngresoIds = <String>{};

  Future<void> _pickDateRange(List<Ingreso> ingresos) async {
    if (ingresos.isEmpty) return;
    final orderedDates = ingresos.map((item) => item.fecha).toList()..sort();
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
    final ingresosAsync = ref.watch(ingresosControllerProvider);
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
          context.go(RoutePaths.ingresos);
        }
      });
    }

    return ingresosAsync.when(
      loading: () => ListView(
        children: [
          PageHeader(
            title: 'Ingresos',
            subtitle: '',
            actions: [
              ...buildImportExportHeaderActions(
                context,
                entityLabel: 'ingresos',
              ),
              ElevatedButton.icon(
                onPressed: () => _openForm(context),
                icon: Icon(Icons.add),
                label: Text(trText('Nuevo ingreso')),
              ),
            ],
          ),
          SizedBox(height: 12),
          LoadingStateWidget(message: 'Cargando ingresos...'),
        ],
      ),
      error: (_, __) => ListView(
        children: [
          PageHeader(
            title: 'Ingresos',
            subtitle: '',
            actions: [
              ...buildImportExportHeaderActions(
                context,
                entityLabel: 'ingresos',
              ),
              ElevatedButton.icon(
                onPressed: () => _openForm(context),
                icon: Icon(Icons.add),
                label: Text(trText('Nuevo ingreso')),
              ),
            ],
          ),
          SizedBox(height: 12),
          ErrorStateWidget(
            message: 'No se pudieron cargar ingresos.',
            onRetry: () => ref.invalidate(ingresosControllerProvider),
          ),
        ],
      ),
      data: (ingresos) {
        if (ingresos.isEmpty) {
          return ListView(
            children: [
              PageHeader(
                title: 'Ingresos',
                subtitle: '',
                actions: [
                  ...buildImportExportHeaderActions(
                    context,
                    entityLabel: 'ingresos',
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context),
                    icon: Icon(Icons.add),
                    label: Text(trText('Nuevo ingreso')),
                  ),
                ],
              ),
              SizedBox(height: 12),
              EmptyStateWidget(
                title: 'Todavía no hay ingresos',
                subtitle:
                    'Registra tu primer ingreso para comenzar a ver resultados.',
                action: ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: Icon(Icons.add),
                  label: Text(trText('Nuevo ingreso')),
                ),
              ),
            ],
          );
        }

        final clientesCatalogo =
            ref.watch(clientesControllerProvider).valueOrNull ??
            const <Cliente>[];
        final cotizacionesCatalogo =
            ref.watch(cotizacionesControllerProvider).valueOrNull ??
            const <Cotizacion>[];
        final gastosCatalogo =
            ref.watch(gastosControllerProvider).valueOrNull ?? const <Gasto>[];
        final productosCatalogo =
            ref.watch(productosControllerProvider).valueOrNull ??
            const <ProductoServicio>[];
        final detallesCatalogo =
            ref.watch(detalleCotizacionesControllerProvider).valueOrNull ??
            const <DetalleCotizacion>[];
        final clientes = {for (final item in clientesCatalogo) item.id: item};
        final cotizaciones = {
          for (final item in cotizacionesCatalogo) item.id: item,
        };
        final gastos = {for (final item in gastosCatalogo) item.id: item};
        final productos = {for (final item in productosCatalogo) item.id: item};
        final orderedDates = ingresos.map((item) => item.fecha).toList()
          ..sort();
        final lastDate = DateUtils.dateOnly(orderedDates.last);
        final firstDate = DateUtils.dateOnly(orderedDates.first);
        final defaultRange = DateTimeRange(
          start: lastDate.subtract(Duration(days: 49)).isBefore(firstDate)
              ? firstDate
              : lastDate.subtract(Duration(days: 49)),
          end: lastDate,
        );
        final activeRange = _selectedDateRange ?? defaultRange;
        final filteredIngresos = _filterIngresosByRange(ingresos, activeRange);
        final totalIngresos = filteredIngresos.fold<double>(
          0,
          (sum, item) => sum + item.monto,
        );
        final numeroVentas = filteredIngresos.length;
        final serie = _buildIncomeSeriesForRange(filteredIngresos, activeRange);
        final projectedSerie = _buildProjectedIncomeSeries(
          filteredIngresos,
          _selectedProjection,
        );
        final chartValues = _showProjection ? projectedSerie.values : serie.$1;
        final chartLabels = _showProjection ? projectedSerie.labels : serie.$2;
        final chartTotal = _showProjection
            ? projectedSerie.total
            : totalIngresos;
        final rango = _selectedDateRange == null
            ? trText('Ultimas 8 semanas')
            : _formatDateRange(activeRange);
        final baseLabel = _selectedDateRange == null
            ? trText('Base ultimas 8 semanas')
            : tr('Base $rango', 'Base $rango');
        final rankingClientes = _incomeByClient(ingresos, clientes);
        final rankingProductos = _incomeByProduct(
          detallesCatalogo,
          cotizaciones,
          productos,
        );

        return ListView(
          children: [
            PageHeader(
              title: 'Ingresos',
              subtitle: '',
              actions: [
                ...buildImportExportHeaderActions(
                  context,
                  entityLabel: 'ingresos',
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: Icon(Icons.add),
                  label: Text(trText('Nuevo ingreso')),
                ),
              ],
            ),
            SizedBox(height: 14),
            SectionCard(
              title: 'Ingresos totales',
              trailing: _RangeChip(label: _showProjection ? baseLabel : rango),
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
                          Text(
                            _showProjection
                                ? 'Proyeccion estimada con el comportamiento historico de cobro y la tendencia reciente.'
                                : 'Lectura historica de ingresos registrados en el periodo actual.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
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
                                accent: AppColors.primary,
                              ),
                              _ChartMetaItem(
                                icon: Icons.payments_outlined,
                                label: _showProjection
                                    ? 'Horizonte ${_selectedProjection.label}'
                                    : '$numeroVentas ingresos registrados',
                                accent: AppColors.primary,
                              ),
                            ],
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
                              options: incomeProjectionOptions,
                              accent: AppColors.primary,
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
                              onPickDateRange: () => _pickDateRange(ingresos),
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
                            options: incomeProjectionOptions,
                            accent: AppColors.primary,
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
                            onPickDateRange: () => _pickDateRange(ingresos),
                            onClearDateRange: () {
                              setState(() => _selectedDateRange = null);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 280,
                    child: LineChart(
                      _incomeChartData(
                        labels: chartLabels,
                        values: chartValues,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RankingIncomeTable(
                          title: 'Ranking de ingreso por cliente',
                          valueLabel: 'Ingreso',
                          rows: rankingClientes,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _RankingIncomeTable(
                          title: 'Ranking por producto',
                          valueLabel: 'Ingreso estimado',
                          rows: rankingProductos,
                          countLabel: 'Lineas',
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _RankingIncomeTable(
                      title: 'Ranking de ingreso por cliente',
                      valueLabel: 'Ingreso',
                      rows: rankingClientes,
                    ),
                    SizedBox(height: 12),
                    _RankingIncomeTable(
                      title: 'Ranking por producto',
                      valueLabel: 'Ingreso estimado',
                      rows: rankingProductos,
                      countLabel: 'Lineas',
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 12),
            FilterBar(
              children: [
                SizedBox(
                  width: 220,
                  child: SelectField<String>(
                    label: 'Cliente',
                    value: 'Todos',
                    options: ['Todos', 'Cliente 1'],
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: SelectField<String>(
                    label: 'Método',
                    value: 'Todos',
                    options: [
                      'Todos',
                      'Transferencia',
                      'Efectivo',
                      'Tarjeta',
                      'Depósito',
                    ],
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
            SizedBox(height: 12),
            Builder(
              builder: (context) {
                final allSelected =
                    _selectedIngresoIds.length == ingresos.length;
                final partiallySelected =
                    _selectedIngresoIds.isNotEmpty && !allSelected;

                return CotimaxDataTable(
                  toolbar: _selectedIngresoIds.isEmpty
                      ? null
                      : TableSelectionToolbar(
                          count: _selectedIngresoIds.length,
                          entityLabel: 'ingreso',
                          onEdit: _selectedIngresoIds.length == 1
                              ? () {
                                  final ingreso = ingresos.firstWhere(
                                    (item) =>
                                        item.id == _selectedIngresoIds.first,
                                  );
                                  _openForm(context, ingreso);
                                }
                              : null,
                          onDelete: _deleteSelectedIngresos,
                          onClear: () =>
                              setState(() => _selectedIngresoIds.clear()),
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
                              _selectedIngresoIds
                                ..clear()
                                ..addAll(ingresos.map((item) => item.id));
                            } else {
                              _selectedIngresoIds.clear();
                            }
                          });
                        },
                      ),
                    ),
                    DataColumn(label: Text(trText('Cliente'))),
                    DataColumn(label: Text(trText('Cotización'))),
                    DataColumn(label: Text(trText('Fuente de gasto'))),
                    DataColumn(label: Text(trText('Monto'))),
                    DataColumn(label: Text(trText('Metodo de pago'))),
                    DataColumn(label: Text(trText('Fecha'))),
                    DataColumn(label: Text(trText('Referencia'))),
                    DataColumn(label: Text(trText('Notas'))),
                    DataColumn(label: Text(trText('Acciones'))),
                  ],
                  rows: ingresos
                      .map(
                        (item) => DataRow(
                          selected: _selectedIngresoIds.contains(item.id),
                          cells: [
                            DataCell(
                              Checkbox(
                                value: _selectedIngresoIds.contains(item.id),
                                onChanged: (value) {
                                  setState(() {
                                    if (value ?? false) {
                                      _selectedIngresoIds.add(item.id);
                                    } else {
                                      _selectedIngresoIds.remove(item.id);
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
                                    clientes[item.clienteId]?.nombre ??
                                        item.clienteId,
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                item.cotizacionId.trim().isEmpty
                                    ? trText('Sin vincular')
                                    : (cotizaciones[item.cotizacionId]?.folio ??
                                          item.cotizacionId),
                              ),
                            ),
                            DataCell(
                              Text(
                                item.gastoFuenteId.trim().isEmpty
                                    ? trText('Sin vincular')
                                    : (item.gastoFuenteNombre.trim().isNotEmpty
                                          ? item.gastoFuenteNombre
                                          : _expenseSourceLabel(
                                              gastos[item.gastoFuenteId],
                                            )),
                              ),
                            ),
                            DataCell(
                              AmountBadge(amount: item.monto, positive: true),
                            ),
                            DataCell(
                              Text(_paymentMethodLabel(item.metodoPago)),
                            ),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy',
                                  currentIntlLocale(),
                                ).format(item.fecha),
                              ),
                            ),
                            DataCell(Text(item.referencia)),
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

  void _openForm(BuildContext context, [Ingreso? item]) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: item == null ? 'Nuevo ingreso' : 'Editar ingreso',
        child: _IngresoForm(item: item),
      ),
    );
  }

  Future<void> _onRowAction(
    BuildContext context, {
    required Ingreso item,
    required String action,
  }) async {
    if (action == 'edit') {
      _openForm(context, item);
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDeleteConfirmation(
        context,
        entityLabel: 'ingreso',
        dependencyEntityType: 'ingreso',
        dependencyIds: [item.id],
        onConfirmAsync: () async {
          try {
            await ref.read(ingresosRepositoryProvider).delete(item.id);
            if (!context.mounted) return;
            ref.invalidate(ingresosControllerProvider);
            ToastHelper.showSuccess(context, 'Ingreso eliminado.');
          } catch (error) {
            if (!context.mounted) rethrow;
            ToastHelper.showError(
              context,
              buildActionErrorMessage(error, 'No se pudo eliminar el ingreso.'),
            );
            rethrow;
          }
        },
      );
      if (!confirmed) return;
    }
  }

  Future<void> _deleteSelectedIngresos() async {
    final count = _selectedIngresoIds.length;
    if (count == 0) return;

    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: count == 1 ? 'ingreso' : 'ingresos seleccionados',
      title: count == 1 ? 'Eliminar ingreso' : 'Eliminar ingresos',
      message: count == 1
          ? '¿Estás seguro que quieres eliminar este ingreso?'
          : '¿Estás seguro que quieres eliminar los $count ingresos seleccionados?',
      dependencyEntityType: 'ingreso',
      dependencyIds: _selectedIngresoIds.toList(),
      onConfirmAsync: () async {
        try {
          final ids = _selectedIngresoIds.toList();
          for (final id in ids) {
            await ref.read(ingresosRepositoryProvider).delete(id);
          }
          if (!mounted) return;
          ref.invalidate(ingresosControllerProvider);
          setState(() => _selectedIngresoIds.clear());
          ToastHelper.showSuccess(
            context,
            count == 1
                ? 'Ingreso eliminado.'
                : '$count ingresos eliminados correctamente.',
          );
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(
              error,
              'No se pudieron eliminar los ingresos.',
            ),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }
}

class _IngresoForm extends ConsumerStatefulWidget {
  _IngresoForm({this.item});

  final Ingreso? item;

  @override
  ConsumerState<_IngresoForm> createState() => _IngresoFormState();
}

class _IngresoFormState extends ConsumerState<_IngresoForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _tituloController;
  late final TextEditingController _montoController;
  late final TextEditingController _fechaController;
  late final TextEditingController _fechaInicioRecurrenciaController;
  late final TextEditingController _referenciaController;
  late final TextEditingController _notasController;
  late final FocusNode _tituloFocusNode;
  late final FocusNode _clienteFocusNode;
  late final FocusNode _cotizacionFocusNode;
  late final FocusNode _gastoFuenteFocusNode;
  late final FocusNode _categoriaFocusNode;
  late final FocusNode _montoFocusNode;
  late final FocusNode _metodoPagoFocusNode;
  late final FocusNode _fechaFocusNode;
  late final FocusNode _referenciaFocusNode;
  late final FocusNode _notasFocusNode;
  PaymentMethod _metodoPago = PaymentMethod.transferencia;
  bool _recurrente = false;
  RecurrenceFrequency _recurrencia = RecurrenceFrequency.ninguna;
  final Set<int> _diasSemana = <int>{};
  String _iconKey = 'wallet';
  String _categoriaValue = '';
  String _categoriaDisplayLabel = '';
  String _clienteValue = '';
  String _cotizacionValue = '';
  String _gastoFuenteValue = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tituloFocusNode = FocusNode();
    _clienteFocusNode = FocusNode();
    _cotizacionFocusNode = FocusNode();
    _gastoFuenteFocusNode = FocusNode();
    _categoriaFocusNode = FocusNode();
    _montoFocusNode = FocusNode();
    _metodoPagoFocusNode = FocusNode();
    _fechaFocusNode = FocusNode();
    _referenciaFocusNode = FocusNode();
    _notasFocusNode = FocusNode();
    final item = widget.item;
    _categoriaValue = item?.ingresoCategoriaId ?? '';
    _clienteValue = item?.clienteId ?? '';
    _cotizacionValue = item?.cotizacionId ?? '';
    _gastoFuenteValue = item?.gastoFuenteId ?? '';
    _tituloController = seededTextController(item?.titulo ?? '');
    _montoController = seededTextController('0.00');
    if (item != null) {
      assignControllerText(
        _montoController,
        formatNumericValue(item.monto, decimalDigits: 2, useGrouping: true),
      );
    }
    _fechaController = seededTextController(
      DateFormat('yyyy-MM-dd').format(item?.fecha ?? DateTime.now()),
    );
    _fechaInicioRecurrenciaController = seededTextController(
      DateFormat(
        'yyyy-MM-dd',
      ).format(item?.fechaInicioRecurrencia ?? item?.fecha ?? DateTime.now()),
    );
    _referenciaController = seededTextController(item?.referencia);
    _notasController = seededTextController(item?.notas);
    _metodoPago = item?.metodoPago ?? PaymentMethod.transferencia;
    _recurrente = item?.recurrente ?? false;
    _recurrencia = item?.recurrencia ?? RecurrenceFrequency.ninguna;
    _diasSemana
      ..clear()
      ..addAll(item?.diasSemana ?? const <int>[]);
    _iconKey = item?.iconKey ?? 'wallet';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tituloController.dispose();
    _montoController.dispose();
    _fechaController.dispose();
    _fechaInicioRecurrenciaController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    _tituloFocusNode.dispose();
    _clienteFocusNode.dispose();
    _cotizacionFocusNode.dispose();
    _gastoFuenteFocusNode.dispose();
    _categoriaFocusNode.dispose();
    _montoFocusNode.dispose();
    _metodoPagoFocusNode.dispose();
    _fechaFocusNode.dispose();
    _referenciaFocusNode.dispose();
    _notasFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesCatalogo =
        ref.watch(clientesControllerProvider).valueOrNull ?? const <Cliente>[];
    final gastoCategoriasCatalogo =
        ref.watch(gastoCategoriasControllerProvider).valueOrNull ??
        const <GastoCategoria>[];
    final gastoCategoriasById = {
      for (final categoria in gastoCategoriasCatalogo) categoria.id: categoria,
    };
    final categoriasCatalogo =
        ref.watch(ingresoCategoriasControllerProvider).valueOrNull ??
        const <IngresoCategoria>[];
    final cotizacionesCatalogo =
        ref.watch(cotizacionesControllerProvider).valueOrNull ??
        const <Cotizacion>[];
    final gastosCatalogo =
        ref.watch(gastosControllerProvider).valueOrNull ?? const <Gasto>[];
    final categoriaOptions = categoriasCatalogo
        .map((item) => _LookupOption(value: item.id, label: item.nombre))
        .toList();
    final categoriaSelectOptions = _ensureSelectedLookupOption(
      options: categoriaOptions,
      currentValue: _categoriaValue,
      fallbackLabel: _categoriaDisplayLabel.isNotEmpty
          ? _categoriaDisplayLabel
          : _categoriaValue,
    );
    final clienteOptions = clientesCatalogo
        .map(
          (item) =>
              _LookupOption(value: item.id, label: _clientOptionLabel(item)),
        )
        .toList();
    final clienteSelectOptions = _ensureSelectedLookupOption(
      options: clienteOptions,
      currentValue: _clienteValue,
      fallbackLabel: _clienteValue,
    );
    final cotizacionOptions = cotizacionesCatalogo
        .map(
          (item) => _LookupOption(
            value: item.id,
            label: item.folio.trim().isEmpty ? item.id : item.folio,
          ),
        )
        .toList();
    final cotizacionSelectOptions = _ensureSelectedLookupOption(
      options: cotizacionOptions,
      currentValue: _cotizacionValue,
      fallbackLabel: _cotizacionValue,
    );
    final gastoOptions = gastosCatalogo
        .map(
          (item) => _LookupOption(
            value: item.id,
            label: _expenseLinkLabel(
              item,
              categoriasById: gastoCategoriasById,
            ),
          ),
        )
        .toList();
    final gastoSelectOptions = _ensureSelectedLookupOption(
      options: gastoOptions,
      currentValue: _gastoFuenteValue,
      fallbackLabel: _gastoFuenteValue,
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
                      title: 'Datos del ingreso',
                      titleIcon: FontAwesomeIcons.wallet,
                      headerBackgroundColor: AppColors.background,
                      child: Column(
                        children: [
                          FormFieldWrapper(
                            label: 'Icono del ingreso',
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
                                  hintText: trText('Título del ingreso'),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          _ResponsiveFormRow(
                            left: FocusTraversalOrder(
                              order: NumericFocusOrder(2),
                              child: FormFieldWrapper(
                                label: 'Cliente',
                                child: _LookupSelectField(
                                  focusNode: _clienteFocusNode,
                                  value: _clienteValue,
                                  options: clienteSelectOptions,
                                  emptyLabel: 'Sin cliente relacionado',
                                  hintText: 'Selecciona un cliente',
                                  emptyStateMessage:
                                      'No hay clientes registrados. Puedes continuar sin relacionar uno.',
                                  buttonLabel: 'Agregar cliente',
                                  onAddPressed: _goToCreateClient,
                                  onChanged: (value) =>
                                      setState(() => _clienteValue = value),
                                ),
                              ),
                            ),
                            right: FocusTraversalOrder(
                              order: NumericFocusOrder(3),
                              child: FormFieldWrapper(
                                label: 'Cotización',
                                child: _LookupSelectField(
                                  focusNode: _cotizacionFocusNode,
                                  value: _cotizacionValue,
                                  options: cotizacionSelectOptions,
                                  emptyLabel: 'Sin cotización relacionada',
                                  hintText: 'Selecciona una cotización',
                                  emptyStateMessage:
                                      'No hay cotizaciones registradas. Puedes continuar sin relacionar una.',
                                  buttonLabel: 'Agregar cotización',
                                  onAddPressed: _goToCreateQuote,
                                  onChanged: (value) =>
                                      setState(() => _cotizacionValue = value),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(4),
                            child: FormFieldWrapper(
                              label: 'Fuente de gasto',
                              child: _LookupSelectField(
                                focusNode: _gastoFuenteFocusNode,
                                value: _gastoFuenteValue,
                                options: gastoSelectOptions,
                                emptyLabel: 'Sin gasto relacionado',
                                hintText: 'Relaciona este ingreso con un gasto',
                                emptyStateMessage:
                                    'No hay gastos registrados para relacionar.',
                                buttonLabel: 'Agregar gasto',
                                onAddPressed: _goToCreateExpense,
                                onChanged: (value) =>
                                    setState(() => _gastoFuenteValue = value),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(5),
                            child: FormFieldWrapper(
                              label: 'Categoria',
                              child: _LookupSelectField(
                                focusNode: _categoriaFocusNode,
                                value: _categoriaValue,
                                options: categoriaSelectOptions,
                                emptyLabel: 'Sin categoria',
                                hintText: 'Selecciona una categoria',
                                emptyStateMessage:
                                    'No hay categorias de ingreso registradas.',
                                buttonLabel: 'Agregar categoria',
                                onAddPressed: _createIncomeCategory,
                                onChanged: (value) => setState(() {
                                  _categoriaValue = value;
                                  _categoriaDisplayLabel = '';
                                }),
                              ),
                            ),
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
                                      onPressed: _editIncomeCategory,
                                      icon: Icon(Icons.edit_rounded, size: 16),
                                      label: Text(trText('Editar categoria')),
                                    ),
                                  ),
                                  Focus(
                                    canRequestFocus: false,
                                    skipTraversal: true,
                                    child: TextButton.icon(
                                      onPressed: _deleteIncomeCategory,
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
                          SizedBox(height: 12),
                          _ResponsiveFormRow(
                            left: FocusTraversalOrder(
                              order: NumericFocusOrder(6),
                              child: CurrencyInput(
                                controller: _montoController,
                                label: 'Monto',
                                focusNode: _montoFocusNode,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            right: FocusTraversalOrder(
                              order: NumericFocusOrder(7),
                              child: FormFieldWrapper(
                                label: 'Metodo de pago',
                                child: DropdownButtonFormField<PaymentMethod>(
                                  focusNode: _metodoPagoFocusNode,
                                  initialValue: _metodoPago,
                                  isExpanded: true,
                                  menuMaxHeight: 320,
                                  borderRadius: cotimaxMenuBorderRadius,
                                  dropdownColor: AppColors.white,
                                  icon: cotimaxDropdownIcon,
                                  style: cotimaxDropdownTextStyle,
                                  decoration: cotimaxDropdownDecoration(),
                                  items: PaymentMethod.values
                                      .map(
                                        (method) => DropdownMenuItem(
                                          value: method,
                                          child: Text(
                                            trText(method.label),
                                            overflow: TextOverflow.ellipsis,
                                            style: cotimaxDropdownTextStyle,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _metodoPago = value);
                                  },
                                ),
                              ),
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
                              order: NumericFocusOrder(8),
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
                              order: NumericFocusOrder(9),
                              child: FormFieldWrapper(
                                label: 'Referencia',
                                child: TextField(
                                  focusNode: _referenciaFocusNode,
                                  controller: _referenciaController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: trText(
                                      'Folio o referencia bancaria',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          FocusTraversalOrder(
                            order: NumericFocusOrder(10),
                            child: FormFieldWrapper(
                              label: 'Notas',
                              child: TextField(
                                focusNode: _notasFocusNode,
                                controller: _notasController,
                                textInputAction: TextInputAction.next,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: trText('Comentarios adicionales'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    RecurrenceConfigurationCard(
                      title: 'Recurrencia del ingreso',
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
                    widget.item == null
                        ? 'Registrar ingreso'
                        : 'Guardar ingreso',
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
    final gastoById = {
      for (final item
          in (ref.read(gastosControllerProvider).valueOrNull ??
              const <Gasto>[]))
        item.id: item,
    };
    final categoriasCatalogo =
        ref.read(gastoCategoriasControllerProvider).valueOrNull ??
        const <GastoCategoria>[];
    final categoriasById = {
      for (final categoria in categoriasCatalogo) categoria.id: categoria,
    };
    final gastoLabel = _gastoFuenteValue.trim().isEmpty
        ? ''
        : _expenseLinkLabel(
            gastoById[_gastoFuenteValue.trim()],
            categoriasById: categoriasById,
          );
    final item = Ingreso(
      id: widget.item?.id ?? 'ing-${now.microsecondsSinceEpoch}',
      titulo: _tituloController.text.trim(),
      ingresoCategoriaId: _categoriaValue.trim(),
      clienteId: _clienteValue.trim(),
      cotizacionId: _cotizacionValue.trim(),
      monto: parseNumericText(_montoController.text) ?? 0,
      metodoPago: _metodoPago,
      fecha: movementDate,
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
      fechaInicioRecurrencia: _recurrente ? recurrenceStartDate : null,
      iconKey: _iconKey,
      gastoFuenteId: _gastoFuenteValue.trim(),
      gastoFuenteNombre: gastoLabel,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(ingresosRepositoryProvider).upsert(item);
      ref.invalidate(ingresosControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.item == null
            ? 'Ingreso registrado correctamente.'
            : 'Ingreso actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo guardar el ingreso.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

  List<_LookupOption> _ensureSelectedLookupOption({
    required List<_LookupOption> options,
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
      _LookupOption(value: normalizedValue, label: fallbackLabel),
      ...options,
    ];
  }

  String _clientOptionLabel(Cliente cliente) {
    final nombre = cliente.nombre.trim();
    final empresa = cliente.empresa.trim();
    if (nombre.isNotEmpty &&
        empresa.isNotEmpty &&
        nombre.toLowerCase() != empresa.toLowerCase()) {
      return '$nombre · $empresa';
    }
    if (nombre.isNotEmpty) return nombre;
    if (empresa.isNotEmpty) return empresa;
    return cliente.id;
  }

  void _goToCreateClient() {
    Navigator.of(context).pop();
    context.go('${RoutePaths.clientes}?create=1');
  }

  void _goToCreateExpense() {
    Navigator.of(context).pop();
    context.go('${RoutePaths.gastos}?create=1');
  }

  Future<void> _createIncomeCategory() async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(trText('Nueva categoria de ingreso')),
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
                    hintText: trText('Ej. Ventas de servicios'),
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
          .read(ingresosRepositoryProvider)
          .createCategoria(nombre: nombre, descripcion: descripcion);
      ref.invalidate(ingresoCategoriasControllerProvider);
      if (!mounted) return;
      setState(() {
        _categoriaValue = categoriaId;
        _categoriaDisplayLabel = nombre;
      });
      ToastHelper.showSuccess(context, 'Categoria de ingreso creada.');
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudo crear la categoria de ingreso.',
        ),
      );
    }
  }

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  Future<void> _editIncomeCategory() async {
    final categoriaId = _categoriaValue.trim();
    if (!_looksLikeUuid(categoriaId)) {
      ToastHelper.showWarning(
        context,
        'Esta categoria no se puede editar porque no tiene ID valido.',
      );
      return;
    }

    final categorias =
        ref.read(ingresoCategoriasControllerProvider).valueOrNull ??
        const <IngresoCategoria>[];
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
          title: Text(trText('Editar categoria de ingreso')),
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
          .read(ingresosRepositoryProvider)
          .updateCategoria(
            id: categoriaId,
            nombre: nombre,
            descripcion: descripcion,
          );
      ref.invalidate(ingresoCategoriasControllerProvider);
      if (!mounted) return;
      setState(() => _categoriaDisplayLabel = nombre);
      ToastHelper.showSuccess(context, 'Categoria de ingreso actualizada.');
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudo actualizar la categoria de ingreso.',
        ),
      );
    }
  }

  Future<void> _deleteIncomeCategory() async {
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
          trText('¿Seguro que quieres eliminar esta categoria de ingreso?'),
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
      await ref.read(ingresosRepositoryProvider).deleteCategoria(categoriaId);
      ref.invalidate(ingresoCategoriasControllerProvider);
      if (!mounted) return;
      setState(() {
        _categoriaValue = '';
        _categoriaDisplayLabel = '';
      });
      ToastHelper.showSuccess(context, 'Categoria de ingreso eliminada.');
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudo eliminar la categoria de ingreso.',
        ),
      );
    }
  }

  void _goToCreateQuote() {
    Navigator.of(context).pop();
    context.go('${RoutePaths.cotizaciones}?create=1');
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

class _LookupOption {
  _LookupOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _LookupSelectField extends StatelessWidget {
  _LookupSelectField({
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
  final List<_LookupOption> options;
  final String emptyLabel;
  final String hintText;
  final String emptyStateMessage;
  final String buttonLabel;
  final VoidCallback onAddPressed;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return _LookupEmptyState(
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

class _LookupEmptyState extends StatelessWidget {
  _LookupEmptyState({
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

class _RangeChip extends StatelessWidget {
  _RangeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
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

const incomeProjectionOptions = <_ProjectionOption>[
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

class _RankingIncomeTable extends StatelessWidget {
  _RankingIncomeTable({
    required this.title,
    required this.valueLabel,
    required this.rows,
    this.countLabel = 'Movs',
  });

  final String title;
  final String valueLabel;
  final List<_RankingItem> rows;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return CotimaxDataTable(
      title: title,
      columns: [
        DataColumn(label: Text(trText('Nombre'))),
        DataColumn(label: Text(trText(countLabel))),
        DataColumn(label: Text(trText(valueLabel))),
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

class _RankingItem {
  _RankingItem({required this.name, required this.amount, required this.count});

  final String name;
  final double amount;
  final int count;
}

LineChartData _incomeChartData({
  required List<String> labels,
  required List<double> values,
  required Color color,
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
        color: color,
        barWidth: 3,
        dotData: FlDotData(
          show: singleValue,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4.5,
            color: color,
            strokeWidth: 2,
            strokeColor: AppColors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: !singleValue,
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
                formatMxn(spot.y),
                TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
              ),
            )
            .toList(),
      ),
    ),
  );
}

(List<double>, List<String>) _buildIncomeSeriesForRange(
  List<Ingreso> ingresos,
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
        ingresos
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
        ingresos
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
      ingresos
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

_ProjectedChartData _buildProjectedIncomeSeries(
  List<Ingreso> ingresos,
  _ProjectionOption option,
) {
  return option.isWeekly
      ? _buildProjectedIncomeWeeks(ingresos, option.periodCount)
      : _buildProjectedIncomeMonths(ingresos, option.periodCount);
}

_ProjectedChartData _buildProjectedIncomeWeeks(
  List<Ingreso> ingresos,
  int horizon,
) {
  final actual = _buildHistoricalIncomeWeeks(ingresos, weeks: 8);
  final source = [...actual.values];
  final trend = _growthTrend(source);
  final labels = <String>[];
  final values = <double>[];
  var currentWeek = _startOfWeek(DateTime.now());

  for (var index = 0; index < horizon; index++) {
    currentWeek = currentWeek.add(Duration(days: 7));
    final projected = math
        .max(0, _weightedAverage(source) * (1 + (trend * 0.18)))
        .toDouble();
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

_ProjectedChartData _buildProjectedIncomeMonths(
  List<Ingreso> ingresos,
  int horizon,
) {
  final actual = _buildHistoricalIncomeMonths(ingresos, months: 6);
  final source = [...actual.values];
  final trend = _growthTrend(source);
  final labels = <String>[];
  final values = <double>[];
  var currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  for (var index = 0; index < horizon; index++) {
    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    final projected = math
        .max(0, _weightedAverage(source) * (1 + (trend * 0.35)))
        .toDouble();
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

_ProjectedChartData _buildHistoricalIncomeWeeks(
  List<Ingreso> ingresos, {
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
      ingresos
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

_ProjectedChartData _buildHistoricalIncomeMonths(
  List<Ingreso> ingresos, {
  required int months,
}) {
  if (ingresos.isEmpty) {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    return _ProjectedChartData(
      labels: [DateFormat('MMM yy', currentIntlLocale()).format(currentMonth)],
      values: const [0],
      total: 0,
    );
  }

  final monthTotals = <DateTime, double>{};
  for (final item in ingresos) {
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

List<Ingreso> _filterIngresosByRange(
  List<Ingreso> ingresos,
  DateTimeRange? range,
) {
  if (range == null) return ingresos;
  final start = DateUtils.dateOnly(range.start);
  final end = DateUtils.dateOnly(
    range.end,
  ).add(Duration(hours: 23, minutes: 59, seconds: 59));
  return ingresos
      .where((item) => !item.fecha.isBefore(start) && !item.fecha.isAfter(end))
      .toList();
}

String _formatDateRange(DateTimeRange range) {
  final formatter = DateFormat('dd MMM yyyy', currentIntlLocale());
  return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
}

List<_RankingItem> _incomeByClient(
  List<Ingreso> ingresos,
  Map<String, Cliente> clientes,
) {
  final map = <String, _MutableRanking>{};
  for (final item in ingresos) {
    final ranking = map.putIfAbsent(
      item.clienteId,
      () => _MutableRanking(
        name: clientes[item.clienteId]?.nombre ?? item.clienteId,
      ),
    );
    ranking.amount += item.monto;
    ranking.count += 1;
  }
  return map.values
      .map(
        (item) => _RankingItem(
          name: item.name,
          amount: item.amount,
          count: item.count,
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

List<_RankingItem> _incomeByProduct(
  List<DetalleCotizacion> detalles,
  Map<String, Cotizacion> cotizaciones,
  Map<String, ProductoServicio> productos,
) {
  final map = <String, _MutableRanking>{};
  for (final item in detalles) {
    final quote = cotizaciones[item.cotizacionId];
    if (quote == null) continue;
    final key = item.productoServicioId;
    final ranking = map.putIfAbsent(
      key,
      () => _MutableRanking(name: productos[key]?.nombre ?? item.concepto),
    );
    ranking.amount += item.importe;
    ranking.count += 1;
  }
  return map.values
      .map(
        (item) => _RankingItem(
          name: item.name,
          amount: item.amount,
          count: item.count,
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

String _paymentMethodLabel(PaymentMethod method) {
  return method.label;
}

String _expenseSourceLabel(Gasto? gasto) {
  if (gasto == null) return '';
  final titulo = gasto.titulo.trim();
  final desc = gasto.descripcion.trim();
  final provider = gasto.proveedor.trim();
  final focus = titulo.isNotEmpty
      ? titulo
      : (desc.isNotEmpty
            ? desc
            : (provider.isNotEmpty ? provider : trText('Gasto')));
  final date = DateFormat(
    'dd/MM/yyyy',
    currentIntlLocale(),
  ).format(gasto.fecha);
  return '$focus · $date · ${formatMxn(gasto.monto)}';
}

bool _looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$',
  ).hasMatch(value.trim());
}

String _expenseLinkLabel(
  Gasto? gasto, {
  required Map<String, GastoCategoria> categoriasById,
}) {
  if (gasto == null) return '';
  final titulo = gasto.titulo.trim();
  final desc = gasto.descripcion.trim();
  final provider = gasto.proveedor.trim();
  final focus = titulo.isNotEmpty
      ? titulo
      : (desc.isNotEmpty
            ? desc
            : (provider.isNotEmpty ? provider : trText('Gasto')));
  final rawCategoria = gasto.gastoCategoriaId.trim();
  final resolvedCategoria = categoriasById[rawCategoria]?.nombre ??
      (rawCategoria.isNotEmpty && !_looksLikeUuid(rawCategoria)
          ? rawCategoria
          : '');
  final amount = formatMxn(gasto.monto);
  if (resolvedCategoria.isEmpty) return '$focus · $amount';
  return '$focus · $amount · $resolvedCategoria';
}

class _MutableRanking {
  _MutableRanking({required this.name});

  final String name;
  double amount = 0;
  int count = 0;
}
