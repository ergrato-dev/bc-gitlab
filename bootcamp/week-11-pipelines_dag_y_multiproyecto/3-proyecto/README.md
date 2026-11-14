# Proyecto Semana 11 — El pipeline deja de ser un tren en serie

> En la Semana 10 el pipeline de `app` decidió qué ejecutar en cada caso. Esta semana decide también **cuándo** empieza cada job, separa la documentación en un pipeline hijo, avisa a `infra/entornos` de cada paquete nuevo, se protege de dos despliegues a la vez y vigila las caducidades cada mañana. El proyecto deja por escrito la topología y la medición, y ensaya la alarma antes de que haga falta.

---

## 🎯 Objetivo

Dejar en pie la **capa 11** de tu plataforma: un DAG medido, un pipeline hijo de documentación, el primer proyecto de `infra` disparado desde `app` y leyendo su paquete con el job token, candados de despliegue, un pipeline programado que no despliega nada, el ADR-008 en la wiki y la alarma de caducidades ensayada.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| `needs` en todo el pipeline | S12 (los componentes declaran sus `needs`), S16 (mides el pipeline antes y después de Kubernetes) |
| `ci/docs.yml` | S12 (`include` y componentes ordenan el resto del YAML) |
| `infra/entornos` y su disparo | S14 (despliega de verdad), S24 (`infra/terraform` a su lado), S25 (GitOps) |
| La lista de permitidos del job token | S13 (el registry), S17 (auditoría por API) |
| `resource_group` por entorno | S14 (despliegue real y *rollback*) |
| El programado de caducidades | S17 (avisa por webhook), S22 (respuesta a incidentes) |
| `concurrent = 2` | S15 (la flota de runners) |

La decisión con más recorrido es **qué vive en `app` y qué en `infra`**. Hoy, `infra/entornos` solo registra; en la Semana 14 tendrá los secretos de los entornos, y entonces `app` dejará de necesitarlos. El ADR-008 tiene que dejar escrito por qué el corte va ahí.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 11` contra la API de tu instancia.

1. test empieza sin esperar a build
2. gobernanza empieza sin esperar a ningun job
3. package espera solo a build y a test
4. El ultimo pipeline de main por push esta en verde
5. Un job dispara ci/docs.yml como pipeline hijo con strategy mirror
6. Hay al menos un pipeline hijo terminado en verde
7. Existe el proyecto entornos dentro del subgrupo infra
8. En infra/entornos solo Maintainer o mas puede pasar variables a un pipeline
9. El pipeline de app dispara un pipeline en infra/entornos
10. infra/entornos tiene un pipeline multiproyecto terminado en verde
11. El job token de otros proyectos solo entra en app si esta en su lista de permitidos
12. infra/entornos esta en la lista de permitidos del job token de app
13. Existen los resource groups staging y production
14. El resource group staging atiende primero al pipeline mas nuevo
15. Hay un pipeline programado activo que vigila las caducidades
16. Hay al menos un pipeline programado terminado en verde
17. deploy-staging no entra en los pipelines programados
18. El ADR-008 de la wiki explica la topologia de pipelines

Las prácticas 01 a 04 dejan en verde los requisitos 1 a 17. El 18 es este proyecto, y el 4 tiene que seguir en verde después de su merge request.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo antes el paso 0 de la práctica 01 (necesitas `$HR`, `esperar` y `fusionar`):

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s11
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
```

### 1. La medición, en `docs/metricas.md`

`docs/metricas.md` existe desde la Semana 08 con las métricas de flujo. Gana una sección **"Duración del pipeline (Semana 11)"**, en una merge request desde un issue `tipo::mantenimiento`, con:

1. **Las tres medidas** de `~/medidas-s11.txt`: stages con un hueco, DAG con un hueco, DAG con dos. La `duration` de cada una y la línea de tiempo de la tercera.
2. **El camino crítico**, con tus segundos: qué jobs lo forman y cuál acortarías primero.
3. **Por qué el DAG con un hueco no mejoró**, en una frase que entienda alguien que no ha leído la teoría.
4. **Lo que no se ha medido**: el pipeline de merge request, y el tiempo que añade el disparo a `infra/entornos` al pipeline de `main`. Mídelo ahora: la `duration` del job `infra` en el último pipeline de `main`.

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/bridges" | jq -r '.[] | "\(.name) \(.duration // 0 | floor)s"'
```

La merge request toca un `.md`: su pipeline tiene hijo de documentación, y `markdownlint` revisa lo que escribes. Fusiónala con `fusionar`. Después, `rm ~/medidas-s11.txt`: lo que importa ya está en el repositorio.

### 2. El ADR-008: la topología de pipelines

Una página nueva de la wiki, **ADR-008**, con el formato de los anteriores (contexto, decisión, consecuencias, descartado). Tiene que responder:

1. **El grafo de `app`**: qué espera cada job y por qué. Las palabras `needs` y `needs: []` aparecen literalmente.
2. **Por qué un hijo para la documentación** y no cuatro jobs más en el padre, y por qué `strategy: mirror`.
3. **Por qué `infra/entornos` es un proyecto aparte** y no una carpeta de `app`: quién lo cambia, qué secretos tendrá, a qué ritmo cambia. Nombra el proyecto por su ruta, `infra/entornos`.
4. **Con la identidad de quién** se crea el pipeline de `infra/entornos`, y qué pasa el día que la persona que fusiona en `app` deja la organización.
5. **Los candados**: por qué uno por entorno, por qué `newest_first` en `staging` y no en `production`.
6. **El programado**: a nombre de quién está, qué jobs deja fuera y por qué no basta con `rules:changes`.
7. **Descartado**: al menos dos. Por ejemplo, `needs:project` (Premium), un token de proyecto de `app` en `infra` para leer el paquete, descargar "el último artefacto de `main`", o un hijo dinámico.

```bash
cat > adr-008.md <<'EOF'
# ADR-008 — Topología de pipelines
…
EOF
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-008 Topología de pipelines" \
  --data-urlencode "content@adr-008.md" | jq -r .slug
rm adr-008.md
```

### 3. Ensayar la alarma

Un programado que nunca has visto fallar es una alarma que no sabes si suena. Haz que falle sin tocar ninguna fecha: con `AVISO_DIAS` lo bastante grande, cualquier fecha cae dentro del plazo.

```bash
[[ "${SID:-}" =~ ^[0-9]+$ ]] || { echo "Falta \$SID (source ~/.bc-gitlab-s11): NO sigas"; return 1 2>/dev/null || exit 1; }
curl -s --request POST "$API/projects/$P/pipeline_schedules/$SID/variables" -H "$H" \
  --data "key=AVISO_DIAS" --data "value=3650" | jq -c '{key, value}'
curl -s --request POST "$API/projects/$P/pipeline_schedules/$SID/play" -H "$H" -o /dev/null -w '%{http_code}\n'
sleep 15
PROG=$(curl -s -H "$H" "$API/projects/$P/pipelines?source=schedule&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PROG"                                                            # failed
JOB=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PROG/jobs" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$P/jobs/$JOB/trace" | grep -E 'PRONTO|rótalos'

curl -s --request DELETE "$API/projects/$P/pipeline_schedules/$SID/variables/AVISO_DIAS" -H "$H" -o /dev/null -w '%{http_code}\n'   # 204
curl -s --request POST "$API/projects/$P/pipeline_schedules/$SID/play" -H "$H" -o /dev/null -w '%{http_code}\n'
sleep 15
esperar "$P" "$(curl -s -H "$H" "$API/projects/$P/pipelines?source=schedule&per_page=1" | jq -r '.[0].id')"   # success
```

**Verifica**: un programado en `failed` con todos los secretos en `CADUCA PRONTO`, el aviso de pipeline fallido en tu correo si tu laboratorio lo envía (si no, el pipeline en rojo en `Build → Pipelines` es la única señal: la Semana 17 la lleva a un webhook), y el siguiente en `success`. El último programado en verde es el que cuenta para el requisito 16.

### 4. Revocar el token de `revisor`

Cuando la merge request del punto 1 esté fusionada:

```bash
[[ "${UID_REV:-}" =~ ^[0-9]+$ ]] || { echo "Falta \$UID_REV (source ~/.bc-gitlab-s11): NO sigas"; return 1 2>/dev/null || exit 1; }
HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
for id in $(curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
              | jq -r '.[] | select(.name == "flujo-s11" and .active) | .id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$HA" -o /dev/null -w "revocado $id: %{http_code}\n"
done
[ -n "${HR:-}" ] && curl -s -o /dev/null -w 'revisor: %{http_code}\n' -H "$HR" "$API/user"      # 401
curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" | jq '[.[] | select(.name == "flujo-s11" and .active)] | length'   # 0
unset T_REV HR HA
rm -f ~/.bc-gitlab-s11
```

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **La medición es honrada**: tres medidas reales, con el DAG de un hueco sin mejora, y el camino crítico calculado con tus segundos.
- **El ADR-008 dice por qué `infra/entornos` es otro proyecto**, con razones de quién cambia qué, no de orden de carpetas.
- **El ADR-008 nombra la identidad del disparo y del programado** y el riesgo de que esa persona se vaya.
- **La alarma se ensayó**: un programado en rojo y el siguiente en verde, con la variable de ensayo borrada.
- **La lista de permitidos de `app` tiene solo lo necesario**: `app` e `infra/entornos`.
- **Las fechas de `docs/secretos.md` son las reales**: la de `GOBERNANZA_TOKEN` coincide con su `expires_at`.

---

## 💡 Adaptación a tu dominio

El grafo es el mismo en los cuatro dominios. Lo que cambia es qué significaría que dos despliegues a `production` se pisaran, y eso es lo que el ADR-008 tiene que transmitir en la sección de los candados.

| Dominio | Si dos despliegues a `production` se pisan |
|---|---|
| 📖 Biblioteca | El catálogo muestra libros de una versión y préstamos de otra |
| 🏋️ Gimnasio | Las reservas de la mañana se hacen contra una versión que ya no existe |
| 🎥 Cine | Dos versiones de la sala venden el mismo asiento |
| 💊 Farmacia | Una dispensación queda registrada con las reglas de la versión vieja |

El patrón: **el candado protege el estado compartido, no el código**. Si en tu dominio no puedes nombrar qué estado se corrompe, el ADR aún no ha entendido para qué sirve.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de `app`, de `infra/entornos`, de sus pipelines y de la wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 11
```

```
18 de 18 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| El último pipeline de `main` está en rojo por `infra` | Requisito 4 | Lee el log de `registrar` en `infra/entornos`: casi siempre la lista de permitidos o el `dotenv` |
| `adr-008-topologia` en rojo con la página escrita | El slug no empieza por `ADR-008`, o falta `needs` o `infra/entornos` literal | El título de la página fija el slug: `ADR-008 …` |
| `programado-en-verde` en rojo tras el ensayo | El último programado es el del ensayo | Borra `AVISO_DIAS` y vuelve a hacer `play` |
| `markdownlint` en rojo en la merge request de `docs/metricas.md` | La tabla o los títulos que escribiste | Pásalo en local antes de empujar, como en la práctica 02 |
| `programa-de-caducidades` en rojo | El programado está inactivo | Su propietario perdió el acceso: `POST .../pipeline_schedules/<id>/take_ownership` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 10](../../week-10-reglas_variables_y_secretos/3-proyecto/README.md) | **Proyecto Semana 11** | Proyecto Semana 12 |

[← Volver a la Semana 11](../README.md)
