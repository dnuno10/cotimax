drop function if exists public.list_clientes(text);
drop function if exists public.list_materiales(text);
drop function if exists public.list_productos(text);
drop function if exists public.list_cotizaciones(text);
drop function if exists public.list_ingresos();
drop function if exists public.list_gastos();

create function public.list_clientes(p_query text default '')
returns table (
  id uuid,
  empresa_id uuid,
  nombre text,
  empresa text,
  contacto text,
  numero text,
  id_number text,
  rfc_cif_nif text,
  sitio_web text,
  telefono text,
  correo text,
  direccion text,
  routing_number text,
  iva_valido boolean,
  exento_impuestos boolean,
  activo boolean,
  notas text,
  created_at timestamptz,
  updated_at timestamptz,
  calle text,
  apartamento_suite text,
  ciudad text,
  estado_provincia text,
  codigo_postal text,
  pais text
)
language sql
security definer
set search_path = public
as $$
  select
    c.id,
    c.empresa_id,
    c.nombre,
    c.empresa,
    c.contacto,
    c.numero,
    c.id_number,
    c.rfc_cif_nif,
    c.sitio_web,
    c.telefono,
    c.correo,
    coalesce(
      nullif(c.direccion, ''),
      concat_ws(
        ', ',
        nullif(d.calle, ''),
        nullif(d.apartamento_suite, ''),
        nullif(d.ciudad, ''),
        nullif(d.estado_provincia, ''),
        nullif(d.codigo_postal, ''),
        nullif(d.pais, '')
      )
    ) as direccion,
    c.routing_number,
    c.iva_valido,
    c.exento_impuestos,
    c.activo,
    c.notas,
    c.created_at,
    c.updated_at,
    coalesce(d.calle, '') as calle,
    coalesce(d.apartamento_suite, '') as apartamento_suite,
    coalesce(d.ciudad, '') as ciudad,
    coalesce(d.estado_provincia, '') as estado_provincia,
    coalesce(d.codigo_postal, '') as codigo_postal,
    coalesce(d.pais, '') as pais
  from public.clientes c
  left join lateral (
    select
      cd.calle,
      cd.apartamento_suite,
      cd.ciudad,
      cd.estado_provincia,
      cd.codigo_postal,
      cd.pais
    from public.cliente_direcciones cd
    where cd.cliente_id = c.id
    order by cd.es_principal desc, cd.updated_at desc, cd.created_at desc
    limit 1
  ) d on true
  where public.app_can_access_empresa(c.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(c.nombre) like '%' || lower(p_query) || '%'
      or lower(c.empresa) like '%' || lower(p_query) || '%'
      or lower(c.rfc_cif_nif) like '%' || lower(p_query) || '%'
    )
  order by c.updated_at desc;
$$;

create or replace function public.list_proveedores(p_query text default '')
returns setof public.proveedores
language sql
security definer
set search_path = public
as $$
  select p.*
  from public.proveedores p
  where public.app_can_access_empresa(p.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(p.nombre) like '%' || lower(p_query) || '%'
      or lower(p.empresa) like '%' || lower(p_query) || '%'
      or lower(p.rfc_cif_nif) like '%' || lower(p_query) || '%'
    )
  order by p.updated_at desc;
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
  proveedor_id uuid,
  proveedor_nombre text,
  sku text,
  producto_ids text[],
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
    m.costo_unitario, m.stock_disponible, m.proveedor_id, m.proveedor_nombre,
    m.sku,
    coalesce(
      array_agg(distinct p.id::text) filter (where p.id is not null),
      '{}'::text[]
    ) as producto_ids,
    m.activo,
    m.created_at, m.updated_at
  from public.materiales_insumos m
  left join public.producto_componentes pc on pc.material_id = m.id
  left join public.productos_servicios p
    on p.id = pc.producto_id
    and public.app_can_access_empresa(p.empresa_id)
  where public.app_can_access_empresa(m.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(m.nombre) like '%' || lower(p_query) || '%'
      or lower(m.sku) like '%' || lower(p_query) || '%'
      or lower(m.proveedor_nombre) like '%' || lower(p_query) || '%'
    )
  group by
    m.id, m.nombre, m.descripcion, m.tipo_nombre, m.unidad_medida,
    m.costo_unitario, m.stock_disponible, m.proveedor_id, m.proveedor_nombre,
    m.sku, m.activo, m.created_at, m.updated_at
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
  v_producto_ids uuid[] := '{}'::uuid[];
  v_sync_producto_ids boolean := coalesce(
    nullif(p_payload ->> 'sync_producto_ids', '')::boolean,
    false
  );
begin
  perform public.app_require_company_access(v_empresa_id);

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
  where public.app_can_access_empresa(p.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(p.nombre) like '%' || lower(p_query) || '%'
      or lower(p.sku) like '%' || lower(p_query) || '%'
      or lower(coalesce(cp.nombre, p.categoria_nombre_snapshot)) like '%' || lower(p_query) || '%'
    )
  order by p.updated_at desc;
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
  pagado_total numeric,
  saldo_total numeric,
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
    c.id,
    c.folio,
    coalesce(c.cliente_id::text, c.cliente_nombre_snapshot) as cliente_id,
    c.fecha_emision,
    c.fecha_vencimiento,
    c.impuesto_porcentaje,
    c.ret_isr,
    c.subtotal,
    c.descuento_total,
    c.impuesto_total,
    c.total,
    c.pagado_total,
    c.saldo_total,
    c.notas,
    c.notas_privadas,
    c.terminos,
    c.pie_pagina,
    c.estatus,
    c.usuario_id,
    c.empresa_id,
    c.created_at,
    c.updated_at
  from public.cotizaciones c
  where public.app_can_access_empresa(c.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(c.folio) like '%' || lower(p_query) || '%'
      or lower(c.cliente_nombre_snapshot) like '%' || lower(p_query) || '%'
    )
  order by c.updated_at desc;
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
  select empresa_id into v_empresa_id
  from public.cotizaciones
  where id = p_id;

  if v_empresa_id is null then
    raise exception 'Cotización no encontrada';
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.cotizaciones
  set estatus = p_status,
      updated_at = timezone('utc', now())
  where id = p_id;

  if coalesce(p_status, '') <> 'pagada' then
    delete from public.ingresos
    where empresa_id = v_empresa_id
      and cotizacion_id = p_id;
  end if;
end;
$$;

create or replace function public.mark_cotizacion_pagada(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id
  from public.cotizaciones
  where id = p_id;

  if v_empresa_id is null then
    raise exception 'Cotización no encontrada';
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.cotizaciones
  set pagado_total = total,
      saldo_total = 0,
      estatus = 'pagada',
      updated_at = timezone('utc', now())
  where id = p_id;
end;
$$;

create or replace function public.desmarcar_cotizacion_pagada(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id
  from public.cotizaciones
  where id = p_id;

  if v_empresa_id is null then
    raise exception 'Cotización no encontrada';
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.cotizaciones
  set pagado_total = 0,
      saldo_total = total,
      estatus = 'aprobada',
      updated_at = timezone('utc', now())
  where id = p_id;

  delete from public.ingresos
  where empresa_id = v_empresa_id
    and cotizacion_id = p_id;
end;
$$;

create or replace function public.list_ingresos()
returns table (
  id uuid,
  ingreso_categoria_id text,
  cliente_id text,
  cotizacion_id text,
  gasto_fuente_id text,
  gasto_fuente_nombre text,
  monto numeric,
  metodo_pago text,
  fecha date,
  referencia text,
  notas text,
  recurrente boolean,
  recurrencia text,
  dias_semana int[],
  fecha_inicio date,
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
    coalesce(i.ingreso_categoria_id::text, i.categoria_nombre_snapshot) as ingreso_categoria_id,
    coalesce(i.cliente_id::text, i.cliente_nombre_snapshot) as cliente_id,
    coalesce(i.cotizacion_id::text, i.cotizacion_folio_snapshot) as cotizacion_id,
    coalesce(i.gasto_fuente_id::text, '') as gasto_fuente_id,
    coalesce(i.gasto_fuente_nombre_snapshot, '') as gasto_fuente_nombre,
    i.monto,
    i.metodo_pago,
    i.fecha,
    i.referencia,
    i.notas,
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
    ir.fecha_inicio,
    i.icon_key,
    i.created_at,
    i.updated_at
  from public.ingresos i
  left join public.ingresos_recurrentes ir on ir.id = i.ingreso_recurrente_id
  where public.app_can_access_empresa(i.empresa_id)
  order by i.fecha desc, i.updated_at desc;
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
  where public.app_can_access_empresa(g.empresa_id)
  order by g.fecha desc, g.updated_at desc;
$$;

create or replace function public.process_recurrent_ingresos(
  p_until date default current_date
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_until date := coalesce(p_until, current_date);
  v_created_count integer := 0;
  v_exists boolean;
  v_weekdays int[];
  v_next_date date;
  r record;
begin
  perform public.app_require_company_access(v_empresa_id);

  for r in
    select
      ir.id,
      ir.empresa_id,
      ir.ingreso_categoria_id,
      ir.categoria_nombre_snapshot,
      ir.cliente_id,
      ir.cliente_nombre_snapshot,
      ir.cotizacion_id,
      ir.cotizacion_folio_snapshot,
      ir.icon_key,
      ir.monto,
      ir.metodo_pago,
      ir.frecuencia,
      ir.fecha_inicio,
      ir.fecha_fin,
      ir.proxima_fecha,
      ir.activo,
      ir.notas,
      coalesce(
        (
          select array_agg(ird.weekday_iso order by ird.weekday_iso)
          from public.ingresos_recurrentes_dias ird
          where ird.ingreso_recurrente_id = ir.id
        ),
        '{}'::int[]
      ) as dias_semana
    from public.ingresos_recurrentes ir
    where ir.empresa_id = v_empresa_id
      and ir.activo
      and coalesce(ir.frecuencia, 'ninguna') <> 'ninguna'
    order by ir.proxima_fecha asc
  loop
    v_weekdays := r.dias_semana;

    while r.proxima_fecha <= v_until
      and (r.fecha_fin is null or r.proxima_fecha <= r.fecha_fin)
    loop
      select exists(
        select 1
        from public.ingresos i
        where i.empresa_id = r.empresa_id
          and i.ingreso_recurrente_id = r.id
          and i.fecha = r.proxima_fecha
      )
      into v_exists;

      if not v_exists then
        insert into public.ingresos (
          id,
          empresa_id,
          ingreso_categoria_id,
          categoria_nombre_snapshot,
          cliente_id,
          cliente_nombre_snapshot,
          cotizacion_id,
          cotizacion_folio_snapshot,
          ingreso_recurrente_id,
          icon_key,
          monto,
          metodo_pago,
          fecha,
          referencia,
          notas
        )
        values (
          gen_random_uuid(),
          r.empresa_id,
          r.ingreso_categoria_id,
          r.categoria_nombre_snapshot,
          r.cliente_id,
          r.cliente_nombre_snapshot,
          r.cotizacion_id,
          r.cotizacion_folio_snapshot,
          r.id,
          r.icon_key,
          r.monto,
          r.metodo_pago,
          r.proxima_fecha,
          '',
          r.notas
        );
        v_created_count := v_created_count + 1;
      end if;

      v_next_date := public.app_next_ingreso_recurrencia_date(
        r.proxima_fecha,
        r.frecuencia,
        v_weekdays
      );

      if v_next_date is null or v_next_date <= r.proxima_fecha then
        update public.ingresos_recurrentes
        set activo = false
        where id = r.id;
        exit;
      end if;

      update public.ingresos_recurrentes
      set proxima_fecha = v_next_date
      where id = r.id;

      r.proxima_fecha := v_next_date;
    end loop;
  end loop;

  return v_created_count;
end;
$$;

create or replace function public.process_recurrent_gastos(
  p_until date default current_date
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_until date := coalesce(p_until, current_date);
  v_created_count integer := 0;
  v_exists boolean;
  v_weekdays int[];
  v_next_date date;
  r record;
begin
  perform public.app_require_company_access(v_empresa_id);

  for r in
    select
      gr.id,
      gr.empresa_id,
      gr.gasto_categoria_id,
      gr.categoria_nombre_snapshot,
      gr.nombre,
      gr.monto,
      gr.frecuencia,
      gr.fecha_inicio,
      gr.fecha_fin,
      gr.proxima_fecha,
      gr.activo,
      gr.notas,
      gr.icon_key,
      coalesce(
        (
          select array_agg(grd.weekday_iso order by grd.weekday_iso)
          from public.gastos_recurrentes_dias grd
          where grd.gasto_recurrente_id = gr.id
        ),
        '{}'::int[]
      ) as dias_semana
    from public.gastos_recurrentes gr
    where gr.empresa_id = v_empresa_id
      and gr.activo
      and coalesce(gr.frecuencia, 'ninguna') <> 'ninguna'
    order by gr.proxima_fecha asc
  loop
    v_weekdays := r.dias_semana;

    while r.proxima_fecha <= v_until
      and (r.fecha_fin is null or r.proxima_fecha <= r.fecha_fin)
    loop
      select exists(
        select 1
        from public.gastos g
        where g.empresa_id = r.empresa_id
          and g.gasto_recurrente_id = r.id
          and g.fecha = r.proxima_fecha
      )
      into v_exists;

      if not v_exists then
        insert into public.gastos (
          id,
          empresa_id,
          gasto_categoria_id,
          categoria_nombre_snapshot,
          gasto_recurrente_id,
          monto,
          fecha,
          proveedor_nombre,
          referencia,
          descripcion,
          notas,
          icon_key
        )
        values (
          gen_random_uuid(),
          r.empresa_id,
          r.gasto_categoria_id,
          r.categoria_nombre_snapshot,
          r.id,
          r.monto,
          r.proxima_fecha,
          '',
          '',
          r.nombre,
          r.notas,
          r.icon_key
        );
        v_created_count := v_created_count + 1;
      end if;

      v_next_date := public.app_next_gasto_recurrencia_date(
        r.proxima_fecha,
        r.frecuencia,
        v_weekdays
      );

      if v_next_date is null or v_next_date <= r.proxima_fecha then
        update public.gastos_recurrentes
        set activo = false
        where id = r.id;
        exit;
      end if;

      update public.gastos_recurrentes
      set proxima_fecha = v_next_date
      where id = r.id;

      r.proxima_fecha := v_next_date;
    end loop;
  end loop;

  return v_created_count;
end;
$$;

create or replace function public.list_delete_dependencies(
  p_entity_type text,
  p_ids uuid[]
)
returns table (
  dependency_key text,
  dependency_label text,
  dependency_count bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(array_length(p_ids, 1), 0) = 0 then
    return;
  end if;

  if p_entity_type = 'cotizacion' then
    return query
    with target_ids as (
      select c.id
      from public.cotizaciones c
      where c.id = any(p_ids)
        and public.app_can_access_empresa(c.empresa_id)
    )
    select * from (
      select 'recordatorios'::text, 'recordatorios relacionados'::text, count(*)::bigint as dependency_count
      from public.recordatorios r
      where r.cotizacion_id in (select id from target_ids)
      union all
      select 'ingresos'::text, 'ingresos relacionados'::text, count(*)::bigint as dependency_count
      from public.ingresos i
      where i.cotizacion_id in (select id from target_ids)
      union all
      select 'ingresos_recurrentes'::text, 'ingresos recurrentes relacionados'::text, count(*)::bigint as dependency_count
      from public.ingresos_recurrentes ir
      where ir.cotizacion_id in (select id from target_ids)
    ) dependency_rows
    where dependency_rows.dependency_count > 0;
    return;
  end if;

  if p_entity_type = 'cliente' then
    return query
    with target_ids as (
      select c.id
      from public.clientes c
      where c.id = any(p_ids)
        and public.app_can_access_empresa(c.empresa_id)
    )
    select * from (
      select 'cotizaciones'::text, 'cotizaciones relacionadas'::text, count(*)::bigint as dependency_count
      from public.cotizaciones c
      where c.cliente_id in (select id from target_ids)
      union all
      select 'ingresos'::text, 'ingresos relacionados'::text, count(*)::bigint as dependency_count
      from public.ingresos i
      where i.cliente_id in (select id from target_ids)
      union all
      select 'ingresos_recurrentes'::text, 'ingresos recurrentes relacionados'::text, count(*)::bigint as dependency_count
      from public.ingresos_recurrentes ir
      where ir.cliente_id in (select id from target_ids)
      union all
      select 'recordatorios'::text, 'recordatorios relacionados'::text, count(*)::bigint as dependency_count
      from public.recordatorios r
      where r.cliente_id in (select id from target_ids)
    ) dependency_rows
    where dependency_rows.dependency_count > 0;
    return;
  end if;

  if p_entity_type = 'proveedor' then
    return query
    with target_ids as (
      select p.id
      from public.proveedores p
      where p.id = any(p_ids)
        and public.app_can_access_empresa(p.empresa_id)
    )
    select * from (
      select 'gastos'::text, 'gastos relacionados'::text, count(*)::bigint as dependency_count
      from public.gastos g
      where g.proveedor_id in (select id from target_ids)
      union all
      select 'materiales'::text, 'materiales relacionados'::text, count(*)::bigint as dependency_count
      from public.materiales_insumos m
      where m.proveedor_id in (select id from target_ids)
    ) dependency_rows
    where dependency_rows.dependency_count > 0;
    return;
  end if;

  if p_entity_type = 'producto' then
    return query
    with target_ids as (
      select p.id
      from public.productos_servicios p
      where p.id = any(p_ids)
        and public.app_can_access_empresa(p.empresa_id)
    )
    select * from (
      select 'cotizacion_detalles'::text, 'lineas de cotizacion relacionadas'::text, count(*)::bigint as dependency_count
      from public.cotizacion_detalles cd
      where cd.producto_servicio_id in (select id from target_ids)
    ) dependency_rows
    where dependency_rows.dependency_count > 0;
    return;
  end if;

  if p_entity_type = 'material' then
    return query
    with target_ids as (
      select m.id
      from public.materiales_insumos m
      where m.id = any(p_ids)
        and public.app_can_access_empresa(m.empresa_id)
    )
    select * from (
      select 'producto_componentes'::text, 'componentes de producto relacionados'::text, count(*)::bigint as dependency_count
      from public.producto_componentes pc
      where pc.material_id in (select id from target_ids)
    ) dependency_rows
    where dependency_rows.dependency_count > 0;
    return;
  end if;

  if p_entity_type = 'gasto' then
    return query
    with target_ids as (
      select g.id
      from public.gastos g
      where g.id = any(p_ids)
        and public.app_can_access_empresa(g.empresa_id)
    )
    select * from (
      select 'ingresos'::text, 'ingresos relacionados'::text, count(*)::bigint as dependency_count
      from public.ingresos i
      where i.gasto_fuente_id in (select id from target_ids)
    ) dependency_rows
    where dependency_rows.dependency_count > 0;
    return;
  end if;
end;
$$;

do $$
begin
  with soft_quotes as (
    select id, coalesce(folio, '') as folio
    from public.cotizaciones
    where deleted_at is not null
  )
  update public.ingresos i
  set cotizacion_id = null,
      cotizacion_folio_snapshot = coalesce(nullif(i.cotizacion_folio_snapshot, ''), sq.folio),
      updated_at = timezone('utc', now())
  from soft_quotes sq
  where i.cotizacion_id = sq.id;

  with soft_quotes as (
    select id, coalesce(folio, '') as folio
    from public.cotizaciones
    where deleted_at is not null
  )
  update public.ingresos_recurrentes ir
  set cotizacion_id = null,
      cotizacion_folio_snapshot = coalesce(nullif(ir.cotizacion_folio_snapshot, ''), sq.folio),
      updated_at = timezone('utc', now())
  from soft_quotes sq
  where ir.cotizacion_id = sq.id;

  with soft_quotes as (
    select id, coalesce(folio, '') as folio
    from public.cotizaciones
    where deleted_at is not null
  )
  update public.recordatorios r
  set cotizacion_id = null,
      cotizacion_folio_snapshot = coalesce(nullif(r.cotizacion_folio_snapshot, ''), sq.folio),
      updated_at = timezone('utc', now())
  from soft_quotes sq
  where r.cotizacion_id = sq.id;

  delete from public.cotizacion_detalles
  where cotizacion_id in (
    select id from public.cotizaciones where deleted_at is not null
  );

  delete from public.cotizaciones
  where deleted_at is not null;

  with soft_gastos as (
    select
      id,
      coalesce(nullif(descripcion, ''), nullif(referencia, ''), 'Gasto eliminado') as label
    from public.gastos
    where deleted_at is not null
  )
  update public.ingresos i
  set gasto_fuente_id = null,
      gasto_fuente_nombre_snapshot = coalesce(nullif(i.gasto_fuente_nombre_snapshot, ''), sg.label),
      updated_at = timezone('utc', now())
  from soft_gastos sg
  where i.gasto_fuente_id = sg.id;

  delete from public.gastos
  where deleted_at is not null;

  delete from public.ingresos
  where deleted_at is not null;

  with soft_products as (
    select id, coalesce(nullif(nombre, ''), 'Producto eliminado') as label
    from public.productos_servicios
    where deleted_at is not null
  )
  update public.cotizacion_detalles cd
  set producto_servicio_id = null,
      concepto = coalesce(nullif(cd.concepto, ''), sp.label),
      updated_at = timezone('utc', now())
  from soft_products sp
  where cd.producto_servicio_id = sp.id;

  delete from public.producto_precios_rango
  where producto_id in (
    select id from public.productos_servicios where deleted_at is not null
  );

  delete from public.producto_componentes
  where producto_id in (
    select id from public.productos_servicios where deleted_at is not null
  );

  delete from public.productos_servicios
  where deleted_at is not null;

  with soft_materials as (
    select id, coalesce(nullif(nombre, ''), 'Material eliminado') as label
    from public.materiales_insumos
    where deleted_at is not null
  )
  update public.producto_componentes pc
  set material_id = null,
      nombre_libre = coalesce(nullif(pc.nombre_libre, ''), sm.label),
      updated_at = timezone('utc', now())
  from soft_materials sm
  where pc.material_id = sm.id;

  delete from public.materiales_insumos
  where deleted_at is not null;

  with soft_providers as (
    select
      id,
      coalesce(nullif(nombre, ''), nullif(empresa, ''), 'Proveedor eliminado') as label
    from public.proveedores
    where deleted_at is not null
  )
  update public.gastos g
  set proveedor_id = null,
      proveedor_nombre = coalesce(nullif(g.proveedor_nombre, ''), sp.label),
      updated_at = timezone('utc', now())
  from soft_providers sp
  where g.proveedor_id = sp.id;

  with soft_providers as (
    select
      id,
      coalesce(nullif(nombre, ''), nullif(empresa, ''), 'Proveedor eliminado') as label
    from public.proveedores
    where deleted_at is not null
  )
  update public.materiales_insumos m
  set proveedor_id = null,
      proveedor_nombre = coalesce(nullif(m.proveedor_nombre, ''), sp.label),
      updated_at = timezone('utc', now())
  from soft_providers sp
  where m.proveedor_id = sp.id;

  delete from public.proveedor_contactos
  where proveedor_id in (
    select id from public.proveedores where deleted_at is not null
  );

  delete from public.proveedor_direcciones
  where proveedor_id in (
    select id from public.proveedores where deleted_at is not null
  );

  delete from public.proveedores
  where deleted_at is not null;

  with soft_clients as (
    select
      id,
      coalesce(nullif(nombre, ''), nullif(empresa, ''), 'Cliente eliminado') as label
    from public.clientes
    where deleted_at is not null
  )
  update public.cotizaciones c
  set cliente_id = null,
      cliente_nombre_snapshot = coalesce(nullif(c.cliente_nombre_snapshot, ''), sc.label),
      updated_at = timezone('utc', now())
  from soft_clients sc
  where c.cliente_id = sc.id;

  with soft_clients as (
    select
      id,
      coalesce(nullif(nombre, ''), nullif(empresa, ''), 'Cliente eliminado') as label
    from public.clientes
    where deleted_at is not null
  )
  update public.ingresos i
  set cliente_id = null,
      cliente_nombre_snapshot = coalesce(nullif(i.cliente_nombre_snapshot, ''), sc.label),
      updated_at = timezone('utc', now())
  from soft_clients sc
  where i.cliente_id = sc.id;

  with soft_clients as (
    select
      id,
      coalesce(nullif(nombre, ''), nullif(empresa, ''), 'Cliente eliminado') as label
    from public.clientes
    where deleted_at is not null
  )
  update public.ingresos_recurrentes ir
  set cliente_id = null,
      cliente_nombre_snapshot = coalesce(nullif(ir.cliente_nombre_snapshot, ''), sc.label),
      updated_at = timezone('utc', now())
  from soft_clients sc
  where ir.cliente_id = sc.id;

  with soft_clients as (
    select
      id,
      coalesce(nullif(nombre, ''), nullif(empresa, ''), 'Cliente eliminado') as label
    from public.clientes
    where deleted_at is not null
  )
  update public.recordatorios r
  set cliente_id = null,
      cliente_nombre_snapshot = coalesce(nullif(r.cliente_nombre_snapshot, ''), sc.label),
      updated_at = timezone('utc', now())
  from soft_clients sc
  where r.cliente_id = sc.id;

  delete from public.cliente_contactos
  where cliente_id in (
    select id from public.clientes where deleted_at is not null
  );

  delete from public.cliente_direcciones
  where cliente_id in (
    select id from public.clientes where deleted_at is not null
  );

  delete from public.cliente_configuracion
  where cliente_id in (
    select id from public.clientes where deleted_at is not null
  );

  delete from public.cliente_clasificacion
  where cliente_id in (
    select id from public.clientes where deleted_at is not null
  );

  delete from public.clientes
  where deleted_at is not null;

  delete from public.recordatorios
  where deleted_at is not null;
end;
$$;

drop index if exists public.recordatorios_empresa_deleted_idx;
drop index if exists public.ingresos_unique_cotizacion_idx;

create unique index if not exists ingresos_unique_cotizacion_idx
  on public.ingresos (empresa_id, cotizacion_id)
  where cotizacion_id is not null;

alter table public.empresas drop column if exists deleted_at;
alter table public.usuarios drop column if exists deleted_at;
alter table public.clientes drop column if exists deleted_at;
alter table public.proveedores drop column if exists deleted_at;
alter table public.materiales_insumos drop column if exists deleted_at;
alter table public.productos_servicios drop column if exists deleted_at;
alter table public.cotizaciones drop column if exists deleted_at;
alter table public.ingresos drop column if exists deleted_at;
alter table public.gastos drop column if exists deleted_at;
alter table public.recordatorios drop column if exists deleted_at;

grant execute on function public.list_clientes(text) to authenticated;
grant execute on function public.list_proveedores(text) to authenticated;
grant execute on function public.list_materiales(text) to authenticated;
grant execute on function public.upsert_material(jsonb) to authenticated;
grant execute on function public.list_productos(text) to authenticated;
grant execute on function public.list_cotizaciones(text) to authenticated;
grant execute on function public.update_cotizacion_status(uuid, text) to authenticated;
grant execute on function public.mark_cotizacion_pagada(uuid) to authenticated;
grant execute on function public.desmarcar_cotizacion_pagada(uuid) to authenticated;
grant execute on function public.list_ingresos() to authenticated;
grant execute on function public.list_gastos() to authenticated;
grant execute on function public.process_recurrent_ingresos(date) to authenticated;
grant execute on function public.process_recurrent_gastos(date) to authenticated;
grant execute on function public.list_delete_dependencies(text, uuid[]) to authenticated;
