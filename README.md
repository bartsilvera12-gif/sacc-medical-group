# SACC Medical Group

Sitio web institucional de SACC Medical Group — soluciones integrales para la
introducción, desarrollo y comercialización de productos médicos y farmacéuticos
en el mercado paraguayo.

## Cómo verlo

Es un sitio estático: no requiere build ni dependencias. Basta con servir la
carpeta con cualquier servidor estático.

```bash
npx serve . -l 4321
```

Y abrir `http://localhost:4321/SACC Medical Group.dc.html`.

## Estructura

| Archivo | Contenido |
|---|---|
| `SACC Medical Group.dc.html` | El sitio completo: markup, estilos y lógica |
| `politica-de-privacidad.html` | Página legal (texto genérico, pendiente de completar) |
| `support.js`, `image-slot.js` | Runtime del canvas de diseño |
| `uploads/` | Imágenes, video del hero, tipografías y assets de marca |

## Detalles de implementación

Todo es nativo, sin frameworks ni dependencias externas:

- **Bilingüe ES/EN** mediante un diccionario bidireccional que reemplaza los
  nodos de texto según el idioma activo.
- **Seis efectos en canvas**: mapamundi punteado con arcos de conexión, globo 3D
  rotando, mapa topográfico por marching squares, mapa de Paraguay extruido con
  sus departamentos interactivos, apilado del hero y tarjetas con inclinación 3D.
- **Sin dependencias de red**: tipografías, imágenes y datos geográficos están
  todos servidos desde el propio repositorio.

## Créditos

Fotografías de [Unsplash](https://unsplash.com) bajo su licencia de uso libre.
Geometría de los departamentos de Paraguay de
[geoBoundaries](https://www.geoboundaries.org) (ADM1) y contornos mundiales de
[world-atlas](https://github.com/topojson/world-atlas).

Desarrollado por [Neura](https://neura.com.py).

## Despliegue en Vercel

El punto de entrada se llama `SACC Medical Group.dc.html` (con espacios), así que la
raíz del dominio no encontraría un `index.html`. `vercel.json` resuelve eso:

| Ruta | Sirve |
| --- | --- |
| `/` | `SACC Medical Group.dc.html` (reescritura interna, la URL no cambia) |
| `/nosotros` | `nosotros.html` |
| `/privacidad` | `politica-de-privacidad.html` |

Pasos para publicar:

1. En [vercel.com/new](https://vercel.com/new), importar el repositorio
   `bartsilvera12-gif/sacc-medical-group`.
2. Framework Preset: **Other**. Sin Build Command, sin Output Directory, sin Install
   Command — es un sitio estático.
3. Deploy. Cada `git push` a `master` vuelve a desplegar automáticamente.

No hay paso de compilación: el archivo `.dc.html` sigue editándose igual que en local.

## Video del hero

El original (`uploads/15249530_1920_1080_30fps.mp4`, 14 MB a 11 Mbps) no se
publica: queda en local y está en `.gitignore`. Lo que se sirve son versiones
comprimidas con ffmpeg, elegidas por ancho de pantalla en `initVideo()`:

| Archivo | Uso | Peso |
| --- | --- | --- |
| `uploads/hero-poster.jpg` | primer fotograma, se ve mientras carga el video | 66 KB |
| `uploads/hero-480.mp4` | pantallas < 700 px | 668 KB |
| `uploads/hero-720.mp4` | pantallas ≥ 700 px | 1,4 MB |

Para regenerarlas a partir de otro video:

```bash
ffmpeg -i ORIGEN.mp4 -vf scale=1152:-2 -c:v libx264 -preset veryslow -crf 30 -pix_fmt yuv420p -an -movflags +faststart uploads/hero-720.mp4
ffmpeg -i ORIGEN.mp4 -vf scale=720:-2  -c:v libx264 -preset slow     -crf 29 -pix_fmt yuv420p -an -movflags +faststart uploads/hero-480.mp4
ffmpeg -ss 0.5 -i ORIGEN.mp4 -frames:v 1 -vf scale=1280:-2 -q:v 6 uploads/hero-poster.jpg
```

## Comportamiento responsive

`applyResponsive()` no usa media queries (los estilos son inline): mide y
reescribe. Hay dos umbrales:

- **< 900 px** — las grillas de más de dos columnas pasan a dos, los `sticky`
  se degradan a `relative` y los pilares del modelo pierden su `min-height`.
- **< 620 px** — todo pasa a una sola columna.

El menú se vuelve hamburguesa cuando los enlaces no entran (medido, no fijo), y
en ese momento se oculta también el botón "Asociarse con SACC" para dejarle
sitio.

La línea de proceso de "Acceso al mercado" es la excepción: no la toca la regla
genérica de grillas, la maneja `layoutProceso()`. Por debajo de 900px rota
entera — el riel pasa de horizontal arriba a vertical por la izquierda, cada
paso se vuelve una fila "punto · número · etiqueta", y la barra de avance
anima `height` en vez de `width`.

### Scroll táctil sobre las imágenes

`image-slot.js` marca su `<img>` y su capa de arrastre con `touch-action: none`
para poder reencuadrar la foto en el editor. En el sitio publicado eso hace que
apoyar el dedo sobre una imagen cancele el scroll. `liberarTactil()` inyecta una
hoja en cada shadow root que lo devuelve a `pan-y pinch-zoom`, y solo restituye
`none` mientras el slot lleva el atributo `data-reframe` — es decir, mientras se
está reencuadrando de verdad dentro del canvas.

## La pagina /nosotros

Es un HTML aparte, no una seccion del canvas: portada, capacidades, mision y
vision. Repite el header, el menu y el pie del sitio en CSS propio, y comparte
el idioma elegido a traves de `localStorage.sacc-lang`, que el sitio principal escribe
en `setEs`/`setEn` y lee al montar.

El header ya no alterna con el scroll: nace solido y lleva siempre el boton de
contacto. Como en un celular no entran a la vez logotipo, idioma, boton y
hamburguesa, `ajustarCta()` mide y va soltando en orden: aprieta el boton, quita el
selector de idioma, quita la bajada del logotipo y recien entonces esconde el
boton, que igual esta dentro del menu.
