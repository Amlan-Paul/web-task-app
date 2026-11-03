/**
 * Cloudflare Pages Function: GET /api/config
 * Reads public Supabase client configuration from server-side Pages variables.
 * Do not add SUPABASE_SERVICE_ROLE_KEY or any Supabase secret key here.
 */
export async function onRequestGet({ env }) {
  const url = (env.SUPABASE_URL || "").trim().replace(/\/+$/, "");
  const anonKey = (env.SUPABASE_ANON_KEY || "").trim();

  if (!url || !anonKey) {
    return Response.json(
      { error: "Supabase configuration is missing. Set SUPABASE_URL and SUPABASE_ANON_KEY in Cloudflare Pages." },
      { status: 503, headers: { "Cache-Control": "no-store" } }
    );
  }

  // Only expose the public client key. Never expose service-role or secret keys.
  if (!/^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(url) ||
      /service_role|secret/i.test(anonKey)) {
    return Response.json(
      { error: "Invalid public Supabase configuration." },
      { status: 500, headers: { "Cache-Control": "no-store" } }
    );
  }

  return Response.json(
    { url, anonKey },
    { status: 200, headers: { "Cache-Control": "no-store, max-age=0" } }
  );
}

// No POST/PUT/DELETE handlers: browser clients cannot change server configuration.
