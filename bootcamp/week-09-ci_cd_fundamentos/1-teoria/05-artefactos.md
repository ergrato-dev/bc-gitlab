# Artefactos

> Un job muere con su contenedor. Lo único que sobrevive es lo que declara como artefacto: GitLab lo guarda, lo pasa a los stages siguientes, lo deja descargar y lo borra cuando caduca. Si un archivo tiene que salir del job, es un artefacto. Si no, no.

---

## 🎯 Objetivos

- Declarar artefactos con `paths`, `when` y `expire_in`
- Saber qué artefactos recibe cada job y cómo evitarlo
- Publicar el informe de tests (`reports:junit`) y la cobertura (`coverage`)
- Descargar artefactos por API, por job y por rama
- Saber dónde ocupan espacio y cuándo se borran

---

## 1. Qué problema resuelve

`package` necesita el `.tgz` que genera, y tú también, fuera del pipeline. `revisor` necesita saber qué test falló sin leer 300 líneas de log. Las dos cosas son archivos que nacen dentro de un contenedor que va a desaparecer. Los artefactos los sacan de ahí y los guardan en GitLab.

---

## 2. Cómo funciona

### 2.1 Declarar

> Extracto del `.gitlab-ci.yml` de la teoría 02, que ya lleva `workflow:rules`.

```yaml
package:
  stage: package
  script:
    - npm pack
  artifacts:
    expire_in: 1 week
    paths: ["*.tgz"]
```

| Clave | Qué hace | Por defecto |
|---|---|---|
| `paths` | Archivos y directorios, relativos al repositorio clonado | Nada |
| `exclude` | Lo que se quita de `paths` | Nada |
| `when` | `on_success`, `on_failure` o `always` | `on_success` |
| `expire_in` | Cuándo se borran | El de la instancia: `30 days` |
| `name` | Nombre del zip al descargar | `artifacts` |

Al terminar el job, el runner comprime lo declarado y lo sube a GitLab. En el log:

```
*.tgz: found 1 matching artifact files and directories
Uploading artifacts as "archive" to coordinator... 201 Created
```

Si `paths` no encuentra nada, el job **no** falla: avisa con `WARNING: *.tgz: no matching files` y sigue. Un artefacto que no aparece se descubre en el stage siguiente, o nunca.

### 2.2 Quién recibe qué

Por defecto, cada job descarga los artefactos de **todos** los jobs de stages anteriores. `package` recibe los de `build` (ninguno) y los de `test` (ninguno: `junit.xml` va en `reports`, que no se pasa entre jobs).

| Si quieres… | Escribe |
|---|---|
| Que un job no descargue nada | `dependencies: []` |
| Que descargue solo los de un job | `dependencies: [build]` |
| Que empiece sin esperar al stage | `needs`, en la Semana 11 |

### 2.3 Los informes

Un informe (*report*) es un artefacto que GitLab **lee** y presenta, en lugar de solo guardarlo.

> Extracto del `.gitlab-ci.yml` de la teoría 02, que ya lleva `workflow:rules`.

```yaml
test:
  script:
    - npm run test:ci
  coverage: '/all files\s*\|\s*([\d.]+)/'
  artifacts:
    when: always
    expire_in: 1 week
    reports:
      junit: junit.xml
```

| Qué | Dónde se ve | API | Tier |
|---|---|---|:--:|
| `reports:junit` | Pestaña *Tests* del pipeline y resumen en la merge request | `GET .../pipelines/<id>/test_report_summary` | Free |
| `coverage` (expresión regular sobre el log) | Columna de cobertura de jobs y pipelines, insignia `coverage.svg` | `GET .../pipelines/<id> \| jq .coverage` | Free |
| `reports:coverage_report` (Cobertura XML) | Líneas cubiertas, en el diff de la merge request | — | Free |

`when: always` en `test` es deliberado: el informe hace **más** falta cuando los tests fallan. Con `on_success`, un test roto no dejaría `junit.xml` y la merge request solo diría "falló".

El script `test:ci` de `app` le pide a `node:test` dos salidas a la vez: el formato legible en la consola (`spec`) y el XML para GitLab (`junit`). Con `--experimental-test-coverage`, imprime al final una tabla cuya fila `all files` lee la expresión de `coverage`:

```
ℹ all files | 100.00 |   100.00 |  100.00 |
```

La cobertura por línea en el diff (`coverage_report`) necesita un informe en formato Cobertura que `node:test` no genera sin herramientas añadidas. Para `app`, el porcentaje y la insignia bastan.

### 2.4 Caducidad

`expire_in: 1 week` borra el artefacto una semana después. Dos excepciones:

- **El último artefacto correcto de cada rama se conserva** aunque caduque, mientras el ajuste *Keep artifacts from most recent successful jobs* (`keep_latest_artifact`) siga activo, que es el valor por defecto. Así el `.tgz` de `main` siempre se puede descargar.
- **Los informes y el log** también son artefactos (`junit`, `trace`) y caducan con su `expire_in`.

Los artefactos ocupan disco **en la instancia**: `GET /projects/:id?statistics=true | jq .statistics.job_artifacts_size`. El tamaño máximo por artefacto es `max_artifacts_size` (100 MB por defecto) en la configuración de la instancia.

### 2.5 Descargar

| Qué | API |
|---|---|
| El zip de un job | `GET .../jobs/<id>/artifacts` |
| El zip del último job `package` correcto de `main` | `GET .../jobs/artifacts/main/download?job=package` |
| Un archivo suelto del último de `main` | `GET .../jobs/artifacts/main/raw/<ruta>?job=package` |

La segunda es la URL estable: siempre da el último paquete de `main`, sin saber el ID del job.

---

## 3. Cómo se configura

En el job, como en el apartado 2. Los ajustes del proyecto: `Settings → CI/CD → Artifacts`. Los de la instancia (`default_artifacts_expire_in`, `max_artifacts_size`): `Admin → Settings → CI/CD`.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `node_modules/` como artefacto | Cientos de MB por pipeline, subidos y bajados entre stages | Caché de `.npm/` (teoría 06) |
| Sin `expire_in` | Cada pipeline guarda 30 días de lo que haga falta o no | `expire_in` según para qué sirve |
| `when: on_success` en el informe de tests | Cuando falla un test, no hay informe | `when: always` |
| Pasar todo a todos | Jobs que descargan lo que no usan | `dependencies` |
| Un artefacto como única copia de una versión | Caduca | La release y el registro de paquetes (Semana 13) |

---

## 5. Trucos

- **Qué artefactos tiene un job y cuánto pesan**: `GET .../jobs/<id> | jq '.artifacts[] | {file_type, size}'`.
- **El último `.tgz` de `main`, desde la terminal**: `curl -sLo app.zip -H "$H" "$API/projects/$P/jobs/artifacts/main/download?job=package" && unzip -l app.zip`.
- **Resumen de tests sin abrir la web**: `GET .../pipelines/<id>/test_report_summary | jq .total`.

---

## 📚 Recursos Adicionales

- [Job artifacts](https://docs.gitlab.com/ci/jobs/job_artifacts/) — declarar, pasar entre jobs, caducidad
- [Artifacts reports](https://docs.gitlab.com/ci/yaml/artifacts_reports/) — todos los tipos de informe y su tier
- [Unit test reports](https://docs.gitlab.com/ci/testing/unit_test_reports/) — JUnit en la merge request
- [Code coverage](https://docs.gitlab.com/ci/testing/code_coverage/) — la expresión `coverage` y la insignia
- [Job artifacts API](https://docs.gitlab.com/api/job_artifacts/) — descargar por job, por rama o un archivo suelto

---

## ✅ Checklist de Verificación

- [ ] Sabes qué artefactos recibe `package` y por qué
- [ ] Sabes por qué el informe de tests va con `when: always`
- [ ] Sabes qué artefacto no caduca aunque pase su `expire_in`
- [ ] Sabes la URL estable del último paquete de `main`

---

[← Anterior: La vida de un job](04-la-vida-de-un-job.md) · [Volver a la Semana 09](../README.md) · [Siguiente: Caché →](06-cache.md)
