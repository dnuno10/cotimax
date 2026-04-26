-- Compute product costo_base dynamically from related materials when auto_calcular_costo_base is enabled.
-- This keeps product costs up to date when a material cost changes, without requiring re-saving the product.

create or replace function public.list_productos(p_query text default '')
returns table (
  id uuid,
  tipo text,
  nombre text,
  descripcion text,
  precio_base numeric,
  costo_base numeric,
  categoria_nombre text,
  unidad_medida text,
  sku text,
  imagen_url text,
  imagen_bucket text,
  imagen_path text,
  activo boolean,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.tipo,
    p.nombre,
    p.descripcion,
    p.precio_base,
    case
      when coalesce(p.auto_calcular_costo_base, true) then
        coalesce(
          (
            select sum(
              coalesce(pc.cantidad, 0)
              * coalesce(m.costo_unitario, pc.costo_unitario_snapshot, 0)
            )
            from public.producto_componentes pc
            left join public.materiales_insumos m on m.id = pc.material_id
            where pc.producto_id = p.id
          ),
          p.costo_base
        )
      else p.costo_base
    end as costo_base,
    coalesce(cp.nombre, p.categoria_nombre_snapshot) as categoria_nombre,
    p.unidad_medida,
    p.sku,
    coalesce(p.imagen_url, '') as imagen_url,
    coalesce(p.imagen_bucket, '') as imagen_bucket,
    coalesce(p.imagen_path, '') as imagen_path,
    p.activo,
    p.created_at,
    p.updated_at
  from public.productos_servicios p
  left join public.categorias_producto cp on cp.id = p.categoria_producto_id
  where public.app_can_access_empresa(p.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(p.nombre) like '%' || lower(p_query) || '%'
      or lower(p.sku) like '%' || lower(p_query) || '%'
      or lower(coalesce(cp.nombre, p.categoria_nombre_snapshot)) like '%' || lower(p_query) || '%'
    )
  order by p.updated_at desc;
$$;

grant execute on function public.list_productos(text) to authenticated;

