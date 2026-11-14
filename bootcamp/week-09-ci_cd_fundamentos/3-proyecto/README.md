# Proyecto Semana 09 — Cada commit se construye y se prueba solo

> En la Semana 08 `app` tuvo versiones. Esta semana cada cambio que llega al servidor se construye, se prueba, se empaqueta y se audita sin que nadie lo pida, en un runner que es tuyo, y una merge request en rojo ya no se puede fusionar. El proyecto deja escrito por qué es así, y cómo se reproduce cada job sin el runner.

---

## 🎯 Objetivo

Dejar en pie la **capa 9** de tu plataforma: un runner de proyecto propio, un pipeline `build → test → package` en verde en `main`, la auditoría de gobernanza como job, la fusión condicionada al pipeline, y las decisiones del pipeline escritas en un ADR.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| Runner de proyecto `docker-app` | S15 (pasa a formar parte de una flota etiquetada) |
| `.gitlab-ci.yml` con `workflow:rules` | S10 (se desmontan las reglas y se añaden variables por entorno), S11 (`needs` y pipelines hijos) |
| Job oculto `.npm` y caché por lockfile | S12 (se convierte en componente del catálogo), S15 (caché compartida) |
| Artefacto `*.tgz` | S13 (se publica en el registro de paquetes) |
| Informe JUnit y cobertura | S16 (la duración del pipeline se mide sobre ellos), S19 (los escáneres añaden sus informes) |
| Job `gobernanza` y `GOBERNANZA_TOKEN` | S10 (qué secretos llegan a una merge request), S11 (auditoría programada) |
| *Pipelines must succeed* | Cada merge request a partir de hoy |
| ADR-007 | S10, S11 y S12 lo amplían |

La decisión con más recorrido es **qué hace el pipeline cuando falla `gobernanza`**. Hoy, avisar. Si algún día bloquea, cambia el ADR-005 y el ADR-007, no una línea de YAML a escondidas.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 09` contra la API de tu instancia.

1. Hay un runner de proyecto en linea
2. Los jobs llegan a la API: CI_API_V4_URL de instancia no apunta a localhost
3. El archivo .gitlab-ci.yml esta en main
4. El .gitlab-ci.yml de main es valido
5. El pipeline tiene los stages build, test y package, en ese orden
6. El pipeline tiene workflow:rules
7. Todas las imagenes del pipeline llevan version y ninguna es latest
8. La cache de dependencias usa package-lock.json como clave
9. package-lock.json esta en main
10. El ultimo pipeline de main esta en verde
11. El ultimo pipeline de main ejecuto build, test y package con exito
12. El ultimo pipeline de main publico un informe de tests sin fallos
13. El ultimo pipeline de main publico la cobertura
14. El job package del ultimo pipeline de main guardo un artefacto
15. La insignia de cobertura existe
16. Existe el token de proyecto gobernanza-ci, Reporter y solo read_api
17. GOBERNANZA_TOKEN es una variable enmascarada y oculta
18. scripts/gobernanza.sh es ejecutable en main
19. CODEOWNERS da un dueño a .gitlab-ci.yml
20. Algun job gobernanza termino en verde
21. Solo se fusiona con el pipeline en verde
22. CONTRIBUTING.md explica como reproducir el pipeline en local
23. La wiki tiene una pagina cuyo slug empieza por adr-007

Las prácticas 01 a 04 dejan en verde los requisitos 1 a 21. El 22 y el 23 son este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 1. El ADR-007

En la wiki, con el formato de los anteriores (contexto, decisión, consecuencias y **descartes**). Tiene que responder:

1. **Dónde se ejecuta**: runner de proyecto con ejecutor Docker, por qué no de instancia ni `shell`.
2. **Con qué**: imágenes con versión completa, y quién las actualiza.
3. **Qué es artefacto y qué es caché**, con la pregunta de la teoría 06 aplicada a `junit.xml`, `*.tgz` y `.npm/`.
4. **Lo que mediste** en la práctica 03: los dos tiempos de `npm ci` y la diferencia entre `-protected` y `-non_protected`.
5. **`gobernanza` detecta y no bloquea**, enlazando el ADR-005, y el riesgo aceptado de `GOBERNANZA_TOKEN` sin proteger.
6. **El arreglo de `localhost`**: por qué vive en la instancia y no en el YAML.
7. **Descartado**: al menos dos. Por ejemplo, `node_modules/` como artefacto, `allow_failure: false` en `gobernanza`, o la fusión automática.

```bash
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-007 Pipeline de CI" \
  --data-urlencode "content@adr-007.md" | jq -r .slug
```

Añádelo a la barra lateral de la wiki, junto al ADR-006.

### 2. `CONTRIBUTING.md` y `README.md`: el pipeline se reproduce en local

Una merge request desde un issue `tipo::mantenimiento`. En `CONTRIBUTING.md`, una sección **"El pipeline"** que diga, en este orden:

1. Qué hace cada job y con qué comando se reproduce en local: `npm ci`, `npx tsc`, `npm run test:ci`, `npm pack --dry-run`.
2. Que `gobernanza` puede salir en `❌` con el pipeline en verde, y que eso **no** autoriza a fusionar.
3. La secuencia de fusión desde esta semana: aprobación, pipeline nuevo de la merge request, `gobernanza` en verde, fusión. El bloque de la teoría 07.
4. Qué hacer si el pipeline falla por la plataforma y no por el cambio: cómo distinguirlo con `failure_reason`.

En `README.md`, el arranque de la Semana 04 (`npm ci` y `npm test`) tiene que seguir siendo cierto ahora que hay dependencias de verdad. Repite la verificación de la Semana 04 en un clon limpio, y si la salida esperada ya no coincide (ahora hay más tests, o `npm ci` dice `added N packages`), actualízala en esta misma merge request.

Y en `docs/metricas.md`, una línea en el registro de cambios de proceso: desde esta semana, toda merge request pasa un pipeline obligatorio. Si el tiempo de entrega cambia la semana que viene, esa línea lo explica.

Fusiónala con la secuencia que acabas de documentar. Si la sigues al pie de la letra y algo no cuadra, el documento está mal: arréglalo en la misma merge request.

### 3. La protección de verdad de los jobs

Comprueba qué ve un job sin abrir la interfaz de variables. En una rama de prueba, un job temporal que **intenta** imprimir `GOBERNANZA_TOKEN`:

```yaml
fuga:
  image: alpine:3.24.2
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - echo "token=$GOBERNANZA_TOKEN"
    - echo "longitud=${#GOBERNANZA_TOKEN}"
```

El log dice `token=[MASKED]` y una longitud distinta de cero. **El job tiene el token**: el enmascarado solo protege el log. Anota en el ADR-007, en consecuencias, qué impide hoy que alguien lo envíe a otro sitio (nada técnico: el mínimo privilegio y la revisión), y qué cambiará la Semana 10.

Cierra la merge request sin fusionar y borra la rama.

### 4. Revocar el token de `revisor`

Cuando la merge request del punto 2 esté fusionada. Desde la misma terminal en la que creaste `$HR`; si es otra, repite antes el paso 0 de la práctica 01:

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s09
export API="$GITLAB_URL/api/v4"
[ -n "${T_REV:-}" ] && [[ "${UID_REV:-}" =~ ^[0-9]+$ ]] || { echo "Falta \$T_REV o \$UID_REV: NO sigas"; return 1 2>/dev/null || exit 1; }
HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
for id in $(curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
              | jq -r '.[] | select(.name == "flujo-s09" and .active) | .id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$HA" -o /dev/null -w "revocado $id: %{http_code}\n"
done

curl -s -o /dev/null -w '%{http_code}\n' -H "$HR" "$API/user"     # 401: el token existía y ya no vale
curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
  | jq '[.[] | select(.name == "flujo-s09" and .active)] | length'  # 0
unset T_REV HR HA
rm -f ~/.bc-gitlab-s09
```

`GOBERNANZA_TOKEN` **no** se revoca: es del job, caduca en seis meses y la Semana 11 programa el aviso.

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **El ADR-007 dice qué se descartó y por qué**, y enlaza el ADR-005 en lugar de repetirlo.
- **Los números del ADR-007 son los medidos**, no los de la teoría.
- **Cada comando de "El pipeline" en `CONTRIBUTING.md` funciona copiado tal cual** en un clon limpio.
- **El token de `revisor` está revocado**, comprobado en negativo.
- **El token de `gobernanza` nunca apareció en la terminal**: ni en un `echo`, ni en el historial, ni en un archivo.
- **La merge request de la regresión está cerrada sin fusionar**, y su rama borrada.

---

## 💡 Adaptación a tu dominio

El pipeline es el mismo en los cuatro dominios. Lo que cambia es qué regresión demuestra que los tests de borde valían la pena.

| Dominio | Un límite que el pipeline tiene que defender |
|---|---|
| 📖 Biblioteca | El socio con exactamente el máximo de préstamos no puede llevarse otro |
| 🏋️ Gimnasio | La clase con el cupo exacto no admite una reserva más |
| 🎥 Cine | El asiento reservado no se puede volver a reservar en la misma sesión |
| 💊 Farmacia | El lote que caduca hoy ya no se dispensa |

El patrón: **un test de borde es el que falla con un solo carácter cambiado**. Si la regresión de la práctica 03 no rompió ningún test, falta ese test, y añadirlo es parte de este proyecto.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu proyecto, de su runner, de sus pipelines y de su wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 09
```

```
23 de 23 verificaciones superadas.
```

El requisito 2 lee una variable de instancia: necesita `GITLAB_ADMIN_TOKEN` en `~/.bc-gitlab`, como en la Semana 03.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| El último pipeline de `main` es el de `api` de la práctica 03 y falló | Requisito 10 | Relanza: `POST .../pipeline?ref=main` |
| `CONTRIBUTING.md` no dice cómo se ejecutan los tests del pipeline | Requisito 22 | `npm run test:ci`, con lo que añade respecto a `npm test` |
| El runner `offline` tras reiniciar la máquina | Requisito 1 | `docker compose --profile base up -d`; el registro está en el volumen y sobrevive |
| `gobernanza` en `❌` en la merge request del punto 2 y se fusionó igual | Nada lo detecta: `allow_failure` | Es exactamente lo que el punto 2 documenta que no se hace. Anótalo en el ADR-007 |
| El job `fuga` del punto 3 fusionado por error | `.gitlab-ci.yml` de `main` lo contiene | Merge request que lo quita, y rota `GOBERNANZA_TOKEN` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 08](../../week-08-gitlab_flow_releases_y_metricas/3-proyecto/README.md) | **Proyecto Semana 09** | [Proyecto Semana 10](../../week-10-reglas_variables_y_secretos/3-proyecto/README.md) |

[← Volver a la Semana 09](../README.md)
