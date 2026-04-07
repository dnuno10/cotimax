import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/features/clientes/application/clientes_controller.dart';
import 'package:cotimax/features/cotizaciones/application/cotizacion_pdf_service.dart';
import 'package:cotimax/features/cotizaciones/application/cotizaciones_controller.dart';
import 'package:cotimax/features/productos/application/productos_controller.dart';
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
  final Set<String> _selectedQuoteIds = <String>{};

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
    final clientesCatalogo =
        ref.watch(clientesControllerProvider).valueOrNull ?? const <Cliente>[];
    final clientesById = {
      for (final cliente in clientesCatalogo)
        cliente.id: _clientDisplayName(cliente),
    };
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
              label: Text(trText('Nueva cotización')),
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
          loading: () =>
              const LoadingStateWidget(message: 'Cargando cotizaciones...'),
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
                clientesById: clientesById,
                updatingQuoteIds: _updatingQuoteIds,
                onMoveQuote: (quote, status) =>
                    _updateQuoteStatus(context, ref, quote, status),
                onOpenActions: (quote, action) =>
                    _onRowAction(context, ref, quote: quote, action: action),
              );
            }

            final allSelected = _selectedQuoteIds.length == items.length;
            final partiallySelected =
                _selectedQuoteIds.isNotEmpty && !allSelected;

            return CotimaxDataTable(
              toolbar: _selectedQuoteIds.isEmpty
                  ? null
                  : TableSelectionToolbar(
                      count: _selectedQuoteIds.length,
                      entityLabel: 'cotización',
                      pluralLabel: 'cotizaciones',
                      onEdit: _selectedQuoteIds.length == 1
                          ? () {
                              final quote = items.firstWhere(
                                (item) => item.id == _selectedQuoteIds.first,
                              );
                              _openQuoteForm(context, quote);
                            }
                          : null,
                      onDelete: _deleteSelectedCotizaciones,
                      onClear: () => setState(() => _selectedQuoteIds.clear()),
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
                          _selectedQuoteIds
                            ..clear()
                            ..addAll(items.map((item) => item.id));
                        } else {
                          _selectedQuoteIds.clear();
                        }
                      });
                    },
                  ),
                ),
                DataColumn(label: Text(trText('Folio'))),
                DataColumn(label: Text(trText('Cliente'))),
                DataColumn(label: Text(trText('Emisión'))),
                DataColumn(label: Text(trText('Vencimiento'))),
                DataColumn(label: Text(trText('Subtotal'))),
                DataColumn(label: Text(trText('Impuesto'))),
                DataColumn(label: Text(trText('Total'))),
                DataColumn(label: Text(trText('Estatus'))),
                DataColumn(label: Text(trText('Acciones'))),
              ],
              rows: items
                  .map(
                    (quote) => DataRow(
                      selected: _selectedQuoteIds.contains(quote.id),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: _selectedQuoteIds.contains(quote.id),
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selectedQuoteIds.add(quote.id);
                                } else {
                                  _selectedQuoteIds.remove(quote.id);
                                }
                              });
                            },
                          ),
                        ),
                        DataCell(Text(quote.folio)),
                        DataCell(Text(_quoteClientLabel(quote, clientesById))),
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
                        DataCell(Text(formatMoney(quote.subtotal))),
                        DataCell(Text(formatMoney(quote.impuestoTotal))),
                        DataCell(Text(formatMoney(quote.total))),
                        DataCell(StatusBadge(status: quote.estatus)),
                        DataCell(
                          RowActionMenu(
                            onSelected: (action) => _onRowAction(
                              context,
                              ref,
                              quote: quote,
                              action: action,
                            ),
                            actions: [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(trText('Editar')),
                              ),
                              PopupMenuItem(
                                value: 'preview',
                                child: Text(trText('Previsualizar')),
                              ),
                              PopupMenuItem(
                                value: 'pdf',
                                child: Text(trText('Descargar PDF')),
                              ),
                              PopupMenuItem(
                                value: 'approved',
                                child: Text(trText('Marcar aprobada')),
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
  }

  void _openQuoteForm(BuildContext context, [Cotizacion? quote]) {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (_) => ModalBase(
        title: quote == null ? 'Nueva cotización' : 'Editar cotización',
        showCloseButton: true,
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
        onConfirmAsync: () async {
          try {
            await ref.read(cotizacionesRepositoryProvider).delete(quote.id);
            ref.invalidate(cotizacionesControllerProvider);
            if (!context.mounted) return;
            ToastHelper.showSuccess(context, 'Cotización eliminada.');
          } catch (_) {
            if (!context.mounted) rethrow;
            ToastHelper.showError(
              context,
              'No se pudo eliminar la cotización.',
            );
            rethrow;
          }
        },
      );
      if (!confirmed) return;
    }
  }

  Future<void> _deleteSelectedCotizaciones() async {
    final count = _selectedQuoteIds.length;
    if (count == 0) return;

    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: count == 1 ? 'cotización' : 'cotizaciones seleccionadas',
      title: count == 1 ? 'Eliminar cotización' : 'Eliminar cotizaciones',
      message: count == 1
          ? '¿Estás seguro que quieres eliminar esta cotización?'
          : '¿Estás seguro que quieres eliminar las $count cotizaciones seleccionadas?',
      onConfirmAsync: () async {
        try {
          final ids = _selectedQuoteIds.toList();
          for (final id in ids) {
            await ref.read(cotizacionesRepositoryProvider).delete(id);
          }
          ref.invalidate(cotizacionesControllerProvider);
          if (!mounted) return;
          setState(() => _selectedQuoteIds.clear());
          ToastHelper.showSuccess(
            context,
            count == 1
                ? 'Cotización eliminada.'
                : '$count cotizaciones eliminadas correctamente.',
          );
        } catch (_) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            'No se pudieron eliminar las cotizaciones.',
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
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
    required this.clientesById,
    required this.updatingQuoteIds,
    required this.onMoveQuote,
    required this.onOpenActions,
  });

  final List<Cotizacion> items;
  final Map<String, String> clientesById;
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
            clientesById: clientesById,
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
    required this.clientesById,
    required this.updatingQuoteIds,
    required this.onAcceptQuote,
    required this.onOpenActions,
  });

  final QuoteStatus status;
  final List<Cotizacion> items;
  final Map<String, String> clientesById;
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
                            clientLabel: _quoteClientLabel(quote, clientesById),
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
    required this.clientLabel,
    required this.isUpdating,
    required this.onOpenActions,
  });

  final Cotizacion quote;
  final String clientLabel;
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
                        clientLabel,
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

String _clientDisplayName(Cliente cliente) {
  final nombre = cliente.nombre.trim();
  if (nombre.isNotEmpty) return nombre;
  final empresa = cliente.empresa.trim();
  if (empresa.isNotEmpty) return empresa;
  return cliente.id;
}

String _quoteClientLabel(Cotizacion quote, Map<String, String> clientesById) {
  return clientesById[quote.clienteId] ?? quote.clienteId;
}

const List<String> _quoteDiscountTypeOptions = ['Cantidad', 'Porcentaje'];
const double _quoteConceptWidth = 220;
const double _quoteDescriptionWidth = 280;
const double _quotePriceWidth = 170;
const double _quoteUnitWidth = 130;
const double _quoteQuantityWidth = 130;
const double _quoteTaxWidth = 150;
const double _quoteTotalWidth = 170;

double _extractTaxPercent(String raw, {double fallback = 16}) {
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
  if (match == null) return fallback;
  return double.tryParse(match.group(1)!) ?? fallback;
}

String _nextQuoteFolioSuggestion(Iterable<String> folios) {
  var maxValue = 0;
  var width = 4;
  for (final folio in folios) {
    final matches = RegExp(r'(\d+)').allMatches(folio);
    for (final match in matches) {
      final raw = match.group(1)!;
      final parsed = int.tryParse(raw);
      if (parsed == null) continue;
      if (parsed > maxValue) {
        maxValue = parsed;
        width = raw.length;
      }
    }
  }
  final next = maxValue + 1;
  return 'COT-${next.toString().padLeft(width, '0')}';
}

class _QuoteProductOption {
  const _QuoteProductOption({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioBase,
    required this.cantidadPredeterminada,
    required this.impuestoPorcentaje,
    required this.unidad,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final double precioBase;
  final double cantidadPredeterminada;
  final double impuestoPorcentaje;
  final String unidad;
}

class _QuoteForm extends ConsumerStatefulWidget {
  const _QuoteForm({this.quote});

  final Cotizacion? quote;

  @override
  ConsumerState<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends ConsumerState<_QuoteForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _fechaController;
  late final TextEditingController _validaHastaController;
  late final TextEditingController _depositoController;
  late final TextEditingController _folioController;
  late final TextEditingController _ordenController;
  late final TextEditingController _descuentoValorController;
  late final TextEditingController _notasController;
  late final TextEditingController _notasPrivadasController;
  late final TextEditingController _terminosController;
  late final TextEditingController _piePaginaController;
  late List<_QuoteLineDraft> _lineas;
  String? _selectedClientId;
  String _discountType = _quoteDiscountTypeOptions.first;
  bool _retIsr = false;
  bool _loadingExistingQuote = false;
  bool _loadingProductOptions = false;
  String? _productCatalogError;
  List<_QuoteProductOption> _productOptions = const [];
  String _currentSuggestedFolio = 'COT-0001';
  String _lastAutoGeneratedFolio = '';
  QuoteStatus? _savingStatus;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final quote = widget.quote;
    final now = DateTime.now();
    _fechaController = seededTextController(
      quote == null
          ? _formatDate(now)
          : '${quote.fechaEmision.day.toString().padLeft(2, '0')}/${quote.fechaEmision.month.toString().padLeft(2, '0')}/${quote.fechaEmision.year}',
    );
    _validaHastaController = seededTextController(
      quote == null
          ? _formatDate(now.add(const Duration(days: 7)))
          : '${quote.fechaVencimiento.day.toString().padLeft(2, '0')}/${quote.fechaVencimiento.month.toString().padLeft(2, '0')}/${quote.fechaVencimiento.year}',
    );
    _depositoController = seededTextController();
    _folioController = seededTextController(quote?.folio ?? '');
    _ordenController = seededTextController();
    _descuentoValorController = seededTextController('');
    _notasController = seededTextController(quote?.notas);
    _notasPrivadasController = seededTextController(quote?.notasPrivadas ?? '');
    _terminosController = seededTextController(quote?.terminos);
    _piePaginaController = seededTextController(quote?.piePagina);
    _retIsr = quote?.retIsr ?? false;
    _selectedClientId = quote?.clienteId.isNotEmpty == true
        ? quote!.clienteId
        : null;
    _lineas = [_buildLineDraft()];
    _attachGlobalListeners();
    _loadProductOptions();
    if (quote != null) {
      _loadExistingQuoteConfiguration(quote.id);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fechaController.dispose();
    _validaHastaController.dispose();
    _depositoController.dispose();
    _folioController.dispose();
    _ordenController.dispose();
    _descuentoValorController.dispose();
    _notasController.dispose();
    _notasPrivadasController.dispose();
    _terminosController.dispose();
    _piePaginaController.dispose();
    for (final item in _lineas) {
      item.dispose();
    }
    super.dispose();
  }

  void _attachGlobalListeners() {
    for (final controller in [
      _depositoController,
      _descuentoValorController,
      _folioController,
      _ordenController,
      _notasController,
      _notasPrivadasController,
      _terminosController,
      _piePaginaController,
    ]) {
      controller.addListener(_triggerRebuild);
    }
  }

  void _triggerRebuild() {
    if (!mounted) return;
    setState(() {});
  }

  _QuoteLineDraft _buildLineDraft({
    String? productoServicioId,
    String concepto = '',
    String descripcion = '',
    String costoUnitario = '',
    String cantidad = '1',
    String impuesto = '16',
    String total = '',
    String unidad = '',
  }) {
    final draft = _QuoteLineDraft(
      productoServicioId: productoServicioId,
      concepto: concepto,
      descripcion: descripcion,
      costoUnitario: costoUnitario,
      cantidad: cantidad,
      impuesto: impuesto,
      total: total,
      unidad: unidad,
    );
    _attachLineListeners(draft);
    _recalculateLine(draft, notify: false);
    return draft;
  }

  void _attachLineListeners(_QuoteLineDraft draft) {
    void listener() {
      if (draft.syncing) return;
      _recalculateLine(draft);
    }

    draft.costoUnitarioController.addListener(listener);
    draft.cantidadController.addListener(listener);
    draft.impuestoController.addListener(listener);
    draft.conceptoController.addListener(_triggerRebuild);
    draft.descripcionController.addListener(_triggerRebuild);
    draft.unidadController.addListener(_triggerRebuild);
  }

  void _recalculateLine(_QuoteLineDraft draft, {bool notify = true}) {
    final subtotal = _lineSubtotal(draft);
    final shouldShow = subtotal > 0 || _hasMeaningfulLineData(draft);
    draft.syncing = true;
    assignControllerText(
      draft.totalController,
      shouldShow
          ? formatNumericValue(subtotal, decimalDigits: 2, useGrouping: true)
          : '',
    );
    draft.syncing = false;
    if (notify && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProductOptions() async {
    setState(() {
      _loadingProductOptions = true;
      _productCatalogError = null;
    });

    try {
      final products = await ref.read(productosRepositoryProvider).getAll();
      final client = ref.read(supabaseClientProvider);
      final rows = await client
          .from('productos_servicios')
          .select(
            'id,cantidad_predeterminada,tasa_impuesto_nombre,unidad_medida',
          )
          .eq('activo', true);
      final rowsById = {
        for (final row in (rows as List).cast<Map<String, dynamic>>())
          row['id'].toString(): row,
      };
      final options =
          products.where((item) => item.activo).map((item) {
            final raw = rowsById[item.id];
            return _QuoteProductOption(
              id: item.id,
              nombre: item.nombre,
              descripcion: item.descripcion,
              precioBase: item.precioBase,
              cantidadPredeterminada: _doubleFromValue(
                raw?['cantidad_predeterminada'],
                fallback: 1,
              ),
              impuestoPorcentaje: _extractTaxPercent(
                raw?['tasa_impuesto_nombre']?.toString() ?? '',
              ),
              unidad: (raw?['unidad_medida']?.toString() ?? item.unidad).trim(),
            );
          }).toList()..sort(
            (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          );

      if (!mounted) return;
      setState(() => _productOptions = options);
    } catch (error) {
      if (!mounted) return;
      setState(() => _productCatalogError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingProductOptions = false);
      }
    }
  }

  Future<void> _loadExistingQuoteConfiguration(String quoteId) async {
    setState(() => _loadingExistingQuote = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final quoteRow = await client
          .from('cotizaciones')
          .select(
            'cliente_id,fecha_emision,fecha_vencimiento,deposito_parcial,'
            'folio,orden_numero,descuento_tipo,descuento_valor,subtotal,'
            'ret_isr,notas,notas_privadas,terminos,pie_pagina',
          )
          .eq('id', quoteId)
          .maybeSingle();
      final detalles = await ref
          .read(cotizacionesRepositoryProvider)
          .getDetalles(cotizacionId: quoteId);
      if (!mounted) return;

      final previousLines = _lineas;
      final drafts = detalles.isEmpty
          ? [_buildLineDraft()]
          : detalles
                .map(
                  (item) => _buildLineDraft(
                    productoServicioId: item.productoServicioId.isEmpty
                        ? null
                        : item.productoServicioId,
                    concepto: item.concepto,
                    descripcion: item.descripcion,
                    costoUnitario: formatNumericValue(
                      item.precioUnitario,
                      decimalDigits: 2,
                      useGrouping: true,
                    ),
                    cantidad: formatNumericValue(
                      item.cantidad,
                      decimalDigits:
                          item.cantidad == item.cantidad.roundToDouble()
                          ? 0
                          : 2,
                      useGrouping: false,
                    ),
                    impuesto: _formatEditableNumber(item.impuestoPorcentaje),
                    total: formatNumericValue(
                      item.importe,
                      decimalDigits: 2,
                      useGrouping: true,
                    ),
                    unidad: item.unidad,
                  ),
                )
                .toList();

      if (quoteRow != null) {
        final subtotal = _doubleFromValue(quoteRow['subtotal']);
        final discountType =
            ((quoteRow['descuento_tipo'] ?? 'Cantidad') as String).trim();
        final storedDiscount = _doubleFromValue(quoteRow['descuento_valor']);
        final shownDiscount = discountType == 'Porcentaje' && subtotal > 0
            ? (storedDiscount / subtotal) * 100
            : storedDiscount;

        _selectedClientId = quoteRow['cliente_id']?.toString();
        assignControllerText(
          _fechaController,
          _formatDate(DateTime.parse(quoteRow['fecha_emision'].toString())),
        );
        assignControllerText(
          _validaHastaController,
          _formatDate(DateTime.parse(quoteRow['fecha_vencimiento'].toString())),
        );
        assignControllerText(
          _depositoController,
          _formatEditableNumber(_doubleFromValue(quoteRow['deposito_parcial'])),
        );
        assignControllerText(
          _folioController,
          (quoteRow['folio'] ?? '') as String,
        );
        assignControllerText(
          _ordenController,
          (quoteRow['orden_numero'] ?? '') as String,
        );
        _discountType = _quoteDiscountTypeOptions.contains(discountType)
            ? discountType
            : _quoteDiscountTypeOptions.first;
        assignControllerText(
          _descuentoValorController,
          shownDiscount > 0 ? _formatEditableNumber(shownDiscount) : '',
        );
        _retIsr = quoteRow['ret_isr'] == true;
        assignControllerText(
          _notasController,
          (quoteRow['notas'] ?? '') as String,
        );
        assignControllerText(
          _notasPrivadasController,
          (quoteRow['notas_privadas'] ?? '') as String,
        );
        assignControllerText(
          _terminosController,
          (quoteRow['terminos'] ?? '') as String,
        );
        assignControllerText(
          _piePaginaController,
          (quoteRow['pie_pagina'] ?? '') as String,
        );
      }

      setState(() => _lineas = drafts);
      for (final line in previousLines) {
        line.dispose();
      }
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        'No se pudieron cargar las líneas de la cotización.',
      );
    } finally {
      if (mounted) {
        setState(() => _loadingExistingQuote = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesControllerProvider);
    final clientesCatalogo = clientesAsync.valueOrNull ?? const <Cliente>[];
    final cotizacionesCatalogo =
        ref.watch(cotizacionesControllerProvider).valueOrNull ??
        const <Cotizacion>[];
    final clientLabelsById = {
      for (final cliente in clientesCatalogo)
        cliente.id: _clientDisplayName(cliente),
    };
    _currentSuggestedFolio = _nextQuoteFolioSuggestion(
      cotizacionesCatalogo
          .where((item) => item.id != widget.quote?.id)
          .map((item) => item.folio),
    );
    _syncSuggestedFolio();

    final clientOptions = [
      if (_selectedClientId != null &&
          _selectedClientId!.isNotEmpty &&
          !clientLabelsById.containsKey(_selectedClientId))
        (value: _selectedClientId!, label: _selectedClientId!),
      ...clientesCatalogo.map(
        (cliente) => (value: cliente.id, label: _clientDisplayName(cliente)),
      ),
    ];
    final subtotal = _subtotalAmount;
    final discount = _discountAmount(subtotal);
    final taxes = _taxTotalAmount;
    final total = _totalAmount;
    final deposit = _depositAmount;
    final paid = deposit.clamp(0, total).toDouble();
    final balance = (total - paid).clamp(0, double.infinity).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Opacity(
                opacity: _loadingExistingQuote ? 0.6 : 1,
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1040;
                        final blocks = [
                          _QuoteSection(
                            title: 'Cliente',
                            icon: FontAwesomeIcons.userGroup,
                            child: clientesAsync.when(
                              loading: () => const SizedBox(
                                height: 72,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (_, __) => EmptyFieldState(
                                hintText: 'No se pudieron cargar los clientes.',
                                message:
                                    'Vuelve a intentar o registra un cliente nuevo para continuar.',
                                buttonLabel: 'Agregar cliente',
                                onPressed: _goToCreateClient,
                              ),
                              data: (items) {
                                if (items.isEmpty) {
                                  return EmptyFieldState(
                                    hintText: 'No hay clientes registrados.',
                                    message:
                                        'Debes registrar un cliente para poder crear una cotización final.',
                                    buttonLabel: 'Agregar cliente',
                                    onPressed: _goToCreateClient,
                                  );
                                }
                                return _QuoteDropdownFieldRow(
                                  label: 'Cliente',
                                  value: _selectedClientId,
                                  hintText: 'Selecciona un cliente',
                                  options: clientOptions,
                                  onChanged: (value) {
                                    setState(() => _selectedClientId = value);
                                  },
                                );
                              },
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
                                  hintText: 'DD/MM/AAAA',
                                ),
                                _QuoteFieldRow(
                                  label: 'Válida hasta',
                                  controller: _validaHastaController,
                                  hintText: 'DD/MM/AAAA',
                                ),
                                _QuoteFieldRow(
                                  label: 'Depósito inicial',
                                  controller: _depositoController,
                                  suffixText: currentCurrencyCode(),
                                  helperText:
                                      'Monto que el cliente pagará por anticipado. Se refleja en pagado y saldo pendiente.',
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
                                  helperText:
                                      'Próximo folio sugerido: $_currentSuggestedFolio',
                                ),
                                _QuoteFieldRow(
                                  label: 'Orden #',
                                  controller: _ordenController,
                                ),
                                _QuoteCustomFieldRow(
                                  label: 'Descuento',
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _QuoteInlineDropdownField(
                                          value: _discountType,
                                          options: _quoteDiscountTypeOptions
                                              .map(
                                                (item) =>
                                                    (value: item, label: item),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(
                                              () => _discountType = value,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
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
                                          decoration: InputDecoration(
                                            suffixText:
                                                _discountType == 'Porcentaje'
                                                ? '%'
                                                : currentCurrencyCode(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                        label: Text(trText('Añadir artículo')),
                      ),
                      child: _buildProductsSection(),
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
                                label: 'Subtotal',
                                value: formatMoney(subtotal),
                              ),
                              _QuoteSummaryRow(
                                label: 'Descuento',
                                value: formatMoney(discount),
                              ),
                              _QuoteSummaryRow(
                                label: 'Impuesto',
                                value: formatMoney(taxes),
                              ),
                              _QuoteSummaryRow(
                                label: 'Total',
                                value: formatMoney(total),
                                strong: true,
                              ),
                              _QuoteSummaryRow(
                                label: 'Pagado',
                                value: formatMoney(paid),
                              ),
                              _QuoteSummaryRow(
                                label: 'Saldo',
                                value: formatMoney(balance),
                              ),
                              const SizedBox(height: 10),
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
                          children: [
                            notes,
                            const SizedBox(height: 10),
                            summary,
                          ],
                        );
                      },
                    ),
                  ],
                ),
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
                onPressed: _savingStatus != null ? null : _handleCancel,
                child: Text(trText('Cancelar')),
              ),
              ElevatedButton.icon(
                onPressed: _savingStatus != null
                    ? null
                    : () => _save(QuoteStatus.enviada),
                icon: _savingStatus == QuoteStatus.enviada
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        widget.quote == null
                            ? Icons.add_rounded
                            : Icons.save_rounded,
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

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loadingProductOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  trText('Cargando productos para sugerencias...'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        if (_productCatalogError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text(
                  trText('No se pudieron cargar las sugerencias de productos.'),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _loadProductOptions,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(trText('Reintentar')),
                ),
              ],
            ),
          ),
        if (!_loadingProductOptions &&
            _productCatalogError == null &&
            _productOptions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text(
                  trText(
                    'No hay productos registrados. Puedes capturar el concepto manualmente o agregar un producto.',
                  ),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                OutlinedButton.icon(
                  onPressed: _goToCreateProduct,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(trText('Agregar producto')),
                ),
              ],
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1320),
            child: Column(
              children: List.generate(
                _lineas.length,
                (index) => _QuoteLineRow(
                  key: ValueKey('linea_$index'),
                  draft: _lineas[index],
                  productOptions: _productOptions,
                  onConceptChanged: (value) =>
                      _handleConceptChanged(index, value),
                  onProductSelected: (productId) =>
                      _seleccionarProducto(index, productId),
                  onRemove: _lineas.length == 1
                      ? null
                      : () => _removerLinea(index),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _agregarLinea() {
    setState(() {
      _lineas = [..._lineas, _buildLineDraft(impuesto: _defaultTaxText())];
    });
  }

  void _removerLinea(int index) {
    final item = _lineas[index];
    setState(() {
      _lineas = [..._lineas]..removeAt(index);
    });
    item.dispose();
  }

  void _seleccionarProducto(int index, String? productId) {
    if (productId == null) return;
    final product = _findProductById(productId);
    if (product == null) return;
    final draft = _lineas[index];
    draft.syncing = true;
    draft.productoServicioId = product.id;
    assignControllerText(draft.conceptoController, product.nombre);
    assignControllerText(draft.descripcionController, product.descripcion);
    assignControllerText(
      draft.costoUnitarioController,
      formatNumericValue(
        product.precioBase,
        decimalDigits: 2,
        useGrouping: true,
      ),
    );
    assignControllerText(
      draft.cantidadController,
      _formatEditableNumber(
        product.cantidadPredeterminada <= 0
            ? 1
            : product.cantidadPredeterminada,
      ),
    );
    assignControllerText(
      draft.impuestoController,
      _formatEditableNumber(product.impuestoPorcentaje),
    );
    assignControllerText(draft.unidadController, product.unidad);
    draft.syncing = false;
    _recalculateLine(draft);
  }

  void _handleConceptChanged(int index, String value) {
    final draft = _lineas[index];
    final selectedId = draft.productoServicioId;
    if (selectedId == null || selectedId.isEmpty) return;
    final selectedProduct = _findProductById(selectedId);
    final matchesSelected =
        selectedProduct != null &&
        value.trim().toLowerCase() ==
            selectedProduct.nombre.trim().toLowerCase();
    if (matchesSelected) return;
    if (!mounted) return;
    setState(() => draft.productoServicioId = null);
  }

  Future<void> _handleCancel() async {
    if (widget.quote != null || !_hasDraftData()) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await _save(
      QuoteStatus.borrador,
      silent: true,
      allowMissingClient: true,
      allowEmptyLineItems: true,
    );
  }

  Future<void> _save(
    QuoteStatus status, {
    bool silent = false,
    bool allowMissingClient = false,
    bool allowEmptyLineItems = false,
  }) async {
    if (_savingStatus != null) return;
    final meaningfulLines = _lineas.where(_hasMeaningfulLineData).toList();
    final subtotal = _subtotalAmount;
    final discount = _discountAmount(subtotal);
    final total = _totalAmount;
    final deposit = _depositAmount;

    if (!allowMissingClient &&
        status != QuoteStatus.borrador &&
        (_selectedClientId == null || _selectedClientId!.trim().isEmpty)) {
      ToastHelper.showWarning(
        context,
        'Selecciona un cliente para crear la cotización.',
      );
      return;
    }

    if (!allowEmptyLineItems &&
        status != QuoteStatus.borrador &&
        meaningfulLines.isEmpty) {
      ToastHelper.showWarning(
        context,
        'Agrega al menos un producto o concepto antes de guardar la cotización.',
      );
      return;
    }

    if (_discountType == 'Porcentaje' &&
        (parseNumericText(_descuentoValorController.text) ?? 0) > 100) {
      ToastHelper.showWarning(
        context,
        'El descuento porcentual no puede ser mayor a 100.',
      );
      return;
    }

    if (deposit > total && total > 0) {
      ToastHelper.showWarning(
        context,
        'El depósito no puede ser mayor al total de la cotización.',
      );
      return;
    }

    final fechaEmision = _parseDate(_fechaController.text) ?? DateTime.now();
    final fechaVencimiento =
        _parseDate(_validaHastaController.text) ?? fechaEmision;
    final resolvedFolio = _folioController.text.trim().isEmpty
        ? _currentSuggestedFolio
        : _folioController.text.trim();

    if (!allowMissingClient &&
        status != QuoteStatus.borrador &&
        resolvedFolio.trim().isEmpty) {
      ToastHelper.showWarning(
        context,
        'Define un número de cotización antes de guardarla.',
      );
      return;
    }

    final payload = CotizacionUpsertPayload(
      id: widget.quote?.id,
      clienteId: _selectedClientId?.trim() ?? '',
      fechaEmision: fechaEmision,
      fechaVencimiento: fechaVencimiento,
      depositoParcial: deposit,
      folio: resolvedFolio,
      ordenNumero: _ordenController.text.trim(),
      descuentoTipo: _discountType,
      descuentoValor: discount,
      impuestoPorcentaje: _headerTaxPercent,
      retIsr: _retIsr,
      notas: _notasController.text.trim(),
      notasPrivadas: _notasPrivadasController.text.trim(),
      terminos: _terminosController.text.trim(),
      piePagina: _piePaginaController.text.trim(),
      estatus: status,
      lineas: List.generate(meaningfulLines.length, (index) {
        final item = meaningfulLines[index];
        final precio = parseNumericText(item.costoUnitarioController.text) ?? 0;
        final cantidad = parseNumericText(item.cantidadController.text) ?? 0;
        return CotizacionLineaInput(
          productoServicioId: item.productoServicioId,
          concepto: item.conceptoController.text.trim(),
          descripcion: item.descripcionController.text.trim(),
          precioUnitario: precio,
          unidad: item.unidadController.text.trim(),
          descuento: 0,
          cantidad: cantidad,
          impuestoPorcentaje:
              parseNumericText(item.impuestoController.text) ?? 0,
          importe: precio * cantidad,
          orden: index,
        );
      }),
    );

    setState(() => _savingStatus = status);
    try {
      await ref.read(cotizacionesRepositoryProvider).upsert(payload);
      ref.invalidate(cotizacionesControllerProvider);
      if (!mounted) return;
      if (!silent) {
        ToastHelper.showSuccess(
          context,
          status == QuoteStatus.borrador
              ? 'Cotización guardada como borrador.'
              : 'Cotización guardada correctamente.',
        );
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        ToastHelper.showError(context, 'No se pudo guardar la cotización.');
      }
    } finally {
      if (mounted) {
        setState(() => _savingStatus = null);
      }
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

  void _syncSuggestedFolio() {
    if (widget.quote != null) return;
    final current = _folioController.text.trim();
    if (current.isEmpty || current == _lastAutoGeneratedFolio) {
      assignControllerText(_folioController, _currentSuggestedFolio);
      _lastAutoGeneratedFolio = _currentSuggestedFolio;
    }
  }

  void _goToCreateClient() {
    Navigator.of(context).pop();
    context.go('${RoutePaths.clientes}?create=1');
  }

  void _goToCreateProduct() {
    Navigator.of(context).pop();
    context.go('${RoutePaths.productos}?create=1');
  }

  _QuoteProductOption? _findProductById(String productId) {
    for (final product in _productOptions) {
      if (product.id == productId) return product;
    }
    return null;
  }

  bool _hasDraftData() {
    final folio = _folioController.text.trim();
    return (_selectedClientId?.trim().isNotEmpty ?? false) ||
        (folio.isNotEmpty && folio != _currentSuggestedFolio) ||
        _ordenController.text.trim().isNotEmpty ||
        (parseNumericText(_depositoController.text) ?? 0) > 0 ||
        (parseNumericText(_descuentoValorController.text) ?? 0) > 0 ||
        _notasController.text.trim().isNotEmpty ||
        _notasPrivadasController.text.trim().isNotEmpty ||
        _terminosController.text.trim().isNotEmpty ||
        _piePaginaController.text.trim().isNotEmpty ||
        _lineas.any(_hasMeaningfulLineData);
  }

  bool _hasMeaningfulLineData(_QuoteLineDraft draft) {
    final hasProduct =
        draft.productoServicioId != null &&
        draft.productoServicioId!.trim().isNotEmpty;
    final hasConcept = draft.conceptoController.text.trim().isNotEmpty;
    final hasDescription = draft.descripcionController.text.trim().isNotEmpty;
    final price = parseNumericText(draft.costoUnitarioController.text) ?? 0;
    final quantityText = draft.cantidadController.text.trim();
    final quantity = parseNumericText(quantityText) ?? 0;
    return hasProduct ||
        hasConcept ||
        hasDescription ||
        price > 0 ||
        (quantityText.isNotEmpty && quantity != 1);
  }

  double _lineSubtotal(_QuoteLineDraft draft) {
    final price = parseNumericText(draft.costoUnitarioController.text) ?? 0;
    final quantity = parseNumericText(draft.cantidadController.text) ?? 0;
    return price * quantity;
  }

  double _lineTax(_QuoteLineDraft draft) {
    final taxRate = parseNumericText(draft.impuestoController.text) ?? 0;
    return _lineSubtotal(draft) * taxRate / 100;
  }

  double get _subtotalAmount => _lineas
      .where(_hasMeaningfulLineData)
      .fold<double>(0, (sum, draft) => sum + _lineSubtotal(draft));

  double _discountAmount(double subtotal) {
    final raw = parseNumericText(_descuentoValorController.text) ?? 0;
    if (raw <= 0 || subtotal <= 0) return 0;
    if (_discountType == 'Porcentaje') {
      return (subtotal * raw / 100).clamp(0, subtotal).toDouble();
    }
    return raw.clamp(0, subtotal).toDouble();
  }

  double get _taxTotalAmount => _lineas
      .where(_hasMeaningfulLineData)
      .fold<double>(0, (sum, draft) => sum + _lineTax(draft));

  double get _totalAmount =>
      (_subtotalAmount - _discountAmount(_subtotalAmount) + _taxTotalAmount)
          .clamp(0, double.infinity)
          .toDouble();

  double get _depositAmount => (parseNumericText(_depositoController.text) ?? 0)
      .clamp(0, double.infinity)
      .toDouble();

  double get _headerTaxPercent {
    for (final draft in _lineas.where(_hasMeaningfulLineData)) {
      final value = parseNumericText(draft.impuestoController.text) ?? 0;
      if (value > 0) return value;
    }
    return 0;
  }

  String _defaultTaxText() {
    final value = _headerTaxPercent > 0 ? _headerTaxPercent : 16.0;
    return _formatEditableNumber(value);
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatEditableNumber(double value) {
    final decimalDigits = value == value.roundToDouble() ? 0 : 2;
    return formatNumericValue(
      value,
      decimalDigits: decimalDigits,
      useGrouping: false,
    );
  }

  double _doubleFromValue(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
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
                          trText(title),
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
    this.maxLines = 1,
    this.hintText,
    this.helperText,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hintText;
  final String? helperText;
  final String? suffixText;
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
                trText(label),
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
                hintText: hintText == null ? null : trText(hintText!),
                helperText: helperText == null ? null : trText(helperText!),
                suffixText: suffixText == null ? null : trText(suffixText!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCustomFieldRow extends StatelessWidget {
  const _QuoteCustomFieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                trText(label),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _QuoteDropdownFieldRow extends StatelessWidget {
  const _QuoteDropdownFieldRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
  });

  final String label;
  final String? value;
  final List<({String value, String label})> options;
  final ValueChanged<String?> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return _QuoteCustomFieldRow(
      label: label,
      child: _QuoteInlineDropdownField(
        value: value,
        hintText: hintText,
        options: options,
        onChanged: onChanged,
      ),
    );
  }
}

class _QuoteInlineDropdownField extends StatelessWidget {
  const _QuoteInlineDropdownField({
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
  });

  final String? value;
  final List<({String value, String label})> options;
  final ValueChanged<String?> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 320,
      borderRadius: cotimaxMenuBorderRadius,
      dropdownColor: AppColors.white,
      icon: cotimaxDropdownIcon,
      style: cotimaxDropdownTextStyle,
      decoration: cotimaxDropdownDecoration(hintText: hintText),
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
      onChanged: onChanged,
    );
  }
}

class _QuoteLineRow extends StatelessWidget {
  const _QuoteLineRow({
    required super.key,
    required this.draft,
    required this.productOptions,
    required this.onConceptChanged,
    required this.onProductSelected,
    this.onRemove,
  });

  final _QuoteLineDraft draft;
  final List<_QuoteProductOption> productOptions;
  final ValueChanged<String> onConceptChanged;
  final ValueChanged<String> onProductSelected;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuoteFieldColumn(
            width: _quoteConceptWidth,
            label: 'Concepto',
            child: _QuoteConceptAutocomplete(
              draft: draft,
              productOptions: productOptions,
              onChanged: onConceptChanged,
              onSelected: (option) => onProductSelected(option.id),
            ),
          ),
          const SizedBox(width: 8),
          _QuoteFieldColumn(
            width: _quoteDescriptionWidth,
            label: 'Descripción',
            child: TextFormField(controller: draft.descripcionController),
          ),
          const SizedBox(width: 8),
          _QuoteFieldColumn(
            width: _quotePriceWidth,
            label: 'Coste unitario',
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
              decoration: InputDecoration(suffixText: currentCurrencyCode()),
            ),
          ),
          const SizedBox(width: 8),
          _QuoteFieldColumn(
            width: _quoteUnitWidth,
            label: 'Unidad',
            child: _QuoteReadOnlyField(
              controller: draft.unidadController,
              fallbackText: 'Sin unidad',
            ),
          ),
          const SizedBox(width: 8),
          _QuoteFieldColumn(
            width: _quoteQuantityWidth,
            label: 'Cantidad',
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
          _QuoteFieldColumn(
            width: _quoteTaxWidth,
            label: 'Tasa de impuesto',
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
          _QuoteFieldColumn(
            width: _quoteTotalWidth,
            label: 'Total',
            child: TextFormField(
              controller: draft.totalController,
              readOnly: true,
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
            Padding(
              padding: const EdgeInsets.only(top: 31),
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                splashRadius: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteFieldColumn extends StatelessWidget {
  const _QuoteFieldColumn({
    required this.width,
    required this.label,
    required this.child,
  });

  final double width;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trText(label),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _QuoteReadOnlyField extends StatelessWidget {
  const _QuoteReadOnlyField({
    required this.controller,
    required this.fallbackText,
  });

  final TextEditingController controller;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: true,
      decoration: InputDecoration(hintText: trText(fallbackText)),
      style: TextStyle(
        color: controller.text.trim().isNotEmpty
            ? AppColors.textPrimary
            : AppColors.textMuted,
      ),
    );
  }
}

class _QuoteConceptAutocomplete extends StatefulWidget {
  const _QuoteConceptAutocomplete({
    required this.draft,
    required this.productOptions,
    required this.onChanged,
    required this.onSelected,
  });

  final _QuoteLineDraft draft;
  final List<_QuoteProductOption> productOptions;
  final ValueChanged<String> onChanged;
  final ValueChanged<_QuoteProductOption> onSelected;

  @override
  State<_QuoteConceptAutocomplete> createState() =>
      _QuoteConceptAutocompleteState();
}

class _QuoteConceptAutocompleteState extends State<_QuoteConceptAutocomplete> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<_QuoteProductOption>(
      textEditingController: widget.draft.conceptoController,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.nombre,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (widget.productOptions.isEmpty) {
          return const Iterable<_QuoteProductOption>.empty();
        }
        if (query.isEmpty) {
          return widget.productOptions.take(8);
        }
        return widget.productOptions
            .where((option) {
              final name = option.nombre.toLowerCase();
              final description = option.descripcion.toLowerCase();
              return name.contains(query) || description.contains(query);
            })
            .take(8);
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            onChanged: widget.onChanged,
            decoration:
                cotimaxDropdownDecoration(
                  hintText: 'Escribe o selecciona un producto',
                ).copyWith(
                  suffixIcon: widget.productOptions.isEmpty
                      ? null
                      : const Icon(Icons.search_rounded),
                ),
          ),
      optionsViewBuilder: (context, onSelected, options) {
        final matches = options.toList(growable: false);
        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 10,
            color: AppColors.white,
            borderRadius: cotimaxMenuBorderRadius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _quoteConceptWidth,
                maxHeight: 280,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: matches.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = matches[index];
                  final description = option.descripcion.trim();
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
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
              trText(label),
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
              trText(label),
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
    required this.productoServicioId,
    required String concepto,
    required String descripcion,
    required String costoUnitario,
    required String cantidad,
    required String impuesto,
    required String total,
    required String unidad,
  }) : conceptoController = seededTextController(concepto),
       descripcionController = seededTextController(descripcion),
       costoUnitarioController = seededTextController(costoUnitario),
       unidadController = seededTextController(unidad),
       cantidadController = seededTextController(cantidad),
       impuestoController = seededTextController(impuesto),
       totalController = seededTextController(total);

  String? productoServicioId;
  bool syncing = false;
  final TextEditingController conceptoController;
  final TextEditingController descripcionController;
  final TextEditingController costoUnitarioController;
  final TextEditingController unidadController;
  final TextEditingController cantidadController;
  final TextEditingController impuestoController;
  final TextEditingController totalController;

  void dispose() {
    conceptoController.dispose();
    descripcionController.dispose();
    costoUnitarioController.dispose();
    unidadController.dispose();
    cantidadController.dispose();
    impuestoController.dispose();
    totalController.dispose();
  }
}
