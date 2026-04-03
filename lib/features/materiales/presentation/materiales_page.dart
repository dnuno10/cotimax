import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/materiales/application/materiales_controller.dart';
import 'package:cotimax/features/productos/application/productos_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MaterialesPage extends ConsumerStatefulWidget {
  const MaterialesPage({super.key});

  @override
  ConsumerState<MaterialesPage> createState() => _MaterialesPageState();
}

class _MaterialesPageState extends ConsumerState<MaterialesPage> {
  bool _handledCreateRoute = false;

  @override
  Widget build(BuildContext context) {
    final materialesAsync = ref.watch(materialesControllerProvider);
    final shouldCreate =
        GoRouterState.of(context).uri.queryParameters['create'] == '1';

    if (!shouldCreate) {
      _handledCreateRoute = false;
    } else if (!_handledCreateRoute) {
      _handledCreateRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openForm(context, null);
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
              icon: const Icon(Icons.add),
              label: const Text('Nuevo material'),
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
                  hint: 'Buscar por nombre, SKU o proveedor',
                  onChanged: (value) =>
                      ref.read(materialesSearchProvider.notifier).state = value,
                ),
              ),
            ),
            const SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Tipo',
                value: 'Todos',
                options: [
                  'Todos',
                  'Materia prima',
                  'Consumible',
                  'Empaque',
                  'Componente',
                ],
              ),
            ),
            const SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Activo',
                value: 'Todos',
                options: ['Todos', 'Activos', 'Inactivos'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        materialesAsync.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No fue posible cargar materiales.',
            onRetry: () => ref.invalidate(materialesControllerProvider),
          ),
          data: (materiales) {
            final productosCatalogo =
                ref.watch(productosControllerProvider).valueOrNull ??
                const <ProductoServicio>[];
            if (materiales.isEmpty) {
              return const SectionCard(child: InlineEmptyMessage());
            }

            final productosMap = {
              for (final producto in productosCatalogo) producto.id: producto,
            };

            return CotimaxDataTable(
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Tipo')),
                DataColumn(label: Text('Unidad')),
                DataColumn(label: Text('Costo')),
                DataColumn(label: Text('Stock')),
                DataColumn(label: Text('Proveedor')),
                DataColumn(label: Text('Productos')),
                DataColumn(label: Text('Actualizado')),
                DataColumn(label: Text('Activo')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: materiales
                  .map(
                    (material) => DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(material.nombre),
                              Text(
                                material.sku,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(material.tipo)),
                        DataCell(Text(material.unidad)),
                        DataCell(
                          Text(
                            '\$${material.costoUnitario.toStringAsFixed(2)}',
                          ),
                        ),
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
                            DateFormat('dd/MM/yyyy').format(material.updatedAt),
                          ),
                        ),
                        DataCell(Text(material.activo ? 'Si' : 'No')),
                        DataCell(
                          RowActionMenu(
                            actions: [
                              PopupMenuItem(
                                value: 'edit',
                                child: const Text('Editar'),
                                onTap: () => _openForm(context, material),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: const Text('Eliminar'),
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

  void _openForm(BuildContext context, MaterialInsumo? material) {
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
    );
    if (!confirmed) return;

    try {
      await ref.read(materialesRepositoryProvider).delete(id);
      ref.invalidate(materialesControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(context, 'Material eliminado.');
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo eliminar el material.');
    }
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
  const _MaterialForm({this.material});

  final MaterialInsumo? material;

  @override
  ConsumerState<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends ConsumerState<_MaterialForm> {
  late final ScrollController _scrollController;
  int _tabIndex = 0;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _tipoController;
  late final TextEditingController _unidadController;
  late final TextEditingController _costoController;
  late final TextEditingController _stockController;
  late final TextEditingController _proveedorController;
  late final TextEditingController _skuController;
  late final TextEditingController _productosSearchController;
  bool _activo = true;
  late final Set<String> _productoIds;
  String _productosQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final material = widget.material;
    _nombreController = seededTextController(material?.nombre);
    _descripcionController = seededTextController(material?.descripcion ?? '');
    _tipoController = seededTextController(material?.tipo ?? 'Materia prima');
    _unidadController = seededTextController(material?.unidad ?? 'pieza');
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
    _proveedorController = seededTextController(material?.proveedor ?? '');
    _skuController = seededTextController(material?.sku);
    _productosSearchController = seededTextController();
    _activo = material?.activo ?? true;
    _productoIds = {...?material?.productoIds};
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _tipoController.dispose();
    _unidadController.dispose();
    _costoController.dispose();
    _stockController.dispose();
    _proveedorController.dispose();
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
            const SizedBox(width: 18),
            _MaterialTabButton(
              label: 'Productos relacionados',
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
              child: _tabIndex == 0 ? _buildCreateTab() : _buildProductsTab(),
            ),
          ),
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
            controller: _tipoController,
            dropdown: true,
          ),
          _MaterialFieldRow(
            label: 'Unidad de medida',
            controller: _unidadController,
            dropdown: true,
          ),
          _MaterialFieldRow(
            label: 'Costo unitario por unidad',
            controller: _costoController,
            suffixText: 'MXN',
            helper: 'Captura el costo de una sola unidad de medida.',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(useGrouping: true, maxDecimalDigits: 2),
            ],
          ),
          _MaterialFieldRow(
            label: 'Stock disponible',
            controller: _stockController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              NumericTextInputFormatter(maxDecimalDigits: 2),
            ],
          ),
          _MaterialFieldRow(
            label: 'Proveedor',
            controller: _proveedorController,
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
          const Text(
            'Selecciona los productos que requieren este material para su produccion.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SearchField(
            controller: _productosSearchController,
            hint: 'Buscar producto por nombre, SKU o categoria',
            onChanged: (value) =>
                setState(() => _productosQuery = value.trim()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: productos.isEmpty
                ? [
                    const Text(
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
          const SizedBox(height: 14),
          Text(
            _productoIds.isEmpty
                ? 'Sin productos relacionados'
                : '${_productoIds.length} producto(s) relacionados',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final material = MaterialInsumo(
      id: widget.material?.id ?? 'mat-${now.microsecondsSinceEpoch}',
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      tipo: _tipoController.text.trim().isEmpty
          ? 'Materia prima'
          : _tipoController.text.trim(),
      unidad: _unidadController.text.trim().isEmpty
          ? 'pieza'
          : _unidadController.text.trim(),
      costoUnitario: parseNumericText(_costoController.text) ?? 0,
      stockDisponible: parseNumericText(_stockController.text) ?? 0,
      proveedor: _proveedorController.text.trim(),
      sku: _skuController.text.trim(),
      productoIds: _productoIds.toList(),
      activo: _activo,
      createdAt: widget.material?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await ref.read(materialesRepositoryProvider).upsert(material);
      ref.invalidate(materialesControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.material == null
            ? 'Material creado correctamente.'
            : 'Material actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo guardar el material.');
    }
  }
}

class _MaterialTabButton extends StatelessWidget {
  const _MaterialTabButton({
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

class _MaterialSection extends StatelessWidget {
  const _MaterialSection({
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

class _MaterialFieldRow extends StatelessWidget {
  const _MaterialFieldRow({
    required this.label,
    required this.controller,
    this.dropdown = false,
    this.maxLines = 1,
    this.suffixText,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final bool dropdown;
  final int maxLines;
  final String? suffixText;
  final String? helper;
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
  }
}

class _MaterialSwitchRow extends StatelessWidget {
  const _MaterialSwitchRow({
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
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
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
