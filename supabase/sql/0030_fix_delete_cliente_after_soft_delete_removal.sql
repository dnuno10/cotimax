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

grant execute on function public.delete_cliente(uuid) to authenticated;
