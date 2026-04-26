import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/materiales/application/materiales_controller.dart';
import 'package:cotimax/features/planes/application/plan_access.dart';
import 'package:cotimax/features/productos/application/productos_controller.dart';
import 'package:cotimax/features/proveedores/application/proveedores_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class _LocalizedChoice {
  const _LocalizedChoice({required this.canonical, required this.english});

  final String canonical;
  final String english;
}

const List<_LocalizedChoice> _materialTypeChoices = [
  _LocalizedChoice(canonical: 'Materia prima', english: 'Raw material'),
  _LocalizedChoice(canonical: 'Material base', english: 'Base material'),
  _LocalizedChoice(
    canonical: 'Material auxiliar',
    english: 'Auxiliary material',
  ),
  _LocalizedChoice(canonical: 'Consumible', english: 'Consumable'),
  _LocalizedChoice(canonical: 'Empaque', english: 'Packaging'),
  _LocalizedChoice(canonical: 'Embalaje', english: 'Packing'),
  _LocalizedChoice(canonical: 'Componente', english: 'Component'),
  _LocalizedChoice(canonical: 'Refacción', english: 'Spare part'),
  _LocalizedChoice(canonical: 'Insumo químico', english: 'Chemical input'),
  _LocalizedChoice(canonical: 'Insumo textil', english: 'Textile input'),
  _LocalizedChoice(canonical: 'Insumo eléctrico', english: 'Electrical input'),
  _LocalizedChoice(
    canonical: 'Insumo electrónico',
    english: 'Electronic input',
  ),
  _LocalizedChoice(canonical: 'Insumo metálico', english: 'Metal input'),
  _LocalizedChoice(canonical: 'Insumo plástico', english: 'Plastic input'),
  _LocalizedChoice(canonical: 'Insumo de madera', english: 'Wood input'),
  _LocalizedChoice(canonical: 'Insumo de vidrio', english: 'Glass input'),
  _LocalizedChoice(canonical: 'Adhesivo', english: 'Adhesive'),
  _LocalizedChoice(canonical: 'Pintura', english: 'Paint'),
  _LocalizedChoice(canonical: 'Recubrimiento', english: 'Coating'),
  _LocalizedChoice(canonical: 'Solvente', english: 'Solvent'),
  _LocalizedChoice(canonical: 'Lubricante', english: 'Lubricant'),
  _LocalizedChoice(canonical: 'Etiqueta', english: 'Label'),
  _LocalizedChoice(canonical: 'Accesorio', english: 'Accessory'),
  _LocalizedChoice(canonical: 'Herraje', english: 'Hardware'),
  _LocalizedChoice(canonical: 'Tornillería', english: 'Fasteners'),
  _LocalizedChoice(canonical: 'Cableado', english: 'Wiring'),
  _LocalizedChoice(canonical: 'Aislante', english: 'Insulation'),
  _LocalizedChoice(canonical: 'Otro', english: 'Other'),
];

const List<_LocalizedChoice> _materialUnitChoices = [
  _LocalizedChoice(canonical: 'pieza', english: 'piece'),
  _LocalizedChoice(canonical: 'caja', english: 'box'),
  _LocalizedChoice(canonical: 'paquete', english: 'package'),
  _LocalizedChoice(canonical: 'bolsa', english: 'bag'),
  _LocalizedChoice(canonical: 'rollo', english: 'roll'),
  _LocalizedChoice(canonical: 'hoja', english: 'sheet'),
  _LocalizedChoice(canonical: 'pliego', english: 'large sheet'),
  _LocalizedChoice(canonical: 'juego', english: 'set'),
  _LocalizedChoice(canonical: 'kit', english: 'kit'),
  _LocalizedChoice(canonical: 'par', english: 'pair'),
  _LocalizedChoice(canonical: 'docena', english: 'dozen'),
  _LocalizedChoice(canonical: 'ciento', english: 'hundred'),
  _LocalizedChoice(canonical: 'millar', english: 'thousand'),
  _LocalizedChoice(canonical: 'metro', english: 'meter'),
  _LocalizedChoice(canonical: 'centímetro', english: 'centimeter'),
  _LocalizedChoice(canonical: 'milímetro', english: 'millimeter'),
  _LocalizedChoice(canonical: 'kilómetro', english: 'kilometer'),
  _LocalizedChoice(canonical: 'metro cuadrado', english: 'square meter'),
  _LocalizedChoice(canonical: 'metro cúbico', english: 'cubic meter'),
  _LocalizedChoice(canonical: 'litro', english: 'liter'),
  _LocalizedChoice(canonical: 'mililitro', english: 'milliliter'),
  _LocalizedChoice(canonical: 'galón', english: 'gallon'),
  _LocalizedChoice(canonical: 'kilogramo', english: 'kilogram'),
  _LocalizedChoice(canonical: 'gramo', english: 'gram'),
  _LocalizedChoice(canonical: 'miligramo', english: 'milligram'),
  _LocalizedChoice(canonical: 'tonelada', english: 'ton'),
  _LocalizedChoice(canonical: 'onza', english: 'ounce'),
  _LocalizedChoice(canonical: 'libra', english: 'pound'),
  _LocalizedChoice(canonical: 'yarda', english: 'yard'),
  _LocalizedChoice(canonical: 'pie', english: 'foot'),
  _LocalizedChoice(canonical: 'pulgada', english: 'inch'),
  _LocalizedChoice(canonical: 'tambor', english: 'drum'),
  _LocalizedChoice(canonical: 'tarima', english: 'pallet'),
  _LocalizedChoice(canonical: 'contenedor', english: 'container'),
  _LocalizedChoice(canonical: 'bote', english: 'can'),
  _LocalizedChoice(canonical: 'frasco', english: 'jar'),
  _LocalizedChoice(canonical: 'tubo', english: 'tube'),
  _LocalizedChoice(canonical: 'Otra', english: 'Other'),
];

bool _matchesLocalizedChoice(String raw, _LocalizedChoice choice) {
  final normalized = raw.trim().toLowerCase();
  return normalized == choice.canonical.toLowerCase() ||
      normalized == choice.english.toLowerCase();
}

String? _matchLocalizedChoice(String? raw, List<_LocalizedChoice> choices) {
  if (raw == null || raw.trim().isEmpty) return null;
  for (final choice in choices) {
    if (_matchesLocalizedChoice(raw, choice)) {
      return choice.canonical;
    }
  }
  return null;
}

class MaterialesPage extends ConsumerStatefulWidget {
  MaterialesPage({super.key});

  @override
  ConsumerState<MaterialesPage> createState() => _MaterialesPageState();
}

class _MaterialesPageState extends ConsumerState<MaterialesPage> {
  bool _handledCreateRoute = false;
  final Set<String> _selectedMaterialIds = <String>{};
  String _tipoFilter = 'Todos';
  String _activoFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final materialesAsync = ref.watch(materialesControllerProvider);
    final shouldCreate =
        GoRouterState.of(context).uri.queryParameters['create'] == '1';

    if (!shouldCreate) {
      _handledCreateRoute = false;
    } else if (!_handledCreateRoute) {
      _handledCreateRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _openForm(context, null);
        if (mounted) {
          context.go(RoutePaths.materiales);
        }
      });
    }

    return ListView(
      children: [
        PageHeader(
          title: 'Materiales',
          subtitle: '',
          actions: [
            ...buildImportExportHeaderActions(
              context,
              entityLabel: 'materiales',
            ),
            ElevatedButton.icon(
              onPressed: () => _openForm(context, null),
              icon: Icon(Icons.add),
              label: Text(trText('Nuevo material')),
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
                  hint: 'Buscar por nombre, SKU o proveedor',
                  onChanged: (value) =>
                      ref.read(materialesSearchProvider.notifier).state = value,
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Tipo',
                value: _tipoFilter,
                options: [
                  'Todos',
                  ..._materialTypeChoices.map((choice) => choice.canonical),
                ],
                onChanged: (value) =>
                    setState(() => _tipoFilter = value ?? 'Todos'),
              ),
            ),
            SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Activo',
                value: _activoFilter,
                options: ['Todos', 'Activos', 'Inactivos'],
                onChanged: (value) =>
                    setState(() => _activoFilter = value ?? 'Todos'),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        materialesAsync.when(
          loading: () => LoadingStateWidget(message: 'Cargando materiales...'),
          error: (_, __) => ErrorStateWidget(
            message: 'No fue posible cargar materiales.',
            onRetry: () => ref.invalidate(materialesControllerProvider),
          ),
          data: (materiales) {
            if (materiales.isEmpty) {
              return EmptyStateWidget(
                title: 'Todavía no hay materiales',
                subtitle: 'Registra tu primer material para comenzar.',
                action: ElevatedButton.icon(
                  onPressed: () => _openForm(context, null),
                  icon: Icon(Icons.add),
                  label: Text(trText('Nuevo material')),
                ),
              );
            }

            final productosCatalogo =
                ref.watch(productosControllerProvider).valueOrNull ??
                const <ProductoServicio>[];
            final materialesFiltrados = materiales.where((material) {
              final matchesTipo = _tipoFilter == 'Todos'
                  ? true
                  : _tipoFilter == 'Otro'
                  ? _matchLocalizedChoice(
                          material.tipo,
                          _materialTypeChoices
                              .where((choice) => choice.canonical != 'Otro')
                              .toList(),
                        ) ==
                        null
                  : _matchesLocalizedChoice(
                      material.tipo,
                      _materialTypeChoices.firstWhere(
                        (choice) => choice.canonical == _tipoFilter,
                      ),
                    );
              final matchesActivo = _activoFilter == 'Todos'
                  ? true
                  : _activoFilter == 'Activos'
                  ? material.activo
                  : !material.activo;
              return matchesTipo && matchesActivo;
            }).toList();

            if (materialesFiltrados.isEmpty) {
              return SectionCard(
                child: InlineEmptyMessage(
                  message:
                      'No hay materiales que coincidan con los filtros actuales.',
                ),
              );
            }

            final productosMap = {
              for (final producto in productosCatalogo) producto.id: producto,
            };

            final allSelected =
                _selectedMaterialIds.length == materialesFiltrados.length;
            final partiallySelected =
                _selectedMaterialIds.isNotEmpty && !allSelected;

            return CotimaxDataTable(
              toolbar: _selectedMaterialIds.isEmpty
                  ? null
                  : TableSelectionToolbar(
                      count: _selectedMaterialIds.length,
                      entityLabel: 'material',
                      pluralLabel: 'materiales',
                      onEdit: _selectedMaterialIds.length == 1
                          ? () {
                              final material = materiales.firstWhere(
                                (item) => item.id == _selectedMaterialIds.first,
                              );
                              _openForm(context, material);
                            }
                          : null,
                      onDelete: _deleteSelectedMateriales,
                      onClear: () =>
                          setState(() => _selectedMaterialIds.clear()),
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
                          _selectedMaterialIds
                            ..clear()
                            ..addAll(
                              materialesFiltrados.map((item) => item.id),
                            );
                        } else {
                          _selectedMaterialIds.clear();
                        }
                      });
                    },
                  ),
                ),
                DataColumn(label: Text(trText('Nombre'))),
                DataColumn(label: Text(trText('Tipo'))),
                DataColumn(label: Text(trText('Unidad'))),
                DataColumn(label: Text(trText('Costo'))),
                DataColumn(label: Text(trText('Stock'))),
                DataColumn(label: Text(trText('Proveedor'))),
                DataColumn(label: Text(trText('Productos'))),
                DataColumn(label: Text(trText('Actualizado'))),
                DataColumn(label: Text(trText('Activo'))),
                DataColumn(label: Text(trText('Acciones'))),
              ],
              rows: materialesFiltrados
                  .map(
                    (material) => DataRow(
                      selected: _selectedMaterialIds.contains(material.id),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: _selectedMaterialIds.contains(material.id),
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selectedMaterialIds.add(material.id);
                                } else {
                                  _selectedMaterialIds.remove(material.id);
                                }
                              });
                            },
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                material.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              Text(
                                material.sku,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(trText(material.tipo))),
                        DataCell(Text(trText(material.unidad))),
                        DataCell(Text(formatMoney(material.costoUnitario))),
                        DataCell(
                          Text(material.stockDisponible.toStringAsFixed(0)),
                        ),
                        DataCell(Text(material.proveedor)),
                        DataCell(
                          Text(
                            _productLabels(material.productoIds, productosMap),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat(
                              'dd/MM/yyyy',
                              currentIntlLocale(),
                            ).format(material.updatedAt),
                          ),
                        ),
                        DataCell(Text(trText(material.activo ? 'Si' : 'No'))),
                        DataCell(
                          RowActionMenu(
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
                                onTap: () => _openForm(context, material),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(trText('Eliminar')),
                                onTap: () => _deleteMaterial(material.id),
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

  Future<void> _openForm(BuildContext context, MaterialInsumo? material) async {
    if (material == null) {
      final planAccess = await ref.read(activePlanAccessProvider.future);
      final materiales =
          ref.read(materialesControllerProvider).valueOrNull ??
          await ref.read(materialesControllerProvider.future);
      if (!mounted) return;
      if (hasReachedPlanLimit(
        limit: planAccess.plan.limiteMateriales,
        used: materiales?.length ?? 0,
      )) {
        await showPlanUpgradeDialog(
          context,
          title: 'Límite del plan Starter',
          message:
              'Tu plan Starter permite hasta 5 materiales. Actualiza a Pro para registrar más materiales.',
        );
        return;
      }
    }

    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: material == null ? 'Nuevo material' : 'Editar material',
        child: _MaterialForm(material: material),
      ),
    );
  }

  Future<void> _deleteMaterial(String id) async {
    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: 'material',
      dependencyEntityType: 'material',
      dependencyIds: [id],
      onConfirmAsync: () async {
        try {
          await ref.read(materialesRepositoryProvider).delete(id);
          ref.invalidate(materialesControllerProvider);
          ref.invalidate(productosControllerProvider);
          if (!mounted) return;
          ToastHelper.showSuccess(context, 'Material eliminado.');
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(error, 'No se pudo eliminar el material.'),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }

  Future<void> _deleteSelectedMateriales() async {
    final count = _selectedMaterialIds.length;
    if (count == 0) return;

    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: count == 1 ? 'material' : 'materiales seleccionados',
      title: count == 1 ? 'Eliminar material' : 'Eliminar materiales',
      message: count == 1
          ? '¿Estás seguro que quieres eliminar este material?'
          : '¿Estás seguro que quieres eliminar los $count materiales seleccionados?',
      dependencyEntityType: 'material',
      dependencyIds: _selectedMaterialIds.toList(),
      onConfirmAsync: () async {
        try {
          final ids = _selectedMaterialIds.toList();
          for (final id in ids) {
            await ref.read(materialesRepositoryProvider).delete(id);
          }
          ref.invalidate(materialesControllerProvider);
          ref.invalidate(productosControllerProvider);
          if (!mounted) return;
          setState(() => _selectedMaterialIds.clear());
          ToastHelper.showSuccess(
            context,
            count == 1
                ? 'Material eliminado.'
                : '$count materiales eliminados correctamente.',
          );
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(
              error,
              'No se pudieron eliminar los materiales.',
            ),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }

  String _productLabels(
    List<String> ids,
    Map<String, ProductoServicio> productosMap,
  ) {
    if (ids.isEmpty) return 'Sin relacion';
    return ids.map((id) => productosMap[id]?.nombre ?? id).take(2).join(', ');
  }
}

class _MaterialForm extends ConsumerStatefulWidget {
  _MaterialForm({this.material});

  final MaterialInsumo? material;

  @override
  ConsumerState<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends ConsumerState<_MaterialForm> {
  late final ScrollController _scrollController;
  int _tabIndex = 0;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _tipoOtroController;
  late final TextEditingController _unidadOtraController;
  late final TextEditingController _costoController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  late final TextEditingController _productosSearchController;
  bool _activo = true;
  late final Set<String> _productoIds;
  late String _selectedTipo;
  late String _selectedUnidad;
  String? _selectedProveedorId;
  String _productosQuery = '';
  bool _isSaving = false;
  bool _hasEditedProductoRelations = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final material = widget.material;
    _nombreController = seededTextController(material?.nombre);
    _descripcionController = seededTextController(material?.descripcion ?? '');
    final initialTipo = _matchLocalizedChoice(
      material?.tipo,
      _materialTypeChoices,
    );
    final initialUnidad = _matchLocalizedChoice(
      material?.unidad,
      _materialUnitChoices,
    );
    _selectedTipo =
        initialTipo ?? (material == null ? 'Materia prima' : 'Otro');
    _selectedUnidad = initialUnidad ?? (material == null ? 'pieza' : 'Otra');
    _tipoOtroController = seededTextController(
      initialTipo == null && material != null ? material.tipo : '',
    );
    _unidadOtraController = seededTextController(
      initialUnidad == null && material != null ? material.unidad : '',
    );
    _costoController = seededTextController(
      material == null
          ? ''
          : formatNumericValue(
              material.costoUnitario,
              decimalDigits: 2,
              useGrouping: true,
            ),
    );
    _stockController = seededTextController(
      material == null
          ? ''
          : formatNumericValue(material.stockDisponible, decimalDigits: 0),
    );
    _skuController = seededTextController(material?.sku);
    _productosSearchController = seededTextController();
    _activo = material?.activo ?? true;
    _productoIds = {...?material?.productoIds};
    _selectedProveedorId = material?.proveedorId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _tipoOtroController.dispose();
    _unidadOtraController.dispose();
    _costoController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _productosSearchController.dispose();
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
            _MaterialTabButton(
              label: 'Crear',
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            SizedBox(width: 18),
            _MaterialTabButton(
              label: 'Productos relacionados',
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(height: 1, color: AppColors.border),
        SizedBox(height: 10),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _tabIndex == 0 ? _buildCreateTab() : _buildProductsTab(),
            ),
          ),
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
                        widget.material == null
                            ? Icons.add_rounded
                            : Icons.save_rounded,
                      ),
                label: Text(
                  widget.material == null
                      ? 'Crear material'
                      : 'Guardar material',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateTab() {
    final proveedoresAsync = ref.watch(proveedoresControllerProvider);
    return _MaterialSection(
      title: widget.material == null ? 'Nuevo material' : 'Editar material',
      icon: FontAwesomeIcons.cubes,
      child: Column(
        children: [
          _MaterialFieldRow(label: 'Nombre *', controller: _nombreController),
          _MaterialFieldRow(
            label: 'Descripcion',
            controller: _descripcionController,
            maxLines: 4,
          ),
          _MaterialFieldRow(
            label: 'Tipo',
            child: DropdownButtonFormField<String>(
              initialValue: _selectedTipo,
              isExpanded: true,
              menuMaxHeight: 360,
              borderRadius: cotimaxMenuBorderRadius,
              dropdownColor: AppColors.white,
              icon: cotimaxDropdownIcon,
              style: cotimaxDropdownTextStyle,
              decoration: cotimaxDropdownDecoration(),
              items: _materialTypeChoices
                  .map(
                    (choice) => DropdownMenuItem<String>(
                      value: choice.canonical,
                      child: Text(
                        tr(choice.canonical, choice.english),
                        overflow: TextOverflow.ellipsis,
                        style: cotimaxDropdownTextStyle,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedTipo = value ?? 'Materia prima'),
            ),
          ),
          if (_selectedTipo == 'Otro')
            _MaterialFieldRow(
              label: 'Especifica el tipo de material',
              controller: _tipoOtroController,
            ),
          _MaterialFieldRow(
            label: 'Unidad de medida',
            child: DropdownButtonFormField<String>(
              initialValue: _selectedUnidad,
              isExpanded: true,
              menuMaxHeight: 360,
              borderRadius: cotimaxMenuBorderRadius,
              dropdownColor: AppColors.white,
              icon: cotimaxDropdownIcon,
              style: cotimaxDropdownTextStyle,
              decoration: cotimaxDropdownDecoration(),
              items: _materialUnitChoices
                  .map(
                    (choice) => DropdownMenuItem<String>(
                      value: choice.canonical,
                      child: Text(
                        tr(choice.canonical, choice.english),
                        overflow: TextOverflow.ellipsis,
                        style: cotimaxDropdownTextStyle,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedUnidad = value ?? 'pieza'),
            ),
          ),
          if (_selectedUnidad == 'Otra')
            _MaterialFieldRow(
              label: 'Especifica la unidad de medida',
              controller: _unidadOtraController,
            ),
          _MaterialFieldRow(
            label: 'Costo unitario por unidad',
            controller: _costoController,
            suffixText: currentCurrencyCode(),
            helper: 'Captura el costo de una sola unidad de medida.',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(
                useGrouping: true,
                maxDecimalDigits: 2,
                moneyInputBehavior: true,
              ),
            ],
          ),
          _MaterialFieldRow(
            label: 'Stock disponible',
            controller: _stockController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(maxDecimalDigits: 2),
            ],
          ),
          proveedoresAsync.when(
            loading: () => _MaterialFieldRow(
              label: 'Proveedor',
              child: SizedBox(
                height: 20,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (_, __) => _MaterialFieldRow(
              label: 'Proveedor',
              child: EmptyFieldState(
                hintText: 'No fue posible cargar proveedores.',
                message:
                    'Puedes dejar este campo vacío o intentar cargar los proveedores nuevamente.',
                buttonLabel: 'Agregar proveedor',
                onPressed: _goToCreateProvider,
              ),
            ),
            data: (proveedores) {
              if (proveedores.isEmpty) {
                return _MaterialFieldRow(
                  label: 'Proveedor',
                  child: EmptyFieldState(
                    hintText: 'No hay proveedores registrados.',
                    message:
                        'Puedes dejar este campo vacío o registrar un proveedor para vincularlo a este material.',
                    buttonLabel: 'Agregar proveedor',
                    onPressed: _goToCreateProvider,
                  ),
                );
              }

              final resolvedProveedorId = _resolveProveedorId(proveedores);
              return _MaterialFieldRow(
                label: 'Proveedor',
                child: DropdownButtonFormField<String>(
                  initialValue: resolvedProveedorId ?? '',
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
                        tr('Sin proveedor', 'No supplier'),
                        overflow: TextOverflow.ellipsis,
                        style: cotimaxDropdownTextStyle,
                      ),
                    ),
                    ...proveedores.map(
                      (proveedor) => DropdownMenuItem<String>(
                        value: proveedor.id,
                        child: Text(
                          proveedor.nombre.trim().isEmpty
                              ? proveedor.empresa
                              : proveedor.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: cotimaxDropdownTextStyle,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedProveedorId = value ?? '';
                  }),
                ),
              );
            },
          ),
          _MaterialFieldRow(label: 'SKU', controller: _skuController),
          _MaterialSwitchRow(
            label: 'Material activo',
            value: _activo,
            onChanged: (value) => setState(() => _activo = value),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final productosCatalogo =
        ref.watch(productosControllerProvider).valueOrNull ??
        const <ProductoServicio>[];
    if (productosCatalogo.isEmpty) {
      return _MaterialSection(
        title: 'Relacion con productos',
        icon: FontAwesomeIcons.boxOpen,
        child: EmptyFieldState(
          hintText: trText('No hay productos registrados.'),
          message: 'No hay datos para relacionar este material con productos.',
          buttonLabel: 'Agregar producto',
          onPressed: _goToCreateProduct,
        ),
      );
    }

    final productos = productosCatalogo.where((producto) {
      if (_productosQuery.isEmpty) return true;
      final query = _productosQuery.toLowerCase();
      return producto.nombre.toLowerCase().contains(query) ||
          producto.sku.toLowerCase().contains(query) ||
          producto.categoriaId.toLowerCase().contains(query);
    }).toList();

    return _MaterialSection(
      title: 'Relacion con productos',
      icon: FontAwesomeIcons.boxOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona los productos que requieren este material para su produccion.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          SearchField(
            controller: _productosSearchController,
            hint: 'Buscar producto por nombre, SKU o categoria',
            onChanged: (value) =>
                setState(() => _productosQuery = value.trim()),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: productos.isEmpty
                ? [
                    Text(
                      'No hay productos que coincidan con la busqueda.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                : productos
                      .map(
                        (producto) => FilterChip(
                          selected: _productoIds.contains(producto.id),
                          label: Text(producto.nombre),
                          onSelected: (_) => setState(() {
                            _hasEditedProductoRelations = true;
                            if (_productoIds.contains(producto.id)) {
                              _productoIds.remove(producto.id);
                            } else {
                              _productoIds.add(producto.id);
                            }
                          }),
                        ),
                      )
                      .toList(),
          ),
          SizedBox(height: 14),
          Text(
            _productoIds.isEmpty
                ? 'Sin productos relacionados'
                : '${_productoIds.length} producto(s) relacionados',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _goToCreateProduct() {
    context.go('${RoutePaths.productos}?create=1');
  }

  void _goToCreateProvider() {
    context.go('${RoutePaths.proveedores}?create=1');
  }

  String? _resolveProveedorId(List<Proveedor> proveedores) {
    if (_selectedProveedorId != null && _selectedProveedorId!.isEmpty) {
      return null;
    }
    if (_selectedProveedorId != null &&
        proveedores.any((proveedor) => proveedor.id == _selectedProveedorId)) {
      return _selectedProveedorId;
    }
    final existingName = widget.material?.proveedor.trim() ?? '';
    if (existingName.isEmpty) return null;
    for (final proveedor in proveedores) {
      final providerName =
          (proveedor.nombre.trim().isEmpty
                  ? proveedor.empresa
                  : proveedor.nombre)
              .trim()
              .toLowerCase();
      if (providerName == existingName.toLowerCase()) {
        return proveedor.id;
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_selectedTipo == 'Otro' && _tipoOtroController.text.trim().isEmpty) {
      ToastHelper.showError(
        context,
        tr('Especifica el tipo de material.', 'Specify the material type.'),
      );
      return;
    }
    if (_selectedUnidad == 'Otra' &&
        _unidadOtraController.text.trim().isEmpty) {
      ToastHelper.showError(
        context,
        tr('Especifica la unidad de medida.', 'Specify the unit of measure.'),
      );
      return;
    }

    final now = DateTime.now();
    if (widget.material == null) {
      final planAccess = await ref.read(activePlanAccessProvider.future);
      final materiales =
          ref.read(materialesControllerProvider).valueOrNull ??
          const <MaterialInsumo>[];
      if (hasReachedPlanLimit(
        limit: planAccess.plan.limiteMateriales,
        used: materiales.length,
      )) {
        if (!mounted) return;
        await showPlanUpgradeDialog(
          context,
          title: 'Límite del plan Starter',
          message:
              'Tu plan Starter permite hasta 5 materiales. Actualiza a Pro para registrar más materiales.',
        );
        return;
      }
    }
    final proveedores =
        ref.read(proveedoresControllerProvider).valueOrNull ??
        const <Proveedor>[];
    final resolvedProveedorId = _resolveProveedorId(proveedores);
    Proveedor? proveedor;
    if (resolvedProveedorId != null) {
      for (final item in proveedores) {
        if (item.id == resolvedProveedorId) {
          proveedor = item;
          break;
        }
      }
    }
    final material = MaterialInsumo(
      id: widget.material?.id ?? 'mat-${now.microsecondsSinceEpoch}',
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      tipo: _selectedTipo == 'Otro'
          ? _tipoOtroController.text.trim()
          : _selectedTipo,
      unidad: _selectedUnidad == 'Otra'
          ? _unidadOtraController.text.trim()
          : _selectedUnidad,
      costoUnitario: parseNumericText(_costoController.text) ?? 0,
      stockDisponible: parseNumericText(_stockController.text) ?? 0,
      proveedorId: resolvedProveedorId,
      proveedor: proveedor == null
          ? ''
          : (proveedor.nombre.trim().isEmpty
                ? proveedor.empresa
                : proveedor.nombre),
      sku: _skuController.text.trim(),
      productoIds: _productoIds.toList(),
      activo: _activo,
      createdAt: widget.material?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
    try {
      final shouldSyncProductoIds =
          widget.material == null || _hasEditedProductoRelations;
      await ref
          .read(materialesRepositoryProvider)
          .upsert(material, syncProductoIds: shouldSyncProductoIds);
      ref.invalidate(materialesControllerProvider);
      ref.invalidate(productosControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.material == null
            ? 'Material creado correctamente.'
            : 'Material actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo guardar el material.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _MaterialTabButton extends StatelessWidget {
  _MaterialTabButton({
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

class _MaterialSection extends StatelessWidget {
  _MaterialSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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
                  child: Row(
                    children: [
                      FaIcon(icon, size: 14, color: AppColors.textPrimary),
                      SizedBox(width: 8),
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
                    ],
                  ),
                ),
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

class _MaterialFieldRow extends StatelessWidget {
  _MaterialFieldRow({
    required this.label,
    this.controller,
    this.child,
    this.maxLines = 1,
    this.suffixText,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final Widget? child;
  final int maxLines;
  final String? suffixText;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
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
          Expanded(
            child:
                child ??
                TextFormField(
                  controller: controller,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    hintText: suffixText == currentCurrencyCode()
                        ? '0.00'
                        : null,
                    suffixText: suffixText == null ? null : trText(suffixText!),
                    helperText: helper == null ? null : trText(helper!),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _MaterialSwitchRow extends StatelessWidget {
  _MaterialSwitchRow({
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
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
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
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
