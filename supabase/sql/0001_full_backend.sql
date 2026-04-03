create extension if not exists pgcrypto;

create or replace function public.app_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.app_parse_uuid(p_value text)
returns uuid
language plpgsql
immutable
as $$
begin
  if p_value is null or btrim(p_value) = '' then
    return null;
  end if;
  return p_value::uuid;
exception
  when others then
    return null;
end;
$$;

create table if not exists public.empresas (
  id uuid primary key default gen_random_uuid(),
  stripe_customer_id text,
  logo_url text not null default '',
  nombre_fiscal text not null,
  nombre_comercial text not null,
  rfc text not null default '',
  direccion text not null default '',
  telefono text not null default '',
  correo text not null default '',
  sitio_web text not null default '',
  color_primario text not null default '#1E5BB8',
  color_secundario text not null default '#F04A2A',
  color_fondo text not null default '#F7F9FC',
  color_neutro text not null default '#1F2937',
  theme_seleccionado text not null default 'corporativo',
  terminos_default text not null default '',
  pie_pagina_default text not null default '',
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null default '',
  telefono text not null default '',
  correo text not null default '',
  rol text not null default 'usuario' check (rol in ('admin', 'usuario')),
  ultimo_acceso_at timestamptz,
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create unique index if not exists usuarios_correo_key
on public.usuarios (lower(correo));

create table if not exists public.usuario_empresas (
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  es_principal boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (usuario_id, empresa_id)
);

create table if not exists public.planes (
  id text primary key,
  stripe_product_id text,
  stripe_price_id text,
  nombre text not null,
  precio_mensual numeric(14,2) not null default 0,
  billing_mode text not null default 'flat_monthly',
  precio_por_usuario numeric(14,2) not null default 0,
  descripcion text not null default '',
  limite_clientes integer not null default 0,
  limite_productos integer not null default 0,
  limite_cotizaciones_mensuales integer not null default 0,
  limite_usuarios integer not null default 0,
  limite_empresas integer not null default 0,
  usuarios_minimos integer not null default 0,
  usuarios_maximos integer not null default 0,
  incluye_ingresos_gastos boolean not null default false,
  incluye_dashboard boolean not null default false,
  incluye_personalizacion_pdf boolean not null default false,
  incluye_notas_privadas boolean not null default false,
  incluye_estados_cotizacion boolean not null default false,
  incluye_marca_agua boolean not null default true,
  activo boolean not null default true
);

create table if not exists public.suscripciones (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  plan_id text not null references public.planes(id),
  stripe_subscription_id text unique,
  stripe_price_id text,
  estado text not null default 'activa',
  fecha_inicio timestamptz not null default timezone('utc', now()),
  fecha_fin timestamptz not null,
  renovacion_automatica boolean not null default true,
  usuarios_activos integer not null default 1,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.stripe_webhook_events (
  id uuid primary key default gen_random_uuid(),
  stripe_event_id text not null unique,
  tipo text not null,
  payload jsonb not null default '{}'::jsonb,
  procesado boolean not null default false,
  procesado_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.catalogo_monedas (
  codigo text primary key,
  nombre text not null,
  simbolo text not null,
  activo boolean not null default true
);

create table if not exists public.catalogo_idiomas (
  codigo text primary key,
  nombre text not null,
  activo boolean not null default true
);

create table if not exists public.catalogo_unidades_medida (
  id uuid primary key default gen_random_uuid(),
  clave text not null unique,
  nombre text not null,
  activo boolean not null default true
);

create table if not exists public.catalogo_industrias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  activo boolean not null default true
);

create table if not exists public.catalogo_tamanos_empresa (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  activo boolean not null default true
);

create table if not exists public.catalogo_modulos (
  key text primary key,
  nombre text not null,
  activo boolean not null default true
);

create table if not exists public.empresa_localizacion (
  empresa_id uuid primary key references public.empresas(id) on delete cascade,
  moneda text not null default 'MXN',
  idioma text not null default 'es-MX',
  huso_horario text not null default 'America/Tijuana',
  formato_fecha text not null default 'dd/MM/yyyy',
  formato_moneda text not null default '1,000.00 MXN',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.empresa_impuestos_config (
  empresa_id uuid primary key references public.empresas(id) on delete cascade,
  tasas_linea text not null default '',
  impuestos_sobre_gastos text not null default '',
  impuestos_inclusivos text not null default '',
  tasa_predeterminada text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.empresa_tasas_impuesto (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nombre text not null,
  porcentaje numeric(8,4) not null default 0,
  tipo text not null default 'traslado' check (tipo in ('traslado', 'retencion')),
  aplica_a text not null default 'general' check (aplica_a in ('linea', 'gasto', 'general')),
  inclusivo boolean not null default false,
  predeterminada boolean not null default false,
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.empresa_diseno_documentos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  tipo_documento text not null check (tipo_documento in ('invoice', 'quote', 'credit', 'purchase_order')),
  preset_diseno text not null default 'Clean',
  orientacion_pagina text not null default 'Retrato',
  page_size text not null default 'A4',
  font_size integer not null default 18,
  logo_size_mode text not null default 'Porcentaje',
  logo_size_value numeric(10,2) not null default 24,
  fuente_primaria text not null default 'Arimo',
  color_primario text not null default '000000',
  fuente_secundaria text not null default 'Arimo',
  color_secundario text not null default 'F8B142',
  show_paid_stamp boolean not null default false,
  show_shipping_address boolean not null default false,
  embed_attachments boolean not null default false,
  empty_columns_mode text not null default 'Espectaculo',
  show_page_number boolean not null default false,
  show_client_summary boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (empresa_id, tipo_documento)
);

create table if not exists public.empresa_modulos_habilitados (
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  modulo_key text not null references public.catalogo_modulos(key),
  enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (empresa_id, modulo_key)
);

create table if not exists public.clientes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nombre text not null default '',
  empresa text not null default '',
  contacto text not null default '',
  numero text not null default '',
  id_number text not null default '',
  rfc_cif_nif text not null default '',
  sitio_web text not null default '',
  telefono text not null default '',
  correo text not null default '',
  direccion text not null default '',
  routing_number text not null default '',
  iva_valido boolean not null default false,
  exento_impuestos boolean not null default false,
  activo boolean not null default true,
  notas text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create index if not exists clientes_empresa_idx on public.clientes (empresa_id);
create index if not exists clientes_busqueda_idx on public.clientes (empresa_id, lower(nombre), lower(empresa));

create table if not exists public.cliente_contactos (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  nombres text not null default '',
  apellidos text not null default '',
  correo text not null default '',
  telefono text not null default '',
  puesto text not null default '',
  es_principal boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.cliente_direcciones (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.clientes(id) on delete cascade,
  tipo text not null default 'envio',
  calle text not null default '',
  apartamento_suite text not null default '',
  ciudad text not null default '',
  estado_provincia text not null default '',
  codigo_postal text not null default '',
  pais text not null default '',
  es_principal boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.cliente_configuracion (
  cliente_id uuid primary key references public.clientes(id) on delete cascade,
  moneda text,
  idioma text,
  terminos_pago text,
  cotizacion_valida_hasta_dias integer,
  tasa_tarea numeric(14,2),
  enviar_recordatorios boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.cliente_clasificacion (
  cliente_id uuid primary key references public.clientes(id) on delete cascade,
  tamano_empresa text,
  industria text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.proveedores (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nombre text not null default '',
  empresa text not null default '',
  contacto text not null default '',
  numero text not null default '',
  id_number text not null default '',
  rfc_cif_nif text not null default '',
  sitio_web text not null default '',
  telefono text not null default '',
  correo text not null default '',
  direccion text not null default '',
  routing_number text not null default '',
  iva_valido boolean not null default false,
  exento_impuestos boolean not null default false,
  activo boolean not null default true,
  notas text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create index if not exists proveedores_empresa_idx on public.proveedores (empresa_id);

create table if not exists public.proveedor_contactos (
  id uuid primary key default gen_random_uuid(),
  proveedor_id uuid not null references public.proveedores(id) on delete cascade,
  nombres text not null default '',
  apellidos text not null default '',
  correo text not null default '',
  telefono text not null default '',
  puesto text not null default '',
  es_principal boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.proveedor_direcciones (
  id uuid primary key default gen_random_uuid(),
  proveedor_id uuid not null references public.proveedores(id) on delete cascade,
  tipo text not null default 'principal',
  calle text not null default '',
  apartamento_suite text not null default '',
  ciudad text not null default '',
  estado_provincia text not null default '',
  codigo_postal text not null default '',
  pais text not null default '',
  es_principal boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.categorias_producto (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nombre text not null,
  descripcion text not null default '',
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (empresa_id, nombre)
);

create table if not exists public.materiales_insumos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nombre text not null,
  descripcion text not null default '',
  tipo_nombre text not null default '',
  unidad_medida text not null default '',
  costo_unitario numeric(14,4) not null default 0,
  stock_disponible numeric(14,4) not null default 0,
  proveedor_id uuid references public.proveedores(id) on delete set null,
  proveedor_nombre text not null default '',
  sku text not null,
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  unique (empresa_id, sku)
);

create table if not exists public.productos_servicios (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  tipo text not null check (tipo in ('producto', 'servicio')),
  nombre text not null,
  descripcion text not null default '',
  precio_base numeric(14,2) not null default 0,
  costo_base numeric(14,2) not null default 0,
  auto_calcular_costo_base boolean not null default true,
  modo_precio text not null default 'Fijo' check (modo_precio in ('Fijo', 'Dinamico')),
  cantidad_predeterminada numeric(14,4),
  cantidad_maxima numeric(14,4),
  categoria_producto_id uuid references public.categorias_producto(id) on delete set null,
  categoria_nombre_snapshot text not null default '',
  categoria_impuesto_nombre text not null default '',
  tasa_impuesto_nombre text not null default '',
  unidad_medida text not null default '',
  sku text not null,
  imagen_url text not null default '',
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  unique (empresa_id, sku)
);

create table if not exists public.producto_componentes (
  id uuid primary key default gen_random_uuid(),
  producto_id uuid not null references public.productos_servicios(id) on delete cascade,
  tipo text not null check (tipo in ('Material', 'Mano de obra', 'Costo indirecto')),
  material_id uuid references public.materiales_insumos(id) on delete set null,
  nombre_libre text not null default '',
  cantidad numeric(14,4) not null default 0,
  unidad_consumo text not null default '',
  costo_unitario_snapshot numeric(14,4) not null default 0,
  orden integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.producto_precios_rango (
  id uuid primary key default gen_random_uuid(),
  producto_id uuid not null references public.productos_servicios(id) on delete cascade,
  cantidad_desde numeric(14,4) not null default 0,
  cantidad_hasta numeric(14,4) not null default 0,
  precio numeric(14,2) not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.cotizaciones (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  usuario_id uuid not null references public.usuarios(id) on delete restrict,
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nombre_snapshot text not null default '',
  folio text not null,
  fecha_emision date not null,
  fecha_vencimiento date not null,
  deposito_parcial numeric(14,2) not null default 0,
  orden_numero text not null default '',
  descuento_tipo text not null default '',
  descuento_valor numeric(14,2) not null default 0,
  impuesto_porcentaje numeric(8,4) not null default 0,
  ret_isr boolean not null default false,
  subtotal numeric(14,2) not null default 0,
  descuento_total numeric(14,2) not null default 0,
  impuesto_total numeric(14,2) not null default 0,
  total numeric(14,2) not null default 0,
  pagado_total numeric(14,2) not null default 0,
  saldo_total numeric(14,2) not null default 0,
  notas text not null default '',
  notas_privadas text not null default '',
  terminos text not null default '',
  pie_pagina text not null default '',
  estatus text not null default 'borrador' check (estatus in ('borrador', 'enviada', 'aprobada', 'rechazada')),
  moneda_codigo text not null default 'MXN',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  unique (empresa_id, folio)
);

create table if not exists public.cotizacion_detalles (
  id uuid primary key default gen_random_uuid(),
  cotizacion_id uuid not null references public.cotizaciones(id) on delete cascade,
  producto_servicio_id uuid references public.productos_servicios(id) on delete set null,
  concepto text not null default '',
  descripcion text not null default '',
  precio_unitario numeric(14,2) not null default 0,
  unidad text not null default '',
  descuento numeric(14,2) not null default 0,
  cantidad numeric(14,4) not null default 0,
  impuesto_porcentaje numeric(8,4) not null default 0,
  importe numeric(14,2) not null default 0,
  orden integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.ingresos_recurrentes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nombre_snapshot text not null default '',
  cotizacion_id uuid references public.cotizaciones(id) on delete set null,
  cotizacion_folio_snapshot text not null default '',
  icon_key text not null default 'wallet',
  monto numeric(14,2) not null default 0,
  metodo_pago text not null default 'transferencia',
  frecuencia text not null default 'ninguna',
  fecha_inicio date not null default current_date,
  fecha_fin date,
  proxima_fecha date not null default current_date,
  activo boolean not null default true,
  notas text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.ingresos_recurrentes_dias (
  ingreso_recurrente_id uuid not null references public.ingresos_recurrentes(id) on delete cascade,
  weekday_iso smallint not null check (weekday_iso between 1 and 7),
  primary key (ingreso_recurrente_id, weekday_iso)
);

create table if not exists public.ingresos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  cliente_id uuid references public.clientes(id) on delete set null,
  cliente_nombre_snapshot text not null default '',
  cotizacion_id uuid references public.cotizaciones(id) on delete set null,
  cotizacion_folio_snapshot text not null default '',
  ingreso_recurrente_id uuid references public.ingresos_recurrentes(id) on delete set null,
  icon_key text not null default 'wallet',
  monto numeric(14,2) not null default 0,
  metodo_pago text not null default 'transferencia',
  fecha date not null default current_date,
  referencia text not null default '',
  notas text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create table if not exists public.gasto_categorias (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nombre text not null,
  descripcion text not null default '',
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (empresa_id, nombre)
);

create table if not exists public.gastos_recurrentes (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  gasto_categoria_id uuid references public.gasto_categorias(id) on delete set null,
  categoria_nombre_snapshot text not null default '',
  nombre text not null default '',
  monto numeric(14,2) not null default 0,
  frecuencia text not null default 'ninguna',
  fecha_inicio date not null default current_date,
  fecha_fin date,
  proxima_fecha date not null default current_date,
  activo boolean not null default true,
  notas text not null default '',
  icon_key text not null default 'shopping_cart',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.gastos_recurrentes_dias (
  gasto_recurrente_id uuid not null references public.gastos_recurrentes(id) on delete cascade,
  weekday_iso smallint not null check (weekday_iso between 1 and 7),
  primary key (gasto_recurrente_id, weekday_iso)
);

create table if not exists public.gastos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  gasto_categoria_id uuid references public.gasto_categorias(id) on delete set null,
  categoria_nombre_snapshot text not null default '',
  gasto_recurrente_id uuid references public.gastos_recurrentes(id) on delete set null,
  monto numeric(14,2) not null default 0,
  fecha date not null default current_date,
  proveedor_id uuid references public.proveedores(id) on delete set null,
  proveedor_nombre text not null default '',
  referencia text not null default '',
  descripcion text not null default '',
  notas text not null default '',
  icon_key text not null default 'shopping_cart',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz
);

create index if not exists productos_empresa_idx on public.productos_servicios (empresa_id);
create index if not exists materiales_empresa_idx on public.materiales_insumos (empresa_id);
create index if not exists cotizaciones_empresa_idx on public.cotizaciones (empresa_id, fecha_emision desc);
create index if not exists ingresos_empresa_idx on public.ingresos (empresa_id, fecha desc);
create index if not exists gastos_empresa_idx on public.gastos (empresa_id, fecha desc);

create trigger set_updated_at_empresas before update on public.empresas
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_usuarios before update on public.usuarios
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_usuario_empresas before update on public.usuario_empresas
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_suscripciones before update on public.suscripciones
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_empresa_localizacion before update on public.empresa_localizacion
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_empresa_impuestos_config before update on public.empresa_impuestos_config
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_empresa_tasas_impuesto before update on public.empresa_tasas_impuesto
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_empresa_diseno_documentos before update on public.empresa_diseno_documentos
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_empresa_modulos_habilitados before update on public.empresa_modulos_habilitados
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_clientes before update on public.clientes
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_cliente_contactos before update on public.cliente_contactos
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_cliente_direcciones before update on public.cliente_direcciones
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_cliente_configuracion before update on public.cliente_configuracion
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_cliente_clasificacion before update on public.cliente_clasificacion
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_proveedores before update on public.proveedores
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_proveedor_contactos before update on public.proveedor_contactos
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_proveedor_direcciones before update on public.proveedor_direcciones
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_categorias_producto before update on public.categorias_producto
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_materiales_insumos before update on public.materiales_insumos
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_productos_servicios before update on public.productos_servicios
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_producto_componentes before update on public.producto_componentes
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_producto_precios_rango before update on public.producto_precios_rango
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_cotizaciones before update on public.cotizaciones
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_cotizacion_detalles before update on public.cotizacion_detalles
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_ingresos before update on public.ingresos
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_ingresos_recurrentes before update on public.ingresos_recurrentes
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_gasto_categorias before update on public.gasto_categorias
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_gastos before update on public.gastos
for each row execute function public.app_set_updated_at();
create trigger set_updated_at_gastos_recurrentes before update on public.gastos_recurrentes
for each row execute function public.app_set_updated_at();

create or replace function public.app_current_empresa_ids()
returns uuid[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(ue.empresa_id), '{}'::uuid[])
  from public.usuario_empresas ue
  where ue.usuario_id = auth.uid();
$$;

create or replace function public.app_current_empresa_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select ue.empresa_id
      from public.usuario_empresas ue
      where ue.usuario_id = auth.uid()
      order by ue.es_principal desc, ue.created_at asc
      limit 1
    ),
    null
  );
$$;

create or replace function public.app_can_access_empresa(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_empresa_id is not null
    and p_empresa_id = any(public.app_current_empresa_ids());
$$;

create or replace function public.app_is_admin_for_empresa(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuario_empresas ue
    join public.usuarios u on u.id = ue.usuario_id
    where ue.usuario_id = auth.uid()
      and ue.empresa_id = p_empresa_id
      and u.rol = 'admin'
      and u.activo = true
  );
$$;

create or replace function public.app_require_company_access(p_empresa_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;
  if not public.app_can_access_empresa(p_empresa_id) then
    raise exception 'Sin acceso a la empresa';
  end if;
end;
$$;

create or replace function public.app_ensure_user_workspace(
  p_user_id uuid,
  p_email text default null,
  p_nombre text default null,
  p_nombre_empresa text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_email text := coalesce(nullif(trim(coalesce(p_email, '')), ''), '');
  v_alias text := nullif(split_part(v_email, '@', 1), '');
  v_nombre text := coalesce(
    nullif(trim(coalesce(p_nombre, '')), ''),
    initcap(replace(coalesce(v_alias, 'Usuario'), '.', ' ')),
    'Usuario'
  );
  v_nombre_empresa text := coalesce(
    nullif(trim(coalesce(p_nombre_empresa, '')), ''),
    'Empresa de ' || v_nombre
  );
begin
  if p_user_id is null then
    raise exception 'Usuario invalido';
  end if;

  insert into public.usuarios (id, nombre, correo)
  values (p_user_id, v_nombre, v_email)
  on conflict (id) do update
  set correo = excluded.correo,
      nombre = case
        when coalesce(public.usuarios.nombre, '') = '' then excluded.nombre
        else public.usuarios.nombre
      end,
      updated_at = timezone('utc', now());

  select ue.empresa_id
  into v_empresa_id
  from public.usuario_empresas ue
  where ue.usuario_id = p_user_id
  order by ue.es_principal desc, ue.created_at asc
  limit 1;

  if v_empresa_id is null then
    insert into public.empresas (nombre_fiscal, nombre_comercial, correo)
    values (v_nombre_empresa, v_nombre_empresa, v_email)
    returning id into v_empresa_id;

    insert into public.usuario_empresas (usuario_id, empresa_id, es_principal)
    values (p_user_id, v_empresa_id, true)
    on conflict (usuario_id, empresa_id) do update
    set es_principal = excluded.es_principal,
        updated_at = timezone('utc', now());

    insert into public.empresa_localizacion (empresa_id)
    values (v_empresa_id)
    on conflict (empresa_id) do nothing;

    insert into public.empresa_impuestos_config (empresa_id)
    values (v_empresa_id)
    on conflict (empresa_id) do nothing;

    insert into public.empresa_modulos_habilitados (
      empresa_id,
      modulo_key,
      enabled
    )
    select
      v_empresa_id,
      cm.key,
      cm.activo
    from public.catalogo_modulos cm
    on conflict (empresa_id, modulo_key) do update
    set enabled = excluded.enabled,
        updated_at = timezone('utc', now());

    if exists (select 1 from public.planes where id = 'starter')
      and not exists (
        select 1
        from public.suscripciones s
        where s.empresa_id = v_empresa_id
      ) then
      insert into public.suscripciones (
        empresa_id,
        plan_id,
        estado,
        fecha_inicio,
        fecha_fin,
        renovacion_automatica,
        usuarios_activos
      )
      values (
        v_empresa_id,
        'starter',
        'activa',
        timezone('utc', now()),
        timezone('utc', now()) + interval '100 years',
        false,
        1
      );
    end if;
  end if;

  return v_empresa_id;
end;
$$;

create or replace function public.app_handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_ensure_user_workspace(
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'nombre', ''),
    coalesce(new.raw_user_meta_data ->> 'empresa', '')
  );
  return new;
end;
$$;

create or replace function public.ensure_user_workspace()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user auth.users%rowtype;
  v_empresa_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  select *
  into v_auth_user
  from auth.users
  where id = auth.uid();

  v_empresa_id := public.app_ensure_user_workspace(
    auth.uid(),
    coalesce(v_auth_user.email, ''),
    coalesce(v_auth_user.raw_user_meta_data ->> 'nombre', ''),
    coalesce(v_auth_user.raw_user_meta_data ->> 'empresa', '')
  );

  return jsonb_build_object(
    'empresa_id', v_empresa_id
  );
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.app_handle_new_auth_user();

alter table public.empresas enable row level security;
alter table public.usuarios enable row level security;
alter table public.usuario_empresas enable row level security;
alter table public.suscripciones enable row level security;
alter table public.empresa_localizacion enable row level security;
alter table public.empresa_impuestos_config enable row level security;
alter table public.empresa_tasas_impuesto enable row level security;
alter table public.empresa_diseno_documentos enable row level security;
alter table public.empresa_modulos_habilitados enable row level security;
alter table public.clientes enable row level security;
alter table public.cliente_contactos enable row level security;
alter table public.cliente_direcciones enable row level security;
alter table public.cliente_configuracion enable row level security;
alter table public.cliente_clasificacion enable row level security;
alter table public.proveedores enable row level security;
alter table public.proveedor_contactos enable row level security;
alter table public.proveedor_direcciones enable row level security;
alter table public.categorias_producto enable row level security;
alter table public.materiales_insumos enable row level security;
alter table public.productos_servicios enable row level security;
alter table public.producto_componentes enable row level security;
alter table public.producto_precios_rango enable row level security;
alter table public.cotizaciones enable row level security;
alter table public.cotizacion_detalles enable row level security;
alter table public.ingresos_recurrentes enable row level security;
alter table public.ingresos_recurrentes_dias enable row level security;
alter table public.ingresos enable row level security;
alter table public.gasto_categorias enable row level security;
alter table public.gastos_recurrentes enable row level security;
alter table public.gastos_recurrentes_dias enable row level security;
alter table public.gastos enable row level security;
alter table public.planes enable row level security;

create policy empresas_select on public.empresas
for select using (public.app_can_access_empresa(id));
create policy empresas_update on public.empresas
for update using (public.app_can_access_empresa(id)) with check (public.app_can_access_empresa(id));

create policy usuarios_select on public.usuarios
for select using (
  id = auth.uid()
  or exists (
    select 1
    from public.usuario_empresas ue
    where ue.usuario_id = public.usuarios.id
      and public.app_can_access_empresa(ue.empresa_id)
  )
);
create policy usuarios_update on public.usuarios
for update using (
  id = auth.uid()
  or exists (
    select 1
    from public.usuario_empresas ue
    where ue.usuario_id = public.usuarios.id
      and public.app_is_admin_for_empresa(ue.empresa_id)
  )
) with check (true);

create policy usuario_empresas_select on public.usuario_empresas
for select using (usuario_id = auth.uid() or public.app_can_access_empresa(empresa_id));
create policy usuario_empresas_write on public.usuario_empresas
for all using (public.app_is_admin_for_empresa(empresa_id))
with check (public.app_is_admin_for_empresa(empresa_id));

create policy planes_select on public.planes
for select using (auth.uid() is not null);

create policy suscripciones_all on public.suscripciones
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));

create policy empresa_localizacion_all on public.empresa_localizacion
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy empresa_impuestos_config_all on public.empresa_impuestos_config
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy empresa_tasas_impuesto_all on public.empresa_tasas_impuesto
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy empresa_diseno_documentos_all on public.empresa_diseno_documentos
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy empresa_modulos_habilitados_all on public.empresa_modulos_habilitados
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));

create policy clientes_all on public.clientes
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy cliente_contactos_all on public.cliente_contactos
for all using (
  exists (
    select 1 from public.clientes c
    where c.id = cliente_contactos.cliente_id
      and public.app_can_access_empresa(c.empresa_id)
  )
) with check (
  exists (
    select 1 from public.clientes c
    where c.id = cliente_contactos.cliente_id
      and public.app_can_access_empresa(c.empresa_id)
  )
);
create policy cliente_direcciones_all on public.cliente_direcciones
for all using (
  exists (
    select 1 from public.clientes c
    where c.id = cliente_direcciones.cliente_id
      and public.app_can_access_empresa(c.empresa_id)
  )
) with check (
  exists (
    select 1 from public.clientes c
    where c.id = cliente_direcciones.cliente_id
      and public.app_can_access_empresa(c.empresa_id)
  )
);
create policy cliente_configuracion_all on public.cliente_configuracion
for all using (
  exists (
    select 1 from public.clientes c
    where c.id = cliente_configuracion.cliente_id
      and public.app_can_access_empresa(c.empresa_id)
  )
) with check (
  exists (
    select 1 from public.clientes c
    where c.id = cliente_configuracion.cliente_id
      and public.app_can_access_empresa(c.empresa_id)
  )
);
create policy cliente_clasificacion_all on public.cliente_clasificacion
for all using (
  exists (
    select 1 from public.clientes c
    where c.id = cliente_clasificacion.cliente_id
      and public.app_can_access_empresa(c.empresa_id)
  )
) with check (
  exists (
    select 1 from public.clientes c
    where c.id = cliente_clasificacion.cliente_id
      and public.app_can_access_empresa(c.empresa_id)
  )
);

create policy proveedores_all on public.proveedores
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy proveedor_contactos_all on public.proveedor_contactos
for all using (
  exists (
    select 1 from public.proveedores p
    where p.id = proveedor_contactos.proveedor_id
      and public.app_can_access_empresa(p.empresa_id)
  )
) with check (
  exists (
    select 1 from public.proveedores p
    where p.id = proveedor_contactos.proveedor_id
      and public.app_can_access_empresa(p.empresa_id)
  )
);
create policy proveedor_direcciones_all on public.proveedor_direcciones
for all using (
  exists (
    select 1 from public.proveedores p
    where p.id = proveedor_direcciones.proveedor_id
      and public.app_can_access_empresa(p.empresa_id)
  )
) with check (
  exists (
    select 1 from public.proveedores p
    where p.id = proveedor_direcciones.proveedor_id
      and public.app_can_access_empresa(p.empresa_id)
  )
);

create policy categorias_producto_all on public.categorias_producto
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy materiales_insumos_all on public.materiales_insumos
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy productos_servicios_all on public.productos_servicios
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy producto_componentes_all on public.producto_componentes
for all using (
  exists (
    select 1 from public.productos_servicios p
    where p.id = producto_componentes.producto_id
      and public.app_can_access_empresa(p.empresa_id)
  )
) with check (
  exists (
    select 1 from public.productos_servicios p
    where p.id = producto_componentes.producto_id
      and public.app_can_access_empresa(p.empresa_id)
  )
);
create policy producto_precios_rango_all on public.producto_precios_rango
for all using (
  exists (
    select 1 from public.productos_servicios p
    where p.id = producto_precios_rango.producto_id
      and public.app_can_access_empresa(p.empresa_id)
  )
) with check (
  exists (
    select 1 from public.productos_servicios p
    where p.id = producto_precios_rango.producto_id
      and public.app_can_access_empresa(p.empresa_id)
  )
);

create policy cotizaciones_all on public.cotizaciones
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy cotizacion_detalles_all on public.cotizacion_detalles
for all using (
  exists (
    select 1 from public.cotizaciones c
    where c.id = cotizacion_detalles.cotizacion_id
      and public.app_can_access_empresa(c.empresa_id)
  )
) with check (
  exists (
    select 1 from public.cotizaciones c
    where c.id = cotizacion_detalles.cotizacion_id
      and public.app_can_access_empresa(c.empresa_id)
  )
);

create policy ingresos_recurrentes_all on public.ingresos_recurrentes
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy ingresos_recurrentes_dias_all on public.ingresos_recurrentes_dias
for all using (
  exists (
    select 1 from public.ingresos_recurrentes ir
    where ir.id = ingresos_recurrentes_dias.ingreso_recurrente_id
      and public.app_can_access_empresa(ir.empresa_id)
  )
) with check (
  exists (
    select 1 from public.ingresos_recurrentes ir
    where ir.id = ingresos_recurrentes_dias.ingreso_recurrente_id
      and public.app_can_access_empresa(ir.empresa_id)
  )
);
create policy ingresos_all on public.ingresos
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));

create policy gasto_categorias_all on public.gasto_categorias
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy gastos_recurrentes_all on public.gastos_recurrentes
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));
create policy gastos_recurrentes_dias_all on public.gastos_recurrentes_dias
for all using (
  exists (
    select 1 from public.gastos_recurrentes gr
    where gr.id = gastos_recurrentes_dias.gasto_recurrente_id
      and public.app_can_access_empresa(gr.empresa_id)
  )
) with check (
  exists (
    select 1 from public.gastos_recurrentes gr
    where gr.id = gastos_recurrentes_dias.gasto_recurrente_id
      and public.app_can_access_empresa(gr.empresa_id)
  )
);
create policy gastos_all on public.gastos
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));

insert into public.catalogo_monedas (codigo, nombre, simbolo) values
('MXN', 'Peso Mexicano', '$'),
('USD', 'Dólar Estadounidense', '$')
on conflict (codigo) do nothing;

insert into public.catalogo_idiomas (codigo, nombre) values
('es-MX', 'Español'),
('en-US', 'English')
on conflict (codigo) do nothing;

insert into public.catalogo_modulos (key, nombre) values
('facturas', 'Facturas'),
('facturas_recurrentes', 'Facturas recurrentes'),
('cotizaciones', 'Cotizaciones'),
('creditos', 'Creditos'),
('proyectos', 'Proyectos'),
('tareas', 'Tareas'),
('vendedores', 'Vendedores'),
('gastos', 'Gastos'),
('ordenes_compra', 'Ordenes de compra'),
('gastos_recurrentes', 'Gastos recurrentes'),
('actas', 'Actas')
on conflict (key) do nothing;

insert into public.planes (
  id, nombre, precio_mensual, billing_mode, precio_por_usuario, descripcion,
  limite_clientes, limite_productos, limite_cotizaciones_mensuales,
  limite_usuarios, limite_empresas, usuarios_minimos, usuarios_maximos,
  incluye_ingresos_gastos, incluye_dashboard, incluye_personalizacion_pdf,
  incluye_notas_privadas, incluye_estados_cotizacion, incluye_marca_agua, activo
) values
('starter', 'Starter', 0, 'flat_monthly', 0, '20 clientes, 20 productos/servicios, 10 cotizaciones por mes, 1 usuario y 1 empresa.', 20, 20, 10, 1, 1, 0, 0, false, false, false, false, false, true, true),
('pro', 'Pro', 149, 'flat_monthly', 0, 'Clientes, productos y cotizaciones ilimitadas, 1 usuario, 1 empresa, ingresos y gastos.', -1, -1, -1, 1, 1, 0, 0, true, true, true, true, true, false, true),
('empresa', 'Empresa', 0, 'per_user_monthly', 99, 'Plan multiusuario de 2 a 50 usuarios, multiempresa hasta 5 empresas y soporte prioritario.', -1, -1, -1, 50, 5, 2, 50, true, true, true, true, true, false, true)
on conflict (id) do update set
  nombre = excluded.nombre,
  precio_mensual = excluded.precio_mensual,
  billing_mode = excluded.billing_mode,
  precio_por_usuario = excluded.precio_por_usuario,
  descripcion = excluded.descripcion,
  limite_clientes = excluded.limite_clientes,
  limite_productos = excluded.limite_productos,
  limite_cotizaciones_mensuales = excluded.limite_cotizaciones_mensuales,
  limite_usuarios = excluded.limite_usuarios,
  limite_empresas = excluded.limite_empresas,
  usuarios_minimos = excluded.usuarios_minimos,
  usuarios_maximos = excluded.usuarios_maximos,
  incluye_ingresos_gastos = excluded.incluye_ingresos_gastos,
  incluye_dashboard = excluded.incluye_dashboard,
  incluye_personalizacion_pdf = excluded.incluye_personalizacion_pdf,
  incluye_notas_privadas = excluded.incluye_notas_privadas,
  incluye_estados_cotizacion = excluded.incluye_estados_cotizacion,
  incluye_marca_agua = excluded.incluye_marca_agua,
  activo = excluded.activo;

create or replace function public.list_clientes(p_query text default '')
returns setof public.clientes
language sql
security definer
set search_path = public
as $$
  select c.*
  from public.clientes c
  where c.deleted_at is null
    and public.app_can_access_empresa(c.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(c.nombre) like '%' || lower(p_query) || '%'
      or lower(c.empresa) like '%' || lower(p_query) || '%'
      or lower(c.rfc_cif_nif) like '%' || lower(p_query) || '%'
    )
  order by c.updated_at desc;
$$;

create or replace function public.upsert_cliente(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_contacto_id uuid;
begin
  perform public.app_require_company_access(v_empresa_id);

  insert into public.clientes (
    id, empresa_id, numero, id_number, nombre, empresa, contacto, rfc_cif_nif,
    telefono, correo, direccion, notas, activo
  )
  values (
    v_id, v_empresa_id,
    coalesce(p_payload ->> 'numero', ''),
    coalesce(p_payload ->> 'id_number', ''),
    coalesce(p_payload ->> 'nombre', ''),
    coalesce(p_payload ->> 'empresa', ''),
    coalesce(p_payload ->> 'contacto', ''),
    coalesce(p_payload ->> 'rfc_cif_nif', ''),
    coalesce(p_payload ->> 'telefono', ''),
    coalesce(p_payload ->> 'correo', ''),
    coalesce(p_payload ->> 'direccion', ''),
    coalesce(p_payload ->> 'notas', ''),
    coalesce((p_payload ->> 'activo')::boolean, true)
  )
  on conflict (id) do update set
    numero = excluded.numero,
    id_number = excluded.id_number,
    nombre = excluded.nombre,
    empresa = excluded.empresa,
    contacto = excluded.contacto,
    rfc_cif_nif = excluded.rfc_cif_nif,
    telefono = excluded.telefono,
    correo = excluded.correo,
    direccion = excluded.direccion,
    notas = excluded.notas,
    activo = excluded.activo;

  if coalesce(p_payload ->> 'contacto', '') <> '' then
    select cc.id into v_contacto_id
    from public.cliente_contactos cc
    where cc.cliente_id = v_id
      and cc.es_principal = true
    limit 1;

    if v_contacto_id is null then
      insert into public.cliente_contactos (
        cliente_id, nombres, correo, telefono, es_principal
      ) values (
        v_id, coalesce(p_payload ->> 'contacto', ''),
        coalesce(p_payload ->> 'correo', ''),
        coalesce(p_payload ->> 'telefono', ''),
        true
      );
    else
      update public.cliente_contactos
      set nombres = coalesce(p_payload ->> 'contacto', ''),
          correo = coalesce(p_payload ->> 'correo', ''),
          telefono = coalesce(p_payload ->> 'telefono', '')
      where id = v_contacto_id;
    end if;
  end if;

  if coalesce(p_payload ->> 'direccion', '') <> '' then
    insert into public.cliente_direcciones (
      cliente_id, tipo, calle, es_principal
    )
    values (v_id, 'envio', coalesce(p_payload ->> 'direccion', ''), true)
    on conflict do nothing;
  end if;

  return v_id;
end;
$$;

create or replace function public.toggle_cliente_activo(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.clientes where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.clientes set activo = not activo where id = p_id;
end;
$$;

create or replace function public.delete_cliente(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.clientes where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.clientes set deleted_at = timezone('utc', now()) where id = p_id;
end;
$$;

create or replace function public.list_proveedores(p_query text default '')
returns setof public.proveedores
language sql
security definer
set search_path = public
as $$
  select p.*
  from public.proveedores p
  where p.deleted_at is null
    and public.app_can_access_empresa(p.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(p.nombre) like '%' || lower(p_query) || '%'
      or lower(p.empresa) like '%' || lower(p_query) || '%'
      or lower(p.rfc_cif_nif) like '%' || lower(p_query) || '%'
    )
  order by p.updated_at desc;
$$;

create or replace function public.upsert_proveedor(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
begin
  perform public.app_require_company_access(v_empresa_id);

  insert into public.proveedores (
    id, empresa_id, numero, id_number, nombre, empresa, contacto, rfc_cif_nif,
    telefono, correo, direccion, notas, activo
  )
  values (
    v_id, v_empresa_id,
    coalesce(p_payload ->> 'numero', ''),
    coalesce(p_payload ->> 'id_number', ''),
    coalesce(p_payload ->> 'nombre', ''),
    coalesce(p_payload ->> 'empresa', ''),
    coalesce(p_payload ->> 'contacto', ''),
    coalesce(p_payload ->> 'rfc_cif_nif', ''),
    coalesce(p_payload ->> 'telefono', ''),
    coalesce(p_payload ->> 'correo', ''),
    coalesce(p_payload ->> 'direccion', ''),
    coalesce(p_payload ->> 'notas', ''),
    coalesce((p_payload ->> 'activo')::boolean, true)
  )
  on conflict (id) do update set
    numero = excluded.numero,
    id_number = excluded.id_number,
    nombre = excluded.nombre,
    empresa = excluded.empresa,
    contacto = excluded.contacto,
    rfc_cif_nif = excluded.rfc_cif_nif,
    telefono = excluded.telefono,
    correo = excluded.correo,
    direccion = excluded.direccion,
    notas = excluded.notas,
    activo = excluded.activo;

  return v_id;
end;
$$;

create or replace function public.toggle_proveedor_activo(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.proveedores where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.proveedores set activo = not activo where id = p_id;
end;
$$;

create or replace function public.delete_proveedor(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.proveedores where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.proveedores set deleted_at = timezone('utc', now()) where id = p_id;
end;
$$;

create or replace function public.list_materiales(p_query text default '')
returns table (
  id uuid,
  nombre text,
  descripcion text,
  tipo_nombre text,
  unidad_medida text,
  costo_unitario numeric,
  stock_disponible numeric,
  proveedor_nombre text,
  sku text,
  activo boolean,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    m.id, m.nombre, m.descripcion, m.tipo_nombre, m.unidad_medida,
    m.costo_unitario, m.stock_disponible, m.proveedor_nombre, m.sku, m.activo,
    m.created_at, m.updated_at
  from public.materiales_insumos m
  where m.deleted_at is null
    and public.app_can_access_empresa(m.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(m.nombre) like '%' || lower(p_query) || '%'
      or lower(m.sku) like '%' || lower(p_query) || '%'
      or lower(m.proveedor_nombre) like '%' || lower(p_query) || '%'
    )
  order by m.updated_at desc;
$$;

create or replace function public.upsert_material(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_proveedor_id uuid := public.app_parse_uuid(p_payload ->> 'proveedor_id');
begin
  perform public.app_require_company_access(v_empresa_id);

  insert into public.materiales_insumos (
    id, empresa_id, nombre, descripcion, tipo_nombre, unidad_medida,
    costo_unitario, stock_disponible, proveedor_id, proveedor_nombre,
    sku, activo
  )
  values (
    v_id, v_empresa_id,
    coalesce(p_payload ->> 'nombre', ''),
    coalesce(p_payload ->> 'descripcion', ''),
    coalesce(p_payload ->> 'tipo_nombre', ''),
    coalesce(p_payload ->> 'unidad_medida', ''),
    coalesce((p_payload ->> 'costo_unitario')::numeric, 0),
    coalesce((p_payload ->> 'stock_disponible')::numeric, 0),
    v_proveedor_id,
    coalesce(p_payload ->> 'proveedor_nombre', ''),
    coalesce(p_payload ->> 'sku', ''),
    coalesce((p_payload ->> 'activo')::boolean, true)
  )
  on conflict (id) do update set
    nombre = excluded.nombre,
    descripcion = excluded.descripcion,
    tipo_nombre = excluded.tipo_nombre,
    unidad_medida = excluded.unidad_medida,
    costo_unitario = excluded.costo_unitario,
    stock_disponible = excluded.stock_disponible,
    proveedor_id = excluded.proveedor_id,
    proveedor_nombre = excluded.proveedor_nombre,
    sku = excluded.sku,
    activo = excluded.activo;

  return v_id;
end;
$$;

create or replace function public.delete_producto(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.productos_servicios where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.productos_servicios set deleted_at = timezone('utc', now()) where id = p_id;
end;
$$;

create or replace function public.delete_material(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.materiales_insumos where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.materiales_insumos set deleted_at = timezone('utc', now()) where id = p_id;
end;
$$;

create or replace function public.list_productos(p_query text default '')
returns table (
  id uuid,
  tipo text,
  nombre text,
  descripcion text,
  precio_base numeric,
  costo_base numeric,
  categoria_nombre text,
  unidad_medida text,
  sku text,
  imagen_url text,
  activo boolean,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    p.id, p.tipo, p.nombre, p.descripcion, p.precio_base, p.costo_base,
    coalesce(cp.nombre, p.categoria_nombre_snapshot) as categoria_nombre,
    p.unidad_medida, p.sku, p.imagen_url, p.activo, p.created_at, p.updated_at
  from public.productos_servicios p
  left join public.categorias_producto cp on cp.id = p.categoria_producto_id
  where p.deleted_at is null
    and public.app_can_access_empresa(p.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(p.nombre) like '%' || lower(p_query) || '%'
      or lower(p.sku) like '%' || lower(p_query) || '%'
      or lower(coalesce(cp.nombre, p.categoria_nombre_snapshot)) like '%' || lower(p_query) || '%'
    )
  order by p.updated_at desc;
$$;

create or replace function public.upsert_producto(
  p_id uuid default null,
  p_tipo text default 'producto',
  p_nombre text default '',
  p_descripcion text default '',
  p_precio_base numeric default 0,
  p_costo_base numeric default 0,
  p_auto_calcular_costo_base boolean default true,
  p_modo_precio text default 'Fijo',
  p_cantidad_predeterminada numeric default null,
  p_cantidad_maxima numeric default null,
  p_categoria_nombre text default '',
  p_categoria_impuesto_nombre text default '',
  p_tasa_impuesto_nombre text default '',
  p_unidad_medida text default '',
  p_sku text default '',
  p_imagen_url text default '',
  p_activo boolean default true,
  p_componentes jsonb default '[]'::jsonb,
  p_precios_por_rango jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(p_id, gen_random_uuid());
  v_categoria_id uuid;
  v_item jsonb;
  v_material_id uuid;
begin
  perform public.app_require_company_access(v_empresa_id);

  if coalesce(btrim(p_categoria_nombre), '') <> '' then
    insert into public.categorias_producto (empresa_id, nombre, descripcion)
    values (v_empresa_id, p_categoria_nombre, '')
    on conflict (empresa_id, nombre) do update set nombre = excluded.nombre
    returning id into v_categoria_id;

    if v_categoria_id is null then
      select id into v_categoria_id
      from public.categorias_producto
      where empresa_id = v_empresa_id
        and nombre = p_categoria_nombre
      limit 1;
    end if;
  end if;

  insert into public.productos_servicios (
    id, empresa_id, tipo, nombre, descripcion, precio_base, costo_base,
    auto_calcular_costo_base, modo_precio, cantidad_predeterminada,
    cantidad_maxima, categoria_producto_id, categoria_nombre_snapshot,
    categoria_impuesto_nombre, tasa_impuesto_nombre, unidad_medida, sku,
    imagen_url, activo
  )
  values (
    v_id, v_empresa_id, p_tipo, p_nombre, p_descripcion, p_precio_base,
    p_costo_base, p_auto_calcular_costo_base, p_modo_precio,
    p_cantidad_predeterminada, p_cantidad_maxima, v_categoria_id,
    p_categoria_nombre, p_categoria_impuesto_nombre, p_tasa_impuesto_nombre,
    p_unidad_medida, p_sku, p_imagen_url, p_activo
  )
  on conflict (id) do update set
    tipo = excluded.tipo,
    nombre = excluded.nombre,
    descripcion = excluded.descripcion,
    precio_base = excluded.precio_base,
    costo_base = excluded.costo_base,
    auto_calcular_costo_base = excluded.auto_calcular_costo_base,
    modo_precio = excluded.modo_precio,
    cantidad_predeterminada = excluded.cantidad_predeterminada,
    cantidad_maxima = excluded.cantidad_maxima,
    categoria_producto_id = excluded.categoria_producto_id,
    categoria_nombre_snapshot = excluded.categoria_nombre_snapshot,
    categoria_impuesto_nombre = excluded.categoria_impuesto_nombre,
    tasa_impuesto_nombre = excluded.tasa_impuesto_nombre,
    unidad_medida = excluded.unidad_medida,
    sku = excluded.sku,
    imagen_url = excluded.imagen_url,
    activo = excluded.activo;

  delete from public.producto_componentes where producto_id = v_id;
  for v_item in select * from jsonb_array_elements(coalesce(p_componentes, '[]'::jsonb))
  loop
    v_material_id := public.app_parse_uuid(v_item ->> 'material_id');
    insert into public.producto_componentes (
      producto_id, tipo, material_id, nombre_libre, cantidad, unidad_consumo,
      costo_unitario_snapshot, orden
    )
    values (
      v_id,
      coalesce(v_item ->> 'tipo', 'Material'),
      v_material_id,
      coalesce(v_item ->> 'nombre_libre', ''),
      coalesce((v_item ->> 'cantidad')::numeric, 0),
      coalesce(v_item ->> 'unidad_consumo', ''),
      coalesce((v_item ->> 'costo_unitario_snapshot')::numeric, 0),
      coalesce((v_item ->> 'orden')::integer, 0)
    );
  end loop;

  delete from public.producto_precios_rango where producto_id = v_id;
  for v_item in select * from jsonb_array_elements(coalesce(p_precios_por_rango, '[]'::jsonb))
  loop
    insert into public.producto_precios_rango (
      producto_id, cantidad_desde, cantidad_hasta, precio
    )
    values (
      v_id,
      coalesce((v_item ->> 'cantidad_desde')::numeric, 0),
      coalesce((v_item ->> 'cantidad_hasta')::numeric, 0),
      coalesce((v_item ->> 'precio')::numeric, 0)
    );
  end loop;

  return v_id;
end;
$$;

create or replace function public.delete_cotizacion(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.cotizaciones where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.cotizaciones set deleted_at = timezone('utc', now()) where id = p_id;
end;
$$;

create or replace function public.list_cotizaciones(p_query text default '')
returns table (
  id uuid,
  folio text,
  cliente_id text,
  fecha_emision date,
  fecha_vencimiento date,
  impuesto_porcentaje numeric,
  ret_isr boolean,
  subtotal numeric,
  descuento_total numeric,
  impuesto_total numeric,
  total numeric,
  notas text,
  notas_privadas text,
  terminos text,
  pie_pagina text,
  estatus text,
  usuario_id uuid,
  empresa_id uuid,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    c.id, c.folio, coalesce(c.cliente_id::text, c.cliente_nombre_snapshot) as cliente_id,
    c.fecha_emision, c.fecha_vencimiento, c.impuesto_porcentaje, c.ret_isr,
    c.subtotal, c.descuento_total, c.impuesto_total, c.total, c.notas,
    c.notas_privadas, c.terminos, c.pie_pagina, c.estatus, c.usuario_id,
    c.empresa_id, c.created_at, c.updated_at
  from public.cotizaciones c
  where c.deleted_at is null
    and public.app_can_access_empresa(c.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(c.folio) like '%' || lower(p_query) || '%'
      or lower(c.cliente_nombre_snapshot) like '%' || lower(p_query) || '%'
    )
  order by c.updated_at desc;
$$;

create or replace function public.list_cotizacion_detalles(p_cotizacion_id uuid default null)
returns setof public.cotizacion_detalles
language sql
security definer
set search_path = public
as $$
  select d.*
  from public.cotizacion_detalles d
  join public.cotizaciones c on c.id = d.cotizacion_id
  where public.app_can_access_empresa(c.empresa_id)
    and (p_cotizacion_id is null or d.cotizacion_id = p_cotizacion_id)
  order by d.cotizacion_id, d.orden asc, d.created_at asc;
$$;

create or replace function public.update_cotizacion_status(p_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.cotizaciones where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.cotizaciones
  set estatus = p_status
  where id = p_id;
end;
$$;

create or replace function public.upsert_cotizacion(
  p_id uuid default null,
  p_cliente_id text default '',
  p_fecha_emision timestamptz default timezone('utc', now()),
  p_fecha_vencimiento timestamptz default timezone('utc', now()),
  p_deposito_parcial numeric default 0,
  p_folio text default '',
  p_orden_numero text default '',
  p_descuento_tipo text default '',
  p_descuento_valor numeric default 0,
  p_impuesto_porcentaje numeric default 0,
  p_ret_isr boolean default false,
  p_notas text default '',
  p_notas_privadas text default '',
  p_terminos text default '',
  p_pie_pagina text default '',
  p_estatus text default 'borrador',
  p_lineas jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_usuario_id uuid := auth.uid();
  v_id uuid := coalesce(p_id, gen_random_uuid());
  v_cliente_uuid uuid := public.app_parse_uuid(p_cliente_id);
  v_cliente_snapshot text := '';
  v_linea jsonb;
  v_subtotal numeric := 0;
  v_impuesto_total numeric := 0;
  v_total numeric := 0;
  v_folio text := btrim(coalesce(p_folio, ''));
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_cliente_uuid is not null then
    if not exists (
      select 1 from public.clientes c
      where c.id = v_cliente_uuid
        and c.empresa_id = v_empresa_id
    ) then
      v_cliente_uuid := null;
      v_cliente_snapshot := p_cliente_id;
    end if;
  else
    v_cliente_snapshot := p_cliente_id;
  end if;

  for v_linea in select * from jsonb_array_elements(coalesce(p_lineas, '[]'::jsonb))
  loop
    v_subtotal := v_subtotal + coalesce((v_linea ->> 'importe')::numeric, 0);
    v_impuesto_total := v_impuesto_total + (
      coalesce((v_linea ->> 'importe')::numeric, 0)
      * coalesce((v_linea ->> 'impuesto_porcentaje')::numeric, 0) / 100
    );
  end loop;
  v_total := v_subtotal - coalesce(p_descuento_valor, 0) + v_impuesto_total;

  if v_folio = '' then
    v_folio := 'COT-' || to_char(current_date, 'YYYY') || '-' ||
      lpad((floor(random() * 9000) + 1000)::text, 4, '0');
  end if;

  insert into public.cotizaciones (
    id, empresa_id, usuario_id, cliente_id, cliente_nombre_snapshot, folio,
    fecha_emision, fecha_vencimiento, deposito_parcial, orden_numero,
    descuento_tipo, descuento_valor, impuesto_porcentaje, ret_isr, subtotal,
    descuento_total, impuesto_total, total, pagado_total, saldo_total, notas,
    notas_privadas, terminos, pie_pagina, estatus, moneda_codigo
  )
  values (
    v_id, v_empresa_id, v_usuario_id, v_cliente_uuid, v_cliente_snapshot, v_folio,
    p_fecha_emision::date, p_fecha_vencimiento::date, p_deposito_parcial,
    p_orden_numero, p_descuento_tipo, p_descuento_valor, p_impuesto_porcentaje,
    p_ret_isr, v_subtotal, p_descuento_valor, v_impuesto_total, v_total, 0,
    v_total, p_notas, p_notas_privadas, p_terminos, p_pie_pagina, p_estatus, 'MXN'
  )
  on conflict (id) do update set
    cliente_id = excluded.cliente_id,
    cliente_nombre_snapshot = excluded.cliente_nombre_snapshot,
    folio = excluded.folio,
    fecha_emision = excluded.fecha_emision,
    fecha_vencimiento = excluded.fecha_vencimiento,
    deposito_parcial = excluded.deposito_parcial,
    orden_numero = excluded.orden_numero,
    descuento_tipo = excluded.descuento_tipo,
    descuento_valor = excluded.descuento_valor,
    impuesto_porcentaje = excluded.impuesto_porcentaje,
    ret_isr = excluded.ret_isr,
    subtotal = excluded.subtotal,
    descuento_total = excluded.descuento_total,
    impuesto_total = excluded.impuesto_total,
    total = excluded.total,
    saldo_total = excluded.total - public.cotizaciones.pagado_total,
    notas = excluded.notas,
    notas_privadas = excluded.notas_privadas,
    terminos = excluded.terminos,
    pie_pagina = excluded.pie_pagina,
    estatus = excluded.estatus;

   from public.cotizacion_detalles where cotizacion_id = v_id;
  for v_linea in select * from jsonb_array_elements(coalesce(p_lineas, '[]'::jsonb))
  loop
    insert into public.cotizacion_detalles (
      cotizacion_id, producto_servicio_id, concepto, descripcion,
      precio_unitario, unidad, descuento, cantidad, impuesto_porcentaje,
      importe, orden
    )delete
    values (
      v_id,
      public.app_parse_uuid(v_linea ->> 'producto_servicio_id'),
      coalesce(v_linea ->> 'concepto', ''),
      coalesce(v_linea ->> 'descripcion', ''),
      coalesce((v_linea ->> 'precio_unitario')::numeric, 0),
      coalesce(v_linea ->> 'unidad', ''),
      coalesce((v_linea ->> 'descuento')::numeric, 0),
      coalesce((v_linea ->> 'cantidad')::numeric, 0),
      coalesce((v_linea ->> 'impuesto_porcentaje')::numeric, 0),
      coalesce((v_linea ->> 'importe')::numeric, 0),
      coalesce((v_linea ->> 'orden')::integer, 0)
    );
  end loop;

  return v_id;
end;
$$;

create or replace function public.list_ingresos()
returns table (
  id uuid,
  cliente_id text,
  cotizacion_id text,
  monto numeric,
  metodo_pago text,
  fecha date,
  referencia text,
  notas text,
  recurrente boolean,
  recurrencia text,
  dias_semana int[],
  icon_key text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    i.id,
    coalesce(i.cliente_id::text, i.cliente_nombre_snapshot) as cliente_id,
    coalesce(i.cotizacion_id::text, i.cotizacion_folio_snapshot) as cotizacion_id,
    i.monto, i.metodo_pago, i.fecha, i.referencia, i.notas,
    (i.ingreso_recurrente_id is not null) as recurrente,
    coalesce(ir.frecuencia, 'ninguna') as recurrencia,
    coalesce(
      (
        select array_agg(ird.weekday_iso order by ird.weekday_iso)
        from public.ingresos_recurrentes_dias ird
        where ird.ingreso_recurrente_id = i.ingreso_recurrente_id
      ),
      '{}'::int[]
    ) as dias_semana,
    i.icon_key, i.created_at, i.updated_at
  from public.ingresos i
  left join public.ingresos_recurrentes ir on ir.id = i.ingreso_recurrente_id
  where i.deleted_at is null
    and public.app_can_access_empresa(i.empresa_id)
  order by i.fecha desc, i.updated_at desc;
$$;

create or replace function public.upsert_ingreso(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_cliente_uuid uuid := public.app_parse_uuid(p_payload ->> 'cliente_id');
  v_cotizacion_uuid uuid := public.app_parse_uuid(p_payload ->> 'cotizacion_id');
  v_cliente_snapshot text := '';
  v_cotizacion_snapshot text := '';
  v_recurrente boolean := coalesce((p_payload ->> 'recurrente')::boolean, false);
  v_recurrente_id uuid;
  v_day int;
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_cliente_uuid is null then
    v_cliente_snapshot := coalesce(p_payload ->> 'cliente_id', '');
  end if;
  if v_cotizacion_uuid is null then
    v_cotizacion_snapshot := coalesce(p_payload ->> 'cotizacion_id', '');
  end if;

  if v_recurrente then
    select ingreso_recurrente_id into v_recurrente_id
    from public.ingresos
    where id = v_id;

    if v_recurrente_id is null then
      v_recurrente_id := gen_random_uuid();
    end if;

    insert into public.ingresos_recurrentes (
      id, empresa_id, cliente_id, cliente_nombre_snapshot, cotizacion_id,
      cotizacion_folio_snapshot, icon_key, monto, metodo_pago, frecuencia,
      fecha_inicio, proxima_fecha, activo, notas
    )
    values (
      v_recurrente_id, v_empresa_id, v_cliente_uuid, v_cliente_snapshot,
      v_cotizacion_uuid, v_cotizacion_snapshot,
      coalesce(p_payload ->> 'icon_key', 'wallet'),
      coalesce((p_payload ->> 'monto')::numeric, 0),
      coalesce(p_payload ->> 'metodo_pago', 'transferencia'),
      coalesce(p_payload ->> 'recurrencia', 'ninguna'),
      coalesce((p_payload ->> 'fecha')::date, current_date),
      coalesce((p_payload ->> 'fecha')::date, current_date),
      true,
      coalesce(p_payload ->> 'notas', '')
    )
    on conflict (id) do update set
      cliente_id = excluded.cliente_id,
      cliente_nombre_snapshot = excluded.cliente_nombre_snapshot,
      cotizacion_id = excluded.cotizacion_id,
      cotizacion_folio_snapshot = excluded.cotizacion_folio_snapshot,
      icon_key = excluded.icon_key,
      monto = excluded.monto,
      metodo_pago = excluded.metodo_pago,
      frecuencia = excluded.frecuencia,
      fecha_inicio = excluded.fecha_inicio,
      proxima_fecha = excluded.proxima_fecha,
      activo = true,
      notas = excluded.notas;

    delete from public.ingresos_recurrentes_dias where ingreso_recurrente_id = v_recurrente_id;
    for v_day in
      select value::text::int
      from jsonb_array_elements(coalesce(p_payload -> 'dias_semana', '[]'::jsonb))
    loop
      insert into public.ingresos_recurrentes_dias (ingreso_recurrente_id, weekday_iso)
      values (v_recurrente_id, v_day)
      on conflict do nothing;
    end loop;
  else
    v_recurrente_id := null;
  end if;

  insert into public.ingresos (
    id, empresa_id, cliente_id, cliente_nombre_snapshot, cotizacion_id,
    cotizacion_folio_snapshot, ingreso_recurrente_id, icon_key, monto,
    metodo_pago, fecha, referencia, notas
  )
  values (
    v_id, v_empresa_id, v_cliente_uuid, v_cliente_snapshot, v_cotizacion_uuid,
    v_cotizacion_snapshot, v_recurrente_id, coalesce(p_payload ->> 'icon_key', 'wallet'),
    coalesce((p_payload ->> 'monto')::numeric, 0),
    coalesce(p_payload ->> 'metodo_pago', 'transferencia'),
    coalesce((p_payload ->> 'fecha')::date, current_date),
    coalesce(p_payload ->> 'referencia', ''),
    coalesce(p_payload ->> 'notas', '')
  )
  on conflict (id) do update set
    cliente_id = excluded.cliente_id,
    cliente_nombre_snapshot = excluded.cliente_nombre_snapshot,
    cotizacion_id = excluded.cotizacion_id,
    cotizacion_folio_snapshot = excluded.cotizacion_folio_snapshot,
    ingreso_recurrente_id = excluded.ingreso_recurrente_id,
    icon_key = excluded.icon_key,
    monto = excluded.monto,
    metodo_pago = excluded.metodo_pago,
    fecha = excluded.fecha,
    referencia = excluded.referencia,
    notas = excluded.notas;

  return v_id;
end;
$$;

create or replace function public.delete_ingreso(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.ingresos where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.ingresos set deleted_at = timezone('utc', now()) where id = p_id;
end;
$$;

create or replace function public.list_gasto_categorias()
returns setof public.gasto_categorias
language sql
security definer
set search_path = public
as $$
  select gc.*
  from public.gasto_categorias gc
  where public.app_can_access_empresa(gc.empresa_id)
  order by gc.nombre;
$$;

create or replace function public.list_gastos_recurrentes()
returns setof public.gastos_recurrentes
language sql
security definer
set search_path = public
as $$
  select gr.*
  from public.gastos_recurrentes gr
  where public.app_can_access_empresa(gr.empresa_id)
  order by gr.proxima_fecha asc;
$$;

create or replace function public.list_gastos()
returns table (
  id uuid,
  gasto_categoria_id text,
  monto numeric,
  fecha date,
  descripcion text,
  proveedor_nombre text,
  referencia text,
  notas text,
  recurrente boolean,
  recurrencia text,
  dias_semana int[],
  icon_key text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    g.id,
    coalesce(g.gasto_categoria_id::text, g.categoria_nombre_snapshot) as gasto_categoria_id,
    g.monto, g.fecha, g.descripcion, g.proveedor_nombre, g.referencia, g.notas,
    (g.gasto_recurrente_id is not null) as recurrente,
    coalesce(gr.frecuencia, 'ninguna') as recurrencia,
    coalesce(
      (
        select array_agg(grd.weekday_iso order by grd.weekday_iso)
        from public.gastos_recurrentes_dias grd
        where grd.gasto_recurrente_id = g.gasto_recurrente_id
      ),
      '{}'::int[]
    ) as dias_semana,
    g.icon_key, g.created_at, g.updated_at
  from public.gastos g
  left join public.gastos_recurrentes gr on gr.id = g.gasto_recurrente_id
  where g.deleted_at is null
    and public.app_can_access_empresa(g.empresa_id)
  order by g.fecha desc, g.updated_at desc;
$$;

create or replace function public.upsert_gasto(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_categoria_uuid uuid := public.app_parse_uuid(p_payload ->> 'gasto_categoria_id');
  v_categoria_snapshot text := '';
  v_recurrente boolean := coalesce((p_payload ->> 'recurrente')::boolean, false);
  v_recurrente_id uuid;
  v_day int;
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_categoria_uuid is null and coalesce(p_payload ->> 'gasto_categoria_id', '') <> '' then
    insert into public.gasto_categorias (empresa_id, nombre, descripcion)
    values (v_empresa_id, p_payload ->> 'gasto_categoria_id', '')
    on conflict (empresa_id, nombre) do update set nombre = excluded.nombre;

    select id into v_categoria_uuid
    from public.gasto_categorias
    where empresa_id = v_empresa_id
      and nombre = (p_payload ->> 'gasto_categoria_id')
    limit 1;
  end if;

  if v_categoria_uuid is null then
    v_categoria_snapshot := coalesce(p_payload ->> 'gasto_categoria_id', '');
  end if;

  if v_recurrente then
    select gasto_recurrente_id into v_recurrente_id
    from public.gastos
    where id = v_id;

    if v_recurrente_id is null then
      v_recurrente_id := gen_random_uuid();
    end if;

    insert into public.gastos_recurrentes (
      id, empresa_id, gasto_categoria_id, categoria_nombre_snapshot, nombre,
      monto, frecuencia, fecha_inicio, proxima_fecha, activo, notas, icon_key
    )
    values (
      v_recurrente_id, v_empresa_id, v_categoria_uuid, v_categoria_snapshot,
      coalesce(p_payload ->> 'descripcion', ''),
      coalesce((p_payload ->> 'monto')::numeric, 0),
      coalesce(p_payload ->> 'recurrencia', 'ninguna'),
      coalesce((p_payload ->> 'fecha')::date, current_date),
      coalesce((p_payload ->> 'fecha')::date, current_date),
      true,
      coalesce(p_payload ->> 'notas', ''),
      coalesce(p_payload ->> 'icon_key', 'shopping_cart')
    )
    on conflict (id) do update set
      gasto_categoria_id = excluded.gasto_categoria_id,
      categoria_nombre_snapshot = excluded.categoria_nombre_snapshot,
      nombre = excluded.nombre,
      monto = excluded.monto,
      frecuencia = excluded.frecuencia,
      fecha_inicio = excluded.fecha_inicio,
      proxima_fecha = excluded.proxima_fecha,
      activo = true,
      notas = excluded.notas,
      icon_key = excluded.icon_key;

    delete from public.gastos_recurrentes_dias where gasto_recurrente_id = v_recurrente_id;
    for v_day in
      select value::text::int
      from jsonb_array_elements(coalesce(p_payload -> 'dias_semana', '[]'::jsonb))
    loop
      insert into public.gastos_recurrentes_dias (gasto_recurrente_id, weekday_iso)
      values (v_recurrente_id, v_day)
      on conflict do nothing;
    end loop;
  else
    v_recurrente_id := null;
  end if;

  insert into public.gastos (
    id, empresa_id, gasto_categoria_id, categoria_nombre_snapshot,
    gasto_recurrente_id, monto, fecha, proveedor_nombre, referencia,
    descripcion, notas, icon_key
  )
  values (
    v_id, v_empresa_id, v_categoria_uuid, v_categoria_snapshot,
    v_recurrente_id, coalesce((p_payload ->> 'monto')::numeric, 0),
    coalesce((p_payload ->> 'fecha')::date, current_date),
    coalesce(p_payload ->> 'proveedor_nombre', ''),
    coalesce(p_payload ->> 'referencia', ''),
    coalesce(p_payload ->> 'descripcion', ''),
    coalesce(p_payload ->> 'notas', ''),
    coalesce(p_payload ->> 'icon_key', 'shopping_cart')
  )
  on conflict (id) do update set
    gasto_categoria_id = excluded.gasto_categoria_id,
    categoria_nombre_snapshot = excluded.categoria_nombre_snapshot,
    gasto_recurrente_id = excluded.gasto_recurrente_id,
    monto = excluded.monto,
    fecha = excluded.fecha,
    proveedor_nombre = excluded.proveedor_nombre,
    referencia = excluded.referencia,
    descripcion = excluded.descripcion,
    notas = excluded.notas,
    icon_key = excluded.icon_key;

  return v_id;
end;
$$;

create or replace function public.delete_gasto(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id from public.gastos where id = p_id;
  perform public.app_require_company_access(v_empresa_id);
  update public.gastos set deleted_at = timezone('utc', now()) where id = p_id;
end;
$$;

create or replace function public.get_empresa_actual()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_payload jsonb;
begin
  perform public.app_require_company_access(v_empresa_id);

  select jsonb_build_object(
    'id', e.id,
    'logo_url', e.logo_url,
    'nombre_fiscal', e.nombre_fiscal,
    'nombre_comercial', e.nombre_comercial,
    'rfc', e.rfc,
    'direccion', e.direccion,
    'telefono', e.telefono,
    'correo', e.correo,
    'sitio_web', e.sitio_web,
    'color_primario', e.color_primario,
    'color_secundario', e.color_secundario,
    'color_fondo', e.color_fondo,
    'color_neutro', e.color_neutro,
    'theme_seleccionado', e.theme_seleccionado,
    'terminos_default', e.terminos_default,
    'pie_pagina_default', e.pie_pagina_default,
    'created_at', e.created_at,
    'updated_at', e.updated_at,
    'localizacion', jsonb_build_object(
      'moneda', coalesce(el.moneda, 'MXN'),
      'idioma', coalesce(el.idioma, 'es-MX'),
      'huso_horario', coalesce(el.huso_horario, 'America/Tijuana'),
      'formato_fecha', coalesce(el.formato_fecha, 'dd/MM/yyyy'),
      'formato_moneda', coalesce(el.formato_moneda, '1,000.00 MXN')
    ),
    'impuestos', jsonb_build_object(
      'tasas_linea', coalesce(eic.tasas_linea, ''),
      'impuestos_sobre_gastos', coalesce(eic.impuestos_sobre_gastos, ''),
      'impuestos_inclusivos', coalesce(eic.impuestos_inclusivos, ''),
      'tasa_predeterminada', coalesce(eic.tasa_predeterminada, '')
    )
  )
  into v_payload
  from public.empresas e
  left join public.empresa_localizacion el on el.empresa_id = e.id
  left join public.empresa_impuestos_config eic on eic.empresa_id = e.id
  where e.id = v_empresa_id;

  return coalesce(v_payload, '{}'::jsonb);
end;
$$;

create or replace function public.update_empresa_actual(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
begin
  perform public.app_require_company_access(v_empresa_id);

  update public.empresas
  set logo_url = coalesce(p_payload ->> 'logo_url', logo_url),
      nombre_fiscal = coalesce(p_payload ->> 'nombre_fiscal', nombre_fiscal),
      nombre_comercial = coalesce(p_payload ->> 'nombre_comercial', nombre_comercial),
      rfc = coalesce(p_payload ->> 'rfc', rfc),
      direccion = coalesce(p_payload ->> 'direccion', direccion),
      telefono = coalesce(p_payload ->> 'telefono', telefono),
      correo = coalesce(p_payload ->> 'correo', correo),
      sitio_web = coalesce(p_payload ->> 'sitio_web', sitio_web),
      color_primario = coalesce(p_payload ->> 'color_primario', color_primario),
      color_secundario = coalesce(p_payload ->> 'color_secundario', color_secundario),
      color_fondo = coalesce(p_payload ->> 'color_fondo', color_fondo),
      color_neutro = coalesce(p_payload ->> 'color_neutro', color_neutro),
      theme_seleccionado = coalesce(p_payload ->> 'theme_seleccionado', theme_seleccionado),
      terminos_default = coalesce(p_payload ->> 'terminos_default', terminos_default),
      pie_pagina_default = coalesce(p_payload ->> 'pie_pagina_default', pie_pagina_default)
  where id = v_empresa_id;

  insert into public.empresa_localizacion (
    empresa_id, moneda, idioma, huso_horario, formato_fecha, formato_moneda
  )
  values (
    v_empresa_id,
    coalesce(p_payload #>> '{localizacion,moneda}', 'MXN'),
    coalesce(p_payload #>> '{localizacion,idioma}', 'es-MX'),
    coalesce(p_payload #>> '{localizacion,huso_horario}', 'America/Tijuana'),
    coalesce(p_payload #>> '{localizacion,formato_fecha}', 'dd/MM/yyyy'),
    coalesce(p_payload #>> '{localizacion,formato_moneda}', '1,000.00 MXN')
  )
  on conflict (empresa_id) do update set
    moneda = excluded.moneda,
    idioma = excluded.idioma,
    huso_horario = excluded.huso_horario,
    formato_fecha = excluded.formato_fecha,
    formato_moneda = excluded.formato_moneda;

  insert into public.empresa_impuestos_config (
    empresa_id, tasas_linea, impuestos_sobre_gastos, impuestos_inclusivos,
    tasa_predeterminada
  )
  values (
    v_empresa_id,
    coalesce(p_payload #>> '{impuestos,tasas_linea}', ''),
    coalesce(p_payload #>> '{impuestos,impuestos_sobre_gastos}', ''),
    coalesce(p_payload #>> '{impuestos,impuestos_inclusivos}', ''),
    coalesce(p_payload #>> '{impuestos,tasa_predeterminada}', '')
  )
  on conflict (empresa_id) do update set
    tasas_linea = excluded.tasas_linea,
    impuestos_sobre_gastos = excluded.impuestos_sobre_gastos,
    impuestos_inclusivos = excluded.impuestos_inclusivos,
    tasa_predeterminada = excluded.tasa_predeterminada;

  return v_empresa_id;
end;
$$;

create or replace function public.list_usuarios()
returns table (
  id uuid,
  nombre text,
  telefono text,
  correo text,
  rol text,
  activo boolean,
  ultimo_acceso_at timestamptz,
  empresa_ids text[],
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    u.id, u.nombre, u.telefono, u.correo, u.rol, u.activo, u.ultimo_acceso_at,
    array_agg(ue.empresa_id::text order by ue.es_principal desc, ue.created_at asc) as empresa_ids,
    u.created_at, u.updated_at
  from public.usuarios u
  join public.usuario_empresas ue on ue.usuario_id = u.id
  where public.app_can_access_empresa(ue.empresa_id)
  group by u.id, u.nombre, u.telefono, u.correo, u.rol, u.activo, u.ultimo_acceso_at, u.created_at, u.updated_at
  order by u.nombre;
$$;

create or replace function public.list_planes()
returns setof public.planes
language sql
security definer
set search_path = public
as $$
  select p.*
  from public.planes p
  where p.activo = true
  order by
    case p.id
      when 'starter' then 1
      when 'pro' then 2
      when 'empresa' then 3
      else 99
    end,
    p.precio_mensual asc,
    p.precio_por_usuario asc;
$$;

create or replace function public.get_suscripcion_actual()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_payload jsonb;
begin
  perform public.app_require_company_access(v_empresa_id);

  select jsonb_build_object(
    'id', s.id,
    'empresa_id', s.empresa_id,
    'plan_id', s.plan_id,
    'estado', s.estado,
    'fecha_inicio', s.fecha_inicio,
    'fecha_fin', s.fecha_fin,
    'renovacion_automatica', s.renovacion_automatica,
    'usuarios_activos', s.usuarios_activos,
    'created_at', s.created_at,
    'updated_at', s.updated_at
  )
  into v_payload
  from public.suscripciones s
  where s.empresa_id = v_empresa_id
  order by s.updated_at desc
  limit 1;

  return coalesce(v_payload, '{}'::jsonb);
end;
$$;

grant execute on function public.list_clientes(text) to authenticated;
grant execute on function public.upsert_cliente(jsonb) to authenticated;
grant execute on function public.toggle_cliente_activo(uuid) to authenticated;
grant execute on function public.delete_cliente(uuid) to authenticated;
grant execute on function public.list_proveedores(text) to authenticated;
grant execute on function public.upsert_proveedor(jsonb) to authenticated;
grant execute on function public.toggle_proveedor_activo(uuid) to authenticated;
grant execute on function public.delete_proveedor(uuid) to authenticated;
grant execute on function public.list_materiales(text) to authenticated;
grant execute on function public.upsert_material(jsonb) to authenticated;
grant execute on function public.delete_material(uuid) to authenticated;
grant execute on function public.list_productos(text) to authenticated;
grant execute on function public.upsert_producto(uuid, text, text, text, numeric, numeric, boolean, text, numeric, numeric, text, text, text, text, text, text, boolean, jsonb, jsonb) to authenticated;
grant execute on function public.delete_producto(uuid) to authenticated;
grant execute on function public.list_cotizaciones(text) to authenticated;
grant execute on function public.list_cotizacion_detalles(uuid) to authenticated;
grant execute on function public.update_cotizacion_status(uuid, text) to authenticated;
grant execute on function public.upsert_cotizacion(uuid, text, timestamptz, timestamptz, numeric, text, text, text, numeric, numeric, boolean, text, text, text, text, text, jsonb) to authenticated;
grant execute on function public.delete_cotizacion(uuid) to authenticated;
grant execute on function public.list_ingresos() to authenticated;
grant execute on function public.upsert_ingreso(jsonb) to authenticated;
grant execute on function public.delete_ingreso(uuid) to authenticated;
grant execute on function public.list_gasto_categorias() to authenticated;
grant execute on function public.list_gastos_recurrentes() to authenticated;
grant execute on function public.list_gastos() to authenticated;
grant execute on function public.upsert_gasto(jsonb) to authenticated;
grant execute on function public.delete_gasto(uuid) to authenticated;
grant execute on function public.get_empresa_actual() to authenticated;
grant execute on function public.update_empresa_actual(jsonb) to authenticated;
grant execute on function public.list_usuarios() to authenticated;
grant execute on function public.list_planes() to authenticated;
grant execute on function public.get_suscripcion_actual() to authenticated;
grant execute on function public.ensure_user_workspace() to authenticated;
