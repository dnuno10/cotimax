alter table public.productos_servicios
alter column sku set default '';

update public.productos_servicios
set sku = ''
where sku is null;

do $$
declare
  constraint_name text;
begin
  select con.conname
  into constraint_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = rel.relnamespace
  where nsp.nspname = 'public'
    and rel.relname = 'productos_servicios'
    and con.contype = 'u'
    and pg_get_constraintdef(con.oid) ilike '%(empresa_id, sku)%'
  limit 1;

  if constraint_name is not null then
    execute format(
      'alter table public.productos_servicios drop constraint %I',
      constraint_name
    );
  end if;
end $$;
