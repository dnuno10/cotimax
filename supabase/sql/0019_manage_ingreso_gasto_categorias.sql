create or replace function public.update_ingreso_categoria(
  p_id uuid,
  p_nombre text,
  p_descripcion text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_nombre text := btrim(coalesce(p_nombre, ''));
  v_descripcion text := btrim(coalesce(p_descripcion, ''));
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_nombre = '' then
    raise exception 'El nombre de la categoria de ingreso es obligatorio.';
  end if;

  update public.ingreso_categorias
  set nombre = v_nombre,
      descripcion = v_descripcion,
      activo = true
  where id = p_id
    and empresa_id = v_empresa_id;

  if not found then
    raise exception 'Categoria de ingreso no encontrada.';
  end if;
end;
$$;

create or replace function public.delete_ingreso_categoria(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
begin
  perform public.app_require_company_access(v_empresa_id);

  delete from public.ingreso_categorias
  where id = p_id
    and empresa_id = v_empresa_id;

  if not found then
    raise exception 'Categoria de ingreso no encontrada.';
  end if;
end;
$$;

create or replace function public.update_gasto_categoria(
  p_id uuid,
  p_nombre text,
  p_descripcion text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_nombre text := btrim(coalesce(p_nombre, ''));
  v_descripcion text := btrim(coalesce(p_descripcion, ''));
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_nombre = '' then
    raise exception 'El nombre de la categoria de gasto es obligatorio.';
  end if;

  update public.gasto_categorias
  set nombre = v_nombre,
      descripcion = v_descripcion,
      activo = true
  where id = p_id
    and empresa_id = v_empresa_id;

  if not found then
    raise exception 'Categoria de gasto no encontrada.';
  end if;
end;
$$;

create or replace function public.delete_gasto_categoria(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
begin
  perform public.app_require_company_access(v_empresa_id);

  delete from public.gasto_categorias
  where id = p_id
    and empresa_id = v_empresa_id;

  if not found then
    raise exception 'Categoria de gasto no encontrada.';
  end if;
end;
$$;

grant execute on function public.update_ingreso_categoria(uuid, text, text) to authenticated;
grant execute on function public.delete_ingreso_categoria(uuid) to authenticated;
grant execute on function public.update_gasto_categoria(uuid, text, text) to authenticated;
grant execute on function public.delete_gasto_categoria(uuid) to authenticated;
