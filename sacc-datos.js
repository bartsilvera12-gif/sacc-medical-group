// Trae de Supabase los datos editables y los aplica sobre la pagina ya
// renderizada. Todo lo que toca tiene su valor en el HTML, asi que si Supabase
// no responde —o ni siquiera esta configurado— el sitio se ve igual que
// siempre. Nunca deja un hueco.
(function () {
  'use strict';

  if (window.__saccDatos) return;
  window.__saccDatos = true;

  var cfg = window.SACC_SUPABASE || {};
  if (!cfg.URL || !cfg.ANON_KEY) return;

  var base = cfg.URL.replace(/\/+$/, '');
  var cabeceras = {
    apikey: cfg.ANON_KEY,
    Authorization: 'Bearer ' + cfg.ANON_KEY,
    'Accept-Profile': cfg.ESQUEMA || 'sacc',
  };

  function traer(tabla) {
    return fetch(base + '/rest/v1/' + tabla + '?select=*', { headers: cabeceras })
      .then(function (r) { return r.ok ? r.json() : null; })
      .catch(function () { return null; });
  }

  // El sitio principal traduce por diccionario y vuelve a escribir el texto en
  // cada cambio de idioma, asi que los valores se guardan y se reaplican.
  var datos = { contacto: null };

  function idioma() {
    return (document.documentElement.lang || 'es').toLowerCase().indexOf('en') === 0 ? 'en' : 'es';
  }

  function aplicarContacto() {
    var c = datos.contacto;
    if (!c) return;
    var en = idioma() === 'en';

    if (c.email) {
      document.querySelectorAll('a[href^="mailto:"]').forEach(function (a) {
        a.setAttribute('href', 'mailto:' + c.email);
        if (a.textContent.indexOf('@') !== -1) a.textContent = c.email;
      });
      document.querySelectorAll('[data-sacc="email"]').forEach(function (el) {
        el.textContent = c.email;
      });
    }
    if (c.linkedin) {
      document.querySelectorAll('a[href*="linkedin.com"]').forEach(function (a) {
        a.setAttribute('href', c.linkedin);
      });
    }
    var sede = en ? c.sede_en : c.sede_es;
    if (sede) {
      document.querySelectorAll('[data-sacc="sede"]').forEach(function (el) {
        el.textContent = sede;
      });
    }
    var bajada = en ? c.bajada_en : c.bajada_es;
    if (bajada) {
      document.querySelectorAll('[data-sacc="contacto-bajada"]').forEach(function (el) {
        el.textContent = bajada;
      });
    }
  }

  function aplicarImagenes(filas) {
    if (!filas) return;
    filas.forEach(function (f) {
      if (!f.url) return;
      var slot = document.getElementById(f.slot);
      if (slot && slot.tagName.toLowerCase() === 'image-slot') {
        slot.setAttribute('src', f.url);
        var alt = idioma() === 'en' ? f.alt_en : f.alt_es;
        if (alt) slot.setAttribute('placeholder', alt);
      } else {
        // En paginas sueltas la foto es un <img> comun.
        document.querySelectorAll('img[data-sacc-slot="' + f.slot + '"]').forEach(function (img) {
          img.setAttribute('src', f.url);
        });
      }
    });
  }

  Promise.all([traer('contacto'), traer('imagenes')]).then(function (res) {
    var c = res[0];
    if (c && c.length) {
      datos.contacto = c[0];
      aplicarContacto();
      // El re-render por cambio de idioma pisa el texto: se vuelve a aplicar.
      ['click', 'keyup'].forEach(function (ev) {
        document.addEventListener(ev, function () { setTimeout(aplicarContacto, 60); }, true);
      });
    }
    aplicarImagenes(res[1]);
  });
})();
