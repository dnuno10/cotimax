create or replace function public.delete_cliente(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select empresa_id into v_empresa_id
  from public.clientes
  where id = p_id;

  perform public.app_require_company_access(v_empresa_id);

  update public.clientes
  set deleted_at = timezone('utc', now())
  where id = p_id;
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
begin
  select empresa_id into v_empresa_id
  from public.proveedores
  where id = p_id;

  perform public.app_require_company_access(v_empresa_id);

  update public.proveedores
  set deleted_at = timezone('utc', now())
  where id = p_id;
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
begin
  select empresa_id into v_empresa_id
  from public.productos_servicios
  where id = p_id;

  perform public.app_require_company_access(v_empresa_id);

  update public.productos_servicios
  set deleted_at = timezone('utc', now())
  where id = p_id;
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
  select empresa_id into v_empresa_id
  from public.cotizaciones
  where id = p_id;

  perform public.app_require_company_access(v_empresa_id);

  update public.cotizaciones
  set deleted_at = timezone('utc', now())
  where id = p_id;
end;
$$;

grant execute on function public.delete_cliente(uuid) to authenticated;
grant execute on function public.delete_proveedor(uuid) to authenticated;
grant execute on function public.delete_producto(uuid) to authenticated;
grant execute on function public.delete_cotizacion(uuid) to authenticated;
