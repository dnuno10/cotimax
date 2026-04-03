import 'dart:typed_data';

import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class CotizacionPdfService {
  static Future<Uint8List> generate(Cotizacion cotizacion) async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
    final client = Supabase.instance.client;

    final empresaJson = await client.rpc('get_empresa_actual');
    final empresa = EmpresaPerfil(
      id: empresaJson['id'] as String,
      logoUrl: (empresaJson['logo_url'] ?? '') as String,
      nombreFiscal: (empresaJson['nombre_fiscal'] ?? '') as String,
      nombreComercial: (empresaJson['nombre_comercial'] ?? '') as String,
      rfc: (empresaJson['rfc'] ?? '') as String,
      direccion: (empresaJson['direccion'] ?? '') as String,
      telefono: (empresaJson['telefono'] ?? '') as String,
      correo: (empresaJson['correo'] ?? '') as String,
      sitioWeb: (empresaJson['sitio_web'] ?? '') as String,
      colorPrimario: (empresaJson['color_primario'] ?? '#1E5BB8') as String,
      colorSecundario: (empresaJson['color_secundario'] ?? '#F04A2A') as String,
      colorFondo: (empresaJson['color_fondo'] ?? '#F7F9FC') as String,
      colorNeutro: (empresaJson['color_neutro'] ?? '#1F2937') as String,
      themeSeleccionado:
          (empresaJson['theme_seleccionado'] ?? 'corporativo') as String,
      terminosDefault: (empresaJson['terminos_default'] ?? '') as String,
      piePaginaDefault: (empresaJson['pie_pagina_default'] ?? '') as String,
      localizacion: const ConfiguracionLocalizacion(
        moneda: 'MXN',
        idioma: 'es-MX',
        husoHorario: 'America/Tijuana',
        formatoFecha: 'dd/MM/yyyy',
        formatoMoneda: '1,000.00 MXN',
      ),
      impuestos: const ConfiguracionImpuestos(
        tasasLinea: '',
        impuestosSobreGastos: '',
        impuestosInclusivos: '',
        tasaPredeterminada: '',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Cliente cliente;
    try {
      final clienteRow = await client
          .from('clientes')
          .select()
          .eq('id', cotizacion.clienteId)
          .maybeSingle();
      if (clienteRow == null) {
        throw StateError('Cliente no encontrado');
      }
      cliente = Cliente(
        id: clienteRow['id'] as String,
        numero: (clienteRow['numero'] ?? '') as String,
        idNumber: (clienteRow['id_number'] ?? '') as String,
        nombre: (clienteRow['nombre'] ?? '') as String,
        empresa: (clienteRow['empresa'] ?? '') as String,
        rfc: (clienteRow['rfc_cif_nif'] ?? '') as String,
        contacto: (clienteRow['contacto'] ?? '') as String,
        telefono: (clienteRow['telefono'] ?? '') as String,
        correo: (clienteRow['correo'] ?? '') as String,
        direccion: (clienteRow['direccion'] ?? '') as String,
        notas: (clienteRow['notas'] ?? '') as String,
        activo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      cliente = Cliente(
        id: 'na',
        numero: '',
        idNumber: '',
        nombre: 'Cliente no encontrado',
        empresa: '-',
        rfc: '-',
        contacto: '-',
        telefono: '-',
        correo: '-',
        direccion: '-',
        notas: '',
        activo: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
    }

    final detalleRows = await client.rpc(
      'list_cotizacion_detalles',
      params: {'p_cotizacion_id': cotizacion.id},
    );
    final detalles =
        (detalleRows as List)
            .map(
              (item) => DetalleCotizacion(
                id: item['id'] as String,
                cotizacionId: item['cotizacion_id'] as String,
                productoServicioId:
                    (item['producto_servicio_id'] ?? '') as String,
                concepto: (item['concepto'] ?? '') as String,
                descripcion: (item['descripcion'] ?? '') as String,
                precioUnitario: (item['precio_unitario'] as num).toDouble(),
                unidad: (item['unidad'] ?? '') as String,
                descuento: ((item['descuento'] ?? 0) as num).toDouble(),
                cantidad: ((item['cantidad'] ?? 0) as num).toDouble(),
                importe: ((item['importe'] ?? 0) as num).toDouble(),
                orden: ((item['orden'] ?? 0) as num).toInt(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));

    final estatus = {
      QuoteStatus.borrador: 'Borrador',
      QuoteStatus.enviada: 'Enviada',
      QuoteStatus.aprobada: 'Aprobada',
      QuoteStatus.rechazada: 'Rechazada',
    }[cotizacion.estatus]!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      empresa.nombreComercial,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1E5BB8'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(empresa.nombreFiscal),
                    pw.Text('RFC: ${empresa.rfc}'),
                    pw.Text(empresa.correo),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#E6EAF0')),
                  color: PdfColor.fromHex('#F7F9FC'),
                ),
                child: pw.Text(
                  estatus,
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#1F2937'),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E6EAF0')),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Cliente',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#6B7280'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(cliente.nombre),
                      pw.Text(cliente.empresa),
                      pw.Text(cliente.correo),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Cotización',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#6B7280'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Folio: ${cotizacion.folio}'),
                      pw.Text(
                        'Emisión: ${DateFormat('dd/MM/yyyy').format(cotizacion.fechaEmision)}',
                      ),
                      pw.Text(
                        'Vencimiento: ${DateFormat('dd/MM/yyyy').format(cotizacion.fechaVencimiento)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#E6EAF0')),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F7F9FC'),
                ),
                children: [
                  _cell('Concepto', header: true),
                  _cell('Cantidad', header: true),
                  _cell('Precio', header: true),
                  _cell('Importe', header: true),
                ],
              ),
              ...detalles.map(
                (d) => pw.TableRow(
                  children: [
                    _cell('${d.concepto}\n${d.descripcion}'),
                    _cell(d.cantidad.toStringAsFixed(2)),
                    _cell(currency.format(d.precioUnitario)),
                    _cell(currency.format(d.importe)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 240,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#E6EAF0')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _totalLine('Subtotal', currency.format(cotizacion.subtotal)),
                  _totalLine(
                    'Descuento',
                    currency.format(cotizacion.descuentoTotal),
                  ),
                  _totalLine(
                    'Impuesto',
                    currency.format(cotizacion.impuestoTotal),
                  ),
                  pw.Divider(color: PdfColor.fromHex('#E6EAF0')),
                  _totalLine(
                    'Total',
                    currency.format(cotizacion.total),
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Términos: ${cotizacion.terminos}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Notas: ${cotizacion.notas}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            cotizacion.piePagina,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#6B7280'),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 10 : 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromHex(header ? '#1F2937' : '#374151'),
        ),
      ),
    );
  }

  static pw.Widget _totalLine(
    String label,
    String value, {
    bool strong = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
