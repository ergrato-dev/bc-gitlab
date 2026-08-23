---
name: "Nueva práctica"
description: "Genera una práctica del Bootcamp GitLab CE: operaciones reales sobre la instancia, cada paso con Por qué / Con la UI / Con glab / Verifica, y cierre con checklist y tabla de errores."
argument-hint: "Semana (ej: 07), número y título de la práctica, y qué tiene que conseguir el alumno"
mode: "agent"
---

# Nueva práctica — Bootcamp GitLab CE

## Qué es una práctica aquí

**Operaciones sobre GitLab, no código en `starter/`.** El entregable es el
estado real de la instancia del alumno, y se verifica con la API v4.

Solo las semanas con código de apoyo (pipelines, scripts de API, Terraform)
llevan `starter/`, y aun así el entregable sigue siendo el estado de la
instancia.

## Estructura obligatoria

```markdown
# Práctica NN — Título

> Una línea: qué vas a conseguir.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada — `main` protegida

## Contexto

Un escenario de equipo reconocible. Dos o tres frases. Por qué alguien haría
esto en un trabajo real.

## Paso 1: …

**Por qué**: el motivo, antes del comando.

**Con la UI**: `Settings → Repository → Protected branches`, …

**Con `glab`**:

```bash
glab api --method POST "projects/:id/protected_branches" -f name=main
```

**Verifica**:

```bash
glab api "projects/:id/protected_branches" | jq '.[].name'
# "main"
```

## Paso 2: …

## ✅ Resultado

- [ ] Casilla verificable
- [ ] Casilla verificable

```bash
./scripts/verificar-semana.sh NN
```

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|

## 🔗 Navegación
```

## Extensión

200-310 líneas. Entre 8 y 9 pasos.

## Reglas

1. **Todo paso termina en una verificación ejecutable.** Sin excepción. Si un
   paso no se puede verificar, replantéalo.
2. **El porqué antes del comando.** Un comando sin motivo es una receta.
3. **UI y `glab`.** Las dos vías, siempre que existan las dos.
4. **Aviso antes de lo destructivo**, con el backup delante:

   ```markdown
   > [!WARNING]
   > Este paso borra los datos de la instancia. Haz backup primero:
   > `docker compose exec gitlab /opt/lab/lab-backup`
   ```

5. **Para semanas con código, patrón de descomentar**:

   ```yaml
   # PASO 4: añade el stage de despliegue.
   # Descomenta las siguientes líneas:
   # deploy:
   #   stage: deploy
   #   script: ./deploy.sh
   ```

6. **❌ No uses `# TODO:`.** Eso es formato de proyecto, no de práctica.
7. **La tabla de errores es obligatoria** y sale de haber hecho la práctica de
   verdad, no de imaginar fallos.
8. **Los pasos avanzan el proyecto del alumno**, no crean cosas desechables.
9. **No inventes comandos ni endpoints.** Compruébalos.

## Antes de entregar

- [ ] Entre 200 y 310 líneas, 8-9 pasos
- [ ] Cada paso: Por qué, comando (UI y `glab`), Verifica
- [ ] La duración declarada encaja con el presupuesto de 8 h de la semana
- [ ] Los prerrequisitos apuntan a algo que existe en una semana anterior
- [ ] Cierra con `## ✅ Resultado` y `## 🧯 Si algo sale mal`
- [ ] Lo que la práctica consigue está cubierto por alguna entrada de `checks.json`

$input
