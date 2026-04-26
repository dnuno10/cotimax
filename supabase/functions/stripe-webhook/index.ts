// Supabase Edge Function: stripe-webhook
// Receives Stripe webhooks and syncs suscripciones in Postgres.

import Stripe from "https://esm.sh/stripe@14.25.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Json = Record<string, unknown>;

function json(body: Json, init: ResponseInit = {}) {
  return new Response(JSON.stringify(body), {
    ...init,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...(init.headers ?? {}),
    },
  });
}

function requireEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing env ${name}`);
  return value;
}

function toIsoFromUnixSeconds(value: unknown) {
  const seconds = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(seconds)) return null;
  return new Date(seconds * 1000).toISOString();
}

function mapEstadoFromStripeStatus(status: string) {
  switch (status) {
    case "active":
    case "trialing":
      return "activa";
    case "past_due":
      return "past_due";
    case "unpaid":
      return "unpaid";
    case "canceled":
      return "cancelada";
    case "incomplete":
    case "incomplete_expired":
      return "incompleta";
    default:
      return status || "desconocida";
  }
}

async function upsertWebhookEvent(
  adminClient: ReturnType<typeof createClient>,
  eventId: string,
  tipo: string,
  payload: unknown,
) {
  await adminClient.from("stripe_webhook_events").insert({
    stripe_event_id: eventId,
    tipo,
    payload,
    procesado: false,
  });
}

async function markWebhookEventProcessed(
  adminClient: ReturnType<typeof createClient>,
  eventId: string,
) {
  await adminClient
    .from("stripe_webhook_events")
    .update({ procesado: true, procesado_at: new Date().toISOString() })
    .eq("stripe_event_id", eventId);
}

async function resolvePlanId(
  adminClient: ReturnType<typeof createClient>,
  priceId: string,
  productId: string,
  fallbackPlanId?: string,
) {
  const { data } = await adminClient
    .from("planes")
    .select("id")
    .or(`stripe_price_id.eq.${priceId},stripe_product_id.eq.${productId}`)
    .limit(1)
    .maybeSingle();
  return (data?.id as string | undefined) ?? fallbackPlanId ?? null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, { status: 405 });
  }

  const stripe = new Stripe(requireEnv("STRIPE_SECRET_KEY"), {
    apiVersion: "2024-06-20",
  });
  const webhookSecret = requireEnv("STRIPE_WEBHOOK_SECRET");

  const sig = req.headers.get("stripe-signature");
  if (!sig) {
    return json({ error: "Missing stripe-signature." }, { status: 400 });
  }

  const rawBody = await req.text();
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
  } catch (e) {
    return json({ error: "Invalid signature.", detail: String(e) }, { status: 400 });
  }

  const adminClient = createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false } },
  );

  // Persist event (idempotency via unique stripe_event_id).
  try {
    await upsertWebhookEvent(adminClient, event.id, event.type, event);
  } catch (e) {
    // Duplicate event or insert error; still try to process (idempotent updates below).
    const message = String(e);
    if (!message.includes("duplicate") && !message.includes("already exists")) {
      // ignore
    }
  }

  try {
    if (
      event.type === "customer.subscription.created" ||
      event.type === "customer.subscription.updated" ||
      event.type === "customer.subscription.deleted"
    ) {
      const sub = event.data.object as Stripe.Subscription;
      const empresaId = String(sub.metadata?.empresa_id ?? "").trim();
      const planIdFromMetadata = String(sub.metadata?.plan_id ?? "").trim() || undefined;
      if (!empresaId) {
        await markWebhookEventProcessed(adminClient, event.id);
        return json({ ok: true, skipped: true });
      }

      const item = sub.items.data[0];
      const priceId = String(item?.price?.id ?? "").trim();
      const productId = typeof item?.price?.product === "string"
        ? String(item?.price?.product)
        : String((item?.price?.product as Stripe.Product | null)?.id ?? "").trim();

      const planId = await resolvePlanId(
        adminClient,
        priceId,
        productId,
        planIdFromMetadata,
      );
      if (!planId) {
        await markWebhookEventProcessed(adminClient, event.id);
        return json({ ok: true, skipped: true, reason: "plan_not_mapped" });
      }

      const seats = Number(item?.quantity ?? 1) || 1;
      const estado = mapEstadoFromStripeStatus(String(sub.status ?? ""));
      const fechaInicio = toIsoFromUnixSeconds(sub.current_period_start);
      const fechaFin = toIsoFromUnixSeconds(sub.current_period_end) ?? new Date().toISOString();
      const renovacion = !(sub.cancel_at_period_end ?? false);

      await adminClient.from("suscripciones").upsert({
        empresa_id: empresaId,
        plan_id: planId,
        stripe_subscription_id: sub.id,
        stripe_price_id: priceId,
        estado,
        fecha_inicio: fechaInicio ?? new Date().toISOString(),
        fecha_fin: fechaFin,
        renovacion_automatica: renovacion,
        usuarios_activos: seats,
      }, { onConflict: "stripe_subscription_id" });

      // Keep customer id in empresas table if present.
      const customerId = typeof sub.customer === "string" ? sub.customer : "";
      if (customerId) {
        await adminClient.from("empresas").update({ stripe_customer_id: customerId }).eq("id", empresaId);
      }
    }

    if (event.type === "checkout.session.completed") {
      const session = event.data.object as Stripe.Checkout.Session;
      const empresaId = String(session.metadata?.empresa_id ?? "").trim();
      const customerId = typeof session.customer === "string" ? session.customer : "";
      if (empresaId && customerId) {
        await adminClient.from("empresas").update({ stripe_customer_id: customerId }).eq("id", empresaId);
      }
    }

    await markWebhookEventProcessed(adminClient, event.id);
    return json({ ok: true });
  } catch (e) {
    return json({ ok: false, error: String(e) }, { status: 500 });
  }
});
