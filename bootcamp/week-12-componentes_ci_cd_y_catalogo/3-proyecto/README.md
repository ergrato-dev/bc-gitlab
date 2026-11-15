# Proyecto Semana 12 — El YAML deja de duplicarse

> En la Semana 11, `app` era el único sitio donde vivía su pipeline, y la tabla de "lo que espera" decía que reutilizarlo en otro proyecto era copiarlo. Esta semana el pipeline se reparte: el despliegue en su propio archivo, la construcción y la auditoría en componentes versionados de `ci/componentes`, y el entorno de `infra/entornos` como un input que no se puede escribir mal. El proyecto completa lo que hace usable un componente para alguien que no lo escribió: un README, una segunda versión que llega sola a `app`, y el ADR que explica las decisiones.

---

## 🎯 Objetivo

Dejar en pie la **capa 12** de tu plataforma: `ci/componentes` publicado en el catálogo con dos versiones, documentado y protegido; `app` consumiéndolo con `@1`; `infra/entornos` recibiendo su entorno como input; y el ADR-009 en la wiki de `app`.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| `ci/deploy.yml` | S14 (entornos y despliegues reales), S25 (entrega progresiva) |
| `ci/componentes` y el catálogo | S13 (un componente para construir y publicar imágenes), S19 (componentes de escaneo con herramientas libres), S20 (firma y SBOM) |
| El componente `gobernanza` | S17 (la auditoría también por webhook), S26 (auditoría de las 25 capas) |
| El pipeline que prueba los componentes | S19 (se prueba también que el escaneo detecta lo que debe) |
| `infra/entornos` con `spec:inputs` | S14 (`entorno` decide de verdad adónde se despliega) |
| La lista de permitidos de `ci/componentes` | S13 (el registry), S17 (auditoría por API) |

La decisión con más recorrido es **qué versión pide cada consumidor**. `@1` hace que las correcciones lleguen solas y que una *minor* mal clasificada también. El ADR-009 tiene que dejar escrito qué cambios son *major* en tu proyecto de componentes, porque a partir de la Semana 13 habrá más de dos.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 12` contra la API de tu instancia.

1. Los despliegues de app viven en ci/deploy.yml
2. El .gitlab-ci.yml de app incluye ci/deploy.yml
3. Existe el proyecto componentes dentro del subgrupo ci
4. componentes tiene el componente npm
5. componentes tiene el componente gobernanza
6. El ultimo pipeline de main en componentes esta en verde
7. componentes esta marcado como recurso del catalogo CI/CD
8. En componentes solo Maintainer o mas puede crear tags
9. Todas las versiones de componentes son semver sin v delante
10. componentes tiene al menos dos versiones publicadas
11. El job token de los proyectos del grupo puede leer componentes
12. app consume el componente npm por version, no por rama ni por ~latest
13. app consume el componente gobernanza por version, no por rama ni por ~latest
14. infra/entornos declara el input entorno con una lista cerrada de valores
15. El disparo de app a infra/entornos pasa el entorno como input
16. El ultimo pipeline multiproyecto de infra/entornos esta en verde y lleva el entorno en el nombre
17. La wiki de app tiene el ADR-009 sobre el CI compartido

Las prácticas 01 a 04 dejan en verde todos menos el 10 y el 17. Esos dos son este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo antes el paso 0 de la práctica 01 (necesitas `$HR`, `esperar` y `fusionar`):

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s12
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
```

### 1. El README de `ci/componentes`

El catálogo enseña el README como portada. Hoy es el que GitLab creó vacío. Reescríbelo en una merge request de `ci/componentes`, desde un issue, para alguien que llega desde el catálogo sin haber leído este bootcamp:

1. **Qué hay**: los dos componentes, en una frase cada uno.
2. **Por componente**: un ejemplo de `include` con `$CI_SERVER_FQDN` y `@1`, la tabla de inputs (nombre, tipo, valor por defecto, para qué) y los jobs que crea, con su `stage` y sus `needs`.
3. **Lo que el consumidor tiene que poner de su parte**: los `stages`; para `gobernanza`, `GOBERNANZA_TOKEN` y un CODEOWNERS; y que el grupo ya está en la lista de permitidos.
4. **La política de versiones**: semver sin `v`, qué cambios son *major* (la tabla de la teoría 06, apartado 2.1, con tus palabras), y qué versión debería pedir un consumidor.
5. **Cómo se publica**: merge request, tag de un Maintainer, y el pipeline del tag.

Ningún ejemplo con `@~latest` ni con una rama.

### 2. `1.1.0`: una versión que llega sola

Una *minor* de verdad: el componente `npm` gana un input con un valor por defecto que conserva el comportamiento de `1.0.0`. Por ejemplo, `test` pasa a ejecutar `$[[ inputs.test ]]`, con `default: npm run test:ci`. Elige tú el input, y que el pipeline de `ci/componentes` le pase un valor distinto del de por defecto, para que la prueba lo cubra.

1. Merge request en `ci/componentes`, con `gobernanza` en verde. Incluye en ella el cambio del README que documenta el input nuevo.
2. Tag `1.1.0`, firmado, y su pipeline en verde con `publicar`.
3. Sin tocar `app`, lanza un pipeline de su `main` y comprueba que ha recibido `1.1.0`:

```bash
SHA_110=$(curl -s -H "$H" "$API/projects/$PC/repository/tags/1.1.0" | jq -r .commit.id)
curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data "ref=main" | jq -r .id
curl -s -H "$H" "$API/projects/$P/ci/lint" \
  | jq -r '.includes[] | select(.location | test("/npm@")) | .blob' | grep -c "$SHA_110"
# 1
```

Es la propiedad que justifica `@1`, y también su riesgo: escribe en el ADR-009 qué habría pasado si `1.1.0` hubiera renombrado un input.

### 3. El ADR-009: el CI compartido

Una página nueva de la wiki de `app`, **ADR-009**, con el formato de los anteriores (contexto, decisión, consecuencias, descartado). Tiene que responder:

1. **Qué va en `include:local`, qué en un componente y qué se queda en `.gitlab-ci.yml`**, con `ci/deploy.yml` y `ci/docs.yml` como ejemplos. La palabra `componentes` aparece literalmente.
2. **Por qué `ci/componentes` es un proyecto aparte** y no una carpeta de `app`: versión propia, pruebas propias, dueños propios.
3. **La política de versiones**: semver sin `v`, `@1` para lo propio, el SHA para lo ajeno, nunca `@~latest`. Y qué es *major* en este proyecto.
4. **Cómo se protege `ci/componentes`**: las cuatro capas de la teoría 08 y por qué `revisor` es Developer y no Maintainer allí.
5. **El script de `gobernanza`**: por qué vive en `ci/componentes`, por qué se descarga en `component.sha` y por qué el grupo en la lista de permitidos y no un proyecto interno.
6. **Inputs y variables en el disparo a `infra/entornos`**: por qué `entorno` es un input y las otras tres siguen siendo variables, y por qué la restricción sigue en `maintainer`. La palabra `inputs` aparece literalmente.
7. **Descartado**: al menos dos. Por ejemplo, `include:project` contra `app`, copiar el YAML, un proyecto de componentes interno, `@~latest`, o las *pipeline execution policies* (Ultimate).

```bash
cat > adr-009.md <<'EOF'
# ADR-009 — El CI compartido
…
EOF
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-009 El CI compartido" \
  --data-urlencode "content@adr-009.md" | jq -r .slug
rm adr-009.md
```

### 4. Recoger

El token de `revisor` de esta semana se revoca, y los archivos de trabajo se borran: lo que importa ya está en la instancia.

```bash
HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
for id in $(curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
              | jq -r '.[] | select(.name == "flujo-s12" and .active) | .id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$HA" -o /dev/null -w "revocado $id: %{http_code}\n"
done
[ -n "${HR:-}" ] && curl -s -o /dev/null -w 'revisor: %{http_code}\n' -H "$HR" "$API/user"      # 401
unset T_REV HR HA
rm -f ~/.bc-gitlab-s12 ~/s12-antes.yml ~/s12-despues.yml ~/s12-lint.json
```

`GOBERNANZA_TOKEN` de `ci/componentes` no se revoca: es del proyecto y caduca en 180 días. Añádelo a `docs/secretos.md` de `app`, con su fecha de caducidad, en la misma merge request que cualquier otro cambio de documentación: `caducidades` lo vigilará.

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **`1.1.0` es una *minor* de verdad**: un consumidor de `1.0.0` no nota nada hasta que usa el input nuevo, y el pipeline de `ci/componentes` lo prueba con un valor distinto del de por defecto.
- **El README de `ci/componentes` sirve a un desconocido**: con él, alguien de otro grupo podría consumir los dos componentes sin preguntarte nada.
- **El ADR-009 explica por qué las tres variables del disparo no son inputs**, con el momento en que existe cada valor.
- **Los componentes no dependen de `app`**: sin `!reference` a `.fuera-de-programados`, sin `default` ni `variables` globales, con jobs ocultos de nombre propio.
- **`ci/componentes` no está más abierto que `app`**: privado, `main` sin push, tags para Maintainer, `revisor` como Developer.
- **`GOBERNANZA_TOKEN` de `ci/componentes` está en `docs/secretos.md`** con su caducidad.

---

## 💡 Adaptación a tu dominio

Los componentes son los mismos en los cuatro dominios: construir con npm y auditar una merge request no dependen del negocio. Lo que cambia es el **segundo input de pipeline** que tendría sentido en `infra/entornos` el día que los entornos sean reales, y eso es lo que el ADR-009 puede anticipar.

| Dominio | Un input con `options` que tendría sentido |
|---|---|
| 📖 Biblioteca | `sede: [central, norte, sur]`: cada sede, su réplica del catálogo |
| 🏋️ Gimnasio | `franja: [mañana, tarde]`: no se despliega con las salas llenas |
| 🎥 Cine | `ventana: [madrugada]`: una sola opción, y es la política |
| 💊 Farmacia | `turno: [diurno, guardia]`: la guardia no admite despliegues sin aviso |

El patrón: **un input con `options` es una política escrita en el YAML**. Si en tu dominio no hay ningún valor que deba estar prohibido, el input no necesita `options`; si lo hay, una variable de texto libre es una política que nadie hace cumplir.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de `app`, de `ci/componentes`, de `infra/entornos`, del catálogo y de la wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 12
```

```
17 de 17 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `dos-versiones-publicadas` en rojo con el tag `1.1.0` creado | El pipeline del tag falló antes de `publicar` | Corrige en una merge request y publica `1.1.1`: el tag `1.1.0` no se reutiliza |
| `versiones-semver-sin-v` en rojo | Hay una release `v1.1.0` | Bórrala con `DELETE .../releases/v1.1.0` y publica sin `v`; el tag protegido necesita un Maintainer para borrarse |
| `app` sigue resolviendo `1.0.0` | `1.1.0` no está publicada, o el pipeline de `app` se lanzó antes | `ciCatalogResources` y otro pipeline |
| `adr-009-ci-compartido` en rojo con la página escrita | El slug no empieza por `ADR-009`, o falta `componentes` o `inputs` literal | El título fija el slug: `ADR-009 …` |
| `componentes-se-prueba` en rojo tras la `1.1.0` | El input nuevo rompe `tests/npm` | El pipeline de la merge request te lo habría dicho: no fusiones en rojo |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 11](../../week-11-pipelines_dag_y_multiproyecto/3-proyecto/README.md) | **Proyecto Semana 12** | Proyecto Semana 13 |

[← Volver a la Semana 12](../README.md)
