-- Keep the company address fields synchronized and present in every read.

alter table public.empresas
  add column if not exists calle text not null default '',
  add column if not exists apartamento_suite text not null default '',
  add column if not exists ciudad text not null default '',
  add column if not exists estado_provincia text not null default '',
  add column if not exists codigo_postal text not null default '',
  add column if not exists pais text not null default '';

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
    'calle', e.calle,
    'apartamento_suite', e.apartamento_suite,
    'ciudad', e.ciudad,
    'estado_provincia', e.estado_provincia,
    'codigo_postal', e.codigo_postal,
    'pais', e.pais,
    'telefono', e.telefono,
    'correo', e.correo,
    'sitio_web', e.sitio_web,
    'color_primario', e.color_primario,
    'color_secundario', e.color_secundario,
    'color_fondo', e.color_fondo,
    'color_neutro', e.color_neutro,
    'theme_seleccionado', e.theme_seleccionado,
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
    'diseno_quote', jsonb_build_object(
      'preset_diseno', coalesce(
        edq.preset_diseno,
        e.theme_seleccionado,
        'corporativo'
      ),
      'orientacion_pagina', coalesce(edq.orientacion_pagina, 'Retrato'),
      'page_size', coalesce(edq.page_size, 'A4'),
      'font_size', coalesce(edq.font_size, 18),
      'logo_size_mode', coalesce(edq.logo_size_mode, 'Porcentaje'),
      'logo_size_value', coalesce(edq.logo_size_value, 24),
      'fuente_primaria', coalesce(edq.fuente_primaria, 'Arimo'),
      'fuente_secundaria', coalesce(edq.fuente_secundaria, 'Arimo'),
      'show_paid_stamp', coalesce(edq.show_paid_stamp, false),
      'show_shipping_address', coalesce(edq.show_shipping_address, false),
      'embed_attachments', coalesce(edq.embed_attachments, false),
      'empty_columns_mode', coalesce(edq.empty_columns_mode, 'Espectaculo'),
      'show_page_number', coalesce(edq.show_page_number, false)
    ),
    'impuestos', jsonb_build_object(
      'tasas_linea', '',
      'impuestos_sobre_gastos', '',
      'impuestos_inclusivos', '',
      'tasa_predeterminada', coalesce(eic.tasa_predeterminada, ''),
      'tasas', coalesce(eti.tasas, '[]'::jsonb)
    )
  )
  into v_payload
  from public.empresas e
  left join public.empresa_localizacion el on el.empresa_id = e.id
  left join public.empresa_impuestos_config eic on eic.empresa_id = e.id
  left join public.empresa_diseno_documentos edq
    on edq.empresa_id = e.id
   and edq.tipo_documento = 'quote'
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'id', t.id,
        'nombre', t.nombre,
        'porcentaje', t.porcentaje
      )
      order by t.updated_at desc, t.created_at desc
    ) as tasas
    from public.empresa_tasas_impuesto t
    where t.empresa_id = e.id
      and t.activo = true
  ) eti on true
  where e.id = v_empresa_id;

  return coalesce(v_payload, '{}'::jsonb);
end;
$$;

create or replace function public.update_empresa_datos_actual(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_direccion text;
begin
  perform public.app_require_company_access(v_empresa_id);

  v_direccion := concat_ws(
    ', ',
    nullif(btrim(coalesce(p_payload ->> 'calle', '')), ''),
    nullif(btrim(coalesce(p_payload ->> 'apartamento_suite', '')), ''),
    nullif(btrim(coalesce(p_payload ->> 'ciudad', '')), ''),
    nullif(btrim(coalesce(p_payload ->> 'estado_provincia', '')), ''),
    nullif(btrim(coalesce(p_payload ->> 'codigo_postal', '')), ''),
    nullif(btrim(coalesce(p_payload ->> 'pais', '')), '')
  );

  update public.empresas
  set logo_url = coalesce(p_payload ->> 'logo_url', logo_url),
      nombre_fiscal = coalesce(p_payload ->> 'nombre_fiscal', nombre_fiscal),
      nombre_comercial = coalesce(
        p_payload ->> 'nombre_comercial',
        nombre_comercial
      ),
      rfc = coalesce(p_payload ->> 'rfc', rfc),
      calle = coalesce(p_payload ->> 'calle', calle),
      apartamento_suite = coalesce(
        p_payload ->> 'apartamento_suite',
        apartamento_suite
      ),
      ciudad = coalesce(p_payload ->> 'ciudad', ciudad),
      estado_provincia = coalesce(
        p_payload ->> 'estado_provincia',
        estado_provincia
      ),
      codigo_postal = coalesce(p_payload ->> 'codigo_postal', codigo_postal),
      pais = coalesce(p_payload ->> 'pais', pais),
      direccion = case
        when p_payload ? 'calle'
          or p_payload ? 'apartamento_suite'
          or p_payload ? 'ciudad'
          or p_payload ? 'estado_provincia'
          or p_payload ? 'codigo_postal'
          or p_payload ? 'pais'
        then v_direccion
        else coalesce(p_payload ->> 'direccion', direccion)
      end,
      telefono = coalesce(p_payload ->> 'telefono', telefono),
      correo = coalesce(p_payload ->> 'correo', correo),
      sitio_web = coalesce(p_payload ->> 'sitio_web', sitio_web),
      updated_at = timezone('utc', now())
  where id = v_empresa_id;

  if not found then
    raise exception 'No se encontró la empresa actual';
  end if;

  return v_empresa_id;
end;
$$;

grant execute on function public.get_empresa_actual() to authenticated;
grant execute on function public.update_empresa_datos_actual(jsonb)
to authenticated;
