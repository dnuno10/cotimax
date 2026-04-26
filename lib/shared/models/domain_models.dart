import 'package:cotimax/shared/enums/app_enums.dart';

class Cliente {
  Cliente({
    required this.id,
    required this.numero,
    required this.idNumber,
    required this.nombre,
    required this.empresa,
    required this.rfc,
    required this.contacto,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.calle,
    required this.apartamentoSuite,
    required this.ciudad,
    required this.estadoProvincia,
    required this.codigoPostal,
    required this.pais,
    required this.notas,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String numero;
  final String idNumber;
  final String nombre;
  final String empresa;
  final String rfc;
  final String contacto;
  final String telefono;
  final String correo;
  final String direccion;
  final String calle;
  final String apartamentoSuite;
  final String ciudad;
  final String estadoProvincia;
  final String codigoPostal;
  final String pais;
  final String notas;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cliente copyWith({
    String? numero,
    String? idNumber,
    String? nombre,
    bool? activo,
    DateTime? updatedAt,
  }) {
    return Cliente(
      id: id,
      numero: numero ?? this.numero,
      idNumber: idNumber ?? this.idNumber,
      nombre: nombre ?? this.nombre,
      empresa: empresa,
      rfc: rfc,
      contacto: contacto,
      telefono: telefono,
      correo: correo,
      direccion: direccion,
      calle: calle,
      apartamentoSuite: apartamentoSuite,
      ciudad: ciudad,
      estadoProvincia: estadoProvincia,
      codigoPostal: codigoPostal,
      pais: pais,
      notas: notas,
      activo: activo ?? this.activo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Proveedor {
  Proveedor({
    required this.id,
    required this.numero,
    required this.idNumber,
    required this.nombre,
    required this.empresa,
    required this.rfc,
    required this.contacto,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.notas,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String numero;
  final String idNumber;
  final String nombre;
  final String empresa;
  final String rfc;
  final String contacto;
  final String telefono;
  final String correo;
  final String direccion;
  final String notas;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Proveedor copyWith({
    String? numero,
    String? idNumber,
    String? nombre,
    bool? activo,
    DateTime? updatedAt,
  }) {
    return Proveedor(
      id: id,
      numero: numero ?? this.numero,
      idNumber: idNumber ?? this.idNumber,
      nombre: nombre ?? this.nombre,
      empresa: empresa,
      rfc: rfc,
      contacto: contacto,
      telefono: telefono,
      correo: correo,
      direccion: direccion,
      notas: notas,
      activo: activo ?? this.activo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CategoriaProducto {
  CategoriaProducto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MaterialInsumo {
  MaterialInsumo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.unidad,
    required this.costoUnitario,
    required this.stockDisponible,
    this.proveedorId,
    required this.proveedor,
    required this.sku,
    required this.productoIds,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final String unidad;
  final double costoUnitario;
  final double stockDisponible;
  final String? proveedorId;
  final String proveedor;
  final String sku;
  final List<String> productoIds;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaterialInsumo copyWith({
    String? nombre,
    String? descripcion,
    String? tipo,
    String? unidad,
    double? costoUnitario,
    double? stockDisponible,
    String? proveedorId,
    String? proveedor,
    String? sku,
    List<String>? productoIds,
    bool? activo,
    DateTime? updatedAt,
  }) {
    return MaterialInsumo(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      unidad: unidad ?? this.unidad,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      proveedorId: proveedorId ?? this.proveedorId,
      proveedor: proveedor ?? this.proveedor,
      sku: sku ?? this.sku,
      productoIds: productoIds ?? this.productoIds,
      activo: activo ?? this.activo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProductoServicio {
  ProductoServicio({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.precioBase,
    required this.costo,
    required this.categoriaId,
    required this.unidad,
    required this.sku,
    required this.imagenUrl,
    this.imagenBucket = '',
    this.imagenPath = '',
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ProductType tipo;
  final String nombre;
  final String descripcion;
  final double precioBase;
  final double costo;
  final String categoriaId;
  final String unidad;
  final String sku;
  final String imagenUrl;
  final String imagenBucket;
  final String imagenPath;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Cotizacion {
  Cotizacion({
    required this.id,
    required this.folio,
    required this.clienteId,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.impuestoPorcentaje,
    required this.retIsr,
    required this.subtotal,
    required this.descuentoTotal,
    required this.impuestoTotal,
    required this.total,
    required this.notas,
    required this.notasPrivadas,
    required this.terminos,
    required this.piePagina,
    required this.estatus,
    required this.usuarioId,
    required this.empresaId,
    required this.createdAt,
    required this.updatedAt,
    this.pagadoTotal = 0,
    this.saldoTotal = 0,
  });

  final String id;
  final String folio;
  final String clienteId;
  final DateTime fechaEmision;
  final DateTime fechaVencimiento;
  final double impuestoPorcentaje;
  final bool retIsr;
  final double subtotal;
  final double descuentoTotal;
  final double impuestoTotal;
  final double total;
  final String notas;
  final String notasPrivadas;
  final String terminos;
  final String piePagina;
  final QuoteStatus estatus;
  final String usuarioId;
  final String empresaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double pagadoTotal;
  final double saldoTotal;

  bool get isPaid {
    if (total <= 0) return false;
    return pagadoTotal >= total - 0.01 || saldoTotal <= 0.01;
  }

  Cotizacion copyWith({
    QuoteStatus? estatus,
    double? pagadoTotal,
    double? saldoTotal,
  }) {
    return Cotizacion(
      id: id,
      folio: folio,
      clienteId: clienteId,
      fechaEmision: fechaEmision,
      fechaVencimiento: fechaVencimiento,
      impuestoPorcentaje: impuestoPorcentaje,
      retIsr: retIsr,
      subtotal: subtotal,
      descuentoTotal: descuentoTotal,
      impuestoTotal: impuestoTotal,
      total: total,
      notas: notas,
      notasPrivadas: notasPrivadas,
      terminos: terminos,
      piePagina: piePagina,
      estatus: estatus ?? this.estatus,
      usuarioId: usuarioId,
      empresaId: empresaId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      pagadoTotal: pagadoTotal ?? this.pagadoTotal,
      saldoTotal: saldoTotal ?? this.saldoTotal,
    );
  }
}

class DetalleCotizacion {
  DetalleCotizacion({
    required this.id,
    required this.cotizacionId,
    required this.productoServicioId,
    required this.concepto,
    required this.descripcion,
    required this.precioUnitario,
    required this.unidad,
    required this.descuento,
    required this.cantidad,
    required this.impuestoPorcentaje,
    required this.importe,
    required this.orden,
    this.productoImagenUrl = '',
    this.productoImagenBucket = '',
    this.productoImagenPath = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String cotizacionId;
  final String productoServicioId;
  final String concepto;
  final String descripcion;
  final double precioUnitario;
  final String unidad;
  final double descuento;
  final double cantidad;
  final double impuestoPorcentaje;
  final double importe;
  final int orden;
  final String productoImagenUrl;
  final String productoImagenBucket;
  final String productoImagenPath;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Ingreso {
  Ingreso({
    required this.id,
    required this.titulo,
    required this.ingresoCategoriaId,
    required this.clienteId,
    required this.cotizacionId,
    required this.monto,
    required this.metodoPago,
    required this.fecha,
    required this.referencia,
    required this.notas,
    required this.recurrente,
    required this.recurrencia,
    required this.diasSemana,
    required this.fechaInicioRecurrencia,
    required this.iconKey,
    this.gastoFuenteId = '',
    this.gastoFuenteNombre = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String titulo;
  final String ingresoCategoriaId;
  final String clienteId;
  final String cotizacionId;
  final double monto;
  final PaymentMethod metodoPago;
  final DateTime fecha;
  final String referencia;
  final String notas;
  final bool recurrente;
  final RecurrenceFrequency recurrencia;
  final List<int> diasSemana;
  final DateTime? fechaInicioRecurrencia;
  final String iconKey;
  final String gastoFuenteId;
  final String gastoFuenteNombre;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class IngresoCategoria {
  IngresoCategoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class GastoCategoria {
  GastoCategoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Gasto {
  Gasto({
    required this.id,
    required this.titulo,
    required this.gastoCategoriaId,
    required this.monto,
    required this.fecha,
    required this.fechaInicioRecurrencia,
    required this.descripcion,
    required this.proveedorId,
    required this.proveedor,
    required this.referencia,
    required this.notas,
    required this.recurrente,
    required this.recurrencia,
    required this.diasSemana,
    required this.iconKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String titulo;
  final String gastoCategoriaId;
  final double monto;
  final DateTime fecha;
  final DateTime? fechaInicioRecurrencia;
  final String descripcion;
  final String proveedorId;
  final String proveedor;
  final String referencia;
  final String notas;
  final bool recurrente;
  final RecurrenceFrequency recurrencia;
  final List<int> diasSemana;
  final String iconKey;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class GastoRecurrente {
  GastoRecurrente({
    required this.id,
    required this.gastoCategoriaId,
    required this.nombre,
    required this.monto,
    required this.frecuencia,
    required this.diasSemana,
    required this.fechaInicio,
    required this.fechaFin,
    required this.proximaFecha,
    required this.activo,
    required this.notas,
    required this.iconKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String gastoCategoriaId;
  final String nombre;
  final double monto;
  final RecurrenceFrequency frecuencia;
  final List<int> diasSemana;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final DateTime proximaFecha;
  final bool activo;
  final String notas;
  final String iconKey;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Recordatorio {
  Recordatorio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fecha,
    required this.fechaInicioRecurrencia,
    required this.fechaFin,
    required this.activo,
    required this.recurrente,
    required this.recurrencia,
    required this.diasSemana,
    required this.iconKey,
    required this.clienteId,
    required this.clienteNombre,
    required this.cotizacionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fecha;
  final DateTime? fechaInicioRecurrencia;
  final DateTime? fechaFin;
  final bool activo;
  final bool recurrente;
  final RecurrenceFrequency recurrencia;
  final List<int> diasSemana;
  final String iconKey;
  final String clienteId;
  final String clienteNombre;
  final String cotizacionId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class EmpresaPerfil {
  EmpresaPerfil({
    required this.id,
    required this.logoUrl,
    required this.nombreFiscal,
    required this.nombreComercial,
    required this.rfc,
    required this.direccion,
    this.calle = '',
    this.apartamentoSuite = '',
    this.ciudad = '',
    this.estadoProvincia = '',
    this.codigoPostal = '',
    this.pais = '',
    required this.telefono,
    required this.correo,
    required this.sitioWeb,
    required this.colorPrimario,
    required this.colorSecundario,
    required this.colorFondo,
    required this.colorNeutro,
    required this.themeSeleccionado,
    required this.notasDefault,
    required this.notasPrivadasDefault,
    required this.terminosDefault,
    required this.piePaginaDefault,
    required this.localizacion,
    required this.impuestos,
    required this.createdAt,
    required this.updatedAt,
    this.quotePageOrientation = 'Retrato',
    this.quotePageSize = 'A4',
    this.quoteFontSize = 18,
    this.quoteLogoSizeMode = 'Porcentaje',
    this.quoteLogoSizeValue = 24,
    this.quotePrimaryFont = 'Arimo',
    this.quoteSecondaryFont = 'Arimo',
    this.quoteEmptyColumnsMode = 'Espectaculo',
    this.quoteShowPaidStamp = false,
    this.quoteShowShippingAddress = false,
    this.quoteEmbedAttachments = false,
    this.quoteShowPageNumber = false,
  });

  final String id;
  final String logoUrl;
  final String nombreFiscal;
  final String nombreComercial;
  final String rfc;
  final String direccion;
  final String calle;
  final String apartamentoSuite;
  final String ciudad;
  final String estadoProvincia;
  final String codigoPostal;
  final String pais;
  final String telefono;
  final String correo;
  final String sitioWeb;
  final String colorPrimario;
  final String colorSecundario;
  final String colorFondo;
  final String colorNeutro;
  final String themeSeleccionado;
  final String notasDefault;
  final String notasPrivadasDefault;
  final String terminosDefault;
  final String piePaginaDefault;
  final ConfiguracionLocalizacion localizacion;
  final ConfiguracionImpuestos impuestos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String quotePageOrientation;
  final String quotePageSize;
  final int quoteFontSize;
  final String quoteLogoSizeMode;
  final double quoteLogoSizeValue;
  final String quotePrimaryFont;
  final String quoteSecondaryFont;
  final String quoteEmptyColumnsMode;
  final bool quoteShowPaidStamp;
  final bool quoteShowShippingAddress;
  final bool quoteEmbedAttachments;
  final bool quoteShowPageNumber;

  EmpresaPerfil copyWith({
    String? logoUrl,
    String? nombreFiscal,
    String? nombreComercial,
    String? rfc,
    String? direccion,
    String? calle,
    String? apartamentoSuite,
    String? ciudad,
    String? estadoProvincia,
    String? codigoPostal,
    String? pais,
    String? telefono,
    String? correo,
    String? sitioWeb,
    String? colorPrimario,
    String? colorSecundario,
    String? colorFondo,
    String? colorNeutro,
    String? themeSeleccionado,
    String? notasDefault,
    String? notasPrivadasDefault,
    String? terminosDefault,
    String? piePaginaDefault,
    ConfiguracionLocalizacion? localizacion,
    ConfiguracionImpuestos? impuestos,
    DateTime? updatedAt,
    String? quotePageOrientation,
    String? quotePageSize,
    int? quoteFontSize,
    String? quoteLogoSizeMode,
    double? quoteLogoSizeValue,
    String? quotePrimaryFont,
    String? quoteSecondaryFont,
    String? quoteEmptyColumnsMode,
    bool? quoteShowPaidStamp,
    bool? quoteShowShippingAddress,
    bool? quoteEmbedAttachments,
    bool? quoteShowPageNumber,
  }) {
    return EmpresaPerfil(
      id: id,
      logoUrl: logoUrl ?? this.logoUrl,
      nombreFiscal: nombreFiscal ?? this.nombreFiscal,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      rfc: rfc ?? this.rfc,
      direccion: direccion ?? this.direccion,
      calle: calle ?? this.calle,
      apartamentoSuite: apartamentoSuite ?? this.apartamentoSuite,
      ciudad: ciudad ?? this.ciudad,
      estadoProvincia: estadoProvincia ?? this.estadoProvincia,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      pais: pais ?? this.pais,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      sitioWeb: sitioWeb ?? this.sitioWeb,
      colorPrimario: colorPrimario ?? this.colorPrimario,
      colorSecundario: colorSecundario ?? this.colorSecundario,
      colorFondo: colorFondo ?? this.colorFondo,
      colorNeutro: colorNeutro ?? this.colorNeutro,
      themeSeleccionado: themeSeleccionado ?? this.themeSeleccionado,
      notasDefault: notasDefault ?? this.notasDefault,
      notasPrivadasDefault: notasPrivadasDefault ?? this.notasPrivadasDefault,
      terminosDefault: terminosDefault ?? this.terminosDefault,
      piePaginaDefault: piePaginaDefault ?? this.piePaginaDefault,
      localizacion: localizacion ?? this.localizacion,
      impuestos: impuestos ?? this.impuestos,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quotePageOrientation: quotePageOrientation ?? this.quotePageOrientation,
      quotePageSize: quotePageSize ?? this.quotePageSize,
      quoteFontSize: quoteFontSize ?? this.quoteFontSize,
      quoteLogoSizeMode: quoteLogoSizeMode ?? this.quoteLogoSizeMode,
      quoteLogoSizeValue: quoteLogoSizeValue ?? this.quoteLogoSizeValue,
      quotePrimaryFont: quotePrimaryFont ?? this.quotePrimaryFont,
      quoteSecondaryFont: quoteSecondaryFont ?? this.quoteSecondaryFont,
      quoteEmptyColumnsMode:
          quoteEmptyColumnsMode ?? this.quoteEmptyColumnsMode,
      quoteShowPaidStamp: quoteShowPaidStamp ?? this.quoteShowPaidStamp,
      quoteShowShippingAddress:
          quoteShowShippingAddress ?? this.quoteShowShippingAddress,
      quoteEmbedAttachments:
          quoteEmbedAttachments ?? this.quoteEmbedAttachments,
      quoteShowPageNumber: quoteShowPageNumber ?? this.quoteShowPageNumber,
    );
  }
}

class UsuarioActual {
  UsuarioActual({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.rol,
    required this.activo,
    required this.modoOscuro,
    required this.ultimoAccesoAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String telefono;
  final String correo;
  final UserRole rol;
  final bool activo;
  final bool modoOscuro;
  final DateTime ultimoAccesoAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UsuarioActual copyWith({
    String? nombre,
    String? telefono,
    String? correo,
    UserRole? rol,
    bool? activo,
    bool? modoOscuro,
    DateTime? ultimoAccesoAt,
    DateTime? updatedAt,
  }) {
    return UsuarioActual(
      id: id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      modoOscuro: modoOscuro ?? this.modoOscuro,
      ultimoAccesoAt: ultimoAccesoAt ?? this.ultimoAccesoAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ConfiguracionLocalizacion {
  ConfiguracionLocalizacion({
    required this.moneda,
    required this.idioma,
    required this.husoHorario,
    required this.formatoFecha,
    required this.formatoMoneda,
  });

  final String moneda;
  final String idioma;
  final String husoHorario;
  final String formatoFecha;
  final String formatoMoneda;

  ConfiguracionLocalizacion copyWith({
    String? moneda,
    String? idioma,
    String? husoHorario,
    String? formatoFecha,
    String? formatoMoneda,
  }) {
    return ConfiguracionLocalizacion(
      moneda: moneda ?? this.moneda,
      idioma: idioma ?? this.idioma,
      husoHorario: husoHorario ?? this.husoHorario,
      formatoFecha: formatoFecha ?? this.formatoFecha,
      formatoMoneda: formatoMoneda ?? this.formatoMoneda,
    );
  }
}

class EmpresaTasaImpuesto {
  EmpresaTasaImpuesto({
    required this.id,
    required this.nombre,
    required this.porcentaje,
  });

  final String id;
  final String nombre;
  final double porcentaje;

  String get displayLabel {
    final decimalDigits = porcentaje == porcentaje.roundToDouble() ? 0 : 2;
    final normalized = porcentaje.toStringAsFixed(decimalDigits);
    return '$nombre ($normalized%)';
  }

  EmpresaTasaImpuesto copyWith({
    String? id,
    String? nombre,
    double? porcentaje,
  }) {
    return EmpresaTasaImpuesto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      porcentaje: porcentaje ?? this.porcentaje,
    );
  }
}

class ConfiguracionImpuestos {
  ConfiguracionImpuestos({
    required this.tasas,
    required this.tasaPredeterminada,
    this.tasasLinea = '',
    this.impuestosSobreGastos = '',
    this.impuestosInclusivos = '',
  });

  final List<EmpresaTasaImpuesto> tasas;
  final String tasaPredeterminada;
  final String tasasLinea;
  final String impuestosSobreGastos;
  final String impuestosInclusivos;

  ConfiguracionImpuestos copyWith({
    List<EmpresaTasaImpuesto>? tasas,
    String? tasaPredeterminada,
    String? tasasLinea,
    String? impuestosSobreGastos,
    String? impuestosInclusivos,
  }) {
    return ConfiguracionImpuestos(
      tasas: tasas ?? this.tasas,
      tasaPredeterminada: tasaPredeterminada ?? this.tasaPredeterminada,
      tasasLinea: tasasLinea ?? this.tasasLinea,
      impuestosSobreGastos: impuestosSobreGastos ?? this.impuestosSobreGastos,
      impuestosInclusivos: impuestosInclusivos ?? this.impuestosInclusivos,
    );
  }
}

class WorkspaceStatus {
  WorkspaceStatus({required this.hasCompany, this.empresaId});

  final bool hasCompany;
  final String? empresaId;
}

class EmpresaCatalogItem {
  EmpresaCatalogItem({required this.id, required this.nombreComercial});

  final String id;
  final String nombreComercial;
}

class CompanyInvitationCode {
  CompanyInvitationCode({required this.empresaId, required this.codigo});

  final String empresaId;
  final String codigo;
}

class Usuario {
  Usuario({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.rol,
    required this.activo,
    required this.ultimoAccesoAt,
    required this.empresaIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String telefono;
  final String correo;
  final UserRole rol;
  final bool activo;
  final DateTime ultimoAccesoAt;
  final List<String> empresaIds;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Plan {
  Plan({
    required this.id,
    required this.nombre,
    required this.precioMensual,
    required this.billingMode,
    required this.precioPorUsuario,
    required this.descripcion,
    required this.limiteClientes,
    required this.limiteProductos,
    required this.limiteMateriales,
    required this.limiteCotizacionesMensuales,
    required this.limiteUsuarios,
    required this.limiteEmpresas,
    required this.usuariosMinimos,
    required this.usuariosMaximos,
    required this.incluyeIngresosGastos,
    required this.incluyeDashboard,
    required this.incluyeAnalitica,
    required this.incluyePersonalizacionPdf,
    required this.incluyeNotasPrivadas,
    required this.incluyeEstadosCotizacion,
    required this.incluyeMarcaAgua,
    required this.activo,
  });

  final String id;
  final String nombre;
  final double precioMensual;
  final String billingMode;
  final double precioPorUsuario;
  final String descripcion;
  final int limiteClientes;
  final int limiteProductos;
  final int limiteMateriales;
  final int limiteCotizacionesMensuales;
  final int limiteUsuarios;
  final int limiteEmpresas;
  final int usuariosMinimos;
  final int usuariosMaximos;
  final bool incluyeIngresosGastos;
  final bool incluyeDashboard;
  final bool incluyeAnalitica;
  final bool incluyePersonalizacionPdf;
  final bool incluyeNotasPrivadas;
  final bool incluyeEstadosCotizacion;
  final bool incluyeMarcaAgua;
  final bool activo;
}

class Suscripcion {
  Suscripcion({
    required this.id,
    required this.empresaId,
    required this.planId,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.renovacionAutomatica,
    required this.usuariosActivos,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String empresaId;
  final String planId;
  final String estado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool renovacionAutomatica;
  final int usuariosActivos;
  final DateTime createdAt;
  final DateTime updatedAt;
}
