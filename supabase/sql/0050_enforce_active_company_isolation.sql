-- Enforce strict tenant isolation using only the active company for the session.
-- Legacy extra memberships must never broaden data access.

create or replace function public.app_current_empresa_ids()
returns uuid[]
language sql
stable
security definer
set search_path = public
as $$
  select case
    when public.app_current_empresa_id() is null then '{}'::uuid[]
    else array[public.app_current_empresa_id()]
  end;
$$;

create or replace function public.app_can_access_empresa(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null
    and p_empresa_id is not null
    and p_empresa_id = public.app_current_empresa_id();
$$;

create or replace function public.get_data_isolation_context()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'usuario_id', auth.uid(),
    'empresa_id', public.app_current_empresa_id(),
    'membresias', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'empresa_id', ue.empresa_id,
            'es_principal', ue.es_principal,
            'rol', ue.rol
          )
          order by ue.es_principal desc, ue.created_at asc
        )
        from public.usuario_empresas ue
        where ue.usuario_id = auth.uid()
      ),
      '[]'::jsonb
    )
  );
$$;

grant execute on function public.get_data_isolation_context()
to authenticated;
