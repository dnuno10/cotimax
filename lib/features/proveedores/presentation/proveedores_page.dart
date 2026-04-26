import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/gastos/application/gastos_controller.dart';
import 'package:cotimax/features/materiales/application/materiales_controller.dart';
import 'package:cotimax/features/proveedores/application/proveedores_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProveedoresPage extends ConsumerStatefulWidget {
  ProveedoresPage({super.key});

  @override
  ConsumerState<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends ConsumerState<ProveedoresPage> {
  bool _handledCreateRoute = false;
  final Set<String> _selectedProveedorIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final proveedoresAsync = ref.watch(proveedoresControllerProvider);
    final shouldCreate =
        GoRouterState.of(context).uri.queryParameters['create'] == '1';

    if (!shouldCreate) {
      _handledCreateRoute = false;
    } else if (!_handledCreateRoute) {
      _handledCreateRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _openForm(context, null);
        if (mounted) {
          context.go(RoutePaths.proveedores);
        }
      });
    }

    return ListView(
      children: [
        PageHeader(
          title: 'Proveedores',
          subtitle: '',
          actions: [
            ...buildImportExportHeaderActions(
              context,
              entityLabel: 'proveedores',
            ),
            ElevatedButton.icon(
              onPressed: () => _openForm(context, null),
              icon: Icon(Icons.add),
              label: Text(trText('Nuevo proveedor')),
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
                  hint: 'Buscar por nombre, empresa, RFC o correo',
                  onChanged: (value) =>
                      ref.read(proveedoresSearchProvider.notifier).state =
                          value,
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Estatus',
                value: 'Todos',
                options: ['Todos', 'Activos', 'Inactivos'],
              ),
            ),
            SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Origen',
                value: 'Todos',
                options: ['Todos', 'Con empresa', 'Sin empresa'],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        proveedoresAsync.when(
          loading: () => LoadingStateWidget(message: 'Cargando proveedores...'),
          error: (_, __) => ErrorStateWidget(
            message: 'No fue posible cargar proveedores.',
            onRetry: () => ref.invalidate(proveedoresControllerProvider),
          ),
          data: (proveedores) {
            if (proveedores.isEmpty) {
              return EmptyStateWidget(
                title: 'Todavía no hay proveedores',
                subtitle: 'Registra tu primer proveedor para comenzar.',
                action: ElevatedButton.icon(
                  onPressed: () => _openForm(context, null),
                  icon: Icon(Icons.add),
                  label: Text(trText('Nuevo proveedor')),
                ),
              );
            }

            final allSelected =
                _selectedProveedorIds.length == proveedores.length;
            final partiallySelected =
                _selectedProveedorIds.isNotEmpty && !allSelected;

            return CotimaxDataTable(
              toolbar: _selectedProveedorIds.isEmpty
                  ? null
                  : TableSelectionToolbar(
                      count: _selectedProveedorIds.length,
                      entityLabel: 'proveedor',
                      onEdit: _selectedProveedorIds.length == 1
                          ? () {
                              final proveedor = proveedores.firstWhere(
                                (item) =>
                                    item.id == _selectedProveedorIds.first,
                              );
                              _openForm(context, proveedor);
                            }
                          : null,
                      onDelete: _deleteSelectedProveedores,
                      onClear: () =>
                          setState(() => _selectedProveedorIds.clear()),
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
                          _selectedProveedorIds
                            ..clear()
                            ..addAll(proveedores.map((item) => item.id));
                        } else {
                          _selectedProveedorIds.clear();
                        }
                      });
                    },
                  ),
                ),
                DataColumn(label: Text(trText('Nombre'))),
                DataColumn(label: Text(trText('Empresa'))),
                DataColumn(label: Text(trText('RFC'))),
                DataColumn(label: Text(trText('Contacto'))),
                DataColumn(label: Text(trText('Teléfono'))),
                DataColumn(label: Text(trText('Correo'))),
                DataColumn(label: Text(trText('Estatus'))),
                DataColumn(label: Text(trText('Actualizado'))),
                DataColumn(label: Text(trText('Acciones'))),
              ],
              rows: proveedores
                  .map(
                    (proveedor) => DataRow(
                      selected: _selectedProveedorIds.contains(proveedor.id),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: _selectedProveedorIds.contains(proveedor.id),
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selectedProveedorIds.add(proveedor.id);
                                } else {
                                  _selectedProveedorIds.remove(proveedor.id);
                                }
                              });
                            },
                          ),
                        ),
                        DataCell(Text(proveedor.nombre)),
                        DataCell(Text(proveedor.empresa)),
                        DataCell(Text(proveedor.rfc)),
                        DataCell(Text(proveedor.contacto)),
                        DataCell(Text(proveedor.telefono)),
                        DataCell(Text(proveedor.correo)),
                        DataCell(
                          Text(
                            trText(proveedor.activo ? 'Activo' : 'Inactivo'),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${proveedor.updatedAt.day}/${proveedor.updatedAt.month}/${proveedor.updatedAt.year}',
                          ),
                        ),
                        DataCell(
                          RowActionMenu(
                            onSelected: (action) =>
                                _onRowAction(context, proveedor, action),
                            actions: [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(trText('Editar')),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  trText(
                                    proveedor.activo ? 'Desactivar' : 'Activar',
                                  ),
                                ),
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

  void _openForm(BuildContext context, Proveedor? proveedor) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: proveedor == null ? 'Nuevo proveedor' : 'Editar proveedor',
        child: _ProveedorForm(proveedor: proveedor),
      ),
    );
  }

  Future<void> _toggleProveedor(Proveedor proveedor) async {
    try {
      await ref.read(proveedoresRepositoryProvider).toggle(proveedor.id);
      ref.invalidate(proveedoresControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        proveedor.activo ? 'Proveedor desactivado.' : 'Proveedor activado.',
      );
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo actualizar el proveedor.'),
      );
    }
  }

  Future<void> _deleteProveedor(Proveedor proveedor) async {
    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: 'proveedor',
      dependencyEntityType: 'proveedor',
      dependencyIds: [proveedor.id],
      onConfirmAsync: () async {
        try {
          await ref.read(proveedoresRepositoryProvider).delete(proveedor.id);
          ref.invalidate(proveedoresControllerProvider);
          ref.invalidate(gastosControllerProvider);
          ref.invalidate(materialesControllerProvider);
          if (!mounted) return;
          ToastHelper.showSuccess(context, 'Proveedor eliminado.');
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(error, 'No se pudo eliminar el proveedor.'),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }

  Future<void> _deleteSelectedProveedores() async {
    final count = _selectedProveedorIds.length;
    if (count == 0) return;

    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: count == 1 ? 'proveedor' : 'proveedores seleccionados',
      title: count == 1 ? 'Eliminar proveedor' : 'Eliminar proveedores',
      message: count == 1
          ? '¿Estás seguro que quieres eliminar este proveedor?'
          : '¿Estás seguro que quieres eliminar los $count proveedores seleccionados?',
      dependencyEntityType: 'proveedor',
      dependencyIds: _selectedProveedorIds.toList(),
      onConfirmAsync: () async {
        try {
          final ids = _selectedProveedorIds.toList();
          for (final id in ids) {
            await ref.read(proveedoresRepositoryProvider).delete(id);
          }
          ref.invalidate(proveedoresControllerProvider);
          ref.invalidate(gastosControllerProvider);
          ref.invalidate(materialesControllerProvider);
          if (!mounted) return;
          setState(() => _selectedProveedorIds.clear());
          ToastHelper.showSuccess(
            context,
            count == 1
                ? 'Proveedor eliminado.'
                : '$count proveedores eliminados correctamente.',
          );
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(
              error,
              'No se pudieron eliminar los proveedores.',
            ),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }

  void _onRowAction(BuildContext context, Proveedor proveedor, String action) {
    switch (action) {
      case 'edit':
        _openForm(context, proveedor);
        return;
      case 'toggle':
        _toggleProveedor(proveedor);
        return;
      case 'delete':
        _deleteProveedor(proveedor);
        return;
    }
  }
}

class _ProveedorForm extends ConsumerStatefulWidget {
  _ProveedorForm({this.proveedor});

  final Proveedor? proveedor;

  @override
  ConsumerState<_ProveedorForm> createState() => _ProveedorFormState();
}

class _ProveedorFormState extends ConsumerState<_ProveedorForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _empresaController;
  late final TextEditingController _numeroController;
  late final TextEditingController _rfcController;
  late final TextEditingController _sitioWebController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _routingController;
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoContactoController;
  bool _isSaving = false;
  bool _ivaValido = false;
  bool _exentoImpuestos = false;
  bool _activo = true;
  bool _numeroAutofilled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final proveedor = widget.proveedor;
    final contactParts = proveedor?.contacto.trim().split(RegExp(r'\s+')) ?? [];
    _empresaController = seededTextController(proveedor?.empresa);
    _numeroController = seededTextController(proveedor?.numero);
    _rfcController = seededTextController(proveedor?.rfc);
    _sitioWebController = seededTextController();
    _telefonoController = seededTextController(proveedor?.telefono ?? '');
    _routingController = seededTextController();
    _nombresController = seededTextController(
      contactParts.isEmpty ? '' : contactParts.first,
    );
    _apellidosController = seededTextController(
      contactParts.length > 1 ? contactParts.skip(1).join(' ') : '',
    );
    _correoController = seededTextController(proveedor?.correo);
    _telefonoContactoController = seededTextController(
      proveedor?.telefono ?? '',
    );
    _activo = proveedor?.activo ?? true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _empresaController.dispose();
    _numeroController.dispose();
    _rfcController.dispose();
    _sitioWebController.dispose();
    _telefonoController.dispose();
    _routingController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _telefonoContactoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proveedoresExistentes =
        ref.watch(proveedoresCatalogControllerProvider).valueOrNull ??
        const <Proveedor>[];
    final numeroSugerido = nextSequentialValue(
      proveedoresExistentes
          .where((item) => item.id != widget.proveedor?.id)
          .map((item) => item.numero),
    );

    if (!_numeroAutofilled && _numeroController.text.trim().isEmpty) {
      assignControllerText(_numeroController, numeroSugerido);
      _numeroAutofilled = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [_ProviderTabButton(label: 'Crear', selected: true)],
        ),
        SizedBox(height: 8),
        Container(height: 1, color: AppColors.border),
        SizedBox(height: 10),
        Expanded(
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _buildCreateTab(numeroSugerido),
              ),
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
                        widget.proveedor == null
                            ? Icons.add_rounded
                            : Icons.save_rounded,
                      ),
                label: Text(
                  widget.proveedor == null
                      ? 'Crear proveedor'
                      : 'Guardar proveedor',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateTab(String numeroSugerido) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final left = _ProviderSection(
          title: 'Detalles de la empresa',
          icon: FontAwesomeIcons.building,
          headerBackgroundColor: AppColors.background,
          child: Column(
            children: [
              _ProviderFieldRow(
                label: 'Nombre de la empresa',
                controller: _empresaController,
              ),
              _ProviderFieldRow(
                label: 'Número de proveedor (automático)',
                controller: _numeroController,
                hintText: tr(
                  'Se asignará automáticamente: $numeroSugerido',
                  'It will be assigned automatically: $numeroSugerido',
                ),
                helperText:
                    'Si lo dejas vacío, se asigna el consecutivo $numeroSugerido.',
              ),
              _ProviderFieldRow(label: 'CIF/NIF', controller: _rfcController),
              _ProviderFieldRow(
                label: 'Sitio web',
                controller: _sitioWebController,
              ),
              _ProviderFieldRow(
                label: 'Teléfono',
                controller: _telefonoController,
              ),
              _ProviderFieldRow(
                label: 'Id. de enrutamiento',
                controller: _routingController,
              ),
              _ProviderSwitchRow(
                label: 'Número de IVA válido',
                value: _ivaValido,
                onChanged: (value) => setState(() => _ivaValido = value),
              ),
              _ProviderSwitchRow(
                label: 'Exento de impuestos',
                value: _exentoImpuestos,
                onChanged: (value) => setState(() => _exentoImpuestos = value),
              ),
              _ProviderSwitchRow(
                label: 'Proveedor activo',
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
              ),
            ],
          ),
        );

        final right = Column(
          children: [
            _ProviderSection(
              title: 'Contactos',
              icon: FontAwesomeIcons.addressBook,
              headerBackgroundColor: AppColors.background,
              child: Column(
                children: [
                  _ProviderFieldRow(
                    label: 'Nombres',
                    controller: _nombresController,
                  ),
                  _ProviderFieldRow(
                    label: 'Apellidos',
                    controller: _apellidosController,
                  ),
                  _ProviderFieldRow(
                    label: 'Correo electrónico',
                    controller: _correoController,
                  ),
                  _ProviderFieldRow(
                    label: 'Teléfono',
                    controller: _telefonoContactoController,
                  ),
                ],
              ),
            ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: 10),
              Expanded(child: right),
            ],
          );
        }

        return Column(children: [left, SizedBox(height: 10), right]);
      },
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final now = DateTime.now();
    final nombres = _nombresController.text.trim();
    if (nombres.isEmpty) {
      ToastHelper.showWarning(context, 'Ingresa los nombres del contacto.');
      return;
    }

    final proveedoresExistentes =
        ref.read(proveedoresCatalogControllerProvider).valueOrNull ??
        const <Proveedor>[];
    final numeroIngresado = _numeroController.text.trim();
    final numeroDefinitivo = numeroIngresado.isNotEmpty
        ? numeroIngresado
        : nextSequentialValue(
            proveedoresExistentes
                .where((item) => item.id != widget.proveedor?.id)
                .map((item) => item.numero),
          );
    final numeroDuplicado = proveedoresExistentes.any(
      (item) =>
          item.id != widget.proveedor?.id &&
          item.numero.trim().isNotEmpty &&
          sequenceValuesMatch(item.numero, numeroDefinitivo),
    );
    if (numeroDuplicado) {
      ToastHelper.showWarning(context, 'El número de proveedor ya existe.');
      return;
    }

    final nombreContacto = [
      nombres,
      _apellidosController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    final proveedor = Proveedor(
      id: widget.proveedor?.id ?? 'prov-${now.microsecondsSinceEpoch}',
      numero: numeroDefinitivo,
      idNumber: widget.proveedor?.idNumber ?? '',
      nombre: nombreContacto,
      empresa: _empresaController.text.trim(),
      rfc: _rfcController.text.trim(),
      contacto: nombreContacto,
      telefono: _telefonoController.text.trim(),
      correo: _correoController.text.trim(),
      direccion: widget.proveedor?.direccion ?? '',
      notas: '',
      activo: _activo,
      createdAt: widget.proveedor?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(proveedoresRepositoryProvider).upsert(proveedor);
      ref.invalidate(proveedoresControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.proveedor == null
            ? 'Proveedor creado correctamente.'
            : 'Proveedor actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo guardar el proveedor.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ProviderTabButton extends StatelessWidget {
  const _ProviderTabButton({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ProviderSection extends StatelessWidget {
  _ProviderSection({
    required this.title,
    required this.icon,
    required this.child,
    this.headerBackgroundColor,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color? headerBackgroundColor;

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
              color: headerBackgroundColor,
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

class _ProviderFieldRow extends StatelessWidget {
  _ProviderFieldRow({
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 165,
            child: Text(
              trText(label),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              decoration: InputDecoration(
                hintText: hintText == null ? null : trText(hintText!),
                helperText: helperText == null ? null : trText(helperText!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderSwitchRow extends StatelessWidget {
  _ProviderSwitchRow({
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
            width: 165,
            child: Text(
              trText(label),
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
