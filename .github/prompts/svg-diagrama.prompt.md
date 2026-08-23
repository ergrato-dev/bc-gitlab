---
name: "Diagrama SVG"
description: "Genera un diagrama SVG para el bootcamp: tema oscuro, paleta de GitLab, sin degradados, accesible y legible a 900 px de ancho."
argument-hint: "Semana, nombre del archivo (ej: 01-anatomia-de-un-pipeline.svg) y qué tiene que mostrar"
mode: "agent"
---

# Diagrama SVG — Bootcamp GitLab CE

**Arte ASCII prohibido.** Un diagrama de cajas dibujado con guiones se rompe en
cuanto cambia la fuente o el ancho del contenedor.

## Paleta

| Color | Hex | Uso |
|---|---|---|
| Naranja GitLab | `#FC6D26` | Elemento principal, el que el diagrama explica |
| Naranja oscuro | `#E24329` | Acento, estados de error |
| Morado | `#554488` | Secundario |
| Verde | `#108548` | Éxito |
| Fondo | `#1F1F1F` | Lienzo |
| Caja | `#2B2B2B` | Relleno de cajas |
| Texto | `#FAFAFA` | Etiquetas |
| Texto apagado | `#999999` | Notas al margen |
| Línea | `#666666` | Bordes y conectores |

## Reglas técnicas

- `viewBox` obligatorio; nada de `width`/`height` fijos en el elemento raíz.
- Ancho de referencia 900, alto el que pida el contenido.
- `font-family="system-ui, -apple-system, Segoe UI, Roboto, sans-serif"`.
- Tamaño de texto mínimo 13. Por debajo no se lee en el README de GitHub.
- **Sin degradados, sin sombras, sin transparencias.**
- **Sin fuentes externas ni imágenes embebidas.** El SVG es autónomo.
- Contraste mínimo 4.5:1 entre texto y su fondo.
- `<title>` como primer hijo del `<svg>`: es lo que leen los lectores de pantalla.
- Nada de texto en `<image>` ni convertido a trazados: tiene que ser `<text>`.

## Plantilla

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 400" role="img" aria-labelledby="titulo">
  <title id="titulo">Anatomía de un pipeline de GitLab CI/CD</title>
  <rect width="900" height="400" fill="#1F1F1F"/>

  <g font-family="system-ui, -apple-system, Segoe UI, Roboto, sans-serif">
    <!-- Caja -->
    <rect x="40" y="60" width="180" height="80" rx="6" fill="#2B2B2B" stroke="#FC6D26" stroke-width="2"/>
    <text x="130" y="95" fill="#FAFAFA" font-size="16" font-weight="600" text-anchor="middle">stage: build</text>
    <text x="130" y="118" fill="#999999" font-size="13" text-anchor="middle">compila la app</text>

    <!-- Conector -->
    <line x1="220" y1="100" x2="290" y2="100" stroke="#666666" stroke-width="2" marker-end="url(#flecha)"/>
  </g>

  <defs>
    <marker id="flecha" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#666666"/>
    </marker>
  </defs>
</svg>
```

## Nombrado y ubicación

`bootcamp/week-NN-tema/0-assets/NN-nombre-descriptivo.svg`, numerados en orden
de lectura dentro de la semana.

## Reglas de contenido

- **Un diagrama, una idea.** Si necesitas explicar dos cosas, son dos diagramas.
- Etiqueta con los nombres reales de GitLab (`stage`, `needs`, `artifacts`), no
  con genéricos.
- Si el diagrama muestra un flujo, la dirección de lectura es de izquierda a
  derecha o de arriba abajo, nunca las dos a la vez.
- Máximo 7-8 elementos. Más que eso, no se lee.

## Antes de entregar

- [ ] El SVG está enlazado desde algún `.md` (si no, `verificar-enlaces.sh` falla)
- [ ] Abre bien en un navegador y se lee a 900 px
- [ ] Tiene `<title>` y `role="img"`
- [ ] Sin degradados, sombras ni recursos externos
- [ ] Los nombres que aparecen son los reales de GitLab

$input
