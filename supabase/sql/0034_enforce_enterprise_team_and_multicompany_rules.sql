create or replace function public.app_active_members_for_empresa(p_empresa_id uuid)
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

create or replace function public.app_latest_plan_for_empresa(p_empresa_id uuid)
returns table (
  plan_id text,
  usuarios_minimos integer,
  usuarios_maximos integer,
  limite_empresas integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    s.plan_id,
    p.usuarios_minimos,
    p.usuarios_maximos,
    p.limite_empresas
  from public.suscripciones s
  join public.planes p on p.id = s.plan_id
  where s.empresa_id = p_empresa_id
  order by s.updated_at desc
  limit 1;
$$;

create or replace function public.app_user_max_empresas_allowed(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    max(
      case
        when lp.plan_id = 'empresa' then greatest(coalesce(nullif(lp.limite_empresas, 0), 5), 2)
        else 1
      end
    ),
    1
  )::integer
  from public.usuario_empresas ue
  left join lateral public.app_latest_plan_for_empresa(ue.empresa_id) lp on true
  where ue.usuario_id = p_user_id;
$$;

create or replace function public.app_user_has_empresa_plan(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.usuario_empresas ue
    join lateral public.app_latest_plan_for_empresa(ue.empresa_id) lp on true
    where ue.usuario_id = p_user_id
      and lp.plan_id = 'empresa'
  );
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

  insert into public.usuario_empresas (usuario_id, empresa_id, es_principal)
  values (auth.uid(), v_empresa_id, v_membership_count = 0)
  on conflict (usuario_id, empresa_id) do update
  set es_principal = excluded.es_principal,
      updated_at = timezone('utc', now());

  perform public.app_seed_empresa_defaults(v_empresa_id);

  update public.suscripciones s
  set usuarios_activos = public.app_active_members_for_empresa(v_empresa_id),
      updated_at = timezone('utc', now())
  where s.empresa_id = v_empresa_id;

  return jsonb_build_object(
    'empresa_id', v_empresa_id
  );
end;
$$;

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
  v_usuarios_activos integer := 0;
begin
  perform public.app_require_company_access(v_empresa_id);

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

  v_usuarios_activos := public.app_active_members_for_empresa(v_empresa_id);

  if v_usuarios_max > 0 and v_usuarios_activos >= v_usuarios_max then
    raise exception 'Tu plan Empresa permite hasta % miembros. Si necesitas más de 50, escríbenos a support@cotimax.com.', v_usuarios_max;
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
    'usuarios_activos', v_usuarios_activos,
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
  v_usuarios_max integer := 0;
  v_usuarios_activos integer := 0;
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

  select lp.plan_id, lp.usuarios_maximos
  into v_plan_id, v_usuarios_max
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

  v_usuarios_activos := public.app_active_members_for_empresa(v_empresa_id);

  if v_usuarios_max > 0 and v_usuarios_activos >= v_usuarios_max then
    raise exception 'Este equipo alcanzó su límite de % miembros. Si necesitan más de 50, escríbanos a support@cotimax.com.', v_usuarios_max;
  end if;

  insert into public.usuario_empresas (
    usuario_id,
    empresa_id,
    es_principal
  )
  values (
    auth.uid(),
    v_empresa_id,
    v_membership_count = 0
  )
  on conflict (usuario_id, empresa_id) do update
  set updated_at = timezone('utc', now());

  update public.suscripciones s
  set usuarios_activos = public.app_active_members_for_empresa(v_empresa_id),
      updated_at = timezone('utc', now())
  where s.empresa_id = v_empresa_id;

  return jsonb_build_object(
    'empresa_id', v_empresa_id
  );
end;
$$;

grant execute on function public.create_empresa_inicial(text, text) to authenticated;
grant execute on function public.get_empresa_invitation_code() to authenticated;
grant execute on function public.join_empresa_by_invitation_code(text) to authenticated;
