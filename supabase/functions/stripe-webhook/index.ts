Deno.serve(() => {
  return new Response(
    JSON.stringify({
      ok: true,
      disabled: true,
      message: "La sincronización de suscripciones está deshabilitada.",
    }),
    {
      status: 200,
      headers: { "content-type": "application/json; charset=utf-8" },
    },
  );
});
