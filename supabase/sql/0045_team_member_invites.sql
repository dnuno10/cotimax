-- Invitaciones directas por correo para equipos (plan Empresa).
-- La invitación aparece como "notificación" en la campana (UI) para el usuario invitado.

create table if not exists public.empresa_invitaciones_miembros (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  invited_user_id uuid not null references public.usuarios(id) on delete cascade,
  invited_email text not null default ''::text,
  invited_by uuid not null references public.usuarios(id) on delete cascade,
  status text not null default 'pendiente'::text check (
    status = any (array['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'cancelada'::text])
  ),
  responded_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists empresa_invitaciones_miembros_invited_user_idx
on public.empresa_invitaciones_miembros (invited_user_id);

create index if not exists empresa_invitaciones_miembros_empresa_idx
on public.empresa_invitaciones_miembros (empresa_id);

-- Solo puede existir una invitación pendiente por (empresa, usuario).
create unique index if not exists empresa_invitaciones_miembros_unique_pending
on public.empresa_invitaciones_miembros (empresa_id, invited_user_id)
where status = 'pendiente';

drop trigger if exists set_updated_at_empresa_invitaciones_miembros on public.empresa_invitaciones_miembros;
create trigger set_updated_at_empresa_invitaciones_miembros
before update on public.empresa_invitaciones_miembros
for each row execute function public.app_set_updated_at();

alter table public.empresa_invitaciones_miembros enable row level security;

drop policy if exists empresa_invitaciones_miembros_select on public.empresa_invitaciones_miembros;
create policy empresa_invitaciones_miembros_select on public.empresa_invitaciones_miembros
for select using (
  invited_user_id = auth.uid()
  or public.app_is_admin_for_empresa(empresa_id)
);

drop policy if exists empresa_invitaciones_miembros_insert on public.empresa_invitaciones_miembros;
create policy empresa_invitaciones_miembros_insert on public.empresa_invitaciones_miembros
for insert
with check (public.app_is_admin_for_empresa(empresa_id));

drop policy if exists empresa_invitaciones_miembros_update on public.empresa_invitaciones_miembros;
create policy empresa_invitaciones_miembros_update on public.empresa_invitaciones_miembros
for update using (
  invited_user_id = auth.uid()
  or public.app_is_admin_for_empresa(empresa_id)
) with check (true);

drop policy if exists empresa_invitaciones_miembros_delete on public.empresa_invitaciones_miembros;
create policy empresa_invitaciones_miembros_delete on public.empresa_invitaciones_miembros
for delete using (public.app_is_admin_for_empresa(empresa_id));

create or replace function public.find_usuario_by_email_for_team_invite(p_email text)
returns table (
  id uuid,
  nombre text,
  correo text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_empresa_id uuid := public.app_current_empresa_id();
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_plan_id text;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  if v_empresa_id is null then
    raise exception 'Sin empresa activa';
  end if;

  if not public.app_is_admin_for_empresa(v_empresa_id) then
    raise exception 'Solo un admin puede invitar miembros';
  end if;

  if v_email = '' then
    raise exception 'Correo inválido';
  end if;

  select lp.plan_id
  into v_plan_id
  from public.app_latest_plan_for_empresa(v_empresa_id) lp;

  if v_plan_id <> 'empresa' then
    raise exception 'Las invitaciones de equipo están disponibles solo en el plan Empresa';
  end if;

  return query
  select u.id, u.nombre, u.correo
  from public.usuarios u
  where lower(u.correo) = v_email
    and u.activo = true
  limit 1;
end;
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
  v_plan_id text;
  v_usuarios_min integer := 0;
  v_usuarios_max integer := 0;
  v_seats integer := 0;
  v_members integer := 0;
  v_user_id uuid;
  v_invite_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  if v_empresa_id is null then
    raise exception 'Sin empresa activa';
  end if;

  if not public.app_is_admin_for_empresa(v_empresa_id) then
    raise exception 'Solo un admin puede invitar miembros';
  end if;

  if v_email = '' then
    raise exception 'Correo inválido';
  end if;

  select lp.plan_id, lp.usuarios_minimos, lp.usuarios_maximos
  into v_plan_id, v_usuarios_min, v_usuarios_max
  from public.app_latest_plan_for_empresa(v_empresa_id) lp;

  if v_plan_id is null then
    raise exception 'No se encontró suscripción activa para esta empresa';
  end if;

  if v_plan_id <> 'empresa' then
    raise exception 'Las invitaciones de equipo están disponibles solo en el plan Empresa';
  end if;

  select coalesce(s.usuarios_activos, 0)::integer
  into v_seats
  from public.suscripciones s
  where s.empresa_id = v_empresa_id
  order by s.updated_at desc
  limit 1;

  v_members := public.app_active_members_for_empresa(v_empresa_id);

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

  select u.id
  into v_user_id
  from public.usuarios u
  where lower(u.correo) = v_email
    and u.activo = true
  limit 1;

  if v_user_id is null then
    raise exception 'No encontramos un usuario con ese correo. Pídele que se registre o usa el código de invitación.';
  end if;

  if exists (
    select 1
    from public.usuario_empresas ue
    where ue.usuario_id = v_user_id
      and ue.empresa_id = v_empresa_id
  ) then
    raise exception 'Ese usuario ya pertenece a tu empresa';
  end if;

  insert into public.empresa_invitaciones_miembros (
    empresa_id,
    invited_user_id,
    invited_email,
    invited_by,
    status
  )
  values (
    v_empresa_id,
    v_user_id,
    v_email,
    auth.uid(),
    'pendiente'
  )
  on conflict (empresa_id, invited_user_id)
  where status = 'pendiente'
  do update
  set
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

create or replace function public.list_my_pending_team_invites()
returns table (
  id uuid,
  empresa_id uuid,
  empresa_nombre text,
  invited_by uuid,
  invited_by_nombre text,
  invited_email text,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    i.id,
    i.empresa_id,
    coalesce(e.nombre_comercial, e.nombre_fiscal, '') as empresa_nombre,
    i.invited_by,
    coalesce(ub.nombre, ub.correo, '') as invited_by_nombre,
    i.invited_email,
    i.created_at
  from public.empresa_invitaciones_miembros i
  join public.empresas e on e.id = i.empresa_id
  left join public.usuarios ub on ub.id = i.invited_by
  where i.invited_user_id = auth.uid()
    and i.status = 'pendiente'
  order by i.created_at desc;
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
  v_plan_id text;
  v_usuarios_min integer := 0;
  v_usuarios_max integer := 0;
  v_seats integer := 0;
  v_members integer := 0;
  v_membership_count integer := 0;
  v_max_empresas_allowed integer := 1;
begin
  if auth.uid() is null then
    raise exception 'Usuario no autenticado';
  end if;

  if p_invite_id is null then
    raise exception 'Invitación inválida';
  end if;

  select *
  into v_invite
  from public.empresa_invitaciones_miembros i
  where i.id = p_invite_id
    and i.invited_user_id = auth.uid()
  limit 1;

  if v_invite.id is null then
    raise exception 'Invitación no encontrada';
  end if;

  if v_invite.status <> 'pendiente' then
    raise exception 'La invitación ya fue respondida';
  end if;

  if v_action = 'aceptar' or v_action = 'accept' or v_action = 'accepted' then
    select lp.plan_id, lp.usuarios_minimos, lp.usuarios_maximos
    into v_plan_id, v_usuarios_min, v_usuarios_max
    from public.app_latest_plan_for_empresa(v_invite.empresa_id) lp;

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

    select coalesce(s.usuarios_activos, 0)::integer
    into v_seats
    from public.suscripciones s
    where s.empresa_id = v_invite.empresa_id
    order by s.updated_at desc
    limit 1;

    v_members := public.app_active_members_for_empresa(v_invite.empresa_id);

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
      v_invite.empresa_id,
      v_membership_count = 0,
      'usuario'
    )
    on conflict (usuario_id, empresa_id) do update
    set updated_at = timezone('utc', now());

    update public.empresa_invitaciones_miembros
    set
      status = 'aceptada',
      responded_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
    where id = v_invite.id;

    return jsonb_build_object('status', 'aceptada', 'empresa_id', v_invite.empresa_id);
  end if;

  if v_action = 'rechazar' or v_action = 'reject' or v_action = 'decline' then
    update public.empresa_invitaciones_miembros
    set
      status = 'rechazada',
      responded_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
    where id = v_invite.id;

    return jsonb_build_object('status', 'rechazada', 'empresa_id', v_invite.empresa_id);
  end if;

  raise exception 'Acción inválida';
end;
$$;

grant execute on function public.find_usuario_by_email_for_team_invite(text) to authenticated;
grant execute on function public.invite_usuario_by_email_to_current_empresa(text) to authenticated;
grant execute on function public.list_my_pending_team_invites() to authenticated;
grant execute on function public.respond_team_invite(uuid, text) to authenticated;
