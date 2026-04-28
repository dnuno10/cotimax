-- Roles por empresa (admin/usuario) y enforcement correcto de asientos (Stripe quantity)
-- para el plan Empresa.

alter table public.usuario_empresas
  add column if not exists rol text not null default 'usuario' check (rol in ('admin', 'usuario'));

-- Backfill: asegura al menos un admin por empresa (primer miembro registrado).
with first_members as (
  select
    ue.empresa_id,
    (array_agg(ue.usuario_id order by ue.created_at asc))[1] as usuario_id
  from public.usuario_empresas ue
  group by ue.empresa_id
)
update public.usuario_empresas ue
set rol = 'admin'
from first_members fm
where ue.empresa_id = fm.empresa_id
  and ue.usuario_id = fm.usuario_id;

create or replace function public.app_is_admin_for_empresa(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuario_empresas ue
    join public.usuarios u on u.id = ue.usuario_id
    where ue.usuario_id = auth.uid()
      and ue.empresa_id = p_empresa_id
      and u.activo = true
      and ue.rol = 'admin'
  );
$$;

create or replace function public.get_usuario_actual()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  select jsonb_build_object(
    'id', u.id,
    'nombre', u.nombre,
    'telefono', u.telefono,
    'correo', u.correo,
    -- Rol por empresa (si existe), fallback al rol global.
    'rol', coalesce(ue.rol, u.rol),
    'modo_oscuro', u.modo_oscuro,
    'activo', u.activo,
    'ultimo_acceso_at', u.ultimo_acceso_at,
    'created_at', u.created_at,
    'updated_at', u.updated_at
  )
  into v_payload
  from public.usuarios u
  left join public.usuario_empresas ue
    on ue.usuario_id = u.id
   and ue.empresa_id = v_empresa_id
  where u.id = auth.uid();

  return coalesce(v_payload, '{}'::jsonb);
end;
$$;

-- Helpers: asientos (Stripe quantity) y miembros activos.
create or replace function public.app_empresa_seats_for_empresa(p_empresa_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(s.usuarios_activos, 0)::integer
  from public.suscripciones s
  where s.empresa_id = p_empresa_id
  order by s.updated_at desc
  limit 1;
$$;

create or replace function public.app_empresa_active_members(p_empresa_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
  from public.usuario_empresas ue
  join public.usuarios u on u.id = ue.usuario_id
  where ue.empresa_id = p_empresa_id
    and u.activo = true;
$$;

-- Solo admin/principal puede ver/generar el código de invitación y además se limita por asientos comprados.
create or replace function public.get_empresa_invitation_code()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_codigo text;
  v_plan_id text;
  v_usuarios_min integer := 0;
  v_usuarios_max integer := 0;
  v_seats integer := 0;
  v_members integer := 0;
begin
  perform public.app_require_company_access(v_empresa_id);

  if not public.app_is_admin_for_empresa(v_empresa_id) then
    raise exception 'Solo un admin puede invitar miembros';
  end if;

  select
    lp.plan_id,
    lp.usuarios_minimos,
    lp.usuarios_maximos
  into
    v_plan_id,
    v_usuarios_min,
    v_usuarios_max
  from public.app_latest_plan_for_empresa(v_empresa_id) lp;

  if v_plan_id is null then
    raise exception 'No se encontró suscripción activa para esta empresa';
  end if;

  if v_plan_id <> 'empresa' then
    raise exception 'Las invitaciones de equipo están disponibles solo en el plan Empresa';
  end if;

  v_seats := public.app_empresa_seats_for_empresa(v_empresa_id);
  v_members := public.app_empresa_active_members(v_empresa_id);

  if v_seats <= 0 then
    raise exception 'No se pudo determinar el número de asientos de tu plan. Intenta de nuevo en unos segundos.';
  end if;

  if v_members >= v_seats then
    raise exception 'Tu suscripción tiene % asientos y tu equipo ya tiene % miembros. Aumenta asientos en Stripe para invitar más.', v_seats, v_members;
  end if;

  if v_usuarios_max > 0 and v_seats > v_usuarios_max then
    raise exception 'Tu plan Empresa permite hasta % asientos.', v_usuarios_max;
  end if;

  if v_usuarios_min > 0 and v_seats < v_usuarios_min then
    raise exception 'Tu plan Empresa requiere al menos % asientos.', v_usuarios_min;
  end if;

  select ei.codigo
  into v_codigo
  from public.empresa_invitaciones ei
  where ei.empresa_id = v_empresa_id
    and ei.activo = true
  limit 1;

  if v_codigo is null then
    v_codigo := public.app_generate_invitation_code();

    insert into public.empresa_invitaciones (
      empresa_id,
      codigo,
      created_by,
      activo
    )
    values (
      v_empresa_id,
      v_codigo,
      auth.uid(),
      true
    );
  end if;

  return jsonb_build_object(
    'empresa_id', v_empresa_id,
    'codigo', v_codigo,
    'seats', v_seats,
    'miembros_activos', v_members,
    'usuarios_minimos', v_usuarios_min,
    'usuarios_maximos', v_usuarios_max
  );
end;
$$;

create or replace function public.join_empresa_by_invitation_code(p_codigo text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user auth.users%rowtype;
  v_empresa_id uuid;
  v_plan_id text;
  v_usuarios_min integer := 0;
  v_usuarios_max integer := 0;
  v_seats integer := 0;
  v_members integer := 0;
  v_membership_count integer := 0;
  v_max_empresas_allowed integer := 1;
  v_already_member boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  if nullif(trim(coalesce(p_codigo, '')), '') is null then
    raise exception 'Codigo de invitacion invalido';
  end if;

  select *
  into v_auth_user
  from auth.users
  where id = auth.uid();

  perform public.app_sync_user_profile(
    auth.uid(),
    coalesce(v_auth_user.email, ''),
    coalesce(v_auth_user.raw_user_meta_data ->> 'nombre', '')
  );

  select ei.empresa_id
  into v_empresa_id
  from public.empresa_invitaciones ei
  where upper(trim(ei.codigo)) = upper(trim(p_codigo))
    and ei.activo = true
  limit 1;

  if v_empresa_id is null then
    raise exception 'Codigo de invitacion invalido';
  end if;

  select exists(
    select 1
    from public.usuario_empresas ue
    where ue.usuario_id = auth.uid()
      and ue.empresa_id = v_empresa_id
  )
  into v_already_member;

  if v_already_member then
    return jsonb_build_object(
      'empresa_id', v_empresa_id
    );
  end if;

  select lp.plan_id, lp.usuarios_minimos, lp.usuarios_maximos
  into v_plan_id, v_usuarios_min, v_usuarios_max
  from public.app_latest_plan_for_empresa(v_empresa_id) lp;

  if v_plan_id <> 'empresa' then
    raise exception 'Solo las empresas con plan Empresa pueden invitar miembros';
  end if;

  select count(*)::integer
  into v_membership_count
  from public.usuario_empresas ue
  where ue.usuario_id = auth.uid();

  v_max_empresas_allowed := public.app_user_max_empresas_allowed(auth.uid());

  if v_membership_count >= v_max_empresas_allowed then
    if v_max_empresas_allowed <= 1 then
      raise exception 'Tu plan actual permite estar relacionado con una sola empresa. Actualiza a Empresa para gestionar más de una.';
    end if;
    raise exception 'Tu plan actual permite estar relacionado con hasta % empresas.', v_max_empresas_allowed;
  end if;

  v_seats := public.app_empresa_seats_for_empresa(v_empresa_id);
  v_members := public.app_empresa_active_members(v_empresa_id);

  if v_seats <= 0 then
    raise exception 'No se pudo determinar el número de asientos del equipo. Intenta de nuevo en unos segundos.';
  end if;

  if v_members >= v_seats then
    raise exception 'Este equipo ya llenó sus % asientos. Pidan al admin que aumente asientos en Stripe.', v_seats;
  end if;

  if v_usuarios_max > 0 and v_seats > v_usuarios_max then
    raise exception 'Tu plan Empresa permite hasta % asientos.', v_usuarios_max;
  end if;

  if v_usuarios_min > 0 and v_seats < v_usuarios_min then
    raise exception 'Tu plan Empresa requiere al menos % asientos.', v_usuarios_min;
  end if;

  insert into public.usuario_empresas (
    usuario_id,
    empresa_id,
    es_principal,
    rol
  )
  values (
    auth.uid(),
    v_empresa_id,
    v_membership_count = 0,
    'usuario'
  )
  on conflict (usuario_id, empresa_id) do update
  set updated_at = timezone('utc', now());

  return jsonb_build_object(
    'empresa_id', v_empresa_id
  );
end;
$$;

-- Asegura que el creador de una empresa sea admin en esa empresa.
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
  v_nombre_empresa text := nullif(trim(coalesce(p_nombre_comercial, '')), '');
  v_membership_count integer := 0;
  v_max_empresas_allowed integer := 1;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  if v_nombre_empresa is null then
    raise exception 'Ingresa el nombre de la empresa';
  end if;

  select *
  into v_auth_user
  from auth.users
  where id = auth.uid();

  perform public.app_sync_user_profile(
    auth.uid(),
    coalesce(v_auth_user.email, ''),
    coalesce(v_auth_user.raw_user_meta_data ->> 'nombre', '')
  );

  select count(*)::integer
  into v_membership_count
  from public.usuario_empresas ue
  where ue.usuario_id = auth.uid();

  v_max_empresas_allowed := public.app_user_max_empresas_allowed(auth.uid());

  if v_membership_count >= v_max_empresas_allowed then
    if v_max_empresas_allowed <= 1 then
      raise exception 'Tu plan actual permite estar relacionado con una sola empresa. Actualiza a Empresa para gestionar más de una.';
    end if;
    raise exception 'Tu plan actual permite estar relacionado con hasta % empresas.', v_max_empresas_allowed;
  end if;

  insert into public.empresas (
    logo_url,
    nombre_fiscal,
    nombre_comercial,
    correo
  )
  values (
    coalesce(p_logo_url, ''),
    v_nombre_empresa,
    v_nombre_empresa,
    coalesce(v_auth_user.email, '')
  )
  returning id into v_empresa_id;

  insert into public.usuario_empresas (usuario_id, empresa_id, es_principal, rol)
  values (auth.uid(), v_empresa_id, v_membership_count = 0, 'admin')
  on conflict (usuario_id, empresa_id) do update
  set es_principal = excluded.es_principal,
      rol = 'admin',
      updated_at = timezone('utc', now());

  perform public.app_seed_empresa_defaults(v_empresa_id);

  return jsonb_build_object(
    'empresa_id', v_empresa_id
  );
end;
$$;

-- Asegura que el workspace inicial cree la empresa con rol admin.
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
  v_email text := coalesce(nullif(trim(coalesce(p_email, '')), ''), '');
  v_alias text := nullif(split_part(v_email, '@', 1), '');
  v_nombre text := coalesce(
    nullif(trim(coalesce(p_nombre, '')), ''),
    initcap(replace(coalesce(v_alias, 'Usuario'), '.', ' ')),
    'Usuario'
  );
  v_nombre_empresa text := coalesce(
    nullif(trim(coalesce(p_nombre_empresa, '')), ''),
    'Empresa de ' || v_nombre
  );
begin
  if p_user_id is null then
    raise exception 'Usuario invalido';
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

    insert into public.usuario_empresas (usuario_id, empresa_id, es_principal, rol)
    values (p_user_id, v_empresa_id, true, 'admin')
    on conflict (usuario_id, empresa_id) do update
    set es_principal = excluded.es_principal,
        rol = 'admin',
        updated_at = timezone('utc', now());

    insert into public.empresa_localizacion (empresa_id)
    values (v_empresa_id)
    on conflict (empresa_id) do nothing;

    insert into public.empresa_impuestos_config (empresa_id)
    values (v_empresa_id)
    on conflict (empresa_id) do nothing;

    insert into public.empresa_modulos_habilitados (
      empresa_id,
      modulo_key,
      enabled
    )
    select
      v_empresa_id,
      cm.key,
      cm.activo
    from public.catalogo_modulos cm
    on conflict (empresa_id, modulo_key) do update
    set enabled = excluded.enabled,
        updated_at = timezone('utc', now());

    if exists (select 1 from public.planes where id = 'starter')
      and not exists (
        select 1
        from public.suscripciones s
        where s.empresa_id = v_empresa_id
      ) then
      insert into public.suscripciones (
        empresa_id,
        plan_id,
        estado,
        fecha_inicio,
        fecha_fin,
        renovacion_automatica,
        usuarios_activos
      )
      values (
        v_empresa_id,
        'starter',
        'activa',
        timezone('utc', now()),
        timezone('utc', now()) + interval '100 years',
        false,
        1
      );
    end if;
  end if;

  return v_empresa_id;
end;
$$;

-- Gestión de miembros de la empresa actual (para plan Empresa).
create or replace function public.list_miembros_empresa_actual()
returns table (
  usuario_id uuid,
  nombre text,
  correo text,
  rol text,
  es_principal boolean,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    u.id as usuario_id,
    u.nombre,
    u.correo,
    ue.rol,
    ue.es_principal,
    ue.created_at
  from public.usuario_empresas ue
  join public.usuarios u on u.id = ue.usuario_id
  where ue.empresa_id = public.app_current_empresa_id()
    and public.app_can_access_empresa(ue.empresa_id)
  order by ue.es_principal desc, ue.rol asc, u.nombre asc;
$$;

create or replace function public.update_miembro_rol_empresa_actual(
  p_usuario_id uuid,
  p_rol text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_rol text := lower(btrim(coalesce(p_rol, '')));
begin
  perform public.app_require_company_access(v_empresa_id);

  if not public.app_is_admin_for_empresa(v_empresa_id) then
    raise exception 'Solo un admin puede cambiar roles';
  end if;

  if v_rol not in ('admin', 'usuario') then
    raise exception 'Rol inválido';
  end if;

  update public.usuario_empresas
  set rol = v_rol,
      updated_at = timezone('utc', now())
  where empresa_id = v_empresa_id
    and usuario_id = p_usuario_id
    and es_principal = false;

  if not found then
    raise exception 'No se pudo actualizar el rol (¿es principal o no pertenece a la empresa?)';
  end if;
end;
$$;

grant execute on function public.app_empresa_seats_for_empresa(uuid) to authenticated;
grant execute on function public.app_empresa_active_members(uuid) to authenticated;
grant execute on function public.list_miembros_empresa_actual() to authenticated;
grant execute on function public.update_miembro_rol_empresa_actual(uuid, text) to authenticated;
