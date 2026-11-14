# `needs`: artefactos y opcionales

> `needs` no solo decide cuándo empieza un job: también decide qué artefactos descarga y qué pasa cuando el job que nombra no existe en este pipeline. Las dos cosas fallan en silencio o con un error de creación que asusta si no sabes leerlo.

---

## 🎯 Objetivos

- Predecir qué artefactos descarga un job con y sin `needs`
- Usar `needs:artifacts: false` y `needs:optional: true`, y saber cuándo cada uno
- Pasar un valor de un job a los siguientes con un informe `dotenv`
- Conocer los límites de `needs` y qué ofrece CE en lugar de `needs:project`

---

## 1. Qué problema resuelve

`package` necesita a `build` y a `test`, pero no sus archivos: `npm pack` empaqueta desde el código. Con stages descarga todo lo de los stages anteriores, incluido el `junit.xml` de `test`. Y en la Semana 10 aprendiste que un job puede no existir en un pipeline porque sus `rules` lo dejan fuera: si otro job lo nombra en `needs`, el pipeline no se crea.

---

## 2. Cómo funciona

### 2.1 Qué se descarga

| El job tiene | Descarga los artefactos de |
|---|---|
| Ni `needs` ni `dependencies` | Todos los jobs de los stages anteriores |
| `dependencies: [a]` | Solo `a` (Semana 09) |
| `needs: [a, b]` | Solo `a` y `b` |
| `needs: []` | Ninguno |
| `needs: [{job: a, artifacts: false}]` | Ninguno, pero espera a `a` |

Con `needs`, la lista de `needs` **sustituye** a `dependencies` como forma de elegir: no mezcles las dos en el mismo job. Si un job espera a otro pero no quiere sus archivos, `artifacts: false`:

```yaml
deploy-production:
  needs:
    - job: deploy-staging
      artifacts: false     # espera a que staging vaya bien; no hay nada que descargar
```

### 2.2 Cuando el job nombrado no existe

Si `package` dice `needs: [build]` y en este pipeline `build` no entra por sus `rules`, GitLab **no crea el pipeline**. El error aparece en la merge request o en `POST .../pipeline`:

```
'package' job needs 'build' job, but 'build' does not exist in the pipeline.
This might be because of the only, except, or rules keywords.
```

Es un error de creación, no de ejecución: no hay jobs, no hay log. Dos salidas:

| Situación | Solución |
|---|---|
| El job que necesitas debería estar siempre que esté el tuyo | Alinea las `rules`: que el tuyo no entre cuando el otro no entra |
| Es legítimo que a veces no esté | `optional: true`: si está, lo espera; si no, sigue |

```yaml
package:
  needs:
    - build
    - job: test
      optional: true       # solo si de verdad puede faltar
```

En `app`, `build` y `test` están en todo pipeline donde está `package` (la regla `!= merge_request_event` de `.npm` los deja entrar fuera de las merge requests). No hace falta `optional`, y ponerlo escondería un error de reglas el día que alguien cambie `.npm`.

### 2.3 Pasar un valor con `dotenv`

Un artefacto es un archivo. A veces quieres pasar **un dato**: el ID del job que generó el paquete, la versión calculada, una URL. Un informe `dotenv` convierte un archivo `CLAVE=valor` en variables de los jobs que lo descargan:

```yaml
package:
  script:
    - npm pack
    - echo "PACKAGE_JOB_ID=$CI_JOB_ID" > package.env
  artifacts:
    paths: ["*.tgz"]
    reports:
      dotenv: package.env

deploy-staging:
  needs: [package]
  script:
    - echo "Despliego el paquete del job $PACKAGE_JOB_ID"
```

Viaja con las mismas reglas que un artefacto: lo recibe quien lo descarga. Con `needs: [{job: package, artifacts: false}]` no llega. Y tiene un tamaño y un número de variables limitados, configurables en `Admin → Settings → CI/CD → CI/CD limits`.

En la práctica 03, `PACKAGE_JOB_ID` es lo que permite a `infra/entornos` descargar exactamente **este** paquete.

### 2.4 Los límites

| Límite | Valor | Dónde se cambia |
|---|---|---|
| Jobs en un `needs` | 50 | `Admin → Settings → CI/CD → CI/CD limits` |
| `needs` hacia otro proyecto | Premium | — |
| `optional` con `parallel:matrix` | No se combinan | — |

### 2.5 `needs:project`: Premium

`needs:project` descarga artefactos de un job de **otro proyecto** dentro del YAML, sin escribir una línea de `curl`. Es **Premium**. Lo que resuelve: que `infra/entornos` use el `.tgz` que generó `app`.

El sustituto libre que usa este bootcamp: el job token (teoría 06) y la API de artefactos.

```bash
curl --fail -sS -o app.tgz --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  "$CI_API_V4_URL/projects/$APP_PROJECT_ID/jobs/$APP_PACKAGE_JOB_ID/artifacts"
```

Cuesta tres líneas y una entrada en la lista de permitidos de `app`. Compensa pagar Premium cuando tienes decenas de proyectos encadenados y esas tres líneas se multiplican: los componentes de la Semana 12 las reducen a una.

---

## 3. Cómo se configura

Antes de empujar, pregunta a `ci/lint` qué jobs entrarían y si el grafo es válido:

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c, dry_run: true, ref: "main", include_jobs: true}' \
  | curl -s --request POST "$API/projects/$P/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors}'
```

Un `needs` hacia un job que no existe en ese pipeline aparece en `errors`. `dry_run` simula un push a la rama de `ref`: no ve un pipeline de merge request ni uno programado.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `optional: true` para callar el error de creación | El día que el job falte por un error de reglas, nadie se entera | Alinea las `rules` |
| `needs` y `dependencies` en el mismo job | Dos fuentes de verdad sobre qué se descarga | Solo `needs`, con `artifacts: false` donde no haga falta |
| Pasar un secreto por `dotenv` | Queda en un artefacto descargable por cualquiera con acceso al job | Las variables del proyecto (Semana 10) |
| Descargar "el último artefacto de `main`" desde otro proyecto | Puede ser el de un pipeline anterior al que te disparó | El ID del job, pasado por `dotenv` |

---

## 5. Trucos

- **Ver qué artefactos tiene un job**: `GET .../jobs/<id> | jq '.artifacts[] | {file_type, size}'`. El informe `dotenv` aparece como `file_type: "dotenv"`.
- **El error de creación de un pipeline de merge request**: no está en la lista de pipelines; está en el widget de la merge request y en `POST .../merge_requests/<iid>/pipelines`, que devuelve el mensaje.

---

## 📚 Recursos Adicionales

- [`needs:artifacts`](https://docs.gitlab.com/ci/yaml/#needsartifacts) y [`needs:optional`](https://docs.gitlab.com/ci/yaml/#needsoptional)
- [Pass an environment variable to another job](https://docs.gitlab.com/ci/variables/job_scripts/#pass-an-environment-variable-to-another-job) — `dotenv`
- [`needs:project`](https://docs.gitlab.com/ci/yaml/#needsproject) — lo que ofrece Premium

---

## ✅ Checklist de Verificación

- [ ] Sabes qué artefactos descarga `package` con `needs: [build, test]`
- [ ] Sabes leer el error "does not exist in the pipeline" y decidir entre alinear reglas y `optional`
- [ ] Sabes pasar un dato de un job a otro sin un archivo que leer a mano
- [ ] Sabes qué hace `needs:project`, su tier y su sustituto en CE

---

[← Anterior: De stages a DAG](01-de-stages-a-dag.md) · [Volver a la Semana 11](../README.md) · [Siguiente: Pipelines padre-hijo →](03-pipelines-padre-hijo.md)
