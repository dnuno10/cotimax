// Supabase Edge Function: stripe-checkout
// Creates a Stripe Checkout Session for PRO/EMPRESA or a Billing Portal session
// when a subscription already exists.

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

function error(status: number, message: string, details?: Json) {
  return json({ error: message, ...(details ?? {}) }, { status });
}

function requireEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing env ${name}`);
  return value;
}

function parseIntSafe(value: unknown) {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "access-control-allow-origin": "*",
        "access-control-allow-headers":
          "authorization, x-client-info, apikey, content-type",
        "access-control-allow-methods": "POST, OPTIONS",
      },
    });
  }

  if (req.method !== "POST") {
    return error(405, "Method not allowed.");
  }

  const stripe = new Stripe(requireEnv("STRIPE_SECRET_KEY"), {
    apiVersion: "2024-06-20",
  });

  const supabaseUrl = requireEnv("SUPABASE_URL");
  const supabaseAnonKey = requireEnv("SUPABASE_ANON_KEY");
  const supabaseServiceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");

  const authHeader = req.headers.get("authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return error(401, "Missing Authorization header.");
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false },
  });

  let body: Json;
  try {
    body = (await req.json()) as Json;
  } catch {
    return error(400, "Invalid JSON body.");
  }

  const planId = String(body["plan_id"] ?? "").trim();
  if (planId !== "pro" && planId !== "empresa") {
    return error(400, "Invalid plan_id. Expected 'pro' or 'empresa'.");
  }

  const seatsRequested = parseIntSafe(body["seats"]);
  const origin = String(body["origin"] ?? "").trim();
  const appBaseUrl = String(body["app_base_url"] ?? "").trim() ||
    Deno.env.get("APP_BASE_URL") ||
    origin;
  if (!appBaseUrl) {
    return error(
      400,
      "Missing app_base_url. Provide it or set APP_BASE_URL in Edge Function env.",
    );
  }

  const { data: empresaId, error: empresaError } = await userClient.rpc(
    "app_current_empresa_id",
  );
  if (empresaError) {
    return error(401, "No se pudo validar tu sesión.", { detail: empresaError.message });
  }
  if (!empresaId) {
    return error(403, "No hay una empresa seleccionada.");
  }

  const { data: isAdmin, error: adminError } = await userClient.rpc(
    "app_is_admin_for_empresa",
    { p_empresa_id: empresaId },
  );
  if (adminError) {
    return error(401, "No se pudo validar permisos.", { detail: adminError.message });
  }
  if (!isAdmin) {
    return error(403, "Solo un admin puede cambiar el plan.");
  }

  const { data: plan, error: planError } = await adminClient
    .from("planes")
    .select(
      "id, nombre, stripe_product_id, stripe_price_id, billing_mode, usuarios_minimos, usuarios_maximos",
    )
    .eq("id", planId)
    .limit(1)
    .maybeSingle();
  if (planError) {
    return error(500, "No se pudo cargar el plan.", { detail: planError.message });
  }
  if (!plan) {
    return error(404, "Plan no encontrado.");
  }

  const billingMode = String(plan.billing_mode ?? "").trim();
  const minUsers = Number(plan.usuarios_minimos ?? 0) || 0;
  const maxUsers = Number(plan.usuarios_maximos ?? 0) || 0;

  let quantity = 1;
  let adjustableQuantity:
    | { enabled: true; minimum: number; maximum: number }
    | undefined;

  if (billingMode === "per_user_monthly") {
    const min = Math.max(2, minUsers || 2);
    const max = Math.max(min, Math.min(50, maxUsers || 50));
    const desired = seatsRequested == null ? min : seatsRequested;
    if (desired < min || desired > max) {
      return error(400, `La cantidad de asientos debe ser entre ${min} y ${max}.`);
    }
    quantity = desired;
    adjustableQuantity = { enabled: true, minimum: min, maximum: max };
  } else {
    // PRO: individual
    quantity = 1;
  }

  const stripeProductId = String(plan.stripe_product_id ?? "").trim();
  let stripePriceId = String(plan.stripe_price_id ?? "").trim();
  if (!stripePriceId) {
    if (!stripeProductId) {
      return error(
        500,
        "El plan no tiene Stripe Product configurado. Actualiza planes.stripe_product_id.",
      );
    }
    const prices = await stripe.prices.list({
      product: stripeProductId,
      active: true,
      limit: 10,
    });
    const monthlyRecurring = prices.data.find((p) =>
      p.type === "recurring" && p.recurring?.interval === "month"
    );
    stripePriceId = (monthlyRecurring ?? prices.data[0])?.id ?? "";
    if (!stripePriceId) {
      return error(
        500,
        "No se encontró un Stripe Price activo para el producto del plan.",
      );
    }
  }

  const { data: empresa, error: empresaRowError } = await adminClient
    .from("empresas")
    .select("id, stripe_customer_id, nombre_comercial, correo")
    .eq("id", empresaId)
    .single();
  if (empresaRowError) {
    return error(500, "No se pudo cargar la empresa.", { detail: empresaRowError.message });
  }

  let customerId = String(empresa.stripe_customer_id ?? "").trim();
  if (!customerId) {
    const customer = await stripe.customers.create({
      name: String(empresa.nombre_comercial ?? "").trim() || undefined,
      email: String(empresa.correo ?? "").trim() || undefined,
      metadata: { empresa_id: String(empresaId) },
    });
    customerId = customer.id;
    const { error: updateError } = await adminClient
      .from("empresas")
      .update({ stripe_customer_id: customerId })
      .eq("id", empresaId);
    if (updateError) {
      return error(
        500,
        "Se creó el cliente en Stripe, pero no se pudo guardar en la BD.",
        { detail: updateError.message },
      );
    }
  }

  const { data: suscripcionActual } = await adminClient
    .from("suscripciones")
    .select("stripe_subscription_id, plan_id, estado")
    .eq("empresa_id", empresaId)
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const existingSubscriptionId = String(suscripcionActual?.stripe_subscription_id ?? "").trim();

  // If there's an existing Stripe subscription, send them to the Billing Portal
  // to manage plan/quantity safely (avoids double-subscription charges).
  if (existingSubscriptionId) {
    const portal = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${appBaseUrl}/#/planes?checkout=portal`,
    });
    return json(
      { url: portal.url, mode: "portal" },
      { headers: { "access-control-allow-origin": "*" } },
    );
  }

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    allow_promotion_codes: true,
    line_items: [
      {
        price: stripePriceId,
        quantity,
        adjustable_quantity: adjustableQuantity,
      },
    ],
    metadata: {
      empresa_id: String(empresaId),
      plan_id: planId,
    },
    subscription_data: {
      metadata: {
        empresa_id: String(empresaId),
        plan_id: planId,
      },
    },
    success_url:
      `${appBaseUrl}/#/planes?checkout=success&session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${appBaseUrl}/#/planes?checkout=cancel`,
  });

  return json(
    { url: session.url, mode: "checkout" },
    { headers: { "access-control-allow-origin": "*" } },
  );
});
