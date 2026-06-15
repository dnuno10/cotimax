-- All Cotimax features are always available.
-- Remove the obsolete per-company module catalog and switches.

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

drop table if exists public.empresa_modulos_habilitados;
drop table if exists public.catalogo_modulos;
