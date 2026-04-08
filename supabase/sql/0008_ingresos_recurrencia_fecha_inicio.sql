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
    ir.fecha_inicio,
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
