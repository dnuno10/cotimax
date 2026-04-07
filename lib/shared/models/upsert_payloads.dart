import 'package:cotimax/shared/enums/app_enums.dart';

class ProductoComponenteInput {
  const ProductoComponenteInput({
    required this.tipo,
    required this.materialId,
    required this.nombreLibre,
    required this.cantidad,
    required this.unidadConsumo,
    required this.costoUnitario,
    required this.orden,
  });

  final String tipo;
  final String? materialId;
  final String? nombreLibre;
  final double cantidad;
  final String unidadConsumo;
  final double costoUnitario;
  final int orden;

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'material_id': materialId,
      'nombre_libre': nombreLibre,
      'cantidad': cantidad,
      'unidad_consumo': unidadConsumo,
      'costo_unitario_snapshot': costoUnitario,
      'orden': orden,
    };
  }
}

class ProductoPrecioRangoInput {
  const ProductoPrecioRangoInput({
    required this.cantidadDesde,
    required this.cantidadHasta,
    required this.precio,
  });

  final double cantidadDesde;
  final double cantidadHasta;
  final double precio;

  Map<String, dynamic> toJson() {
    return {
      'cantidad_desde': cantidadDesde,
      'cantidad_hasta': cantidadHasta,
      'precio': precio,
    };
  }
}

class ProductoUpsertPayload {
  const ProductoUpsertPayload({
    this.id,
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.precioBase,
    required this.costoBase,
    required this.autoCalcularCostoBase,
    required this.modoPrecio,
    required this.cantidadPredeterminada,
    required this.cantidadMaxima,
    required this.categoriaNombre,
    required this.categoriaImpuestoNombre,
    required this.tasaImpuestoNombre,
    required this.unidadMedida,
    required this.sku,
    required this.imagenUrl,
    required this.activo,
    required this.componentes,
    required this.preciosPorRango,
  });

  final String? id;
  final ProductType tipo;
  final String nombre;
  final String descripcion;
  final double precioBase;
  final double costoBase;
  final bool autoCalcularCostoBase;
  final String modoPrecio;
  final double? cantidadPredeterminada;
  final double? cantidadMaxima;
  final String categoriaNombre;
  final String categoriaImpuestoNombre;
  final String tasaImpuestoNombre;
  final String unidadMedida;
  final String sku;
  final String imagenUrl;
  final bool activo;
  final List<ProductoComponenteInput> componentes;
  final List<ProductoPrecioRangoInput> preciosPorRango;

  Map<String, dynamic> toJson() {
    return {
      'p_id': id,
      'p_tipo': tipo.key,
      'p_nombre': nombre,
      'p_descripcion': descripcion,
      'p_precio_base': precioBase,
      'p_costo_base': costoBase,
      'p_auto_calcular_costo_base': autoCalcularCostoBase,
      'p_modo_precio': modoPrecio,
      'p_cantidad_predeterminada': cantidadPredeterminada,
      'p_cantidad_maxima': cantidadMaxima,
      'p_categoria_nombre': categoriaNombre,
      'p_categoria_impuesto_nombre': categoriaImpuestoNombre,
      'p_tasa_impuesto_nombre': tasaImpuestoNombre,
      'p_unidad_medida': unidadMedida,
      'p_sku': sku,
      'p_imagen_url': imagenUrl,
      'p_activo': activo,
      'p_componentes': componentes.map((item) => item.toJson()).toList(),
      'p_precios_por_rango': preciosPorRango
          .map((item) => item.toJson())
          .toList(),
    };
  }
}

class CotizacionLineaInput {
  const CotizacionLineaInput({
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
  });

  final String? productoServicioId;
  final String concepto;
  final String descripcion;
  final double precioUnitario;
  final String unidad;
  final double descuento;
  final double cantidad;
  final double impuestoPorcentaje;
  final double importe;
  final int orden;

  Map<String, dynamic> toJson() {
    return {
      'producto_servicio_id': productoServicioId,
      'concepto': concepto,
      'descripcion': descripcion,
      'precio_unitario': precioUnitario,
      'unidad': unidad,
      'descuento': descuento,
      'cantidad': cantidad,
      'impuesto_porcentaje': impuestoPorcentaje,
      'importe': importe,
      'orden': orden,
    };
  }
}

class CotizacionUpsertPayload {
  const CotizacionUpsertPayload({
    this.id,
    required this.clienteId,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.depositoParcial,
    required this.folio,
    required this.ordenNumero,
    required this.descuentoTipo,
    required this.descuentoValor,
    required this.impuestoPorcentaje,
    required this.retIsr,
    required this.notas,
    required this.notasPrivadas,
    required this.terminos,
    required this.piePagina,
    required this.estatus,
    required this.lineas,
  });

  final String? id;
  final String clienteId;
  final DateTime fechaEmision;
  final DateTime fechaVencimiento;
  final double depositoParcial;
  final String folio;
  final String ordenNumero;
  final String descuentoTipo;
  final double descuentoValor;
  final double impuestoPorcentaje;
  final bool retIsr;
  final String notas;
  final String notasPrivadas;
  final String terminos;
  final String piePagina;
  final QuoteStatus estatus;
  final List<CotizacionLineaInput> lineas;

  Map<String, dynamic> toJson() {
    return {
      'p_id': id,
      'p_cliente_id': clienteId,
      'p_fecha_emision': fechaEmision.toIso8601String(),
      'p_fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'p_deposito_parcial': depositoParcial,
      'p_folio': folio,
      'p_orden_numero': ordenNumero,
      'p_descuento_tipo': descuentoTipo,
      'p_descuento_valor': descuentoValor,
      'p_impuesto_porcentaje': impuestoPorcentaje,
      'p_ret_isr': retIsr,
      'p_notas': notas,
      'p_notas_privadas': notasPrivadas,
      'p_terminos': terminos,
      'p_pie_pagina': piePagina,
      'p_estatus': estatus.key,
      'p_lineas': lineas.map((item) => item.toJson()).toList(),
    };
  }
}
