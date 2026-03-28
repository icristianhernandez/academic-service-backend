import "@supabase/functions-js/edge-runtime.d.ts";
import mailer from "smtp";
import {
  build_invitation_email_html,
  build_invitation_email_text,
} from "./email-template.ts";

Deno.serve(async (req) => {
  const invitation_edge_api_key = Deno.env.get("INVITATION_EDGE_API_KEY");
  const smtp_provider = Deno.env.get("SMTP_PROVIDER");

  console.log("test");

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (req.headers.get("x-api-key") !== invitation_edge_api_key) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let payload: {
    email?: string;
    token?: string;
    role?: string;
    expires_at?: string;
  };

  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const email = payload.email?.trim();
  const token = payload.token?.trim();
  const role = payload.role?.trim();
  const expires_at = payload.expires_at?.trim();

  if (!email || !token || !role || !expires_at) {
    return new Response(
      JSON.stringify({
        error:
          "Missing one required payload fields: email, token, role, expires_at",
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  const expiration_date = new Date(expires_at);
  const formatted_expired_date = new Intl.DateTimeFormat("es-VE", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: true,
  }).format(expiration_date);

  const email_text = build_invitation_email_text({
    email,
    role,
    token,
    expires_at: formatted_expired_date,
  });

  const email_html = build_invitation_email_html({
    email,
    role,
    token,
    expires_at: formatted_expired_date,
  });

  if (smtp_provider === "mock") {
    console.log(
      `[MOCK EMAIL] ` +
        `To: ${email}, ` +
        `Role: ${role}, ` +
        `Token: ${token}, ` +
        `Expires: ${formatted_expired_date}\n` +
        `${email_text}`,
    );
  } else if (smtp_provider === "local") {
    const smtp_transporter = mailer.transporter({
      host: "inbucket",
      port: 1025,
      secure: false,
    });
    try {
      await smtp_transporter.send({
        from: "no-reply@usm.local",
        to: email,
        subject:
          "Invitación Sistema de Servicio Comunitario - Universidad Santa María",
        text: email_text,
        html: email_html,
      });

      console.log(`[LOCAL EMAIL] Sent successfully to ${email}`);
    } catch (error) {
      const error_message =
        error instanceof Error ? error.message : String(error);
      console.error(`[LOCAL EMAIL] Error:`, error);
      return new Response(
        JSON.stringify({
          error: `Failed to send local email: ${error_message}`,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }
  } else {
    return new Response(
      JSON.stringify({
        error: `SMTP provider '${smtp_provider}' not supported yet`,
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      message: "Invitation email processed successfully",
      email,
    }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
});
