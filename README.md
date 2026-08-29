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
