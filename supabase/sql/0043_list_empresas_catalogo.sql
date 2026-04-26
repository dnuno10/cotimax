-- Lista empresas accesibles para el usuario actual (id + nombre).

create or replace function public.list_empresas_catalogo()
returns table (
  id uuid,
  nombre_comercial text
)
language sql
security definer
set search_path = public
as $$
  select
    e.id,
    e.nombre_comercial
  from public.empresas e
  where public.app_can_access_empresa(e.id)
  order by e.nombre_comercial asc;
$$;

grant execute on function public.list_empresas_catalogo() to authenticated;
