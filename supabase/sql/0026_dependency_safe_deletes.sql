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
      select
        'recordatorios'::text,
        'recordatorios relacionados'::text,
        count(*)::bigint as dependency_count
      from public.recordatorios r
      where r.deleted_at is null
        and r.cotizacion_id in (select id from target_ids)
      union all
      select
        'ingresos'::text,
        'ingresos relacionados'::text,
        count(*)::bigint as dependency_count
      from public.ingresos i
      where i.deleted_at is null
        and i.cotizacion_id in (select id from target_ids)
      union all
      select
        'ingresos_recurrentes'::text,
        'ingresos recurrentes relacionados'::text,
        count(*)::bigint as dependency_count
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
      select
        'cotizaciones'::text,
        'cotizaciones relacionadas'::text,
        count(*)::bigint as dependency_count
      from public.cotizaciones c
      where c.deleted_at is null
        and c.cliente_id in (select id from target_ids)
      union all
      select
        'ingresos'::text,
        'ingresos relacionados'::text,
        count(*)::bigint as dependency_count
      from public.ingresos i
      where i.deleted_at is null
        and i.cliente_id in (select id from target_ids)
      union all
      select
        'ingresos_recurrentes'::text,
        'ingresos recurrentes relacionados'::text,
        count(*)::bigint as dependency_count
      from public.ingresos_recurrentes ir
      where ir.cliente_id in (select id from target_ids)
      union all
      select
        'recordatorios'::text,
        'recordatorios relacionados'::text,
        count(*)::bigint as dependency_count
      from public.recordatorios r
      where r.deleted_at is null
        and r.cliente_id in (select id from target_ids)
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
      select
        'gastos'::text,
        'gastos relacionados'::text,
        count(*)::bigint as dependency_count
      from public.gastos g
      where g.deleted_at is null
        and g.proveedor_id in (select id from target_ids)
      union all
      select
        'materiales'::text,
        'materiales relacionados'::text,
        count(*)::bigint as dependency_count
      from public.materiales_insumos m
      where m.deleted_at is null
        and m.proveedor_id in (select id from target_ids)
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
      select
        'cotizacion_detalles'::text,
        'lineas de cotizacion relacionadas'::text,
        count(*)::bigint as dependency_count
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
      select
        'producto_componentes'::text,
        'componentes de producto relacionados'::text,
        count(*)::bigint as dependency_count
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
      select
        'ingresos'::text,
        'ingresos relacionados'::text,
        count(*)::bigint as dependency_count
      from public.ingresos i
      where i.deleted_at is null
        and i.gasto_fuente_id in (select id from target_ids)
    ) dependency_rows
    where dependency_rows.dependency_count > 0;
    return;
  end if;
end;
$$;

create or replace function public.delete_cliente(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_cliente_label text;
begin
  select
    c.empresa_id,
    coalesce(nullif(c.nombre, ''), nullif(c.empresa, ''), 'Cliente eliminado')
  into v_empresa_id, v_cliente_label
  from public.clientes c
  where c.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.cotizaciones
  set cliente_id = null,
      cliente_nombre_snapshot = coalesce(nullif(cliente_nombre_snapshot, ''), v_cliente_label),
      updated_at = timezone('utc', now())
  where cliente_id = p_id;

  update public.ingresos
  set cliente_id = null,
      cliente_nombre_snapshot = coalesce(nullif(cliente_nombre_snapshot, ''), v_cliente_label),
      updated_at = timezone('utc', now())
  where cliente_id = p_id;

  update public.ingresos_recurrentes
  set cliente_id = null,
      cliente_nombre_snapshot = coalesce(nullif(cliente_nombre_snapshot, ''), v_cliente_label),
      updated_at = timezone('utc', now())
  where cliente_id = p_id;

  update public.recordatorios
  set cliente_id = null,
      cliente_nombre_snapshot = coalesce(nullif(cliente_nombre_snapshot, ''), v_cliente_label),
      updated_at = timezone('utc', now())
  where cliente_id = p_id;

  delete from public.cliente_contactos where cliente_id = p_id;
  delete from public.cliente_direcciones where cliente_id = p_id;
  delete from public.cliente_configuracion where cliente_id = p_id;
  delete from public.cliente_clasificacion where cliente_id = p_id;
  delete from public.clientes where id = p_id;
end;
$$;

create or replace function public.delete_proveedor(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_proveedor_label text;
begin
  select
    p.empresa_id,
    coalesce(nullif(p.nombre, ''), nullif(p.empresa, ''), 'Proveedor eliminado')
  into v_empresa_id, v_proveedor_label
  from public.proveedores p
  where p.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.gastos
  set proveedor_id = null,
      proveedor_nombre = coalesce(nullif(proveedor_nombre, ''), v_proveedor_label),
      updated_at = timezone('utc', now())
  where proveedor_id = p_id;

  update public.materiales_insumos
  set proveedor_id = null,
      proveedor_nombre = coalesce(nullif(proveedor_nombre, ''), v_proveedor_label),
      updated_at = timezone('utc', now())
  where proveedor_id = p_id;

  delete from public.proveedor_contactos where proveedor_id = p_id;
  delete from public.proveedor_direcciones where proveedor_id = p_id;
  delete from public.proveedores where id = p_id;
end;
$$;

create or replace function public.delete_producto(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_producto_label text;
begin
  select
    p.empresa_id,
    coalesce(nullif(p.nombre, ''), 'Producto eliminado')
  into v_empresa_id, v_producto_label
  from public.productos_servicios p
  where p.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.cotizacion_detalles
  set producto_servicio_id = null,
      concepto = coalesce(nullif(concepto, ''), v_producto_label),
      updated_at = timezone('utc', now())
  where producto_servicio_id = p_id;

  delete from public.producto_precios_rango where producto_id = p_id;
  delete from public.producto_componentes where producto_id = p_id;
  delete from public.productos_servicios where id = p_id;
end;
$$;

create or replace function public.delete_material(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_material_label text;
begin
  select
    m.empresa_id,
    coalesce(nullif(m.nombre, ''), 'Material eliminado')
  into v_empresa_id, v_material_label
  from public.materiales_insumos m
  where m.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.producto_componentes
  set material_id = null,
      nombre_libre = coalesce(nullif(nombre_libre, ''), v_material_label),
      updated_at = timezone('utc', now())
  where material_id = p_id;

  delete from public.materiales_insumos where id = p_id;
end;
$$;

create or replace function public.delete_cotizacion(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_folio text;
begin
  select c.empresa_id, c.folio
  into v_empresa_id, v_folio
  from public.cotizaciones c
  where c.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.ingresos
  set cotizacion_id = null,
      cotizacion_folio_snapshot = coalesce(nullif(cotizacion_folio_snapshot, ''), coalesce(v_folio, '')),
      updated_at = timezone('utc', now())
  where cotizacion_id = p_id;

  update public.ingresos_recurrentes
  set cotizacion_id = null,
      cotizacion_folio_snapshot = coalesce(nullif(cotizacion_folio_snapshot, ''), coalesce(v_folio, '')),
      updated_at = timezone('utc', now())
  where cotizacion_id = p_id;

  update public.recordatorios
  set cotizacion_id = null,
      cotizacion_folio_snapshot = coalesce(nullif(cotizacion_folio_snapshot, ''), coalesce(v_folio, '')),
      updated_at = timezone('utc', now())
  where cotizacion_id = p_id;

  delete from public.cotizacion_detalles where cotizacion_id = p_id;
  delete from public.cotizaciones where id = p_id;
end;
$$;

create or replace function public.delete_ingreso(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select i.empresa_id
  into v_empresa_id
  from public.ingresos i
  where i.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);
  delete from public.ingresos where id = p_id;
end;
$$;

create or replace function public.delete_gasto(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_gasto_label text;
begin
  select
    g.empresa_id,
    coalesce(nullif(g.descripcion, ''), nullif(g.referencia, ''), 'Gasto eliminado')
  into v_empresa_id, v_gasto_label
  from public.gastos g
  where g.id = p_id;

  if v_empresa_id is null then
    return;
  end if;

  perform public.app_require_company_access(v_empresa_id);

  update public.ingresos
  set gasto_fuente_id = null,
      gasto_fuente_nombre_snapshot = coalesce(
        nullif(gasto_fuente_nombre_snapshot, ''),
        v_gasto_label
      ),
      updated_at = timezone('utc', now())
  where gasto_fuente_id = p_id;

  delete from public.gastos where id = p_id;
end;
$$;

grant execute on function public.list_delete_dependencies(text, uuid[]) to authenticated;
grant execute on function public.delete_cliente(uuid) to authenticated;
grant execute on function public.delete_proveedor(uuid) to authenticated;
grant execute on function public.delete_producto(uuid) to authenticated;
grant execute on function public.delete_material(uuid) to authenticated;
grant execute on function public.delete_cotizacion(uuid) to authenticated;
grant execute on function public.delete_ingreso(uuid) to authenticated;
grant execute on function public.delete_gasto(uuid) to authenticated;
