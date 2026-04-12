drop function if exists public.list_materiales(text);

create or replace function public.list_materiales(p_query text default '')
returns table (
  id uuid,
  nombre text,
  descripcion text,
  tipo_nombre text,
  unidad_medida text,
  costo_unitario numeric,
  stock_disponible numeric,
  proveedor_id uuid,
  proveedor_nombre text,
  sku text,
  producto_ids text[],
  activo boolean,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    m.id, m.nombre, m.descripcion, m.tipo_nombre, m.unidad_medida,
    m.costo_unitario, m.stock_disponible, m.proveedor_id, m.proveedor_nombre,
    m.sku,
    coalesce(
      array_agg(distinct p.id::text) filter (where p.id is not null),
      '{}'::text[]
    ) as producto_ids,
    m.activo,
    m.created_at, m.updated_at
  from public.materiales_insumos m
  left join public.producto_componentes pc on pc.material_id = m.id
  left join public.productos_servicios p
    on p.id = pc.producto_id
    and p.deleted_at is null
    and public.app_can_access_empresa(p.empresa_id)
  where m.deleted_at is null
    and public.app_can_access_empresa(m.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(m.nombre) like '%' || lower(p_query) || '%'
      or lower(m.sku) like '%' || lower(p_query) || '%'
      or lower(m.proveedor_nombre) like '%' || lower(p_query) || '%'
    )
  group by
    m.id, m.nombre, m.descripcion, m.tipo_nombre, m.unidad_medida,
    m.costo_unitario, m.stock_disponible, m.proveedor_id, m.proveedor_nombre,
    m.sku, m.activo, m.created_at, m.updated_at
  order by m.updated_at desc;
$$;

create or replace function public.upsert_material(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_proveedor_id uuid := public.app_parse_uuid(p_payload ->> 'proveedor_id');
  v_producto_ids uuid[] := '{}'::uuid[];
begin
  perform public.app_require_company_access(v_empresa_id);

  select coalesce(array_agg(producto_id), '{}'::uuid[])
  into v_producto_ids
  from (
    select distinct public.app_parse_uuid(value) as producto_id
    from jsonb_array_elements_text(coalesce(p_payload -> 'producto_ids', '[]'::jsonb))
  ) selected_ids
  join public.productos_servicios p
    on p.id = selected_ids.producto_id
   and p.empresa_id = v_empresa_id
   and p.deleted_at is null
  where selected_ids.producto_id is not null;

  insert into public.materiales_insumos (
    id, empresa_id, nombre, descripcion, tipo_nombre, unidad_medida,
    costo_unitario, stock_disponible, proveedor_id, proveedor_nombre,
    sku, activo
  )
  values (
    v_id, v_empresa_id,
    coalesce(p_payload ->> 'nombre', ''),
    coalesce(p_payload ->> 'descripcion', ''),
    coalesce(p_payload ->> 'tipo_nombre', ''),
    coalesce(p_payload ->> 'unidad_medida', ''),
    coalesce((p_payload ->> 'costo_unitario')::numeric, 0),
    coalesce((p_payload ->> 'stock_disponible')::numeric, 0),
    v_proveedor_id,
    coalesce(p_payload ->> 'proveedor_nombre', ''),
    coalesce(p_payload ->> 'sku', ''),
    coalesce((p_payload ->> 'activo')::boolean, true)
  )
  on conflict (id) do update set
    nombre = excluded.nombre,
    descripcion = excluded.descripcion,
    tipo_nombre = excluded.tipo_nombre,
    unidad_medida = excluded.unidad_medida,
    costo_unitario = excluded.costo_unitario,
    stock_disponible = excluded.stock_disponible,
    proveedor_id = excluded.proveedor_id,
    proveedor_nombre = excluded.proveedor_nombre,
    sku = excluded.sku,
    activo = excluded.activo;

  delete from public.producto_componentes pc
  using public.productos_servicios p
  where p.id = pc.producto_id
    and p.empresa_id = v_empresa_id
    and p.deleted_at is null
    and pc.material_id = v_id
    and not (pc.producto_id = any(v_producto_ids));

  insert into public.producto_componentes (
    producto_id, tipo, material_id, nombre_libre, cantidad, unidad_consumo,
    costo_unitario_snapshot, orden
  )
  select
    p.id,
    'Material',
    v_id,
    '',
    1,
    coalesce(p_payload ->> 'unidad_medida', ''),
    coalesce((p_payload ->> 'costo_unitario')::numeric, 0),
    coalesce((
      select max(existing.orden) + 1
      from public.producto_componentes existing
      where existing.producto_id = p.id
    ), 0)
  from public.productos_servicios p
  where p.id = any(v_producto_ids)
    and p.empresa_id = v_empresa_id
    and p.deleted_at is null
    and not exists (
      select 1
      from public.producto_componentes existing
      where existing.producto_id = p.id
        and existing.material_id = v_id
    );

  return v_id;
end;
$$;

grant execute on function public.list_materiales(text) to authenticated;
grant execute on function public.upsert_material(jsonb) to authenticated;
