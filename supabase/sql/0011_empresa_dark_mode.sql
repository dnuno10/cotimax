alter table public.empresas
  add column if not exists modo_oscuro boolean not null default false;

create or replace function public.get_empresa_actual()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_payload jsonb;
begin
  perform public.app_require_company_access(v_empresa_id);

  select jsonb_build_object(
    'id', e.id,
    'logo_url', e.logo_url,
    'nombre_fiscal', e.nombre_fiscal,
    'nombre_comercial', e.nombre_comercial,
    'rfc', e.rfc,
    'direccion', e.direccion,
    'telefono', e.telefono,
    'correo', e.correo,
    'sitio_web', e.sitio_web,
    'color_primario', e.color_primario,
    'color_secundario', e.color_secundario,
    'color_fondo', e.color_fondo,
    'color_neutro', e.color_neutro,
    'theme_seleccionado', e.theme_seleccionado,
    'modo_oscuro', e.modo_oscuro,
    'notas_default', e.notas_default,
    'notas_privadas_default', e.notas_privadas_default,
    'terminos_default', e.terminos_default,
    'pie_pagina_default', e.pie_pagina_default,
    'created_at', e.created_at,
    'updated_at', e.updated_at,
    'localizacion', jsonb_build_object(
      'moneda', coalesce(el.moneda, 'MXN'),
      'idioma', coalesce(el.idioma, 'es-MX'),
      'huso_horario', coalesce(el.huso_horario, 'America/Tijuana'),
      'formato_fecha', coalesce(el.formato_fecha, 'dd/MM/yyyy'),
      'formato_moneda', coalesce(el.formato_moneda, '1,000.00 MXN')
    ),
    'impuestos', jsonb_build_object(
      'tasas_linea', coalesce(eic.tasas_linea, ''),
      'impuestos_sobre_gastos', coalesce(eic.impuestos_sobre_gastos, ''),
      'impuestos_inclusivos', coalesce(eic.impuestos_inclusivos, ''),
      'tasa_predeterminada', coalesce(eic.tasa_predeterminada, '')
    )
  )
  into v_payload
  from public.empresas e
  left join public.empresa_localizacion el on el.empresa_id = e.id
  left join public.empresa_impuestos_config eic on eic.empresa_id = e.id
  where e.id = v_empresa_id;

  return coalesce(v_payload, '{}'::jsonb);
end;
$$;

create or replace function public.update_empresa_actual(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
begin
  perform public.app_require_company_access(v_empresa_id);

  update public.empresas
  set logo_url = coalesce(p_payload ->> 'logo_url', logo_url),
      nombre_fiscal = coalesce(p_payload ->> 'nombre_fiscal', nombre_fiscal),
      nombre_comercial = coalesce(p_payload ->> 'nombre_comercial', nombre_comercial),
      rfc = coalesce(p_payload ->> 'rfc', rfc),
      direccion = coalesce(p_payload ->> 'direccion', direccion),
      telefono = coalesce(p_payload ->> 'telefono', telefono),
      correo = coalesce(p_payload ->> 'correo', correo),
      sitio_web = coalesce(p_payload ->> 'sitio_web', sitio_web),
      color_primario = coalesce(p_payload ->> 'color_primario', color_primario),
      color_secundario = coalesce(p_payload ->> 'color_secundario', color_secundario),
      color_fondo = coalesce(p_payload ->> 'color_fondo', color_fondo),
      color_neutro = coalesce(p_payload ->> 'color_neutro', color_neutro),
      theme_seleccionado = coalesce(p_payload ->> 'theme_seleccionado', theme_seleccionado),
      modo_oscuro = coalesce((p_payload ->> 'modo_oscuro')::boolean, modo_oscuro),
      notas_default = coalesce(p_payload ->> 'notas_default', notas_default),
      notas_privadas_default = coalesce(
        p_payload ->> 'notas_privadas_default',
        notas_privadas_default
      ),
      terminos_default = coalesce(p_payload ->> 'terminos_default', terminos_default),
      pie_pagina_default = coalesce(p_payload ->> 'pie_pagina_default', pie_pagina_default)
  where id = v_empresa_id;

  insert into public.empresa_localizacion (
    empresa_id, moneda, idioma, huso_horario, formato_fecha, formato_moneda
  )
  values (
    v_empresa_id,
    coalesce(p_payload #>> '{localizacion,moneda}', 'MXN'),
    coalesce(p_payload #>> '{localizacion,idioma}', 'es-MX'),
    coalesce(p_payload #>> '{localizacion,huso_horario}', 'America/Tijuana'),
    coalesce(p_payload #>> '{localizacion,formato_fecha}', 'dd/MM/yyyy'),
    coalesce(p_payload #>> '{localizacion,formato_moneda}', '1,000.00 MXN')
  )
  on conflict (empresa_id) do update set
    moneda = excluded.moneda,
    idioma = excluded.idioma,
    huso_horario = excluded.huso_horario,
    formato_fecha = excluded.formato_fecha,
    formato_moneda = excluded.formato_moneda;

  insert into public.empresa_impuestos_config (
    empresa_id, tasas_linea, impuestos_sobre_gastos, impuestos_inclusivos, tasa_predeterminada
  )
  values (
    v_empresa_id,
    coalesce(p_payload #>> '{impuestos,tasas_linea}', ''),
    coalesce(p_payload #>> '{impuestos,impuestos_sobre_gastos}', ''),
    coalesce(p_payload #>> '{impuestos,impuestos_inclusivos}', ''),
    coalesce(p_payload #>> '{impuestos,tasa_predeterminada}', '')
  )
  on conflict (empresa_id) do update set
    tasas_linea = excluded.tasas_linea,
    impuestos_sobre_gastos = excluded.impuestos_sobre_gastos,
    impuestos_inclusivos = excluded.impuestos_inclusivos,
    tasa_predeterminada = excluded.tasa_predeterminada;

  return v_empresa_id;
end;
$$;
