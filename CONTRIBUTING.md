# Contribuir

Gracias por el interés. Este repositorio es material educativo, así que lo que más ayuda no es siempre código.

---

## Qué aporta más

| Tipo | Por qué importa |
|---|---|
| **Un comando o endpoint que ya no existe** | GitLab cambia. Un ejemplo que revienta al ejecutarlo es el peor fallo posible aquí |
| **Un paso que no se entiende** | Si tuviste que releerlo tres veces, el problema es del texto |
| **Un error real con su solución** | Alimenta la tabla "Si algo sale mal" de la práctica correspondiente |
| **Una diferencia de versión** | "En 19.2 esto está en otro sitio" ahorra una hora a quien venga detrás |
| **Un truco** | Si te ahorró tiempo, ahorrará el de otro |

Para todo eso, un [issue](https://github.com/ergrato-dev/bc-gitlab/issues) es suficiente. No hace falta que abras un pull request.

---

## Pull requests

Se aceptan, pero ten en cuenta que este repositorio **cierra automáticamente los PR externos** y continúa la conversación en el issue. No es desconfianza: el material se escribe en tandas de una semana completa y un cambio suelto suele descolocar la coherencia entre teoría, prácticas, rúbrica y `checks.json`.

Abre primero un issue. Si el cambio encaja, se te dirá por dónde entrarlo.

---

## Si escribes contenido

Las convenciones completas están en [`.github/copilot-instructions.md`](.github/copilot-instructions.md). El resumen:

- **Un archivo, un concepto.** Si el título necesita una "y", probablemente son dos archivos.
- **Siempre el porqué antes del comando.** Un comando sin motivo es una receta, no formación.
- **Todo paso termina en una verificación** que el lector pueda ejecutar.
- **No inventes endpoints, flags ni nombres de features.** Si dudas, enlaza `docs.gitlab.com` en vez de improvisar. Compruébalo contra tu instancia antes de escribirlo.
- **Marca el tier.** Si una feature es Premium o Ultimate, dilo y explica con qué se sustituye en CE.
- **Nunca un token con formato válido**, ni real ni inventado. Usa `<TOKEN>` o `$CI_JOB_TOKEN`.
- **Los diagramas son SVG.** Nada de arte ASCII.
- **Código y nombres de identificadores en inglés; documentación y comentarios educativos en español.**

Antes de proponer nada:

```bash
bash scripts/verificar-enlaces.sh
```

Tiene que salir en verde.

---

## Mensajes de commit

Conventional Commits, en español, con el ámbito de la semana:

```
feat(week-09): contenido completo de la Semana 09 — CI/CD fundamentos
fix(week-04): corregir el endpoint de wikis en la practica 02
docs: actualizar la tabla de versiones del stack
```

---

## Código de conducta

Participar implica aceptar el [Código de Conducta](CODE_OF_CONDUCT.md).

---

[← Volver al README principal](README.md)
