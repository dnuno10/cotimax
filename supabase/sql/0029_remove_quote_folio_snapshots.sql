create or replace function public.delete_cotizacion(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select c.empresa_id
  into v_empresa_id
  from public.cotizaciones c
  where c.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.ingresos
  set cotizacion_id = null,
      updated_at = timezone('utc', now())
  where cotizacion_id = p_id;

  update public.ingresos_recurrentes
  set cotizacion_id = null,
      updated_at = timezone('utc', now())
  where cotizacion_id = p_id;

  update public.recordatorios
  set cotizacion_id = null,
      updated_at = timezone('utc', now())
  where cotizacion_id = p_id;

  delete from public.cotizacion_detalles
  where cotizacion_id = p_id;

  delete from public.cotizaciones
  where id = p_id;
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
  v_cliente_uuid uuid := public.app_parse_uuid(p_payload ->> 'cliente_id');
  v_cotizacion_uuid uuid := public.app_parse_uuid(p_payload ->> 'cotizacion_id');
  v_cliente_snapshot text := '';
  v_recurrente boolean := coalesce((p_payload ->> 'recurrente')::boolean, false);
  v_recurrente_id uuid;
  v_day int;
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_cliente_uuid is null then
    v_cliente_snapshot := coalesce(p_payload ->> 'cliente_id', '');
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
      icon_key, monto, metodo_pago, frecuencia,
      fecha_inicio, proxima_fecha, activo, notas
    )
    values (
      v_recurrente_id, v_empresa_id, v_cliente_uuid, v_cliente_snapshot,
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
  end if;

  insert into public.ingresos (
    id, empresa_id, cliente_id, cliente_nombre_snapshot, cotizacion_id,
    ingreso_recurrente_id, icon_key, monto,
    metodo_pago, fecha, referencia, notas
  )
  values (
    v_id, v_empresa_id, v_cliente_uuid, v_cliente_snapshot, v_cotizacion_uuid,
    v_recurrente_id, coalesce(p_payload ->> 'icon_key', 'wallet'),
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

alter table public.ingresos drop column if exists cotizacion_folio_snapshot;
alter table public.ingresos_recurrentes drop column if exists cotizacion_folio_snapshot;
alter table public.recordatorios drop column if exists cotizacion_folio_snapshot;

grant execute on function public.delete_cotizacion(uuid) to authenticated;
grant execute on function public.list_ingresos() to authenticated;
grant execute on function public.upsert_ingreso(jsonb) to authenticated;
grant execute on function public.process_recurrent_ingresos(date) to authenticated;
