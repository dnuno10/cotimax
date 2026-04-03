import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/clientes/application/clientes_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
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
    final clientesAsync = ref.watch(clientesControllerProvider);
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
        _openForm(context, null);
        if (mounted) {
          context.go(RoutePaths.clientes);
        }
      });
    }

    return ListView(
      children: [
        PageHeader(
          title: 'Clientes',
          subtitle: '',
          actions: [
            ...buildImportExportHeaderActions(context, entityLabel: 'clientes'),
            ElevatedButton.icon(
              onPressed: () => _openForm(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo cliente'),
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
                  hint: 'Buscar por nombre, empresa, RFC o correo',
                  onChanged: (value) =>
                      ref.read(clientesSearchProvider.notifier).state = value,
                ),
              ),
            ),
            const SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Estatus',
                value: 'Todos',
                options: ['Todos', 'Activos', 'Inactivos'],
              ),
            ),
            const SizedBox(
              width: 220,
              child: SelectField<String>(
                label: 'Origen',
                value: 'Todos',
                options: ['Todos', 'Con empresa', 'Sin empresa'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        clientesAsync.when(
          loading: LoadingSkeleton.new,
          error: (_, __) => ErrorStateWidget(
            message: 'No fue posible cargar clientes.',
            onRetry: () => ref.invalidate(clientesControllerProvider),
          ),
          data: (clientes) {
            if (clientes.isEmpty) {
              return const SectionCard(child: InlineEmptyMessage());
            }

            return CotimaxDataTable(
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Empresa')),
                DataColumn(label: Text('RFC')),
                DataColumn(label: Text('Contacto')),
                DataColumn(label: Text('Teléfono')),
                DataColumn(label: Text('Correo')),
                DataColumn(label: Text('Estatus')),
                DataColumn(label: Text('Actualizado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: clientes
                  .map(
                    (cliente) => DataRow(
                      cells: [
                        DataCell(Text(cliente.nombre)),
                        DataCell(Text(cliente.empresa)),
                        DataCell(Text(cliente.rfc)),
                        DataCell(Text(cliente.contacto)),
                        DataCell(Text(cliente.telefono)),
                        DataCell(Text(cliente.correo)),
                        DataCell(Text(cliente.activo ? 'Activo' : 'Inactivo')),
                        DataCell(
                          Text(
                            '${cliente.updatedAt.day}/${cliente.updatedAt.month}/${cliente.updatedAt.year}',
                          ),
                        ),
                        DataCell(
                          RowActionMenu(
                            onSelected: (action) =>
                                _onRowAction(context, cliente, action),
                            actions: [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  cliente.activo ? 'Desactivar' : 'Activar',
                                ),
                              ),
                              const PopupMenuItem(
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

  void _openForm(BuildContext context, Cliente? cliente) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalBase(
        title: cliente == null ? 'Nuevo cliente' : 'Editar cliente',
        child: _ClienteForm(cliente: cliente),
      ),
    );
  }

  Future<void> _toggleCliente(Cliente cliente) async {
    try {
      await ref.read(clientesRepositoryProvider).toggle(cliente.id);
      ref.invalidate(clientesControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        cliente.activo ? 'Cliente desactivado.' : 'Cliente activado.',
      );
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo actualizar el cliente.');
    }
  }

  Future<void> _deleteCliente(Cliente cliente) async {
    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: 'cliente',
    );
    if (!confirmed) return;

    try {
      await ref.read(clientesRepositoryProvider).delete(cliente.id);
      ref.invalidate(clientesControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(context, 'Cliente eliminado.');
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo eliminar el cliente.');
    }
  }

  void _onRowAction(BuildContext context, Cliente cliente, String action) {
    switch (action) {
      case 'edit':
        _openForm(context, cliente);
        return;
      case 'toggle':
        _toggleCliente(cliente);
        return;
      case 'delete':
        _deleteCliente(cliente);
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
      ref.read(clientesSearchProvider.notifier).state = routeQuery;
    });
  }
}

class _ClienteForm extends ConsumerStatefulWidget {
  const _ClienteForm({this.cliente});

  final Cliente? cliente;

  @override
  ConsumerState<_ClienteForm> createState() => _ClienteFormState();
}

class _ClienteFormState extends ConsumerState<_ClienteForm> {
  late final ScrollController _scrollController;
  late final TextEditingController _empresaController;
  late final TextEditingController _numeroController;
  late final TextEditingController _rfcController;
  late final TextEditingController _sitioWebController;
  late final TextEditingController _telefonoEmpresaController;
  late final TextEditingController _routingController;
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoContactoController;
  late final TextEditingController _calleController;
  late final TextEditingController _apartamentoController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _estadoController;
  late final TextEditingController _codigoPostalController;
  late final TextEditingController _paisController;
  late final TextEditingController _notasController;
  bool _ivaValido = false;
  bool _exentoImpuestos = false;
  bool _activo = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final cliente = widget.cliente;
    final contactParts = cliente?.contacto.trim().split(RegExp(r'\s+')) ?? [];
    _empresaController = seededTextController(cliente?.empresa);
    _numeroController = seededTextController(cliente?.numero);
    _rfcController = seededTextController(cliente?.rfc);
    _sitioWebController = seededTextController();
    _telefonoEmpresaController = seededTextController(cliente?.telefono);
    _routingController = seededTextController();
    _nombresController = seededTextController(
      contactParts.isEmpty ? '' : contactParts.first,
    );
    _apellidosController = seededTextController(
      contactParts.length > 1 ? contactParts.skip(1).join(' ') : '',
    );
    _correoController = seededTextController(cliente?.correo);
    _telefonoContactoController = seededTextController(cliente?.telefono);
    _calleController = seededTextController(cliente?.direccion);
    _apartamentoController = seededTextController();
    _ciudadController = seededTextController();
    _estadoController = seededTextController();
    _codigoPostalController = seededTextController();
    _paisController = seededTextController();
    _notasController = seededTextController(cliente?.notas);
    _activo = cliente?.activo ?? true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _empresaController.dispose();
    _numeroController.dispose();
    _rfcController.dispose();
    _sitioWebController.dispose();
    _telefonoEmpresaController.dispose();
    _routingController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _telefonoContactoController.dispose();
    _calleController.dispose();
    _apartamentoController.dispose();
    _ciudadController.dispose();
    _estadoController.dispose();
    _codigoPostalController.dispose();
    _paisController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesExistentes =
        ref.watch(clientesControllerProvider).valueOrNull ?? const <Cliente>[];
    final numeroSugerido = nextSequentialValue(
      clientesExistentes
          .where((item) => item.id != widget.cliente?.id)
          .map((item) => item.numero),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _ClientTabButton(
              label: 'Crear',
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            const SizedBox(width: 18),
            _ClientTabButton(
              label: 'Configuración',
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        Expanded(
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _tabIndex == 0
                    ? _ClientCreateTab(
                        empresaController: _empresaController,
                        numeroController: _numeroController,
                        numeroSugerido: numeroSugerido,
                        rfcController: _rfcController,
                        sitioWebController: _sitioWebController,
                        telefonoEmpresaController: _telefonoEmpresaController,
                        routingController: _routingController,
                        nombresController: _nombresController,
                        apellidosController: _apellidosController,
                        correoController: _correoController,
                        telefonoContactoController: _telefonoContactoController,
                        calleController: _calleController,
                        apartamentoController: _apartamentoController,
                        ciudadController: _ciudadController,
                        estadoController: _estadoController,
                        codigoPostalController: _codigoPostalController,
                        paisController: _paisController,
                        ivaValido: _ivaValido,
                        exentoImpuestos: _exentoImpuestos,
                        activo: _activo,
                        onIvaValidoChanged: (value) =>
                            setState(() => _ivaValido = value),
                        onExentoImpuestosChanged: (value) =>
                            setState(() => _exentoImpuestos = value),
                        onActivoChanged: (value) =>
                            setState(() => _activo = value),
                      )
                    : _ClientConfigTab(notasController: _notasController),
              ),
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
                  widget.cliente == null
                      ? Icons.add_rounded
                      : Icons.save_rounded,
                ),
                label: Text(
                  widget.cliente == null ? 'Crear cliente' : 'Guardar cliente',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final nombres = _nombresController.text.trim();
    if (nombres.isEmpty) {
      ToastHelper.showWarning(context, 'Ingresa los nombres del contacto.');
      return;
    }

    final clientesExistentes =
        ref.read(clientesControllerProvider).valueOrNull ?? const <Cliente>[];
    final numeroIngresado = _numeroController.text.trim();
    final numeroDefinitivo = numeroIngresado.isNotEmpty
        ? numeroIngresado
        : nextSequentialValue(
            clientesExistentes
                .where((item) => item.id != widget.cliente?.id)
                .map((item) => item.numero),
          );
    final numeroDuplicado = clientesExistentes.any(
      (item) =>
          item.id != widget.cliente?.id &&
          item.numero.trim().isNotEmpty &&
          sequenceValuesMatch(item.numero, numeroDefinitivo),
    );
    if (numeroDuplicado) {
      ToastHelper.showWarning(context, 'El número de cliente ya existe.');
      return;
    }

    final now = DateTime.now();
    final empresa = _empresaController.text.trim();
    final contacto = [
      nombres,
      _apellidosController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final direccion = [
      _calleController.text.trim(),
      _apartamentoController.text.trim(),
      _ciudadController.text.trim(),
      _estadoController.text.trim(),
      _codigoPostalController.text.trim(),
      _paisController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');

    final cliente = Cliente(
      id: widget.cliente?.id ?? 'cli-${now.microsecondsSinceEpoch}',
      numero: numeroDefinitivo,
      idNumber: widget.cliente?.idNumber ?? '',
      nombre: contacto,
      empresa: empresa,
      rfc: _rfcController.text.trim(),
      contacto: contacto,
      telefono: _telefonoEmpresaController.text.trim().isNotEmpty
          ? _telefonoEmpresaController.text.trim()
          : _telefonoContactoController.text.trim(),
      correo: _correoController.text.trim(),
      direccion: direccion,
      notas: _notasController.text.trim(),
      activo: _activo,
      createdAt: widget.cliente?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await ref.read(clientesRepositoryProvider).upsert(cliente);
      ref.invalidate(clientesControllerProvider);
      if (!mounted) return;
      ToastHelper.showSuccess(
        context,
        widget.cliente == null
            ? 'Cliente creado correctamente.'
            : 'Cliente actualizado correctamente.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'No se pudo guardar el cliente.');
    }
  }
}

class _ClientCreateTab extends StatelessWidget {
  const _ClientCreateTab({
    required this.empresaController,
    required this.numeroController,
    required this.numeroSugerido,
    required this.rfcController,
    required this.sitioWebController,
    required this.telefonoEmpresaController,
    required this.routingController,
    required this.nombresController,
    required this.apellidosController,
    required this.correoController,
    required this.telefonoContactoController,
    required this.calleController,
    required this.apartamentoController,
    required this.ciudadController,
    required this.estadoController,
    required this.codigoPostalController,
    required this.paisController,
    required this.ivaValido,
    required this.exentoImpuestos,
    required this.activo,
    required this.onIvaValidoChanged,
    required this.onExentoImpuestosChanged,
    required this.onActivoChanged,
  });

  final TextEditingController empresaController;
  final TextEditingController numeroController;
  final String numeroSugerido;
  final TextEditingController rfcController;
  final TextEditingController sitioWebController;
  final TextEditingController telefonoEmpresaController;
  final TextEditingController routingController;
  final TextEditingController nombresController;
  final TextEditingController apellidosController;
  final TextEditingController correoController;
  final TextEditingController telefonoContactoController;
  final TextEditingController calleController;
  final TextEditingController apartamentoController;
  final TextEditingController ciudadController;
  final TextEditingController estadoController;
  final TextEditingController codigoPostalController;
  final TextEditingController paisController;
  final bool ivaValido;
  final bool exentoImpuestos;
  final bool activo;
  final ValueChanged<bool> onIvaValidoChanged;
  final ValueChanged<bool> onExentoImpuestosChanged;
  final ValueChanged<bool> onActivoChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final left = _ClientSection(
          title: 'Detalles de la empresa',
          icon: FontAwesomeIcons.building,
          child: Column(
            children: [
              _ClientFieldRow(
                label: 'Nombre de la empresa',
                controller: empresaController,
              ),
              _ClientFieldRow(
                label: 'Número de cliente (automático)',
                controller: numeroController,
                hintText: 'Se asignará automáticamente: $numeroSugerido',
                helperText:
                    'Si lo dejas vacío, se asigna el consecutivo $numeroSugerido.',
              ),
              _ClientFieldRow(label: 'CIF/NIF', controller: rfcController),
              _ClientFieldRow(
                label: 'Sitio web',
                controller: sitioWebController,
              ),
              _ClientFieldRow(
                label: 'Teléfono',
                controller: telefonoEmpresaController,
              ),
              _ClientFieldRow(
                label: 'Id. de enrutamiento',
                controller: routingController,
              ),
              _ClientSwitchRow(
                label: 'Número de IVA válido',
                value: ivaValido,
                onChanged: onIvaValidoChanged,
              ),
              _ClientSwitchRow(
                label: 'Exento de impuestos',
                value: exentoImpuestos,
                onChanged: onExentoImpuestosChanged,
              ),
              _ClientSwitchRow(
                label: 'Cliente activo',
                value: activo,
                onChanged: onActivoChanged,
              ),
            ],
          ),
        );

        final right = Column(
          children: [
            _ClientSection(
              title: 'Contactos',
              icon: FontAwesomeIcons.addressBook,
              trailing: OutlinedButton(
                onPressed: () {},
                child: const Text('+ Añadir contacto'),
              ),
              child: Column(
                children: [
                  _ClientFieldRow(
                    label: 'Nombres',
                    controller: nombresController,
                  ),
                  _ClientFieldRow(
                    label: 'Apellidos',
                    controller: apellidosController,
                  ),
                  _ClientFieldRow(
                    label: 'Correo electrónico',
                    controller: correoController,
                  ),
                  _ClientFieldRow(
                    label: 'Teléfono',
                    controller: telefonoContactoController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _ClientSection(
              title: 'Dirección de envío',
              icon: FontAwesomeIcons.locationDot,
              child: Column(
                children: [
                  _ClientFieldRow(
                    label: 'Calle de envio',
                    controller: calleController,
                  ),
                  _ClientFieldRow(
                    label: 'Apartamento/Suite',
                    controller: apartamentoController,
                  ),
                  _ClientFieldRow(
                    label: 'Ciudad',
                    controller: ciudadController,
                  ),
                  _ClientFieldRow(
                    label: 'Estado/Provincia',
                    controller: estadoController,
                  ),
                  _ClientFieldRow(
                    label: 'Código Postal',
                    controller: codigoPostalController,
                  ),
                  _ClientFieldRow(label: 'País', controller: paisController),
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
              const SizedBox(width: 10),
              Expanded(child: right),
            ],
          );
        }

        return Column(children: [left, const SizedBox(height: 10), right]);
      },
    );
  }
}

class _ClientConfigTab extends StatelessWidget {
  const _ClientConfigTab({required this.notasController});

  final TextEditingController notasController;

  @override
  Widget build(BuildContext context) {
    final configSection = _ClientSection(
      title: 'Configuración',
      icon: FontAwesomeIcons.sliders,
      child: Column(
        children: const [
          _ClientFieldRow(label: 'Moneda', dropdown: true),
          _ClientFieldRow(label: 'Idioma', dropdown: true),
          _ClientFieldRow(label: 'Términos de pago', dropdown: true),
          _ClientFieldRow(label: 'Cotización válida hasta', dropdown: true),
          _ClientFieldRow(label: 'Tasa de tarea'),
          _ClientFieldRow(label: 'Enviar recordatorios', dropdown: true),
        ],
      ),
    );

    final classifySection = _ClientSection(
      title: 'Clasificar',
      icon: FontAwesomeIcons.tags,
      child: Column(
        children: const [
          _ClientFieldRow(label: 'Tamaño de la empresa', dropdown: true),
          _ClientFieldRow(label: 'Industria', dropdown: true),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return Column(
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: configSection),
                  const SizedBox(width: 10),
                  Expanded(child: classifySection),
                ],
              )
            else
              Column(
                children: [
                  configSection,
                  const SizedBox(height: 10),
                  classifySection,
                ],
              ),
            const SizedBox(height: 10),
            _ClientSection(
              title: 'Notas internas',
              icon: FontAwesomeIcons.noteSticky,
              child: Column(
                children: [
                  _ClientFieldRow(
                    label: 'Notas',
                    controller: notasController,
                    maxLines: 8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClientTabButton extends StatelessWidget {
  const _ClientTabButton({
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

class _ClientSection extends StatelessWidget {
  const _ClientSection({
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

class _ClientFieldRow extends StatelessWidget {
  const _ClientFieldRow({
    required this.label,
    this.controller,
    this.dropdown = false,
    this.maxLines = 1,
    this.hintText,
    this.helperText,
  });

  final String label;
  final TextEditingController? controller;
  final bool dropdown;
  final int maxLines;
  final String? hintText;
  final String? helperText;

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
            width: 165,
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
              textInputAction: maxLines > 1
                  ? TextInputAction.newline
                  : TextInputAction.next,
              onFieldSubmitted: maxLines > 1
                  ? null
                  : (_) => FocusScope.of(context).nextFocus(),
              decoration: InputDecoration(
                hintText: hintText ?? '',
                helperText: helperText,
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

class _ClientSwitchRow extends StatelessWidget {
  const _ClientSwitchRow({
    required this.label,
    this.value = false,
    this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 165,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged ?? (_) {}),
        ],
      ),
    );
  }
}
