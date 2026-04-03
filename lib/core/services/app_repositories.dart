import 'package:cotimax/core/config/backend_config.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/models/upsert_payloads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ClientesRepository {
  Future<List<Cliente>> getAll({String query = ''});
  Future<void> upsert(Cliente cliente);
  Future<void> toggle(String id);
  Future<void> delete(String id);
}

abstract class ProveedoresRepository {
  Future<List<Proveedor>> getAll({String query = ''});
  Future<void> upsert(Proveedor proveedor);
  Future<void> toggle(String id);
  Future<void> delete(String id);
}

abstract class ProductosRepository {
  Future<List<ProductoServicio>> getAll({String query = ''});
  Future<void> upsert(ProductoUpsertPayload producto);
  Future<void> delete(String id);
}

abstract class MaterialesRepository {
  Future<List<MaterialInsumo>> getAll({String query = ''});
  Future<void> upsert(MaterialInsumo material);
  Future<void> delete(String id);
}

abstract class CotizacionesRepository {
  Future<List<Cotizacion>> getAll({String query = ''});
  Future<List<DetalleCotizacion>> getDetalles({String? cotizacionId});
  Future<void> updateStatus(String id, QuoteStatus status);
  Future<void> upsert(CotizacionUpsertPayload cotizacion);
  Future<void> delete(String id);
}

abstract class IngresosRepository {
  Future<List<Ingreso>> getAll();
  Future<void> upsert(Ingreso ingreso);
  Future<void> delete(String id);
}

abstract class GastosRepository {
  Future<List<Gasto>> getAll();
  Future<List<GastoRecurrente>> getRecurrentes();
  Future<List<GastoCategoria>> getCategorias();
  Future<void> upsert(Gasto gasto);
  Future<void> delete(String id);
}

abstract class ConfiguracionRepository {
  Future<EmpresaPerfil> getEmpresa();
  Future<void> updateEmpresa(EmpresaPerfil empresa);
}

abstract class UsuariosRepository {
  Future<List<Usuario>> getAll();
}

abstract class PlanesRepository {
  Future<List<Plan>> getPlanes();
  Future<Suscripcion> getSuscripcion();
}

class SupabaseClientesRepository implements ClientesRepository {
  const SupabaseClientesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Cliente>> getAll({String query = ''}) async {
    final response = await _client.rpc(
      'list_clientes',
      params: {'p_query': query},
    );
    return _mapList(response, _clienteFromRow);
  }

  @override
  Future<void> upsert(Cliente cliente) async {
    await _client.rpc(
      'upsert_cliente',
      params: {
        'p_payload': {
          'id': cliente.id,
          'numero': cliente.numero,
          'id_number': cliente.idNumber,
          'nombre': cliente.nombre,
          'empresa': cliente.empresa,
          'rfc_cif_nif': cliente.rfc,
          'telefono': cliente.telefono,
          'correo': cliente.correo,
          'direccion': cliente.direccion,
          'notas': cliente.notas,
          'contacto': cliente.contacto,
          'activo': cliente.activo,
        },
      },
    );
  }

  @override
  Future<void> toggle(String id) async {
    await _client.rpc('toggle_cliente_activo', params: {'p_id': id});
  }

  @override
  Future<void> delete(String id) async {
    await _client.rpc('delete_cliente', params: {'p_id': id});
  }
}

class SupabaseProveedoresRepository implements ProveedoresRepository {
  const SupabaseProveedoresRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Proveedor>> getAll({String query = ''}) async {
    final response = await _client.rpc(
      'list_proveedores',
      params: {'p_query': query},
    );
    return _mapList(response, _proveedorFromRow);
  }

  @override
  Future<void> upsert(Proveedor proveedor) async {
    await _client.rpc(
      'upsert_proveedor',
      params: {
        'p_payload': {
          'id': proveedor.id,
          'numero': proveedor.numero,
          'id_number': proveedor.idNumber,
          'nombre': proveedor.nombre,
          'empresa': proveedor.empresa,
          'rfc_cif_nif': proveedor.rfc,
          'telefono': proveedor.telefono,
          'correo': proveedor.correo,
          'direccion': proveedor.direccion,
          'notas': proveedor.notas,
          'contacto': proveedor.contacto,
          'activo': proveedor.activo,
        },
      },
    );
  }

  @override
  Future<void> toggle(String id) async {
    await _client.rpc('toggle_proveedor_activo', params: {'p_id': id});
  }

  @override
  Future<void> delete(String id) async {
    await _client.rpc('delete_proveedor', params: {'p_id': id});
  }
}

class SupabaseProductosRepository implements ProductosRepository {
  const SupabaseProductosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ProductoServicio>> getAll({String query = ''}) async {
    final response = await _client.rpc(
      'list_productos',
      params: {'p_query': query},
    );
    return _mapList(response, _productoFromRow);
  }

  @override
  Future<void> upsert(ProductoUpsertPayload producto) async {
    await _client.rpc('upsert_producto', params: producto.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _client.rpc('delete_producto', params: {'p_id': id});
  }
}

class SupabaseMaterialesRepository implements MaterialesRepository {
  const SupabaseMaterialesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MaterialInsumo>> getAll({String query = ''}) async {
    final response = await _client.rpc(
      'list_materiales',
      params: {'p_query': query},
    );
    return _mapList(response, _materialFromRow);
  }

  @override
  Future<void> upsert(MaterialInsumo material) async {
    await _client.rpc(
      'upsert_material',
      params: {
        'p_payload': {
          'id': material.id,
          'nombre': material.nombre,
          'descripcion': material.descripcion,
          'tipo_nombre': material.tipo,
          'unidad_medida': material.unidad,
          'costo_unitario': material.costoUnitario,
          'stock_disponible': material.stockDisponible,
          'proveedor_nombre': material.proveedor,
          'sku': material.sku,
          'activo': material.activo,
        },
      },
    );
  }

  @override
  Future<void> delete(String id) async {
    await _client.rpc('delete_material', params: {'p_id': id});
  }
}

class SupabaseCotizacionesRepository implements CotizacionesRepository {
  const SupabaseCotizacionesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Cotizacion>> getAll({String query = ''}) async {
    final response = await _client.rpc(
      'list_cotizaciones',
      params: {'p_query': query},
    );
    return _mapList(response, _cotizacionFromRow);
  }

  @override
  Future<List<DetalleCotizacion>> getDetalles({String? cotizacionId}) async {
    final response = await _client.rpc(
      'list_cotizacion_detalles',
      params: {'p_cotizacion_id': cotizacionId},
    );
    return _mapList(response, _detalleCotizacionFromRow);
  }

  @override
  Future<void> updateStatus(String id, QuoteStatus status) async {
    await _client.rpc(
      'update_cotizacion_status',
      params: {'p_id': id, 'p_status': status.name},
    );
  }

  @override
  Future<void> upsert(CotizacionUpsertPayload cotizacion) async {
    await _client.rpc('upsert_cotizacion', params: cotizacion.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _client.rpc('delete_cotizacion', params: {'p_id': id});
  }
}

class SupabaseIngresosRepository implements IngresosRepository {
  const SupabaseIngresosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Ingreso>> getAll() async {
    final response = await _client.rpc('list_ingresos');
    return _mapList(response, _ingresoFromRow);
  }

  @override
  Future<void> upsert(Ingreso ingreso) async {
    await _client.rpc(
      'upsert_ingreso',
      params: {
        'p_payload': {
          'id': ingreso.id,
          'cliente_id': _nullIfEmpty(ingreso.clienteId),
          'cotizacion_id': _nullIfEmpty(ingreso.cotizacionId),
          'monto': ingreso.monto,
          'metodo_pago': ingreso.metodoPago.name,
          'fecha': ingreso.fecha.toIso8601String(),
          'referencia': ingreso.referencia,
          'notas': ingreso.notas,
          'recurrente': ingreso.recurrente,
          'recurrencia': ingreso.recurrencia.name,
          'dias_semana': ingreso.diasSemana,
          'icon_key': ingreso.iconKey,
        },
      },
    );
  }

  @override
  Future<void> delete(String id) async {
    await _client.rpc('delete_ingreso', params: {'p_id': id});
  }
}

class SupabaseGastosRepository implements GastosRepository {
  const SupabaseGastosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Gasto>> getAll() async {
    final response = await _client.rpc('list_gastos');
    return _mapList(response, _gastoFromRow);
  }

  @override
  Future<List<GastoRecurrente>> getRecurrentes() async {
    final response = await _client.rpc('list_gastos_recurrentes');
    return _mapList(response, _gastoRecurrenteFromRow);
  }

  @override
  Future<List<GastoCategoria>> getCategorias() async {
    final response = await _client.rpc('list_gasto_categorias');
    return _mapList(response, _gastoCategoriaFromRow);
  }

  @override
  Future<void> upsert(Gasto gasto) async {
    await _client.rpc(
      'upsert_gasto',
      params: {
        'p_payload': {
          'id': gasto.id,
          'gasto_categoria_id': _nullIfEmpty(gasto.gastoCategoriaId),
          'monto': gasto.monto,
          'fecha': gasto.fecha.toIso8601String(),
          'descripcion': gasto.descripcion,
          'proveedor_nombre': gasto.proveedor,
          'referencia': gasto.referencia,
          'notas': gasto.notas,
          'recurrente': gasto.recurrente,
          'recurrencia': gasto.recurrencia.name,
          'dias_semana': gasto.diasSemana,
          'icon_key': gasto.iconKey,
        },
      },
    );
  }

  @override
  Future<void> delete(String id) async {
    await _client.rpc('delete_gasto', params: {'p_id': id});
  }
}

class SupabaseConfiguracionRepository implements ConfiguracionRepository {
  const SupabaseConfiguracionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<EmpresaPerfil> getEmpresa() async {
    final response = await _client.rpc('get_empresa_actual');
    return _empresaFromRow(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<void> updateEmpresa(EmpresaPerfil empresa) async {
    await _client.rpc(
      'update_empresa_actual',
      params: {
        'p_payload': {
          'logo_url': empresa.logoUrl,
          'nombre_fiscal': empresa.nombreFiscal,
          'nombre_comercial': empresa.nombreComercial,
          'rfc': empresa.rfc,
          'direccion': empresa.direccion,
          'telefono': empresa.telefono,
          'correo': empresa.correo,
          'sitio_web': empresa.sitioWeb,
          'color_primario': empresa.colorPrimario,
          'color_secundario': empresa.colorSecundario,
          'color_fondo': empresa.colorFondo,
          'color_neutro': empresa.colorNeutro,
          'theme_seleccionado': empresa.themeSeleccionado,
          'terminos_default': empresa.terminosDefault,
          'pie_pagina_default': empresa.piePaginaDefault,
          'localizacion': {
            'moneda': empresa.localizacion.moneda,
            'idioma': empresa.localizacion.idioma,
            'huso_horario': empresa.localizacion.husoHorario,
            'formato_fecha': empresa.localizacion.formatoFecha,
            'formato_moneda': empresa.localizacion.formatoMoneda,
          },
          'impuestos': {
            'tasas_linea': empresa.impuestos.tasasLinea,
            'impuestos_sobre_gastos': empresa.impuestos.impuestosSobreGastos,
            'impuestos_inclusivos': empresa.impuestos.impuestosInclusivos,
            'tasa_predeterminada': empresa.impuestos.tasaPredeterminada,
          },
        },
      },
    );
  }
}

class SupabaseUsuariosRepository implements UsuariosRepository {
  const SupabaseUsuariosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Usuario>> getAll() async {
    final response = await _client.rpc('list_usuarios');
    return _mapList(response, _usuarioFromRow);
  }
}

class SupabasePlanesRepository implements PlanesRepository {
  const SupabasePlanesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Plan>> getPlanes() async {
    final response = await _client.rpc('list_planes');
    return _mapList(response, _planFromRow);
  }

  @override
  Future<Suscripcion> getSuscripcion() async {
    final response = await _client.rpc('get_suscripcion_actual');
    return _suscripcionFromRow(Map<String, dynamic>.from(response as Map));
  }
}

List<T> _mapList<T>(
  dynamic response,
  T Function(Map<String, dynamic> row) mapper,
) {
  if (response is! List) return const [];
  return response
      .map((item) => mapper(Map<String, dynamic>.from(item as Map)))
      .toList();
}

String? _nullIfEmpty(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime _dateTimeFrom(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.parse(value.toString());
}

bool _boolFrom(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return fallback;
}

double _doubleFrom(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

T _enumByName<T>(Iterable<T> values, String? raw, T fallback) {
  if (raw == null || raw.isEmpty) return fallback;
  for (final value in values) {
    if ((value as dynamic).name == raw) return value;
  }
  return fallback;
}

Cliente _clienteFromRow(Map<String, dynamic> row) {
  return Cliente(
    id: row['id'] as String,
    numero: (row['numero'] ?? '') as String,
    idNumber: (row['id_number'] ?? '') as String,
    nombre: (row['nombre'] ?? row['empresa'] ?? '') as String,
    empresa: (row['empresa'] ?? '') as String,
    rfc: (row['rfc_cif_nif'] ?? row['rfc'] ?? '') as String,
    contacto: (row['contacto'] ?? '') as String,
    telefono: (row['telefono'] ?? '') as String,
    correo: (row['correo'] ?? '') as String,
    direccion: (row['direccion'] ?? '') as String,
    notas: (row['notas'] ?? '') as String,
    activo: _boolFrom(row['activo'], fallback: true),
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

Proveedor _proveedorFromRow(Map<String, dynamic> row) {
  return Proveedor(
    id: row['id'] as String,
    numero: (row['numero'] ?? '') as String,
    idNumber: (row['id_number'] ?? '') as String,
    nombre: (row['nombre'] ?? row['empresa'] ?? '') as String,
    empresa: (row['empresa'] ?? '') as String,
    rfc: (row['rfc_cif_nif'] ?? row['rfc'] ?? '') as String,
    contacto: (row['contacto'] ?? '') as String,
    telefono: (row['telefono'] ?? '') as String,
    correo: (row['correo'] ?? '') as String,
    direccion: (row['direccion'] ?? '') as String,
    notas: (row['notas'] ?? '') as String,
    activo: _boolFrom(row['activo'], fallback: true),
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

MaterialInsumo _materialFromRow(Map<String, dynamic> row) {
  return MaterialInsumo(
    id: row['id'] as String,
    nombre: (row['nombre'] ?? '') as String,
    descripcion: (row['descripcion'] ?? '') as String,
    tipo: (row['tipo_nombre'] ?? row['tipo'] ?? '') as String,
    unidad: (row['unidad_medida'] ?? row['unidad'] ?? '') as String,
    costoUnitario: _doubleFrom(row['costo_unitario'] ?? row['costoUnitario']),
    stockDisponible: _doubleFrom(
      row['stock_disponible'] ?? row['stockDisponible'],
    ),
    proveedor: (row['proveedor_nombre'] ?? row['proveedor'] ?? '') as String,
    sku: (row['sku'] ?? '') as String,
    productoIds: const [],
    activo: _boolFrom(row['activo'], fallback: true),
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

ProductoServicio _productoFromRow(Map<String, dynamic> row) {
  return ProductoServicio(
    id: row['id'] as String,
    tipo: _enumByName(
      ProductType.values,
      row['tipo']?.toString(),
      ProductType.producto,
    ),
    nombre: (row['nombre'] ?? '') as String,
    descripcion: (row['descripcion'] ?? '') as String,
    precioBase: _doubleFrom(row['precio_base'] ?? row['precioBase']),
    costo: _doubleFrom(row['costo_base'] ?? row['costo']),
    categoriaId:
        (row['categoria_nombre'] ??
                row['categoria_id'] ??
                row['categoriaId'] ??
                '')
            as String,
    unidad: (row['unidad_medida'] ?? row['unidad'] ?? '') as String,
    sku: (row['sku'] ?? '') as String,
    imagenUrl: (row['imagen_url'] ?? row['imagenUrl'] ?? '') as String,
    activo: _boolFrom(row['activo'], fallback: true),
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

Cotizacion _cotizacionFromRow(Map<String, dynamic> row) {
  return Cotizacion(
    id: row['id'] as String,
    folio: (row['folio'] ?? '') as String,
    clienteId: (row['cliente_id'] ?? row['clienteId'] ?? '') as String,
    fechaEmision: _dateTimeFrom(row['fecha_emision'] ?? row['fechaEmision']),
    fechaVencimiento: _dateTimeFrom(
      row['fecha_vencimiento'] ?? row['fechaVencimiento'],
    ),
    impuestoPorcentaje: _doubleFrom(
      row['impuesto_porcentaje'] ?? row['impuestoPorcentaje'],
    ),
    retIsr: _boolFrom(row['ret_isr'] ?? row['retIsr']),
    subtotal: _doubleFrom(row['subtotal']),
    descuentoTotal: _doubleFrom(
      row['descuento_total'] ?? row['descuentoTotal'],
    ),
    impuestoTotal: _doubleFrom(row['impuesto_total'] ?? row['impuestoTotal']),
    total: _doubleFrom(row['total']),
    notas: (row['notas'] ?? '') as String,
    notasPrivadas:
        (row['notas_privadas'] ?? row['notasPrivadas'] ?? '') as String,
    terminos: (row['terminos'] ?? '') as String,
    piePagina: (row['pie_pagina'] ?? row['piePagina'] ?? '') as String,
    estatus: _enumByName(
      QuoteStatus.values,
      row['estatus']?.toString(),
      QuoteStatus.borrador,
    ),
    usuarioId: (row['usuario_id'] ?? row['usuarioId'] ?? '') as String,
    empresaId:
        (row['empresa_id'] ??
                row['empresaId'] ??
                BackendConfig.defaultEmpresaId)
            as String,
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

DetalleCotizacion _detalleCotizacionFromRow(Map<String, dynamic> row) {
  return DetalleCotizacion(
    id: row['id'] as String,
    cotizacionId: (row['cotizacion_id'] ?? '') as String,
    productoServicioId: (row['producto_servicio_id'] ?? '') as String,
    concepto: (row['concepto'] ?? '') as String,
    descripcion: (row['descripcion'] ?? '') as String,
    precioUnitario: _doubleFrom(row['precio_unitario']),
    unidad: (row['unidad'] ?? '') as String,
    descuento: _doubleFrom(row['descuento']),
    cantidad: _doubleFrom(row['cantidad']),
    importe: _doubleFrom(row['importe']),
    orden: (row['orden'] as num?)?.toInt() ?? 0,
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

Ingreso _ingresoFromRow(Map<String, dynamic> row) {
  final diasSemana = row['dias_semana'] is List
      ? (row['dias_semana'] as List).map((item) => item as int).toList()
      : const <int>[];
  return Ingreso(
    id: row['id'] as String,
    clienteId: (row['cliente_id'] ?? '') as String,
    cotizacionId: (row['cotizacion_id'] ?? '') as String,
    monto: _doubleFrom(row['monto']),
    metodoPago: _enumByName(
      PaymentMethod.values,
      row['metodo_pago']?.toString(),
      PaymentMethod.transferencia,
    ),
    fecha: _dateTimeFrom(row['fecha']),
    referencia: (row['referencia'] ?? '') as String,
    notas: (row['notas'] ?? '') as String,
    recurrente: _boolFrom(row['recurrente']),
    recurrencia: _enumByName(
      RecurrenceFrequency.values,
      row['recurrencia']?.toString(),
      RecurrenceFrequency.ninguna,
    ),
    diasSemana: diasSemana,
    iconKey: (row['icon_key'] ?? 'wallet') as String,
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

GastoCategoria _gastoCategoriaFromRow(Map<String, dynamic> row) {
  return GastoCategoria(
    id: row['id'] as String,
    nombre: (row['nombre'] ?? '') as String,
    descripcion: (row['descripcion'] ?? '') as String,
    activo: _boolFrom(row['activo'], fallback: true),
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

Gasto _gastoFromRow(Map<String, dynamic> row) {
  final diasSemana = row['dias_semana'] is List
      ? (row['dias_semana'] as List).map((item) => item as int).toList()
      : const <int>[];
  return Gasto(
    id: row['id'] as String,
    gastoCategoriaId: (row['gasto_categoria_id'] ?? '') as String,
    monto: _doubleFrom(row['monto']),
    fecha: _dateTimeFrom(row['fecha']),
    descripcion: (row['descripcion'] ?? '') as String,
    proveedor: (row['proveedor_nombre'] ?? row['proveedor'] ?? '') as String,
    referencia: (row['referencia'] ?? '') as String,
    notas: (row['notas'] ?? '') as String,
    recurrente: _boolFrom(row['recurrente']),
    recurrencia: _enumByName(
      RecurrenceFrequency.values,
      row['recurrencia']?.toString(),
      RecurrenceFrequency.ninguna,
    ),
    diasSemana: diasSemana,
    iconKey: (row['icon_key'] ?? 'shopping_cart') as String,
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

GastoRecurrente _gastoRecurrenteFromRow(Map<String, dynamic> row) {
  final diasSemana = row['dias_semana'] is List
      ? (row['dias_semana'] as List).map((item) => item as int).toList()
      : const <int>[];
  return GastoRecurrente(
    id: row['id'] as String,
    gastoCategoriaId: (row['gasto_categoria_id'] ?? '') as String,
    nombre: (row['nombre'] ?? '') as String,
    monto: _doubleFrom(row['monto']),
    frecuencia: _enumByName(
      RecurrenceFrequency.values,
      row['frecuencia']?.toString(),
      RecurrenceFrequency.ninguna,
    ),
    diasSemana: diasSemana,
    fechaInicio: _dateTimeFrom(row['fecha_inicio']),
    fechaFin: row['fecha_fin'] == null ? null : _dateTimeFrom(row['fecha_fin']),
    proximaFecha: _dateTimeFrom(row['proxima_fecha']),
    activo: _boolFrom(row['activo'], fallback: true),
    notas: (row['notas'] ?? '') as String,
    iconKey: (row['icon_key'] ?? 'shopping_cart') as String,
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

EmpresaPerfil _empresaFromRow(Map<String, dynamic> row) {
  final localizacion = Map<String, dynamic>.from(
    row['localizacion'] as Map? ?? const {},
  );
  final impuestos = Map<String, dynamic>.from(
    row['impuestos'] as Map? ?? const {},
  );
  return EmpresaPerfil(
    id: row['id'] as String,
    logoUrl: (row['logo_url'] ?? '') as String,
    nombreFiscal: (row['nombre_fiscal'] ?? '') as String,
    nombreComercial: (row['nombre_comercial'] ?? '') as String,
    rfc: (row['rfc'] ?? '') as String,
    direccion: (row['direccion'] ?? '') as String,
    telefono: (row['telefono'] ?? '') as String,
    correo: (row['correo'] ?? '') as String,
    sitioWeb: (row['sitio_web'] ?? '') as String,
    colorPrimario: (row['color_primario'] ?? '#1E5BB8') as String,
    colorSecundario: (row['color_secundario'] ?? '#F04A2A') as String,
    colorFondo: (row['color_fondo'] ?? '#F7F9FC') as String,
    colorNeutro: (row['color_neutro'] ?? '#1F2937') as String,
    themeSeleccionado: (row['theme_seleccionado'] ?? 'corporativo') as String,
    terminosDefault: (row['terminos_default'] ?? '') as String,
    piePaginaDefault: (row['pie_pagina_default'] ?? '') as String,
    localizacion: ConfiguracionLocalizacion(
      moneda: (localizacion['moneda'] ?? '') as String,
      idioma: (localizacion['idioma'] ?? '') as String,
      husoHorario: (localizacion['huso_horario'] ?? '') as String,
      formatoFecha: (localizacion['formato_fecha'] ?? '') as String,
      formatoMoneda: (localizacion['formato_moneda'] ?? '') as String,
    ),
    impuestos: ConfiguracionImpuestos(
      tasasLinea: (impuestos['tasas_linea'] ?? '') as String,
      impuestosSobreGastos:
          (impuestos['impuestos_sobre_gastos'] ?? '') as String,
      impuestosInclusivos: (impuestos['impuestos_inclusivos'] ?? '') as String,
      tasaPredeterminada: (impuestos['tasa_predeterminada'] ?? '') as String,
    ),
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

Usuario _usuarioFromRow(Map<String, dynamic> row) {
  final empresaIds = row['empresa_ids'] is List
      ? (row['empresa_ids'] as List).map((item) => item.toString()).toList()
      : <String>[if (row['empresa_id'] != null) row['empresa_id'].toString()];
  return Usuario(
    id: row['id'] as String,
    nombre: (row['nombre'] ?? '') as String,
    telefono: (row['telefono'] ?? '') as String,
    correo: (row['correo'] ?? '') as String,
    rol: _enumByName(UserRole.values, row['rol']?.toString(), UserRole.usuario),
    activo: _boolFrom(row['activo'], fallback: true),
    ultimoAccesoAt: _dateTimeFrom(row['ultimo_acceso_at']),
    empresaIds: empresaIds,
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

Plan _planFromRow(Map<String, dynamic> row) {
  return Plan(
    id: row['id'] as String,
    nombre: (row['nombre'] ?? '') as String,
    precioMensual: _doubleFrom(row['precio_mensual']),
    billingMode: (row['billing_mode'] ?? 'flat_monthly') as String,
    precioPorUsuario: _doubleFrom(row['precio_por_usuario']),
    descripcion: (row['descripcion'] ?? '') as String,
    limiteClientes: (row['limite_clientes'] as num?)?.toInt() ?? 0,
    limiteProductos: (row['limite_productos'] as num?)?.toInt() ?? 0,
    limiteCotizacionesMensuales:
        (row['limite_cotizaciones_mensuales'] as num?)?.toInt() ?? 0,
    limiteUsuarios: (row['limite_usuarios'] as num?)?.toInt() ?? 0,
    limiteEmpresas: (row['limite_empresas'] as num?)?.toInt() ?? 0,
    usuariosMinimos: (row['usuarios_minimos'] as num?)?.toInt() ?? 0,
    usuariosMaximos: (row['usuarios_maximos'] as num?)?.toInt() ?? 0,
    incluyeIngresosGastos: _boolFrom(row['incluye_ingresos_gastos']),
    incluyeDashboard: _boolFrom(row['incluye_dashboard']),
    incluyePersonalizacionPdf: _boolFrom(row['incluye_personalizacion_pdf']),
    incluyeNotasPrivadas: _boolFrom(row['incluye_notas_privadas']),
    incluyeEstadosCotizacion: _boolFrom(row['incluye_estados_cotizacion']),
    incluyeMarcaAgua: _boolFrom(row['incluye_marca_agua']),
    activo: _boolFrom(row['activo'], fallback: true),
  );
}

Suscripcion _suscripcionFromRow(Map<String, dynamic> row) {
  return Suscripcion(
    id: row['id'] as String,
    empresaId: (row['empresa_id'] ?? BackendConfig.defaultEmpresaId) as String,
    planId: (row['plan_id'] ?? '') as String,
    estado: (row['estado'] ?? '') as String,
    fechaInicio: _dateTimeFrom(row['fecha_inicio']),
    fechaFin: _dateTimeFrom(row['fecha_fin']),
    renovacionAutomatica: _boolFrom(row['renovacion_automatica']),
    usuariosActivos: (row['usuarios_activos'] as num?)?.toInt() ?? 0,
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}
