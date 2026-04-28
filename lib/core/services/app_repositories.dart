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
  Future<void> upsert(MaterialInsumo material, {bool syncProductoIds = false});
  Future<void> delete(String id);
}

abstract class CotizacionesRepository {
  Future<List<Cotizacion>> getAll({String query = ''});
  Future<List<DetalleCotizacion>> getDetalles({String? cotizacionId});
  Future<void> updateStatus(String id, QuoteStatus status);
  Future<void> markPaid(String id);
  Future<void> markUnpaid(String id);
  Future<void> upsert(CotizacionUpsertPayload cotizacion);
  Future<void> delete(String id);
}

abstract class IngresosRepository {
  Future<List<Ingreso>> getAll();
  Future<List<IngresoCategoria>> getCategorias();
  Future<String> createCategoria({required String nombre, String descripcion});
  Future<void> updateCategoria({
    required String id,
    required String nombre,
    String descripcion,
  });
  Future<void> deleteCategoria(String id);
  Future<void> upsert(Ingreso ingreso);
  Future<void> delete(String id);
}

abstract class GastosRepository {
  Future<List<Gasto>> getAll();
  Future<List<GastoRecurrente>> getRecurrentes();
  Future<int> processRecurrentes({DateTime? until});
  Future<List<GastoCategoria>> getCategorias();
  Future<String> createCategoria({required String nombre, String descripcion});
  Future<void> updateCategoria({
    required String id,
    required String nombre,
    String descripcion,
  });
  Future<void> deleteCategoria(String id);
  Future<void> upsert(Gasto gasto);
  Future<void> delete(String id);
}

abstract class RecordatoriosRepository {
  Future<List<Recordatorio>> getAll();
  Future<void> upsert(Recordatorio recordatorio);
  Future<void> delete(String id);
}

abstract class ConfiguracionRepository {
  Future<EmpresaPerfil> getEmpresa();
  Future<void> updateEmpresa(EmpresaPerfil empresa);
  Future<UsuarioActual> getUsuarioActual();
  Future<void> updateUsuarioActualThemeMode(bool modoOscuro);
  Future<void> updateUsuarioActualNombre(String nombre);
  Future<List<EmpresaCatalogItem>> getEmpresasCatalog();
}

abstract class WorkspaceRepository {
  Future<WorkspaceStatus> getStatus();
  Future<void> createInitialCompany({
    required String nombreEmpresa,
    String logoUrl = '',
  });
  Future<void> joinByInvitationCode(String code);
  Future<CompanyInvitationCode> getInvitationCode();

  Future<InviteUserCandidate?> findUserCandidateForTeamInvite(String email);
  Future<void> inviteMemberByEmail(String email);
  Future<List<TeamMemberInvite>> listMyPendingTeamInvites();
  Future<void> respondToTeamInvite({
    required String inviteId,
    required bool accept,
  });
}

abstract class UsuariosRepository {
  Future<List<CompanyMember>> getMembers();
  Future<void> updateMemberRole({
    required String userId,
    required UserRole role,
  });
}

abstract class PlanesRepository {
  Future<List<Plan>> getPlanes();
  Future<Suscripcion> getSuscripcion();
}

class SupabaseClientesRepository implements ClientesRepository {
  SupabaseClientesRepository(this._client);

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
          'calle': cliente.calle,
          'apartamento_suite': cliente.apartamentoSuite,
          'ciudad': cliente.ciudad,
          'estado_provincia': cliente.estadoProvincia,
          'codigo_postal': cliente.codigoPostal,
          'pais': cliente.pais,
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
  SupabaseProveedoresRepository(this._client);

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
  SupabaseProductosRepository(this._client);

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
  SupabaseMaterialesRepository(this._client);

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
  Future<void> upsert(
    MaterialInsumo material, {
    bool syncProductoIds = false,
  }) async {
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
          'proveedor_id': material.proveedorId,
          'proveedor_nombre': material.proveedor,
          'sku': material.sku,
          'sync_producto_ids': syncProductoIds,
          if (syncProductoIds) 'producto_ids': material.productoIds,
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
  SupabaseCotizacionesRepository(this._client);

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
      params: {'p_id': id, 'p_status': status.key},
    );
  }

  @override
  Future<void> markPaid(String id) async {
    await _client.rpc('mark_cotizacion_pagada', params: {'p_id': id});
  }

  @override
  Future<void> markUnpaid(String id) async {
    await _client.rpc('desmarcar_cotizacion_pagada', params: {'p_id': id});
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
  SupabaseIngresosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Ingreso>> getAll() async {
    await _client.rpc('process_recurrent_ingresos');
    final response = await _client.rpc('list_ingresos');
    return _mapList(response, _ingresoFromRow);
  }

  @override
  Future<List<IngresoCategoria>> getCategorias() async {
    final response = await _client.rpc('list_ingreso_categorias');
    return _mapList(response, _ingresoCategoriaFromRow);
  }

  @override
  Future<String> createCategoria({
    required String nombre,
    String descripcion = '',
  }) async {
    final response = await _client.rpc(
      'upsert_ingreso_categoria',
      params: {'p_nombre': nombre, 'p_descripcion': descripcion},
    );
    return (response ?? '').toString();
  }

  @override
  Future<void> updateCategoria({
    required String id,
    required String nombre,
    String descripcion = '',
  }) async {
    await _client.rpc(
      'update_ingreso_categoria',
      params: {'p_id': id, 'p_nombre': nombre, 'p_descripcion': descripcion},
    );
  }

  @override
  Future<void> deleteCategoria(String id) async {
    await _client.rpc('delete_ingreso_categoria', params: {'p_id': id});
  }

  @override
  Future<void> upsert(Ingreso ingreso) async {
    await _client.rpc(
      'upsert_ingreso',
      params: {
        'p_payload': {
          'id': ingreso.id,
          'titulo': ingreso.titulo,
          'ingreso_categoria_id': _nullIfEmpty(ingreso.ingresoCategoriaId),
          'cliente_id': _nullIfEmpty(ingreso.clienteId),
          'cotizacion_id': _nullIfEmpty(ingreso.cotizacionId),
          'monto': ingreso.monto,
          'metodo_pago': ingreso.metodoPago.key,
          'fecha': ingreso.fecha.toIso8601String(),
          'fecha_inicio': ingreso.fechaInicioRecurrencia?.toIso8601String(),
          'referencia': ingreso.referencia,
          'notas': ingreso.notas,
          'recurrente': ingreso.recurrente,
          'recurrencia': ingreso.recurrencia.key,
          'dias_semana': ingreso.diasSemana,
          'icon_key': ingreso.iconKey,
          'gasto_fuente_id': _nullIfEmpty(ingreso.gastoFuenteId),
          'gasto_fuente_nombre_snapshot': _nullIfEmpty(
            ingreso.gastoFuenteNombre,
          ),
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
  SupabaseGastosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Gasto>> getAll() async {
    await _client.rpc('process_recurrent_gastos');
    final response = await _client.rpc('list_gastos');
    return _mapList(response, _gastoFromRow);
  }

  @override
  Future<List<GastoRecurrente>> getRecurrentes() async {
    await _client.rpc('process_recurrent_gastos');
    final response = await _client.rpc('list_gastos_recurrentes');
    return _mapList(response, _gastoRecurrenteFromRow);
  }

  @override
  Future<int> processRecurrentes({DateTime? until}) async {
    final response = await _client.rpc(
      'process_recurrent_gastos',
      params: {'p_until': until?.toIso8601String()},
    );
    if (response is int) return response;
    if (response is num) return response.toInt();
    return int.tryParse(response?.toString() ?? '') ?? 0;
  }

  @override
  Future<List<GastoCategoria>> getCategorias() async {
    final response = await _client.rpc('list_gasto_categorias');
    return _mapList(response, _gastoCategoriaFromRow);
  }

  @override
  Future<String> createCategoria({
    required String nombre,
    String descripcion = '',
  }) async {
    final response = await _client.rpc(
      'upsert_gasto_categoria',
      params: {'p_nombre': nombre, 'p_descripcion': descripcion},
    );
    return (response ?? '').toString();
  }

  @override
  Future<void> updateCategoria({
    required String id,
    required String nombre,
    String descripcion = '',
  }) async {
    await _client.rpc(
      'update_gasto_categoria',
      params: {'p_id': id, 'p_nombre': nombre, 'p_descripcion': descripcion},
    );
  }

  @override
  Future<void> deleteCategoria(String id) async {
    await _client.rpc('delete_gasto_categoria', params: {'p_id': id});
  }

  @override
  Future<void> upsert(Gasto gasto) async {
    await _client.rpc(
      'upsert_gasto',
      params: {
        'p_payload': {
          'id': gasto.id,
          'titulo': gasto.titulo,
          'gasto_categoria_id': _nullIfEmpty(gasto.gastoCategoriaId),
          'monto': gasto.monto,
          'fecha': gasto.fecha.toIso8601String(),
          'fecha_inicio': gasto.fechaInicioRecurrencia?.toIso8601String(),
          'descripcion': gasto.descripcion,
          'proveedor_id': _nullIfEmpty(gasto.proveedorId),
          'proveedor_nombre': gasto.proveedor,
          'referencia': gasto.referencia,
          'notas': gasto.notas,
          'recurrente': gasto.recurrente,
          'recurrencia': gasto.recurrencia.key,
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

class SupabaseRecordatoriosRepository implements RecordatoriosRepository {
  SupabaseRecordatoriosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Recordatorio>> getAll() async {
    try {
      final response = await _client.rpc('list_recordatorios');
      return _mapList(response, _recordatorioFromRow);
    } catch (_) {
      final response = await _client
          .from('recordatorios')
          .select('*, recordatorios_dias(weekday_iso)')
          .order('fecha', ascending: true)
          .order('created_at', ascending: true);
      return _mapList(response, _recordatorioFromRow);
    }
  }

  @override
  Future<void> upsert(Recordatorio recordatorio) async {
    DateTime dateOnly(DateTime value) =>
        DateTime(value.year, value.month, value.day);
    final normalizedId = _nullIfInvalidUuid(recordatorio.id);
    final weekdays =
        recordatorio.recurrente &&
            recordatorio.recurrencia.supportsWeekdaySelection
        ? () {
            final values = recordatorio.diasSemana.toList();
            values.sort();
            return values;
          }()
        : <int>[];
    final payload = {
      if (normalizedId != null) 'id': normalizedId,
      'cliente_id': _nullIfEmpty(recordatorio.clienteId),
      'cliente_nombre_snapshot': recordatorio.clienteNombre,
      'cotizacion_id': _nullIfEmpty(recordatorio.cotizacionId),
      'nombre': recordatorio.nombre,
      'descripcion': recordatorio.descripcion,
      'fecha': dateOnly(recordatorio.fecha).toIso8601String(),
      'fecha_inicio': dateOnly(
        recordatorio.fechaInicioRecurrencia ?? recordatorio.fecha,
      ).toIso8601String(),
      'fecha_fin': recordatorio.fechaFin == null
          ? null
          : dateOnly(recordatorio.fechaFin!).toIso8601String(),
      'frecuencia': recordatorio.recurrente
          ? recordatorio.recurrencia.key
          : RecurrenceFrequency.ninguna.key,
      'activo': recordatorio.activo,
      'icon_key': recordatorio.iconKey,
      'dias_semana': weekdays,
    };
    try {
      await _client.rpc('upsert_recordatorio', params: {'p_payload': payload});
      return;
    } catch (_) {
      final response = await _client
          .from('recordatorios')
          .upsert(payload)
          .select('id')
          .single();
      final recordatorioId = response['id'].toString();

      await _client
          .from('recordatorios_dias')
          .delete()
          .eq('recordatorio_id', recordatorioId);
      if (weekdays.isNotEmpty) {
        await _client
            .from('recordatorios_dias')
            .insert(
              weekdays
                  .map(
                    (weekday) => {
                      'recordatorio_id': recordatorioId,
                      'weekday_iso': weekday,
                    },
                  )
                  .toList(growable: false),
            );
      }
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.rpc('delete_recordatorio', params: {'p_id': id});
      return;
    } catch (_) {
      await _client.from('recordatorios').delete().eq('id', id);
    }
  }
}

class SupabaseConfiguracionRepository implements ConfiguracionRepository {
  SupabaseConfiguracionRepository(this._client);

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
          'calle': empresa.calle,
          'apartamento_suite': empresa.apartamentoSuite,
          'ciudad': empresa.ciudad,
          'estado_provincia': empresa.estadoProvincia,
          'codigo_postal': empresa.codigoPostal,
          'pais': empresa.pais,
          'telefono': empresa.telefono,
          'correo': empresa.correo,
          'sitio_web': empresa.sitioWeb,
          'color_primario': empresa.colorPrimario,
          'color_secundario': empresa.colorSecundario,
          'color_fondo': empresa.colorFondo,
          'color_neutro': empresa.colorNeutro,
          'theme_seleccionado': empresa.themeSeleccionado,
          'diseno_quote': {
            'preset_diseno': empresa.themeSeleccionado,
            'orientacion_pagina': empresa.quotePageOrientation,
            'page_size': empresa.quotePageSize,
            'font_size': empresa.quoteFontSize,
            'logo_size_mode': empresa.quoteLogoSizeMode,
            'logo_size_value': empresa.quoteLogoSizeValue,
            'fuente_primaria': empresa.quotePrimaryFont,
            'fuente_secundaria': empresa.quoteSecondaryFont,
            'empty_columns_mode': empresa.quoteEmptyColumnsMode,
            'show_paid_stamp': empresa.quoteShowPaidStamp,
            'show_shipping_address': empresa.quoteShowShippingAddress,
            'embed_attachments': empresa.quoteEmbedAttachments,
            'show_page_number': empresa.quoteShowPageNumber,
          },
          'notas_default': empresa.notasDefault,
          'notas_privadas_default': empresa.notasPrivadasDefault,
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
            'tasa_predeterminada': empresa.impuestos.tasaPredeterminada,
            'tasas': empresa.impuestos.tasas
                .map(
                  (item) => {
                    'id': item.id,
                    'nombre': item.nombre,
                    'porcentaje': item.porcentaje,
                  },
                )
                .toList(growable: false),
          },
        },
      },
    );
  }

  @override
  Future<UsuarioActual> getUsuarioActual() async {
    final response = await _client.rpc('get_usuario_actual');
    return _usuarioActualFromRow(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<void> updateUsuarioActualThemeMode(bool modoOscuro) async {
    await _client.rpc(
      'update_usuario_actual',
      params: {
        'p_payload': {'modo_oscuro': modoOscuro},
      },
    );
  }

  @override
  Future<void> updateUsuarioActualNombre(String nombre) async {
    await _client.rpc(
      'update_usuario_actual',
      params: {
        'p_payload': {'nombre': nombre},
      },
    );
  }

  @override
  Future<List<EmpresaCatalogItem>> getEmpresasCatalog() async {
    final response = await _client.rpc('list_empresas_catalogo');
    return _mapList(response, _empresaCatalogItemFromRow);
  }
}

class SupabaseWorkspaceRepository implements WorkspaceRepository {
  SupabaseWorkspaceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<WorkspaceStatus> getStatus() async {
    final response = await _client.rpc('get_workspace_status');
    final row = Map<String, dynamic>.from(response as Map);
    return WorkspaceStatus(
      hasCompany: _boolFrom(row['has_company']),
      empresaId: row['empresa_id']?.toString(),
    );
  }

  @override
  Future<void> createInitialCompany({
    required String nombreEmpresa,
    String logoUrl = '',
  }) async {
    await _client.rpc(
      'create_empresa_inicial',
      params: {'p_nombre_comercial': nombreEmpresa, 'p_logo_url': logoUrl},
    );
  }

  @override
  Future<void> joinByInvitationCode(String code) async {
    await _client.rpc(
      'join_empresa_by_invitation_code',
      params: {'p_codigo': code},
    );
  }

  @override
  Future<CompanyInvitationCode> getInvitationCode() async {
    final response = await _client.rpc('get_empresa_invitation_code');
    final row = Map<String, dynamic>.from(response as Map);
    return CompanyInvitationCode(
      empresaId: row['empresa_id'].toString(),
      codigo: (row['codigo'] ?? '') as String,
    );
  }

  @override
  Future<InviteUserCandidate?> findUserCandidateForTeamInvite(
    String email,
  ) async {
    final response = await _client.rpc(
      'find_usuario_by_email_for_team_invite',
      params: {'p_email': email},
    );
    final items = _mapList(response, _inviteUserCandidateFromRow);
    if (items.isEmpty) return null;
    return items.first;
  }

  @override
  Future<void> inviteMemberByEmail(String email) async {
    await _client.rpc(
      'invite_usuario_by_email_to_current_empresa',
      params: {'p_email': email},
    );
  }

  @override
  Future<List<TeamMemberInvite>> listMyPendingTeamInvites() async {
    final response = await _client.rpc('list_my_pending_team_invites');
    return _mapList(response, _teamMemberInviteFromRow);
  }

  @override
  Future<void> respondToTeamInvite({
    required String inviteId,
    required bool accept,
  }) async {
    await _client.rpc(
      'respond_team_invite',
      params: {
        'p_invite_id': inviteId,
        'p_action': accept ? 'aceptar' : 'rechazar',
      },
    );
  }
}

class SupabaseUsuariosRepository implements UsuariosRepository {
  SupabaseUsuariosRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CompanyMember>> getMembers() async {
    final response = await _client.rpc('list_miembros_empresa_actual');
    return _mapList(response, _companyMemberFromRow);
  }

  @override
  Future<void> updateMemberRole({
    required String userId,
    required UserRole role,
  }) async {
    await _client.rpc(
      'update_miembro_rol_empresa_actual',
      params: {'p_usuario_id': userId, 'p_rol': role.key},
    );
  }
}

class SupabasePlanesRepository implements PlanesRepository {
  SupabasePlanesRepository(this._client);

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

String? _nullIfInvalidUuid(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final isUuid = RegExp(
    r'^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$',
  ).hasMatch(trimmed);
  return isUuid ? trimmed : null;
}

List<String> _stringListFrom(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
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
    if (enumKey(value as Object) == raw) return value;
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
    calle: (row['calle'] ?? '') as String,
    apartamentoSuite: (row['apartamento_suite'] ?? '') as String,
    ciudad: (row['ciudad'] ?? '') as String,
    estadoProvincia: (row['estado_provincia'] ?? '') as String,
    codigoPostal: (row['codigo_postal'] ?? '') as String,
    pais: (row['pais'] ?? '') as String,
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
    proveedorId: row['proveedor_id']?.toString(),
    proveedor: (row['proveedor_nombre'] ?? row['proveedor'] ?? '') as String,
    sku: (row['sku'] ?? '') as String,
    productoIds: _stringListFrom(row['producto_ids'] ?? row['productoIds']),
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
    imagenBucket: (row['imagen_bucket'] ?? row['imagenBucket'] ?? '') as String,
    imagenPath: (row['imagen_path'] ?? row['imagenPath'] ?? '') as String,
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
    pagadoTotal: _doubleFrom(row['pagado_total'] ?? row['pagadoTotal']),
    saldoTotal: _doubleFrom(row['saldo_total'] ?? row['saldoTotal']),
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
    impuestoPorcentaje: _doubleFrom(row['impuesto_porcentaje']),
    importe: _doubleFrom(row['importe']),
    orden: (row['orden'] as num?)?.toInt() ?? 0,
    productoImagenUrl:
        (row['producto_imagen_url'] ?? row['productoImagenUrl'] ?? '')
            as String,
    productoImagenBucket:
        (row['producto_imagen_bucket'] ?? row['productoImagenBucket'] ?? '')
            as String,
    productoImagenPath:
        (row['producto_imagen_path'] ?? row['productoImagenPath'] ?? '')
            as String,
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
    titulo: (row['titulo'] ?? '') as String,
    ingresoCategoriaId: (row['ingreso_categoria_id'] ?? '') as String,
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
    fechaInicioRecurrencia: row['fecha_inicio'] == null
        ? null
        : _dateTimeFrom(row['fecha_inicio']),
    iconKey: (row['icon_key'] ?? 'wallet') as String,
    gastoFuenteId: (row['gasto_fuente_id'] ?? '') as String,
    gastoFuenteNombre:
        (row['gasto_fuente_nombre'] ??
                row['gasto_fuente_nombre_snapshot'] ??
                '')
            as String,
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

IngresoCategoria _ingresoCategoriaFromRow(Map<String, dynamic> row) {
  return IngresoCategoria(
    id: row['id'] as String,
    nombre: (row['nombre'] ?? '') as String,
    descripcion: (row['descripcion'] ?? '') as String,
    activo: _boolFrom(row['activo'], fallback: true),
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
    titulo: (row['titulo'] ?? '') as String,
    gastoCategoriaId: (row['gasto_categoria_id'] ?? '') as String,
    monto: _doubleFrom(row['monto']),
    fecha: _dateTimeFrom(row['fecha']),
    fechaInicioRecurrencia: row['fecha_inicio'] == null
        ? null
        : _dateTimeFrom(row['fecha_inicio']),
    descripcion: (row['descripcion'] ?? '') as String,
    proveedorId: (row['proveedor_id'] ?? '') as String,
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

Recordatorio _recordatorioFromRow(Map<String, dynamic> row) {
  final diasSemana = row['dias_semana'] is List
      ? (row['dias_semana'] as List)
            .map(
              (item) => item is num
                  ? item.toInt()
                  : int.tryParse(item?.toString() ?? ''),
            )
            .whereType<int>()
            .where((weekday) => weekday >= 1 && weekday <= 7)
            .toList(growable: false)
      : () {
          final diasRaw = row['recordatorios_dias'] is List
              ? row['recordatorios_dias'] as List
              : const [];
          return diasRaw
              .map((item) => Map<String, dynamic>.from(item as Map))
              .map((item) => (item['weekday_iso'] as num?)?.toInt())
              .whereType<int>()
              .toList(growable: false);
        }();
  final frecuencia = _enumByName(
    RecurrenceFrequency.values,
    row['frecuencia']?.toString(),
    RecurrenceFrequency.ninguna,
  );
  return Recordatorio(
    id: row['id'] as String,
    nombre: (row['nombre'] ?? '') as String,
    descripcion: (row['descripcion'] ?? '') as String,
    fecha: _dateTimeFrom(row['fecha']),
    fechaInicioRecurrencia: row['fecha_inicio'] == null
        ? null
        : _dateTimeFrom(row['fecha_inicio']),
    fechaFin: row['fecha_fin'] == null ? null : _dateTimeFrom(row['fecha_fin']),
    activo: _boolFrom(row['activo'], fallback: true),
    recurrente: frecuencia != RecurrenceFrequency.ninguna,
    recurrencia: frecuencia,
    diasSemana: diasSemana,
    iconKey: (row['icon_key'] ?? 'calendar_month') as String,
    clienteId: (row['cliente_id'] ?? '') as String,
    clienteNombre: (row['cliente_nombre_snapshot'] ?? '') as String,
    cotizacionId: (row['cotizacion_id'] ?? '') as String,
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
  final disenoQuote = Map<String, dynamic>.from(
    row['diseno_quote'] as Map? ?? const {},
  );
  return EmpresaPerfil(
    id: row['id'] as String,
    logoUrl: (row['logo_url'] ?? '') as String,
    nombreFiscal: (row['nombre_fiscal'] ?? '') as String,
    nombreComercial: (row['nombre_comercial'] ?? '') as String,
    rfc: (row['rfc'] ?? '') as String,
    direccion: (row['direccion'] ?? '') as String,
    calle: (row['calle'] ?? '') as String,
    apartamentoSuite: (row['apartamento_suite'] ?? '') as String,
    ciudad: (row['ciudad'] ?? '') as String,
    estadoProvincia: (row['estado_provincia'] ?? '') as String,
    codigoPostal: (row['codigo_postal'] ?? '') as String,
    pais: (row['pais'] ?? '') as String,
    telefono: (row['telefono'] ?? '') as String,
    correo: (row['correo'] ?? '') as String,
    sitioWeb: (row['sitio_web'] ?? '') as String,
    colorPrimario: (row['color_primario'] ?? '#1E5BB8') as String,
    colorSecundario: (row['color_secundario'] ?? '#F04A2A') as String,
    colorFondo: (row['color_fondo'] ?? '#F7F9FC') as String,
    colorNeutro: (row['color_neutro'] ?? '#1F2937') as String,
    themeSeleccionado: (row['theme_seleccionado'] ?? 'corporativo') as String,
    notasDefault: (row['notas_default'] ?? '') as String,
    notasPrivadasDefault: (row['notas_privadas_default'] ?? '') as String,
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
      tasaPredeterminada: (impuestos['tasa_predeterminada'] ?? '') as String,
      tasas: ((impuestos['tasas'] as List?) ?? const [])
          .map(
            (item) => EmpresaTasaImpuesto(
              id: (item['id'] ?? '') as String,
              nombre: (item['nombre'] ?? '') as String,
              porcentaje: ((item['porcentaje'] ?? 0) as num).toDouble(),
            ),
          )
          .where((item) => item.id.trim().isNotEmpty)
          .toList(growable: false),
      tasasLinea: (impuestos['tasas_linea'] ?? '') as String,
      impuestosSobreGastos:
          (impuestos['impuestos_sobre_gastos'] ?? '') as String,
      impuestosInclusivos: (impuestos['impuestos_inclusivos'] ?? '') as String,
    ),
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
    quotePageOrientation:
        (disenoQuote['orientacion_pagina'] ?? 'Retrato') as String,
    quotePageSize: (disenoQuote['page_size'] ?? 'A4') as String,
    quoteFontSize: (disenoQuote['font_size'] as num?)?.toInt() ?? 18,
    quoteLogoSizeMode:
        (disenoQuote['logo_size_mode'] ?? 'Porcentaje') as String,
    quoteLogoSizeValue:
        (disenoQuote['logo_size_value'] as num?)?.toDouble() ?? 24,
    quotePrimaryFont: (disenoQuote['fuente_primaria'] ?? 'Arimo') as String,
    quoteSecondaryFont: (disenoQuote['fuente_secundaria'] ?? 'Arimo') as String,
    quoteEmptyColumnsMode:
        (disenoQuote['empty_columns_mode'] ?? 'Espectaculo') as String,
    quoteShowPaidStamp: _boolFrom(disenoQuote['show_paid_stamp']),
    quoteShowShippingAddress: _boolFrom(disenoQuote['show_shipping_address']),
    quoteEmbedAttachments: _boolFrom(disenoQuote['embed_attachments']),
    quoteShowPageNumber: _boolFrom(disenoQuote['show_page_number']),
  );
}

UsuarioActual _usuarioActualFromRow(Map<String, dynamic> row) {
  return UsuarioActual(
    id: row['id'] as String,
    nombre: (row['nombre'] ?? '') as String,
    telefono: (row['telefono'] ?? '') as String,
    correo: (row['correo'] ?? '') as String,
    rol: _enumByName(UserRole.values, row['rol']?.toString(), UserRole.usuario),
    activo: _boolFrom(row['activo'], fallback: true),
    modoOscuro: _boolFrom(row['modo_oscuro']),
    ultimoAccesoAt: _dateTimeFrom(row['ultimo_acceso_at']),
    createdAt: _dateTimeFrom(row['created_at']),
    updatedAt: _dateTimeFrom(row['updated_at']),
  );
}

EmpresaCatalogItem _empresaCatalogItemFromRow(Map<String, dynamic> row) {
  return EmpresaCatalogItem(
    id: row['id'] as String,
    nombreComercial: (row['nombre_comercial'] ?? '') as String,
  );
}

InviteUserCandidate _inviteUserCandidateFromRow(Map<String, dynamic> row) {
  return InviteUserCandidate(
    id: row['id']?.toString() ?? '',
    nombre: (row['nombre'] ?? '') as String,
    correo: (row['correo'] ?? '') as String,
  );
}

TeamMemberInvite _teamMemberInviteFromRow(Map<String, dynamic> row) {
  return TeamMemberInvite(
    id: row['id']?.toString() ?? '',
    empresaId: row['empresa_id']?.toString() ?? '',
    empresaNombre: (row['empresa_nombre'] ?? '') as String,
    invitedById: row['invited_by']?.toString() ?? '',
    invitedByNombre: (row['invited_by_nombre'] ?? '') as String,
    invitedEmail: (row['invited_email'] ?? '') as String,
    createdAt: _dateTimeFrom(row['created_at']),
  );
}

CompanyMember _companyMemberFromRow(Map<String, dynamic> row) {
  return CompanyMember(
    id: row['usuario_id']?.toString() ?? '',
    nombre: (row['nombre'] ?? '') as String,
    correo: (row['correo'] ?? '') as String,
    rol: _enumByName(UserRole.values, row['rol']?.toString(), UserRole.usuario),
    esPrincipal: _boolFrom(row['es_principal']),
    createdAt: _dateTimeFrom(row['created_at']),
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
    limiteMateriales: (row['limite_materiales'] as num?)?.toInt() ?? 0,
    limiteCotizacionesMensuales:
        (row['limite_cotizaciones_mensuales'] as num?)?.toInt() ?? 0,
    limiteUsuarios: (row['limite_usuarios'] as num?)?.toInt() ?? 0,
    limiteEmpresas: (row['limite_empresas'] as num?)?.toInt() ?? 0,
    usuariosMinimos: (row['usuarios_minimos'] as num?)?.toInt() ?? 0,
    usuariosMaximos: (row['usuarios_maximos'] as num?)?.toInt() ?? 0,
    incluyeIngresosGastos: _boolFrom(row['incluye_ingresos_gastos']),
    incluyeDashboard: _boolFrom(row['incluye_dashboard']),
    incluyeAnalitica: _boolFrom(row['incluye_analitica']),
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
