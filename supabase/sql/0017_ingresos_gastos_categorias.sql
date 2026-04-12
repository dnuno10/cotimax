create table if not exists public.ingreso_categorias (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  nombre text not null,
  descripcion text not null default '',
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (empresa_id, nombre)
);

alter table public.ingreso_categorias enable row level security;

drop policy if exists ingreso_categorias_all on public.ingreso_categorias;
create policy ingreso_categorias_all on public.ingreso_categorias
  for all to authenticated
  using (public.app_can_access_empresa(empresa_id))
  with check (public.app_can_access_empresa(empresa_id));

drop trigger if exists set_updated_at_ingreso_categorias on public.ingreso_categorias;
create trigger set_updated_at_ingreso_categorias
before update on public.ingreso_categorias
for each row execute function public.app_set_updated_at();

alter table public.ingresos
  add column if not exists ingreso_categoria_id uuid references public.ingreso_categorias(id) on delete set null,
  add column if not exists categoria_nombre_snapshot text not null default '';

alter table public.ingresos_recurrentes
  add column if not exists ingreso_categoria_id uuid references public.ingreso_categorias(id) on delete set null,
  add column if not exists categoria_nombre_snapshot text not null default '';

create index if not exists ingresos_categoria_idx
  on public.ingresos (empresa_id, ingreso_categoria_id);

create index if not exists ingresos_recurrentes_categoria_idx
  on public.ingresos_recurrentes (empresa_id, ingreso_categoria_id);

create or replace function public.list_ingreso_categorias()
returns setof public.ingreso_categorias
language sql
security definer
set search_path = public
as $$
  select ic.*
  from public.ingreso_categorias ic
  where public.app_can_access_empresa(ic.empresa_id)
  order by ic.nombre;
$$;

create or replace function public.upsert_ingreso_categoria(
  p_nombre text,
  p_descripcion text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_nombre text := btrim(coalesce(p_nombre, ''));
  v_descripcion text := btrim(coalesce(p_descripcion, ''));
  v_id uuid;
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_nombre = '' then
    raise exception 'El nombre de la categoria de ingreso es obligatorio.';
  end if;

  insert into public.ingreso_categorias (
    empresa_id,
    nombre,
    descripcion,
    activo
  )
  values (
    v_empresa_id,
    v_nombre,
    v_descripcion,
    true
  )
  on conflict (empresa_id, nombre) do update set
    descripcion = excluded.descripcion,
    activo = true
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.upsert_gasto_categoria(
  p_nombre text,
  p_descripcion text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_nombre text := btrim(coalesce(p_nombre, ''));
  v_descripcion text := btrim(coalesce(p_descripcion, ''));
  v_id uuid;
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_nombre = '' then
    raise exception 'El nombre de la categoria de gasto es obligatorio.';
  end if;

  insert into public.gasto_categorias (
    empresa_id,
    nombre,
    descripcion,
    activo
  )
  values (
    v_empresa_id,
    v_nombre,
    v_descripcion,
    true
  )
  on conflict (empresa_id, nombre) do update set
    descripcion = excluded.descripcion,
    activo = true
  returning id into v_id;

  return v_id;
end;
$$;

drop function if exists public.list_ingresos();

create or replace function public.list_ingresos()
returns table (
  id uuid,
  ingreso_categoria_id text,
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
    coalesce(i.ingreso_categoria_id::text, i.categoria_nombre_snapshot) as ingreso_categoria_id,
    coalesce(i.cliente_id::text, i.cliente_nombre_snapshot) as cliente_id,
    coalesce(i.cotizacion_id::text, i.cotizacion_folio_snapshot) as cotizacion_id,
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
  where i.deleted_at is null
    and public.app_can_access_empresa(i.empresa_id)
  order by i.fecha desc, i.updated_at desc;
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
          and i.deleted_at is null
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

create or replace function public.upsert_ingreso(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_categoria_uuid uuid := public.app_parse_uuid(p_payload ->> 'ingreso_categoria_id');
  v_categoria_snapshot text := '';
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
  if v_cotizacion_uuid is null then
    v_cotizacion_snapshot := coalesce(p_payload ->> 'cotizacion_id', '');
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
      cotizacion_folio_snapshot,
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
      v_cotizacion_snapshot,
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
    v_id,
    v_empresa_id,
    v_categoria_uuid,
    v_categoria_snapshot,
    v_cliente_uuid,
    v_cliente_snapshot,
    v_cotizacion_uuid,
    v_cotizacion_snapshot,
    v_recurrente_id,
    coalesce(p_payload ->> 'icon_key', 'wallet'),
    coalesce((p_payload ->> 'monto')::numeric, 0),
    coalesce(p_payload ->> 'metodo_pago', 'transferencia'),
    coalesce((p_payload ->> 'fecha')::date, current_date),
    coalesce(p_payload ->> 'referencia', ''),
    coalesce(p_payload ->> 'notas', '')
  )
  on conflict (id) do update set
    ingreso_categoria_id = excluded.ingreso_categoria_id,
    categoria_nombre_snapshot = excluded.categoria_nombre_snapshot,
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

grant execute on function public.list_ingreso_categorias() to authenticated;
grant execute on function public.upsert_ingreso_categoria(text, text) to authenticated;
grant execute on function public.upsert_gasto_categoria(text, text) to authenticated;
