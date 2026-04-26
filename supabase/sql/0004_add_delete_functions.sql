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

  delete from public.cotizacion_detalles where cotizacion_id = p_id;
  delete from public.cotizaciones where id = p_id;
end;
$$;

grant execute on function public.delete_cliente(uuid) to authenticated;
grant execute on function public.delete_proveedor(uuid) to authenticated;
grant execute on function public.delete_producto(uuid) to authenticated;
grant execute on function public.delete_cotizacion(uuid) to authenticated;
