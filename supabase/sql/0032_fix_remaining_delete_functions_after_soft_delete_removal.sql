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

grant execute on function public.delete_producto(uuid) to authenticated;
grant execute on function public.delete_material(uuid) to authenticated;
grant execute on function public.delete_ingreso(uuid) to authenticated;
grant execute on function public.delete_gasto(uuid) to authenticated;
