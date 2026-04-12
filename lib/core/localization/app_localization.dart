import 'package:cotimax/features/auth/application/auth_controller.dart';
import 'package:cotimax/features/configuracion/application/configuracion_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AppPresentationSettings {
  const AppPresentationSettings({
    required this.locale,
    required this.currencyCode,
    required this.themeMode,
  });

  final Locale locale;
  final String currencyCode;
  final ThemeMode themeMode;

  String get intlLocale =>
      locale.countryCode == null || locale.countryCode!.isEmpty
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';

  bool get isEnglish => locale.languageCode.toLowerCase().startsWith('en');

  static const fallback = AppPresentationSettings(
    locale: Locale('es', 'MX'),
    currencyCode: 'MXN',
    themeMode: ThemeMode.light,
  );
}

final appPresentationSettingsProvider = Provider<AppPresentationSettings>((
  ref,
) {
  final auth = ref.watch(authControllerProvider);
  final themeModeOverride = ref.watch(themeModeOverrideProvider);
  if (!auth.isAuthenticated) {
    return AppPresentationSettings.fallback;
  }

  final empresa = ref.watch(empresaPerfilControllerProvider).valueOrNull;
  final usuario = ref.watch(usuarioActualControllerProvider).valueOrNull;
  final persistedThemeMode = (usuario?.modoOscuro ?? false)
      ? ThemeMode.dark
      : ThemeMode.light;
  if (empresa == null) {
    return AppPresentationSettings(
      locale: AppPresentationSettings.fallback.locale,
      currencyCode: AppPresentationSettings.fallback.currencyCode,
      themeMode: themeModeOverride ?? persistedThemeMode,
    );
  }

  return AppPresentationSettings(
    locale: localeFromLanguageTag(empresa.localizacion.idioma),
    currencyCode: normalizeCurrencyCode(empresa.localizacion.moneda),
    themeMode: themeModeOverride ?? persistedThemeMode,
  );
});

final themeModeOverrideProvider = StateProvider<ThemeMode?>((ref) => null);
final themeChangeInProgressProvider = StateProvider<bool>((ref) => false);
final themeOverlayVisibleProvider = Provider<bool>((ref) {
  if (ref.watch(themeChangeInProgressProvider)) {
    return true;
  }

  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated) {
    return false;
  }

  if (ref.watch(themeModeOverrideProvider) != null) {
    return false;
  }

  final usuarioActual = ref.watch(usuarioActualControllerProvider);
  return usuarioActual.isLoading && usuarioActual.valueOrNull == null;
});

AppPresentationSettings _currentSettings = AppPresentationSettings.fallback;

void syncAppPresentationSettings(AppPresentationSettings settings) {
  _currentSettings = settings;
}

Locale currentAppLocale() => _currentSettings.locale;

String currentCurrencyCode() => _currentSettings.currencyCode;

String currentIntlLocale() => _currentSettings.intlLocale;

String normalizeSupportedLanguageTag(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) {
    return AppPresentationSettings.fallback.locale.toLanguageTag();
  }
  if (normalized.startsWith('en') ||
      normalized.contains('english') ||
      normalized.contains('ingl')) {
    return 'en-US';
  }
  if (normalized.startsWith('es') ||
      normalized.contains('spanish') ||
      normalized.contains('españ') ||
      normalized.contains('espan')) {
    return 'es-MX';
  }
  return 'es-MX';
}

Locale localeFromLanguageTag(String raw) {
  final normalized = normalizeSupportedLanguageTag(raw);
  if (normalized.isEmpty) return AppPresentationSettings.fallback.locale;
  final parts = normalized.split(RegExp(r'[-_]'));
  if (parts.length >= 2) {
    return Locale(parts[0], parts[1].toUpperCase());
  }
  return Locale(parts.first);
}

String normalizeCurrencyCode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return AppPresentationSettings.fallback.currencyCode;
  final match = RegExp(r'^[A-Z]{3}').firstMatch(trimmed.toUpperCase());
  return match?.group(0) ?? AppPresentationSettings.fallback.currencyCode;
}

String tr(String es, String en) => _currentSettings.isEnglish ? en : es;

String trText(String text) {
  if (_currentSettings.isEnglish) {
    return _translateWithMap(text, _englishTranslations);
  }
  return _translateWithMap(text, _spanishTranslations);
}

String _translateWithMap(String text, Map<String, String> translations) {
  final exact = translations[text];
  if (exact != null) return exact;

  var translated = text;
  final keys = translations.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final key in keys) {
    if (!translated.contains(key)) continue;
    translated = _replaceStandaloneOccurrences(
      translated,
      key,
      translations[key]!,
    );
  }
  return translated;
}

String _replaceStandaloneOccurrences(
  String text,
  String target,
  String replacement,
) {
  final pattern = RegExp(
    '(^|[^A-Za-z0-9ÁÉÍÓÚáéíóúÑñ])'
    '${RegExp.escape(target)}'
    '(?=\$|[^A-Za-z0-9ÁÉÍÓÚáéíóúÑñ])',
  );
  return text.replaceAllMapped(pattern, (match) {
    final prefix = match.group(1) ?? '';
    return '$prefix$replacement';
  });
}

String formatMoney(
  num value, {
  int decimalDigits = 2,
  bool includeCurrencyCode = true,
}) {
  final code = _currentSettings.currencyCode;
  final formatter = NumberFormat.currency(
    locale: _currentSettings.intlLocale,
    symbol: includeCurrencyCode ? '$code ' : '',
    decimalDigits: decimalDigits,
  );
  return formatter.format(value);
}

final Map<String, String> _englishTranslations = {
  'Inicio': 'Home',
  'Clientes': 'Clients',
  'Proveedores': 'Suppliers',
  'Productos': 'Products',
  'Productos / Servicios': 'Products / Services',
  'Materiales': 'Materials',
  'Cotizaciones': 'Quotes',
  'Ingresos': 'Income',
  'Gastos': 'Expenses',
  'Analítica': 'Analytics',
  'Configuración': 'Settings',
  'Usuarios': 'Users',
  'Planes': 'Plans',
  'COMERCIAL': 'SALES',
  'ADMINISTRACION': 'ADMINISTRATION',
  'Busca clientes, folios, productos o acciones':
      'Search clients, quotes, products, or actions',
  'Vista diaria': 'Daily view',
  'Editar': 'Edit',
  'Eliminar': 'Delete',
  'Limpiar': 'Clear',
  'Importar': 'Import',
  'Exportar': 'Export',
  'Cancelar': 'Cancel',
  'Guardar': 'Save',
  'Crear': 'Create',
  'Registrar': 'Register',
  'Aplicar': 'Apply',
  'Confirmar': 'Confirm',
  'Reintentar': 'Retry',
  'Actualizar a Pro': 'Upgrade to Pro',
  'Upgrade ahora': 'Upgrade now',
  'Subir imagen': 'Upload image',
  'Consumo del plan': 'Plan usage',
  'Ocurrio un error': 'An error occurred',
  'Selecciona el rango': 'Select the range',
  'Selecciona un rango': 'Select a range',
  'Gratis': 'Free',
  'Nombre': 'Name',
  'RFC': 'Tax ID',
  'Contacto': 'Contact',
  'Teléfono': 'Phone',
  'Correo': 'Email',
  'Estatus': 'Status',
  'Actualizado': 'Updated',
  'Acciones': 'Actions',
  'Activo': 'Active',
  'Inactivo': 'Inactive',
  'Activar': 'Activate',
  'Desactivar': 'Deactivate',
  'Tipo': 'Type',
  'Categoria': 'Category',
  'Categoría': 'Category',
  'Categoría de impuestos': 'Tax category',
  'Unidad': 'Unit',
  'Precio base': 'Base price',
  'Costo': 'Cost',
  'Folio': 'Folio',
  'Emisión': 'Issue date',
  'Vencimiento': 'Due date',
  'Subtotal': 'Subtotal',
  'Impuesto': 'Tax',
  'Total': 'Total',
  'Stock': 'Stock',
  'Proveedor': 'Supplier',
  'General': 'General',
  'Gasto': 'Expense',
  'Movs': 'Moves',
  'Producto terminado': 'Finished product',
  'Producto personalizado': 'Custom product',
  'Producto digital': 'Digital product',
  'Servicio profesional': 'Professional service',
  'Servicio técnico': 'Technical service',
  'Consultoría': 'Consulting',
  'Diseño': 'Design',
  'Desarrollo de software': 'Software development',
  'Desarrollo web': 'Web development',
  'Marketing': 'Marketing',
  'Publicidad': 'Advertising',
  'Impresión': 'Printing',
  'Papelería': 'Stationery',
  'Empaque': 'Packaging',
  'Embalaje': 'Packing',
  'Uniformes': 'Uniforms',
  'Promocionales': 'Promotional items',
  'Electrónica': 'Electronics',
  'Hardware': 'Hardware',
  'Accesorios': 'Accessories',
  'Refacciones': 'Spare parts',
  'Mantenimiento': 'Maintenance',
  'Instalación': 'Installation',
  'Construcción': 'Construction',
  'Carpintería': 'Carpentry',
  'Metal mecánica': 'Metalworking',
  'Logística': 'Logistics',
  'Transporte': 'Transportation',
  'Alimentos y bebidas': 'Food and beverages',
  'Salud': 'Health',
  'Educación': 'Education',
  'Limpieza': 'Cleaning',
  'Seguridad': 'Security',
  'Eventos': 'Events',
  'Bienes gravados IVA 16%': 'Goods taxed VAT 16%',
  'Bienes tasa 0% IVA': 'Goods VAT 0%',
  'Bienes exentos de IVA': 'VAT-exempt goods',
  'Servicios gravados IVA 16%': 'Services taxed VAT 16%',
  'Servicios tasa 0% IVA': 'Services VAT 0%',
  'Servicios exentos de IVA': 'VAT-exempt services',
  'Exportación de bienes 0%': 'Goods export 0%',
  'Exportación de servicios 0%': 'Services export 0%',
  'Región fronteriza IVA 8%': 'Border region VAT 8%',
  'Arrendamiento gravado IVA 16%': 'Lease taxed VAT 16%',
  'Honorarios gravados IVA 16%': 'Professional fees taxed VAT 16%',
  'Actividad mixta gravada': 'Mixed taxable activity',
  'Alimentos tasa 0%': 'Food VAT 0%',
  'Medicinas tasa 0%': 'Medicines VAT 0%',
  'Equipo médico tasa 0%': 'Medical equipment VAT 0%',
  'Libros y revistas tasa 0%': 'Books and magazines VAT 0%',
  'Transporte exento': 'Exempt transportation',
  'Educación exenta': 'Exempt education',
  'Servicios financieros exentos': 'Exempt financial services',
  'Donativos exentos': 'Exempt donations',
  'Campo opcional.': 'Optional field.',
  'Sin proveedor': 'No supplier',
  'No hay proveedores registrados.': 'No suppliers registered.',
  'Agregar proveedor': 'Add supplier',
  'No fue posible cargar proveedores.': 'Unable to load suppliers.',
  'Puedes dejar este campo vacío o registrar un proveedor para vincularlo a este material.':
      'You can leave this field empty or register a supplier to link it to this material.',
  'Puedes dejar este campo vacío o intentar cargar los proveedores nuevamente.':
      'You can leave this field empty or try loading suppliers again.',
  'No hay impuestos registrados.': 'No taxes registered.',
  'Agregar impuesto': 'Add tax',
  'Registra tus impuestos en Configuración para poder asignarlos a este producto.':
      'Register your taxes in Settings to assign them to this product.',
  'Unidad de medida': 'Unit of measure',
  'Costo unitario por unidad': 'Unit cost per unit',
  'Captura el costo de una sola unidad de medida.':
      'Enter the cost of a single unit of measure.',
  'Será la cantidad predeterminada a mostrar al seleccionar el producto en la cotización.':
      'This will be the default quantity shown when selecting the product in the quote.',
  'No hay materiales que coincidan con los filtros actuales.':
      'No materials match the current filters.',
  'Especifica el tipo de material': 'Specify the material type',
  'Especifica la unidad de medida': 'Specify the unit of measure',
  'Especifica el tipo de material.': 'Specify the material type.',
  'Especifica la unidad de medida.': 'Specify the unit of measure.',
  'Materia prima': 'Raw material',
  'Material base': 'Base material',
  'Material auxiliar': 'Auxiliary material',
  'Consumible': 'Consumable',
  'Componente': 'Component',
  'Refacción': 'Spare part',
  'Insumo químico': 'Chemical input',
  'Insumo textil': 'Textile input',
  'Insumo eléctrico': 'Electrical input',
  'Insumo electrónico': 'Electronic input',
  'Insumo metálico': 'Metal input',
  'Insumo plástico': 'Plastic input',
  'Insumo de madera': 'Wood input',
  'Insumo de vidrio': 'Glass input',
  'Registra insumos y consumibles para calcular el costo base del producto.':
      'Register inputs and consumables to calculate the product base cost.',
  'Adhesivo': 'Adhesive',
  'Pintura': 'Paint',
  'Recubrimiento': 'Coating',
  'Solvente': 'Solvent',
  'Lubricante': 'Lubricant',
  'Etiqueta': 'Label',
  'Accesorio': 'Accessory',
  'Herraje': 'Hardware',
  'Tornillería': 'Fasteners',
  'Cableado': 'Wiring',
  'Aislante': 'Insulation',
  'Otro': 'Other',
  'Otra': 'Other',
  'pieza': 'piece',
  'caja': 'box',
  'paquete': 'package',
  'bolsa': 'bag',
  'rollo': 'roll',
  'hoja': 'sheet',
  'pliego': 'large sheet',
  'juego': 'set',
  'kit': 'kit',
  'par': 'pair',
  'docena': 'dozen',
  'ciento': 'hundred',
  'millar': 'thousand',
  'metro': 'meter',
  'centímetro': 'centimeter',
  'milímetro': 'millimeter',
  'kilómetro': 'kilometer',
  'metro cuadrado': 'square meter',
  'metro cúbico': 'cubic meter',
  'litro': 'liter',
  'mililitro': 'milliliter',
  'galón': 'gallon',
  'kilogramo': 'kilogram',
  'gramo': 'gram',
  'miligramo': 'milligram',
  'tonelada': 'ton',
  'onza': 'ounce',
  'libra': 'pound',
  'yarda': 'yard',
  'pie': 'foot',
  'pulgada': 'inch',
  'tambor': 'drum',
  'tarima': 'pallet',
  'contenedor': 'container',
  'bote': 'can',
  'frasco': 'jar',
  'tubo': 'tube',
  'Probabilidad': 'Probability',
  'Fecha': 'Date',
  'Monto': 'Amount',
  'Previsualizar': 'Preview',
  'Descargar PDF': 'Download PDF',
  'Marcar aprobada': 'Mark approved',
  'Método': 'Method',
  'Metodo': 'Method',
  'Método de pago': 'Payment method',
  'Mostrar resumen para cliente': 'Show client summary',
  'Referencia': 'Reference',
  'Notas': 'Notes',
  'Descripción': 'Description',
  'Descripcion': 'Description',
  'Cliente relacionado': 'Related client',
  'Folio o ID de cotización': 'Quote folio or ID',
  'AAAA-MM-DD': 'YYYY-MM-DD',
  'Folio o referencia bancaria': 'Folio or bank reference',
  'Comentarios adicionales': 'Additional comments',
  'Categoria del gasto': 'Expense category',
  'Proveedor o beneficiario': 'Supplier or beneficiary',
  'Folio o referencia': 'Folio or reference',
  'Descripcion breve': 'Short description',
  'Notas internas del gasto': 'Internal expense notes',
  'Plan de actualización': 'Upgrade plan',
  'Gestionar plan': 'Manage plan',
  'Elegir': 'Choose',
  'Buscar icono por nombre': 'Search icon by name',
  'Enviar enlace': 'Send link',
  'Volver al login': 'Back to login',
  'Reenviar código': 'Resend code',
  'Cambiar correo': 'Change email',
  'Términos y condiciones': 'Terms and conditions',
  'Al continuar aceptas nuestros': 'By continuing you accept our',
  'y': 'and',
  'Politica de privacidad': 'Privacy policy',
  'Ver mas': 'See more',
  'Limpiar rango': 'Clear range',
  'Si': 'Yes',
  'Sí': 'Yes',
  'No': 'No',
  'Cotización': 'Quote',
  'Cotización válida hasta': 'Quote valid until',
  'Términos de pago': 'Payment terms',
  'Tasa de tarea': 'Task rate',
  'Enviar recordatorios': 'Send reminders',
  'Clasificar': 'Classify',
  'Detalles de la empresa': 'Company details',
  'Contactos': 'Contacts',
  'Dirección de envío': 'Shipping address',
  'Añadir artículo': 'Add item',
  'Concepto': 'Item',
  'Coste unitario': 'Unit cost',
  'Cantidad': 'Quantity',
  'Tasa de impuesto 1': 'Tax rate 1',
  'Nuevo item': 'New item',
  'Duplicar': 'Duplicate',
  'Agregar material': 'Add material',
  'Agregar rango': 'Add range',
  'Ultimos ingresos': 'Latest income',
  'Todavia no hay ingresos recientes en el rango.':
      'There is no recent income in the selected range yet.',
  'Cuando entren cobros, esta vista mostrara lo ultimo registrado sin saturar el dashboard.':
      'When payments come in, this view will show the latest activity without cluttering the dashboard.',
  'Error': 'Error',
  'Cobranza': 'Collections',
  'Frecuencia': 'Frequency',
  'Dependencia': 'Dependency',
  'Periodo': 'Period',
  'Libre': 'Free cash',
  'Actual': 'Actual',
  'Proyeccion': 'Projection',
  'Utilidad confirmada': 'Confirmed profit',
  'Flujo libre': 'Free cash',
  'Cobertura': 'Coverage',
  'Acciones rapidas': 'Quick actions',
  'Clientes clave': 'Key clients',
  'Top 3 clientes': 'Top 3 clients',
  'Top 5 clientes': 'Top 5 clients',
  'Rentabilidad por cliente': 'Client profitability',
  'Concentracion de ingresos': 'Income concentration',
  'Top productos por utilidad': 'Top products by profit',
  'Mostramos solo los clientes con mejor utilidad confirmada para que el analisis siga digerible.':
      'We show only the clients with the best confirmed profit to keep the analysis readable.',
  'Resumimos la exposicion a pocos clientes con dos indicadores claros para no abrumar la lectura.':
      'We summarize exposure to a few clients with two clear indicators to keep the reading focused.',
  'Indicadores clave': 'Key indicators',
  'Cobertura operativa': 'Operating coverage',
  'Ingresos / gastos del ultimo mes': 'Income / expenses for the last month',
  'Burn multiple': 'Burn multiple',
  'Gastos / utilidad confirmada': 'Expenses / confirmed profit',
  'Run rate anual': 'Annual run rate',
  'Promedio mensual anualizado': 'Annualized monthly average',
  'Flujo libre promedio': 'Average free cash flow',
  'Ingreso cobrado menos gasto mensual':
      'Collected income minus monthly expenses',
  'Escenarios y lectura': 'Scenarios and interpretation',
  'Escenario conservador': 'Conservative scenario',
  '12% menos dinero libre promedio': '12% lower average free cash',
  'Escenario base': 'Base scenario',
  'Promedio esperado por mes': 'Expected monthly average',
  'Escenario expansion': 'Expansion scenario',
  '12% mas dinero libre promedio': '12% higher average free cash',
  'Pulso semanal': 'Weekly pulse',
  'Cierre mensual': 'Monthly close',
  'Proyeccion operativa': 'Operating projection',
  'Tabla de resultados': 'Results table',
  'Ingresos proyectados': 'Projected income',
  'Gastos proyectados': 'Projected expenses',
  'Dinero libre proyectado': 'Projected free cash',
  'Total en el horizonte seleccionado': 'Total over the selected horizon',
  'Base operativa esperada': 'Expected operating base',
  'Resultado neto proyectado': 'Projected net result',
  'Facturación automática activada': 'Automatic billing enabled',
  'Titular': 'Cardholder',
  'Correo de facturación': 'Billing email',
  'Tasas de línea': 'Line taxes',
  'Payment method': 'Payment method',
  'Add Payment Method': 'Add payment method',
  'Visa terminación 4242': 'Visa ending in 4242',
  'Rol': 'Role',
  'Empresas': 'Companies',
  'Admin': 'Admin',
  'Usuario': 'User',
  'Ilimitados': 'Unlimited',
  'Ilimitadas': 'Unlimited',
  'Usuarios activos': 'Active users',
  'Cotizaciones mes': 'Monthly quotes',
  'Actualiza a los planes Pro o Enterprise para funciones avanzadas.':
      'Upgrade to Pro or Enterprise plans for advanced features.',
  'Comience su prueba GRATUITA de 14 días del Plan Pro':
      'Start your FREE 14-day trial of the Pro Plan',
  'Abre un dialogo compacto para cambiarlo':
      'Open a compact dialog to change it',
  'Seleccionar icono': 'Select icon',
  'Toca un icono para seleccionarlo': 'Tap an icon to select it',
  'Reportes por usuario: proximamente.': 'Per-user reports: coming soon.',
  'Cambiar plan': 'Change plan',
  'Nuevo cliente': 'New client',
  'Nuevo proveedor': 'New supplier',
  'Nuevo producto': 'New product',
  'Nuevo material': 'New material',
  'Nueva cotización': 'New quote',
  'Nuevo ingreso': 'New income',
  'Nuevo gasto': 'New expense',
  'Ruta no encontrada': 'Route not found',
  'Dashboard': 'Dashboard',
  'Configuración General': 'General Settings',
  'Diseño de factura': 'Invoice Design',
  'Diseños personalizados': 'Custom layouts',
  'Cliente': 'Client',
  'Localización': 'Localization',
  'Impuestos': 'Taxes',
  'Empresa': 'Company',
  'Gestión de cuenta': 'Account Management',
  'Descripción general': 'Overview',
  'Módulos habilitados': 'Enabled Modules',
  'Zona peligrosa': 'Danger Zone',
  'Moneda': 'Currency',
  'Idioma': 'Language',
  'Español': 'Spanish',
  'Inglés': 'English',
  'Huso horario': 'Time zone',
  'Formato de fecha': 'Date format',
  'Formato de moneda': 'Currency format',
  'Guardar localización': 'Save localization',
  'Guardar impuestos': 'Save taxes',
  'Guardar empresa': 'Save company',
  'Guardando...': 'Saving...',
  'Renueva': 'Renews',
  'Número': 'Number',
  'Número de Orden': 'Order number',
  'Fecha de Factura': 'Invoice date',
  'Fecha de Vencimiento': 'Due date',
  'Total Facturado': 'Total invoiced',
  'FACTURA': 'INVOICE',
  'PAGADO': 'PAID',
  'Enviar a:': 'Ship to:',
  'Servicio base': 'Base service',
  'Descripción del concepto.': 'Item description.',
  'Adjuntos incluidos:': 'Attachments included:',
  'Página': 'Page',
  'Tamaño de página': 'Page size',
  'Agregar método de pago': 'Add payment method',
  'Agregar método de pago disponible pronto.':
      'Add payment method coming soon.',
  'Gestionar plan disponible pronto.': 'Manage plan coming soon.',
  'Purgar datos disponible pronto.': 'Data purge coming soon.',
  'Eliminación de cuenta disponible pronto.': 'Account deletion coming soon.',
  'No se pudo cargar la configuración.': 'Could not load settings.',
  'No se pudo cargar la suscripción.': 'Could not load subscription.',
  'No se pudo cargar el plan.': 'Could not load plan.',
  'Datos de empresa guardados.': 'Company details saved.',
  'Configuración de localización guardada.': 'Localization settings saved.',
  'Configuración de impuestos guardada.': 'Tax settings saved.',
  'No hay datos que mostrar.': 'No data to display.',
  'Sin registros para mostrar.': 'No records to display.',
  'Ajusta el rango o agrega datos para ver actividad.':
      'Adjust the range or add data to see activity.',
  'Búsqueda global': 'Global search',
  'Sesión': 'Session',
  'Administrador': 'Administrator',
  'No hay materiales registrados.': 'No materials have been registered.',
  'No hay productos registrados.': 'No products have been registered.',
  'Sana': 'Healthy',
  'Atencion': 'Attention',
  'Riesgo': 'Risk',
  'Prioridad financiera: ingresos, gastos, utilidad y cierre comercial del rango actual. Usa Ctrl/Cmd + K para navegar o crear sin salir del flujo.':
      'Financial priority: income, expenses, profit, and commercial closing for the current range. Use Ctrl/Cmd + K to navigate or create without leaving the flow.',
  'Ingresos totales': 'Total income',
  'Gastos totales': 'Total expenses',
  'Tendencia de ingresos': 'Income trend',
  'Tendencia de gastos': 'Expense trend',
  'Utilidad real (basada en cotizaciones confirmadas)':
      'Actual profit (based on confirmed quotes)',
  'Margen real': 'Actual margin',
  'Ultimos gastos': 'Latest expenses',
  'Cotizaciones aprobadas con utilidad': 'Approved quotes with profit',
  'Cotizaciones prioritarias': 'Priority quotes',
  'Seguimiento': 'Follow-up',
  'Cierre ponderado': 'Weighted close',
  'Prob. promedio': 'Avg. probability',
  'Todavia no hay pipeline para analizar en este rango.':
      'There is no pipeline to analyze in this range yet.',
  'Cotizaciones aprobadas': 'Approved quotes',
  'Ingresos cobrados': 'Collected income',
  'Gastos del periodo': 'Period expenses',
  'Tendencia de ingresos cobrados': 'Collected income trend',
  'Estimado con promedio ponderado y tendencia reciente':
      'Estimated using weighted average and recent trend',
  'Utilidad confirmada proyectada': 'Projected confirmed profit',
  'Cotizaciones aprobadas estimadas': 'Estimated approved quotes',
  'Modelo basado en aprobaciones y utilidad historica':
      'Model based on approvals and historical profit',
  'Base operativa y gasto recurrente': 'Operating base and recurring expense',
  'Incluye tendencia de gasto y cargas recurrentes activas':
      'Includes spending trend and active recurring charges',
  'Tendencia semanal de ingresos': 'Weekly income trend',
  'Proyeccion basada en semanas recientes': 'Projection based on recent weeks',
  'Cotizaciones aprobadas esperadas': 'Expected approved quotes',
  'Estimado con comportamiento reciente': 'Estimated from recent behavior',
  'Carga operativa semanal': 'Weekly operating load',
  'Flujo de caja': 'Cash flow',
  'Flujo': 'Flow',
  'Tu plan': 'Your Plan',
  'Ilimitado': 'Unlimited',
  'Historico': 'Historical',
  'Historico real': 'Actual historical',
  'Escenario proyectado': 'Projected scenario',
  'Ultimas 8 semanas': 'Last 8 weeks',
  'Base ultimas 8 semanas': 'Base last 8 weeks',
  'Enter abre el primero': 'Enter opens the first',
  'Sugerencias listas para navegar': 'Suggestions ready to navigate',
  'No encontramos coincidencias.': 'No matches found.',
  'Prueba con un cliente, un folio, un producto o una acción rápida.':
      'Try a client, a folio, a product, or a quick action.',
  'Sin dias seleccionados': 'No days selected',
  'Activa una regla para generar el movimiento de forma recurrente.':
      'Activate a rule to generate the entry recurrently.',
  'Desactiva esta opcion si el movimiento solo ocurre una vez.':
      'Disable this option if the entry happens only once.',
  'Lun': 'Mon',
  'Mar': 'Tue',
  'Mie': 'Wed',
  'Jue': 'Thu',
  'Vie': 'Fri',
  'Sab': 'Sat',
  'Dom': 'Sun',
  '1 semana': '1 week',
  '2 semanas': '2 weeks',
  '1 mes': '1 month',
  '2 meses': '2 months',
  '3 meses': '3 months',
  '4 meses': '4 months',
  '5 meses': '5 months',
  '6 meses': '6 months',
  '1 año': '1 year',
  'Dashboard actualizado para': 'Dashboard updated for',
  'Total del rango': 'Total for range',
  'Ritmo comercial: cotizaciones aprobadas convertidas a ingreso en el rango actual.':
      'Sales pace: approved quotes converted into income for the current range.',
  'Esta vista resume cuanto ingreso entro y que tan activo estuvo el cierre comercial durante el periodo.':
      'This view summarizes how much income came in and how active commercial closing was during the period.',
  'Estado financiero': 'Financial status',
  'Margen actual': 'Current margin',
  'El gasto se mantiene bajo control.': 'Spending remains under control.',
  'Conviene revisar gastos para recuperar margen.':
      'It is advisable to review expenses to recover margin.',
  'Todo el rango actual': 'Entire current range',
  'sin referencia': 'no reference',
  'de': 'of',
  'ingresos': 'income entries',
  'gastos': 'expense entries',
  'cotizaciones aprobadas': 'approved quotes',
  'Ingreso por': 'Income via',
  'Gasto registrado': 'Registered expense',
  'Gasto con': 'Expense with',
  'Cotización aprobada': 'Approved quote',
  'Utilidad': 'Profit',
  'Costo estimado': 'Estimated cost',
  'Partidas': 'Lines',
  'No hay datos del periodo anterior.': 'No previous-period data.',
  'vs periodo anterior': 'vs previous period',
  'Alta': 'High',
  'Media': 'Medium',
  'Ocasional': 'Occasional',
  'Dependencia alta': 'High dependency',
  'Dependencia moderada': 'Moderate dependency',
  'Dependencia saludable': 'Healthy dependency',
  'Conviene diversificar el pipeline para no quedar expuesto a pocos clientes.':
      'It is advisable to diversify the pipeline to avoid exposure to only a few clients.',
  'Hay concentracion visible, pero aun con margen para equilibrar la cartera.':
      'There is visible concentration, but there is still room to balance the portfolio.',
  'La distribucion se ve equilibrada y reduce el riesgo comercial.':
      'The distribution looks balanced and reduces commercial risk.',
  'Operación única': 'One-time operation',
  'Operacion unica': 'One-time operation',
  'Recurrente': 'Recurring',
  'MXN - Peso mexicano': 'MXN - Mexican peso',
  'USD - Dólar estadounidense': 'USD - US dollar',
  'EUR - Euro': 'EUR - Euro',
  'GBP - Libra esterlina': 'GBP - British pound',
  'CAD - Dólar canadiense': 'CAD - Canadian dollar',
  'BRL - Real brasileño': 'BRL - Brazilian real',
  'ARS - Peso argentino': 'ARS - Argentine peso',
  'CLP - Peso chileno': 'CLP - Chilean peso',
  'COP - Peso colombiano': 'COP - Colombian peso',
  'PEN - Sol peruano': 'PEN - Peruvian sol',
  'UYU - Peso uruguayo': 'UYU - Uruguayan peso',
  'PYG - Guaraní paraguayo': 'PYG - Paraguayan guarani',
  'BOB - Boliviano': 'BOB - Bolivian boliviano',
  'GTQ - Quetzal guatemalteco': 'GTQ - Guatemalan quetzal',
  'CRC - Colón costarricense': 'CRC - Costa Rican colon',
  'DOP - Peso dominicano': 'DOP - Dominican peso',
  'JPY - Yen japonés': 'JPY - Japanese yen',
  'CNY - Yuan chino': 'CNY - Chinese yuan',
  'INR - Rupia india': 'INR - Indian rupee',
  'AUD - Dólar australiano': 'AUD - Australian dollar',
  'NZD - Dólar neozelandés': 'NZD - New Zealand dollar',
  'CHF - Franco suizo': 'CHF - Swiss franc',
  'SEK - Corona sueca': 'SEK - Swedish krona',
  'NOK - Corona noruega': 'NOK - Norwegian krone',
  'DKK - Corona danesa': 'DKK - Danish krone',
  'SGD - Dólar de Singapur': 'SGD - Singapore dollar',
  'HKD - Dólar de Hong Kong': 'HKD - Hong Kong dollar',
  'KRW - Won surcoreano': 'KRW - South Korean won',
  'ZAR - Rand sudafricano': 'ZAR - South African rand',
  'AED - Dírham de Emiratos': 'AED - UAE dirham',
  'Español (México)': 'Spanish (Mexico)',
  'Español (España)': 'Spanish (Spain)',
  'Inglés (Estados Unidos)': 'English (United States)',
  'Inglés (Reino Unido)': 'English (United Kingdom)',
  'Portugués (Brasil)': 'Portuguese (Brazil)',
  'Francés (Francia)': 'French (France)',
  'Alemán (Alemania)': 'German (Germany)',
  'Italiano (Italia)': 'Italian (Italy)',
  'América/Tijuana (UTC-08:00)': 'America/Tijuana (UTC-08:00)',
  'América/Hermosillo (UTC-07:00)': 'America/Hermosillo (UTC-07:00)',
  'América/Mazatlán (UTC-07:00)': 'America/Mazatlan (UTC-07:00)',
  'América/Ciudad de México (UTC-06:00)': 'America/Mexico City (UTC-06:00)',
  'América/Monterrey (UTC-06:00)': 'America/Monterrey (UTC-06:00)',
  'América/Bogotá (UTC-05:00)': 'America/Bogota (UTC-05:00)',
  'América/Lima (UTC-05:00)': 'America/Lima (UTC-05:00)',
  'América/Santiago (UTC-04:00)': 'America/Santiago (UTC-04:00)',
  'América/Caracas (UTC-04:00)': 'America/Caracas (UTC-04:00)',
  'América/Buenos Aires (UTC-03:00)': 'America/Buenos Aires (UTC-03:00)',
  'Europa/Madrid (UTC+01:00)': 'Europe/Madrid (UTC+01:00)',
  'Símbolo antes del monto': 'Symbol before amount',
  'Símbolo después del monto': 'Symbol after amount',
  'Código antes del monto': 'Code before amount',
  'Código después del monto': 'Code after amount',
  'Símbolo antes con espacio': 'Symbol before with space',
  'Código antes con espacio': 'Code before with space',
  'Pago inmediato': 'Immediate payment',
  'Contra entrega': 'Cash on delivery',
  'Anticipo del 50%': '50% advance',
  'Anticipo del 70%': '70% advance',
  '1 día': '1 day',
  '3 días': '3 days',
  '5 días': '5 days',
  '7 días': '7 days',
  '10 días': '10 days',
  '15 días': '15 days',
  '20 días': '20 days',
  '30 días': '30 days',
  '45 días': '45 days',
  '60 días': '60 days',
  '90 días': '90 days',
  'Fin de mes': 'End of month',
  'Quincenal': 'Biweekly',
  'Mensual': 'Monthly',
  'Sin tasa definida': 'No defined rate',
  'No enviar': 'Do not send',
  'El mismo día': 'Same day',
  '1 día antes': '1 day before',
  '3 días antes': '3 days before',
  '5 días antes': '5 days before',
  '7 días antes': '7 days before',
  '10 días antes': '10 days before',
  '15 días antes': '15 days before',
  '30 días antes': '30 days before',
  '1-5 empleados': '1-5 employees',
  '6-20 empleados': '6-20 employees',
  '21-50 empleados': '21-50 employees',
  '51-100 empleados': '51-100 employees',
  '101-250 empleados': '101-250 employees',
  '251-500 empleados': '251-500 employees',
  '501-1,000 empleados': '501-1,000 employees',
  '1,001-5,000 empleados': '1,001-5,000 employees',
  '5,001+ empleados': '5,001+ employees',
  'Facturas recurrentes': 'Recurring invoices',
  'Creditos': 'Credits',
  'Proyectos': 'Projects',
  'Tareas': 'Tasks',
  'Vendedores': 'Salespeople',
  'Ordenes de compra': 'Purchase orders',
  'Gastos recurrentes': 'Recurring expenses',
  'Actas': 'Records',
  'Purgar Datos': 'Purge Data',
  'Eliminar cuenta': 'Delete account',
  'Resumen de cuenta': 'Account summary',
  'Plan activo': 'Active plan',
  'Correo principal': 'Primary email',
  'Sitio web': 'Website',
  'Capacidad actual': 'Current capacity',
  'Cotizaciones mensuales': 'Monthly quotes',
  'Diseño de Cotización': 'Quote design',
  'Diseño de Créditos': 'Credit design',
  'Diseño de orden de compra': 'Purchase order design',
  'Diseño de página': 'Page orientation',
  'Tamaño de Letra': 'Font size',
  'Tamaño del logotipo': 'Logo size',
  'Fuente principal': 'Primary font',
  'Color Primario': 'Primary color',
  'Fuente secundaria': 'Secondary font',
  'Color Secundario': 'Secondary color',
  'Mostrar sello pagado': 'Show paid stamp',
  'Mostrar dirección de envío': 'Show shipping address',
  'Incrustar imágenes/documentos': 'Embed images/documents',
  'Incluya imágenes/pdf adjuntos en la factura.':
      'Include attached images/PDFs in the invoice.',
  'Columnas vacías': 'Empty columns',
  'Numeración de páginas': 'Page numbering',
  'Guardar valores por defecto': 'Save defaults',
  'Modo oscuro': 'Dark mode',
  'Notas privadas': 'Private notes',
  'Pie de página': 'Footer',
  'Términos': 'Terms',
  'IVA': 'VAT',
  'Impuestos inclusivos': 'Inclusive taxes',
  'Impuestos sobre gastos': 'Taxes on expenses',
  'Tasa predeterminada': 'Default rate',
  'Dirección': 'Address',
  'UTC (UTC+00:00)': 'UTC (UTC+00:00)',
  'dd/MM/yyyy': 'dd/MM/yyyy',
  'dd-MM-yyyy': 'dd-MM-yyyy',
  'dd MMM yyyy': 'dd MMM yyyy',
  'yyyy-MM-dd': 'yyyy-MM-dd',
  'MM/dd/yyyy': 'MM/dd/yyyy',
  'MMMM dd, yyyy': 'MMMM dd, yyyy',
  'Retrato': 'Portrait',
  'Horizontal': 'Landscape',
  'Porcentaje': 'Percentage',
  'Ocultar': 'Hide',
  'Espectaculo': 'Show',
  'Detalles de empresa': 'Company details',
  'Configura tu empresa': 'Set up your company',
  'Nombre de la empresa': 'Company name',
  'Nombre comercial': 'Trade name',
  'Nombre fiscal': 'Legal name',
  'Logo': 'Logo',
  'Cargar logo': 'Upload logo',
  'Cambiar logo': 'Change logo',
  'Crear empresa': 'Create company',
  'Creando...': 'Creating...',
  'Nueva empresa': 'New company',
  'Código de invitación': 'Invitation code',
  'Código único del equipo': 'Unique team code',
  'Ej. TEAM-4F8K2P': 'Ex. TEAM-4F8K2P',
  'Elige cómo continuar': 'Choose how to continue',
  'Unirse por invitación': 'Join by invitation',
  'Unirse al equipo': 'Join the team',
  'Uniendo...': 'Joining...',
  'Copiar': 'Copy',
  'Agregar producto': 'Add product',
  'Añadir renglón': 'Add row',
  'Cargando productos para sugerencias...':
      'Loading products for suggestions...',
  'No se pudieron cargar las sugerencias de productos.':
      'Product suggestions could not be loaded.',
  '+ Añadir contacto': '+ Add contact',
  'SKU': 'SKU',
  'Producto': 'Product',
  'Servicio': 'Service',
  'Depósito': 'Deposit',
  'Base \$rango': 'Base \$rango',
  'Eliminar \$entityLabel': 'Delete \$entityLabel',
  '1 \$entityLabel seleccionado': '1 \$entityLabel selected',
  '\$count \$plural seleccionados': '\$count \$plural selected',
  'mes': 'month',
  'usuario': 'user',
  'Metodo de pago': 'Payment method',
  'Transferencia': 'Transfer',
  'Efectivo': 'Cash',
  'Tarjeta': 'Card',
  'Ninguna': 'None',
  'Cada dia': 'Every day',
  'Fin de semana': 'Weekend',
  'Cada semana': 'Every week',
  'Cada dos semanas': 'Every two weeks',
  'Cada 4 semanas': 'Every 4 weeks',
  'Cada mes': 'Every month',
  'Cada 2 meses': 'Every 2 months',
  'Cada 3 meses': 'Every 3 months',
  'Cada 4 meses': 'Every 4 months',
  'Cada 6 meses': 'Every 6 months',
  'Cada año': 'Every year',
  'Dias de la semana': 'Days of the week',
  'Días de la semana': 'Days of the week',
  'Diseño claro, corporativo y centrado en lectura.':
      'Clean, corporate, reading-focused design.',
  'Encabezados más contrastados y tabla con más presencia.':
      'More contrasted headers and a more prominent table.',
  'Más aire visual y densidad reducida para cliente final.':
      'More visual breathing room and reduced density for the end client.',
  'Limpio': 'Clean',
  'Negrita': 'Bold',
  'Mínimo': 'Minimal',
  'Remove Invoice Ninja logo': 'Quitar logo de Invoice Ninja',
  'Unlimited Clients': 'Clientes ilimitados',
  'Advanced Customization': 'Personalización avanzada',
  'Additional Account Users': 'Usuarios de cuenta adicionales',
  'Attach Files to Emails (pdf, jpg, xls..)':
      'Adjuntar archivos a correos (pdf, jpg, xls..)',
  'Custom URL “invoice.company.com”': 'URL personalizada “invoice.company.com”',
  'Auto-sync Bank Transactions':
      'Sincronización automática de movimientos bancarios',
  'REST API Access': 'Acceso a API REST',
  'Cartera': 'Wallet',
  'Pagos': 'Payments',
  'Dinero': 'Money',
  'Banco': 'Bank',
  'Recibo': 'Receipt',
  'Caja': 'Cashbox',
  'Tienda': 'Store',
  'Carrito': 'Cart',
  'Bolsa': 'Bag',
  'Inventario': 'Inventory',
  'Envio': 'Shipping',
  'Venta': 'Sale',
  'Ahorro': 'Savings',
  'Ingreso': 'Income',
  'Internet': 'Internet',
  'Egreso': 'Expense',
  'Reporte': 'Report',
  'Grafica': 'Chart',
  'Barras': 'Bars',
  'Ranking': 'Ranking',
  'KPI': 'KPI',
  'Web': 'Web',
  'Equipo': 'Team',
  'Persona': 'Person',
  'Soporte': 'Support',
  'Nomina': 'Payroll',
  'Trabajo': 'Work',
  'Negocio': 'Business',
  'Oficina': 'Office',
  'Renta': 'Rent',
  'Obra': 'Construction',
  'Herramienta': 'Tool',
  'Ingenieria': 'Engineering',
  'Plomeria': 'Plumbing',
  'Electricidad': 'Electricity',
  'Luz': 'Electric bill',
  'Agua': 'Water',
  'Gasolina': 'Fuel',
  'Auto': 'Car',
  'Viaje': 'Travel',
  'Hospedaje': 'Lodging',
  'Comida': 'Food',
  'Cafe': 'Coffee',
  'Alimentos': 'Groceries',
  'Gym': 'Gym',
  'Educacion': 'Education',
  'Cursos': 'Courses',
  'Computadora': 'Computer',
  'Laptop': 'Laptop',
  'Escritorio': 'Desk',
  'Celular': 'Mobile',
  'Audio': 'Audio',
  'Impresion': 'Printing',
  'Dispositivos': 'Devices',
  'Nube': 'Cloud',
  'Servidor': 'Server',
  'Proteccion': 'Protection',
  'Bloqueo': 'Lock',
  'Validado': 'Validated',
  'Documento': 'Document',
  'Carpeta': 'Folder',
  'QR': 'QR',
  'Almacen': 'Warehouse',
  'Sucursal': 'Branch',
  'Mall': 'Mall',
  'Regalo': 'Gift',
  'Promocion': 'Promotion',
  'Lealtad': 'Loyalty',
  'Premium': 'Premium',
  'Premio': 'Award',
  'Evento': 'Event',
  'Horario': 'Schedule',
  'Calendario': 'Calendar',
  'Hoy': 'Today',
  'Alerta': 'Alert',
  'Notificacion': 'Notification',
  'Llamada': 'Call',
  'Mensaje': 'Message',
  'Conversacion': 'Conversation',
  'Acuerdo': 'Agreement',
  'Legal': 'Legal',
  'Billetera': 'Wallet',
  'Cobrado': 'Collected',
  'Precio': 'Price',
  'Calculo': 'Calculation',
  'Linea de tiempo': 'Timeline',
  'Favorito': 'Favorite',
  'Confirmado': 'Confirmed',
  'Objetivo': 'Goal',
  'Rapido': 'Fast',
  'Sostenible': 'Sustainable',
  'Tendencia': 'Trend',
};

final Map<String, String> _spanishTranslations = {
  for (final entry in _englishTranslations.entries) entry.value: entry.key,
};
