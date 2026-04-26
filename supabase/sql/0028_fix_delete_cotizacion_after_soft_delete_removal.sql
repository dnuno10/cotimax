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

  delete from public.cotizacion_detalles
  where cotizacion_id = p_id;

  delete from public.cotizaciones
  where id = p_id;
end;
$$;

grant execute on function public.delete_cotizacion(uuid) to authenticated;
