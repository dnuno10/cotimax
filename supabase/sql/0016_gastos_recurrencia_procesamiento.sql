create or replace function public.app_next_gasto_recurrencia_date(
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
          and g.deleted_at is null
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
    if v_prev_recurrente_id is not null then
      update public.gastos_recurrentes
      set activo = false
      where id = v_prev_recurrente_id
        and empresa_id = v_empresa_id;
    end if;
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

grant execute on function public.process_recurrent_gastos(date) to authenticated;
