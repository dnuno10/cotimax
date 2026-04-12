import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cotimax/core/localization/app_localization.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:cotimax/shared/widgets/cotimax_rich_text_editor.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CotizacionPdfService {
  static Future<_CotizacionPdfFonts>? _fontsFuture;
  static String? _cachedFontFamily;
  static final Map<String, Uint8List> _pdfCache = <String, Uint8List>{};
  static final Map<String, Future<pw.ImageProvider?>> _logoCache =
      <String, Future<pw.ImageProvider?>>{};
  static final Map<String, _QuotePdfSourceData> _quoteDataCache =
      <String, _QuotePdfSourceData>{};
  static final Map<String, Future<_QuotePdfSourceData>> _quoteDataInFlight =
      <String, Future<_QuotePdfSourceData>>{};
  static Map<String, dynamic>? _empresaActualCache;
  static DateTime? _empresaActualCacheAt;

  static Future<Uint8List> generate(
    Cotizacion cotizacion, {
    bool useCache = true,
    EmpresaPerfil? empresaOverride,
    Map<String, dynamic>? disenoQuoteOverride,
  }) async {
    final client = Supabase.instance.client;
    final empresaJson = empresaOverride == null
        ? await _getEmpresaActualCached(client)
        : null;
    final storedDisenoQuoteJson = empresaOverride == null
        ? ((empresaJson!['diseno_quote'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{})
        : _disenoQuoteFromEmpresa(empresaOverride);
    final disenoQuoteJson = <String, dynamic>{
      ...storedDisenoQuoteJson,
      ...?disenoQuoteOverride,
    };
    final primaryFont =
        (disenoQuoteJson['fuente_primaria'] ??
                disenoQuoteJson['quote_primary_font'] ??
                'Arimo')
            .toString();
    final fonts = await _loadFonts(primaryFont);
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.base,
        bold: fonts.bold,
        italic: fonts.italic,
        boldItalic: fonts.boldItalic,
      ),
    );
    final localizacionJson = empresaOverride == null
        ? ((empresaJson!['localizacion'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{})
        : <String, dynamic>{
            'moneda': empresaOverride.localizacion.moneda,
            'idioma': empresaOverride.localizacion.idioma,
            'huso_horario': empresaOverride.localizacion.husoHorario,
            'formato_fecha': empresaOverride.localizacion.formatoFecha,
            'formato_moneda': empresaOverride.localizacion.formatoMoneda,
          };
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
    final empresaBase =
        empresaOverride ??
        EmpresaPerfil(
          id: empresaJson!['id'] as String,
          logoUrl: (empresaJson['logo_url'] ?? '') as String,
          nombreFiscal: (empresaJson['nombre_fiscal'] ?? '') as String,
          nombreComercial: (empresaJson['nombre_comercial'] ?? '') as String,
          rfc: (empresaJson['rfc'] ?? '') as String,
          direccion: (empresaJson['direccion'] ?? '') as String,
          telefono: (empresaJson['telefono'] ?? '') as String,
          correo: (empresaJson['correo'] ?? '') as String,
          sitioWeb: (empresaJson['sitio_web'] ?? '') as String,
          colorPrimario: (empresaJson['color_primario'] ?? '#1E5BB8') as String,
          colorSecundario:
              (empresaJson['color_secundario'] ?? '#F04A2A') as String,
          colorFondo: (empresaJson['color_fondo'] ?? '#F7F9FC') as String,
          colorNeutro: (empresaJson['color_neutro'] ?? '#1F2937') as String,
          themeSeleccionado:
              (storedDisenoQuoteJson['preset_diseno'] ??
                      empresaJson['theme_seleccionado'] ??
                      'corporativo')
                  as String,
          notasDefault: (empresaJson['notas_default'] ?? '') as String,
          notasPrivadasDefault:
              (empresaJson['notas_privadas_default'] ?? '') as String,
          terminosDefault: (empresaJson['terminos_default'] ?? '') as String,
          piePaginaDefault: (empresaJson['pie_pagina_default'] ?? '') as String,
          localizacion: ConfiguracionLocalizacion(
            moneda: moneda,
            idioma: (localizacionJson['idioma'] ?? 'es-MX') as String,
            husoHorario:
                (localizacionJson['huso_horario'] ?? 'America/Tijuana')
                    as String,
            formatoFecha:
                (localizacionJson['formato_fecha'] ?? 'dd/MM/yyyy') as String,
            formatoMoneda:
                (localizacionJson['formato_moneda'] ?? '1,000.00 MXN')
                    as String,
          ),
          impuestos: ConfiguracionImpuestos(
            tasas: const [],
            tasaPredeterminada: '',
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    final empresa = empresaBase.copyWith(
      themeSeleccionado: _normalizeThemePreset(
        (disenoQuoteJson['preset_diseno'] ?? empresaBase.themeSeleccionado)
            .toString(),
      ),
    );
    final pdfTheme = _QuotePdfTheme.fromEmpresa(empresa);
    final quoteFontSize =
        (disenoQuoteJson['font_size'] as num?)?.toDouble() ?? 18;
    final logoSize =
        (disenoQuoteJson['logo_size_value'] as num?)?.toDouble() ?? 24;
    final logoSizeMode =
        (disenoQuoteJson['logo_size_mode'] ??
                disenoQuoteJson['quote_logo_size_mode'] ??
                'Porcentaje')
            .toString();
    final showPaidStamp = disenoQuoteJson['show_paid_stamp'] == true;
    final showShippingAddress =
        disenoQuoteJson['show_shipping_address'] == true;
    final embedAttachments = disenoQuoteJson['embed_attachments'] == true;
    final showPageNumber = disenoQuoteJson['show_page_number'] == true;
    final pageOrientation =
        (disenoQuoteJson['page_orientation'] ??
                disenoQuoteJson['quote_page_orientation'] ??
                'Retrato')
            .toString();
    final pageSize = (disenoQuoteJson['page_size'] ?? 'A4').toString();
    final empresaUpdated = empresaOverride == null
        ? (empresaJson!['updated_at'] ?? '').toString()
        : 'override-${empresaOverride.updatedAt.microsecondsSinceEpoch}';
    final disenoSignature = _stableJsonSignature(disenoQuoteJson);
    final overrideSignature = empresaOverride == null
        ? ''
        : [
            empresaOverride.themeSeleccionado,
            empresaOverride.colorPrimario,
            empresaOverride.colorSecundario,
            empresaOverride.colorFondo,
            empresaOverride.colorNeutro,
            empresaOverride.quotePageSize,
            empresaOverride.quotePageOrientation,
            empresaOverride.quoteFontSize,
            empresaOverride.quoteLogoSizeMode,
            empresaOverride.quoteLogoSizeValue,
            empresaOverride.quotePrimaryFont,
            empresaOverride.quoteSecondaryFont,
          ].join('|');
    final cacheKey = [
      cotizacion.id,
      cotizacion.updatedAt.microsecondsSinceEpoch,
      cotizacion.total,
      empresaUpdated,
      empresa.themeSeleccionado,
      quoteFontSize,
      pageSize,
      pageOrientation,
      disenoSignature,
      overrideSignature,
    ].join('|');
    if (useCache) {
      final cached = _pdfCache[cacheKey];
      if (cached != null) return cached;
    }

    final quoteSourceFuture = _loadQuoteSourceData(
      client,
      cotizacion,
      isEnglish,
      useCache: useCache,
    );
    final logoFuture = _loadLogoProvider(empresa.logoUrl);

    final parallelData = await Future.wait<dynamic>([
      quoteSourceFuture,
      logoFuture,
    ]);
    final quoteSource = parallelData[0] as _QuotePdfSourceData;
    final logoProvider = parallelData[1] as pw.ImageProvider?;
    final cliente = quoteSource.cliente;
    final detalles = quoteSource.detalles;
    final themePreset = _normalizeThemePreset(empresa.themeSeleccionado);
    final isCorporateTemplate = themePreset == 'corporativo';
    final isIndustrialTemplate = themePreset == 'industrial';
    final isMinimalTemplate = themePreset == 'minimal';
    final isDestacadoTemplate = themePreset == 'destacado';
    final isEditorialTemplate = themePreset == 'editorial';

    final resolvedPageFormat = _resolvePageFormat(
      pageSize: pageSize,
      pageOrientation: pageOrientation,
    );
    final fontScale = _resolveFontScale(
      quoteFontSize: quoteFontSize,
      pageFormat: resolvedPageFormat,
    );
    final logoExtent = _resolveLogoExtent(
      logoSize: logoSize,
      logoSizeMode: logoSizeMode,
      pageFormat: resolvedPageFormat,
    );
    final pageMargin = _resolvePageMargin(resolvedPageFormat);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: resolvedPageFormat,
          margin: pw.EdgeInsets.all(pageMargin),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: pdfTheme.background),
          ),
        ),
        footer: showPageNumber
            ? (context) => pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${isEnglish ? 'Page' : 'Pagina'} ${context.pageNumber} / ${context.pagesCount} • $pageSize',
                  style: pw.TextStyle(fontSize: 8, color: pdfTheme.textMuted),
                ),
              )
            : null,
        build: (context) => isCorporateTemplate
            ? _buildCorporateQuoteBody(
                cotizacion: cotizacion,
                cliente: cliente,
                detalles: detalles,
                empresa: empresa,
                pdfTheme: pdfTheme,
                currency: currency,
                dateFormat: dateFormat,
                isEnglish: isEnglish,
                logoProvider: logoProvider,
                fontScale: fontScale,
                logoExtent: logoExtent,
                showPaidStamp: showPaidStamp,
              )
            : isIndustrialTemplate
            ? _buildIndustrialQuoteBody(
                cotizacion: cotizacion,
                cliente: cliente,
                detalles: detalles,
                empresa: empresa,
                pdfTheme: pdfTheme,
                currency: currency,
                dateFormat: dateFormat,
                isEnglish: isEnglish,
                logoProvider: logoProvider,
                fontScale: fontScale,
                logoExtent: logoExtent,
              )
            : isMinimalTemplate
            ? _buildMinimalQuoteBody(
                cotizacion: cotizacion,
                cliente: cliente,
                detalles: detalles,
                empresa: empresa,
                pdfTheme: pdfTheme,
                currency: currency,
                dateFormat: dateFormat,
                isEnglish: isEnglish,
                logoProvider: logoProvider,
                fontScale: fontScale,
                logoExtent: logoExtent,
              )
            : isDestacadoTemplate
            ? _buildDestacadoQuoteBody(
                cotizacion: cotizacion,
                cliente: cliente,
                detalles: detalles,
                empresa: empresa,
                pdfTheme: pdfTheme,
                currency: currency,
                dateFormat: dateFormat,
                isEnglish: isEnglish,
                logoProvider: logoProvider,
                fontScale: fontScale,
                logoExtent: logoExtent,
              )
            : isEditorialTemplate
            ? _buildEditorialQuoteBody(
                cotizacion: cotizacion,
                cliente: cliente,
                detalles: detalles,
                empresa: empresa,
                pdfTheme: pdfTheme,
                currency: currency,
                dateFormat: dateFormat,
                isEnglish: isEnglish,
                logoProvider: logoProvider,
                fontScale: fontScale,
                logoExtent: logoExtent,
              )
            : [
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: pdfTheme.background,
                    borderRadius: pw.BorderRadius.circular(pdfTheme.radius),
                    border: pw.Border.all(color: pdfTheme.border),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoProvider != null) ...[
                        pw.Container(
                          width: logoExtent,
                          height: logoExtent,
                          alignment: pw.Alignment.center,
                          child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(width: 12),
                      ],
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              empresa.nombreComercial,
                              style: pw.TextStyle(
                                fontSize: 20 * fontScale,
                                fontWeight: pw.FontWeight.bold,
                                color: pdfTheme.primary,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(empresa.nombreFiscal),
                            pw.Text(
                              '${isEnglish ? 'Tax ID' : 'RFC'}: ${empresa.rfc}',
                              style: pw.TextStyle(color: pdfTheme.textMuted),
                            ),
                            pw.Text(empresa.correo),
                            if (empresa.telefono.trim().isNotEmpty)
                              pw.Text(empresa.telefono),
                            if (empresa.sitioWeb.trim().isNotEmpty)
                              pw.Text(empresa.sitioWeb),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.SizedBox(
                        width: 190,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              empresa.direccion,
                              style: pw.TextStyle(
                                color: pdfTheme.textMuted,
                                fontSize: 9 * fontScale,
                                fontWeight: pw.FontWeight.bold,
                                lineSpacing: 2,
                              ),
                            ),
                            if (showShippingAddress) ...[
                              pw.SizedBox(height: 6),
                              pw.Text(
                                isEnglish
                                    ? 'Ship to: Blvd. Agua Caliente 1444, Tijuana, BC'
                                    : 'Enviar a: Blvd. Agua Caliente 1444, Tijuana, BC',
                                style: pw.TextStyle(
                                  color: pdfTheme.secondary,
                                  fontSize: 9 * fontScale,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (showPaidStamp)
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(top: 8),
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _mix(
                          pdfTheme.secondary,
                          pdfTheme.background,
                          0.85,
                        ),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: pdfTheme.secondary),
                      ),
                      child: pw.Text(
                        isEnglish ? 'PAID' : 'PAGADO',
                        style: pw.TextStyle(
                          color: pdfTheme.secondary,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 20),
                pw.Text(
                  isEnglish ? 'QUOTE' : 'COTIZACION',
                  style: pw.TextStyle(
                    fontSize: 16 * fontScale,
                    fontWeight: pw.FontWeight.bold,
                    color: pdfTheme.primary,
                    letterSpacing: 0.6,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  height: pdfTheme.ruleThickness,
                  color: pdfTheme.rule,
                ),
                pw.SizedBox(height: 14),
                pw.Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  children: [
                    _metaInline(
                      isEnglish ? 'Number' : 'Numero',
                      cotizacion.folio,
                      pdfTheme,
                    ),
                    _metaInline(
                      isEnglish ? 'Issue date' : 'Fecha de cotizacion',
                      dateFormat.format(cotizacion.fechaEmision),
                      pdfTheme,
                    ),
                    _metaInline(
                      isEnglish ? 'Due date' : 'Fecha de vencimiento',
                      dateFormat.format(cotizacion.fechaVencimiento),
                      pdfTheme,
                    ),
                    _metaInline(
                      isEnglish ? 'Client' : 'Cliente',
                      cliente.nombre,
                      pdfTheme,
                    ),
                    _metaInline(
                      isEnglish ? 'Quoted total' : 'Total cotizado',
                      currency.format(cotizacion.total),
                      pdfTheme,
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(color: pdfTheme.border),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1.2),
                    4: const pw.FlexColumnWidth(1.2),
                    5: const pw.FlexColumnWidth(1.6),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: pdfTheme.accentPanel),
                      children: [
                        _cell(
                          isEnglish ? 'Item' : 'Concepto',
                          header: true,
                          color: pdfTheme.primary,
                        ),
                        _cell(
                          isEnglish ? 'Description' : 'Descripcion',
                          header: true,
                          color: pdfTheme.primary,
                        ),
                        _cell(
                          isEnglish ? 'Unit Cost' : 'Coste unitario',
                          header: true,
                          color: pdfTheme.primary,
                        ),
                        _cell(
                          isEnglish ? 'Quantity' : 'Cantidad',
                          header: true,
                          color: pdfTheme.primary,
                        ),
                        _cell(
                          isEnglish ? 'Tax' : 'Impuesto',
                          header: true,
                          color: pdfTheme.primary,
                        ),
                        _cell(
                          isEnglish ? 'Total' : 'Total',
                          header: true,
                          color: pdfTheme.primary,
                        ),
                      ],
                    ),
                    ...detalles.map(
                      (d) => pw.TableRow(
                        children: [
                          _cell(d.concepto, color: pdfTheme.textPrimary),
                          _cell(d.descripcion, color: pdfTheme.textPrimary),
                          _cell(
                            currency.format(d.precioUnitario),
                            color: pdfTheme.textPrimary,
                          ),
                          _cell(
                            d.cantidad.toStringAsFixed(2),
                            color: pdfTheme.textPrimary,
                          ),
                          _cell(
                            '${d.impuestoPorcentaje.toStringAsFixed(0)}%',
                            color: pdfTheme.textPrimary,
                          ),
                          _cell(
                            currency.format(d.importe),
                            color: pdfTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 260,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: pdfTheme.surface,
                      border: pw.Border.all(color: pdfTheme.border),
                      borderRadius: pw.BorderRadius.circular(pdfTheme.radius),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _totalLine(
                          isEnglish ? 'Subtotal' : 'Subtotal',
                          currency.format(cotizacion.subtotal),
                          labelColor: pdfTheme.textMuted,
                          valueColor: pdfTheme.primary,
                        ),
                        _totalLine(
                          isEnglish ? 'Discount' : 'Descuento',
                          currency.format(cotizacion.descuentoTotal),
                          labelColor: pdfTheme.textMuted,
                          valueColor: pdfTheme.textPrimary,
                        ),
                        _totalLine(
                          isEnglish ? 'Tax' : 'Impuesto',
                          currency.format(cotizacion.impuestoTotal),
                          labelColor: pdfTheme.textMuted,
                          valueColor: pdfTheme.textPrimary,
                        ),
                        pw.Divider(color: pdfTheme.border),
                        _totalLine(
                          isEnglish ? 'Total' : 'Total',
                          currency.format(cotizacion.total),
                          strong: true,
                          labelColor: pdfTheme.textMuted,
                          valueColor: pdfTheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (embedAttachments) ...[
                  pw.SizedBox(height: 14),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: pdfTheme.surface,
                      border: pw.Border.all(color: pdfTheme.border),
                      borderRadius: pw.BorderRadius.circular(pdfTheme.radius),
                    ),
                    child: pw.Text(
                      isEnglish
                          ? 'Attachments included: ficha-tecnica.pdf, evidencia-obra.jpg'
                          : 'Adjuntos incluidos: ficha-tecnica.pdf, evidencia-obra.jpg',
                      style: pw.TextStyle(
                        color: pdfTheme.textMuted,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                ..._buildRichTextSection(
                  label: isEnglish ? 'Terms' : 'Términos',
                  stored: cotizacion.terminos,
                  labelStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: pdfTheme.textPrimary,
                  ),
                  contentStyle: const pw.TextStyle(fontSize: 10),
                ),
                ..._buildRichTextSection(
                  label: isEnglish ? 'Notes' : 'Notas',
                  stored: cotizacion.notas,
                  labelStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: pdfTheme.textPrimary,
                  ),
                  contentStyle: const pw.TextStyle(fontSize: 10),
                ),
                if (richTextPlainTextFromStorage(
                  cotizacion.piePagina,
                ).isNotEmpty) ...[
                  pw.SizedBox(height: 18),
                  _buildRichTextDocument(
                    cotizacion.piePagina,
                    baseStyle: pw.TextStyle(
                      fontSize: 9,
                      color: pdfTheme.textMuted,
                    ),
                  ),
                ],
              ],
      ),
    );

    final bytes = await pdf.save();
    if (useCache) {
      _pdfCache[cacheKey] = bytes;
      if (_pdfCache.length > 24) {
        _pdfCache.remove(_pdfCache.keys.first);
      }
    }
    return bytes;
  }

  static Future<Map<String, dynamic>> _getEmpresaActualCached(
    SupabaseClient client,
  ) async {
    final now = DateTime.now();
    if (_empresaActualCache != null && _empresaActualCacheAt != null) {
      if (now.difference(_empresaActualCacheAt!).inSeconds <= 10) {
        return _empresaActualCache!;
      }
    }
    final raw = await client.rpc('get_empresa_actual');
    final parsed = (raw as Map).cast<String, dynamic>();
    _empresaActualCache = parsed;
    _empresaActualCacheAt = now;
    return parsed;
  }

  static Map<String, dynamic> _disenoQuoteFromEmpresa(EmpresaPerfil empresa) {
    return <String, dynamic>{
      'preset_diseno': empresa.themeSeleccionado,
      'page_orientation': empresa.quotePageOrientation,
      'page_size': empresa.quotePageSize,
      'font_size': empresa.quoteFontSize,
      'logo_size_mode': empresa.quoteLogoSizeMode,
      'logo_size_value': empresa.quoteLogoSizeValue,
      'fuente_primaria': empresa.quotePrimaryFont,
      'fuente_secundaria': empresa.quoteSecondaryFont,
      'show_paid_stamp': empresa.quoteShowPaidStamp,
      'show_shipping_address': empresa.quoteShowShippingAddress,
      'embed_attachments': empresa.quoteEmbedAttachments,
      'show_page_number': empresa.quoteShowPageNumber,
    };
  }

  static String _stableJsonSignature(Map<String, dynamic> value) {
    final entries = value.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final sorted = <String, dynamic>{};
    for (final entry in entries) {
      sorted[entry.key] = entry.value;
    }
    return jsonEncode(sorted);
  }

  static Future<_QuotePdfSourceData> _loadQuoteSourceData(
    SupabaseClient client,
    Cotizacion cotizacion,
    bool isEnglish, {
    required bool useCache,
  }) async {
    final sourceKey = [
      cotizacion.id,
      cotizacion.clienteId,
      cotizacion.updatedAt.microsecondsSinceEpoch,
    ].join('|');

    if (useCache) {
      final cached = _quoteDataCache[sourceKey];
      if (cached != null) return cached;
      final inFlight = _quoteDataInFlight[sourceKey];
      if (inFlight != null) return inFlight;
    }

    final future = () async {
      final clienteFuture = client
          .from('clientes')
          .select()
          .eq('id', cotizacion.clienteId)
          .maybeSingle();
      final detalleFuture = client.rpc(
        'list_cotizacion_detalles',
        params: {'p_cotizacion_id': cotizacion.id},
      );
      final parallelData = await Future.wait<dynamic>([
        clienteFuture,
        detalleFuture,
      ]);
      final clienteRow = parallelData[0] as Map<String, dynamic>?;
      final detalleRows = parallelData[1] as List;

      final cliente = clienteRow == null
          ? Cliente(
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
            )
          : Cliente(
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

      final detalles =
          detalleRows
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

      return _QuotePdfSourceData(cliente: cliente, detalles: detalles);
    }();

    if (useCache) {
      _quoteDataInFlight[sourceKey] = future;
    }

    try {
      final result = await future;
      if (useCache) {
        _quoteDataCache[sourceKey] = result;
        if (_quoteDataCache.length > 24) {
          _quoteDataCache.remove(_quoteDataCache.keys.first);
        }
      }
      return result;
    } finally {
      _quoteDataInFlight.remove(sourceKey);
    }
  }

  static Future<_CotizacionPdfFonts> _loadFonts(String preferredFamily) {
    if (_fontsFuture != null && _cachedFontFamily == preferredFamily) {
      return _fontsFuture!;
    }
    _cachedFontFamily = preferredFamily;
    _fontsFuture = () async {
      switch (preferredFamily.toLowerCase()) {
        case 'montserrat':
          return _CotizacionPdfFonts(
            base: await PdfGoogleFonts.montserratRegular(),
            bold: await PdfGoogleFonts.montserratBold(),
            italic: await PdfGoogleFonts.montserratItalic(),
            boldItalic: await PdfGoogleFonts.montserratBoldItalic(),
          );
        case 'lora':
          return _CotizacionPdfFonts(
            base: await PdfGoogleFonts.loraRegular(),
            bold: await PdfGoogleFonts.loraBold(),
            italic: await PdfGoogleFonts.loraItalic(),
            boldItalic: await PdfGoogleFonts.loraBoldItalic(),
          );
        case 'poppins':
          return _CotizacionPdfFonts(
            base: await PdfGoogleFonts.poppinsRegular(),
            bold: await PdfGoogleFonts.poppinsBold(),
            italic: await PdfGoogleFonts.poppinsItalic(),
            boldItalic: await PdfGoogleFonts.poppinsBoldItalic(),
          );
        case 'playfair display':
          return _CotizacionPdfFonts(
            base: await PdfGoogleFonts.playfairDisplayRegular(),
            bold: await PdfGoogleFonts.playfairDisplayBold(),
            italic: await PdfGoogleFonts.playfairDisplayItalic(),
            boldItalic: await PdfGoogleFonts.playfairDisplayBoldItalic(),
          );
        case 'merriweather':
          return _CotizacionPdfFonts(
            base: await PdfGoogleFonts.merriweatherRegular(),
            bold: await PdfGoogleFonts.merriweatherBold(),
            italic: await PdfGoogleFonts.merriweatherItalic(),
            boldItalic: await PdfGoogleFonts.merriweatherBoldItalic(),
          );
        case 'open sans':
          return _CotizacionPdfFonts(
            base: await PdfGoogleFonts.openSansRegular(),
            bold: await PdfGoogleFonts.openSansBold(),
            italic: await PdfGoogleFonts.openSansItalic(),
            boldItalic: await PdfGoogleFonts.openSansBoldItalic(),
          );
        case 'arimo':
        default:
          return _CotizacionPdfFonts(
            base: await PdfGoogleFonts.arimoRegular(),
            bold: await PdfGoogleFonts.arimoBold(),
            italic: await PdfGoogleFonts.arimoItalic(),
            boldItalic: await PdfGoogleFonts.arimoBoldItalic(),
          );
      }
    }();
    return _fontsFuture!;
  }

  static List<pw.Widget> _buildRichTextSection({
    required String label,
    required String stored,
    required pw.TextStyle labelStyle,
    required pw.TextStyle contentStyle,
  }) {
    if (richTextPlainTextFromStorage(stored).isEmpty) {
      return const [];
    }

    return [
      pw.SizedBox(height: 16),
      pw.Text(label, style: labelStyle),
      pw.SizedBox(height: 6),
      _buildRichTextDocument(stored, baseStyle: contentStyle),
    ];
  }

  static pw.Widget _buildRichTextDocument(
    String stored, {
    required pw.TextStyle baseStyle,
  }) {
    final lines = _parseRichTextLines(stored);
    if (lines.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final children = <pw.Widget>[];
    var orderedIndex = 1;
    for (final line in lines) {
      final listType = line.attributes['list']?.toString();
      if (listType != 'ordered') {
        orderedIndex = 1;
      }

      children.add(
        _buildRichTextLine(
          line,
          baseStyle: baseStyle,
          orderedIndex: listType == 'ordered' ? orderedIndex++ : null,
        ),
      );
      children.add(pw.SizedBox(height: 4));
    }

    children.removeLast();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  static pw.Widget _buildRichTextLine(
    _PdfRichTextLine line, {
    required pw.TextStyle baseStyle,
    int? orderedIndex,
  }) {
    if (line.spans.isEmpty) {
      return pw.SizedBox(height: baseStyle.fontSize ?? 10);
    }

    final lineStyle = _lineBaseStyle(baseStyle, line.attributes);
    final text = pw.RichText(
      text: pw.TextSpan(
        children: line.spans
            .map((span) {
              return pw.TextSpan(
                text: span.text,
                style: _spanStyle(
                  baseStyle: lineStyle,
                  attributes: span.attributes,
                ),
              );
            })
            .toList(growable: false),
      ),
      textAlign: _textAlignForAttributes(line.attributes),
    );

    final indent = ((line.attributes['indent'] as num?)?.toInt() ?? 0) * 12.0;
    final listType = line.attributes['list']?.toString();
    final quoted = line.attributes['blockquote'] == true;

    pw.Widget child = indent > 0
        ? pw.Padding(
            padding: pw.EdgeInsets.only(left: indent),
            child: text,
          )
        : text;

    if (listType == 'bullet' ||
        listType == 'ordered' ||
        listType == 'checked' ||
        listType == 'unchecked') {
      final marker = switch (listType) {
        'ordered' => '${orderedIndex ?? 1}.',
        'checked' => '[x]',
        'unchecked' => '[ ]',
        _ => '•',
      };
      child = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 6),
            child: pw.Text(marker, style: lineStyle),
          ),
          pw.Expanded(child: child),
        ],
      );
    }

    if (quoted) {
      child = pw.Container(
        padding: const pw.EdgeInsets.only(left: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColor.fromHex('#D1D5DB'), width: 2),
          ),
        ),
        child: child,
      );
    }

    return child;
  }

  static List<_PdfRichTextLine> _parseRichTextLines(String stored) {
    final ops = richTextDeltaOpsFromStorage(stored);
    final lines = <_PdfRichTextLine>[];
    final currentSpans = <_PdfRichTextSpan>[];

    for (final operation in ops) {
      final insert = operation['insert'];
      final attributes = Map<String, dynamic>.from(
        (operation['attributes'] as Map?) ?? const <String, dynamic>{},
      );

      if (insert is! String) {
        continue;
      }

      final segments = insert.split('\n');
      for (var index = 0; index < segments.length; index++) {
        final segment = segments[index];
        if (segment.isNotEmpty) {
          currentSpans.add(
            _PdfRichTextSpan(text: segment, attributes: attributes),
          );
        }

        final closesLine = index < segments.length - 1;
        if (closesLine) {
          lines.add(
            _PdfRichTextLine(
              spans: List<_PdfRichTextSpan>.from(currentSpans),
              attributes: _lineAttributes(attributes),
            ),
          );
          currentSpans.clear();
        }
      }
    }

    if (currentSpans.isNotEmpty) {
      lines.add(
        _PdfRichTextLine(
          spans: List<_PdfRichTextSpan>.from(currentSpans),
          attributes: const <String, dynamic>{},
        ),
      );
    }

    return lines;
  }

  static Map<String, dynamic> _lineAttributes(Map<String, dynamic> attributes) {
    const blockKeys = <String>{
      'header',
      'align',
      'list',
      'blockquote',
      'code-block',
      'indent',
      'direction',
    };
    return {
      for (final entry in attributes.entries)
        if (blockKeys.contains(entry.key)) entry.key: entry.value,
    };
  }

  static pw.TextStyle _lineBaseStyle(
    pw.TextStyle baseStyle,
    Map<String, dynamic> attributes,
  ) {
    final header = (attributes['header'] as num?)?.toInt();
    if (header == null) {
      return baseStyle;
    }

    final size = switch (header) {
      1 => 20.0,
      2 => 18.0,
      3 => 16.0,
      4 => 14.0,
      5 => 12.0,
      _ => 11.0,
    };

    return baseStyle.copyWith(fontSize: size, fontWeight: pw.FontWeight.bold);
  }

  static pw.TextStyle _spanStyle({
    required pw.TextStyle baseStyle,
    required Map<String, dynamic> attributes,
  }) {
    final decorations = <pw.TextDecoration>[];
    if (attributes['underline'] == true) {
      decorations.add(pw.TextDecoration.underline);
    }
    if (attributes['strike'] == true) {
      decorations.add(pw.TextDecoration.lineThrough);
    }

    return baseStyle.copyWith(
      fontWeight: attributes['bold'] == true
          ? pw.FontWeight.bold
          : baseStyle.fontWeight,
      fontStyle: attributes['italic'] == true
          ? pw.FontStyle.italic
          : baseStyle.fontStyle,
      fontSize: _fontSizeFromAttributes(attributes) ?? baseStyle.fontSize,
      color: _pdfColorFromAttribute(attributes['color']) ?? baseStyle.color,
      background: _pdfColorFromAttribute(attributes['background']) != null
          ? pw.BoxDecoration(
              color: _pdfColorFromAttribute(attributes['background']),
            )
          : baseStyle.background,
      decoration: decorations.isEmpty
          ? baseStyle.decoration
          : pw.TextDecoration.combine(decorations),
    );
  }

  static double? _fontSizeFromAttributes(Map<String, dynamic> attributes) {
    if (attributes['small'] == true) {
      return 10;
    }
    final size = attributes['size'];
    if (size is num) {
      return size.toDouble();
    }
    return switch (size?.toString()) {
      '12' => 12,
      '14' => 14,
      '16' => 16,
      '18' => 18,
      '24' => 24,
      'small' => 10,
      'large' => 18,
      'huge' => 24,
      _ => null,
    };
  }

  static PdfColor? _pdfColorFromAttribute(Object? value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final normalized = raw.startsWith('#') ? raw : '#$raw';
    try {
      return PdfColor.fromHex(normalized);
    } catch (_) {
      return null;
    }
  }

  static pw.TextAlign _textAlignForAttributes(Map<String, dynamic> attributes) {
    return switch (attributes['align']?.toString()) {
      'center' => pw.TextAlign.center,
      'right' => pw.TextAlign.right,
      'justify' => pw.TextAlign.justify,
      _ => pw.TextAlign.left,
    };
  }

  static pw.Widget _cell(
    String text, {
    bool header = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
    pw.FontWeight? fontWeight,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: header ? 10 : 9,
          fontWeight:
              fontWeight ??
              (header ? pw.FontWeight.bold : pw.FontWeight.normal),
          color: color ?? PdfColor.fromHex(header ? '#1F2937' : '#374151'),
        ),
      ),
    );
  }

  static pw.Widget _totalLine(
    String label,
    String value, {
    bool strong = false,
    PdfColor? labelColor,
    PdfColor? valueColor,
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
              color: labelColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaInline(
    String label,
    String value,
    _QuotePdfTheme theme,
  ) {
    return pw.SizedBox(
      width: 118,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: theme.textMuted,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.4,
              color: theme.textPrimary,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildCorporateQuoteBody({
    required Cotizacion cotizacion,
    required Cliente cliente,
    required List<DetalleCotizacion> detalles,
    required EmpresaPerfil empresa,
    required _QuotePdfTheme pdfTheme,
    required NumberFormat currency,
    required DateFormat dateFormat,
    required bool isEnglish,
    required pw.ImageProvider? logoProvider,
    required double fontScale,
    required double logoExtent,
    required bool showPaidStamp,
  }) {
    final notes = richTextPlainTextFromStorage(cotizacion.notas).trim();
    final orderNumber = cliente.idNumber.trim().isNotEmpty
        ? cliente.idNumber.trim()
        : (cliente.numero.trim().isNotEmpty ? cliente.numero.trim() : '-');
    final clientBlockLines = <String>[
      if (cliente.empresa.trim().isNotEmpty) cliente.empresa.trim(),
      if (cliente.nombre.trim().isNotEmpty) cliente.nombre.trim(),
      if (cliente.idNumber.trim().isNotEmpty) cliente.idNumber.trim(),
      if (cliente.rfc.trim().isNotEmpty) cliente.rfc.trim(),
      ..._compactAddressLines(cliente.direccion),
      if (cliente.telefono.trim().isNotEmpty) cliente.telefono.trim(),
      if (cliente.correo.trim().isNotEmpty) cliente.correo.trim(),
    ];

    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: pdfTheme.background),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: (logoExtent * 2.2).clamp(110, 220),
              child: logoProvider == null
                  ? pw.SizedBox()
                  : pw.Container(
                      height: logoExtent,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
                    ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _corpHeaderText(
                    empresa.nombreComercial,
                    size: 11 * fontScale,
                    bold: true,
                  ),
                  if (empresa.rfc.trim().isNotEmpty)
                    _corpHeaderText(empresa.rfc, size: 10 * fontScale),
                  if (empresa.telefono.trim().isNotEmpty)
                    _corpHeaderText(empresa.telefono, size: 10 * fontScale),
                  if (empresa.sitioWeb.trim().isNotEmpty)
                    _corpHeaderText(empresa.sitioWeb, size: 10 * fontScale),
                  if (empresa.correo.trim().isNotEmpty)
                    _corpHeaderText(empresa.correo, size: 10 * fontScale),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.SizedBox(
              width: 180,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final line in _compactAddressLines(empresa.direccion))
                    _corpHeaderText(line, size: 10 * fontScale),
                ],
              ),
            ),
          ],
        ),
      ),
      if (showPaidStamp)
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _mix(pdfTheme.secondary, PdfColors.white, 0.82),
              border: pw.Border.all(color: pdfTheme.secondary),
            ),
            child: pw.Text(
              isEnglish ? 'PAID' : 'PAGADO',
              style: pw.TextStyle(
                color: pdfTheme.secondary,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      pw.SizedBox(height: 14),
      pw.Text(
        isEnglish ? 'QUOTE' : 'COTIZACION',
        style: pw.TextStyle(
          fontSize: 15 * fontScale,
          color: pdfTheme.textPrimary,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(height: 1, color: PdfColor.fromHex('#C9CDD3')),
      pw.SizedBox(height: 10),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                _corpMetaRow(isEnglish ? 'Number' : 'Número', cotizacion.folio),
                _corpMetaRow(
                  isEnglish ? 'Order Number' : 'Número de Orden',
                  orderNumber,
                ),
                _corpMetaRow(
                  isEnglish ? 'Issue Date' : 'Fecha de cotización',
                  dateFormat.format(cotizacion.fechaEmision),
                ),
                _corpMetaRow(
                  isEnglish ? 'Due Date' : 'Fecha de vencimiento',
                  dateFormat.format(cotizacion.fechaVencimiento),
                ),
                _corpMetaRow(
                  isEnglish ? 'Total Quoted' : 'Total cotizado',
                  currency.format(cotizacion.total),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 28),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  cliente.nombre.trim().isEmpty
                      ? (isEnglish ? 'Client' : 'Cliente')
                      : cliente.nombre.trim(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: pdfTheme.textPrimary,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                for (final line in clientBlockLines)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      line,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        color: pdfTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      _buildCorporateItemsTable(
        rows: detalles,
        currency: currency,
        isEnglish: isEnglish,
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isEnglish ? 'Public notes' : 'Notas públicas',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: pdfTheme.textPrimary,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  notes.isEmpty ? '-' : notes,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    color: pdfTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.SizedBox(
            width: 210,
            child: pw.Column(
              children: [
                _corpTotalRow(
                  isEnglish ? 'Subtotal' : 'Subtotal',
                  currency.format(cotizacion.subtotal),
                ),
                _corpTotalRow(
                  isEnglish ? 'Discount' : 'Descuento',
                  currency.format(cotizacion.descuentoTotal),
                ),
                _corpTotalRow(
                  isEnglish
                      ? 'Tax ${cotizacion.impuestoPorcentaje.toStringAsFixed(0)}%'
                      : 'Impuesto ${cotizacion.impuestoPorcentaje.toStringAsFixed(0)}%',
                  currency.format(cotizacion.impuestoTotal),
                ),
                _corpTotalRow(
                  isEnglish ? 'Total' : 'Total',
                  currency.format(cotizacion.total),
                  strong: true,
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static String _orderNumberForCliente(Cliente cliente) {
    return cliente.idNumber.trim().isNotEmpty
        ? cliente.idNumber.trim()
        : (cliente.numero.trim().isNotEmpty ? cliente.numero.trim() : '-');
  }

  static List<String> _clientBlockLines(Cliente cliente) {
    return <String>[
      if (cliente.empresa.trim().isNotEmpty) cliente.empresa.trim(),
      if (cliente.nombre.trim().isNotEmpty) cliente.nombre.trim(),
      if (cliente.idNumber.trim().isNotEmpty) cliente.idNumber.trim(),
      if (cliente.rfc.trim().isNotEmpty) cliente.rfc.trim(),
      ..._compactAddressLines(cliente.direccion),
      if (cliente.telefono.trim().isNotEmpty) cliente.telefono.trim(),
      if (cliente.correo.trim().isNotEmpty) cliente.correo.trim(),
    ];
  }

  static List<String> _companyBlockLines(EmpresaPerfil empresa) {
    return <String>[
      if (empresa.nombreFiscal.trim().isNotEmpty) empresa.nombreFiscal.trim(),
      if (empresa.rfc.trim().isNotEmpty) empresa.rfc.trim(),
      if (empresa.telefono.trim().isNotEmpty) empresa.telefono.trim(),
      if (empresa.correo.trim().isNotEmpty) empresa.correo.trim(),
      if (empresa.sitioWeb.trim().isNotEmpty) empresa.sitioWeb.trim(),
      ..._compactAddressLines(empresa.direccion),
    ];
  }

  static List<String> _compactAddressLines(String raw) {
    return raw
        .split(RegExp(r'\n|,'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  static pw.Widget _corpHeaderText(
    String value, {
    required double size,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: size,
          color: PdfColor.fromHex('#111111'),
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _corpMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 95,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#111111'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#111111'),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCorporateItemsTable({
    required List<DetalleCotizacion> rows,
    required NumberFormat currency,
    required bool isEnglish,
  }) {
    final contentRows = rows.isEmpty ? <DetalleCotizacion?>[null] : rows;
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#D1D5DB')),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2.4),
        2: const pw.FlexColumnWidth(1.7),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E5E7EB')),
          children: [
            _cell(isEnglish ? 'Item' : 'Concepto', header: true),
            _cell(isEnglish ? 'Description' : 'Descripción', header: true),
            _cell(isEnglish ? 'Unit Cost' : 'Coste unitario', header: true),
            _cell(isEnglish ? 'Qty' : 'Cantidad', header: true),
            _cell(isEnglish ? 'Tax' : 'Impuesto', header: true),
            _cell(
              isEnglish ? 'Total' : 'Total',
              header: true,
              align: pw.TextAlign.right,
            ),
          ],
        ),
        for (var index = 0; index < contentRows.length; index++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven
                  ? PdfColor.fromHex('#F3F4F6')
                  : PdfColor.fromHex('#E5E7EB'),
            ),
            children: [
              _cell(contentRows[index]?.concepto ?? '-'),
              _cell(contentRows[index]?.descripcion ?? '-'),
              _cell(
                contentRows[index] == null
                    ? '-'
                    : currency.format(contentRows[index]!.precioUnitario),
              ),
              _cell(
                contentRows[index] == null
                    ? '-'
                    : _compactNumber(contentRows[index]!.cantidad),
              ),
              _cell(
                contentRows[index] == null
                    ? '-'
                    : '${contentRows[index]!.impuestoPorcentaje.toStringAsFixed(0)}%',
              ),
              _cell(
                contentRows[index] == null
                    ? '-'
                    : currency.format(contentRows[index]!.importe),
                align: pw.TextAlign.right,
                fontWeight: pw.FontWeight.bold,
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _corpTotalRow(
    String label,
    String value, {
    bool strong = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#111111'),
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#111111'),
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static String _compactNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  static List<pw.Widget> _buildMinimalQuoteBody({
    required Cotizacion cotizacion,
    required Cliente cliente,
    required List<DetalleCotizacion> detalles,
    required EmpresaPerfil empresa,
    required _QuotePdfTheme pdfTheme,
    required NumberFormat currency,
    required DateFormat dateFormat,
    required bool isEnglish,
    required pw.ImageProvider? logoProvider,
    required double fontScale,
    required double logoExtent,
  }) {
    final accent = pdfTheme.primary;
    final lightAccent = pdfTheme.rule;
    final textDark = pdfTheme.textPrimary;
    final textMuted = pdfTheme.textMuted;
    final rowItems = detalles.isEmpty ? <DetalleCotizacion?>[null] : detalles;
    final companyBlockLines = _companyBlockLines(empresa);
    final introText = richTextPlainTextFromStorage(cotizacion.notas).trim();
    final quoteIntro = introText;
    final clientAddress = _compactAddressLines(cliente.direccion);
    final clientPhone = cliente.telefono.trim();
    final leftContacts = <String>[
      if (empresa.correo.trim().isNotEmpty) empresa.correo.trim(),
      if (empresa.telefono.trim().isNotEmpty)
        isEnglish
            ? 'Call us at ${empresa.telefono.trim()}'
            : 'Llámanos al ${empresa.telefono.trim()}',
      if (empresa.direccion.trim().isNotEmpty)
        ..._compactAddressLines(empresa.direccion),
    ];

    return [
      pw.Container(
        color: pdfTheme.background,
        padding: const pw.EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: (logoExtent * 2.35).clamp(120, 240),
                  child: logoProvider == null
                      ? pw.SizedBox(height: logoExtent)
                      : pw.Container(
                          height: logoExtent,
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
                        ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (empresa.nombreComercial.trim().isNotEmpty)
                        pw.Text(
                          empresa.nombreComercial.trim().toUpperCase(),
                          style: pw.TextStyle(
                            color: accent,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 22 * fontScale,
                            letterSpacing: 0.8,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      pw.SizedBox(height: 2),
                      for (final line in companyBlockLines.take(5))
                        pw.Text(
                          line,
                          style: pw.TextStyle(color: textMuted, fontSize: 9.8),
                          textAlign: pw.TextAlign.right,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isEnglish ? 'Quote' : 'Cotización',
                        style: pw.TextStyle(
                          color: accent,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 56 * 0.36 * fontScale,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (quoteIntro.isNotEmpty)
                        pw.SizedBox(
                          width: 320,
                          child: pw.Text(
                            quoteIntro,
                            style: pw.TextStyle(
                              color: textDark,
                              fontSize: 10.2,
                              lineSpacing: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 18),
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        isEnglish ? 'CLIENT:' : 'CLIENTE:',
                        style: pw.TextStyle(
                          color: accent,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      if (cliente.nombre.trim().isNotEmpty)
                        pw.Text(
                          cliente.nombre.trim(),
                          style: pw.TextStyle(
                            color: textDark,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      for (final line in clientAddress)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            line,
                            style: pw.TextStyle(
                              color: textDark,
                              fontSize: 10.5,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      if (clientPhone.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                            clientPhone,
                            style: pw.TextStyle(
                              color: textDark,
                              fontSize: 10.5,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      pw.SizedBox(height: 26),
                      pw.Text(
                        '${isEnglish ? 'FOLIO' : 'FOLIO'} ${cotizacion.folio}',
                        style: pw.TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        dateFormat.format(cotizacion.fechaEmision),
                        style: pw.TextStyle(color: textMuted, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Container(height: 1, color: lightAccent),
            pw.SizedBox(height: 24),
            _buildMinimalTable(
              rows: rowItems,
              currency: currency,
              textDark: textDark,
              isEnglish: isEnglish,
            ),
            pw.SizedBox(height: 18),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _minimalSummaryRow(
                      isEnglish ? 'SUBTOTAL' : 'SUBTOTAL',
                      currency.format(cotizacion.subtotal),
                      textDark,
                    ),
                    _minimalSummaryRow(
                      isEnglish ? 'DISCOUNT' : 'DESCUENTO',
                      currency.format(cotizacion.descuentoTotal),
                      textDark,
                    ),
                    _minimalSummaryRow(
                      '${isEnglish ? 'TAX' : '% IMP'} ${cotizacion.impuestoPorcentaje.toStringAsFixed(0)}%',
                      currency.format(cotizacion.impuestoTotal),
                      textDark,
                    ),
                    _minimalSummaryRow(
                      isEnglish ? 'TOTAL' : 'TOTAL',
                      currency.format(cotizacion.total),
                      textDark,
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 28),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isEnglish ? 'Contacts:' : 'Contáctanos:',
                        style: pw.TextStyle(
                          color: accent,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 15 * 0.78,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      ...(leftContacts.isEmpty
                              ? [
                                  'hello@interiores.com',
                                  isEnglish
                                      ? 'Call us at 123 456 789'
                                      : 'Llámanos al 123 456 789',
                                  isEnglish
                                      ? '123 Any Street, Any City'
                                      : 'Calle Cualquiera 123 Cualquier Lugar',
                                ]
                              : leftContacts)
                          .map(
                            (line) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Text(
                                line,
                                style: pw.TextStyle(
                                  color: textDark,
                                  fontSize: 10.3,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
            ..._buildRichTextSection(
              label: isEnglish ? 'Terms' : 'Términos',
              stored: cotizacion.terminos,
              labelStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
              contentStyle: pw.TextStyle(fontSize: 10, color: textDark),
            ),
            ..._buildRichTextSection(
              label: isEnglish ? 'Notes' : 'Notas',
              stored: cotizacion.notas,
              labelStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
              contentStyle: pw.TextStyle(fontSize: 10, color: textDark),
            ),
            if (richTextPlainTextFromStorage(
              cotizacion.piePagina,
            ).isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _buildRichTextDocument(
                cotizacion.piePagina,
                baseStyle: pw.TextStyle(fontSize: 9.5, color: textMuted),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  static pw.Widget _buildMinimalTable({
    required List<DetalleCotizacion?> rows,
    required NumberFormat currency,
    required PdfColor textDark,
    required bool isEnglish,
  }) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(0.7),
        1: const pw.FlexColumnWidth(3.2),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          children: [
            _cell('NO', header: true, color: textDark),
            _cell(
              isEnglish ? 'DESCRIPTION' : 'DESCRIPCIÓN',
              header: true,
              color: textDark,
            ),
            _cell(
              isEnglish ? 'PRICE' : 'PRECIO',
              header: true,
              color: textDark,
            ),
            _cell(
              isEnglish ? 'QTY' : 'CANTIDAD',
              header: true,
              color: textDark,
            ),
            _cell(
              isEnglish ? 'TOTAL' : 'TOTAL',
              header: true,
              color: textDark,
              align: pw.TextAlign.right,
            ),
          ],
        ),
        for (var index = 0; index < rows.length; index++)
          pw.TableRow(
            children: [
              _cell('${index + 1}', color: textDark),
              _cell(
                rows[index]?.descripcion.trim().isNotEmpty == true
                    ? rows[index]!.descripcion
                    : (rows[index]?.concepto ?? '-'),
                color: textDark,
              ),
              _cell(
                rows[index] == null
                    ? '-'
                    : currency.format(rows[index]!.precioUnitario),
                color: textDark,
              ),
              _cell(
                rows[index] == null
                    ? '-'
                    : _compactNumber(rows[index]!.cantidad),
                color: textDark,
              ),
              _cell(
                rows[index] == null
                    ? '-'
                    : currency.format(rows[index]!.importe),
                color: textDark,
                align: pw.TextAlign.right,
                fontWeight: pw.FontWeight.bold,
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _minimalSummaryRow(
    String label,
    String value,
    PdfColor textColor, {
    bool strong = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.SizedBox(
            width: 86,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildDestacadoQuoteBody({
    required Cotizacion cotizacion,
    required Cliente cliente,
    required List<DetalleCotizacion> detalles,
    required EmpresaPerfil empresa,
    required _QuotePdfTheme pdfTheme,
    required NumberFormat currency,
    required DateFormat dateFormat,
    required bool isEnglish,
    required pw.ImageProvider? logoProvider,
    required double fontScale,
    required double logoExtent,
  }) {
    final primary = pdfTheme.primary;
    final secondary = pdfTheme.secondary;
    final dark = pdfTheme.textPrimary;
    final rows = detalles.isEmpty ? <DetalleCotizacion?>[null] : detalles;
    final orderNumber = _orderNumberForCliente(cliente);
    final companyBlockLines = _companyBlockLines(empresa);
    final clientBlockLines = _clientBlockLines(cliente);

    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isEnglish ? 'QUOTE' : 'COTIZACION',
                  style: pw.TextStyle(
                    color: primary,
                    fontSize: 24 * fontScale,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(width: 96, height: 2, color: secondary),
                pw.SizedBox(height: 8),
                if (logoProvider != null)
                  pw.Container(
                    width: logoExtent,
                    height: logoExtent,
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
                  ),
                pw.Text(
                  empresa.nombreComercial.trim().toUpperCase(),
                  style: pw.TextStyle(
                    color: dark,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${isEnglish ? 'Folio' : 'Folio'} ${cotizacion.folio} • ${dateFormat.format(cotizacion.fechaEmision)}',
                  style: pw.TextStyle(
                    color: secondary,
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                for (final line in companyBlockLines.take(5))
                  pw.Text(
                    line,
                    style: pw.TextStyle(color: dark, fontSize: 9.5),
                  ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: pdfTheme.surface,
          border: pw.Border.all(color: pdfTheme.border),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                '${isEnglish ? 'Client' : 'Cliente'}: ${cliente.nombre.trim().isEmpty ? '-' : cliente.nombre.trim()} · ${isEnglish ? 'Order' : 'Orden'}: $orderNumber',
                style: pw.TextStyle(
                  color: dark,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              currency.format(cotizacion.total),
              style: pw.TextStyle(
                color: secondary,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      if (clientBlockLines.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: clientBlockLines
                .take(6)
                .map(
                  (line) => pw.Text(
                    line,
                    style: pw.TextStyle(color: dark, fontSize: 9.5),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      pw.SizedBox(height: 12),
      pw.Table(
        border: pw.TableBorder.all(color: pdfTheme.border),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.8),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(1.4),
          3: const pw.FlexColumnWidth(1.2),
          4: const pw.FlexColumnWidth(1.6),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: pdfTheme.surface),
            children: [
              _cell('NO', header: true, color: dark),
              _cell(
                isEnglish ? 'DESCRIPTION' : 'DESCRIPCIÓN',
                header: true,
                color: dark,
              ),
              _cell(isEnglish ? 'PRICE' : 'PRECIO', header: true, color: dark),
              _cell(isEnglish ? 'QTY' : 'CANT.', header: true, color: dark),
              _cell(
                'TOTAL',
                header: true,
                color: dark,
                align: pw.TextAlign.right,
              ),
            ],
          ),
          for (var i = 0; i < rows.length; i++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i.isEven ? pdfTheme.surface : pdfTheme.background,
              ),
              children: [
                _cell('${i + 1}', color: dark),
                _cell(rows[i]?.descripcion ?? '-', color: dark),
                _cell(
                  rows[i] == null
                      ? '-'
                      : currency.format(rows[i]!.precioUnitario),
                  color: dark,
                ),
                _cell(
                  rows[i] == null ? '-' : _compactNumber(rows[i]!.cantidad),
                  color: dark,
                ),
                _cell(
                  rows[i] == null ? '-' : currency.format(rows[i]!.importe),
                  color: dark,
                  align: pw.TextAlign.right,
                  fontWeight: pw.FontWeight.bold,
                ),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdfTheme.accentPanel,
                border: pw.Border.all(color: pdfTheme.border),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isEnglish ? 'Quote details' : 'Detalles de cotización',
                    style: pw.TextStyle(
                      color: secondary,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${isEnglish ? 'Issue date' : 'Fecha emisión'}: ${dateFormat.format(cotizacion.fechaEmision)}',
                    style: pw.TextStyle(color: dark, fontSize: 10),
                  ),
                  pw.Text(
                    '${isEnglish ? 'Due date' : 'Fecha vencimiento'}: ${dateFormat.format(cotizacion.fechaVencimiento)}',
                    style: pw.TextStyle(color: dark, fontSize: 10),
                  ),
                  if (cliente.correo.trim().isNotEmpty)
                    pw.Text(
                      '${isEnglish ? 'Email' : 'Correo'}: ${cliente.correo.trim()}',
                      style: pw.TextStyle(color: dark, fontSize: 10),
                    ),
                  if (cliente.telefono.trim().isNotEmpty)
                    pw.Text(
                      '${isEnglish ? 'Phone' : 'Teléfono'}: ${cliente.telefono.trim()}',
                      style: pw.TextStyle(color: dark, fontSize: 10),
                    ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.SizedBox(
            width: 240,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdfTheme.accentPanel,
                border: pw.Border.all(color: pdfTheme.border),
              ),
              child: pw.Column(
                children: [
                  _minimalSummaryRow(
                    'SUBTOTAL',
                    currency.format(cotizacion.subtotal),
                    dark,
                  ),
                  _minimalSummaryRow(
                    isEnglish ? 'DISCOUNT' : 'DESCUENTO',
                    currency.format(cotizacion.descuentoTotal),
                    dark,
                  ),
                  _minimalSummaryRow(
                    '${isEnglish ? 'TAX' : 'IMPUESTO'} ${cotizacion.impuestoPorcentaje.toStringAsFixed(0)}%',
                    currency.format(cotizacion.impuestoTotal),
                    dark,
                  ),
                  _minimalSummaryRow(
                    'TOTAL',
                    currency.format(cotizacion.total),
                    dark,
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text(
        '${isEnglish ? 'Due date' : 'Fecha de vencimiento'}: ${dateFormat.format(cotizacion.fechaVencimiento)}',
        style: pw.TextStyle(color: dark, fontSize: 10),
      ),
      ..._buildRichTextSection(
        label: isEnglish ? 'Terms' : 'Términos',
        stored: cotizacion.terminos,
        labelStyle: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: dark,
        ),
        contentStyle: pw.TextStyle(fontSize: 10, color: dark),
      ),
      ..._buildRichTextSection(
        label: isEnglish ? 'Notes' : 'Notas',
        stored: cotizacion.notas,
        labelStyle: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: dark,
        ),
        contentStyle: pw.TextStyle(fontSize: 10, color: dark),
      ),
      if (richTextPlainTextFromStorage(cotizacion.piePagina).isNotEmpty) ...[
        pw.SizedBox(height: 14),
        _buildRichTextDocument(
          cotizacion.piePagina,
          baseStyle: pw.TextStyle(fontSize: 9.5, color: pdfTheme.textMuted),
        ),
      ],
    ];
  }

  static List<pw.Widget> _buildEditorialQuoteBody({
    required Cotizacion cotizacion,
    required Cliente cliente,
    required List<DetalleCotizacion> detalles,
    required EmpresaPerfil empresa,
    required _QuotePdfTheme pdfTheme,
    required NumberFormat currency,
    required DateFormat dateFormat,
    required bool isEnglish,
    required pw.ImageProvider? logoProvider,
    required double fontScale,
    required double logoExtent,
  }) {
    final ink = pdfTheme.textPrimary;
    final secondary = pdfTheme.secondary;
    final containerBg = _mix(secondary, pdfTheme.background, 0.975);
    final tableHeaderBg = _mix(secondary, pdfTheme.background, 0.965);
    final rows = detalles.isEmpty ? <DetalleCotizacion?>[null] : detalles;
    final orderNumber = _orderNumberForCliente(cliente);
    final companyBlockLines = _companyBlockLines(empresa);
    final clientBlockLines = _clientBlockLines(cliente);

    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: secondary, width: 1)),
        ),
        child: pw.Column(
          children: [
            if (logoProvider != null)
              pw.Container(
                width: (logoExtent * 1.15).clamp(44, 180),
                height: (logoExtent * 1.15).clamp(44, 180),
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
              ),
            if (companyBlockLines.isNotEmpty) pw.SizedBox(height: 4),
            for (final line in companyBlockLines.take(5))
              pw.Text(
                line,
                style: pw.TextStyle(color: pdfTheme.textMuted, fontSize: 9.3),
              ),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              '${isEnglish ? 'Quote' : 'Cotización'} ${cotizacion.folio}',
              style: pw.TextStyle(
                color: secondary,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            dateFormat.format(cotizacion.fechaEmision),
            style: pw.TextStyle(color: ink, fontSize: 10.5),
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        '${isEnglish ? 'For' : 'Para'}: ${cliente.nombre.trim().isEmpty ? '-' : cliente.nombre.trim()} • ${isEnglish ? 'Order' : 'Orden'}: $orderNumber',
        style: pw.TextStyle(color: ink, fontSize: 11),
      ),
      pw.SizedBox(height: 4),
      if (clientBlockLines.isNotEmpty)
        pw.Wrap(
          spacing: 10,
          runSpacing: 4,
          children: clientBlockLines
              .take(6)
              .map(
                (line) => pw.Text(
                  line,
                  style: pw.TextStyle(color: pdfTheme.textMuted, fontSize: 9.5),
                ),
              )
              .toList(growable: false),
        ),
      pw.SizedBox(height: 4),
      if (cliente.correo.trim().isNotEmpty)
        pw.Text(
          '${isEnglish ? 'Email' : 'Correo'}: ${cliente.correo.trim()}',
          style: pw.TextStyle(color: pdfTheme.textMuted, fontSize: 10),
        ),
      if (cliente.telefono.trim().isNotEmpty)
        pw.Text(
          '${isEnglish ? 'Phone' : 'Teléfono'}: ${cliente.telefono.trim()}',
          style: pw.TextStyle(color: pdfTheme.textMuted, fontSize: 10),
        ),
      pw.SizedBox(height: 12),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: containerBg,
                border: pw.Border.all(color: pdfTheme.border),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isEnglish ? 'Company data' : 'Datos de empresa',
                    style: pw.TextStyle(
                      color: ink,
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  for (final line in companyBlockLines.take(6))
                    pw.Text(
                      line,
                      style: pw.TextStyle(color: ink, fontSize: 9.5),
                    ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.SizedBox(
            width: 250,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: containerBg,
                border: pw.Border.all(color: pdfTheme.border),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isEnglish ? 'Quote data' : 'Datos de cotización',
                    style: pw.TextStyle(
                      color: secondary,
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${isEnglish ? 'Order number' : 'Número de orden'}: $orderNumber',
                    style: pw.TextStyle(color: ink, fontSize: 9.8),
                  ),
                  pw.Text(
                    '${isEnglish ? 'Issue date' : 'Fecha de emisión'}: ${dateFormat.format(cotizacion.fechaEmision)}',
                    style: pw.TextStyle(color: ink, fontSize: 9.8),
                  ),
                  pw.Text(
                    '${isEnglish ? 'Due date' : 'Fecha de vencimiento'}: ${dateFormat.format(cotizacion.fechaVencimiento)}',
                    style: pw.TextStyle(color: ink, fontSize: 9.8),
                  ),
                  pw.Text(
                    '${isEnglish ? 'Total quoted' : 'Total cotizado'}: ${currency.format(cotizacion.total)}',
                    style: pw.TextStyle(
                      color: secondary,
                      fontSize: 9.8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: pdfTheme.border),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.8),
          1: const pw.FlexColumnWidth(3.2),
          2: const pw.FlexColumnWidth(1.3),
          3: const pw.FlexColumnWidth(1.1),
          4: const pw.FlexColumnWidth(1.7),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: tableHeaderBg),
            children: [
              _cell('N°', header: true, color: ink),
              _cell(isEnglish ? 'ITEM' : 'CONCEPTO', header: true, color: ink),
              _cell(isEnglish ? 'UNIT' : 'UNITARIO', header: true, color: ink),
              _cell('QTY', header: true, color: ink),
              _cell(
                'TOTAL',
                header: true,
                color: ink,
                align: pw.TextAlign.right,
              ),
            ],
          ),
          for (var i = 0; i < rows.length; i++)
            pw.TableRow(
              children: [
                _cell('${i + 1}', color: ink),
                _cell(
                  rows[i]?.concepto.trim().isNotEmpty == true
                      ? rows[i]!.concepto
                      : (rows[i]?.descripcion ?? '-'),
                  color: ink,
                ),
                _cell(
                  rows[i] == null
                      ? '-'
                      : currency.format(rows[i]!.precioUnitario),
                  color: ink,
                ),
                _cell(
                  rows[i] == null ? '-' : _compactNumber(rows[i]!.cantidad),
                  color: ink,
                ),
                _cell(
                  rows[i] == null ? '-' : currency.format(rows[i]!.importe),
                  color: ink,
                  align: pw.TextAlign.right,
                  fontWeight: pw.FontWeight.bold,
                ),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 230,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: containerBg,
            border: pw.Border.all(color: pdfTheme.border),
          ),
          child: pw.Column(
            children: [
              _minimalSummaryRow(
                'SUBTOTAL',
                currency.format(cotizacion.subtotal),
                ink,
              ),
              _minimalSummaryRow(
                isEnglish ? 'DISCOUNT' : 'DESCUENTO',
                currency.format(cotizacion.descuentoTotal),
                ink,
              ),
              _minimalSummaryRow(
                '${isEnglish ? 'TAX' : 'IMPUESTO'} ${cotizacion.impuestoPorcentaje.toStringAsFixed(0)}%',
                currency.format(cotizacion.impuestoTotal),
                ink,
              ),
              _minimalSummaryRow(
                'TOTAL',
                currency.format(cotizacion.total),
                ink,
                strong: true,
              ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 14),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: containerBg,
          border: pw.Border.all(color: pdfTheme.border),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                '${isEnglish ? 'Issue date' : 'Fecha emisión'}: ${dateFormat.format(cotizacion.fechaEmision)}',
                style: pw.TextStyle(color: ink, fontSize: 10),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                '${isEnglish ? 'Due date' : 'Fecha vencimiento'}: ${dateFormat.format(cotizacion.fechaVencimiento)}',
                style: pw.TextStyle(color: ink, fontSize: 10),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      ..._buildRichTextSection(
        label: isEnglish ? 'Terms' : 'Términos',
        stored: cotizacion.terminos,
        labelStyle: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: ink,
        ),
        contentStyle: pw.TextStyle(fontSize: 10, color: ink),
      ),
      ..._buildRichTextSection(
        label: isEnglish ? 'Notes' : 'Notas',
        stored: cotizacion.notas,
        labelStyle: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: ink,
        ),
        contentStyle: pw.TextStyle(fontSize: 10, color: ink),
      ),
      if (richTextPlainTextFromStorage(cotizacion.piePagina).isNotEmpty) ...[
        pw.SizedBox(height: 14),
        _buildRichTextDocument(
          cotizacion.piePagina,
          baseStyle: pw.TextStyle(fontSize: 9.5, color: pdfTheme.textMuted),
        ),
      ],
    ];
  }

  static List<pw.Widget> _buildIndustrialQuoteBody({
    required Cotizacion cotizacion,
    required Cliente cliente,
    required List<DetalleCotizacion> detalles,
    required EmpresaPerfil empresa,
    required _QuotePdfTheme pdfTheme,
    required NumberFormat currency,
    required DateFormat dateFormat,
    required bool isEnglish,
    required pw.ImageProvider? logoProvider,
    required double fontScale,
    required double logoExtent,
  }) {
    final headerBlue = pdfTheme.primary;
    final stripeBlue = pdfTheme.accentPanel;
    final lightBorder = pdfTheme.border;
    final lineGray = pdfTheme.rule;
    final textDark = pdfTheme.textPrimary;
    final muted = pdfTheme.textMuted;
    final onHeader = _contrastColor(headerBlue);
    final rows = detalles.isEmpty ? <DetalleCotizacion?>[null] : detalles;
    final orderNumber = _orderNumberForCliente(cliente);
    final companyBlockLines = _companyBlockLines(empresa);
    final clientBlockLines = _clientBlockLines(cliente);
    final taxRate = cotizacion.impuestoPorcentaje;
    const paid = 0.0;
    final balance = cotizacion.total.clamp(0, double.infinity).toDouble();
    final retIsrRate = 0.0125;
    final retIsrBase = (cotizacion.subtotal - cotizacion.descuentoTotal)
        .clamp(0, double.infinity)
        .toDouble();
    final retIsrAmount = cotizacion.retIsr
        ? (retIsrBase * retIsrRate).clamp(0, double.infinity).toDouble()
        : 0.0;
    final leftContact = <String>[
      if (empresa.telefono.trim().isNotEmpty) empresa.telefono.trim(),
      if (empresa.correo.trim().isNotEmpty) empresa.correo.trim(),
      if (empresa.direccion.trim().isNotEmpty) empresa.direccion.trim(),
    ];

    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoProvider != null)
                  pw.Container(
                    width: logoExtent,
                    height: logoExtent,
                    alignment: pw.Alignment.center,
                    child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
                  ),
                if (logoProvider != null) pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        empresa.nombreComercial.trim().toUpperCase(),
                        style: pw.TextStyle(
                          color: textDark,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 17 * fontScale,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      if (companyBlockLines.isNotEmpty) pw.SizedBox(height: 3),
                      for (final line in companyBlockLines.take(4))
                        pw.Text(
                          line,
                          style: pw.TextStyle(color: muted, fontSize: 9.2),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Text(
            isEnglish ? 'INVOICE' : 'COTIZACIÓN',
            style: pw.TextStyle(
              color: headerBlue,
              fontWeight: pw.FontWeight.bold,
              fontSize: 26 * fontScale,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              height: 2,
              color: lineGray,
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Container(width: 42, color: headerBlue),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            empresa.sitioWeb.trim().toUpperCase(),
            style: pw.TextStyle(
              color: textDark,
              fontSize: 10 * fontScale,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 22),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isEnglish ? 'Invoice to :' : 'Cotización para :',
                  style: pw.TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  cliente.nombre.trim().isEmpty ? '-' : cliente.nombre.trim(),
                  style: pw.TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                if (cliente.telefono.trim().isNotEmpty)
                  pw.Text(
                    cliente.telefono.trim(),
                    style: pw.TextStyle(color: muted, fontSize: 10),
                  ),
                if (cliente.correo.trim().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      cliente.correo.trim(),
                      style: pw.TextStyle(color: muted, fontSize: 10),
                    ),
                  ),
                if (cliente.direccion.trim().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      cliente.direccion.trim(),
                      style: pw.TextStyle(color: muted, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 22),
          pw.SizedBox(
            width: 210,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${isEnglish ? 'Invoice no' : 'Folio'} : ${cotizacion.folio}',
                  style: pw.TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '${isEnglish ? 'Order number' : 'Número de orden'} : $orderNumber',
                  style: pw.TextStyle(color: textDark, fontSize: 10.5),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  dateFormat.format(cotizacion.fechaEmision),
                  style: pw.TextStyle(color: textDark, fontSize: 11),
                ),
                pw.Text(
                  '${isEnglish ? 'Due' : 'Vence'}: ${dateFormat.format(cotizacion.fechaVencimiento)}',
                  style: pw.TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
      if (clientBlockLines.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Wrap(
            spacing: 10,
            runSpacing: 4,
            children: clientBlockLines
                .take(6)
                .map(
                  (line) => pw.Text(
                    line,
                    style: pw.TextStyle(color: muted, fontSize: 9.6),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      pw.SizedBox(height: 14),
      _buildIndustrialTable(
        rows: rows,
        currency: currency,
        headerBlue: headerBlue,
        headerTextColor: onHeader,
        surfaceColor: pdfTheme.surface,
        stripeBlue: stripeBlue,
        borderColor: lightBorder,
        textColor: textDark,
        isEnglish: isEnglish,
      ),
      pw.SizedBox(height: 8),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 235,
          child: pw.Column(
            children: [
              _industrialSummaryLine(
                isEnglish ? 'Sub Total :' : 'Sub Total :',
                currency.format(cotizacion.subtotal),
                textDark,
              ),
              _industrialSummaryLine(
                isEnglish ? 'Discount :' : 'Descuento :',
                currency.format(cotizacion.descuentoTotal),
                textDark,
              ),
              _industrialSummaryLine(
                '${isEnglish ? 'Tax' : 'Impuesto'} ${taxRate.toStringAsFixed(0)}% :',
                currency.format(cotizacion.impuestoTotal),
                textDark,
              ),
              if (cotizacion.retIsr)
                _industrialSummaryLine(
                  '${isEnglish ? 'RET ISR' : 'RET ISR'} (${(retIsrRate * 100).toStringAsFixed(2)}%) :',
                  '-${currency.format(retIsrAmount)}',
                  textDark,
                ),
              _industrialSummaryLine(
                isEnglish ? 'Total :' : 'Total :',
                currency.format(cotizacion.total),
                textDark,
              ),
              _industrialSummaryLine(
                isEnglish ? 'Paid :' : 'Pagado :',
                currency.format(paid),
                textDark,
              ),
              _industrialSummaryLine(
                isEnglish ? 'Balance :' : 'Saldo :',
                currency.format(balance),
                textDark,
              ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                ..._buildRichTextSection(
                  label: isEnglish ? 'Terms' : 'Términos',
                  stored: cotizacion.terminos,
                  labelStyle: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: textDark,
                  ),
                  contentStyle: pw.TextStyle(fontSize: 10, color: muted),
                ),
                ..._buildRichTextSection(
                  label: isEnglish ? 'Notes' : 'Notas',
                  stored: cotizacion.notas,
                  labelStyle: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: textDark,
                  ),
                  contentStyle: pw.TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.SizedBox(
            width: 210,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${isEnglish ? 'Issue date' : 'Fecha emisión'}: ${dateFormat.format(cotizacion.fechaEmision)}',
                  style: pw.TextStyle(color: textDark, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${isEnglish ? 'Due date' : 'Fecha vencimiento'}: ${dateFormat.format(cotizacion.fechaVencimiento)}',
                  style: pw.TextStyle(color: textDark, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${isEnglish ? 'Order number' : 'Número de orden'}: $orderNumber',
                  style: pw.TextStyle(color: muted, fontSize: 9.5),
                  textAlign: pw.TextAlign.right,
                ),
                if (cotizacion.retIsr)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      '${isEnglish ? 'RET ISR base' : 'Base RET ISR'}: ${currency.format(retIsrBase)}',
                      style: pw.TextStyle(color: muted, fontSize: 9.5),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              height: 2,
              color: lineGray,
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Container(width: 42, color: headerBlue),
              ),
            ),
          ),
          pw.Container(width: 42, height: 2, color: headerBlue),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Wrap(
        spacing: 14,
        runSpacing: 6,
        children: leftContact
            .map(
              (line) => pw.Text(
                line,
                style: pw.TextStyle(color: muted, fontSize: 10.5),
              ),
            )
            .toList(growable: false),
      ),
      if (richTextPlainTextFromStorage(cotizacion.piePagina).isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _buildRichTextDocument(
          cotizacion.piePagina,
          baseStyle: pw.TextStyle(fontSize: 9.2, color: muted),
        ),
      ],
    ];
  }

  static pw.Widget _buildIndustrialTable({
    required List<DetalleCotizacion?> rows,
    required NumberFormat currency,
    required PdfColor headerBlue,
    required PdfColor headerTextColor,
    required PdfColor surfaceColor,
    required PdfColor stripeBlue,
    required PdfColor borderColor,
    required PdfColor textColor,
    required bool isEnglish,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.8),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.6),
        1: const pw.FlexColumnWidth(3.1),
        2: const pw.FlexColumnWidth(1.0),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerBlue),
          children: [
            _cell('NO', header: true, color: headerTextColor),
            _cell(
              isEnglish ? 'DESCRIPTION' : 'DESCRIPCIÓN',
              header: true,
              color: headerTextColor,
            ),
            _cell('QTY', header: true, color: headerTextColor),
            _cell('PRICE', header: true, color: headerTextColor),
            _cell(
              'TOTAL',
              header: true,
              color: headerTextColor,
              align: pw.TextAlign.right,
            ),
          ],
        ),
        for (var index = 0; index < rows.length; index++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? surfaceColor : stripeBlue,
            ),
            children: [
              _cell('${index + 1}', color: textColor),
              _cell(
                rows[index]?.concepto.trim().isNotEmpty == true
                    ? rows[index]!.concepto
                    : (rows[index]?.descripcion ?? '-'),
                color: textColor,
              ),
              _cell(
                rows[index] == null
                    ? '-'
                    : _compactNumber(rows[index]!.cantidad),
                color: textColor,
              ),
              _cell(
                rows[index] == null
                    ? '-'
                    : currency.format(rows[index]!.precioUnitario),
                color: textColor,
              ),
              _cell(
                rows[index] == null
                    ? '-'
                    : currency.format(rows[index]!.importe),
                color: textColor,
                align: pw.TextAlign.right,
                fontWeight: pw.FontWeight.bold,
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _industrialSummaryLine(
    String label,
    String value,
    PdfColor textColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(color: textColor, fontSize: 11),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(color: textColor, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _CotizacionPdfFonts {
  _CotizacionPdfFonts({
    required this.base,
    required this.bold,
    required this.italic,
    required this.boldItalic,
  });

  final pw.Font base;
  final pw.Font bold;
  final pw.Font italic;
  final pw.Font boldItalic;
}

class _QuotePdfSourceData {
  _QuotePdfSourceData({required this.cliente, required this.detalles});

  final Cliente cliente;
  final List<DetalleCotizacion> detalles;
}

class _QuotePdfTheme {
  _QuotePdfTheme({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.accentPanel,
    required this.border,
    required this.rule,
    required this.ruleThickness,
    required this.radius,
    required this.textPrimary,
    required this.textMuted,
  });

  final PdfColor primary;
  final PdfColor secondary;
  final PdfColor background;
  final PdfColor surface;
  final PdfColor accentPanel;
  final PdfColor border;
  final PdfColor rule;
  final double ruleThickness;
  final double radius;
  final PdfColor textPrimary;
  final PdfColor textMuted;

  static _QuotePdfTheme fromEmpresa(EmpresaPerfil empresa) {
    final rawPrimary = _safePdfHex(empresa.colorPrimario, '#1E5BB8');
    final rawSecondary = _safePdfHex(empresa.colorSecundario, '#F04A2A');
    final baseBackground = _safePdfHex(empresa.colorFondo, '#F7F9FC');
    final baseNeutral = _safePdfHex(empresa.colorNeutro, '#1F2937');
    final basePrimary = _mix(rawPrimary, baseBackground, 0.08);
    final baseSecondary = _mix(rawSecondary, baseBackground, 0.16);
    return _QuotePdfTheme(
      primary: basePrimary,
      secondary: baseSecondary,
      background: baseBackground,
      surface: _mix(baseBackground, baseSecondary, 0.985),
      accentPanel: _mix(baseSecondary, baseBackground, 0.955),
      border: _mix(baseNeutral, baseBackground, 0.82),
      rule: _mix(basePrimary, baseBackground, 0.48),
      ruleThickness: 1,
      radius: 8,
      textPrimary: baseNeutral,
      textMuted: _mix(baseNeutral, baseBackground, 0.55),
    );
  }
}

PdfColor _contrastColor(PdfColor color) {
  final luminance =
      0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
  return luminance > 0.55 ? PdfColor(0, 0, 0) : PdfColor(1, 1, 1);
}

String _normalizeThemePreset(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'corporativo':
    case 'corporate':
      return 'corporativo';
    case 'industrial':
      return 'industrial';
    case 'minimal':
    case 'minimalista':
      return 'minimal';
    case 'destacado':
    case 'highlight':
      return 'destacado';
    case 'editorial':
      return 'editorial';
    default:
      return 'corporativo';
  }
}

PdfColor _safePdfHex(String raw, String fallback) {
  var normalized = raw.trim();
  if (normalized.isEmpty) normalized = fallback;
  if (!normalized.startsWith('#')) normalized = '#$normalized';
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(normalized)) {
    normalized = fallback;
  }
  return PdfColor.fromHex(normalized);
}

PdfColor _mix(PdfColor a, PdfColor b, double t) {
  final clamped = t.clamp(0.0, 1.0);
  return PdfColor(
    a.red * (1 - clamped) + b.red * clamped,
    a.green * (1 - clamped) + b.green * clamped,
    a.blue * (1 - clamped) + b.blue * clamped,
  );
}

Future<pw.ImageProvider?> _loadLogoProvider(String rawUrl) async {
  final url = rawUrl.trim();
  if (url.isEmpty) return null;
  final existing = CotizacionPdfService._logoCache[url];
  if (existing != null) {
    return existing;
  }
  final future = () async {
    try {
      return await networkImage(url).timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }();
  CotizacionPdfService._logoCache[url] = future;
  return future;
}

PdfPageFormat _pageFormatFromName(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'letter':
      return PdfPageFormat.letter;
    case 'legal':
      return PdfPageFormat.legal;
    case 'oficio':
      return PdfPageFormat(8.5 * PdfPageFormat.inch, 13 * PdfPageFormat.inch);
    case 'tabloid':
      return PdfPageFormat(11 * PdfPageFormat.inch, 17 * PdfPageFormat.inch);
    case 'a4':
    default:
      return PdfPageFormat.a4;
  }
}

PdfPageFormat _resolvePageFormat({
  required String pageSize,
  required String pageOrientation,
}) {
  final base = _pageFormatFromName(pageSize);
  if (_isHorizontalOrientation(pageOrientation)) {
    return PdfPageFormat(base.height, base.width);
  }
  return base;
}

bool _isHorizontalOrientation(String raw) {
  final normalized = raw.trim().toLowerCase();
  return normalized == 'horizontal' || normalized == 'landscape';
}

double _resolvePageMargin(PdfPageFormat pageFormat) {
  final shortSide = pageFormat.width < pageFormat.height
      ? pageFormat.width
      : pageFormat.height;
  if (shortSide <= 595) return 24;
  if (shortSide <= 650) return 26;
  if (shortSide <= 760) return 28;
  return 30;
}

double _resolveFontScale({
  required double quoteFontSize,
  required PdfPageFormat pageFormat,
}) {
  final baseScale = (quoteFontSize / 18).clamp(0.70, 1.45);
  final area = pageFormat.width * pageFormat.height;
  final a4Area = PdfPageFormat.a4.width * PdfPageFormat.a4.height;
  final pageScale = (area / a4Area).clamp(0.85, 1.40);
  final normalizedPageScale = math
      .sqrt(pageScale.toDouble())
      .clamp(0.92, 1.18)
      .toDouble();
  return (baseScale * normalizedPageScale).clamp(0.70, 1.55).toDouble();
}

double _resolveLogoExtent({
  required double logoSize,
  required String logoSizeMode,
  required PdfPageFormat pageFormat,
}) {
  final value = logoSize.clamp(1, 300).toDouble();
  final shortSide = pageFormat.width < pageFormat.height
      ? pageFormat.width
      : pageFormat.height;
  switch (logoSizeMode.trim().toLowerCase()) {
    case 'porcentaje':
      return (shortSide * (value / 100) * 0.45).clamp(28, 180).toDouble();
    case 'ancho fijo':
    case 'px':
    default:
      return value.clamp(28, 180).toDouble();
  }
}

class _PdfRichTextLine {
  _PdfRichTextLine({required this.spans, required this.attributes});

  final List<_PdfRichTextSpan> spans;
  final Map<String, dynamic> attributes;
}

class _PdfRichTextSpan {
  _PdfRichTextSpan({required this.text, required this.attributes});

  final String text;
  final Map<String, dynamic> attributes;
}
