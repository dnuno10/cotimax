-- Relacion entre ingresos y gastos para medir impacto (ROI por gasto).

alter table public.ingresos
  add column if not exists gasto_fuente_id uuid references public.gastos(id) on delete set null,
  add column if not exists gasto_fuente_nombre_snapshot text not null default '';

create index if not exists ingresos_gasto_fuente_idx
  on public.ingresos (empresa_id, gasto_fuente_id);

-- Opcional: evita duplicar ingreso para la misma cotizacion aprobada.
create unique index if not exists ingresos_unique_cotizacion_idx
  on public.ingresos (empresa_id, cotizacion_id)
  where cotizacion_id is not null and deleted_at is null;

-- Exponer la relacion en el listado para frontend.
drop function if exists public.list_ingresos();

create or replace function public.list_ingresos()
returns table (
  id uuid,
  ingreso_categoria_id text,
  cliente_id text,
  cotizacion_id text,
  gasto_fuente_id text,
  gasto_fuente_nombre text,
  monto numeric,
  metodo_pago text,
  fecha date,
  referencia text,
  notas text,
  recurrente boolean,
  recurrencia text,
  dias_semana int[],
  fecha_inicio date,
  icon_key text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    i.id,
    coalesce(i.ingreso_categoria_id::text, i.categoria_nombre_snapshot) as ingreso_categoria_id,
    coalesce(i.cliente_id::text, i.cliente_nombre_snapshot) as cliente_id,
    coalesce(i.cotizacion_id::text, i.cotizacion_folio_snapshot) as cotizacion_id,
    coalesce(i.gasto_fuente_id::text, '') as gasto_fuente_id,
    coalesce(i.gasto_fuente_nombre_snapshot, '') as gasto_fuente_nombre,
    i.monto,
    i.metodo_pago,
    i.fecha,
    i.referencia,
    i.notas,
    (i.ingreso_recurrente_id is not null) as recurrente,
    coalesce(ir.frecuencia, 'ninguna') as recurrencia,
    coalesce(
      (
        select array_agg(ird.weekday_iso order by ird.weekday_iso)
        from public.ingresos_recurrentes_dias ird
        where ird.ingreso_recurrente_id = i.ingreso_recurrente_id
      ),
      '{}'::int[]
    ) as dias_semana,
    ir.fecha_inicio,
    i.icon_key,
    i.created_at,
    i.updated_at
  from public.ingresos i
  left join public.ingresos_recurrentes ir on ir.id = i.ingreso_recurrente_id
  where i.deleted_at is null
    and public.app_can_access_empresa(i.empresa_id)
  order by i.fecha desc, i.updated_at desc;
$$;

-- IMPORTANTE:
-- Ajusta la funcion public.upsert_ingreso(p_payload jsonb) para mapear:
-- p_payload ->> 'gasto_fuente_id'                 => ingresos.gasto_fuente_id
-- p_payload ->> 'gasto_fuente_nombre_snapshot'    => ingresos.gasto_fuente_nombre_snapshot
-- tanto en INSERT como en ON CONFLICT DO UPDATE.
