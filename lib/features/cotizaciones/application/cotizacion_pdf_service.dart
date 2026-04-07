import 'dart:typed_data';

import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/shared/enums/app_enums.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class CotizacionPdfService {
  static Future<Uint8List> generate(Cotizacion cotizacion) async {
    final pdf = pw.Document();
    final client = Supabase.instance.client;

    final empresaJson = await client.rpc('get_empresa_actual');
    final localizacionJson =
        (empresaJson['localizacion'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final moneda = normalizeCurrencyCode(
      (localizacionJson['moneda'] ?? 'MXN') as String,
    );
    final locale = localeFromLanguageTag(
      (localizacionJson['idioma'] ?? 'es-MX') as String,
    );
    final intlLocale = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    final isEnglish = locale.languageCode.toLowerCase().startsWith('en');
    final currency = NumberFormat.currency(
      locale: intlLocale,
      symbol: '$moneda ',
    );
    final dateFormat = DateFormat('dd/MM/yyyy', intlLocale);
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
      localizacion: ConfiguracionLocalizacion(
        moneda: moneda,
        idioma: (localizacionJson['idioma'] ?? 'es-MX') as String,
        husoHorario:
            (localizacionJson['huso_horario'] ?? 'America/Tijuana') as String,
        formatoFecha:
            (localizacionJson['formato_fecha'] ?? 'dd/MM/yyyy') as String,
        formatoMoneda:
            (localizacionJson['formato_moneda'] ?? '1,000.00 MXN') as String,
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
        throw StateError(
          isEnglish ? 'Client not found' : 'Cliente no encontrado',
        );
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
        calle: '',
        apartamentoSuite: '',
        ciudad: '',
        estadoProvincia: '',
        codigoPostal: '',
        pais: '',
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
        nombre: isEnglish ? 'Client not found' : 'Cliente no encontrado',
        empresa: '-',
        rfc: '-',
        contacto: '-',
        telefono: '-',
        correo: '-',
        direccion: '-',
        calle: '',
        apartamentoSuite: '',
        ciudad: '',
        estadoProvincia: '',
        codigoPostal: '',
        pais: '',
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
                impuestoPorcentaje:
                    ((item['impuesto_porcentaje'] ?? 0) as num).toDouble(),
                importe: ((item['importe'] ?? 0) as num).toDouble(),
                orden: ((item['orden'] ?? 0) as num).toInt(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));

    final estatus = {
      QuoteStatus.borrador: isEnglish ? 'Draft' : 'Borrador',
      QuoteStatus.enviada: isEnglish ? 'Sent' : 'Enviada',
      QuoteStatus.aprobada: isEnglish ? 'Approved' : 'Aprobada',
      QuoteStatus.rechazada: isEnglish ? 'Rejected' : 'Rechazada',
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
                    pw.Text('${isEnglish ? 'Tax ID' : 'RFC'}: ${empresa.rfc}'),
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
                        isEnglish ? 'Client' : 'Cliente',
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
                        isEnglish ? 'Quote' : 'Cotización',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#6B7280'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${isEnglish ? 'Folio' : 'Folio'}: ${cotizacion.folio}',
                      ),
                      pw.Text(
                        '${isEnglish ? 'Issued' : 'Emisión'}: ${dateFormat.format(cotizacion.fechaEmision)}',
                      ),
                      pw.Text(
                        '${isEnglish ? 'Due' : 'Vencimiento'}: ${dateFormat.format(cotizacion.fechaVencimiento)}',
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
                  _cell(isEnglish ? 'Item' : 'Concepto', header: true),
                  _cell(isEnglish ? 'Quantity' : 'Cantidad', header: true),
                  _cell(isEnglish ? 'Price' : 'Precio', header: true),
                  _cell(isEnglish ? 'Amount' : 'Importe', header: true),
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
                  _totalLine(
                    isEnglish ? 'Subtotal' : 'Subtotal',
                    currency.format(cotizacion.subtotal),
                  ),
                  _totalLine(
                    isEnglish ? 'Discount' : 'Descuento',
                    currency.format(cotizacion.descuentoTotal),
                  ),
                  _totalLine(
                    isEnglish ? 'Tax' : 'Impuesto',
                    currency.format(cotizacion.impuestoTotal),
                  ),
                  pw.Divider(color: PdfColor.fromHex('#E6EAF0')),
                  _totalLine(
                    isEnglish ? 'Total' : 'Total',
                    currency.format(cotizacion.total),
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '${isEnglish ? 'Terms' : 'Términos'}: ${cotizacion.terminos}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${isEnglish ? 'Notes' : 'Notas'}: ${cotizacion.notas}',
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
