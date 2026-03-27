import "@supabase/functions-js/edge-runtime.d.ts";
import mailer from "smtp";
import {
  buildInvitationEmailHtml,
  buildInvitationEmailText,
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

  const date = new Date(expires_at);
  const formattedExpiredDate = new Intl.DateTimeFormat("es-VE", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: true,
  }).format(date);

  const emailText = buildInvitationEmailText({
    email,
    role,
    token,
    expiresAt: formattedExpiredDate,
  });

  const emailHtml = buildInvitationEmailHtml({
    email,
    role,
    token,
    expiresAt: formattedExpiredDate,
  });

  if (smtp_provider === "mock") {
    console.log(
      `[MOCK EMAIL] ` +
        `To: ${email}, ` +
        `Role: ${role}, ` +
        `Token: ${token}, ` +
        `Expires: ${formattedExpiredDate}\n` +
        `${emailText}`,
    );
  } else if (smtp_provider === "local") {
    const transporter = mailer.transporter({
      host: "inbucket",
      port: 1025,
      secure: false,
    });
    try {
      await transporter.send({
        from: "no-reply@usm.local",
        to: email,
        subject:
          "Invitación Sistema de Servicio Comunitario - Universidad Santa María",
        text: emailText,
        html: emailHtml,
      });

      console.log(`[LOCAL EMAIL] Sent successfully to ${email}`);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      console.error(`[LOCAL EMAIL] Error:`, error);
      return new Response(
        JSON.stringify({
          error: `Failed to send local email: ${errorMessage}`,
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
