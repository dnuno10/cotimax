import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/materiales/application/materiales_controller.dart';
import 'package:cotimax/features/productos/application/productos_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/models/upsert_payloads.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  bool _handledCreateRoute = false;
  late final TextEditingController _searchController;
  String _appliedRouteQuery = '';

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
    final asyncData = ref.watch(productosControllerProvider);
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
        _openForm(context);
        if (mounted) {
          context.go(RoutePaths.productos);
        }
      });
    }

    return ListView(
      children: [
        PageHeader(
          title: 'Productos / Servicios',
          subtitle: '',
          actions: [
            ...buildImportExportHeaderActions(
              context,
              entityLabel: 'productos',
            ),
            ElevatedButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo item'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilterBar(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: 320,
                child: SearchField(
                  controller: _searchController,
                  hint: 'Buscar por nombre, SKU o categoria',
                  onChanged: (value) =>
                      ref.read(productosSearchProvider.notifier).state = value,
                ),
              ),
            ),
            const SizedBox(
              width: 180,
              child: SelectField<String>(
                label: 'Tipo',
                value: 'Todos',
                options: ['Todos', 'Producto', 'Servicio'],
              ),
            ),
            const SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Categoria',
                value: 'Todas',
                options: ['Todas', 'Software', 'Consultoria'],
              ),
            ),
            const SizedBox(
              width: 180,
              child: SelectField<String>(
                label: 'Activo',
                value: 'Todos',
                options: ['Todos', 'Activos', 'Inactivos'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        asyncData.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No fue posible cargar productos.',
            onRetry: () => ref.invalidate(productosControllerProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const SectionCard(child: InlineEmptyMessage());
            }

            return CotimaxDataTable(
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Tipo')),
                DataColumn(label: Text('Categoria')),
                DataColumn(label: Text('Unidad')),
                DataColumn(label: Text('Precio base')),
                DataColumn(label: Text('Costo')),
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('Activo')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(Text(item.nombre)),
                        DataCell(Text(item.tipo.label)),
                        DataCell(Text(item.categoriaId)),
                        DataCell(Text(item.unidad)),
                        DataCell(
                          Text('\$${item.precioBase.toStringAsFixed(2)}'),
                        ),
                        DataCell(Text('\$${item.costo.toStringAsFixed(2)}')),
                        DataCell(Text(item.sku)),
                        DataCell(Text(item.activo ? 'Si' : 'No')),
                        DataCell(
                          RowActionMenu(
                            onSelected: (action) =>
                                _onRowAction(context, item, action),
                            actions: const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'dup',
                                child: Text('Duplicar'),
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

  void _openForm(BuildContext context, [ProductoServicio? item]) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: item == null ? 'Nuevo producto' : 'Editar producto',
        child: _ProductoForm(item: item),
      ),
    );
  }

  Future<void> _deleteProducto(ProductoServicio item) async {
    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: 'producto',
    );
    if (!confirmed) return;

    try {
      await ref.read(productosRepositoryProvider).delete(item.id);
      ref.invalidate(productosControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(context, 'Producto eliminado.');
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo eliminar el producto.');
    }
  }

  void _onRowAction(
    BuildContext context,
    ProductoServicio item,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _openForm(context, item);
        return;
      case 'dup':
        _openForm(context);
        return;
      case 'delete':
        _deleteProducto(item);
        return;
    }
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
      ref.read(productosSearchProvider.notifier).state = routeQuery;
    });
  }
}

class _ProductoForm extends ConsumerStatefulWidget {
  const _ProductoForm({this.item});

  final ProductoServicio? item;

  @override
  ConsumerState<_ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends ConsumerState<_ProductoForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _conceptoController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _costoBaseController;
  late final TextEditingController _cantidadDefaultController;
  late final TextEditingController _cantidadMaximaController;
  late final TextEditingController _categoriaImpuestosController;
  late final TextEditingController _imagenController;
  late final TextEditingController _impuestoController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _unidadController;
  late final TextEditingController _skuController;
  late ProductType _selectedTipo;
  String _modoPrecio = 'Fijo';
  bool _activo = true;
  bool _autoCalcularCostoBase = true;
  int _tabIndex = 0;
  late List<_MaterialDraft> _materiales;
  late List<_PrecioRangoDraft> _preciosPorRango;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final item = widget.item;
    _conceptoController = seededTextController(item?.nombre);
    _descripcionController = seededTextController(item?.descripcion ?? '');
    _precioController = seededTextController(
      item == null
          ? ''
          : formatNumericValue(
              item.precioBase,
              decimalDigits: 2,
              useGrouping: true,
            ),
    );
    _costoBaseController = seededTextController(
      item == null
          ? ''
          : formatNumericValue(item.costo, decimalDigits: 2, useGrouping: true),
    );
    _cantidadDefaultController = seededTextController('1');
    _cantidadMaximaController = seededTextController();
    _categoriaImpuestosController = seededTextController(
      item?.tipo == ProductType.producto ? 'Bienes fisicos' : 'Servicios',
    );
    _imagenController = seededTextController(item?.imagenUrl);
    _impuestoController = seededTextController('IVA 16%');
    _categoriaController = seededTextController(item?.categoriaId);
    _unidadController = seededTextController(item?.unidad);
    _skuController = seededTextController(item?.sku);
    _selectedTipo = item?.tipo ?? ProductType.producto;
    _modoPrecio = 'Fijo';
    _activo = item?.activo ?? true;
    _autoCalcularCostoBase = true;
    _materiales = [
      _MaterialDraft(
        materialId: null,
        nombre: 'Material principal',
        tipo: 'Material',
        cantidad: '1',
        costoUnitario: item == null
            ? ''
            : formatNumericValue(
                item.costo,
                decimalDigits: 2,
                useGrouping: true,
              ),
        unidad: item?.unidad ?? 'pieza',
      ),
    ];
    _preciosPorRango = [
      _PrecioRangoDraft(desde: '1', hasta: '49', precio: ''),
      _PrecioRangoDraft(desde: '50', hasta: '199', precio: ''),
    ];
    _attachCalculationListeners();
    _handleCalculationChanged();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _conceptoController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _costoBaseController.dispose();
    _cantidadDefaultController.dispose();
    _cantidadMaximaController.dispose();
    _categoriaImpuestosController.dispose();
    _imagenController.dispose();
    _impuestoController.dispose();
    _categoriaController.dispose();
    _unidadController.dispose();
    _skuController.dispose();
    for (final item in _materiales) {
      item.dispose();
    }
    for (final item in _preciosPorRango) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _ProductTabButton(
              label: 'Crear',
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            const SizedBox(width: 18),
            _ProductTabButton(
              label: 'Materiales y consumibles',
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _tabIndex == 0 ? _buildCreateTab() : _buildMaterialsTab(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProductProfitSummary(
          precio: _precioActual,
          costoBase: _costoBaseActual,
          utilidad: _utilidadActual,
          autoCalculo: _autoCalcularCostoBase,
        ),
        const SizedBox(height: 12),
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
                  widget.item == null ? 'Crear producto' : 'Guardar producto',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateTab() {
    return _ProductoSection(
      title: widget.item == null ? 'Nuevo producto' : 'Editar producto',
      child: Column(
        children: [
          _ProductoTypeFieldRow(
            value: _selectedTipo,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedTipo = value;
                assignControllerText(
                  _categoriaImpuestosController,
                  value == ProductType.producto
                      ? 'Bienes fisicos'
                      : 'Servicios',
                );
              });
            },
          ),
          _ProductoFieldRow(
            label: 'Concepto *',
            controller: _conceptoController,
          ),
          _ProductoFieldRow(
            label: 'Descripcion',
            controller: _descripcionController,
            maxLines: 4,
          ),
          _ProductoFieldRow(
            label: 'Precio',
            controller: _precioController,
            suffixText: 'MXN',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(useGrouping: true, maxDecimalDigits: 2),
            ],
          ),
          _ProductoDropdownFieldRow(
            label: 'Modo de precio',
            value: _modoPrecio,
            options: const ['Fijo', 'Dinamico'],
            onChanged: (value) => setState(() => _modoPrecio = value),
          ),
          if (_modoPrecio == 'Dinamico') ...[
            _ProductoPriceRangesSection(
              drafts: _preciosPorRango,
              onAdd: _agregarPrecioPorRango,
              onRemove: (index) => _removerPrecioPorRango(index),
            ),
            const SizedBox(height: 10),
          ],
          _ProductoSwitchRow(
            label: 'Calcular costo base automaticamente',
            helper:
                'Usa cantidad x costo unitario de cada material/consumible y bloquea la captura manual.',
            value: _autoCalcularCostoBase,
            onChanged: (value) {
              setState(() => _autoCalcularCostoBase = value);
              _handleCalculationChanged();
            },
          ),
          _ProductoFieldRow(
            label: 'Costo base',
            controller: _costoBaseController,
            suffixText: 'MXN',
            enabled: !_autoCalcularCostoBase,
            helper: _autoCalcularCostoBase
                ? 'Calculado automaticamente con base en materiales y consumibles.'
                : 'Captura manual del costo base del producto.',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(useGrouping: true, maxDecimalDigits: 2),
            ],
          ),
          _ProductoFieldRow(
            label: 'Cantidad predeterminada',
            controller: _cantidadDefaultController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(maxDecimalDigits: 2),
            ],
          ),
          _ProductoFieldRow(
            label: 'Cantidad maxima',
            controller: _cantidadMaximaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(maxDecimalDigits: 2),
            ],
          ),
          _ProductoFieldRow(
            label: 'Categoria de impuestos',
            controller: _categoriaImpuestosController,
            dropdown: true,
          ),
          _ProductoFieldRow(
            label: 'Categoria',
            controller: _categoriaController,
            dropdown: true,
          ),
          _ProductoFieldRow(
            label: 'Unidad de medida',
            controller: _unidadController,
          ),
          _ProductoFieldRow(label: 'SKU', controller: _skuController),
          _ProductoFieldRow(
            label: 'URL de la imagen',
            controller: _imagenController,
          ),
          _ProductoFieldRow(
            label: 'Impuesto',
            controller: _impuestoController,
            dropdown: true,
          ),
          _ProductoSwitchRow(
            label: 'Producto activo',
            value: _activo,
            onChanged: (value) => setState(() => _activo = value),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsTab() {
    final materialesCatalogo =
        ref.watch(materialesControllerProvider).valueOrNull ??
        const <MaterialInsumo>[];

    return Column(
      children: [
        _ProductoSection(
          title: 'Materiales y consumibles',
          trailing: TextButton.icon(
            onPressed: _agregarMaterial,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar material'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registra insumos y consumibles. El costo unitario se toma del material seleccionado.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(
                _materiales.length,
                (index) => _MaterialRow(
                  key: ValueKey('material_$index'),
                  index: index,
                  draft: _materiales[index],
                  materialesCatalogo: materialesCatalogo,
                  onTipoChanged: (value) =>
                      _seleccionarTipoMaterial(index, value),
                  onMaterialChanged: (value) =>
                      _seleccionarMaterialCatalogo(index, value),
                  onRemove: _materiales.length == 1
                      ? null
                      : () => _removerMaterial(index),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _agregarMaterial() {
    setState(() {
      _materiales = [
        ..._materiales,
        _MaterialDraft(
          materialId: null,
          nombre: '',
          tipo: 'Material',
          cantidad: '',
          costoUnitario: '',
          unidad: '',
        ),
      ];
    });
    _attachDraftCalculationListeners(_materiales.last);
    _handleCalculationChanged();
  }

  void _removerMaterial(int index) {
    final item = _materiales[index];
    setState(() {
      _materiales = [..._materiales]..removeAt(index);
    });
    item.dispose();
    _handleCalculationChanged();
  }

  void _seleccionarMaterialCatalogo(int index, String? materialId) {
    final draft = _materiales[index];
    final catalogo =
        ref.read(materialesControllerProvider).valueOrNull ??
        const <MaterialInsumo>[];
    MaterialInsumo? material;
    for (final item in catalogo) {
      if (item.id == materialId) {
        material = item;
        break;
      }
    }

    setState(() {
      draft.materialId = materialId;
      if (material == null) return;
      assignControllerText(draft.nombreController, material.nombre);
      assignControllerText(draft.tipoController, 'Material');
      assignControllerText(
        draft.costoUnitarioController,
        formatNumericValue(
          material.costoUnitario,
          decimalDigits: 2,
          useGrouping: true,
        ),
      );
      assignControllerText(draft.unidadController, material.unidad);
      if (draft.cantidadController.text.trim().isEmpty) {
        assignControllerText(draft.cantidadController, '1');
      }
    });
    _handleCalculationChanged();
  }

  void _seleccionarTipoMaterial(int index, String? tipo) {
    if (tipo == null) return;
    final draft = _materiales[index];

    setState(() {
      assignControllerText(draft.tipoController, tipo);
      if (tipo != 'Material') {
        draft.materialId = null;
        clearControllerText(draft.costoUnitarioController);
      }
    });

    _handleCalculationChanged();
  }

  void _agregarPrecioPorRango() {
    setState(() {
      _preciosPorRango = [
        ..._preciosPorRango,
        _PrecioRangoDraft(desde: '', hasta: '', precio: ''),
      ];
    });
  }

  void _removerPrecioPorRango(int index) {
    final item = _preciosPorRango[index];
    setState(() {
      _preciosPorRango = [..._preciosPorRango]..removeAt(index);
    });
    item.dispose();
  }

  void _attachCalculationListeners() {
    _precioController.addListener(_handleCalculationChanged);
    _costoBaseController.addListener(_handleCalculationChanged);
    for (final item in _materiales) {
      _attachDraftCalculationListeners(item);
    }
  }

  void _attachDraftCalculationListeners(_MaterialDraft draft) {
    draft.cantidadController.addListener(_handleCalculationChanged);
    draft.costoUnitarioController.addListener(_handleCalculationChanged);
  }

  double get _costoBaseCalculado {
    return _materiales.fold<double>(0, (sum, item) {
      final cantidad = parseNumericText(item.cantidadController.text) ?? 0;
      final costoUnitario =
          parseNumericText(item.costoUnitarioController.text) ?? 0;
      return sum + (cantidad * costoUnitario);
    });
  }

  double get _precioActual => parseNumericText(_precioController.text) ?? 0;

  double get _costoBaseActual => _autoCalcularCostoBase
      ? _costoBaseCalculado
      : (parseNumericText(_costoBaseController.text) ?? 0);

  double get _utilidadActual => _precioActual - _costoBaseActual;

  void _handleCalculationChanged() {
    if (!mounted) return;

    if (_autoCalcularCostoBase) {
      final formatted = formatNumericValue(
        _costoBaseCalculado,
        decimalDigits: 2,
        useGrouping: true,
      );

      if (_costoBaseController.text != formatted) {
        _costoBaseController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
        return;
      }
    }

    setState(() {});
  }

  Future<void> _save() async {
    final payload = ProductoUpsertPayload(
      id: widget.item?.id,
      tipo: _selectedTipo,
      nombre: _conceptoController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      precioBase: parseNumericText(_precioController.text) ?? 0,
      costoBase: _costoBaseActual,
      autoCalcularCostoBase: _autoCalcularCostoBase,
      modoPrecio: _modoPrecio,
      cantidadPredeterminada: parseNumericText(_cantidadDefaultController.text),
      cantidadMaxima: parseNumericText(_cantidadMaximaController.text),
      categoriaNombre: _categoriaController.text.trim(),
      categoriaImpuestoNombre: _categoriaImpuestosController.text.trim(),
      tasaImpuestoNombre: _impuestoController.text.trim(),
      unidadMedida: _unidadController.text.trim(),
      sku: _skuController.text.trim(),
      imagenUrl: _imagenController.text.trim(),
      activo: _activo,
      componentes: List.generate(_materiales.length, (index) {
        final item = _materiales[index];
        return ProductoComponenteInput(
          tipo: item.tipoController.text.trim(),
          materialId: item.materialId,
          nombreLibre: item.nombreController.text.trim().isEmpty
              ? null
              : item.nombreController.text.trim(),
          cantidad: parseNumericText(item.cantidadController.text) ?? 0,
          unidadConsumo: item.unidadController.text.trim(),
          costoUnitario:
              parseNumericText(item.costoUnitarioController.text) ?? 0,
          orden: index,
        );
      }),
      preciosPorRango: _modoPrecio == 'Dinamico'
          ? _preciosPorRango
                .map(
                  (item) => ProductoPrecioRangoInput(
                    cantidadDesde:
                        parseNumericText(item.desdeController.text) ?? 0,
                    cantidadHasta:
                        parseNumericText(item.hastaController.text) ?? 0,
                    precio: parseNumericText(item.precioController.text) ?? 0,
                  ),
                )
                .toList()
          : const [],
    );

    try {
      await ref.read(productosRepositoryProvider).upsert(payload);
      ref.invalidate(productosControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.item == null
            ? 'Producto creado correctamente.'
            : 'Producto actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo guardar el producto.');
    }
  }
}

class _ProductTabButton extends StatelessWidget {
  const _ProductTabButton({
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
        padding: const EdgeInsets.only(bottom: 10),
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
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ProductoSection extends StatelessWidget {
  const _ProductoSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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

class _ProductoFieldRow extends StatelessWidget {
  const _ProductoFieldRow({
    required this.label,
    required this.controller,
    this.dropdown = false,
    this.maxLines = 1,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final bool dropdown;
  final int maxLines;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller,
                      maxLines: maxLines,
                      enabled: enabled,
                      keyboardType: keyboardType,
                      inputFormatters: inputFormatters,
                      decoration: InputDecoration(
                        suffixText: suffixText,
                        helperText: helper,
                        suffixIcon: dropdown
                            ? const Icon(Icons.keyboard_arrow_down)
                            : null,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: maxLines > 1
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
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
                        enabled: enabled,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        decoration: InputDecoration(
                          suffixText: suffixText,
                          helperText: helper,
                          suffixIcon: dropdown
                              ? const Icon(Icons.keyboard_arrow_down)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ProductoTypeFieldRow extends StatelessWidget {
  const _ProductoTypeFieldRow({required this.value, required this.onChanged});

  final ProductType value;
  final ValueChanged<ProductType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;

        final field = DropdownButtonFormField<ProductType>(
          initialValue: value,
          isExpanded: true,
          menuMaxHeight: 320,
          borderRadius: cotimaxMenuBorderRadius,
          dropdownColor: AppColors.white,
          icon: cotimaxDropdownIcon,
          style: cotimaxDropdownTextStyle,
          decoration: cotimaxDropdownDecoration(),
          items: ProductType.values
              .map(
                (type) => DropdownMenuItem<ProductType>(
                  value: type,
                  child: Text(
                    type.label,
                    overflow: TextOverflow.ellipsis,
                    style: cotimaxDropdownTextStyle,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    field,
                  ],
                )
              : Row(
                  children: [
                    const SizedBox(
                      width: 220,
                      child: Text(
                        'Tipo',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(child: field),
                  ],
                ),
        );
      },
    );
  }
}

class _ProductoDropdownFieldRow extends StatelessWidget {
  const _ProductoDropdownFieldRow({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;

        final field = DropdownButtonFormField<String>(
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
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    field,
                  ],
                )
              : Row(
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
                    Expanded(child: field),
                  ],
                ),
        );
      },
    );
  }
}

class _ProductoSwitchRow extends StatelessWidget {
  const _ProductoSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (helper != null) ...[
                      const SizedBox(height: 4),
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
                    const SizedBox(height: 8),
                    Switch(value: value, onChanged: onChanged),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (helper != null) ...[
                            const SizedBox(height: 4),
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
                    const SizedBox(width: 8),
                    Switch(value: value, onChanged: onChanged),
                  ],
                ),
        );
      },
    );
  }
}

class _ProductoPriceRangesSection extends StatelessWidget {
  const _ProductoPriceRangesSection({
    required this.drafts,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_PrecioRangoDraft> drafts;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return _ProductoSection(
      title: 'Precio por rangos',
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Agregar rango'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Define precios por cantidad cuando el producto use precio dinamico.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            drafts.length,
            (index) => _PrecioRangoRow(
              key: ValueKey('precio_rango_$index'),
              index: index,
              draft: drafts[index],
              onRemove: drafts.length == 1 ? null : () => onRemove(index),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductProfitSummary extends StatelessWidget {
  const _ProductProfitSummary({
    required this.precio,
    required this.costoBase,
    required this.utilidad,
    required this.autoCalculo,
  });

  final double precio;
  final double costoBase;
  final double utilidad;
  final bool autoCalculo;

  @override
  Widget build(BuildContext context) {
    final utilidadColor = utilidad >= 0 ? AppColors.success : AppColors.error;

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: [
          _ProfitMetric(
            label: 'Precio',
            value:
                '\$${formatNumericValue(precio, decimalDigits: 2, useGrouping: true)}',
          ),
          _ProfitMetric(
            label: autoCalculo ? 'Costo base auto' : 'Costo base manual',
            value:
                '\$${formatNumericValue(costoBase, decimalDigits: 2, useGrouping: true)}',
          ),
          _ProfitMetric(
            label: 'Utilidad',
            value:
                '\$${formatNumericValue(utilidad, decimalDigits: 2, useGrouping: true)}',
            valueColor: utilidadColor,
          ),
        ],
      ),
    );
  }
}

class _ProfitMetric extends StatelessWidget {
  const _ProfitMetric({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CompactFieldRow extends StatelessWidget {
  const _CompactFieldRow({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactDropdownRow extends StatelessWidget {
  const _CompactDropdownRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
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
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSelectRow extends StatelessWidget {
  const _CompactSelectRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<({String value, String label})> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String?>(
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
                    (option) => DropdownMenuItem<String?>(
                      value: option.value,
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: cotimaxDropdownTextStyle,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required super.key,
    required this.index,
    required this.draft,
    required this.materialesCatalogo,
    required this.onTipoChanged,
    required this.onMaterialChanged,
    this.onRemove,
  });

  final int index;
  final _MaterialDraft draft;
  final List<MaterialInsumo> materialesCatalogo;
  final ValueChanged<String?> onTipoChanged;
  final ValueChanged<String?> onMaterialChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isMaterial = draft.tipoController.text == 'Material';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Material ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  splashRadius: 18,
                ),
            ],
          ),
          _CompactDropdownRow(
            label: 'Tipo',
            value: draft.tipoController.text,
            options: const ['Material', 'Mano de obra', 'Costo indirecto'],
            onChanged: onTipoChanged,
          ),
          if (isMaterial)
            _CompactSelectRow(
              label: 'Nombre',
              value: draft.materialId,
              options: materialesCatalogo
                  .map(
                    (material) => (value: material.id, label: material.nombre),
                  )
                  .toList(),
              onChanged: onMaterialChanged,
            )
          else
            _CompactFieldRow(
              label: 'Nombre',
              controller: draft.nombreController,
            ),
          Row(
            children: [
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Cantidad',
                  controller: draft.cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [
                    NumericTextInputFormatter(maxDecimalDigits: 2),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Costo unitario',
                  controller: draft.costoUnitarioController,
                  enabled: false,
                  suffixText: 'MXN',
                  helper: isMaterial
                      ? 'Se toma del material'
                      : 'Disponible solo para materiales',
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
              const SizedBox(width: 10),
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Unidad de consumo',
                  controller: draft.unidadController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrecioRangoRow extends StatelessWidget {
  const _PrecioRangoRow({
    required super.key,
    required this.index,
    required this.draft,
    this.onRemove,
  });

  final int index;
  final _PrecioRangoDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rango ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  splashRadius: 18,
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Desde',
                  controller: draft.desdeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [
                    NumericTextInputFormatter(maxDecimalDigits: 2),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Hasta',
                  controller: draft.hastaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [
                    NumericTextInputFormatter(maxDecimalDigits: 2),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Precio',
                  controller: draft.precioController,
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
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactFieldColumn extends StatelessWidget {
  const _CompactFieldColumn({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.suffixText,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? suffixText;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            suffixText: suffixText,
            helperText: helper,
          ),
        ),
      ],
    );
  }
}

class _MaterialDraft {
  _MaterialDraft({
    required this.materialId,
    required String nombre,
    required String tipo,
    required String cantidad,
    required String costoUnitario,
    required String unidad,
  }) : nombreController = seededTextController(nombre),
       tipoController = seededTextController(tipo),
       cantidadController = seededTextController(cantidad),
       costoUnitarioController = seededTextController(costoUnitario),
       unidadController = seededTextController(unidad);

  String? materialId;
  final TextEditingController nombreController;
  final TextEditingController tipoController;
  final TextEditingController cantidadController;
  final TextEditingController costoUnitarioController;
  final TextEditingController unidadController;

  void dispose() {
    nombreController.dispose();
    tipoController.dispose();
    cantidadController.dispose();
    costoUnitarioController.dispose();
    unidadController.dispose();
  }
}

class _PrecioRangoDraft {
  _PrecioRangoDraft({
    required String desde,
    required String hasta,
    required String precio,
  }) : desdeController = seededTextController(desde),
       hastaController = seededTextController(hasta),
       precioController = seededTextController(precio);

  final TextEditingController desdeController;
  final TextEditingController hastaController;
  final TextEditingController precioController;

  void dispose() {
    desdeController.dispose();
    hastaController.dispose();
    precioController.dispose();
  }
}
