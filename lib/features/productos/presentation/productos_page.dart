import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/platform/product_image_picker.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/core/utils/uuid.dart';
import 'package:cotimax/features/configuracion/application/configuracion_controller.dart';
import 'package:cotimax/features/cotizaciones/application/cotizaciones_controller.dart';
import 'package:cotimax/features/materiales/application/materiales_controller.dart';
import 'package:cotimax/features/planes/application/plan_access.dart';
import 'package:cotimax/features/productos/application/productos_controller.dart';
import 'package:cotimax/features/workspace/application/workspace_controller.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/models/upsert_payloads.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const List<String> _productCategoryOptions = [
  'General',
  'Producto terminado',
  'Producto personalizado',
  'Producto digital',
  'Servicio profesional',
  'Servicio técnico',
  'Consultoría',
  'Diseño',
  'Desarrollo de software',
  'Desarrollo web',
  'Marketing',
  'Publicidad',
  'Impresión',
  'Papelería',
  'Empaque',
  'Embalaje',
  'Uniformes',
  'Promocionales',
  'Electrónica',
  'Hardware',
  'Accesorios',
  'Refacciones',
  'Mantenimiento',
  'Instalación',
  'Construcción',
  'Carpintería',
  'Metal mecánica',
  'Logística',
  'Transporte',
  'Alimentos y bebidas',
  'Salud',
  'Educación',
  'Limpieza',
  'Seguridad',
  'Eventos',
];

const List<String> _productUnitOptions = [
  'pieza',
  'caja',
  'paquete',
  'bolsa',
  'rollo',
  'hoja',
  'pliego',
  'juego',
  'kit',
  'par',
  'docena',
  'ciento',
  'millar',
  'metro',
  'centímetro',
  'milímetro',
  'kilómetro',
  'metro cuadrado',
  'metro cúbico',
  'litro',
  'mililitro',
  'galón',
  'kilogramo',
  'gramo',
  'miligramo',
  'tonelada',
  'onza',
  'libra',
  'yarda',
  'pie',
  'pulgada',
  'tambor',
  'tarima',
  'contenedor',
  'bote',
  'frasco',
  'tubo',
];

List<String> _buildConfiguredTaxOptions(EmpresaPerfil? empresa) {
  if (empresa == null) return const [];
  final impuestos = empresa.impuestos;
  EmpresaTasaImpuesto? defaultRate;
  for (final item in impuestos.tasas) {
    if (item.nombre == impuestos.tasaPredeterminada) {
      defaultRate = item;
      break;
    }
  }
  final values = <String>[
    if (defaultRate != null) defaultRate.displayLabel,
    ...impuestos.tasas.map((item) => item.displayLabel),
  ];
  final seen = <String>{};
  final deduped = <String>[];
  for (final value in values) {
    final normalized = value.toLowerCase();
    if (seen.add(normalized)) {
      deduped.add(value);
    }
  }
  return deduped;
}

String _resolvedOptionValue(
  String? raw, {
  required List<String> options,
  required String fallback,
}) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return fallback;
  return options.contains(value) ? value : value;
}

List<String> _optionsWithCurrent(List<String> options, String currentValue) {
  if (currentValue.trim().isEmpty || options.contains(currentValue)) {
    return options;
  }
  return [currentValue, ...options];
}

class ProductosPage extends ConsumerStatefulWidget {
  ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  bool _handledCreateRoute = false;
  late final TextEditingController _searchController;
  String _appliedRouteQuery = '';
  final Set<String> _selectedProductoIds = <String>{};

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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _openForm(context);
        if (!context.mounted) return;
        context.go(RoutePaths.productos);
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
              icon: Icon(Icons.add),
              label: Text(trText('Nuevo item')),
            ),
          ],
        ),
        SizedBox(height: 10),
        FilterBar(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 20),
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
            SizedBox(
              width: 180,
              child: SelectField<String>(
                label: 'Tipo',
                value: 'Todos',
                options: ['Todos', 'Producto', 'Servicio'],
              ),
            ),
            SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Categoria',
                value: 'Todas',
                options: ['Todas', 'Software', 'Consultoria'],
              ),
            ),
            SizedBox(
              width: 180,
              child: SelectField<String>(
                label: 'Activo',
                value: 'Todos',
                options: ['Todos', 'Activos', 'Inactivos'],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        asyncData.when(
          loading: () => LoadingStateWidget(message: 'Cargando productos...'),
          error: (error, _) => shouldCreate
              ? LoadingStateWidget(message: 'Preparando formulario...')
              : ErrorStateWidget(
                  message: 'No fue posible cargar productos.',
                  details: error.toString(),
                  onRetry: () => ref.invalidate(productosControllerProvider),
                ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyStateWidget(
                title: 'Todavía no hay productos',
                subtitle: 'Registra tu primer producto para comenzar.',
                action: ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: Icon(Icons.add),
                  label: Text(trText('Nuevo item')),
                ),
              );
            }

            final allSelected = _selectedProductoIds.length == items.length;
            final partiallySelected =
                _selectedProductoIds.isNotEmpty && !allSelected;

            return CotimaxDataTable(
              toolbar: _selectedProductoIds.isEmpty
                  ? null
                  : TableSelectionToolbar(
                      count: _selectedProductoIds.length,
                      entityLabel: 'producto',
                      onEdit: _selectedProductoIds.length == 1
                          ? () {
                              final producto = items.firstWhere(
                                (item) => item.id == _selectedProductoIds.first,
                              );
                              _openForm(context, producto);
                            }
                          : null,
                      onDelete: _deleteSelectedProductos,
                      onClear: () =>
                          setState(() => _selectedProductoIds.clear()),
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
                          _selectedProductoIds
                            ..clear()
                            ..addAll(items.map((item) => item.id));
                        } else {
                          _selectedProductoIds.clear();
                        }
                      });
                    },
                  ),
                ),
                DataColumn(label: Text(trText('Nombre'))),
                DataColumn(label: Text(trText('Tipo'))),
                DataColumn(label: Text(trText('Categoria'))),
                DataColumn(label: Text(trText('Unidad'))),
                DataColumn(label: Text(trText('Precio base'))),
                DataColumn(label: Text(trText('Costo'))),
                DataColumn(label: Text(trText('SKU'))),
                DataColumn(label: Text(trText('Activo'))),
                DataColumn(label: Text(trText('Acciones'))),
              ],
              rows: items
                  .map(
                    (item) => DataRow(
                      selected: _selectedProductoIds.contains(item.id),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: _selectedProductoIds.contains(item.id),
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selectedProductoIds.add(item.id);
                                } else {
                                  _selectedProductoIds.remove(item.id);
                                }
                              });
                            },
                          ),
                        ),
                        DataCell(Text(item.nombre)),
                        DataCell(Text(trText(item.tipo.label))),
                        DataCell(Text(item.categoriaId)),
                        DataCell(Text(item.unidad)),
                        DataCell(Text(formatMoney(item.precioBase))),
                        DataCell(Text(formatMoney(item.costo))),
                        DataCell(Text(item.sku)),
                        DataCell(Text(trText(item.activo ? 'Si' : 'No'))),
                        DataCell(
                          RowActionMenu(
                            onSelected: (action) =>
                                _onRowAction(context, item, action),
                            actions: [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                    SizedBox(width: 8),
                                    Text(trText('Editar')),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'dup',
                                child: Text(trText('Duplicar')),
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

  Future<void> _openForm(BuildContext context, [ProductoServicio? item]) async {
    if (item == null) {
      final planAccess = await ref.read(activePlanAccessProvider.future);
      final productos =
          ref.read(productosControllerProvider).valueOrNull ??
          await ref.read(productosControllerProvider.future);
      if (!mounted) return;
      if (hasReachedPlanLimit(
        limit: planAccess.plan.limiteProductos,
        used: productos?.length ?? 0,
      )) {
        await showPlanUpgradeDialog(
          context,
          title: 'Límite del plan Starter',
          message:
              'Tu plan Starter permite hasta 5 productos o servicios. Actualiza a Pro para registrar más items.',
        );
        return;
      }
    }

    return showDialog<void>(
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
      dependencyEntityType: 'producto',
      dependencyIds: [item.id],
      onConfirmAsync: () async {
        try {
          await ref.read(productosRepositoryProvider).delete(item.id);
          ref.invalidate(productosControllerProvider);
          ref.invalidate(cotizacionesControllerProvider);
          if (!mounted) return;
          ToastHelper.showSuccess(context, 'Producto eliminado.');
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(error, 'No se pudo eliminar el producto.'),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }

  Future<void> _deleteSelectedProductos() async {
    final count = _selectedProductoIds.length;
    if (count == 0) return;

    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: count == 1 ? 'producto' : 'productos seleccionados',
      title: count == 1 ? 'Eliminar producto' : 'Eliminar productos',
      message: count == 1
          ? '¿Estás seguro que quieres eliminar este producto?'
          : '¿Estás seguro que quieres eliminar los $count productos seleccionados?',
      dependencyEntityType: 'producto',
      dependencyIds: _selectedProductoIds.toList(),
      onConfirmAsync: () async {
        try {
          final ids = _selectedProductoIds.toList();
          for (final id in ids) {
            await ref.read(productosRepositoryProvider).delete(id);
          }
          ref.invalidate(productosControllerProvider);
          ref.invalidate(cotizacionesControllerProvider);
          if (!mounted) return;
          setState(() => _selectedProductoIds.clear());
          ToastHelper.showSuccess(
            context,
            count == 1
                ? 'Producto eliminado.'
                : '$count productos eliminados correctamente.',
          );
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(
              error,
              'No se pudieron eliminar los productos.',
            ),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
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
  _ProductoForm({this.item});

  final ProductoServicio? item;

  @override
  ConsumerState<_ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends ConsumerState<_ProductoForm> {
  static const int _maxProductImageBytes = 5 * 1024 * 1024;
  static const String _productImagesBucket = 'producto_imagenes';

  late final ScrollController _scrollController;
  late final TextEditingController _conceptoController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _costoBaseController;
  late final TextEditingController _cantidadDefaultController;
  late final TextEditingController _cantidadMaximaController;
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
  bool _isSaving = false;
  bool _isHydrating = false;
  late final String _draftProductId;
  ProductImagePickResult? _pendingImage;
  bool _removeImage = false;
  String _materialDraftCatalogSyncKey = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _draftProductId = widget.item?.id ?? generateUuidV4();
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
    _impuestoController = seededTextController();
    _categoriaController = seededTextController(
      _resolvedOptionValue(
        item?.categoriaId,
        options: _productCategoryOptions,
        fallback: 'General',
      ),
    );
    _unidadController = seededTextController(
      _resolvedOptionValue(
        item?.unidad,
        options: _productUnitOptions,
        fallback: 'pieza',
      ),
    );
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
    if (item != null) {
      _loadExistingProductConfiguration();
    }
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
            SizedBox(width: 18),
            _ProductTabButton(
              label: 'Materiales y consumibles',
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(height: 1, color: AppColors.border),
        SizedBox(height: 10),
        Expanded(
          child: _isHydrating
              ? LoadingStateWidget(message: 'Cargando producto...')
              : Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: _tabIndex == 0
                        ? _buildCreateTab()
                        : _buildMaterialsTab(),
                  ),
                ),
        ),
        SizedBox(height: 12),
        _ProductProfitSummary(
          precio: _precioActual,
          costoBase: _costoBaseActual,
          utilidad: _utilidadActual,
          autoCalculo: _autoCalcularCostoBase,
        ),
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 10,
            children: [
              OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
    final empresa = ref.watch(empresaPerfilControllerProvider).valueOrNull;
    final impuestosRegistrados = _buildConfiguredTaxOptions(empresa);
    final materialesCatalogo =
        ref.watch(materialesControllerProvider).valueOrNull ??
        const <MaterialInsumo>[];
    final planAccess = ref.watch(activePlanAccessProvider).valueOrNull;
    final canManageImages = _canManageProductImages(planAccess);

    _scheduleMaterialDraftSync(materialesCatalogo);
    final noneTaxOption = tr('Ninguno', 'None');
    final impuestoActual = _impuestoController.text.trim();
    final impuestoSeleccionado = impuestoActual.isNotEmpty
        ? impuestoActual
        : noneTaxOption;

    return _ProductoSection(
      title: widget.item == null ? 'Nuevo producto' : 'Editar producto',
      child: Column(
        children: [
          _ProductoCustomFieldRow(
            label: 'Imagen',
            labelSuffix: Icon(
              Icons.workspace_premium_rounded,
              size: 16,
              color: AppColors.accent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    if (_pendingImage != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _pendingImage!.bytes,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    final existingUrl = (widget.item?.imagenUrl ?? '').trim();
                    final showExisting =
                        existingUrl.isNotEmpty && !_removeImage;
                    if (showExisting) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          existingUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'No se pudo cargar la imagen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Sin imagen. Máximo 5MB.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickProductImage,
                      icon: Icon(Icons.photo_library_outlined, size: 16),
                      label: Text(
                        trText(
                          (_pendingImage != null ||
                                  ((widget.item?.imagenUrl ?? '')
                                          .trim()
                                          .isNotEmpty &&
                                      !_removeImage))
                              ? 'Cambiar imagen'
                              : 'Cargar imagen',
                        ),
                      ),
                    ),
                    if (_pendingImage != null ||
                        (((widget.item?.imagenUrl ?? '').trim().isNotEmpty) &&
                            !_removeImage))
                      TextButton.icon(
                        onPressed: _isSaving ? null : _clearProductImage,
                        icon: Icon(Icons.delete_outline_rounded, size: 16),
                        label: Text(trText('Quitar imagen')),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                  ],
                ),
                if (!canManageImages) ...[
                  SizedBox(height: 8),
                  Text(
                    'Imágenes de producto disponibles en Pro o Empresa.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _ProductoTypeFieldRow(
            value: _selectedTipo,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedTipo = value);
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
            suffixText: currentCurrencyCode(),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(
                useGrouping: true,
                maxDecimalDigits: 2,
                moneyInputBehavior: true,
              ),
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
            SizedBox(height: 10),
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
            suffixText: currentCurrencyCode(),
            enabled: !_autoCalcularCostoBase,
            helper: _autoCalcularCostoBase
                ? 'Calculado automaticamente con base en materiales y consumibles.'
                : 'Captura manual del costo base del producto.',
            helperActionLabel: 'Ver materiales y consumibles',
            onHelperAction: _goToMaterialsTab,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(
                useGrouping: true,
                maxDecimalDigits: 2,
                moneyInputBehavior: true,
              ),
            ],
          ),
          _ProductoFieldRow(
            label: 'Cantidad predeterminada',
            controller: _cantidadDefaultController,
            helper:
                'Será la cantidad predeterminada a mostrar al seleccionar el producto en la cotización.',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(maxDecimalDigits: 2),
            ],
          ),
          _ProductoFieldRow(
            label: 'Cantidad maxima',
            controller: _cantidadMaximaController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(maxDecimalDigits: 2),
            ],
          ),
          _ProductoDropdownFieldRow(
            label: 'Categoría',
            value: _categoriaController.text.trim().isEmpty
                ? 'General'
                : _categoriaController.text.trim(),
            options: _optionsWithCurrent(
              _productCategoryOptions,
              _categoriaController.text.trim(),
            ),
            onChanged: (value) =>
                assignControllerText(_categoriaController, value),
          ),
          _ProductoDropdownFieldRow(
            label: 'Unidad de medida',
            value: _unidadController.text.trim().isEmpty
                ? 'pieza'
                : _unidadController.text.trim(),
            options: _optionsWithCurrent(
              _productUnitOptions,
              _unidadController.text.trim().isEmpty
                  ? 'pieza'
                  : _unidadController.text.trim(),
            ),
            onChanged: (value) =>
                assignControllerText(_unidadController, value),
          ),
          _ProductoFieldRow(label: 'SKU', controller: _skuController),
          impuestosRegistrados.isEmpty
              ? _ProductoCustomFieldRow(
                  label: 'Impuesto',
                  child: EmptyFieldState(
                    hintText: 'No hay impuestos registrados.',
                    message:
                        'Registra tus impuestos en Configuración para poder asignarlos a este producto.',
                    buttonLabel: 'Agregar impuesto',
                    onPressed: _goToTaxSettings,
                  ),
                )
              : _ProductoDropdownFieldRow(
                  label: 'Impuesto',
                  value: impuestoSeleccionado,
                  options: _optionsWithCurrent([
                    noneTaxOption,
                    ...impuestosRegistrados,
                  ], impuestoSeleccionado),
                  onChanged: (value) {
                    if (value == noneTaxOption) {
                      clearControllerText(_impuestoController);
                      return;
                    }
                    assignControllerText(_impuestoController, value);
                  },
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

    _scheduleMaterialDraftSync(materialesCatalogo);

    return Column(
      children: [
        _ProductoSection(
          title: 'Materiales y consumibles',
          trailing: TextButton.icon(
            onPressed: _agregarMaterial,
            icon: Icon(Icons.add, size: 16),
            label: Text(trText('Añadir renglón')),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registra insumos y consumibles para calcular el costo base del producto.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              if (_materiales.isEmpty)
                EmptyFieldState(
                  hintText: 'Sin materiales y consumibles.',
                  message:
                      'Este producto no tiene renglones registrados. Puedes agregar uno cuando lo necesites.',
                  buttonLabel: 'Añadir renglón',
                  onPressed: _agregarMaterial,
                )
              else
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
                    onAddMaterial: _goToCreateMaterial,
                    onRemove: () => _removerMaterial(index),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildMaterialCatalogSyncKey(List<MaterialInsumo> catalogo) {
    final ids = _materiales
        .map((item) => item.materialId)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    if (ids.isEmpty) return '';
    final map = <String, MaterialInsumo>{
      for (final item in catalogo) item.id: item,
    };
    final parts = <String>[];
    for (final id in ids) {
      final material = map[id];
      if (material == null) continue;
      parts.add(
        '$id:${material.updatedAt.microsecondsSinceEpoch}:${material.costoUnitario}:${material.nombre}:${material.unidad}',
      );
    }
    parts.sort();
    return parts.join('|');
  }

  void _scheduleMaterialDraftSync(List<MaterialInsumo> catalogo) {
    if (!mounted || _isHydrating) return;
    final nextKey = _buildMaterialCatalogSyncKey(catalogo);
    if (nextKey == _materialDraftCatalogSyncKey) return;
    _materialDraftCatalogSyncKey = nextKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isHydrating) return;
      final materialMap = <String, MaterialInsumo>{
        for (final item in catalogo) item.id: item,
      };
      for (final draft in _materiales) {
        final materialId = draft.materialId;
        if (materialId == null || materialId.trim().isEmpty) continue;
        if (draft.tipoController.text.trim() != 'Material') continue;
        final material = materialMap[materialId];
        if (material == null) continue;

        final desiredName = material.nombre;
        final desiredUnit = material.unidad;
        final desiredCost = formatNumericValue(
          material.costoUnitario,
          decimalDigits: 2,
          useGrouping: true,
        );

        if (draft.nombreController.text.trim() != desiredName.trim()) {
          assignControllerText(draft.nombreController, desiredName);
        }
        if (draft.unidadController.text.trim() != desiredUnit.trim()) {
          assignControllerText(draft.unidadController, desiredUnit);
        }
        if (draft.costoUnitarioController.text.trim() != desiredCost.trim()) {
          assignControllerText(draft.costoUnitarioController, desiredCost);
        }
      }
    });
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

  void _goToCreateMaterial() {
    context.go('${RoutePaths.materiales}?create=1');
  }

  void _goToMaterialsTab() {
    setState(() => _tabIndex = 1);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _goToTaxSettings() {
    context.go('${RoutePaths.configuracion}?main=impuestos');
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
        clearControllerText(draft.unidadController);
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

  Future<void> _loadExistingProductConfiguration() async {
    final productId = widget.item?.id;
    if (productId == null) return;

    setState(() => _isHydrating = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final empresaId = ref
          .read(workspaceStatusProvider)
          .valueOrNull
          ?.empresaId;
      dynamic productQuery = client
          .from('productos_servicios')
          .select(
            'modo_precio,auto_calcular_costo_base,cantidad_predeterminada,'
            'cantidad_maxima,tasa_impuesto_nombre',
          )
          .eq('id', productId);
      if (empresaId != null && empresaId.trim().isNotEmpty) {
        productQuery = productQuery.eq('empresa_id', empresaId.trim());
      }
      final productRow = await productQuery.maybeSingle();

      final componentesRows = await client
          .from('producto_componentes')
          .select(
            'tipo,material_id,nombre_libre,cantidad,unidad_consumo,'
            'costo_unitario_snapshot,orden',
          )
          .eq('producto_id', productId)
          .order('orden');

      final preciosRows = await client
          .from('producto_precios_rango')
          .select('cantidad_desde,cantidad_hasta,precio')
          .eq('producto_id', productId)
          .order('cantidad_desde');

      final materialIds = (componentesRows as List)
          .map((item) => item['material_id']?.toString())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();

      final materialMap = <String, Map<String, dynamic>>{};
      if (materialIds.isNotEmpty) {
        dynamic materialQuery = client
            .from('materiales_insumos')
            .select('id,nombre,unidad_medida,costo_unitario')
            .inFilter('id', materialIds);
        if (empresaId != null && empresaId.trim().isNotEmpty) {
          materialQuery = materialQuery.eq('empresa_id', empresaId.trim());
        }
        final materialRows = await materialQuery;
        for (final row in (materialRows as List).cast<Map<String, dynamic>>()) {
          materialMap[row['id'] as String] = row;
        }
      }

      final nuevosMateriales = (componentesRows as List)
          .cast<Map<String, dynamic>>()
          .map((row) {
            final materialId = row['material_id']?.toString();
            final materialData = materialId == null
                ? null
                : materialMap[materialId];
            final cantidad = _formatDecimal(
              (row['cantidad'] as num?)?.toDouble() ?? 0,
            );
            final costoUnitario = formatNumericValue(
              (materialData?['costo_unitario'] as num?)?.toDouble() ??
                  (row['costo_unitario_snapshot'] as num?)?.toDouble() ??
                  0,
              decimalDigits: 2,
              useGrouping: true,
            );
            final unidadConsumo =
                (row['unidad_consumo']?.toString() ?? '').trim().isNotEmpty
                ? row['unidad_consumo']!.toString()
                : (materialData?['unidad_medida']?.toString() ?? '');
            final nombre =
                (materialData?['nombre']?.toString() ?? '').trim().isNotEmpty
                ? materialData!['nombre'].toString()
                : (row['nombre_libre']?.toString() ?? '');
            return _MaterialDraft(
              materialId: materialId,
              nombre: nombre,
              tipo: row['tipo']?.toString() ?? 'Material',
              cantidad: cantidad,
              costoUnitario: costoUnitario,
              unidad: unidadConsumo,
            );
          })
          .toList();

      final nuevosRangos = (preciosRows as List)
          .cast<Map<String, dynamic>>()
          .map(
            (row) => _PrecioRangoDraft(
              desde: _formatDecimal(
                (row['cantidad_desde'] as num?)?.toDouble() ?? 0,
              ),
              hasta: _formatDecimal(
                (row['cantidad_hasta'] as num?)?.toDouble() ?? 0,
              ),
              precio: formatNumericValue(
                (row['precio'] as num?)?.toDouble() ?? 0,
                decimalDigits: 2,
                useGrouping: true,
              ),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _modoPrecio = (productRow?['modo_precio']?.toString() ?? 'Fijo');
        _autoCalcularCostoBase =
            productRow?['auto_calcular_costo_base'] as bool? ?? true;
        assignControllerText(
          _cantidadDefaultController,
          _formatNullableDecimal(
            (productRow?['cantidad_predeterminada'] as num?)?.toDouble(),
            fallback: '1',
          ),
        );
        assignControllerText(
          _cantidadMaximaController,
          _formatNullableDecimal(
            (productRow?['cantidad_maxima'] as num?)?.toDouble(),
          ),
        );
        assignControllerText(
          _impuestoController,
          productRow?['tasa_impuesto_nombre']?.toString() ?? '',
        );
        _replaceMaterialDrafts(nuevosMateriales);
        _replacePriceRangeDrafts(nuevosRangos);
      });
      _handleCalculationChanged();
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(
          error,
          'No se pudo cargar la configuración del producto.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isHydrating = false);
      }
    }
  }

  void _replaceMaterialDrafts(List<_MaterialDraft> drafts) {
    for (final item in _materiales) {
      item.dispose();
    }
    _materiales = drafts;
    for (final item in _materiales) {
      _attachDraftCalculationListeners(item);
    }
  }

  void _replacePriceRangeDrafts(List<_PrecioRangoDraft> drafts) {
    for (final item in _preciosPorRango) {
      item.dispose();
    }
    _preciosPorRango = drafts.isEmpty
        ? [
            _PrecioRangoDraft(desde: '1', hasta: '49', precio: ''),
            _PrecioRangoDraft(desde: '50', hasta: '199', precio: ''),
          ]
        : drafts;
  }

  String _formatDecimal(double value) {
    return formatNumericValue(value, decimalDigits: 2);
  }

  String _formatNullableDecimal(double? value, {String fallback = ''}) {
    if (value == null) return fallback;
    return formatNumericValue(value, decimalDigits: 2);
  }

  bool _canManageProductImages(ActivePlanAccess? access) {
    final planId = access?.plan.id ?? 'starter';
    return planId == 'pro' || planId == 'empresa';
  }

  Future<void> _pickProductImage() async {
    final access = await ref.read(activePlanAccessProvider.future);
    if (!_canManageProductImages(access)) {
      if (!mounted) return;
      await showPlanUpgradeDialog(
        context,
        title: 'Imágenes disponibles en Pro',
        message:
            'Necesitas el plan Pro o Empresa para agregar o actualizar imágenes en productos.',
      );
      return;
    }

    final picked = await pickProductImage();
    if (!mounted || picked == null) return;

    if (picked.mimeType.trim().isNotEmpty &&
        !picked.mimeType.toLowerCase().startsWith('image/')) {
      ToastHelper.showWarning(context, 'Selecciona un archivo de imagen.');
      return;
    }

    if (picked.sizeBytes > _maxProductImageBytes) {
      ToastHelper.showWarning(
        context,
        'La imagen supera 5MB. Selecciona una imagen más ligera.',
      );
      return;
    }

    setState(() {
      _pendingImage = picked;
      _removeImage = false;
    });
  }

  Future<void> _clearProductImage() async {
    final access = await ref.read(activePlanAccessProvider.future);
    if (!_canManageProductImages(access)) {
      if (!mounted) return;
      await showPlanUpgradeDialog(
        context,
        title: 'Imágenes disponibles en Pro',
        message:
            'Necesitas el plan Pro o Empresa para quitar imágenes en productos.',
      );
      return;
    }

    setState(() {
      _pendingImage = null;
      _removeImage = true;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final nombre = _conceptoController.text.trim();
    final sku = _skuController.text.trim();
    if (nombre.isEmpty) {
      ToastHelper.showWarning(
        context,
        'Debes capturar el nombre del producto antes de guardarlo.',
      );
      return;
    }
    if (widget.item == null) {
      final planAccess = await ref.read(activePlanAccessProvider.future);
      final productos =
          ref.read(productosControllerProvider).valueOrNull ??
          const <ProductoServicio>[];
      if (hasReachedPlanLimit(
        limit: planAccess.plan.limiteProductos,
        used: productos.length,
      )) {
        if (!mounted) return;
        await showPlanUpgradeDialog(
          context,
          title: 'Límite del plan Starter',
          message:
              'Tu plan Starter permite hasta 5 productos o servicios. Actualiza a Pro para registrar más items.',
        );
        return;
      }
    }
    final productId = _draftProductId;

    final payload = ProductoUpsertPayload(
      id: productId,
      tipo: _selectedTipo,
      nombre: nombre,
      descripcion: _descripcionController.text.trim(),
      precioBase: parseNumericText(_precioController.text) ?? 0,
      costoBase: _costoBaseActual,
      autoCalcularCostoBase: _autoCalcularCostoBase,
      modoPrecio: _modoPrecio,
      cantidadPredeterminada: parseNumericText(_cantidadDefaultController.text),
      cantidadMaxima: parseNumericText(_cantidadMaximaController.text),
      categoriaNombre: _categoriaController.text.trim(),
      tasaImpuestoNombre: _impuestoController.text.trim(),
      unidadMedida: _unidadController.text.trim().isEmpty
          ? 'pieza'
          : _unidadController.text.trim(),
      sku: sku,
      imagenUrl: _pendingImage != null || _removeImage
          ? ''
          : (widget.item?.imagenUrl ?? ''),
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

    setState(() => _isSaving = true);
    try {
      await ref.read(productosRepositoryProvider).upsert(payload);

      if (_pendingImage != null || _removeImage) {
        final access = await ref.read(activePlanAccessProvider.future);
        if (_canManageProductImages(access)) {
          final client = ref.read(supabaseClientProvider);
          final existingBucket = widget.item?.imagenBucket ?? '';
          final existingPath = widget.item?.imagenPath ?? '';

          if (existingBucket.trim().isNotEmpty &&
              existingPath.trim().isNotEmpty) {
            try {
              await client.storage.from(existingBucket).remove([existingPath]);
            } catch (_) {
              // Ignore storage cleanup errors.
            }
          }

          if (_removeImage) {
            await client.rpc(
              'update_producto_imagen',
              params: {
                'p_id': productId,
                'p_imagen_bucket': '',
                'p_imagen_path': '',
                'p_imagen_url': '',
              },
            );
          } else if (_pendingImage != null) {
            final empresaId =
                ref.read(workspaceStatusProvider).valueOrNull?.empresaId ??
                access.suscripcion.empresaId;
            final ext = _pendingImage!.extension;
            final mime = _pendingImage!.mimeType.trim().isEmpty
                ? 'image/$ext'
                : _pendingImage!.mimeType.trim();
            final path = '${empresaId.trim()}/$productId/main.$ext';

            await client.storage
                .from(_productImagesBucket)
                .uploadBinary(
                  path,
                  _pendingImage!.bytes,
                  fileOptions: FileOptions(contentType: mime, upsert: true),
                );
            final publicUrl = client.storage
                .from(_productImagesBucket)
                .getPublicUrl(path);
            await client.rpc(
              'update_producto_imagen',
              params: {
                'p_id': productId,
                'p_imagen_bucket': _productImagesBucket,
                'p_imagen_path': path,
                'p_imagen_url': publicUrl,
              },
            );
          }
        }
      }

      ref.invalidate(productosControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.item == null
            ? 'Producto creado correctamente.'
            : 'Producto actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo guardar el producto.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ProductTabButton extends StatelessWidget {
  _ProductTabButton({
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
        padding: EdgeInsets.only(bottom: 10),
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
  _ProductoSection({required this.title, required this.child, this.trailing});

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
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    trText(title),
                    style: TextStyle(
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
          Padding(padding: EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _ProductoFieldRow extends StatelessWidget {
  _ProductoFieldRow({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.helper,
    this.helperActionLabel,
    this.onHelperAction,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final String? helper;
  final String? helperActionLabel;
  final VoidCallback? onHelperAction;

  @override
  Widget build(BuildContext context) {
    final actionButton = helperActionLabel != null && onHelperAction != null
        ? Padding(
            padding: EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: onHelperAction,
              icon: Icon(Icons.layers_outlined, size: 16),
              label: Text(trText(helperActionLabel!)),
            ),
          )
        : null;

    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: suffixText == currentCurrencyCode() ? '0.00' : null,
            suffixText: suffixText == null ? null : trText(suffixText!),
            helperText: helper == null ? null : trText(helper!),
          ),
        ),
        if (actionButton != null) actionButton,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;

        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trText(label),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    field,
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
                          trText(label),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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

class _ProductoTypeFieldRow extends StatelessWidget {
  _ProductoTypeFieldRow({required this.value, required this.onChanged});

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
                    trText(type.label),
                    overflow: TextOverflow.ellipsis,
                    style: cotimaxDropdownTextStyle,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );

        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trText('Tipo'),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    field,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: Text(
                        trText('Tipo'),
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
  _ProductoDropdownFieldRow({
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
                    trText(option),
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
          padding: EdgeInsets.only(bottom: 10),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trText(label),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    field,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: Text(
                        label,
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

class _ProductoSwitchRow extends StatelessWidget {
  _ProductoSwitchRow({
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
          padding: EdgeInsets.only(bottom: 4),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (helper != null) ...[
                      SizedBox(height: 4),
                      Text(
                        helper!,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                    SizedBox(height: 8),
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
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (helper != null) ...[
                            SizedBox(height: 4),
                            Text(
                              helper!,
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
                    SizedBox(width: 8),
                    Switch(value: value, onChanged: onChanged),
                  ],
                ),
        );
      },
    );
  }
}

class _ProductoPriceRangesSection extends StatelessWidget {
  _ProductoPriceRangesSection({
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
        icon: Icon(Icons.add, size: 16),
        label: Text(trText('Agregar rango')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Define precios por cantidad cuando el producto use precio dinamico.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
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

class _ProductoCustomFieldRow extends StatelessWidget {
  _ProductoCustomFieldRow({
    required this.label,
    required this.child,
    this.labelSuffix,
  });

  final String label;
  final Widget child;
  final Widget? labelSuffix;

  Widget _buildLabel(TextStyle style) {
    if (labelSuffix == null) {
      return Text(trText(label), style: style);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(trText(label), style: style),
        labelSuffix!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final labelStyle = TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        );

        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(labelStyle),
                    SizedBox(height: 6),
                    child,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: _buildLabel(labelStyle),
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
        );
      },
    );
  }
}

class _ProductProfitSummary extends StatelessWidget {
  _ProductProfitSummary({
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
          _ProfitMetric(label: 'Precio', value: formatMoney(precio)),
          _ProfitMetric(label: 'Costo base', value: formatMoney(costoBase)),
          _ProfitMetric(
            label: 'Utilidad',
            value: formatMoney(utilidad),
            valueColor: utilidadColor,
          ),
        ],
      ),
    );
  }
}

class _ProfitMetric extends StatelessWidget {
  _ProfitMetric({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CompactFieldRow extends StatelessWidget {
  _CompactFieldRow({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactDropdownRow extends StatelessWidget {
  _CompactDropdownRow({
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
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
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
  _CompactSelectRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.emptyHintText = 'No hay datos.',
    this.emptyMessage,
    this.emptyButtonLabel,
    this.onEmptyPressed,
  });

  final String label;
  final String? value;
  final List<({String value, String label})> options;
  final ValueChanged<String?> onChanged;
  final String emptyHintText;
  final String? emptyMessage;
  final String? emptyButtonLabel;
  final VoidCallback? onEmptyPressed;

  @override
  Widget build(BuildContext context) {
    final hasOptions = options.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: hasOptions
                ? DropdownButtonFormField<String?>(
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
                  )
                : EmptyFieldState(
                    hintText: emptyHintText,
                    message:
                        emptyMessage ??
                        'No hay datos disponibles para este selector.',
                    buttonLabel: emptyButtonLabel ?? 'Agregar',
                    onPressed: onEmptyPressed ?? () {},
                  ),
          ),
        ],
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  _MaterialRow({
    required super.key,
    required this.index,
    required this.draft,
    required this.materialesCatalogo,
    required this.onTipoChanged,
    required this.onMaterialChanged,
    required this.onAddMaterial,
    this.onRemove,
  });

  final int index;
  final _MaterialDraft draft;
  final List<MaterialInsumo> materialesCatalogo;
  final ValueChanged<String?> onTipoChanged;
  final ValueChanged<String?> onMaterialChanged;
  final VoidCallback onAddMaterial;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isMaterial = draft.tipoController.text == 'Material';
    final materialOptions = [
      if (draft.materialId != null &&
          draft.nombreController.text.trim().isNotEmpty &&
          !materialesCatalogo.any(
            (material) => material.id == draft.materialId,
          ))
        (value: draft.materialId!, label: draft.nombreController.text.trim()),
      ...materialesCatalogo.map(
        (material) => (value: material.id, label: material.nombre),
      ),
    ];

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.close, size: 18),
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
              options: materialOptions,
              onChanged: onMaterialChanged,
              emptyHintText: 'No hay materiales registrados.',
              emptyMessage:
                  'No hay materiales registrados todavía. Crea uno nuevo para poder usarlo en este producto.',
              emptyButtonLabel: 'Crear material',
              onEmptyPressed: onAddMaterial,
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
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [
                    NumericTextInputFormatter(maxDecimalDigits: 2),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Costo unitario',
                  controller: draft.costoUnitarioController,
                  enabled: false,
                  suffixText: currentCurrencyCode(),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [
                    NumericTextInputFormatter(
                      useGrouping: true,
                      maxDecimalDigits: 2,
                      moneyInputBehavior: true,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Unidad de consumo',
                  controller: draft.unidadController,
                  enabled: false,
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
  _PrecioRangoRow({
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
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.close, size: 18),
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
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [
                    NumericTextInputFormatter(maxDecimalDigits: 2),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Hasta',
                  controller: draft.hastaController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [
                    NumericTextInputFormatter(maxDecimalDigits: 2),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _CompactFieldColumn(
                  label: 'Precio',
                  controller: draft.precioController,
                  suffixText: currentCurrencyCode(),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [
                    NumericTextInputFormatter(
                      useGrouping: true,
                      maxDecimalDigits: 2,
                      moneyInputBehavior: true,
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
  _CompactFieldColumn({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: suffixText == currentCurrencyCode() ? '0.00' : null,
            suffixText: suffixText,
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
