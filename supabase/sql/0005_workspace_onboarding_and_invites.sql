create or replace function public.app_sync_user_profile(
  p_user_id uuid,
  p_email text default null,
  p_nombre text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := coalesce(nullif(trim(coalesce(p_email, '')), ''), '');
  v_alias text := nullif(split_part(v_email, '@', 1), '');
  v_nombre text := coalesce(
    nullif(trim(coalesce(p_nombre, '')), ''),
    initcap(replace(coalesce(v_alias, 'Usuario'), '.', ' ')),
    'Usuario'
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
end;
$$;

create or replace function public.app_seed_empresa_defaults(p_empresa_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_empresa_id is null then
    raise exception 'Empresa invalida';
  end if;

  insert into public.empresa_localizacion (empresa_id)
  values (p_empresa_id)
  on conflict (empresa_id) do nothing;

  insert into public.empresa_impuestos_config (empresa_id)
  values (p_empresa_id)
  on conflict (empresa_id) do nothing;

  insert into public.empresa_modulos_habilitados (
    empresa_id,
    modulo_key,
    enabled
  )
  select
    p_empresa_id,
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
    )
    values (
      p_empresa_id,
      'starter',
      'activa',
      timezone('utc', now()),
      timezone('utc', now()) + interval '100 years',
      false,
      1
    );
  end if;
end;
$$;

create table if not exists public.empresa_invitaciones (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null unique references public.empresas(id) on delete cascade,
  codigo text not null unique,
  created_by uuid not null references public.usuarios(id) on delete cascade,
  activo boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger set_updated_at_empresa_invitaciones before update on public.empresa_invitaciones
for each row execute function public.app_set_updated_at();

alter table public.empresa_invitaciones enable row level security;

drop policy if exists empresa_invitaciones_select on public.empresa_invitaciones;
create policy empresa_invitaciones_select on public.empresa_invitaciones
for select using (public.app_can_access_empresa(empresa_id));

drop policy if exists empresa_invitaciones_write on public.empresa_invitaciones;
create policy empresa_invitaciones_write on public.empresa_invitaciones
for all using (public.app_is_admin_for_empresa(empresa_id))
with check (public.app_is_admin_for_empresa(empresa_id));

create or replace function public.app_generate_invitation_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  loop
    v_code := 'TEAM-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    exit when not exists (
      select 1
      from public.empresa_invitaciones ei
      where ei.codigo = v_code
    );
  end loop;

  return v_code;
end;
$$;

create or replace function public.get_workspace_status()
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

  select ue.empresa_id
  into v_empresa_id
  from public.usuario_empresas ue
  where ue.usuario_id = auth.uid()
  order by ue.es_principal desc, ue.created_at asc
  limit 1;

  return jsonb_build_object(
    'has_company', v_empresa_id is not null,
    'empresa_id', v_empresa_id
  );
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
  v_nombre_empresa text := nullif(trim(coalesce(p_nombre_comercial, '')), '');
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

  select ue.empresa_id
  into v_empresa_id
  from public.usuario_empresas ue
  where ue.usuario_id = auth.uid()
  order by ue.es_principal desc, ue.created_at asc
  limit 1;

  if v_empresa_id is not null then
    return jsonb_build_object(
      'empresa_id', v_empresa_id
    );
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
  values (auth.uid(), v_empresa_id, true)
  on conflict (usuario_id, empresa_id) do update
  set es_principal = excluded.es_principal,
      updated_at = timezone('utc', now());

  perform public.app_seed_empresa_defaults(v_empresa_id);

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
begin
  perform public.app_require_company_access(v_empresa_id);

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
    'codigo', v_codigo
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
  v_has_company boolean;
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
  )
  into v_has_company;

  insert into public.usuario_empresas (
    usuario_id,
    empresa_id,
    es_principal
  )
  values (
    auth.uid(),
    v_empresa_id,
    not v_has_company
  )
  on conflict (usuario_id, empresa_id) do update
  set updated_at = timezone('utc', now());

  return jsonb_build_object(
    'empresa_id', v_empresa_id
  );
end;
$$;

create or replace function public.app_handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_sync_user_profile(
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'nombre', '')
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
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
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

  return public.get_workspace_status();
end;
$$;

grant execute on function public.get_workspace_status() to authenticated;
grant execute on function public.create_empresa_inicial(text, text) to authenticated;
grant execute on function public.get_empresa_invitation_code() to authenticated;
grant execute on function public.join_empresa_by_invitation_code(text) to authenticated;
