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

grant execute on function public.delete_proveedor(uuid) to authenticated;
