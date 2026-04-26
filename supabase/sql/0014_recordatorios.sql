create table if not exists public.recordatorios (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null default public.app_current_empresa_id()
    references public.empresas(id),
  cliente_id uuid references public.clientes(id),
  cliente_nombre_snapshot text not null default '',
  cotizacion_id uuid references public.cotizaciones(id),
  cotizacion_folio_snapshot text not null default '',
  nombre text not null default '',
  descripcion text not null default '',
  fecha date not null default current_date,
  fecha_inicio date not null default current_date,
  fecha_fin date,
  frecuencia text not null default 'ninguna'
    check (
      frecuencia = any (
        array[
          'ninguna',
          'cadaDia',
          'diasDeLaSemana',
          'finDeSemana',
          'cadaSemana',
          'cadaDosSemanas',
          'cadaCuatroSemanas',
          'cadaMes',
          'cadaDosMeses',
          'cadaTresMeses',
          'cadaCuatroMeses',
          'cadaSeisMeses',
          'cadaAnio'
        ]
      )
    ),
  activo boolean not null default true,
  icon_key text not null default 'calendar_month',
  created_at timestamp with time zone not null default timezone('utc', now()),
  updated_at timestamp with time zone not null default timezone('utc', now()),
  deleted_at timestamp with time zone
);

create table if not exists public.recordatorios_dias (
  recordatorio_id uuid not null
    references public.recordatorios(id) on delete cascade,
  weekday_iso smallint not null check (weekday_iso >= 1 and weekday_iso <= 7),
  created_at timestamp with time zone not null default timezone('utc', now()),
  primary key (recordatorio_id, weekday_iso)
);

create index if not exists recordatorios_empresa_fecha_idx
  on public.recordatorios (empresa_id, fecha);

create index if not exists recordatorios_empresa_deleted_idx
  on public.recordatorios (empresa_id, deleted_at);

drop trigger if exists set_updated_at_recordatorios on public.recordatorios;
create trigger set_updated_at_recordatorios before update on public.recordatorios
for each row execute function public.app_set_updated_at();

alter table public.recordatorios enable row level security;
alter table public.recordatorios_dias enable row level security;

drop policy if exists recordatorios_all on public.recordatorios;
create policy recordatorios_all on public.recordatorios
for all using (public.app_can_access_empresa(empresa_id))
with check (public.app_can_access_empresa(empresa_id));

drop policy if exists recordatorios_dias_all on public.recordatorios_dias;
create policy recordatorios_dias_all on public.recordatorios_dias
for all using (
  exists (
    select 1
    from public.recordatorios r
    where r.id = recordatorio_id
      and public.app_can_access_empresa(r.empresa_id)
  )
)
with check (
  exists (
    select 1
    from public.recordatorios r
    where r.id = recordatorio_id
      and public.app_can_access_empresa(r.empresa_id)
  )
);
