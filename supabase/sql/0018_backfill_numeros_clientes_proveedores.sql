-- Backfill de numeros vacios en clientes y proveedores.
-- Asigna consecutivos por empresa tomando como base el maximo numero numerico existente.

with clientes_existentes as (
  select
    c.empresa_id,
    max((regexp_replace(c.numero, '[^0-9]', '', 'g'))::bigint) as max_numero,
    max(length(regexp_replace(c.numero, '[^0-9]', '', 'g'))) as ancho
  from public.clientes c
  where c.deleted_at is null
    and regexp_replace(coalesce(c.numero, ''), '[^0-9]', '', 'g') <> ''
  group by c.empresa_id
),
clientes_objetivo as (
  select
    c.id,
    c.empresa_id,
    row_number() over (
      partition by c.empresa_id
      order by c.created_at, c.id
    ) as rn
  from public.clientes c
  where c.deleted_at is null
    and btrim(coalesce(c.numero, '')) = ''
)
update public.clientes c
set numero = lpad(
  (
    coalesce(ce.max_numero, 0) + coalesce(co.rn, 0)
  )::text,
  greatest(coalesce(ce.ancho, 1), 1),
  '0'
)
from clientes_objetivo co
left join clientes_existentes ce on ce.empresa_id = co.empresa_id
where c.id = co.id;

with proveedores_existentes as (
  select
    p.empresa_id,
    max((regexp_replace(p.numero, '[^0-9]', '', 'g'))::bigint) as max_numero,
    max(length(regexp_replace(p.numero, '[^0-9]', '', 'g'))) as ancho
  from public.proveedores p
  where p.deleted_at is null
    and regexp_replace(coalesce(p.numero, ''), '[^0-9]', '', 'g') <> ''
  group by p.empresa_id
),
proveedores_objetivo as (
  select
    p.id,
    p.empresa_id,
    row_number() over (
      partition by p.empresa_id
      order by p.created_at, p.id
    ) as rn
  from public.proveedores p
  where p.deleted_at is null
    and btrim(coalesce(p.numero, '')) = ''
)
update public.proveedores p
set numero = lpad(
  (
    coalesce(pe.max_numero, 0) + coalesce(po.rn, 0)
  )::text,
  greatest(coalesce(pe.ancho, 1), 1),
  '0'
)
from proveedores_objetivo po
left join proveedores_existentes pe on pe.empresa_id = po.empresa_id
where p.id = po.id;
