const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

Deno.serve((req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  return new Response(
    JSON.stringify({
      error:
        "La compra y administración de planes está deshabilitada. Todas las cuentas tienen acceso Cotimax Pro.",
    }),
    {
      status: 410,
      headers: {
        ...corsHeaders,
        "content-type": "application/json; charset=utf-8",
      },
    },
  );
});
