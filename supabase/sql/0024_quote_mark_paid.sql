drop function if exists public.list_cotizaciones(text);

alter table public.cotizaciones
  drop constraint if exists cotizaciones_estatus_check;

alter table public.cotizaciones
  add constraint cotizaciones_estatus_check
  check (estatus in ('borrador', 'enviada', 'aprobada', 'pagada', 'rechazada'));

create function public.list_cotizaciones(p_query text default '')
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
  where c.deleted_at is null
    and public.app_can_access_empresa(c.empresa_id)
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
  where id = p_id
    and deleted_at is null;

  if v_empresa_id is null then
    raise exception 'Cotización no encontrada';
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.cotizaciones
  set estatus = p_status,
      updated_at = timezone('utc', now())
  where id = p_id;

  if coalesce(p_status, '') <> 'pagada' then
    update public.ingresos
    set deleted_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where empresa_id = v_empresa_id
      and cotizacion_id = p_id
      and deleted_at is null;
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
  where id = p_id
    and deleted_at is null;

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
  where id = p_id
    and deleted_at is null;

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

  update public.ingresos
  set deleted_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where empresa_id = v_empresa_id
    and cotizacion_id = p_id
    and deleted_at is null;
end;
$$;

grant execute on function public.mark_cotizacion_pagada(uuid) to authenticated;
grant execute on function public.desmarcar_cotizacion_pagada(uuid) to authenticated;
grant execute on function public.list_cotizaciones(text) to authenticated;
