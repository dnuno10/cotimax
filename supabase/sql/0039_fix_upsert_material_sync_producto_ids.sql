-- Prevent accidental removal of product/material relations when updating a material.
-- Only sync producto_componentes when p_payload.sync_producto_ids = true.

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
  v_sync_producto_ids boolean := coalesce(
    nullif(p_payload ->> 'sync_producto_ids', '')::boolean,
    false
  );
  v_is_new boolean;
  v_limite_materiales integer := -1;
  v_materiales_actuales integer := 0;
begin
  perform public.app_require_company_access(v_empresa_id);

  select not exists(
    select 1
    from public.materiales_insumos m
    where m.id = v_id
      and m.empresa_id = v_empresa_id
  )
  into v_is_new;

  if v_is_new then
    select p.limite_materiales
    into v_limite_materiales
    from public.suscripciones s
    join public.planes p on p.id = s.plan_id
    where s.empresa_id = v_empresa_id
    order by s.updated_at desc
    limit 1;

    if coalesce(v_limite_materiales, -1) >= 0 then
      select count(*)::int into v_materiales_actuales
      from public.materiales_insumos
      where empresa_id = v_empresa_id;

      if v_materiales_actuales >= v_limite_materiales then
        raise exception 'Tu plan actual permite hasta % materiales.', v_limite_materiales;
      end if;
    end if;
  end if;

  if v_sync_producto_ids then
    select coalesce(array_agg(producto_id), '{}'::uuid[])
    into v_producto_ids
    from (
      select distinct public.app_parse_uuid(value) as producto_id
      from jsonb_array_elements_text(coalesce(p_payload -> 'producto_ids', '[]'::jsonb))
    ) selected_ids
    join public.productos_servicios p
      on p.id = selected_ids.producto_id
     and p.empresa_id = v_empresa_id
    where selected_ids.producto_id is not null;
  end if;

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

  if v_sync_producto_ids then
    delete from public.producto_componentes pc
    using public.productos_servicios p
    where p.id = pc.producto_id
      and p.empresa_id = v_empresa_id
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
      and not exists (
        select 1
        from public.producto_componentes existing
        where existing.producto_id = p.id
          and existing.material_id = v_id
      );
  end if;

  return v_id;
end;
$$;

grant execute on function public.upsert_material(jsonb) to authenticated;

