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
      'preset_diseno', coalesce(edq.preset_diseno, e.theme_seleccionado, 'corporativo'),
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

create or replace function public.update_empresa_actual(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_tasa jsonb;
  v_tasa_id uuid;
  v_tasa_ids uuid[] := '{}'::uuid[];
  v_default_tax_name text := coalesce(p_payload #>> '{impuestos,tasa_predeterminada}', '');
  v_quote jsonb := coalesce(p_payload -> 'diseno_quote', '{}'::jsonb);
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
    '',
    '',
    '',
    v_default_tax_name
  )
  on conflict (empresa_id) do update set
    tasas_linea = '',
    impuestos_sobre_gastos = '',
    impuestos_inclusivos = '',
    tasa_predeterminada = excluded.tasa_predeterminada;

  if jsonb_typeof(p_payload #> '{impuestos,tasas}') = 'array' then
    for v_tasa in
      select value
      from jsonb_array_elements(p_payload #> '{impuestos,tasas}')
    loop
      if trim(coalesce(v_tasa ->> 'nombre', '')) = '' then
        continue;
      end if;

      v_tasa_id := coalesce(
        public.app_parse_uuid(v_tasa ->> 'id'),
        gen_random_uuid()
      );
      v_tasa_ids := array_append(v_tasa_ids, v_tasa_id);

      insert into public.empresa_tasas_impuesto (
        id,
        empresa_id,
        nombre,
        porcentaje,
        tipo,
        aplica_a,
        inclusivo,
        predeterminada,
        activo
      )
      values (
        v_tasa_id,
        v_empresa_id,
        trim(coalesce(v_tasa ->> 'nombre', '')),
        coalesce((v_tasa ->> 'porcentaje')::numeric, 0),
        'traslado',
        'general',
        false,
        trim(coalesce(v_tasa ->> 'nombre', '')) = v_default_tax_name,
        true
      )
      on conflict (id) do update set
        nombre = excluded.nombre,
        porcentaje = excluded.porcentaje,
        tipo = excluded.tipo,
        aplica_a = excluded.aplica_a,
        inclusivo = excluded.inclusivo,
        predeterminada = excluded.predeterminada,
        activo = excluded.activo;
    end loop;

    delete from public.empresa_tasas_impuesto
    where empresa_id = v_empresa_id
      and not (id = any(v_tasa_ids));

    update public.empresa_tasas_impuesto
    set predeterminada = (nombre = v_default_tax_name)
    where empresa_id = v_empresa_id;
  end if;

  if jsonb_typeof(v_quote) = 'object' then
    insert into public.empresa_diseno_documentos (
      empresa_id,
      tipo_documento,
      preset_diseno,
      orientacion_pagina,
      page_size,
      font_size,
      logo_size_mode,
      logo_size_value,
      fuente_primaria,
      color_primario,
      fuente_secundaria,
      color_secundario,
      show_paid_stamp,
      show_shipping_address,
      embed_attachments,
      empty_columns_mode,
      show_page_number,
      show_client_summary
    )
    values (
      v_empresa_id,
      'quote',
      coalesce(v_quote ->> 'preset_diseno', 'corporativo'),
      coalesce(v_quote ->> 'orientacion_pagina', 'Retrato'),
      coalesce(v_quote ->> 'page_size', 'A4'),
      coalesce((nullif(v_quote ->> 'font_size', ''))::integer, 18),
      coalesce(v_quote ->> 'logo_size_mode', 'Porcentaje'),
      coalesce((nullif(v_quote ->> 'logo_size_value', ''))::numeric, 24),
      coalesce(v_quote ->> 'fuente_primaria', 'Arimo'),
      coalesce(p_payload ->> 'color_primario', '000000'),
      coalesce(v_quote ->> 'fuente_secundaria', 'Arimo'),
      coalesce(p_payload ->> 'color_secundario', 'F8B142'),
      coalesce((nullif(v_quote ->> 'show_paid_stamp', ''))::boolean, false),
      coalesce((nullif(v_quote ->> 'show_shipping_address', ''))::boolean, false),
      coalesce((nullif(v_quote ->> 'embed_attachments', ''))::boolean, false),
      coalesce(v_quote ->> 'empty_columns_mode', 'Espectaculo'),
      coalesce((nullif(v_quote ->> 'show_page_number', ''))::boolean, false),
      true
    )
    on conflict (empresa_id, tipo_documento) do update set
      preset_diseno = coalesce(v_quote ->> 'preset_diseno', empresa_diseno_documentos.preset_diseno),
      orientacion_pagina = coalesce(v_quote ->> 'orientacion_pagina', empresa_diseno_documentos.orientacion_pagina),
      page_size = coalesce(v_quote ->> 'page_size', empresa_diseno_documentos.page_size),
      font_size = coalesce((nullif(v_quote ->> 'font_size', ''))::integer, empresa_diseno_documentos.font_size),
      logo_size_mode = coalesce(v_quote ->> 'logo_size_mode', empresa_diseno_documentos.logo_size_mode),
      logo_size_value = coalesce((nullif(v_quote ->> 'logo_size_value', ''))::numeric, empresa_diseno_documentos.logo_size_value),
      fuente_primaria = coalesce(v_quote ->> 'fuente_primaria', empresa_diseno_documentos.fuente_primaria),
      fuente_secundaria = coalesce(v_quote ->> 'fuente_secundaria', empresa_diseno_documentos.fuente_secundaria),
      show_paid_stamp = coalesce((nullif(v_quote ->> 'show_paid_stamp', ''))::boolean, empresa_diseno_documentos.show_paid_stamp),
      show_shipping_address = coalesce((nullif(v_quote ->> 'show_shipping_address', ''))::boolean, empresa_diseno_documentos.show_shipping_address),
      embed_attachments = coalesce((nullif(v_quote ->> 'embed_attachments', ''))::boolean, empresa_diseno_documentos.embed_attachments),
      empty_columns_mode = coalesce(v_quote ->> 'empty_columns_mode', empresa_diseno_documentos.empty_columns_mode),
      show_page_number = coalesce((nullif(v_quote ->> 'show_page_number', ''))::boolean, empresa_diseno_documentos.show_page_number);
  end if;

  return v_empresa_id;
end;
$$;
