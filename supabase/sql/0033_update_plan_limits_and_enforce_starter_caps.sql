alter table public.planes
  add column if not exists limite_materiales integer not null default 0,
  add column if not exists incluye_analitica boolean not null default false;

update public.planes
set
  nombre = 'Starter',
  precio_mensual = 0,
  billing_mode = 'flat_monthly',
  precio_por_usuario = 0,
  descripcion = '5 clientes, 5 productos/servicios, 5 materiales, 10 cotizaciones por mes con marca de agua de Cotimax, ingresos, gastos y recordatorios ilimitados, 1 usuario.',
  limite_clientes = 5,
  limite_productos = 5,
  limite_materiales = 5,
  limite_cotizaciones_mensuales = 10,
  limite_usuarios = 1,
  limite_empresas = 1,
  usuarios_minimos = 0,
  usuarios_maximos = 0,
  incluye_ingresos_gastos = true,
  incluye_dashboard = true,
  incluye_analitica = false,
  incluye_personalizacion_pdf = false,
  incluye_notas_privadas = false,
  incluye_estados_cotizacion = false,
  incluye_marca_agua = true,
  activo = true
where id = 'starter';

update public.planes
set
  nombre = 'Pro',
  precio_mensual = 249,
  billing_mode = 'flat_monthly',
  precio_por_usuario = 0,
  descripcion = 'Clientes, productos, materiales, cotizaciones, ingresos, gastos y recordatorios ilimitados, 1 usuario.',
  limite_clientes = -1,
  limite_productos = -1,
  limite_materiales = -1,
  limite_cotizaciones_mensuales = -1,
  limite_usuarios = 1,
  limite_empresas = 1,
  usuarios_minimos = 0,
  usuarios_maximos = 0,
  incluye_ingresos_gastos = true,
  incluye_dashboard = true,
  incluye_analitica = true,
  incluye_personalizacion_pdf = true,
  incluye_notas_privadas = true,
  incluye_estados_cotizacion = true,
  incluye_marca_agua = false,
  activo = true
where id = 'pro';

update public.planes
set
  nombre = 'Empresa',
  precio_mensual = 0,
  billing_mode = 'per_user_monthly',
  precio_por_usuario = 199,
  descripcion = 'Clientes, productos, materiales, cotizaciones, ingresos, gastos y recordatorios ilimitados, de 2 a 50 usuarios.',
  limite_clientes = -1,
  limite_productos = -1,
  limite_materiales = -1,
  limite_cotizaciones_mensuales = -1,
  limite_usuarios = 50,
  limite_empresas = 5,
  usuarios_minimos = 2,
  usuarios_maximos = 50,
  incluye_ingresos_gastos = true,
  incluye_dashboard = true,
  incluye_analitica = true,
  incluye_personalizacion_pdf = true,
  incluye_notas_privadas = true,
  incluye_estados_cotizacion = true,
  incluye_marca_agua = false,
  activo = true
where id = 'empresa';

insert into public.planes (
  id, nombre, precio_mensual, billing_mode, precio_por_usuario, descripcion,
  limite_clientes, limite_productos, limite_materiales,
  limite_cotizaciones_mensuales, limite_usuarios, limite_empresas,
  usuarios_minimos, usuarios_maximos, incluye_ingresos_gastos,
  incluye_dashboard, incluye_analitica, incluye_personalizacion_pdf,
  incluye_notas_privadas, incluye_estados_cotizacion, incluye_marca_agua,
  activo
) values
('starter', 'Starter', 0, 'flat_monthly', 0, '5 clientes, 5 productos/servicios, 5 materiales, 10 cotizaciones por mes con marca de agua de Cotimax, ingresos, gastos y recordatorios ilimitados, 1 usuario.', 5, 5, 5, 10, 1, 1, 0, 0, true, true, false, false, false, false, true, true),
('pro', 'Pro', 249, 'flat_monthly', 0, 'Clientes, productos, materiales, cotizaciones, ingresos, gastos y recordatorios ilimitados, 1 usuario.', -1, -1, -1, -1, 1, 1, 0, 0, true, true, true, true, true, true, false, true),
('empresa', 'Empresa', 0, 'per_user_monthly', 199, 'Clientes, productos, materiales, cotizaciones, ingresos, gastos y recordatorios ilimitados, de 2 a 50 usuarios.', -1, -1, -1, -1, 50, 5, 2, 50, true, true, true, true, true, true, false, true)
on conflict (id) do update set
  nombre = excluded.nombre,
  precio_mensual = excluded.precio_mensual,
  billing_mode = excluded.billing_mode,
  precio_por_usuario = excluded.precio_por_usuario,
  descripcion = excluded.descripcion,
  limite_clientes = excluded.limite_clientes,
  limite_productos = excluded.limite_productos,
  limite_materiales = excluded.limite_materiales,
  limite_cotizaciones_mensuales = excluded.limite_cotizaciones_mensuales,
  limite_usuarios = excluded.limite_usuarios,
  limite_empresas = excluded.limite_empresas,
  usuarios_minimos = excluded.usuarios_minimos,
  usuarios_maximos = excluded.usuarios_maximos,
  incluye_ingresos_gastos = excluded.incluye_ingresos_gastos,
  incluye_dashboard = excluded.incluye_dashboard,
  incluye_analitica = excluded.incluye_analitica,
  incluye_personalizacion_pdf = excluded.incluye_personalizacion_pdf,
  incluye_notas_privadas = excluded.incluye_notas_privadas,
  incluye_estados_cotizacion = excluded.incluye_estados_cotizacion,
  incluye_marca_agua = excluded.incluye_marca_agua,
  activo = excluded.activo;

create or replace function public.app_next_monthly_anchor(p_source date)
returns date
language plpgsql
immutable
set search_path = public
as $$
declare
  v_next_month date := (date_trunc('month', p_source::timestamp) + interval '1 month')::date;
  v_last_day integer := extract(
    day from (date_trunc('month', p_source::timestamp) + interval '2 month - 1 day')
  )::int;
begin
  return make_date(
    extract(year from v_next_month)::int,
    extract(month from v_next_month)::int,
    least(extract(day from p_source)::int, v_last_day)
  );
end;
$$;

create or replace function public.app_current_monthly_anchor(
  p_anchor date,
  p_reference date default current_date
)
returns table (
  window_start date,
  window_end date
)
language plpgsql
stable
set search_path = public
as $$
declare
  v_start date := coalesce(p_anchor, p_reference);
begin
  while p_reference >= public.app_next_monthly_anchor(v_start) loop
    v_start := public.app_next_monthly_anchor(v_start);
  end loop;

  return query
  select v_start, public.app_next_monthly_anchor(v_start);
end;
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
  v_direccion_id uuid;
  v_calle text := coalesce(p_payload ->> 'calle', '');
  v_apartamento_suite text := coalesce(p_payload ->> 'apartamento_suite', '');
  v_ciudad text := coalesce(p_payload ->> 'ciudad', '');
  v_estado_provincia text := coalesce(p_payload ->> 'estado_provincia', '');
  v_codigo_postal text := coalesce(p_payload ->> 'codigo_postal', '');
  v_pais text := coalesce(p_payload ->> 'pais', '');
  v_direccion text := coalesce(
    nullif(p_payload ->> 'direccion', ''),
    concat_ws(
      ', ',
      nullif(v_calle, ''),
      nullif(v_apartamento_suite, ''),
      nullif(v_ciudad, ''),
      nullif(v_estado_provincia, ''),
      nullif(v_codigo_postal, ''),
      nullif(v_pais, '')
    )
  );
  v_is_new boolean;
  v_limite_clientes integer := -1;
  v_clientes_actuales integer := 0;
begin
  perform public.app_require_company_access(v_empresa_id);

  select not exists(
    select 1
    from public.clientes c
    where c.id = v_id
      and c.empresa_id = v_empresa_id
  )
  into v_is_new;

  if v_is_new then
    select p.limite_clientes
    into v_limite_clientes
    from public.suscripciones s
    join public.planes p on p.id = s.plan_id
    where s.empresa_id = v_empresa_id
    order by s.updated_at desc
    limit 1;

    if coalesce(v_limite_clientes, -1) >= 0 then
      select count(*)::int into v_clientes_actuales
      from public.clientes
      where empresa_id = v_empresa_id;

      if v_clientes_actuales >= v_limite_clientes then
        raise exception 'Tu plan actual permite hasta % clientes.', v_limite_clientes;
      end if;
    end if;
  end if;

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
    coalesce(v_direccion, ''),
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

  select cd.id into v_direccion_id
  from public.cliente_direcciones cd
  where cd.cliente_id = v_id
  order by cd.es_principal desc, cd.updated_at desc, cd.created_at desc
  limit 1;

  if v_direccion_id is null then
    if v_calle <> ''
      or v_apartamento_suite <> ''
      or v_ciudad <> ''
      or v_estado_provincia <> ''
      or v_codigo_postal <> ''
      or v_pais <> '' then
      insert into public.cliente_direcciones (
        cliente_id, tipo, calle, apartamento_suite, ciudad,
        estado_provincia, codigo_postal, pais, es_principal
      )
      values (
        v_id, 'envio', v_calle, v_apartamento_suite, v_ciudad,
        v_estado_provincia, v_codigo_postal, v_pais, true
      );
    end if;
  else
    update public.cliente_direcciones
    set tipo = 'envio',
        calle = v_calle,
        apartamento_suite = v_apartamento_suite,
        ciudad = v_ciudad,
        estado_provincia = v_estado_provincia,
        codigo_postal = v_codigo_postal,
        pais = v_pais,
        es_principal = true
    where id = v_direccion_id;
  end if;

  return v_id;
end;
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
  v_producto_ids uuid[] := '{}'::uuid[];
  v_sync_producto_ids boolean := coalesce(
    nullif(p_payload ->> 'sync_producto_ids', '')::boolean,
    false
  );
  v_is_new boolean;
  v_limite_materiales integer := -1;
  v_materiales_actuales integer := 0;
begin
  perform public.app_require_company_access(v_empresa_id);

  select not exists(
    select 1
    from public.materiales_insumos m
    where m.id = v_id
      and m.empresa_id = v_empresa_id
  )
  into v_is_new;

  if v_is_new then
    select p.limite_materiales
    into v_limite_materiales
    from public.suscripciones s
    join public.planes p on p.id = s.plan_id
    where s.empresa_id = v_empresa_id
    order by s.updated_at desc
    limit 1;

    if coalesce(v_limite_materiales, -1) >= 0 then
      select count(*)::int into v_materiales_actuales
      from public.materiales_insumos
      where empresa_id = v_empresa_id;

      if v_materiales_actuales >= v_limite_materiales then
        raise exception 'Tu plan actual permite hasta % materiales.', v_limite_materiales;
      end if;
    end if;
  end if;

  if v_sync_producto_ids then
    select coalesce(array_agg(producto_id), '{}'::uuid[])
    into v_producto_ids
    from (
      select distinct public.app_parse_uuid(value) as producto_id
      from jsonb_array_elements_text(coalesce(p_payload -> 'producto_ids', '[]'::jsonb))
    ) selected_ids
    join public.productos_servicios p
      on p.id = selected_ids.producto_id
     and p.empresa_id = v_empresa_id
    where selected_ids.producto_id is not null;
  end if;

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

  if v_sync_producto_ids then
    delete from public.producto_componentes pc
    using public.productos_servicios p
    where p.id = pc.producto_id
      and p.empresa_id = v_empresa_id
      and pc.material_id = v_id
      and not (pc.producto_id = any(v_producto_ids));

    insert into public.producto_componentes (
      producto_id, tipo, material_id, nombre_libre, cantidad, unidad_consumo,
      costo_unitario_snapshot, orden
    )
    select
      p.id,
      'Material',
      v_id,
      '',
      1,
      coalesce(p_payload ->> 'unidad_medida', ''),
      coalesce((p_payload ->> 'costo_unitario')::numeric, 0),
      coalesce((
        select max(existing.orden) + 1
        from public.producto_componentes existing
        where existing.producto_id = p.id
      ), 0)
    from public.productos_servicios p
    where p.id = any(v_producto_ids)
      and p.empresa_id = v_empresa_id
      and not exists (
        select 1
        from public.producto_componentes existing
        where existing.producto_id = p.id
          and existing.material_id = v_id
      );
  end if;

  return v_id;
end;
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
  v_is_new boolean;
  v_limite_productos integer := -1;
  v_productos_actuales integer := 0;
begin
  perform public.app_require_company_access(v_empresa_id);

  select not exists(
    select 1
    from public.productos_servicios p
    where p.id = v_id
      and p.empresa_id = v_empresa_id
  )
  into v_is_new;

  if v_is_new then
    select p.limite_productos
    into v_limite_productos
    from public.suscripciones s
    join public.planes p on p.id = s.plan_id
    where s.empresa_id = v_empresa_id
    order by s.updated_at desc
    limit 1;

    if coalesce(v_limite_productos, -1) >= 0 then
      select count(*)::int into v_productos_actuales
      from public.productos_servicios
      where empresa_id = v_empresa_id;

      if v_productos_actuales >= v_limite_productos then
        raise exception 'Tu plan actual permite hasta % productos o servicios.', v_limite_productos;
      end if;
    end if;
  end if;

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
      coalesce((v_item ->> 'orden')::int, 0)
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
  v_line_tax_total numeric := 0;
  v_subtotal_tax_total numeric := 0;
  v_impuesto_total numeric := 0;
  v_ret_isr_base numeric := 0;
  v_ret_isr_total numeric := 0;
  v_total numeric := 0;
  v_folio text := btrim(coalesce(p_folio, ''));
  v_is_new boolean;
  v_limite_cotizaciones integer := -1;
  v_anchor date := current_date;
  v_window_start date;
  v_window_end date;
  v_cotizaciones_actuales integer := 0;
begin
  perform public.app_require_company_access(v_empresa_id);

  select not exists(
    select 1
    from public.cotizaciones c
    where c.id = v_id
      and c.empresa_id = v_empresa_id
  )
  into v_is_new;

  if v_is_new then
    select
      p.limite_cotizaciones_mensuales,
      coalesce(s.fecha_inicio::date, current_date)
    into v_limite_cotizaciones, v_anchor
    from public.suscripciones s
    join public.planes p on p.id = s.plan_id
    where s.empresa_id = v_empresa_id
    order by s.updated_at desc
    limit 1;

    if coalesce(v_limite_cotizaciones, -1) >= 0 then
      select window_start, window_end
      into v_window_start, v_window_end
      from public.app_current_monthly_anchor(v_anchor, current_date);

      select count(*)::int into v_cotizaciones_actuales
      from public.cotizaciones c
      where c.empresa_id = v_empresa_id
        and c.fecha_emision >= v_window_start
        and c.fecha_emision < v_window_end;

      if v_cotizaciones_actuales >= v_limite_cotizaciones then
        raise exception 'Tu plan actual permite hasta % cotizaciones por mes.', v_limite_cotizaciones;
      end if;
    end if;
  end if;

  if v_cliente_uuid is not null then
    if not exists (
      select 1
      from public.clientes c
      where c.id = v_cliente_uuid
        and c.empresa_id = v_empresa_id
    ) then
      v_cliente_uuid := null;
      v_cliente_snapshot := p_cliente_id;
    end if;
  else
    v_cliente_snapshot := p_cliente_id;
  end if;

  for v_linea in
    select *
    from jsonb_array_elements(coalesce(p_lineas, '[]'::jsonb))
  loop
    v_subtotal := v_subtotal + coalesce((v_linea ->> 'importe')::numeric, 0);
    v_line_tax_total := v_line_tax_total + (
      coalesce((v_linea ->> 'importe')::numeric, 0)
      * coalesce((v_linea ->> 'impuesto_porcentaje')::numeric, 0) / 100
    );
  end loop;

  v_ret_isr_base := greatest(v_subtotal - coalesce(p_descuento_valor, 0), 0);
  v_subtotal_tax_total :=
    v_ret_isr_base * greatest(coalesce(p_impuesto_porcentaje, 0), 0) / 100;
  v_impuesto_total := v_line_tax_total + v_subtotal_tax_total;

  if coalesce(p_ret_isr, false) then
    v_ret_isr_total := v_ret_isr_base * 0.10;
  end if;

  v_total := v_ret_isr_base + v_impuesto_total - v_ret_isr_total;

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
    saldo_total = excluded.total - coalesce(cotizaciones.pagado_total, 0),
    notas = excluded.notas,
    notas_privadas = excluded.notas_privadas,
    terminos = excluded.terminos,
    pie_pagina = excluded.pie_pagina,
    estatus = excluded.estatus,
    updated_at = timezone('utc', now());

  delete from public.cotizacion_detalles
  where cotizacion_id = v_id;

  insert into public.cotizacion_detalles (
    cotizacion_id, producto_servicio_id, concepto, descripcion,
    precio_unitario, unidad, descuento, cantidad, impuesto_porcentaje,
    importe, orden
  )
  select
    v_id,
    public.app_parse_uuid(line_item.value ->> 'producto_servicio_id'),
    coalesce(line_item.value ->> 'concepto', ''),
    coalesce(line_item.value ->> 'descripcion', ''),
    coalesce((line_item.value ->> 'precio_unitario')::numeric, 0),
    coalesce(line_item.value ->> 'unidad', ''),
    coalesce((line_item.value ->> 'descuento')::numeric, 0),
    coalesce((line_item.value ->> 'cantidad')::numeric, 0),
    coalesce((line_item.value ->> 'impuesto_porcentaje')::numeric, 0),
    coalesce((line_item.value ->> 'importe')::numeric, 0),
    coalesce((line_item.value ->> 'orden')::int, 0)
  from jsonb_array_elements(coalesce(p_lineas, '[]'::jsonb)) as line_item(value);

  return v_id;
end;
$$;

grant execute on function public.app_next_monthly_anchor(date) to authenticated;
grant execute on function public.app_current_monthly_anchor(date, date) to authenticated;
grant execute on function public.upsert_cliente(jsonb) to authenticated;
grant execute on function public.upsert_material(jsonb) to authenticated;
grant execute on function public.upsert_producto(
  uuid, text, text, text, numeric, numeric, boolean, text, numeric, numeric,
  text, text, text, text, text, text, boolean, jsonb, jsonb
) to authenticated;
grant execute on function public.upsert_cotizacion(
  uuid, text, timestamptz, timestamptz, numeric, text, text, text, numeric,
  numeric, boolean, text, text, text, text, text, jsonb
) to authenticated;
