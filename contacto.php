<?php
// Aviso por correo de las consultas del formulario de contacto.
//
// Corre en Hostinger, el mismo servidor donde vive la casilla info@. Por eso
// el correo se entrega localmente y sale desde el propio dominio, cuyo SPF/DKIM
// ya configura Hostinger para sus casillas. No guarda nada: el guardado lo hace
// Supabase (sacc.mensajes) y se lee desde el panel. Esto solo notifica.
//
// El navegador llama a este archivo despues de guardar en Supabase, asi que el
// aviso solo se manda cuando la consulta ya quedo registrada. Si este envio
// falla (por ejemplo en un host sin PHP), no pasa nada: la consulta ya esta
// guardada y el usuario ya vio la confirmacion.

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(['ok' => false]);
  exit;
}

// A donde llega el aviso y desde que casilla sale. Las dos son la misma casilla
// real del dominio: entrega local y remitente autorizado, sin contrasenas.
$DESTINO   = 'info@saccmedicalgroup.com';
$REMITENTE = 'info@saccmedicalgroup.com';

// El cuerpo llega como JSON (lo manda el formulario) o, por las dudas, como form.
$raw = file_get_contents('php://input');
$d = json_decode($raw, true);
if (!is_array($d)) { $d = $_POST; }

function limpio($v, $max = 2000) {
  $v = is_string($v) ? trim($v) : '';
  // Sin saltos de linea en los campos cortos: evita inyeccion de cabeceras.
  return mb_substr($v, 0, $max);
}
function unaLinea($v, $max = 200) {
  return preg_replace('/[\r\n]+/', ' ', limpio($v, $max));
}

// Trampa anti-bots: si el campo oculto vino relleno, respondemos ok y no
// mandamos nada, para no darle una pista al robot.
if (unaLinea($d['sacc-sitio'] ?? ($d['website'] ?? '')) !== '') {
  echo json_encode(['ok' => true]);
  exit;
}

$nombre  = unaLinea($d['nombre']   ?? '', 200);
$empresa = unaLinea($d['empresa']  ?? '', 200);
$email   = unaLinea($d['email']    ?? '', 200);
$tel     = unaLinea($d['telefono'] ?? '', 100);
$interes = unaLinea($d['interes']  ?? '', 200);
$origen  = unaLinea($d['origen']   ?? '', 200);
$mensaje = limpio($d['mensaje']    ?? '', 5000);

// Validacion minima. La fuerte ya la hizo el navegador y las reglas de Supabase.
if ($nombre === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($mensaje) < 10) {
  http_response_code(422);
  echo json_encode(['ok' => false]);
  exit;
}

$asunto = 'Nueva consulta del sitio — ' . $nombre;

$cuerpo = implode("\r\n", [
  'Nueva consulta recibida desde el formulario del sitio.',
  '',
  'Nombre:   ' . $nombre,
  'Empresa:  ' . ($empresa !== '' ? $empresa : '—'),
  'Correo:   ' . $email,
  'Telefono: ' . ($tel !== '' ? $tel : '—'),
  'Interes:  ' . ($interes !== '' ? $interes : '—'),
  'Origen:   ' . ($origen !== '' ? $origen : '—'),
  '',
  'Mensaje:',
  $mensaje,
  '',
  '—',
  'Para responder, basta con contestar este correo: va directo a quien escribio.',
]);

// Reply-To apunta al que escribio: al dar "Responder" en info@, el mail va a el.
$headers = implode("\r\n", [
  'From: SACC Medical Group <' . $REMITENTE . '>',
  'Reply-To: ' . $nombre . ' <' . $email . '>',
  'MIME-Version: 1.0',
  'Content-Type: text/plain; charset=UTF-8',
  'Content-Transfer-Encoding: 8bit',
  'X-Mailer: SACC-Form',
]);

// Asunto codificado en UTF-8 para que los acentos y el guion no se rompan.
$asuntoEnc = '=?UTF-8?B?' . base64_encode($asunto) . '?=';

// El 5.o parametro fija el Return-Path en la casilla del dominio: ayuda al SPF.
$ok = @mail($DESTINO, $asuntoEnc, $cuerpo, $headers, '-f' . $REMITENTE);

if (!$ok) { http_response_code(502); }
echo json_encode(['ok' => (bool)$ok]);
