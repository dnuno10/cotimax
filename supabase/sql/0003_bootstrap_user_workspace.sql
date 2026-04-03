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

    insert into public.usuario_empresas (usuario_id, empresa_id, es_principal)
    values (p_user_id, v_empresa_id, true)
    on conflict (usuario_id, empresa_id) do update
    set es_principal = excluded.es_principal,
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

create or replace function public.app_handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_ensure_user_workspace(
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'nombre', ''),
    coalesce(new.raw_user_meta_data ->> 'empresa', '')
  );
  return new;
end;
$$;

create or replace function public.ensure_user_workspace()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user auth.users%rowtype;
  v_empresa_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  select *
  into v_auth_user
  from auth.users
  where id = auth.uid();

  v_empresa_id := public.app_ensure_user_workspace(
    auth.uid(),
    coalesce(v_auth_user.email, ''),
    coalesce(v_auth_user.raw_user_meta_data ->> 'nombre', ''),
    coalesce(v_auth_user.raw_user_meta_data ->> 'empresa', '')
  );

  return jsonb_build_object(
    'empresa_id', v_empresa_id
  );
end;
$$;

grant execute on function public.ensure_user_workspace() to authenticated;

select public.app_ensure_user_workspace(
  u.id,
  coalesce(au.email, u.correo, ''),
  coalesce(nullif(u.nombre, ''), coalesce(au.raw_user_meta_data ->> 'nombre', '')),
  coalesce(au.raw_user_meta_data ->> 'empresa', '')
)
from public.usuarios u
left join auth.users au on au.id = u.id
where not exists (
  select 1
  from public.usuario_empresas ue
  where ue.usuario_id = u.id
);
