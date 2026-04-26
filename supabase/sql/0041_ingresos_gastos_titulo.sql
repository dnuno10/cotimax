-- Agrega titulo a ingresos/gastos y actualiza RPCs para exponerlo.

alter table public.ingresos
  add column if not exists titulo text not null default '';

alter table public.gastos
  add column if not exists titulo text not null default '';

-- OJO: Al agregar columnas al RETURNS TABLE, Postgres no permite cambiar el
-- tipo de retorno con CREATE OR REPLACE. Hay que dropear primero.
drop function if exists public.list_ingresos();

create or replace function public.list_ingresos()
returns table (
  id uuid,
  titulo text,
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
    coalesce(i.titulo, '') as titulo,
    coalesce(i.ingreso_categoria_id::text, i.categoria_nombre_snapshot) as ingreso_categoria_id,
    coalesce(i.cliente_id::text, i.cliente_nombre_snapshot) as cliente_id,
    coalesce(i.cotizacion_id::text, '') as cotizacion_id,
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

create or replace function public.upsert_ingreso(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_titulo text := btrim(coalesce(p_payload ->> 'titulo', ''));
  v_categoria_uuid uuid := public.app_parse_uuid(p_payload ->> 'ingreso_categoria_id');
  v_categoria_snapshot text := '';
  v_cliente_uuid uuid := public.app_parse_uuid(p_payload ->> 'cliente_id');
  v_cotizacion_uuid uuid := public.app_parse_uuid(p_payload ->> 'cotizacion_id');
  v_gasto_fuente_uuid uuid := public.app_parse_uuid(p_payload ->> 'gasto_fuente_id');
  v_cliente_snapshot text := '';
  v_recurrente boolean := coalesce((p_payload ->> 'recurrente')::boolean, false);
  v_recurrente_id uuid;
  v_prev_recurrente_id uuid;
  v_day int;
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_categoria_uuid is null and coalesce(p_payload ->> 'ingreso_categoria_id', '') <> '' then
    select public.upsert_ingreso_categoria(
      p_payload ->> 'ingreso_categoria_id',
      ''
    ) into v_categoria_uuid;
  end if;

  if v_categoria_uuid is null then
    v_categoria_snapshot := coalesce(p_payload ->> 'ingreso_categoria_id', '');
  end if;

  if v_cliente_uuid is null then
    v_cliente_snapshot := coalesce(p_payload ->> 'cliente_id', '');
  end if;

  select ingreso_recurrente_id into v_prev_recurrente_id
  from public.ingresos
  where id = v_id;

  if v_recurrente then
    v_recurrente_id := coalesce(v_prev_recurrente_id, gen_random_uuid());

    insert into public.ingresos_recurrentes (
      id,
      empresa_id,
      ingreso_categoria_id,
      categoria_nombre_snapshot,
      cliente_id,
      cliente_nombre_snapshot,
      cotizacion_id,
      icon_key,
      monto,
      metodo_pago,
      frecuencia,
      fecha_inicio,
      proxima_fecha,
      activo,
      notas
    )
    values (
      v_recurrente_id,
      v_empresa_id,
      v_categoria_uuid,
      v_categoria_snapshot,
      v_cliente_uuid,
      v_cliente_snapshot,
      v_cotizacion_uuid,
      coalesce(p_payload ->> 'icon_key', 'wallet'),
      coalesce((p_payload ->> 'monto')::numeric, 0),
      coalesce(p_payload ->> 'metodo_pago', 'transferencia'),
      coalesce(p_payload ->> 'recurrencia', 'ninguna'),
      coalesce(
        (p_payload ->> 'fecha_inicio')::date,
        (p_payload ->> 'fecha')::date,
        current_date
      ),
      coalesce(
        (p_payload ->> 'fecha_inicio')::date,
        (p_payload ->> 'fecha')::date,
        current_date
      ),
      true,
      coalesce(p_payload ->> 'notas', '')
    )
    on conflict (id) do update set
      ingreso_categoria_id = excluded.ingreso_categoria_id,
      categoria_nombre_snapshot = excluded.categoria_nombre_snapshot,
      cliente_id = excluded.cliente_id,
      cliente_nombre_snapshot = excluded.cliente_nombre_snapshot,
      cotizacion_id = excluded.cotizacion_id,
      icon_key = excluded.icon_key,
      monto = excluded.monto,
      metodo_pago = excluded.metodo_pago,
      frecuencia = excluded.frecuencia,
      fecha_inicio = excluded.fecha_inicio,
      proxima_fecha = excluded.proxima_fecha,
      activo = true,
      notas = excluded.notas;

    delete from public.ingresos_recurrentes_dias
    where ingreso_recurrente_id = v_recurrente_id;

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
    if v_prev_recurrente_id is not null then
      update public.ingresos_recurrentes
      set activo = false
      where id = v_prev_recurrente_id
        and empresa_id = v_empresa_id;
    end if;
  end if;

  insert into public.ingresos (
    id,
    empresa_id,
    titulo,
    ingreso_categoria_id,
    categoria_nombre_snapshot,
    cliente_id,
    cliente_nombre_snapshot,
    cotizacion_id,
    ingreso_recurrente_id,
    icon_key,
    monto,
    metodo_pago,
    fecha,
    referencia,
    notas,
    gasto_fuente_id,
    gasto_fuente_nombre_snapshot
  )
  values (
    v_id,
    v_empresa_id,
    v_titulo,
    v_categoria_uuid,
    v_categoria_snapshot,
    v_cliente_uuid,
    v_cliente_snapshot,
    v_cotizacion_uuid,
    v_recurrente_id,
    coalesce(p_payload ->> 'icon_key', 'wallet'),
    coalesce((p_payload ->> 'monto')::numeric, 0),
    coalesce(p_payload ->> 'metodo_pago', 'transferencia'),
    coalesce((p_payload ->> 'fecha')::date, current_date),
    coalesce(p_payload ->> 'referencia', ''),
    coalesce(p_payload ->> 'notas', ''),
    v_gasto_fuente_uuid,
    coalesce(p_payload ->> 'gasto_fuente_nombre_snapshot', '')
  )
  on conflict (id) do update set
    titulo = excluded.titulo,
    ingreso_categoria_id = excluded.ingreso_categoria_id,
    categoria_nombre_snapshot = excluded.categoria_nombre_snapshot,
    cliente_id = excluded.cliente_id,
    cliente_nombre_snapshot = excluded.cliente_nombre_snapshot,
    cotizacion_id = excluded.cotizacion_id,
    ingreso_recurrente_id = excluded.ingreso_recurrente_id,
    icon_key = excluded.icon_key,
    monto = excluded.monto,
    metodo_pago = excluded.metodo_pago,
    fecha = excluded.fecha,
    referencia = excluded.referencia,
    notas = excluded.notas,
    gasto_fuente_id = excluded.gasto_fuente_id,
    gasto_fuente_nombre_snapshot = excluded.gasto_fuente_nombre_snapshot;

  return v_id;
end;
$$;

drop function if exists public.list_gastos();

create or replace function public.list_gastos()
returns table (
  id uuid,
  titulo text,
  gasto_categoria_id text,
  monto numeric,
  fecha date,
  fecha_inicio date,
  descripcion text,
  proveedor_id text,
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
    coalesce(g.titulo, '') as titulo,
    coalesce(g.gasto_categoria_id::text, g.categoria_nombre_snapshot) as gasto_categoria_id,
    g.monto,
    g.fecha,
    gr.fecha_inicio,
    g.descripcion,
    coalesce(g.proveedor_id::text, '') as proveedor_id,
    g.proveedor_nombre,
    g.referencia,
    g.notas,
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
    g.icon_key,
    g.created_at,
    g.updated_at
  from public.gastos g
  left join public.gastos_recurrentes gr on gr.id = g.gasto_recurrente_id
  where public.app_can_access_empresa(g.empresa_id)
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
  v_titulo text := btrim(coalesce(p_payload ->> 'titulo', ''));
  v_categoria_uuid uuid := public.app_parse_uuid(p_payload ->> 'gasto_categoria_id');
  v_categoria_snapshot text := '';
  v_proveedor_uuid uuid := public.app_parse_uuid(p_payload ->> 'proveedor_id');
  v_recurrente boolean := coalesce((p_payload ->> 'recurrente')::boolean, false);
  v_recurrente_id uuid;
  v_prev_recurrente_id uuid;
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

  select gasto_recurrente_id into v_prev_recurrente_id
  from public.gastos
  where id = v_id;

  if v_recurrente then
    v_recurrente_id := coalesce(v_prev_recurrente_id, gen_random_uuid());

    insert into public.gastos_recurrentes (
      id, empresa_id, gasto_categoria_id, categoria_nombre_snapshot, nombre,
      monto, frecuencia, fecha_inicio, proxima_fecha, activo, notas, icon_key
    )
    values (
      v_recurrente_id, v_empresa_id, v_categoria_uuid, v_categoria_snapshot,
      coalesce(nullif(v_titulo, ''), coalesce(p_payload ->> 'descripcion', '')),
      coalesce((p_payload ->> 'monto')::numeric, 0),
      coalesce(p_payload ->> 'recurrencia', 'ninguna'),
      coalesce(
        (p_payload ->> 'fecha_inicio')::date,
        (p_payload ->> 'fecha')::date,
        current_date
      ),
      coalesce(
        (p_payload ->> 'fecha_inicio')::date,
        (p_payload ->> 'fecha')::date,
        current_date
      ),
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

    delete from public.gastos_recurrentes_dias
    where gasto_recurrente_id = v_recurrente_id;
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
    if v_prev_recurrente_id is not null then
      update public.gastos_recurrentes
      set activo = false
      where id = v_prev_recurrente_id
        and empresa_id = v_empresa_id;
    end if;
  end if;

  insert into public.gastos (
    id,
    empresa_id,
    titulo,
    gasto_categoria_id,
    categoria_nombre_snapshot,
    gasto_recurrente_id,
    monto,
    fecha,
    proveedor_id,
    proveedor_nombre,
    referencia,
    descripcion,
    notas,
    icon_key
  )
  values (
    v_id,
    v_empresa_id,
    v_titulo,
    v_categoria_uuid,
    v_categoria_snapshot,
    v_recurrente_id,
    coalesce((p_payload ->> 'monto')::numeric, 0),
    coalesce((p_payload ->> 'fecha')::date, current_date),
    v_proveedor_uuid,
    coalesce(p_payload ->> 'proveedor_nombre', ''),
    coalesce(p_payload ->> 'referencia', ''),
    coalesce(p_payload ->> 'descripcion', ''),
    coalesce(p_payload ->> 'notas', ''),
    coalesce(p_payload ->> 'icon_key', 'shopping_cart')
  )
  on conflict (id) do update set
    titulo = excluded.titulo,
    gasto_categoria_id = excluded.gasto_categoria_id,
    categoria_nombre_snapshot = excluded.categoria_nombre_snapshot,
    gasto_recurrente_id = excluded.gasto_recurrente_id,
    monto = excluded.monto,
    fecha = excluded.fecha,
    proveedor_id = excluded.proveedor_id,
    proveedor_nombre = excluded.proveedor_nombre,
    referencia = excluded.referencia,
    descripcion = excluded.descripcion,
    notas = excluded.notas,
    icon_key = excluded.icon_key;

  return v_id;
end;
$$;

grant execute on function public.list_ingresos() to authenticated;
grant execute on function public.upsert_ingreso(jsonb) to authenticated;
grant execute on function public.list_gastos() to authenticated;
grant execute on function public.upsert_gasto(jsonb) to authenticated;
