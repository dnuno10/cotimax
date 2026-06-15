create or replace function public.normalize_cotizacion_totals()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_base numeric;
  v_ret_isr_total numeric := 0;
begin
  v_base := greatest(
    coalesce(new.subtotal, 0) - coalesce(new.descuento_total, 0),
    0
  );

  if coalesce(new.ret_isr, false) then
    v_ret_isr_total := v_base * 0.0125;
  end if;

  new.total := v_base + coalesce(new.impuesto_total, 0) - v_ret_isr_total;
  new.saldo_total := new.total - coalesce(new.pagado_total, 0);
  return new;
end;
$$;

drop trigger if exists trg_normalize_cotizacion_totals
on public.cotizaciones;

create trigger trg_normalize_cotizacion_totals
before insert or update of
  subtotal,
  descuento_total,
  impuesto_total,
  ret_isr,
  pagado_total,
  total,
  saldo_total
on public.cotizaciones
for each row
execute function public.normalize_cotizacion_totals();

update public.cotizaciones
set total = total
where ret_isr = true;
