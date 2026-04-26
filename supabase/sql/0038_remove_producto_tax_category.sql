-- Remove product tax category (categoria_impuesto_nombre) from products.

begin;

-- Drop old RPC signature (had p_categoria_impuesto_nombre).
drop function if exists public.upsert_producto(
  uuid, text, text, text, numeric, numeric, boolean, text, numeric, numeric,
  text, text, text, text, text, text, boolean, jsonb, jsonb
);

alter table if exists public.productos_servicios
drop column if exists categoria_impuesto_nombre;

create or replace function public.upsert_producto(
  p_id uuid default null,
  p_tipo text default 'producto',
  p_nombre text default '',
  p_descripcion text default '',
  p_precio_base numeric default 0,
  p_costo_base numeric default 0,
  p_auto_calcular_costo_base boolean default true,
  p_modo_precio text default 'Fijo',
  p_cantidad_predeterminada numeric default null,
  p_cantidad_maxima numeric default null,
  p_categoria_nombre text default '',
  p_tasa_impuesto_nombre text default '',
  p_unidad_medida text default '',
  p_sku text default '',
  p_imagen_url text default '',
  p_activo boolean default true,
  p_componentes jsonb default '[]'::jsonb,
  p_precios_por_rango jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(p_id, gen_random_uuid());
  v_categoria_id uuid;
  v_item jsonb;
  v_material_id uuid;
begin
  perform public.app_require_company_access(v_empresa_id);

  if coalesce(btrim(p_categoria_nombre), '') <> '' then
    insert into public.categorias_producto (empresa_id, nombre, descripcion)
    values (v_empresa_id, p_categoria_nombre, '')
    on conflict (empresa_id, nombre) do update set nombre = excluded.nombre
    returning id into v_categoria_id;

    if v_categoria_id is null then
      select id into v_categoria_id
      from public.categorias_producto
      where empresa_id = v_empresa_id
        and nombre = p_categoria_nombre
      limit 1;
    end if;
  end if;

  insert into public.productos_servicios (
    id, empresa_id, tipo, nombre, descripcion, precio_base, costo_base,
    auto_calcular_costo_base, modo_precio, cantidad_predeterminada,
    cantidad_maxima, categoria_producto_id, categoria_nombre_snapshot,
    tasa_impuesto_nombre, unidad_medida, sku, imagen_url, activo
  )
  values (
    v_id, v_empresa_id, p_tipo, p_nombre, p_descripcion, p_precio_base,
    p_costo_base, p_auto_calcular_costo_base, p_modo_precio,
    p_cantidad_predeterminada, p_cantidad_maxima, v_categoria_id,
    p_categoria_nombre, p_tasa_impuesto_nombre, p_unidad_medida, p_sku,
    p_imagen_url, p_activo
  )
  on conflict (id) do update set
    tipo = excluded.tipo,
    nombre = excluded.nombre,
    descripcion = excluded.descripcion,
    precio_base = excluded.precio_base,
    costo_base = excluded.costo_base,
    auto_calcular_costo_base = excluded.auto_calcular_costo_base,
    modo_precio = excluded.modo_precio,
    cantidad_predeterminada = excluded.cantidad_predeterminada,
    cantidad_maxima = excluded.cantidad_maxima,
    categoria_producto_id = excluded.categoria_producto_id,
    categoria_nombre_snapshot = excluded.categoria_nombre_snapshot,
    tasa_impuesto_nombre = excluded.tasa_impuesto_nombre,
    unidad_medida = excluded.unidad_medida,
    sku = excluded.sku,
    imagen_url = excluded.imagen_url,
    activo = excluded.activo;

  delete from public.producto_componentes where producto_id = v_id;
  for v_item in select * from jsonb_array_elements(coalesce(p_componentes, '[]'::jsonb))
  loop
    v_material_id := public.app_parse_uuid(v_item ->> 'material_id');
    insert into public.producto_componentes (
      producto_id, tipo, material_id, nombre_libre, cantidad, unidad_consumo,
      costo_unitario_snapshot, orden
    )
    values (
      v_id,
      coalesce(v_item ->> 'tipo', 'Material'),
      v_material_id,
      coalesce(v_item ->> 'nombre_libre', ''),
      coalesce((v_item ->> 'cantidad')::numeric, 0),
      coalesce(v_item ->> 'unidad_consumo', ''),
      coalesce((v_item ->> 'costo_unitario_snapshot')::numeric, 0),
      coalesce((v_item ->> 'orden')::int, 0)
    );
  end loop;

  delete from public.producto_precios_rango where producto_id = v_id;
  for v_item in select * from jsonb_array_elements(coalesce(p_precios_por_rango, '[]'::jsonb))
  loop
    insert into public.producto_precios_rango (
      producto_id, cantidad_desde, cantidad_hasta, precio
    )
    values (
      v_id,
      coalesce((v_item ->> 'cantidad_desde')::numeric, 0),
      coalesce((v_item ->> 'cantidad_hasta')::numeric, 0),
      coalesce((v_item ->> 'precio')::numeric, 0)
    );
  end loop;

  return v_id;
end;
$$;

grant execute on function public.upsert_producto(
  uuid, text, text, text, numeric, numeric, boolean, text, numeric, numeric,
  text, text, text, text, text, boolean, jsonb, jsonb
) to authenticated;

commit;
