// Envio del formulario de contacto.
//
// El mensaje se guarda en sacc.mensajes, en Supabase, y se lee desde el panel.
// Guardar y no mandar correo es a proposito: la casilla corporativa todavia no
// existe, y enviar correo desde el navegador exigiria una credencial de un
// proveedor de envio, que no puede vivir en el codigo publico. Guardando, no
// se pierde ninguna consulta mientras tanto; el reenvio por correo se enchufa
// despues sin tocar el formulario.
//
// El listener va delegado en document y no en el formulario: la pagina se
// renderiza con React en tiempo de ejecucion y vuelve a crear nodos en cada
// cambio de idioma, asi que un listener atado al nodo se perderia.
(function () {
  'use strict';

  if (window.__saccFormulario) return;
  window.__saccFormulario = true;

  var TEXTOS = {
    es: {
      faltan: 'Completá los campos obligatorios: nombre, correo y mensaje.',
      correo: 'Revisá el correo electrónico: no parece válido.',
      corto: 'Contanos un poco más: el mensaje necesita al menos 10 caracteres.',
      enviando: 'Enviando…',
      listo: 'Gracias. Recibimos tu mensaje y te vamos a responder a la brevedad.',
      falla: 'No pudimos enviar el mensaje. Escribinos directamente a ',
      fallaSin: 'No pudimos enviar el mensaje. Volvé a intentarlo en unos minutos.',
    },
    en: {
      faltan: 'Please complete the required fields: name, email and message.',
      correo: 'Please check the email address: it does not look valid.',
      corto: 'Please tell us a bit more: the message needs at least 10 characters.',
      enviando: 'Sending…',
      listo: 'Thank you. We have received your message and will reply shortly.',
      falla: 'We could not send the message. Please write to us directly at ',
      fallaSin: 'We could not send the message. Please try again in a few minutes.',
    },
  };

  function idioma() {
    try {
      return localStorage.getItem('sacc-lang') === 'EN' ? 'en' : 'es';
    } catch (e) { return 'es'; }
  }

  // Si el envio falla, se ofrece la direccion que el propio sitio muestra, en
  // vez de una escrita a mano aca: asi sigue al panel si la cambian.
  function correoDelSitio() {
    var el = document.querySelector('[data-sacc="email"]');
    var t = el && el.textContent ? el.textContent.trim() : '';
    return /.+@.+\..+/.test(t) ? t : '';
  }

  function aviso(form, texto, tono) {
    var p = form.querySelector('[data-form-aviso]');
    if (!p) return;
    p.textContent = texto;
    p.style.color = tono === 'mal' ? '#9C3A26' : (tono === 'bien' ? '#3F6B44' : '#485463');
  }

  function valor(form, id) {
    var el = form.querySelector('#' + id);
    return el && el.value ? el.value.trim() : '';
  }

  // Aviso por correo a info@, best-effort. Corre solo despues de guardar en
  // Supabase, asi que la consulta ya quedo registrada pase lo que pase aca. Si
  // el host no tiene PHP (o el envio falla), se ignora en silencio: el guardado
  // ya ocurrio y el usuario ya vio la confirmacion.
  function notificar(datos) {
    try {
      fetch('contacto.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(datos),
        keepalive: true,
      }).catch(function () {});
    } catch (e) {}
  }

  document.addEventListener('submit', function (ev) {
    var form = ev.target;
    if (!form || !form.hasAttribute || !form.hasAttribute('data-form-contacto')) return;
    ev.preventDefault();

    var t = TEXTOS[idioma()];

    // La trampa: si vino rellena, es un robot. Se simula exito y no se manda
    // nada, para no darle una pista de que fue detectado.
    if (valor(form, 'sacc-sitio')) { aviso(form, t.listo, 'bien'); form.reset(); return; }

    var datos = {
      nombre: valor(form, 'sacc-nombre'),
      empresa: valor(form, 'sacc-empresa') || null,
      email: valor(form, 'sacc-email'),
      telefono: valor(form, 'sacc-telefono') || null,
      interes: valor(form, 'sacc-interes') || null,
      mensaje: valor(form, 'sacc-mensaje'),
      origen: (location.pathname || '/').slice(0, 120),
    };

    if (!datos.nombre || !datos.email || !datos.mensaje) { aviso(form, t.faltan, 'mal'); return; }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(datos.email)) { aviso(form, t.correo, 'mal'); return; }
    if (datos.mensaje.length < 10) { aviso(form, t.corto, 'mal'); return; }

    var cfg = window.SACC_SUPABASE || {};
    var boton = form.querySelector('[data-form-enviar]');
    var fallar = function () {
      var mail = correoDelSitio();
      aviso(form, mail ? t.falla + mail : t.fallaSin, 'mal');
      if (boton) { boton.disabled = false; boton.style.opacity = ''; }
    };

    if (!cfg.URL || !cfg.ANON_KEY) { fallar(); return; }

    if (boton) { boton.disabled = true; boton.style.opacity = '.55'; }
    aviso(form, t.enviando, '');

    fetch(cfg.URL.replace(/\/+$/, '') + '/rest/v1/mensajes', {
      method: 'POST',
      headers: {
        apikey: cfg.ANON_KEY,
        Authorization: 'Bearer ' + cfg.ANON_KEY,
        'Content-Type': 'application/json',
        'Content-Profile': cfg.ESQUEMA || 'sacc',
        // Sin esto PostgREST intenta devolver la fila insertada, y anon no
        // tiene permiso de lectura sobre la tabla: el insert quedaria bien
        // pero la respuesta daria error.
        Prefer: 'return=minimal',
      },
      body: JSON.stringify(datos),
    }).then(function (r) {
      if (!r.ok) { fallar(); return; }
      notificar(datos);
      aviso(form, t.listo, 'bien');
      form.reset();
      if (boton) { boton.disabled = false; boton.style.opacity = ''; }
    }).catch(fallar);
  }, true);
})();
