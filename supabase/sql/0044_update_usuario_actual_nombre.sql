-- Permite actualizar el nombre del usuario actual (además de modo_oscuro).

create or replace function public.update_usuario_actual(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_nombre text := nullif(btrim(coalesce(p_payload ->> 'nombre', '')), '');
begin
  if v_usuario_id is null then
    raise exception 'Usuario no autenticado';
  end if;

  if (p_payload ? 'nombre') and v_nombre is null then
    raise exception 'El nombre es obligatorio.';
  end if;

  update public.usuarios
  set
    nombre = coalesce(v_nombre, nombre),
    modo_oscuro = coalesce((p_payload ->> 'modo_oscuro')::boolean, modo_oscuro)
  where id = v_usuario_id;

  return v_usuario_id;
end;
$$;

grant execute on function public.update_usuario_actual(jsonb) to authenticated;

