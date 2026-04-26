-- Configura Stripe Product IDs para planes pagados.
-- NOTA: Stripe Price IDs se resuelven por Edge Function (o se pueden llenar aquí).

update public.planes
set stripe_product_id = 'prod_UP3Ncir5mqXRSn'
where id = 'pro';

update public.planes
set stripe_product_id = 'prod_UP3OM8xrrUEkQu'
where id = 'empresa';

