drop function if exists public.list_gastos();

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
    g.id,
    coalesce(g.gasto_categoria_id::text, g.categoria_nombre_snapshot) as gasto_categoria_id,
    g.monto,
    g.fecha,
    g.descripcion,
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
    gr.fecha_inicio,
    g.icon_key,
    g.created_at,
    g.updated_at
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

grant execute on function public.list_gastos() to authenticated;
grant execute on function public.upsert_gasto(jsonb) to authenticated;
