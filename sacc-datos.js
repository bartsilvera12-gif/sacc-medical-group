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

  // ---------------------------------------------------------------- listas
  // Areas y principios son listas de largo variable. Se reconstruyen clonando
  // la primera tarjeta que ya esta en el HTML: asi el estilo no se duplica
  // aca y cualquier retoque de diseño se propaga solo.
  function reconstruir(contenedor, filas, pintar) {
    if (!contenedor || !filas || !filas.length) return false;
    var molde = contenedor.firstElementChild;
    if (!molde) return false;
    var visibles = filas.filter(function (f) { return f.visible !== false; })
      .sort(function (a, b) { return (a.orden || 0) - (b.orden || 0); });
    if (!visibles.length) return false;
    var nuevos = visibles.map(function (fila, i) {
      var el = molde.cloneNode(true);
      pintar(el, fila, i);
      return el;
    });
    contenedor.textContent = '';
    nuevos.forEach(function (el) { contenedor.appendChild(el); });
    return true;
  }

  function aplicarAreas(filas) {
    var en = idioma() === 'en';
    var lista = document.querySelector('[data-area]');
    lista = lista && lista.parentElement;
    var ok = reconstruir(lista, filas, function (el, f, i) {
      el.setAttribute('data-area', String(i));
      el._areaLista = false;
      var t = el.querySelector('h3');
      if (t) t.textContent = en ? (f.titulo_en || f.titulo_es) : f.titulo_es;
      var p = el.querySelector('p');
      if (p) p.textContent = en ? (f.descripcion_en || f.descripcion_es) : f.descripcion_es;
    });
    if (!ok) return;

    // La pila de imagenes sticky sigue a las fichas, una por area.
    var pila = document.querySelector('[data-area-img]');
    pila = pila && pila.parentElement;
    reconstruir(pila, filas, function (el, f, i) {
      el.setAttribute('data-area-img', String(i));
      var slot = el.querySelector('image-slot');
      if (slot) {
        slot.id = 'sacc-area-' + (i + 1);
        if (f.imagen_url) slot.setAttribute('src', f.imagen_url);
      }
    });
    if (window.__saccPintarAreas) window.__saccPintarAreas();
  }

  function aplicarPrincipios(filas) {
    var en = idioma() === 'en';
    // El efecto 3D guarda referencias a las tarjetas viejas: hay que rearmarlo.
    var uno = document.querySelector('[data-principio]');
    var lista = uno && uno.parentElement;
    reconstruir(lista, filas, function (el, f, i) {
      el.removeAttribute('data-shown');
      el.style.opacity = '';
      el.style.transform = '';
      var titulo = el.querySelector('[data-principio-titulo]');
      if (titulo) titulo.textContent = en ? (f.titulo_en || f.titulo_es) : f.titulo_es;
      var p = el.querySelector('[data-principio-texto]');
      if (p) p.textContent = en ? (f.texto_en || f.texto_es) : f.texto_es;
    });
    if (window.__saccInitCards3D) window.__saccInitCards3D();
  }

  Promise.all([traer('contacto'), traer('imagenes'), traer('areas'), traer('principios')]).then(function (res) {
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
    aplicarAreas(res[2]);
    aplicarPrincipios(res[3]);
  });
})();
