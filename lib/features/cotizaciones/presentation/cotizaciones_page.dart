import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/cotizaciones/application/cotizacion_pdf_service.dart';
import 'package:cotimax/features/cotizaciones/application/cotizaciones_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/models/upsert_payloads.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

class CotizacionesPage extends ConsumerStatefulWidget {
  const CotizacionesPage({super.key});

  @override
  ConsumerState<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends ConsumerState<CotizacionesPage> {
  bool _handledCreateRoute = false;
  late final TextEditingController _searchController;
  String _appliedRouteQuery = '';
  _QuoteViewMode _viewMode = _QuoteViewMode.table;
  final Set<String> _updatingQuoteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cotizaciones = ref.watch(cotizacionesControllerProvider);
    final uri = GoRouterState.of(context).uri;
    final shouldCreate = uri.queryParameters['create'] == '1';
    final routeQuery = uri.queryParameters['q']?.trim() ?? '';
    _syncRouteQuery(routeQuery);

    if (!shouldCreate) {
      _handledCreateRoute = false;
    } else if (!_handledCreateRoute) {
      _handledCreateRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openQuoteForm(context);
        if (mounted) {
          context.go(RoutePaths.cotizaciones);
        }
      });
    }

    return ListView(
      children: [
        PageHeader(
          title: 'Cotizaciones',
          subtitle: '',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _openQuoteForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva cotización'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilterBar(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: 240,
                child: SearchField(
                  controller: _searchController,
                  hint: 'Buscar por folio',
                  onChanged: (value) =>
                      ref.read(cotizacionesSearchProvider.notifier).state =
                          value,
                ),
              ),
            ),
            const SizedBox(
              width: 180,
              child: SelectField<String>(
                label: 'Cliente',
                value: 'Todos',
                options: ['Todos', 'Cliente 1', 'Cliente 2'],
              ),
            ),
            const SizedBox(
              width: 180,
              child: SelectField<String>(
                label: 'Estatus',
                value: 'Todos',
                options: [
                  'Todos',
                  'Borrador',
                  'Enviada',
                  'Aprobada',
                  'Rechazada',
                ],
              ),
            ),
            const SizedBox(
              width: 180,
              child: SelectField<String>(
                label: 'Usuario',
                value: 'Todos',
                options: ['Todos', 'Admin'],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _QuoteViewToggle(
                mode: _viewMode,
                onChanged: (mode) {
                  setState(() => _viewMode = mode);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        cotizaciones.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No se pudieron cargar cotizaciones.',
            onRetry: () => ref.invalidate(cotizacionesControllerProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const SectionCard(child: InlineEmptyMessage());
            }

            if (_viewMode == _QuoteViewMode.kanban) {
              return _QuotesKanbanBoard(
                items: items,
                updatingQuoteIds: _updatingQuoteIds,
                onMoveQuote: (quote, status) =>
                    _updateQuoteStatus(context, ref, quote, status),
                onOpenActions: (quote, action) =>
                    _onRowAction(context, ref, quote: quote, action: action),
              );
            }

            return CotimaxDataTable(
              columns: const [
                DataColumn(label: Text('Folio')),
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Emisión')),
                DataColumn(label: Text('Vencimiento')),
                DataColumn(label: Text('Subtotal')),
                DataColumn(label: Text('Impuesto')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Estatus')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: items
                  .map(
                    (quote) => DataRow(
                      cells: [
                        DataCell(Text(quote.folio)),
                        DataCell(Text(quote.clienteId)),
                        DataCell(
                          Text(
                            '${quote.fechaEmision.day}/${quote.fechaEmision.month}/${quote.fechaEmision.year}',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${quote.fechaVencimiento.day}/${quote.fechaVencimiento.month}/${quote.fechaVencimiento.year}',
                          ),
                        ),
                        DataCell(
                          Text('\$${quote.subtotal.toStringAsFixed(2)}'),
                        ),
                        DataCell(
                          Text('\$${quote.impuestoTotal.toStringAsFixed(2)}'),
                        ),
                        DataCell(Text('\$${quote.total.toStringAsFixed(2)}')),
                        DataCell(StatusBadge(status: quote.estatus)),
                        DataCell(
                          RowActionMenu(
                            onSelected: (action) => _onRowAction(
                              context,
                              ref,
                              quote: quote,
                              action: action,
                            ),
                            actions: const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'preview',
                                child: Text('Previsualizar'),
                              ),
                              PopupMenuItem(
                                value: 'pdf',
                                child: Text('Descargar PDF'),
                              ),
                              PopupMenuItem(
                                value: 'approved',
                                child: Text('Marcar aprobada'),
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
            );
          },
        ),
      ],
    );
  }

  void _openQuoteForm(BuildContext context, [Cotizacion? quote]) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: quote == null ? 'Nueva cotización' : 'Editar cotización',
        child: _QuoteForm(quote: quote),
      ),
    );
  }

  void _syncRouteQuery(String routeQuery) {
    if (_appliedRouteQuery == routeQuery) return;
    _appliedRouteQuery = routeQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchController.value = TextEditingValue(
        text: routeQuery,
        selection: TextSelection.collapsed(offset: routeQuery.length),
      );
      ref.read(cotizacionesSearchProvider.notifier).state = routeQuery;
    });
  }

  Future<void> _onRowAction(
    BuildContext context,
    WidgetRef ref, {
    required Cotizacion quote,
    required String action,
  }) async {
    if (action == 'edit') {
      _openQuoteForm(context, quote);
      return;
    }

    if (action == 'preview') {
      await _openPdfPreview(context, quote);
      return;
    }

    if (action == 'pdf') {
      final bytes = await CotizacionPdfService.generate(quote);
      await Printing.sharePdf(bytes: bytes, filename: '${quote.folio}.pdf');
      if (context.mounted) {
        ToastHelper.show(context, 'PDF generado para ${quote.folio}.');
      }
      return;
    }

    if (action == 'approved') {
      await _updateQuoteStatus(context, ref, quote, QuoteStatus.aprobada);
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDeleteConfirmation(
        context,
        entityLabel: 'cotización',
      );
      if (!confirmed) return;

      try {
        await ref.read(cotizacionesRepositoryProvider).delete(quote.id);
        ref.invalidate(cotizacionesControllerProvider);
        if (!context.mounted) return;
        ToastHelper.showSuccess(context, 'Cotización eliminada.');
      } catch (_) {
        if (!context.mounted) return;
        ToastHelper.showError(context, 'No se pudo eliminar la cotización.');
      }
    }
  }

  Future<void> _updateQuoteStatus(
    BuildContext context,
    WidgetRef ref,
    Cotizacion quote,
    QuoteStatus status,
  ) async {
    if (quote.estatus == status || _updatingQuoteIds.contains(quote.id)) return;
    setState(() => _updatingQuoteIds.add(quote.id));
    try {
      await ref
          .read(cotizacionesRepositoryProvider)
          .updateStatus(quote.id, status);
      ref.invalidate(cotizacionesControllerProvider);
      if (context.mounted) {
        ToastHelper.show(
          context,
          'Cotización ${quote.folio} movida a ${_quoteStatusLabel(status)}.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingQuoteIds.remove(quote.id));
      }
    }
  }

  Future<void> _openPdfPreview(BuildContext context, Cotizacion quote) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 1000,
            height: 760,
            child: PdfPreview(
              build: (_) => CotizacionPdfService.generate(quote),
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowSharing: true,
              allowPrinting: true,
              pdfFileName: '${quote.folio}.pdf',
            ),
          ),
        );
      },
    );
  }
}

enum _QuoteViewMode { table, kanban }

class _QuoteViewToggle extends StatelessWidget {
  const _QuoteViewToggle({required this.mode, required this.onChanged});

  final _QuoteViewMode mode;
  final ValueChanged<_QuoteViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuoteViewButton(
            label: 'Tabla',
            icon: Icons.table_rows_rounded,
            active: mode == _QuoteViewMode.table,
            onPressed: () => onChanged(_QuoteViewMode.table),
          ),
          _QuoteViewButton(
            label: 'Vista kanban',
            icon: Icons.view_week_rounded,
            active: mode == _QuoteViewMode.kanban,
            onPressed: () => onChanged(_QuoteViewMode.kanban),
          ),
        ],
      ),
    );
  }
}

class _QuoteViewButton extends StatelessWidget {
  const _QuoteViewButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.white : AppColors.textPrimary;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: active ? AppColors.textPrimary : Colors.transparent,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _QuotesKanbanBoard extends StatelessWidget {
  const _QuotesKanbanBoard({
    required this.items,
    required this.updatingQuoteIds,
    required this.onMoveQuote,
    required this.onOpenActions,
  });

  final List<Cotizacion> items;
  final Set<String> updatingQuoteIds;
  final Future<void> Function(Cotizacion quote, QuoteStatus status) onMoveQuote;
  final Future<void> Function(Cotizacion quote, String action) onOpenActions;

  @override
  Widget build(BuildContext context) {
    final columns = quoteKanbanStatuses
        .map(
          (status) => _QuoteKanbanColumn(
            status: status,
            items: items.where((item) => item.estatus == status).toList(),
            updatingQuoteIds: updatingQuoteIds,
            onAcceptQuote: (quote) => onMoveQuote(quote, status),
            onOpenActions: onOpenActions,
          ),
        )
        .toList();

    return SizedBox(
      height: 720,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < columns.length; index++) ...[
              SizedBox(width: 312, child: columns[index]),
              if (index != columns.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuoteKanbanColumn extends StatelessWidget {
  const _QuoteKanbanColumn({
    required this.status,
    required this.items,
    required this.updatingQuoteIds,
    required this.onAcceptQuote,
    required this.onOpenActions,
  });

  final QuoteStatus status;
  final List<Cotizacion> items;
  final Set<String> updatingQuoteIds;
  final ValueChanged<Cotizacion> onAcceptQuote;
  final Future<void> Function(Cotizacion quote, String action) onOpenActions;

  @override
  Widget build(BuildContext context) {
    final color = _quoteStatusColor(status);
    return DragTarget<Cotizacion>(
      onWillAcceptWithDetails: (details) => details.data.estatus != status,
      onAcceptWithDetails: (details) => onAcceptQuote(details.data),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: highlighted
                ? color.withValues(alpha: 0.08)
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted
                  ? color.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _quoteStatusLabel(status),
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Arrastra aqui las cotizaciones ${_quoteStatusLabel(status).toLowerCase()}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final quote = items[index];
                          return _QuoteKanbanCard(
                            quote: quote,
                            isUpdating: updatingQuoteIds.contains(quote.id),
                            onOpenActions: (action) =>
                                onOpenActions(quote, action),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuoteKanbanCard extends StatelessWidget {
  const _QuoteKanbanCard({
    required this.quote,
    required this.isUpdating,
    required this.onOpenActions,
  });

  final Cotizacion quote;
  final bool isUpdating;
  final ValueChanged<String> onOpenActions;

  @override
  Widget build(BuildContext context) {
    final color = _quoteStatusColor(quote.estatus);
    final card = Opacity(
      opacity: isUpdating ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D101828),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
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
                        quote.folio,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quote.clienteId,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                RowActionMenu(
                  onSelected: onOpenActions,
                  actions: const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'preview',
                      child: Text('Previsualizar'),
                    ),
                    PopupMenuItem(value: 'pdf', child: Text('Descargar PDF')),
                    PopupMenuItem(
                      value: 'approved',
                      child: Text('Marcar aprobada'),
                    ),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatusBadge(status: quote.estatus),
            const SizedBox(height: 14),
            _QuoteKanbanMetaRow(
              label: 'Total',
              value: '\$${quote.total.toStringAsFixed(2)}',
              valueColor: color,
            ),
            const SizedBox(height: 8),
            _QuoteKanbanMetaRow(
              label: 'Emision',
              value:
                  '${quote.fechaEmision.day}/${quote.fechaEmision.month}/${quote.fechaEmision.year}',
            ),
            const SizedBox(height: 6),
            _QuoteKanbanMetaRow(
              label: 'Vencimiento',
              value:
                  '${quote.fechaVencimiento.day}/${quote.fechaVencimiento.month}/${quote.fechaVencimiento.year}',
            ),
          ],
        ),
      ),
    );

    return Draggable<Cotizacion>(
      data: quote,
      feedback: SizedBox(
        width: 280,
        child: Material(color: Colors.transparent, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _QuoteKanbanMetaRow extends StatelessWidget {
  const _QuoteKanbanMetaRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

const quoteKanbanStatuses = <QuoteStatus>[
  QuoteStatus.borrador,
  QuoteStatus.enviada,
  QuoteStatus.aprobada,
  QuoteStatus.rechazada,
];

String _quoteStatusLabel(QuoteStatus status) {
  switch (status) {
    case QuoteStatus.borrador:
      return 'Borrador';
    case QuoteStatus.enviada:
      return 'Enviada';
    case QuoteStatus.aprobada:
      return 'Aprobada';
    case QuoteStatus.rechazada:
      return 'Rechazada';
  }
}

Color _quoteStatusColor(QuoteStatus status) {
  switch (status) {
    case QuoteStatus.borrador:
      return AppColors.textMuted;
    case QuoteStatus.enviada:
      return AppColors.primary;
    case QuoteStatus.aprobada:
      return AppColors.success;
    case QuoteStatus.rechazada:
      return AppColors.error;
  }
}

class _QuoteForm extends ConsumerStatefulWidget {
  const _QuoteForm({this.quote});

  final Cotizacion? quote;

  @override
  ConsumerState<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends ConsumerState<_QuoteForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _clienteController;
  late final TextEditingController _fechaController;
  late final TextEditingController _validaHastaController;
  late final TextEditingController _depositoController;
  late final TextEditingController _folioController;
  late final TextEditingController _ordenController;
  late final TextEditingController _descuentoTipoController;
  late final TextEditingController _descuentoValorController;
  late final TextEditingController _notasController;
  late final TextEditingController _notasPrivadasController;
  late final TextEditingController _terminosController;
  late final TextEditingController _piePaginaController;
  late final TextEditingController _impuestoResumenController;
  late List<_QuoteLineDraft> _lineas;
  bool _retIsr = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final quote = widget.quote;
    _clienteController = seededTextController(quote?.clienteId);
    _fechaController = seededTextController(
      quote == null
          ? '04/01/2026'
          : '${quote.fechaEmision.day.toString().padLeft(2, '0')}/${quote.fechaEmision.month.toString().padLeft(2, '0')}/${quote.fechaEmision.year}',
    );
    _validaHastaController = seededTextController(
      quote == null
          ? '04/01/2026'
          : '${quote.fechaVencimiento.day.toString().padLeft(2, '0')}/${quote.fechaVencimiento.month.toString().padLeft(2, '0')}/${quote.fechaVencimiento.year}',
    );
    _depositoController = seededTextController();
    _folioController = seededTextController(
      quote?.folio ?? 'Generar automaticamente',
    );
    _ordenController = seededTextController();
    _descuentoTipoController = seededTextController('Cantidad');
    _descuentoValorController = seededTextController(
      quote == null
          ? ''
          : formatNumericValue(
              quote.descuentoTotal,
              decimalDigits: 2,
              useGrouping: true,
            ),
    );
    _notasController = seededTextController(quote?.notas);
    _notasPrivadasController = seededTextController(quote?.notasPrivadas ?? '');
    _terminosController = seededTextController(quote?.terminos);
    _piePaginaController = seededTextController(quote?.piePagina);
    _impuestoResumenController = seededTextController(
      quote?.impuestoPorcentaje.toStringAsFixed(0) ?? '16',
    );
    _retIsr = quote?.retIsr ?? false;
    _lineas = [
      _QuoteLineDraft(
        concepto: '',
        descripcion: '',
        costoUnitario: '',
        cantidad: '1',
        impuesto: '16',
        total: '',
      ),
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _clienteController.dispose();
    _fechaController.dispose();
    _validaHastaController.dispose();
    _depositoController.dispose();
    _folioController.dispose();
    _ordenController.dispose();
    _descuentoTipoController.dispose();
    _descuentoValorController.dispose();
    _notasController.dispose();
    _notasPrivadasController.dispose();
    _terminosController.dispose();
    _piePaginaController.dispose();
    _impuestoResumenController.dispose();
    for (final item in _lineas) {
      item.dispose();
    }
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1040;
                      final blocks = [
                        _QuoteSection(
                          title: 'Cliente',
                          icon: FontAwesomeIcons.userGroup,
                          child: _QuoteSimpleField(
                            controller: _clienteController,
                            dropdown: true,
                          ),
                        ),
                        _QuoteSection(
                          title: 'Fechas y anticipo',
                          icon: FontAwesomeIcons.calendarDays,
                          child: Column(
                            children: [
                              _QuoteFieldRow(
                                label: 'Fecha cotización',
                                controller: _fechaController,
                              ),
                              _QuoteFieldRow(
                                label: 'Válida hasta',
                                controller: _validaHastaController,
                              ),
                              _QuoteFieldRow(
                                label: 'Parcial/Depósito',
                                controller: _depositoController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: const [
                                  NumericTextInputFormatter(
                                    useGrouping: true,
                                    maxDecimalDigits: 2,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _QuoteSection(
                          title: 'Control comercial',
                          icon: FontAwesomeIcons.clipboardList,
                          child: Column(
                            children: [
                              _QuoteFieldRow(
                                label: 'Cotización #',
                                controller: _folioController,
                              ),
                              _QuoteFieldRow(
                                label: 'Orden #',
                                controller: _ordenController,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QuoteFieldRow(
                                      label: 'Descuento',
                                      controller: _descuentoTipoController,
                                      dropdown: true,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _QuoteSimpleField(
                                      controller: _descuentoValorController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: const [
                                        NumericTextInputFormatter(
                                          useGrouping: true,
                                          maxDecimalDigits: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ];

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: blocks[0]),
                            const SizedBox(width: 10),
                            Expanded(child: blocks[1]),
                            const SizedBox(width: 10),
                            Expanded(child: blocks[2]),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          blocks[0],
                          const SizedBox(height: 10),
                          blocks[1],
                          const SizedBox(height: 10),
                          blocks[2],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _QuoteSection(
                    title: 'Productos',
                    icon: FontAwesomeIcons.boxOpen,
                    trailing: TextButton.icon(
                      onPressed: _agregarLinea,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Añadir artículo'),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text('Concepto')),
                              Expanded(flex: 3, child: Text('Descripción')),
                              Expanded(flex: 2, child: Text('Coste unitario')),
                              Expanded(flex: 2, child: Text('Cantidad')),
                              Expanded(
                                flex: 2,
                                child: Text('Tasa de impuesto 1'),
                              ),
                              Expanded(flex: 2, child: Text('Total')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          _lineas.length,
                          (index) => _QuoteLineRow(
                            key: ValueKey('linea_$index'),
                            draft: _lineas[index],
                            onRemove: _lineas.length == 1
                                ? null
                                : () => _removerLinea(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;
                      final notes = _QuoteSection(
                        title: 'Notas y textos',
                        icon: FontAwesomeIcons.noteSticky,
                        child: Column(
                          children: [
                            _QuoteFieldRow(
                              label: 'Notas',
                              controller: _notasController,
                              maxLines: 4,
                            ),
                            _QuoteFieldRow(
                              label: 'Notas privadas',
                              controller: _notasPrivadasController,
                              maxLines: 4,
                            ),
                            _QuoteFieldRow(
                              label: 'Términos',
                              controller: _terminosController,
                              maxLines: 4,
                            ),
                            _QuoteFieldRow(
                              label: 'Pie de página',
                              controller: _piePaginaController,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      );

                      final summary = _QuoteSection(
                        title: 'Resumen',
                        icon: FontAwesomeIcons.chartPie,
                        child: Column(
                          children: [
                            _QuoteSummaryRow(
                              label: 'Net',
                              value:
                                  '\$${widget.quote?.subtotal.toStringAsFixed(2) ?? '0.00'}',
                            ),
                            _QuoteSummaryRow(
                              label: 'Subtotal',
                              value:
                                  '\$${widget.quote?.subtotal.toStringAsFixed(2) ?? '0.00'}',
                            ),
                            _QuoteSummaryRow(
                              label: 'Total',
                              value:
                                  '\$${widget.quote?.total.toStringAsFixed(2) ?? '0.00'}',
                              strong: true,
                            ),
                            _QuoteSummaryRow(label: 'Pagado', value: '\$0.00'),
                            _QuoteSummaryRow(label: 'Saldo', value: '\$0.00'),
                            const SizedBox(height: 10),
                            _QuoteFieldRow(
                              label: 'Impuesto',
                              controller: _impuestoResumenController,
                              dropdown: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: const [
                                NumericTextInputFormatter(maxDecimalDigits: 2),
                              ],
                            ),
                            _QuoteSwitchRow(
                              label: 'RET ISR',
                              value: _retIsr,
                              onChanged: (value) =>
                                  setState(() => _retIsr = value),
                            ),
                          ],
                        ),
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: notes),
                            const SizedBox(width: 10),
                            Expanded(child: summary),
                          ],
                        );
                      }

                      return Column(
                        children: [notes, const SizedBox(height: 10), summary],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _save(QuoteStatus.borrador),
                icon: Icon(
                  widget.quote == null ? Icons.add_rounded : Icons.save_rounded,
                ),
                label: Text(
                  widget.quote == null ? 'Crear borrador' : 'Guardar borrador',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _save(QuoteStatus.enviada),
                icon: Icon(
                  widget.quote == null ? Icons.add_rounded : Icons.save_rounded,
                ),
                label: Text(
                  widget.quote == null
                      ? 'Crear cotización'
                      : 'Guardar cotización',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _agregarLinea() {
    setState(() {
      _lineas = [
        ..._lineas,
        _QuoteLineDraft(
          concepto: '',
          descripcion: '',
          costoUnitario: '',
          cantidad: '1',
          impuesto: '16',
          total: '',
        ),
      ];
    });
  }

  void _removerLinea(int index) {
    final item = _lineas[index];
    setState(() {
      _lineas = [..._lineas]..removeAt(index);
    });
    item.dispose();
  }

  Future<void> _save(QuoteStatus status) async {
    final fechaEmision = _parseDate(_fechaController.text) ?? DateTime.now();
    final fechaVencimiento =
        _parseDate(_validaHastaController.text) ?? fechaEmision;
    final payload = CotizacionUpsertPayload(
      id: widget.quote?.id,
      clienteId: _clienteController.text.trim(),
      fechaEmision: fechaEmision,
      fechaVencimiento: fechaVencimiento,
      depositoParcial: parseNumericText(_depositoController.text) ?? 0,
      folio: _folioController.text.trim() == 'Generar automáticamente'
          ? ''
          : _folioController.text.trim(),
      ordenNumero: _ordenController.text.trim(),
      descuentoTipo: _descuentoTipoController.text.trim(),
      descuentoValor: parseNumericText(_descuentoValorController.text) ?? 0,
      impuestoPorcentaje:
          parseNumericText(_impuestoResumenController.text) ?? 0,
      retIsr: _retIsr,
      notas: _notasController.text.trim(),
      notasPrivadas: _notasPrivadasController.text.trim(),
      terminos: _terminosController.text.trim(),
      piePagina: _piePaginaController.text.trim(),
      estatus: status,
      lineas: List.generate(_lineas.length, (index) {
        final item = _lineas[index];
        final precio = parseNumericText(item.costoUnitarioController.text) ?? 0;
        final cantidad = parseNumericText(item.cantidadController.text) ?? 0;
        final total =
            parseNumericText(item.totalController.text) ?? (precio * cantidad);
        return CotizacionLineaInput(
          productoServicioId: null,
          concepto: item.conceptoController.text.trim(),
          descripcion: item.descripcionController.text.trim(),
          precioUnitario: precio,
          unidad: 'unidad',
          descuento: 0,
          cantidad: cantidad,
          impuestoPorcentaje:
              parseNumericText(item.impuestoController.text) ?? 0,
          importe: total,
          orden: index,
        );
      }),
    );

    try {
      await ref.read(cotizacionesRepositoryProvider).upsert(payload);
      ref.invalidate(cotizacionesControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        status == QuoteStatus.borrador
            ? 'Cotización guardada como borrador.'
            : 'Cotización guardada correctamente.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo guardar la cotización.');
    }
  }

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final slash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final dash = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final slashMatch = slash.firstMatch(value);
    if (slashMatch != null) {
      return DateTime(
        int.parse(slashMatch.group(3)!),
        int.parse(slashMatch.group(2)!),
        int.parse(slashMatch.group(1)!),
      );
    }
    final dashMatch = dash.firstMatch(value);
    if (dashMatch != null) {
      return DateTime(
        int.parse(dashMatch.group(1)!),
        int.parse(dashMatch.group(2)!),
        int.parse(dashMatch.group(3)!),
      );
    }
    return DateTime.tryParse(value);
  }
}

class _QuoteSection extends StatelessWidget {
  const _QuoteSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      FaIcon(icon, size: 14, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _QuoteFieldRow extends StatelessWidget {
  const _QuoteFieldRow({
    required this.label,
    required this.controller,
    this.dropdown = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final bool dropdown;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                suffixIcon: dropdown
                    ? const Icon(Icons.keyboard_arrow_down)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteSimpleField extends StatelessWidget {
  const _QuoteSimpleField({
    required this.controller,
    this.dropdown = false,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final bool dropdown;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        suffixIcon: dropdown ? const Icon(Icons.keyboard_arrow_down) : null,
      ),
    );
  }
}

class _QuoteLineRow extends StatelessWidget {
  const _QuoteLineRow({required super.key, required this.draft, this.onRemove});

  final _QuoteLineDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(controller: draft.conceptoController),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(controller: draft.descripcionController),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.costoUnitarioController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [
                NumericTextInputFormatter(
                  useGrouping: true,
                  maxDecimalDigits: 2,
                ),
              ],
              decoration: const InputDecoration(suffixText: 'MXN'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.cantidadController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [
                NumericTextInputFormatter(maxDecimalDigits: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.impuestoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [
                NumericTextInputFormatter(maxDecimalDigits: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: draft.totalController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [
                NumericTextInputFormatter(
                  useGrouping: true,
                  maxDecimalDigits: 2,
                ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              splashRadius: 18,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteSummaryRow extends StatelessWidget {
  const _QuoteSummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteSwitchRow extends StatelessWidget {
  const _QuoteSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _QuoteLineDraft {
  _QuoteLineDraft({
    required String concepto,
    required String descripcion,
    required String costoUnitario,
    required String cantidad,
    required String impuesto,
    required String total,
  }) : conceptoController = seededTextController(concepto),
       descripcionController = seededTextController(descripcion),
       costoUnitarioController = seededTextController(costoUnitario),
       cantidadController = seededTextController(cantidad),
       impuestoController = seededTextController(impuesto),
       totalController = seededTextController(total);

  final TextEditingController conceptoController;
  final TextEditingController descripcionController;
  final TextEditingController costoUnitarioController;
  final TextEditingController cantidadController;
  final TextEditingController impuestoController;
  final TextEditingController totalController;

  void dispose() {
    conceptoController.dispose();
    descripcionController.dispose();
    costoUnitarioController.dispose();
    cantidadController.dispose();
    impuestoController.dispose();
    totalController.dispose();
  }
}
