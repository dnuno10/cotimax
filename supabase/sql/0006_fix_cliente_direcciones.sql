drop function if exists public.list_clientes(text);

create or replace function public.list_clientes(p_query text default '')
returns table (
  id uuid,
  empresa_id uuid,
  nombre text,
  empresa text,
  contacto text,
  numero text,
  id_number text,
  rfc_cif_nif text,
  sitio_web text,
  telefono text,
  correo text,
  direccion text,
  routing_number text,
  iva_valido boolean,
  exento_impuestos boolean,
  activo boolean,
  notas text,
  created_at timestamptz,
  updated_at timestamptz,
  deleted_at timestamptz,
  calle text,
  apartamento_suite text,
  ciudad text,
  estado_provincia text,
  codigo_postal text,
  pais text
)
language sql
security definer
set search_path = public
as $$
  select
    c.id,
    c.empresa_id,
    c.nombre,
    c.empresa,
    c.contacto,
    c.numero,
    c.id_number,
    c.rfc_cif_nif,
    c.sitio_web,
    c.telefono,
    c.correo,
    coalesce(
      nullif(c.direccion, ''),
      concat_ws(
        ', ',
        nullif(d.calle, ''),
        nullif(d.apartamento_suite, ''),
        nullif(d.ciudad, ''),
        nullif(d.estado_provincia, ''),
        nullif(d.codigo_postal, ''),
        nullif(d.pais, '')
      )
    ) as direccion,
    c.routing_number,
    c.iva_valido,
    c.exento_impuestos,
    c.activo,
    c.notas,
    c.created_at,
    c.updated_at,
    c.deleted_at,
    coalesce(d.calle, '') as calle,
    coalesce(d.apartamento_suite, '') as apartamento_suite,
    coalesce(d.ciudad, '') as ciudad,
    coalesce(d.estado_provincia, '') as estado_provincia,
    coalesce(d.codigo_postal, '') as codigo_postal,
    coalesce(d.pais, '') as pais
  from public.clientes c
  left join lateral (
    select
      cd.calle,
      cd.apartamento_suite,
      cd.ciudad,
      cd.estado_provincia,
      cd.codigo_postal,
      cd.pais
    from public.cliente_direcciones cd
    where cd.cliente_id = c.id
    order by cd.es_principal desc, cd.updated_at desc, cd.created_at desc
    limit 1
  ) d on true
  where c.deleted_at is null
    and public.app_can_access_empresa(c.empresa_id)
    and (
      coalesce(p_query, '') = ''
      or lower(c.nombre) like '%' || lower(p_query) || '%'
      or lower(c.empresa) like '%' || lower(p_query) || '%'
      or lower(c.rfc_cif_nif) like '%' || lower(p_query) || '%'
    )
  order by c.updated_at desc;
$$;

create or replace function public.upsert_cliente(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_id uuid := coalesce(public.app_parse_uuid(p_payload ->> 'id'), gen_random_uuid());
  v_contacto_id uuid;
  v_direccion_id uuid;
  v_calle text := coalesce(p_payload ->> 'calle', '');
  v_apartamento_suite text := coalesce(p_payload ->> 'apartamento_suite', '');
  v_ciudad text := coalesce(p_payload ->> 'ciudad', '');
  v_estado_provincia text := coalesce(p_payload ->> 'estado_provincia', '');
  v_codigo_postal text := coalesce(p_payload ->> 'codigo_postal', '');
  v_pais text := coalesce(p_payload ->> 'pais', '');
  v_direccion text := coalesce(
    nullif(p_payload ->> 'direccion', ''),
    concat_ws(
      ', ',
      nullif(v_calle, ''),
      nullif(v_apartamento_suite, ''),
      nullif(v_ciudad, ''),
      nullif(v_estado_provincia, ''),
      nullif(v_codigo_postal, ''),
      nullif(v_pais, '')
    )
  );
begin
  perform public.app_require_company_access(v_empresa_id);

  insert into public.clientes (
    id, empresa_id, numero, id_number, nombre, empresa, contacto, rfc_cif_nif,
    telefono, correo, direccion, notas, activo
  )
  values (
    v_id, v_empresa_id,
    coalesce(p_payload ->> 'numero', ''),
    coalesce(p_payload ->> 'id_number', ''),
    coalesce(p_payload ->> 'nombre', ''),
    coalesce(p_payload ->> 'empresa', ''),
    coalesce(p_payload ->> 'contacto', ''),
    coalesce(p_payload ->> 'rfc_cif_nif', ''),
    coalesce(p_payload ->> 'telefono', ''),
    coalesce(p_payload ->> 'correo', ''),
    coalesce(v_direccion, ''),
    coalesce(p_payload ->> 'notas', ''),
    coalesce((p_payload ->> 'activo')::boolean, true)
  )
  on conflict (id) do update set
    numero = excluded.numero,
    id_number = excluded.id_number,
    nombre = excluded.nombre,
    empresa = excluded.empresa,
    contacto = excluded.contacto,
    rfc_cif_nif = excluded.rfc_cif_nif,
    telefono = excluded.telefono,
    correo = excluded.correo,
    direccion = excluded.direccion,
    notas = excluded.notas,
    activo = excluded.activo;

  if coalesce(p_payload ->> 'contacto', '') <> '' then
    select cc.id into v_contacto_id
    from public.cliente_contactos cc
    where cc.cliente_id = v_id
      and cc.es_principal = true
    limit 1;

    if v_contacto_id is null then
      insert into public.cliente_contactos (
        cliente_id, nombres, correo, telefono, es_principal
      ) values (
        v_id, coalesce(p_payload ->> 'contacto', ''),
        coalesce(p_payload ->> 'correo', ''),
        coalesce(p_payload ->> 'telefono', ''),
        true
      );
    else
      update public.cliente_contactos
      set nombres = coalesce(p_payload ->> 'contacto', ''),
          correo = coalesce(p_payload ->> 'correo', ''),
          telefono = coalesce(p_payload ->> 'telefono', '')
      where id = v_contacto_id;
    end if;
  end if;

  select cd.id into v_direccion_id
  from public.cliente_direcciones cd
  where cd.cliente_id = v_id
  order by cd.es_principal desc, cd.updated_at desc, cd.created_at desc
  limit 1;

  if v_direccion_id is null then
    if v_calle <> ''
      or v_apartamento_suite <> ''
      or v_ciudad <> ''
      or v_estado_provincia <> ''
      or v_codigo_postal <> ''
      or v_pais <> '' then
      insert into public.cliente_direcciones (
        cliente_id,
        tipo,
        calle,
        apartamento_suite,
        ciudad,
        estado_provincia,
        codigo_postal,
        pais,
        es_principal
      )
      values (
        v_id,
        'envio',
        v_calle,
        v_apartamento_suite,
        v_ciudad,
        v_estado_provincia,
        v_codigo_postal,
        v_pais,
        true
      );
    end if;
  else
    update public.cliente_direcciones
    set tipo = 'envio',
        calle = v_calle,
        apartamento_suite = v_apartamento_suite,
        ciudad = v_ciudad,
        estado_provincia = v_estado_provincia,
        codigo_postal = v_codigo_postal,
        pais = v_pais,
        es_principal = true
    where id = v_direccion_id;
  end if;

  return v_id;
end;
$$;

grant execute on function public.list_clientes(text) to authenticated;
grant execute on function public.upsert_cliente(jsonb) to authenticated;
