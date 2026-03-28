type invitation_template_params = {
  email: string;
  role: string;
  token: string;
  expires_at: string;
};

const role_labels: Record<string, string> = {
  student: "Estudiante",
  tutor: "Tutor",
  coordinator: "Coordinador",
  dean: "Decano",
  administrative: "Administrativo",
  sysadmin: "Administrador del Sistema",
};

function resolve_role_label(role: string): string {
  const role_key = role.trim().toLowerCase();
  return role_labels[role_key] ?? role;
}

export function build_invitation_email_text(
  params: invitation_template_params,
): string {
  const role_label = resolve_role_label(params.role);

  return [
    "Universidad Santa Maria",
    "Sistema de Servicio Comunitario",
    "",
    "Hola,",
    "",
    "Has sido invitado para registrarte en el sistema.",
    `Correo invitado: ${params.email}`,
    `Rol asignado: ${role_label}`,
    "",
    `Codigo de invitacion: ${params.token}`,
    `Vence: ${params.expires_at}`,
    "",
    "Instrucciones:",
    "1) Abre la pantalla de registro del sistema.",
    "2) Ingresa tu codigo de invitacion.",
    "3) Completa tus datos y finaliza el registro.",
    "",
    "No compartas este codigo con terceros.",
    "Si no esperabas esta invitacion, ignora este mensaje.",
    "",
    "Soporte: servicio.comunitario@usm.edu.ve",
  ].join("\n");
}

export function build_invitation_email_html(
  params: invitation_template_params,
): string {
  const role_label = resolve_role_label(params.role);

  return `
<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Invitacion al Sistema de Servicio Comunitario</title>
  </head>
  <body style="margin:0;padding:0;background:#f3f6fb;font-family:Arial,Helvetica,sans-serif;color:#16233b;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f3f6fb;padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #dbe3ee;">
            <tr>
              <td style="background:#003d82;padding:22px 24px;color:#ffffff;">
                <p style="margin:0;font-size:12px;letter-spacing:.5px;text-transform:uppercase;opacity:.92;">Universidad Santa Maria</p>
                <h1 style="margin:8px 0 0;font-size:20px;line-height:1.3;">Invitacion al Sistema de Servicio Comunitario</h1>
              </td>
            </tr>

            <tr>
              <td style="padding:24px;">
                <p style="margin:0 0 12px;font-size:15px;line-height:1.6;">Hola, has sido invitado para registrarte en el sistema.</p>

                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 16px;border:1px solid #dbe3ee;background:#f9fbff;">
                  <tr>
                    <td style="padding:14px 16px;font-size:14px;line-height:1.7;">
                      <strong>Correo invitado:</strong> ${params.email}<br />
                      <strong>Rol asignado:</strong> ${role_label}<br />
                      <strong>Vigencia:</strong> ${params.expires_at}
                    </td>
                  </tr>
                </table>

                <p style="margin:0 0 8px;font-size:13px;text-transform:uppercase;letter-spacing:.4px;color:#35517a;">Codigo de invitacion</p>
                <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 18px;">
                  <tr>
                    <td style="padding:14px 20px;border:2px dashed #003d82;background:#eef4ff;font-size:30px;font-weight:700;letter-spacing:7px;color:#003d82;">
                      ${params.token}
                    </td>
                  </tr>
                </table>

                <p style="margin:0 0 8px;font-size:14px;"><strong>Como usar este codigo:</strong></p>
                <ol style="margin:0 0 14px;padding-left:18px;font-size:14px;line-height:1.7;">
                  <li>Abre la pantalla de registro del sistema.</li>
                  <li>Ingresa tu codigo de invitacion.</li>
                  <li>Completa tus datos y finaliza tu registro.</li>
                </ol>

                <p style="margin:0 0 8px;font-size:13px;line-height:1.6;color:#3f4f68;">
                  No compartas este codigo con terceros. Si no esperabas esta invitacion, puedes ignorar este mensaje.
                </p>
              </td>
            </tr>

            <tr>
              <td style="padding:16px 24px;border-top:1px solid #dbe3ee;background:#fbfcff;font-size:12px;color:#4d6283;line-height:1.6;">
                Soporte: servicio.comunitario@usm.edu.ve<br />
                Sistema de Servicio Comunitario - Universidad Santa Maria
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}
