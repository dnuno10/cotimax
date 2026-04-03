import 'dart:math' as math;

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/clientes/application/clientes_controller.dart';
import 'package:cotimax/features/cotizaciones/application/cotizaciones_controller.dart';
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
  const IngresosPage({super.key});

  @override
  ConsumerState<IngresosPage> createState() => _IngresosPageState();
}

class _IngresosPageState extends ConsumerState<IngresosPage> {
  bool _handledCreateRoute = false;
  bool _showProjection = false;
  _ProjectionOption _selectedProjection = incomeProjectionOptions[2];
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange(List<Ingreso> ingresos) async {
    if (ingresos.isEmpty) return;
    final orderedDates = ingresos.map((item) => item.fecha).toList()..sort();
    final firstDate = DateUtils.dateOnly(orderedDates.first);
    final lastDate = DateUtils.dateOnly(orderedDates.last);
    final defaultStart = DateUtils.dateOnly(
      lastDate.subtract(const Duration(days: 49)),
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
      helpText: 'Selecciona el rango',
      saveText: 'Aplicar',
      locale: const Locale('es', 'MX'),
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
        children: const [
          PageHeader(title: 'Ingresos', subtitle: ''),
          SizedBox(height: 12),
          LoadingSkeleton(),
        ],
      ),
      error: (_, __) => ListView(
        children: [
          const PageHeader(title: 'Ingresos', subtitle: ''),
          const SizedBox(height: 12),
          ErrorStateWidget(
            message: 'No se pudieron cargar ingresos.',
            onRetry: () => ref.invalidate(ingresosControllerProvider),
          ),
        ],
      ),
      data: (ingresos) {
        if (ingresos.isEmpty) {
          return ListView(
            children: const [
              PageHeader(title: 'Ingresos', subtitle: ''),
              SizedBox(height: 12),
              SectionCard(child: InlineEmptyMessage()),
            ],
          );
        }

        final clientesCatalogo =
            ref.watch(clientesControllerProvider).valueOrNull ??
            const <Cliente>[];
        final cotizacionesCatalogo =
            ref.watch(cotizacionesControllerProvider).valueOrNull ??
            const <Cotizacion>[];
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
        final productos = {for (final item in productosCatalogo) item.id: item};
        final orderedDates = ingresos.map((item) => item.fecha).toList()
          ..sort();
        final lastDate = DateUtils.dateOnly(orderedDates.last);
        final firstDate = DateUtils.dateOnly(orderedDates.first);
        final defaultRange = DateTimeRange(
          start: lastDate.subtract(const Duration(days: 49)).isBefore(firstDate)
              ? firstDate
              : lastDate.subtract(const Duration(days: 49)),
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
            ? 'Ultimas 8 semanas'
            : _formatDateRange(activeRange);
        final baseLabel = _selectedDateRange == null
            ? 'Base ultimas 8 semanas'
            : 'Base $rango';
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
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo ingreso'),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                                ? 'Escenario proyectado'
                                : 'Historico real',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatMxn(chartTotal),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 30,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showProjection
                                ? 'Proyeccion estimada con el comportamiento historico de cobro y la tendencia reciente.'
                                : 'Lectura historica de ingresos registrados en el periodo actual.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                            const SizedBox(height: 16),
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
                          const SizedBox(width: 18),
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
                  const SizedBox(height: 20),
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
            const SizedBox(height: 12),
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
                      const SizedBox(width: 12),
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
                    const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            const FilterBar(
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
            const SizedBox(height: 12),
            CotimaxDataTable(
              columns: const [
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Cotización')),
                DataColumn(label: Text('Monto')),
                DataColumn(label: Text('Metodo de pago')),
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Referencia')),
                DataColumn(label: Text('Notas')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: ingresos
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FinanceIconAvatar(
                                iconKey: item.iconKey,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                clientes[item.clienteId]?.nombre ??
                                    item.clienteId,
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            cotizaciones[item.cotizacionId]?.folio ??
                                item.cotizacionId,
                          ),
                        ),
                        DataCell(
                          AmountBadge(amount: item.monto, positive: true),
                        ),
                        DataCell(Text(_paymentMethodLabel(item.metodoPago))),
                        DataCell(
                          Text(DateFormat('dd/MM/yyyy').format(item.fecha)),
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
                            actions: const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
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
      );
      if (!confirmed) return;

      try {
        await ref.read(ingresosRepositoryProvider).delete(item.id);
        if (!context.mounted) return;
        ref.invalidate(ingresosControllerProvider);
        ToastHelper.showSuccess(context, 'Ingreso eliminado.');
      } catch (_) {
        if (!context.mounted) return;
        ToastHelper.showError(context, 'No se pudo eliminar el ingreso.');
      }
    }
  }
}

class _IngresoForm extends ConsumerStatefulWidget {
  const _IngresoForm({this.item});

  final Ingreso? item;

  @override
  ConsumerState<_IngresoForm> createState() => _IngresoFormState();
}

class _IngresoFormState extends ConsumerState<_IngresoForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _clienteController;
  late final TextEditingController _cotizacionController;
  late final TextEditingController _montoController;
  late final TextEditingController _fechaController;
  late final TextEditingController _referenciaController;
  late final TextEditingController _notasController;
  PaymentMethod _metodoPago = PaymentMethod.transferencia;
  bool _recurrente = false;
  RecurrenceFrequency _recurrencia = RecurrenceFrequency.ninguna;
  final Set<int> _diasSemana = <int>{};
  String _iconKey = 'wallet';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final item = widget.item;
    _clienteController = seededTextController(item?.clienteId);
    _cotizacionController = seededTextController(item?.cotizacionId ?? '');
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
    _clienteController.dispose();
    _cotizacionController.dispose();
    _montoController.dispose();
    _fechaController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    child: Column(
                      children: [
                        FormFieldWrapper(
                          label: 'Icono del ingreso',
                          child: FinanceIconPicker(
                            selectedKey: _iconKey,
                            onChanged: (value) =>
                                setState(() => _iconKey = value),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ResponsiveFormRow(
                          left: FormFieldWrapper(
                            label: 'Cliente',
                            child: TextField(
                              controller: _clienteController,
                              decoration: const InputDecoration(
                                hintText: 'Cliente relacionado',
                              ),
                            ),
                          ),
                          right: FormFieldWrapper(
                            label: 'Cotización',
                            child: TextField(
                              controller: _cotizacionController,
                              decoration: const InputDecoration(
                                hintText: 'Folio o ID de cotización',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ResponsiveFormRow(
                          left: CurrencyInput(
                            controller: _montoController,
                            label: 'Monto',
                          ),
                          right: FormFieldWrapper(
                            label: 'Metodo de pago',
                            child: DropdownButtonFormField<PaymentMethod>(
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
                                        method.label,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Seguimiento',
                    titleIcon: FontAwesomeIcons.calendarCheck,
                    child: Column(
                      children: [
                        _ResponsiveFormRow(
                          left: FormFieldWrapper(
                            label: 'Fecha',
                            child: TextField(
                              controller: _fechaController,
                              decoration: const InputDecoration(
                                hintText: 'AAAA-MM-DD',
                              ),
                            ),
                          ),
                          right: FormFieldWrapper(
                            label: 'Referencia',
                            child: TextField(
                              controller: _referenciaController,
                              decoration: const InputDecoration(
                                hintText: 'Folio o referencia bancaria',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FormFieldWrapper(
                          label: 'Notas',
                          child: TextField(
                            controller: _notasController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Comentarios adicionales',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RecurrenceConfigurationCard(
                    title: 'Recurrencia del ingreso',
                    titleIcon: FontAwesomeIcons.arrowsRotate,
                    isRecurring: _recurrente,
                    frequency: _recurrencia,
                    selectedWeekdays: _diasSemana,
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
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(
                  widget.item == null ? Icons.add_rounded : Icons.save_rounded,
                ),
                label: Text(
                  widget.item == null ? 'Registrar ingreso' : 'Guardar ingreso',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final item = Ingreso(
      id: widget.item?.id ?? 'ing-${now.microsecondsSinceEpoch}',
      clienteId: _clienteController.text.trim(),
      cotizacionId: _cotizacionController.text.trim(),
      monto: parseNumericText(_montoController.text) ?? 0,
      metodoPago: _metodoPago,
      fecha: DateTime.tryParse(_fechaController.text.trim()) ?? now,
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
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo guardar el ingreso.');
    }
  }
}

class _ResponsiveFormRow extends StatelessWidget {
  const _ResponsiveFormRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }

        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ChartMetaItem extends StatelessWidget {
  const _ChartMetaItem({
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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
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
  const _ProjectionToolbar({
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
            offset: const Offset(0, 8),
            onSelected: onOptionSelected,
            itemBuilder: (context) => options
                .map(
                  (option) => PopupMenuItem<_ProjectionOption>(
                    value: option,
                    child: Text(option.label),
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
  const _DateRangeButton({
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
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProjectionModeButton extends StatelessWidget {
  const _ProjectionModeButton({
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
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: active ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectionResetButton extends StatelessWidget {
  const _ProjectionResetButton({
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
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProjectionOptionButton extends StatelessWidget {
  const _ProjectionOptionButton({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
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
  const _ProjectedChartData({
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
  const _RankingIncomeTable({
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
        const DataColumn(label: Text('Nombre')),
        DataColumn(label: Text(countLabel)),
        DataColumn(label: Text(valueLabel)),
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
                        const SizedBox(width: 8),
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
  const _RankingItem({
    required this.name,
    required this.amount,
    required this.count,
  });

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
      labels.add(DateFormat('dd MMM').format(currentDay));
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
      final weekEnd = weekStart.add(const Duration(days: 6));
      labels.add(DateFormat('dd MMM').format(weekStart));
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
    labels.add(DateFormat('MMM yy').format(currentMonth));
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
    currentWeek = currentWeek.add(const Duration(days: 7));
    final projected = math
        .max(0, _weightedAverage(source) * (1 + (trend * 0.18)))
        .toDouble();
    source.add(projected);
    labels.add(DateFormat('dd MMM').format(currentWeek));
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
    labels.add(DateFormat('MMM yy').format(currentMonth));
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
    final weekEnd = weekStart.add(const Duration(days: 6));
    labels.add(DateFormat('dd MMM').format(weekStart));
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
  final now = DateTime.now();
  final labels = <String>[];
  final values = <double>[];

  for (var index = 0; index < months; index++) {
    final monthKey = DateTime(now.year, now.month - (months - 1 - index));
    labels.add(DateFormat('MMM yy').format(monthKey));
    values.add(
      ingresos
          .where((item) => _sameMonth(item.fecha, monthKey))
          .fold<double>(0, (sum, item) => sum + item.monto),
    );
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
  ).add(const Duration(hours: 23, minutes: 59, seconds: 59));
  return ingresos
      .where((item) => !item.fecha.isBefore(start) && !item.fecha.isAfter(end))
      .toList();
}

String _formatDateRange(DateTimeRange range) {
  final formatter = DateFormat('dd MMM yyyy');
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

class _MutableRanking {
  _MutableRanking({required this.name});

  final String name;
  double amount = 0;
  int count = 0;
}
