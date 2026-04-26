create or replace function public.list_recordatorios()
returns table (
  id uuid,
  cliente_id text,
  cliente_nombre_snapshot text,
  cotizacion_id text,
  nombre text,
  descripcion text,
  fecha date,
  fecha_inicio date,
  fecha_fin date,
  frecuencia text,
  activo boolean,
  icon_key text,
  dias_semana int[],
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    r.id,
    coalesce(r.cliente_id::text, '') as cliente_id,
    coalesce(r.cliente_nombre_snapshot, '') as cliente_nombre_snapshot,
    coalesce(r.cotizacion_id::text, '') as cotizacion_id,
    r.nombre,
    r.descripcion,
    r.fecha,
    r.fecha_inicio,
    r.fecha_fin,
    r.frecuencia,
    r.activo,
    r.icon_key,
    coalesce(
      (
        select array_agg(rd.weekday_iso order by rd.weekday_iso)
        from public.recordatorios_dias rd
        where rd.recordatorio_id = r.id
      ),
      '{}'::int[]
    ) as dias_semana,
    r.created_at,
    r.updated_at
  from public.recordatorios r
  where public.app_can_access_empresa(r.empresa_id)
  order by r.fecha asc, r.created_at asc;
$$;

create or replace function public.upsert_recordatorio(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_default_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_existing_empresa_id uuid;
  v_empresa_id uuid;
  v_cliente_uuid uuid := public.app_parse_uuid(p_payload ->> 'cliente_id');
  v_cotizacion_uuid uuid := public.app_parse_uuid(p_payload ->> 'cotizacion_id');
  v_cliente_snapshot text := coalesce(p_payload ->> 'cliente_nombre_snapshot', '');
  v_nombre text := coalesce(p_payload ->> 'nombre', '');
  v_descripcion text := coalesce(p_payload ->> 'descripcion', '');
  v_fecha date := coalesce((p_payload ->> 'fecha')::date, current_date);
  v_fecha_inicio date := coalesce((p_payload ->> 'fecha_inicio')::date, v_fecha);
  v_fecha_fin date := nullif(p_payload ->> 'fecha_fin', '')::date;
  v_frecuencia text := coalesce(nullif(p_payload ->> 'frecuencia', ''), 'ninguna');
  v_activo boolean := coalesce((p_payload ->> 'activo')::boolean, true);
  v_icon_key text := coalesce(nullif(p_payload ->> 'icon_key', ''), 'calendar_month');
  v_weekdays int[] := '{}'::int[];
  v_day int;
begin
  select r.empresa_id
  into v_existing_empresa_id
  from public.recordatorios r
  where r.id = v_id;

  v_empresa_id := coalesce(v_existing_empresa_id, v_default_empresa_id);
  perform public.app_require_company_access(v_empresa_id);

  select coalesce(array_agg(distinct day_val order by day_val), '{}'::int[])
  into v_weekdays
  from (
    select value::int as day_val
    from jsonb_array_elements_text(coalesce(p_payload -> 'dias_semana', '[]'::jsonb)) t(value)
    where value ~ '^[0-9]+$'
      and value::int between 1 and 7
  ) days;

  insert into public.recordatorios (
    id,
    empresa_id,
    cliente_id,
    cliente_nombre_snapshot,
    cotizacion_id,
    nombre,
    descripcion,
    fecha,
    fecha_inicio,
    fecha_fin,
    frecuencia,
    activo,
    icon_key
  )
  values (
    v_id,
    v_empresa_id,
    v_cliente_uuid,
    v_cliente_snapshot,
    v_cotizacion_uuid,
    v_nombre,
    v_descripcion,
    v_fecha,
    v_fecha_inicio,
    v_fecha_fin,
    v_frecuencia,
    v_activo,
    v_icon_key
  )
  on conflict (id) do update
  set
    cliente_id = excluded.cliente_id,
    cliente_nombre_snapshot = excluded.cliente_nombre_snapshot,
    cotizacion_id = excluded.cotizacion_id,
    nombre = excluded.nombre,
    descripcion = excluded.descripcion,
    fecha = excluded.fecha,
    fecha_inicio = excluded.fecha_inicio,
    fecha_fin = excluded.fecha_fin,
    frecuencia = excluded.frecuencia,
    activo = excluded.activo,
    icon_key = excluded.icon_key,
    updated_at = timezone('utc', now());

  delete from public.recordatorios_dias
  where recordatorio_id = v_id;

  foreach v_day in array v_weekdays loop
    insert into public.recordatorios_dias (recordatorio_id, weekday_iso)
    values (v_id, v_day)
    on conflict do nothing;
  end loop;

  return v_id;
end;
$$;

create or replace function public.delete_recordatorio(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select r.empresa_id
  into v_empresa_id
  from public.recordatorios r
  where r.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);

  delete from public.recordatorios
  where id = p_id;
end;
$$;

grant execute on function public.list_recordatorios() to authenticated;
grant execute on function public.upsert_recordatorio(jsonb) to authenticated;
grant execute on function public.delete_recordatorio(uuid) to authenticated;

