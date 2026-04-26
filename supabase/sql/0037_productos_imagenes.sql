create or replace function public.app_plan_allows_product_images(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select s.plan_id
      from public.suscripciones s
      where s.empresa_id = p_empresa_id
      order by s.updated_at desc
      limit 1
    ),
    'starter'
  ) in ('pro', 'empresa');
$$;

-- NOTE:
-- The Storage section in this migration (storage.buckets / storage.objects
-- policies / triggers) must be executed with elevated privileges (e.g. in the
-- Supabase Dashboard SQL editor as the admin role). Running it from the client
-- (authenticated/anon) will fail with "must be owner of table objects".

alter table public.productos_servicios
  add column if not exists imagen_bucket text not null default '',
  add column if not exists imagen_path text not null default '';

drop function if exists public.list_productos(text);

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
    p.costo_base,
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

drop function if exists public.list_cotizacion_detalles(uuid);

create or replace function public.list_cotizacion_detalles(
  p_cotizacion_id uuid default null
)
returns table (
  id uuid,
  cotizacion_id uuid,
  producto_servicio_id uuid,
  concepto text,
  descripcion text,
  precio_unitario numeric,
  unidad text,
  descuento numeric,
  cantidad numeric,
  impuesto_porcentaje numeric,
  importe numeric,
  orden integer,
  created_at timestamptz,
  updated_at timestamptz,
  producto_imagen_url text,
  producto_imagen_bucket text,
  producto_imagen_path text
)
language sql
security definer
set search_path = public
as $$
  select
    d.id,
    d.cotizacion_id,
    d.producto_servicio_id,
    d.concepto,
    d.descripcion,
    d.precio_unitario,
    d.unidad,
    d.descuento,
    d.cantidad,
    d.impuesto_porcentaje,
    d.importe,
    d.orden,
    d.created_at,
    d.updated_at,
    coalesce(p.imagen_url, '') as producto_imagen_url,
    coalesce(p.imagen_bucket, '') as producto_imagen_bucket,
    coalesce(p.imagen_path, '') as producto_imagen_path
  from public.cotizacion_detalles d
  join public.cotizaciones c on c.id = d.cotizacion_id
  left join public.productos_servicios p on p.id = d.producto_servicio_id
  where public.app_can_access_empresa(c.empresa_id)
    and (p_cotizacion_id is null or d.cotizacion_id = p_cotizacion_id)
  order by d.cotizacion_id, d.orden asc, d.created_at asc;
$$;

grant execute on function public.list_cotizacion_detalles(uuid) to authenticated;

create or replace function public.update_producto_imagen(
  p_id uuid,
  p_imagen_bucket text default '',
  p_imagen_path text default '',
  p_imagen_url text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_has_image boolean := coalesce(btrim(p_imagen_path), '') <> '';
begin
  select empresa_id
  into v_empresa_id
  from public.productos_servicios
  where id = p_id;

  if v_empresa_id is null then
    raise exception 'Producto no encontrado';
  end if;

  perform public.app_require_company_access(v_empresa_id);

  if v_has_image and not public.app_plan_allows_product_images(v_empresa_id) then
    raise exception 'Imágenes de producto disponibles en Pro o Empresa';
  end if;

  update public.productos_servicios
  set imagen_bucket = coalesce(p_imagen_bucket, ''),
      imagen_path = coalesce(p_imagen_path, ''),
      imagen_url = coalesce(p_imagen_url, ''),
      updated_at = timezone('utc', now())
  where id = p_id;
end;
$$;

grant execute on function public.update_producto_imagen(uuid, text, text, text)
to authenticated;

do $$
begin
  insert into storage.buckets (id, name, public)
  values ('producto_imagenes', 'producto_imagenes', true)
  on conflict (id) do update set public = excluded.public;
exception
  when insufficient_privilege then
    raise notice 'Skipping storage bucket creation (insufficient_privilege).';
end;
$$;

do $$
begin
  drop policy if exists producto_imagenes_select on storage.objects;
  create policy producto_imagenes_select on storage.objects
  for select
  using (bucket_id = 'producto_imagenes');

  drop policy if exists producto_imagenes_insert on storage.objects;
  create policy producto_imagenes_insert on storage.objects
  for insert
  with check (
    bucket_id = 'producto_imagenes'
    and public.app_can_access_empresa(
      public.app_parse_uuid(split_part(name, '/', 1))
    )
    and public.app_plan_allows_product_images(
      public.app_parse_uuid(split_part(name, '/', 1))
    )
  );

  drop policy if exists producto_imagenes_update on storage.objects;
  create policy producto_imagenes_update on storage.objects
  for update
  using (
    bucket_id = 'producto_imagenes'
    and public.app_can_access_empresa(
      public.app_parse_uuid(split_part(name, '/', 1))
    )
    and public.app_plan_allows_product_images(
      public.app_parse_uuid(split_part(name, '/', 1))
    )
  )
  with check (
    bucket_id = 'producto_imagenes'
    and public.app_can_access_empresa(
      public.app_parse_uuid(split_part(name, '/', 1))
    )
    and public.app_plan_allows_product_images(
      public.app_parse_uuid(split_part(name, '/', 1))
    )
  );

  drop policy if exists producto_imagenes_delete on storage.objects;
  create policy producto_imagenes_delete on storage.objects
  for delete
  using (
    bucket_id = 'producto_imagenes'
    and public.app_can_access_empresa(
      public.app_parse_uuid(split_part(name, '/', 1))
    )
    and public.app_plan_allows_product_images(
      public.app_parse_uuid(split_part(name, '/', 1))
    )
  );
exception
  when insufficient_privilege then
    raise notice 'Skipping storage policies (insufficient_privilege).';
end;
$$;

create or replace function public.app_validate_producto_imagen_storage_object()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_size bigint := 0;
  v_mime text := '';
begin
  if new.bucket_id <> 'producto_imagenes' then
    return new;
  end if;

  v_mime := coalesce(
    new.metadata ->> 'mimetype',
    new.metadata ->> 'contentType',
    new.metadata ->> 'content-type',
    new.metadata ->> 'type',
    ''
  );

  if v_mime = '' or v_mime not like 'image/%' then
    raise exception 'Solo se permiten imágenes';
  end if;

  begin
    v_size := coalesce((new.metadata ->> 'size')::bigint, 0);
  exception
    when others then
      v_size := 0;
  end;

  if v_size > 5242880 then
    raise exception 'La imagen excede el límite de 5MB';
  end if;

  return new;
end;
$$;

do $$
begin
  drop trigger if exists trg_validate_producto_imagenes on storage.objects;
  create trigger trg_validate_producto_imagenes
  before insert or update on storage.objects
  for each row execute function public.app_validate_producto_imagen_storage_object();
exception
  when insufficient_privilege then
    raise notice 'Skipping storage trigger (insufficient_privilege).';
end;
$$;
