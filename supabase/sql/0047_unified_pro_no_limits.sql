-- Unified Cotimax Pro access.
-- Plan/subscription rows remain as historical data, but no longer gate features.

insert into public.planes (
  id, nombre, precio_mensual, billing_mode, precio_por_usuario, descripcion,
  limite_clientes, limite_productos, limite_materiales,
  limite_cotizaciones_mensuales, limite_usuarios, limite_empresas,
  usuarios_minimos, usuarios_maximos, incluye_ingresos_gastos,
  incluye_dashboard, incluye_analitica, incluye_personalizacion_pdf,
  incluye_notas_privadas, incluye_estados_cotizacion, incluye_marca_agua,
  activo
) values (
  'pro', 'Cotimax Pro', 0, 'flat_monthly', 0,
  'Acceso completo sin límites de uso. Una empresa por cuenta.',
  -1, -1, -1, -1, -1, 1, 0, 0,
  true, true, true, true, true, true, false, true
)
on conflict (id) do update set
  nombre = excluded.nombre,
  precio_mensual = excluded.precio_mensual,
  billing_mode = excluded.billing_mode,
  precio_por_usuario = excluded.precio_por_usuario,
  descripcion = excluded.descripcion,
  limite_clientes = excluded.limite_clientes,
  limite_productos = excluded.limite_productos,
  limite_materiales = excluded.limite_materiales,
  limite_cotizaciones_mensuales = excluded.limite_cotizaciones_mensuales,
  limite_usuarios = excluded.limite_usuarios,
  limite_empresas = excluded.limite_empresas,
  usuarios_minimos = excluded.usuarios_minimos,
  usuarios_maximos = excluded.usuarios_maximos,
  incluye_ingresos_gastos = excluded.incluye_ingresos_gastos,
  incluye_dashboard = excluded.incluye_dashboard,
  incluye_analitica = excluded.incluye_analitica,
  incluye_personalizacion_pdf = excluded.incluye_personalizacion_pdf,
  incluye_notas_privadas = excluded.incluye_notas_privadas,
  incluye_estados_cotizacion = excluded.incluye_estados_cotizacion,
  incluye_marca_agua = excluded.incluye_marca_agua,
  activo = excluded.activo;

update public.planes
set limite_clientes = -1,
    limite_productos = -1,
    limite_materiales = -1,
    limite_cotizaciones_mensuales = -1,
    limite_usuarios = -1,
    limite_empresas = 1,
    incluye_ingresos_gastos = true,
    incluye_dashboard = true,
    incluye_analitica = true,
    incluye_personalizacion_pdf = true,
    incluye_notas_privadas = true,
    incluye_estados_cotizacion = true,
    incluye_marca_agua = false,
    activo = (id = 'pro');

update public.suscripciones
set plan_id = 'pro',
    estado = 'activa',
    renovacion_automatica = false,
    fecha_fin = greatest(fecha_fin, timezone('utc', now()) + interval '100 years'),
    updated_at = timezone('utc', now())
where plan_id <> 'pro'
   or estado <> 'activa'
   or renovacion_automatica
   or fecha_fin < timezone('utc', now()) + interval '100 years';

create or replace function public.list_planes()
returns setof public.planes
language sql
stable
security definer
set search_path = public
as $$
  select p.*
  from public.planes p
  where p.id = 'pro';
$$;

create or replace function public.app_seed_empresa_defaults(p_empresa_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_empresa_id is null then
    raise exception 'Empresa inválida';
  end if;

  insert into public.empresa_localizacion (empresa_id)
  values (p_empresa_id)
  on conflict (empresa_id) do nothing;

  insert into public.empresa_impuestos_config (empresa_id)
  values (p_empresa_id)
  on conflict (empresa_id) do nothing;

  if not exists (
    select 1
    from public.suscripciones s
    where s.empresa_id = p_empresa_id
  ) then
    insert into public.suscripciones (
      empresa_id,
      plan_id,
      estado,
      fecha_inicio,
      fecha_fin,
      renovacion_automatica,
      usuarios_activos
    ) values (
      p_empresa_id,
      'pro',
      'activa',
      timezone('utc', now()),
      timezone('utc', now()) + interval '100 years',
      false,
      1
    );
  else
    update public.suscripciones
    set plan_id = 'pro',
        estado = 'activa',
        renovacion_automatica = false,
        fecha_fin = greatest(
          fecha_fin,
          timezone('utc', now()) + interval '100 years'
        ),
        updated_at = timezone('utc', now())
    where empresa_id = p_empresa_id;
  end if;
end;
$$;

create or replace function public.app_ensure_user_workspace(
  p_user_id uuid,
  p_email text default null,
  p_nombre text default null,
  p_nombre_empresa text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
  v_email text := coalesce(nullif(btrim(coalesce(p_email, '')), ''), '');
  v_alias text := nullif(split_part(v_email, '@', 1), '');
  v_nombre text := coalesce(
    nullif(btrim(coalesce(p_nombre, '')), ''),
    initcap(replace(coalesce(v_alias, 'Usuario'), '.', ' ')),
    'Usuario'
  );
  v_nombre_empresa text := coalesce(
    nullif(btrim(coalesce(p_nombre_empresa, '')), ''),
    'Empresa de ' || v_nombre
  );
begin
  if p_user_id is null then
    raise exception 'Usuario inválido';
  end if;

  insert into public.usuarios (id, nombre, correo)
  values (p_user_id, v_nombre, v_email)
  on conflict (id) do update
  set correo = excluded.correo,
      nombre = case
        when coalesce(public.usuarios.nombre, '') = '' then excluded.nombre
        else public.usuarios.nombre
      end,
      updated_at = timezone('utc', now());

  select ue.empresa_id
  into v_empresa_id
  from public.usuario_empresas ue
  where ue.usuario_id = p_user_id
  order by ue.es_principal desc, ue.created_at asc
  limit 1;

  if v_empresa_id is null then
    insert into public.empresas (nombre_fiscal, nombre_comercial, correo)
    values (v_nombre_empresa, v_nombre_empresa, v_email)
    returning id into v_empresa_id;

    insert into public.usuario_empresas (
      usuario_id,
      empresa_id,
      es_principal,
      rol
    ) values (
      p_user_id,
      v_empresa_id,
      true,
      'admin'
    );
  end if;

  perform public.app_seed_empresa_defaults(v_empresa_id);
  return v_empresa_id;
end;
$$;

create or replace function public.app_plan_allows_product_images(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.app_can_access_empresa(p_empresa_id);
$$;

create or replace function public.app_user_max_empresas_allowed(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select 1;
$$;

-- Preserve legacy memberships, but prevent creating any new multi-company link.
create or replace function public.app_enforce_one_company_per_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1
    from public.usuario_empresas ue
    where ue.usuario_id = new.usuario_id
      and ue.empresa_id <> new.empresa_id
  ) then
    raise exception 'Cada cuenta solo puede estar asociada a una empresa';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_one_company_per_user on public.usuario_empresas;
create trigger enforce_one_company_per_user
before insert or update of usuario_id, empresa_id
on public.usuario_empresas
for each row execute function public.app_enforce_one_company_per_user();

create or replace function public.update_empresa_datos_actual(p_payload jsonb)
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
      calle = coalesce(p_payload ->> 'calle', calle),
      apartamento_suite = coalesce(p_payload ->> 'apartamento_suite', apartamento_suite),
      ciudad = coalesce(p_payload ->> 'ciudad', ciudad),
      estado_provincia = coalesce(p_payload ->> 'estado_provincia', estado_provincia),
      codigo_postal = coalesce(p_payload ->> 'codigo_postal', codigo_postal),
      pais = coalesce(p_payload ->> 'pais', pais),
      telefono = coalesce(p_payload ->> 'telefono', telefono),
      correo = coalesce(p_payload ->> 'correo', correo),
      sitio_web = coalesce(p_payload ->> 'sitio_web', sitio_web),
      updated_at = timezone('utc', now())
  where id = v_empresa_id;

  return v_empresa_id;
end;
$$;

grant execute on function public.update_empresa_datos_actual(jsonb) to authenticated;

create or replace function public.get_empresa_invitation_code()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_codigo text;
begin
  perform public.app_require_company_access(v_empresa_id);
  if not public.app_is_admin_for_empresa(v_empresa_id) then
    raise exception 'Solo un admin puede invitar miembros';
  end if;
  select codigo into v_codigo
  from public.empresa_invitaciones
  where empresa_id = v_empresa_id and activo = true
  limit 1;

  if v_codigo is null then
    v_codigo := public.app_generate_invitation_code();
    insert into public.empresa_invitaciones (
      empresa_id, codigo, created_by, activo
    ) values (
      v_empresa_id, v_codigo, auth.uid(), true
    );
  end if;

  return jsonb_build_object('empresa_id', v_empresa_id, 'codigo', v_codigo);
end;
$$;

create or replace function public.find_usuario_by_email_for_team_invite(p_email text)
returns table (id uuid, nombre text, correo text)
language sql
security definer
set search_path = public
as $$
  select u.id, u.nombre, u.correo
  from public.usuarios u
  where public.app_is_admin_for_empresa(public.app_current_empresa_id())
    and lower(u.correo) = lower(btrim(coalesce(p_email, '')))
    and u.activo = true
  limit 1;
$$;

create or replace function public.invite_usuario_by_email_to_current_empresa(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_user_id uuid;
  v_invite_id uuid;
begin
  perform public.app_require_company_access(v_empresa_id);
  if not public.app_is_admin_for_empresa(v_empresa_id) then
    raise exception 'Solo un admin puede invitar miembros';
  end if;
  if v_email = '' then
    raise exception 'Ingresa un correo válido';
  end if;

  select id into v_user_id
  from public.usuarios
  where lower(correo) = v_email and activo = true
  limit 1;

  if v_user_id is null then
    raise exception 'No encontramos un usuario activo con ese correo';
  end if;
  if v_user_id = auth.uid() then
    raise exception 'Tu cuenta ya pertenece a esta empresa';
  end if;
  if exists (select 1 from public.usuario_empresas where usuario_id = v_user_id) then
    raise exception 'Ese usuario ya está asociado a una empresa';
  end if;

  insert into public.empresa_invitaciones_miembros (
    empresa_id, invited_user_id, invited_email, invited_by, status
  ) values (
    v_empresa_id, v_user_id, v_email, auth.uid(), 'pendiente'
  )
  on conflict (empresa_id, invited_user_id) where status = 'pendiente'
  do update set
    invited_email = excluded.invited_email,
    invited_by = excluded.invited_by,
    updated_at = timezone('utc', now())
  returning id into v_invite_id;

  return jsonb_build_object(
    'invite_id', v_invite_id,
    'empresa_id', v_empresa_id,
    'invited_user_id', v_user_id
  );
end;
$$;

create or replace function public.respond_team_invite(
  p_invite_id uuid,
  p_action text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_action text := lower(btrim(coalesce(p_action, '')));
  v_invite public.empresa_invitaciones_miembros%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  select * into v_invite
  from public.empresa_invitaciones_miembros
  where id = p_invite_id
    and invited_user_id = auth.uid()
    and status = 'pendiente';

  if v_invite.id is null then
    raise exception 'Invitación no encontrada';
  end if;

  if v_action in ('aceptar', 'accept', 'accepted') then
    if exists (select 1 from public.usuario_empresas where usuario_id = auth.uid()) then
      raise exception 'Tu cuenta ya está asociada a una empresa';
    end if;

    insert into public.usuario_empresas (
      usuario_id, empresa_id, es_principal, rol
    ) values (
      auth.uid(), v_invite.empresa_id, true, 'usuario'
    );

    update public.empresa_invitaciones_miembros
    set status = 'aceptada',
        responded_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = v_invite.id;

    update public.empresa_invitaciones_miembros
    set status = 'rechazada',
        responded_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where invited_user_id = auth.uid()
      and status = 'pendiente'
      and id <> v_invite.id;

    return jsonb_build_object('status', 'aceptada', 'empresa_id', v_invite.empresa_id);
  end if;

  if v_action in ('rechazar', 'reject', 'decline') then
    update public.empresa_invitaciones_miembros
    set status = 'rechazada',
        responded_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = v_invite.id;

    return jsonb_build_object('status', 'rechazada', 'empresa_id', v_invite.empresa_id);
  end if;

  raise exception 'Acción inválida';
end;
$$;

create or replace function public.join_empresa_by_invitation_code(p_codigo text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;
  if exists (select 1 from public.usuario_empresas where usuario_id = auth.uid()) then
    raise exception 'Tu cuenta ya está asociada a una empresa';
  end if;

  select empresa_id into v_empresa_id
  from public.empresa_invitaciones
  where upper(btrim(codigo)) = upper(btrim(coalesce(p_codigo, '')))
    and activo = true
  limit 1;

  if v_empresa_id is null then
    raise exception 'Código de invitación inválido';
  end if;

  insert into public.usuario_empresas (
    usuario_id, empresa_id, es_principal, rol
  ) values (
    auth.uid(), v_empresa_id, true, 'usuario'
  );

  return jsonb_build_object('empresa_id', v_empresa_id);
end;
$$;

create or replace function public.create_empresa_inicial(
  p_nombre_comercial text,
  p_logo_url text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user auth.users%rowtype;
  v_empresa_id uuid;
  v_nombre text := nullif(btrim(coalesce(p_nombre_comercial, '')), '');
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;
  if v_nombre is null then
    raise exception 'Ingresa el nombre de la empresa';
  end if;
  if exists (select 1 from public.usuario_empresas where usuario_id = auth.uid()) then
    raise exception 'Tu cuenta ya tiene una empresa asociada';
  end if;

  select * into v_auth_user from auth.users where id = auth.uid();
  perform public.app_sync_user_profile(
    auth.uid(),
    coalesce(v_auth_user.email, ''),
    coalesce(v_auth_user.raw_user_meta_data ->> 'nombre', '')
  );

  insert into public.empresas (
    logo_url, nombre_fiscal, nombre_comercial, correo
  ) values (
    coalesce(p_logo_url, ''),
    v_nombre,
    v_nombre,
    coalesce(v_auth_user.email, '')
  ) returning id into v_empresa_id;

  insert into public.usuario_empresas (
    usuario_id, empresa_id, es_principal, rol
  ) values (
    auth.uid(), v_empresa_id, true, 'admin'
  );

  perform public.app_seed_empresa_defaults(v_empresa_id);
  return jsonb_build_object('empresa_id', v_empresa_id);
end;
$$;

grant execute on function public.get_empresa_invitation_code() to authenticated;
grant execute on function public.list_planes() to authenticated;
grant execute on function public.find_usuario_by_email_for_team_invite(text) to authenticated;
grant execute on function public.invite_usuario_by_email_to_current_empresa(text) to authenticated;
grant execute on function public.respond_team_invite(uuid, text) to authenticated;
grant execute on function public.join_empresa_by_invitation_code(text) to authenticated;
grant execute on function public.create_empresa_inicial(text, text) to authenticated;
