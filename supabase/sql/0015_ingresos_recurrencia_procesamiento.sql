create or replace function public.app_next_ingreso_recurrencia_date(
  p_current date,
  p_frecuencia text,
  p_dias_semana int[] default '{}'
)
returns date
language plpgsql
immutable
as $$
declare
  v_today_isodow int := extract(isodow from p_current)::int;
  v_next_dow int;
begin
  case coalesce(p_frecuencia, 'ninguna')
    when 'cadaDia' then
      return p_current + 1;
    when 'diasDeLaSemana' then
      if coalesce(array_length(p_dias_semana, 1), 0) = 0 then
        return null;
      end if;

      select min(d)
      into v_next_dow
      from unnest(p_dias_semana) as d
      where d > v_today_isodow;

      if v_next_dow is not null then
        return p_current + (v_next_dow - v_today_isodow);
      end if;

      select min(d)
      into v_next_dow
      from unnest(p_dias_semana) as d;

      return p_current + ((7 - v_today_isodow) + v_next_dow);
    when 'finDeSemana' then
      if v_today_isodow = 6 then
        return p_current + 1;
      elsif v_today_isodow = 7 then
        return p_current + 6;
      elsif v_today_isodow < 6 then
        return p_current + (6 - v_today_isodow);
      end if;
    when 'cadaSemana' then
      return p_current + 7;
    when 'cadaDosSemanas' then
      return p_current + 14;
    when 'cadaCuatroSemanas' then
      return p_current + 28;
    when 'cadaMes' then
      return (p_current + interval '1 month')::date;
    when 'cadaDosMeses' then
      return (p_current + interval '2 month')::date;
    when 'cadaTresMeses' then
      return (p_current + interval '3 month')::date;
    when 'cadaCuatroMeses' then
      return (p_current + interval '4 month')::date;
    when 'cadaSeisMeses' then
      return (p_current + interval '6 month')::date;
    when 'cadaAnio' then
      return (p_current + interval '1 year')::date;
    else
      return null;
  end case;

  return null;
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
          and i.deleted_at is null
      )
      into v_exists;

      if not v_exists then
        insert into public.ingresos (
          id,
          empresa_id,
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
  v_prev_recurrente_id uuid;
  v_day int;
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_cliente_uuid is null then
    v_cliente_snapshot := coalesce(p_payload ->> 'cliente_id', '');
  end if;
  if v_cotizacion_uuid is null then
    v_cotizacion_snapshot := coalesce(p_payload ->> 'cotizacion_id', '');
  end if;

  select ingreso_recurrente_id into v_prev_recurrente_id
  from public.ingresos
  where id = v_id;

  if v_recurrente then
    v_recurrente_id := coalesce(v_prev_recurrente_id, gen_random_uuid());

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
    if v_prev_recurrente_id is not null then
      update public.ingresos_recurrentes
      set activo = false
      where id = v_prev_recurrente_id
        and empresa_id = v_empresa_id;
    end if;
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

grant execute on function public.process_recurrent_ingresos(date) to authenticated;
