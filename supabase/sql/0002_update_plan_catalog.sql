alter table public.planes
  add column if not exists billing_mode text not null default 'flat_monthly',
  add column if not exists precio_por_usuario numeric(14,2) not null default 0,
  add column if not exists usuarios_minimos integer not null default 0,
  add column if not exists usuarios_maximos integer not null default 0;

update public.planes
set
  nombre = 'Starter',
  precio_mensual = 0,
  billing_mode = 'flat_monthly',
  precio_por_usuario = 0,
  descripcion = '20 clientes, 20 productos/servicios, 10 cotizaciones por mes, 1 usuario y 1 empresa.',
  limite_clientes = 20,
  limite_productos = 20,
  limite_cotizaciones_mensuales = 10,
  limite_usuarios = 1,
  limite_empresas = 1,
  usuarios_minimos = 0,
  usuarios_maximos = 0,
  incluye_ingresos_gastos = false,
  incluye_dashboard = false,
  incluye_personalizacion_pdf = false,
  incluye_notas_privadas = false,
  incluye_estados_cotizacion = false,
  incluye_marca_agua = true,
  activo = true
where id = 'starter';

update public.planes
set
  nombre = 'Pro',
  precio_mensual = 149,
  billing_mode = 'flat_monthly',
  precio_por_usuario = 0,
  descripcion = 'Clientes, productos y cotizaciones ilimitadas, 1 usuario, 1 empresa, ingresos y gastos.',
  limite_clientes = -1,
  limite_productos = -1,
  limite_cotizaciones_mensuales = -1,
  limite_usuarios = 1,
  limite_empresas = 1,
  usuarios_minimos = 0,
  usuarios_maximos = 0,
  incluye_ingresos_gastos = true,
  incluye_dashboard = true,
  incluye_personalizacion_pdf = true,
  incluye_notas_privadas = true,
  incluye_estados_cotizacion = true,
  incluye_marca_agua = false,
  activo = true
where id = 'pro';

update public.planes
set
  nombre = 'Empresa',
  precio_mensual = 0,
  billing_mode = 'per_user_monthly',
  precio_por_usuario = 99,
  descripcion = 'Plan multiusuario de 2 a 50 usuarios, multiempresa hasta 5 empresas y soporte prioritario.',
  limite_clientes = -1,
  limite_productos = -1,
  limite_cotizaciones_mensuales = -1,
  limite_usuarios = 50,
  limite_empresas = 5,
  usuarios_minimos = 2,
  usuarios_maximos = 50,
  incluye_ingresos_gastos = true,
  incluye_dashboard = true,
  incluye_personalizacion_pdf = true,
  incluye_notas_privadas = true,
  incluye_estados_cotizacion = true,
  incluye_marca_agua = false,
  activo = true
where id = 'empresa';

insert into public.planes (
  id, nombre, precio_mensual, billing_mode, precio_por_usuario, descripcion,
  limite_clientes, limite_productos, limite_cotizaciones_mensuales,
  limite_usuarios, limite_empresas, usuarios_minimos, usuarios_maximos,
  incluye_ingresos_gastos, incluye_dashboard, incluye_personalizacion_pdf,
  incluye_notas_privadas, incluye_estados_cotizacion, incluye_marca_agua, activo
) values
('starter', 'Starter', 0, 'flat_monthly', 0, '20 clientes, 20 productos/servicios, 10 cotizaciones por mes, 1 usuario y 1 empresa.', 20, 20, 10, 1, 1, 0, 0, false, false, false, false, false, true, true),
('pro', 'Pro', 149, 'flat_monthly', 0, 'Clientes, productos y cotizaciones ilimitadas, 1 usuario, 1 empresa, ingresos y gastos.', -1, -1, -1, 1, 1, 0, 0, true, true, true, true, true, false, true),
('empresa', 'Empresa', 0, 'per_user_monthly', 99, 'Plan multiusuario de 2 a 50 usuarios, multiempresa hasta 5 empresas y soporte prioritario.', -1, -1, -1, 50, 5, 2, 50, true, true, true, true, true, false, true)
on conflict (id) do update set
  nombre = excluded.nombre,
  precio_mensual = excluded.precio_mensual,
  billing_mode = excluded.billing_mode,
  precio_por_usuario = excluded.precio_por_usuario,
  descripcion = excluded.descripcion,
  limite_clientes = excluded.limite_clientes,
  limite_productos = excluded.limite_productos,
  limite_cotizaciones_mensuales = excluded.limite_cotizaciones_mensuales,
  limite_usuarios = excluded.limite_usuarios,
  limite_empresas = excluded.limite_empresas,
  usuarios_minimos = excluded.usuarios_minimos,
  usuarios_maximos = excluded.usuarios_maximos,
  incluye_ingresos_gastos = excluded.incluye_ingresos_gastos,
  incluye_dashboard = excluded.incluye_dashboard,
  incluye_personalizacion_pdf = excluded.incluye_personalizacion_pdf,
  incluye_notas_privadas = excluded.incluye_notas_privadas,
  incluye_estados_cotizacion = excluded.incluye_estados_cotizacion,
  incluye_marca_agua = excluded.incluye_marca_agua,
  activo = excluded.activo;

create or replace function public.list_planes()
returns setof public.planes
language sql
security definer
set search_path = public
as $$
  select p.*
  from public.planes p
  where p.activo = true
  order by
    case p.id
      when 'starter' then 1
      when 'pro' then 2
      when 'empresa' then 3
      else 99
    end,
    p.precio_mensual asc,
    p.precio_por_usuario asc;
$$;

grant execute on function public.list_planes() to authenticated;
