import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/core/routing/route_paths.dart';
import 'package:cotimax/features/clientes/application/clientes_controller.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const List<({String value, String label})> clientCurrencyOptions = [
  (value: 'MXN', label: 'MXN - Peso mexicano'),
  (value: 'USD', label: 'USD - Dólar estadounidense'),
  (value: 'EUR', label: 'EUR - Euro'),
  (value: 'GBP', label: 'GBP - Libra esterlina'),
  (value: 'CAD', label: 'CAD - Dólar canadiense'),
  (value: 'BRL', label: 'BRL - Real brasileño'),
  (value: 'ARS', label: 'ARS - Peso argentino'),
  (value: 'CLP', label: 'CLP - Peso chileno'),
  (value: 'COP', label: 'COP - Peso colombiano'),
  (value: 'PEN', label: 'PEN - Sol peruano'),
  (value: 'UYU', label: 'UYU - Peso uruguayo'),
  (value: 'PYG', label: 'PYG - Guaraní paraguayo'),
  (value: 'BOB', label: 'BOB - Boliviano'),
  (value: 'GTQ', label: 'GTQ - Quetzal guatemalteco'),
  (value: 'CRC', label: 'CRC - Colón costarricense'),
  (value: 'DOP', label: 'DOP - Peso dominicano'),
  (value: 'JPY', label: 'JPY - Yen japonés'),
  (value: 'CNY', label: 'CNY - Yuan chino'),
  (value: 'INR', label: 'INR - Rupia india'),
  (value: 'AUD', label: 'AUD - Dólar australiano'),
  (value: 'NZD', label: 'NZD - Dólar neozelandés'),
  (value: 'CHF', label: 'CHF - Franco suizo'),
  (value: 'SEK', label: 'SEK - Corona sueca'),
  (value: 'NOK', label: 'NOK - Corona noruega'),
  (value: 'DKK', label: 'DKK - Corona danesa'),
  (value: 'SGD', label: 'SGD - Dólar de Singapur'),
  (value: 'HKD', label: 'HKD - Dólar de Hong Kong'),
  (value: 'KRW', label: 'KRW - Won surcoreano'),
  (value: 'ZAR', label: 'ZAR - Rand sudafricano'),
  (value: 'AED', label: 'AED - Dírham de Emiratos'),
];

const List<({String value, String label})> clientLanguageOptions = [
  (value: 'es-MX', label: 'Español'),
  (value: 'en-US', label: 'Inglés'),
];

const List<String> clientPaymentTermsOptions = [
  'Pago inmediato',
  'Contra entrega',
  'Anticipo del 50%',
  'Anticipo del 70%',
  '7 días',
  '10 días',
  '15 días',
  '20 días',
  '30 días',
  '45 días',
  '60 días',
  '90 días',
  'Fin de mes',
  'Quincenal',
  'Mensual',
];

const List<String> clientQuoteValidUntilOptions = [
  '1 día',
  '3 días',
  '5 días',
  '7 días',
  '10 días',
  '15 días',
  '30 días',
  '45 días',
  '60 días',
  '90 días',
];

List<String> clientTaskRateOptions(String currencyCode) => [
  'Sin tasa definida',
  '100 $currencyCode/h',
  '150 $currencyCode/h',
  '200 $currencyCode/h',
  '250 $currencyCode/h',
  '300 $currencyCode/h',
  '400 $currencyCode/h',
  '500 $currencyCode/h',
  '750 $currencyCode/h',
  '1,000 $currencyCode/h',
  '1,500 $currencyCode/h',
  '2,000 $currencyCode/h',
];

const List<String> clientReminderOptions = [
  'No enviar',
  'El mismo día',
  '1 día antes',
  '3 días antes',
  '5 días antes',
  '7 días antes',
  '10 días antes',
  '15 días antes',
  '30 días antes',
];

const List<String> clientCompanySizeOptions = [
  '1-5 empleados',
  '6-20 empleados',
  '21-50 empleados',
  '51-100 empleados',
  '101-250 empleados',
  '251-500 empleados',
  '501-1,000 empleados',
  '1,001-5,000 empleados',
  '5,001+ empleados',
];

const List<String> clientIndustryOptions = [
  'Arquitectura',
  'Construcción',
  'Ingeniería civil',
  'Ingeniería mecánica',
  'Ingeniería eléctrica',
  'Ingeniería industrial',
  'Manufactura',
  'Maquila',
  'Automotriz',
  'Aeroespacial',
  'Electrónica',
  'Semiconductores',
  'Metalmecánica',
  'Plásticos',
  'Textil',
  'Moda',
  'Calzado',
  'Muebles',
  'Carpintería',
  'Diseño de interiores',
  'Bienes raíces',
  'Desarrollo inmobiliario',
  'Administración de propiedades',
  'Hotelería',
  'Restaurantes',
  'Cafeterías',
  'Alimentos y bebidas',
  'Agricultura',
  'Ganadería',
  'Pesca',
  'Minería',
  'Energía',
  'Energía solar',
  'Petróleo y gas',
  'Tratamiento de agua',
  'Logística',
  'Transporte terrestre',
  'Transporte marítimo',
  'Transporte aéreo',
  'Almacenaje',
  'Comercio mayorista',
  'Comercio minorista',
  'E-commerce',
  'Importación y exportación',
  'Distribución',
  'Farmacéutica',
  'Dispositivos médicos',
  'Hospitales',
  'Clínicas',
  'Laboratorios',
  'Odontología',
  'Veterinaria',
  'Seguros',
  'Banca',
  'Fintech',
  'Contabilidad',
  'Auditoría',
  'Legal',
  'Consultoría de negocios',
  'Recursos humanos',
  'Reclutamiento',
  'Tecnología',
  'Software',
  'SaaS',
  'Ciberseguridad',
  'Telecomunicaciones',
  'Marketing digital',
  'Publicidad',
  'Medios',
  'Producción audiovisual',
  'Fotografía',
  'Impresión',
  'Educación',
  'Capacitación',
  'Investigación',
  'ONG',
  'Gobierno',
  'Seguridad privada',
  'Limpieza industrial',
  'Mantenimiento',
  'Reparación industrial',
  'Facility management',
  'Eventos',
  'Organización de bodas',
  'Entretenimiento',
  'Deportes',
  'Gimnasios',
  'Belleza',
  'Cosmética',
  'Spa y bienestar',
  'Turismo',
  'Call center',
  'BPO',
  'Servicio al cliente',
  'Paquetería',
  'Reciclaje',
  'Gestión ambiental',
  'Decoración',
  'Papelería y oficina',
  'Comercio internacional',
];

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  bool _handledCreateRoute = false;
  late final TextEditingController _searchController;
  String _appliedRouteQuery = '';
  final Set<String> _selectedClienteIds = <String>{};

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
              label: Text(trText('Nuevo cliente')),
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
          loading: () =>
              const LoadingStateWidget(message: 'Cargando clientes...'),
          error: (_, __) => ErrorStateWidget(
            message: 'No fue posible cargar clientes.',
            onRetry: () => ref.invalidate(clientesControllerProvider),
          ),
          data: (clientes) {
            if (clientes.isEmpty) {
              return const SectionCard(child: InlineEmptyMessage());
            }

            final allSelected = _selectedClienteIds.length == clientes.length;
            final partiallySelected =
                _selectedClienteIds.isNotEmpty && !allSelected;

            return CotimaxDataTable(
              toolbar: _selectedClienteIds.isEmpty
                  ? null
                  : TableSelectionToolbar(
                      count: _selectedClienteIds.length,
                      entityLabel: 'cliente',
                      onEdit: _selectedClienteIds.length == 1
                          ? () {
                              final cliente = clientes.firstWhere(
                                (item) => item.id == _selectedClienteIds.first,
                              );
                              _openForm(context, cliente);
                            }
                          : null,
                      onDelete: _deleteSelectedClientes,
                      onClear: () =>
                          setState(() => _selectedClienteIds.clear()),
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
                          _selectedClienteIds
                            ..clear()
                            ..addAll(clientes.map((item) => item.id));
                        } else {
                          _selectedClienteIds.clear();
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
              rows: clientes
                  .map(
                    (cliente) => DataRow(
                      selected: _selectedClienteIds.contains(cliente.id),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: _selectedClienteIds.contains(cliente.id),
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selectedClienteIds.add(cliente.id);
                                } else {
                                  _selectedClienteIds.remove(cliente.id);
                                }
                              });
                            },
                          ),
                        ),
                        DataCell(Text(cliente.nombre)),
                        DataCell(Text(cliente.empresa)),
                        DataCell(Text(cliente.rfc)),
                        DataCell(Text(cliente.contacto)),
                        DataCell(Text(cliente.telefono)),
                        DataCell(Text(cliente.correo)),
                        DataCell(
                          Text(trText(cliente.activo ? 'Activo' : 'Inactivo')),
                        ),
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
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(trText('Editar')),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  trText(
                                    cliente.activo ? 'Desactivar' : 'Activar',
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
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo actualizar el cliente.'),
      );
    }
  }

  Future<void> _deleteCliente(Cliente cliente) async {
    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: 'cliente',
      onConfirmAsync: () async {
        try {
          await ref.read(clientesRepositoryProvider).delete(cliente.id);
          ref.invalidate(clientesControllerProvider);
          if (!mounted) return;
          ToastHelper.showSuccess(context, 'Cliente eliminado.');
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(error, 'No se pudo eliminar el cliente.'),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
  }

  Future<void> _deleteSelectedClientes() async {
    final count = _selectedClienteIds.length;
    if (count == 0) return;

    final confirmed = await showDeleteConfirmation(
      context,
      entityLabel: count == 1 ? 'cliente' : 'clientes seleccionados',
      title: count == 1 ? 'Eliminar cliente' : 'Eliminar clientes',
      message: count == 1
          ? '¿Estás seguro que quieres eliminar este cliente?'
          : '¿Estás seguro que quieres eliminar los $count clientes seleccionados?',
      onConfirmAsync: () async {
        try {
          final ids = _selectedClienteIds.toList();
          for (final id in ids) {
            await ref.read(clientesRepositoryProvider).delete(id);
          }
          ref.invalidate(clientesControllerProvider);
          if (!mounted) return;
          setState(() => _selectedClienteIds.clear());
          ToastHelper.showSuccess(
            context,
            count == 1
                ? 'Cliente eliminado.'
                : '$count clientes eliminados correctamente.',
          );
        } catch (error) {
          if (!mounted) rethrow;
          ToastHelper.showError(
            context,
            buildActionErrorMessage(
              error,
              'No se pudieron eliminar los clientes.',
            ),
          );
          rethrow;
        }
      },
    );
    if (!confirmed) return;
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
  bool _isSaving = false;
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
    _calleController = seededTextController(
      cliente == null
          ? ''
          : cliente.calle.isNotEmpty
          ? cliente.calle
          : cliente.direccion,
    );
    _apartamentoController = seededTextController(cliente?.apartamentoSuite);
    _ciudadController = seededTextController(cliente?.ciudad);
    _estadoController = seededTextController(cliente?.estadoProvincia);
    _codigoPostalController = seededTextController(cliente?.codigoPostal);
    _paisController = seededTextController(cliente?.pais);
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
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                child: Text(trText('Cancelar')),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
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
    if (_isSaving) return;
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
      calle: _calleController.text.trim(),
      apartamentoSuite: _apartamentoController.text.trim(),
      ciudad: _ciudadController.text.trim(),
      estadoProvincia: _estadoController.text.trim(),
      codigoPostal: _codigoPostalController.text.trim(),
      pais: _paisController.text.trim(),
      notas: _notasController.text.trim(),
      activo: _activo,
      createdAt: widget.cliente?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _isSaving = true);
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
    } catch (error) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        buildActionErrorMessage(error, 'No se pudo guardar el cliente.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                hintText: tr(
                  'Se asignará automáticamente: $numeroSugerido',
                  'It will be assigned automatically: $numeroSugerido',
                ),
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
                child: Text(trText('+ Añadir contacto')),
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

class _ClientConfigTab extends StatefulWidget {
  const _ClientConfigTab({required this.notasController});

  final TextEditingController notasController;

  @override
  State<_ClientConfigTab> createState() => _ClientConfigTabState();
}

class _ClientConfigTabState extends State<_ClientConfigTab> {
  String _moneda = clientCurrencyOptions.first.value;
  String _idioma = clientLanguageOptions.first.value;
  String _terminosPago = clientPaymentTermsOptions.first;
  String _cotizacionValidaHasta = clientQuoteValidUntilOptions[3];
  String _tasaTarea = 'Sin tasa definida';
  String _recordatorios = clientReminderOptions.first;
  String _tamanoEmpresa = clientCompanySizeOptions.first;
  String _industria = clientIndustryOptions.first;

  @override
  Widget build(BuildContext context) {
    final taskRateOptions = clientTaskRateOptions(currentCurrencyCode());
    final selectedTaskRate = taskRateOptions.contains(_tasaTarea)
        ? _tasaTarea
        : taskRateOptions.first;
    final configSection = _ClientSection(
      title: 'Configuración',
      icon: FontAwesomeIcons.sliders,
      child: Column(
        children: [
          _ClientDropdownRow(
            label: 'Moneda',
            value: _moneda,
            options: clientCurrencyOptions,
            onChanged: (value) => setState(() => _moneda = value),
          ),
          _ClientDropdownRow(
            label: 'Idioma',
            value: _idioma,
            options: clientLanguageOptions,
            onChanged: (value) => setState(() => _idioma = value),
          ),
          _ClientDropdownRow(
            label: 'Términos de pago',
            value: _terminosPago,
            options: [
              for (final option in clientPaymentTermsOptions)
                (value: option, label: option),
            ],
            onChanged: (value) => setState(() => _terminosPago = value),
          ),
          _ClientDropdownRow(
            label: 'Cotización válida hasta',
            value: _cotizacionValidaHasta,
            options: [
              for (final option in clientQuoteValidUntilOptions)
                (value: option, label: option),
            ],
            onChanged: (value) =>
                setState(() => _cotizacionValidaHasta = value),
          ),
          _ClientDropdownRow(
            label: 'Tasa de tarea',
            value: selectedTaskRate,
            options: [
              for (final option in taskRateOptions)
                (value: option, label: option),
            ],
            onChanged: (value) => setState(() => _tasaTarea = value),
          ),
          _ClientDropdownRow(
            label: 'Enviar recordatorios',
            value: _recordatorios,
            options: [
              for (final option in clientReminderOptions)
                (value: option, label: option),
            ],
            onChanged: (value) => setState(() => _recordatorios = value),
          ),
        ],
      ),
    );

    final classifySection = _ClientSection(
      title: 'Clasificar',
      icon: FontAwesomeIcons.tags,
      child: Column(
        children: [
          _ClientDropdownRow(
            label: 'Tamaño de la empresa',
            value: _tamanoEmpresa,
            options: [
              for (final option in clientCompanySizeOptions)
                (value: option, label: option),
            ],
            onChanged: (value) => setState(() => _tamanoEmpresa = value),
          ),
          _ClientDropdownRow(
            label: 'Industria',
            value: _industria,
            options: [
              for (final option in clientIndustryOptions)
                (value: option, label: option),
            ],
            onChanged: (value) => setState(() => _industria = value),
          ),
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
                    controller: widget.notasController,
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

class _ClientFieldRow extends StatelessWidget {
  const _ClientFieldRow({
    required this.label,
    this.controller,
    this.maxLines = 1,
    this.hintText,
    this.helperText,
  });

  final String label;
  final TextEditingController? controller;
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
              textInputAction: maxLines > 1
                  ? TextInputAction.newline
                  : TextInputAction.next,
              onFieldSubmitted: maxLines > 1
                  ? null
                  : (_) => FocusScope.of(context).nextFocus(),
              decoration: InputDecoration(
                hintText: hintText == null ? '' : trText(hintText!),
                helperText: helperText == null ? null : trText(helperText!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientDropdownRow extends StatelessWidget {
  const _ClientDropdownRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<({String value, String label})> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 165,
            child: Text(
              trText(label),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
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
                      value: option.value,
                      child: Text(
                        trText(option.label),
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
              trText(label),
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
