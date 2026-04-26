create or replace function public.upsert_cotizacion(
  p_id uuid default null,
  p_cliente_id text default '',
  p_fecha_emision timestamptz default timezone('utc', now()),
  p_fecha_vencimiento timestamptz default timezone('utc', now()),
  p_deposito_parcial numeric default 0,
  p_folio text default '',
  p_orden_numero text default '',
  p_descuento_tipo text default '',
  p_descuento_valor numeric default 0,
  p_impuesto_porcentaje numeric default 0,
  p_ret_isr boolean default false,
  p_notas text default '',
  p_notas_privadas text default '',
  p_terminos text default '',
  p_pie_pagina text default '',
  p_estatus text default 'borrador',
  p_lineas jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_usuario_id uuid := auth.uid();
  v_id uuid := coalesce(p_id, gen_random_uuid());
  v_cliente_uuid uuid := public.app_parse_uuid(p_cliente_id);
  v_cliente_snapshot text := '';
  v_linea jsonb;
  v_subtotal numeric := 0;
  v_line_tax_total numeric := 0;
  v_subtotal_tax_total numeric := 0;
  v_impuesto_total numeric := 0;
  v_ret_isr_base numeric := 0;
  v_ret_isr_total numeric := 0;
  v_total numeric := 0;
  v_folio text := btrim(coalesce(p_folio, ''));
begin
  perform public.app_require_company_access(v_empresa_id);

  if v_cliente_uuid is not null then
    if not exists (
      select 1
      from public.clientes c
      where c.id = v_cliente_uuid
        and c.empresa_id = v_empresa_id
    ) then
      v_cliente_uuid := null;
      v_cliente_snapshot := p_cliente_id;
    end if;
  else
    v_cliente_snapshot := p_cliente_id;
  end if;

  for v_linea in
    select *
    from jsonb_array_elements(coalesce(p_lineas, '[]'::jsonb))
  loop
    v_subtotal := v_subtotal + coalesce((v_linea ->> 'importe')::numeric, 0);
    v_line_tax_total := v_line_tax_total + (
      coalesce((v_linea ->> 'importe')::numeric, 0)
      * coalesce((v_linea ->> 'impuesto_porcentaje')::numeric, 0) / 100
    );
  end loop;

  v_ret_isr_base := greatest(v_subtotal - coalesce(p_descuento_valor, 0), 0);
  v_subtotal_tax_total :=
    v_ret_isr_base * greatest(coalesce(p_impuesto_porcentaje, 0), 0) / 100;
  v_impuesto_total := v_line_tax_total + v_subtotal_tax_total;

  if coalesce(p_ret_isr, false) then
    v_ret_isr_total := v_ret_isr_base * 0.10;
  end if;

  v_total := v_ret_isr_base + v_impuesto_total - v_ret_isr_total;

  if v_folio = '' then
    v_folio := 'COT-' || to_char(current_date, 'YYYY') || '-' ||
      lpad((floor(random() * 9000) + 1000)::text, 4, '0');
  end if;

  insert into public.cotizaciones (
    id, empresa_id, usuario_id, cliente_id, cliente_nombre_snapshot, folio,
    fecha_emision, fecha_vencimiento, deposito_parcial, orden_numero,
    descuento_tipo, descuento_valor, impuesto_porcentaje, ret_isr, subtotal,
    descuento_total, impuesto_total, total, pagado_total, saldo_total, notas,
    notas_privadas, terminos, pie_pagina, estatus, moneda_codigo
  )
  values (
    v_id, v_empresa_id, v_usuario_id, v_cliente_uuid, v_cliente_snapshot, v_folio,
    p_fecha_emision::date, p_fecha_vencimiento::date, p_deposito_parcial,
    p_orden_numero, p_descuento_tipo, p_descuento_valor, p_impuesto_porcentaje,
    p_ret_isr, v_subtotal, p_descuento_valor, v_impuesto_total, v_total, 0,
    v_total, p_notas, p_notas_privadas, p_terminos, p_pie_pagina, p_estatus, 'MXN'
  )
  on conflict (id) do update set
    cliente_id = excluded.cliente_id,
    cliente_nombre_snapshot = excluded.cliente_nombre_snapshot,
    folio = excluded.folio,
    fecha_emision = excluded.fecha_emision,
    fecha_vencimiento = excluded.fecha_vencimiento,
    deposito_parcial = excluded.deposito_parcial,
    orden_numero = excluded.orden_numero,
    descuento_tipo = excluded.descuento_tipo,
    descuento_valor = excluded.descuento_valor,
    impuesto_porcentaje = excluded.impuesto_porcentaje,
    ret_isr = excluded.ret_isr,
    subtotal = excluded.subtotal,
    descuento_total = excluded.descuento_total,
    impuesto_total = excluded.impuesto_total,
    total = excluded.total,
    saldo_total = excluded.total - coalesce(cotizaciones.pagado_total, 0),
    notas = excluded.notas,
    notas_privadas = excluded.notas_privadas,
    terminos = excluded.terminos,
    pie_pagina = excluded.pie_pagina,
    estatus = excluded.estatus,
    updated_at = timezone('utc', now());

  delete from public.cotizacion_detalles
  where cotizacion_id = v_id;

  insert into public.cotizacion_detalles (
    cotizacion_id, producto_servicio_id, concepto, descripcion,
    precio_unitario, unidad, descuento, cantidad, impuesto_porcentaje,
    importe, orden
  )
  select
    v_id,
    public.app_parse_uuid(line_item.value ->> 'producto_servicio_id'),
    coalesce(line_item.value ->> 'concepto', ''),
    coalesce(line_item.value ->> 'descripcion', ''),
    coalesce((line_item.value ->> 'precio_unitario')::numeric, 0),
    coalesce(line_item.value ->> 'unidad', ''),
    coalesce((line_item.value ->> 'descuento')::numeric, 0),
    coalesce((line_item.value ->> 'cantidad')::numeric, 0),
    coalesce((line_item.value ->> 'impuesto_porcentaje')::numeric, 0),
    coalesce((line_item.value ->> 'importe')::numeric, 0),
    coalesce((line_item.value ->> 'orden')::int, 0)
  from jsonb_array_elements(coalesce(p_lineas, '[]'::jsonb)) as line_item(value);

  return v_id;
end;
$$;

grant execute on function public.upsert_cotizacion(
  uuid, text, timestamptz, timestamptz, numeric, text, text, text,
  numeric, numeric, boolean, text, text, text, text, text, jsonb
) to authenticated;
