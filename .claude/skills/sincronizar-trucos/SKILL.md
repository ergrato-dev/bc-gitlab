---
name: sincronizar-trucos
description: Mantiene sincronizada la sección "🎩 Trucos y atajos" de cada README de semana con el cheatsheet acumulativo docs/trucos-gitlab.md. Usar tras crear o editar la sección de trucos de cualquier semana, y antes de cerrar una semana.
allowed-tools: Bash(grep*) Bash(awk*) Bash(find*) Read Edit Grep Glob
---

# Sincronizar trucos

`docs/trucos-gitlab.md` es la unión de todas las secciones "🎩 Trucos y atajos"
de los READMEs de semana. Crece con el alumno: al terminar la semana 26 es su
cheatsheet completo.

**Fuente de verdad: el README de la semana.** Si los dos lados difieren, gana el
README y se corrige el cheatsheet.

## Procedimiento

### 1. Extraer los trucos de la semana

```bash
awk '/^## 🎩 Trucos y atajos/,/^## /' bootcamp/week-NN-*/README.md
```

Los trucos son una tabla `| Truco | Cómo |`. Cuéntalos.

### 2. Localizar la sección en el cheatsheet

```bash
grep -n '^## Semana' docs/trucos-gitlab.md
```

Las secciones van en orden numérico, después de las dos secciones globales
(atajos de teclado y URLs ocultas) y del comentario marcador.

### 3. Comparar y corregir

| Situación | Qué hacer |
|---|---|
| La sección de la semana no existe en el cheatsheet | Créala, en su posición numérica |
| Está pero le faltan filas | Añade las que faltan, en el mismo orden que el README |
| Tiene filas que el README ya no tiene | Bórralas del cheatsheet |
| El texto difiere | Gana el README |
| Un truco se repite en dos semanas | Déjalo en la primera y quítalo de la segunda; si es de uso general, súbelo a las secciones globales de cabecera |

Formato de la sección en el cheatsheet:

```markdown
## Semana NN — Tema de la semana

| Truco | Cómo |
|---|---|
| ... | ... |
```

### 4. Comprobar

```bash
bash scripts/verificar-enlaces.sh
```

## Reglas

- **Solo tocas `docs/trucos-gitlab.md`.** El README de la semana no se modifica
  desde aquí: si un truco está mal, se arregla en su semana y luego se
  sincroniza.
- **No inventes trucos** para rellenar una sección corta. Tres trucos buenos
  valen más que diez de relleno.
- **No reordenes** los trucos dentro de una semana: el orden del README es
  deliberado.
- Las dos secciones globales de cabecera (atajos de teclado, URLs ocultas) no se
  tocan salvo que se suba a ellas un truco que resultó ser de uso general.

## Salida

Qué se añadió, qué se borró y qué se corrigió, una línea por cambio. Si no hubo
ninguno: `OK: trucos sincronizados.`
