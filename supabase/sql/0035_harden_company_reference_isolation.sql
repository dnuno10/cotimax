create or replace function public.app_validate_company_reference(
  p_empresa_id uuid,
  p_related_id uuid,
  p_related_table regclass,
  p_reference_label text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_exists boolean := false;
begin
  if p_related_id is null then
    return;
  end if;

  execute format(
    'select exists (select 1 from %s where id = $1 and empresa_id = $2)',
    p_related_table
  )
  into v_exists
  using p_related_id, p_empresa_id;

  if not v_exists then
    raise exception '% no pertenece a la empresa activa', p_reference_label;
  end if;
end;
$$;

create or replace function public.app_enforce_materiales_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.proveedor_id,
    'public.proveedores',
    'proveedor_id'
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_materiales_empresa_refs on public.materiales_insumos;
create trigger trg_enforce_materiales_empresa_refs
before insert or update on public.materiales_insumos
for each row execute function public.app_enforce_materiales_empresa_refs();

create or replace function public.app_enforce_productos_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.categoria_producto_id,
    'public.categorias_producto',
    'categoria_producto_id'
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_productos_empresa_refs on public.productos_servicios;
create trigger trg_enforce_productos_empresa_refs
before insert or update on public.productos_servicios
for each row execute function public.app_enforce_productos_empresa_refs();

create or replace function public.app_enforce_producto_componentes_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select p.empresa_id into v_empresa_id
  from public.productos_servicios p
  where p.id = new.producto_id;

  if v_empresa_id is null then
    raise exception 'producto_id no valido para componente';
  end if;

  perform public.app_validate_company_reference(
    v_empresa_id,
    new.material_id,
    'public.materiales_insumos',
    'material_id'
  );

  return new;
end;
$$;

drop trigger if exists trg_enforce_producto_componentes_empresa_refs on public.producto_componentes;
create trigger trg_enforce_producto_componentes_empresa_refs
before insert or update on public.producto_componentes
for each row execute function public.app_enforce_producto_componentes_empresa_refs();

create or replace function public.app_enforce_cotizaciones_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.cliente_id,
    'public.clientes',
    'cliente_id'
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_cotizaciones_empresa_refs on public.cotizaciones;
create trigger trg_enforce_cotizaciones_empresa_refs
before insert or update on public.cotizaciones
for each row execute function public.app_enforce_cotizaciones_empresa_refs();

create or replace function public.app_enforce_cotizacion_detalles_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  select c.empresa_id into v_empresa_id
  from public.cotizaciones c
  where c.id = new.cotizacion_id;

  if v_empresa_id is null then
    raise exception 'cotizacion_id no valido para detalle';
  end if;

  perform public.app_validate_company_reference(
    v_empresa_id,
    new.producto_servicio_id,
    'public.productos_servicios',
    'producto_servicio_id'
  );

  return new;
end;
$$;

drop trigger if exists trg_enforce_cotizacion_detalles_empresa_refs on public.cotizacion_detalles;
create trigger trg_enforce_cotizacion_detalles_empresa_refs
before insert or update on public.cotizacion_detalles
for each row execute function public.app_enforce_cotizacion_detalles_empresa_refs();

create or replace function public.app_enforce_ingresos_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.cliente_id,
    'public.clientes',
    'cliente_id'
  );
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.cotizacion_id,
    'public.cotizaciones',
    'cotizacion_id'
  );
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.ingreso_categoria_id,
    'public.ingreso_categorias',
    'ingreso_categoria_id'
  );
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.gasto_fuente_id,
    'public.gastos',
    'gasto_fuente_id'
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_ingresos_empresa_refs on public.ingresos;
create trigger trg_enforce_ingresos_empresa_refs
before insert or update on public.ingresos
for each row execute function public.app_enforce_ingresos_empresa_refs();

create or replace function public.app_enforce_ingresos_recurrentes_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.cliente_id,
    'public.clientes',
    'cliente_id'
  );
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.cotizacion_id,
    'public.cotizaciones',
    'cotizacion_id'
  );
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.ingreso_categoria_id,
    'public.ingreso_categorias',
    'ingreso_categoria_id'
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_ingresos_recurrentes_empresa_refs on public.ingresos_recurrentes;
create trigger trg_enforce_ingresos_recurrentes_empresa_refs
before insert or update on public.ingresos_recurrentes
for each row execute function public.app_enforce_ingresos_recurrentes_empresa_refs();

create or replace function public.app_enforce_gastos_recurrentes_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.gasto_categoria_id,
    'public.gasto_categorias',
    'gasto_categoria_id'
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_gastos_recurrentes_empresa_refs on public.gastos_recurrentes;
create trigger trg_enforce_gastos_recurrentes_empresa_refs
before insert or update on public.gastos_recurrentes
for each row execute function public.app_enforce_gastos_recurrentes_empresa_refs();

create or replace function public.app_enforce_gastos_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.gasto_categoria_id,
    'public.gasto_categorias',
    'gasto_categoria_id'
  );
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.proveedor_id,
    'public.proveedores',
    'proveedor_id'
  );
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.gasto_recurrente_id,
    'public.gastos_recurrentes',
    'gasto_recurrente_id'
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_gastos_empresa_refs on public.gastos;
create trigger trg_enforce_gastos_empresa_refs
before insert or update on public.gastos
for each row execute function public.app_enforce_gastos_empresa_refs();

create or replace function public.app_enforce_recordatorios_empresa_refs()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.cliente_id,
    'public.clientes',
    'cliente_id'
  );
  perform public.app_validate_company_reference(
    new.empresa_id,
    new.cotizacion_id,
    'public.cotizaciones',
    'cotizacion_id'
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_recordatorios_empresa_refs on public.recordatorios;
create trigger trg_enforce_recordatorios_empresa_refs
before insert or update on public.recordatorios
for each row execute function public.app_enforce_recordatorios_empresa_refs();
