import "@supabase/functions-js/edge-runtime.d.ts";
import mailer from "smtp";

const DEFAULT_SUPABASE_URL = "http://kong:8000";

type claimed_delivery = {
  delivery_id: number;
  notification_recipient_id: number;
  recipient_id: string;
  recipient_name: string;
  recipient_email: string;
  notification_event_id: number;
  notification_type_key: string;
  payload: Record<string, unknown>;
};

type email_template_content = {
  subject: string;
  title: string;
  message: string;
  action_label: string;
  action_hint: string;
  accent_color: string;
};

function escape_html(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function resolve_email_template(delivery: claimed_delivery): email_template_content {
  const notification_type = delivery.notification_type_key;

  if (
    notification_type === "project-phase-advanced-to-review" ||
    notification_type === "project-state-to-review"
  ) {
    return {
      subject: "Nueva entrega recibida para revision",
      title: "Nueva entrega para revision",
      message:
        "Se registro una nueva entrega de proyecto. Ya puedes ingresar al sistema para revisar el documento y continuar el flujo de aprobacion.",
      action_label: "Revisar entrega",
      action_hint: "Ingresa a la bandeja de notificaciones y abre la cola de documentos pendientes.",
      accent_color: "#003d82",
    };
  }

  if (notification_type === "project-review-to-wait-same-phase") {
    return {
      subject: "Tu entrega fue aprobada",
      title: "Entrega aprobada",
      message:
        "Tu entrega fue aprobada por la autoridad correspondiente. Puedes continuar con la siguiente fase del proyecto en la plataforma.",
      action_label: "Continuar proyecto",
      action_hint: "Revisa tus entregas para verificar la fase habilitada y los proximos pasos.",
      accent_color: "#0a7d33",
    };
  }

  if (notification_type === "project-review-to-rejected-same-phase") {
    return {
      subject: "Tu entrega requiere correccion",
      title: "Entrega rechazada para correccion",
      message:
        "Tu entrega fue rechazada y necesita correcciones. Revisa las observaciones registradas en la plataforma y vuelve a enviar la entrega actualizada.",
      action_label: "Corregir y reenviar",
      action_hint: "Consulta observaciones en la seccion de entregas antes de volver a enviar el documento.",
      accent_color: "#b3261e",
    };
  }

  if (notification_type === "project-phase-advanced") {
    return {
      subject: "Actualizacion de proyecto registrada",
      title: "Actualizacion de proyecto",
      message:
        "Se registro un cambio en el progreso del proyecto. Revisa la plataforma para ver el estado actualizado de tus entregas.",
      action_label: "Ver actualizacion",
      action_hint: "Abre tu bandeja de notificaciones para revisar el detalle del cambio.",
      accent_color: "#003d82",
    };
  }

  return {
    subject: "Nueva notificacion del sistema",
    title: "Notificacion de proyecto",
    message:
      "Se registro una actualizacion relacionada con tu proyecto. Consulta la plataforma para ver el detalle.",
    action_label: "Abrir notificaciones",
    action_hint: "Ingresa al sistema y revisa tu bandeja de notificaciones.",
    accent_color: "#003d82",
  };
}

async function call_rpc<T>(
  rpc_name: string,
  rpc_payload: Record<string, unknown>,
  service_role_key: string,
): Promise<T> {
  const supabase_url = Deno.env.get("SUPABASE_URL") ?? DEFAULT_SUPABASE_URL;

  const response = await fetch(
    `${supabase_url}/rest/v1/rpc/${rpc_name}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${service_role_key}`,
        apikey: service_role_key,
      },
      body: JSON.stringify(rpc_payload),
    },
  );

  const raw_body = await response.text();
  let parsed_body: unknown = null;
  if (raw_body) {
    try {
      parsed_body = JSON.parse(raw_body);
    } catch {
      parsed_body = raw_body;
    }
  }

  if (!response.ok) {
    const error_message =
      parsed_body &&
      typeof parsed_body === "object" &&
      "message" in parsed_body &&
      typeof parsed_body.message === "string"
        ? parsed_body.message
        : `RPC ${rpc_name} failed`;
    throw new Error(error_message);
  }

  return parsed_body as T;
}

async function mark_delivery_failed(
  delivery_id: number,
  error_message: string,
  service_role_key: string,
): Promise<void> {
  const marked = await call_rpc<boolean>(
    "mark_notifications_external_delivery_failed",
    {
      p_delivery_id: delivery_id,
      p_error_message: error_message,
    },
    service_role_key,
  );

  if (!marked) {
    throw new Error(`Delivery ${delivery_id} not marked as failed`);
  }
}

async function mark_delivery_sent(
  delivery_id: number,
  service_role_key: string,
): Promise<void> {
  const marked = await call_rpc<boolean>(
    "mark_notifications_external_delivery_sent",
    { p_delivery_id: delivery_id },
    service_role_key,
  );

  if (!marked) {
    throw new Error(`Delivery ${delivery_id} not marked as sent`);
  }
}

function build_email_text(delivery: claimed_delivery): string {
  const template = resolve_email_template(delivery);
  const recipient_name = delivery.recipient_name?.trim() || "usuario";

  return [
    "Universidad Santa Maria",
    "Sistema de Servicio Comunitario",
    "",
    `Hola ${recipient_name},`,
    "",
    template.title,
    template.message,
    "",
    `Accion recomendada: ${template.action_label}`,
    template.action_hint,
    "",
    "Este mensaje fue enviado automaticamente por el Sistema de Servicio Comunitario.",
  ].join("\n");
}

function build_email_html(delivery: claimed_delivery): string {
  const template = resolve_email_template(delivery);
  const recipient_name = escape_html(delivery.recipient_name?.trim() || "usuario");
  const safe_title = escape_html(template.title);
  const safe_message = escape_html(template.message);
  const safe_action_label = escape_html(template.action_label);
  const safe_action_hint = escape_html(template.action_hint);
  const accent_color = template.accent_color;

  return `
<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${safe_title}</title>
  </head>
  <body style="margin:0;padding:0;background:#f3f6fb;font-family:Arial,Helvetica,sans-serif;color:#16233b;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f3f6fb;padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #dbe3ee;">
            <tr>
              <td style="background:${accent_color};padding:22px 24px;color:#ffffff;">
                <p style="margin:0;font-size:12px;letter-spacing:.5px;text-transform:uppercase;opacity:.92;">Universidad Santa Maria</p>
                <h1 style="margin:8px 0 0;font-size:20px;line-height:1.3;">Sistema de Servicio Comunitario</h1>
              </td>
            </tr>
            <tr>
              <td style="padding:24px;">
                <p style="margin:0 0 8px;font-size:15px;line-height:1.6;">Hola ${recipient_name},</p>
                <h2 style="margin:0 0 10px;font-size:22px;line-height:1.35;color:${accent_color};">${safe_title}</h2>
                <p style="margin:0 0 16px;font-size:14px;line-height:1.7;color:#23354f;">${safe_message}</p>

                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 16px;border:1px solid #dbe3ee;background:#f9fbff;">
                  <tr>
                    <td style="padding:14px 16px;font-size:14px;line-height:1.7;">
                      <strong>Accion recomendada:</strong> ${safe_action_label}<br />
                      ${safe_action_hint}
                    </td>
                  </tr>
                </table>
              </td>
            </tr>

            <tr>
              <td style="padding:16px 24px;border-top:1px solid #dbe3ee;background:#fbfcff;font-size:12px;color:#4d6283;line-height:1.6;">
                Este mensaje fue generado automaticamente por el Sistema de Servicio Comunitario.<br />
                Universidad Santa Maria
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

async function send_local_email(delivery: claimed_delivery): Promise<void> {
  const template = resolve_email_template(delivery);

  const smtp_transporter = mailer.transporter({
    host: "inbucket",
    port: 1025,
    secure: false,
  });

  await smtp_transporter.send({
    from: "no-reply@usm.local",
    to: delivery.recipient_email,
    subject: `${template.subject} - Universidad Santa Maria`,
    text: build_email_text(delivery),
    html: build_email_html(delivery),
  });
}

Deno.serve(async (req) => {
  const notifications_edge_api_key = Deno.env.get("NOTIFICATIONS_EDGE_API_KEY");
  const fallback_edge_api_key = Deno.env.get("INVITATION_EDGE_API_KEY");
  const smtp_provider = Deno.env.get("SMTP_PROVIDER");
  const service_role_key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const expected_edge_api_key = notifications_edge_api_key ?? fallback_edge_api_key;

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!expected_edge_api_key || !service_role_key) {
    return new Response(
      JSON.stringify({
        error: "Missing required function environment variables",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  if (req.headers.get("x-api-key") !== expected_edge_api_key) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let batch_size = 100;

  try {
    const payload = await req.json();
    const payload_batch_size = Number(payload?.batch_size);
    if (Number.isFinite(payload_batch_size) && payload_batch_size > 0) {
      batch_size = Math.min(Math.floor(payload_batch_size), 1000);
    }
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (smtp_provider !== "local") {
    return new Response(
      JSON.stringify({
        error: `SMTP provider '${smtp_provider}' not supported for notifications external deliveries`,
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  let claimed_deliveries: claimed_delivery[] = [];
  try {
    claimed_deliveries = await call_rpc<claimed_delivery[]>(
      "claim_notifications_external_deliveries_queue",
      { p_batch_size: batch_size },
      service_role_key,
    );
  } catch (error) {
    const error_message = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: `Failed claiming deliveries: ${error_message}` }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  if (claimed_deliveries.length === 0) {
    return new Response(
      JSON.stringify({
        ok: true,
        message: "No deliveries to process",
        processed_count: 0,
        failed_count: 0,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  }

  let processed_count = 0;
  let failed_count = 0;

  for (const delivery of claimed_deliveries) {
    try {
      await send_local_email(delivery);
      await mark_delivery_sent(delivery.delivery_id, service_role_key);
      processed_count += 1;
    } catch (error) {
      const error_message = error instanceof Error ? error.message : String(error);
      await mark_delivery_failed(delivery.delivery_id, error_message, service_role_key);
      failed_count += 1;
    }
  }

  return new Response(
    JSON.stringify({
      ok: true,
      message: "Notifications external deliveries processed",
      claimed_count: claimed_deliveries.length,
      processed_count,
      failed_count,
    }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
});
