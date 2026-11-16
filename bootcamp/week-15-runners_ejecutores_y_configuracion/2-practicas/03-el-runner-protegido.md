# Práctica 03 — El runner protegido

> Creas en el grupo `infra` el runner `deploy-infra`: de grupo, solo para ramas protegidas, con tiempo máximo, y en el mismo proceso que los otros dos. `desplegar` lo pide por su etiqueta, `infra/entornos` suelta `docker-app` y los runners de instancia, y despliegas en `staging` para ver en qué runner cae. Después intentas lo que no debería funcionar: un job de una rama sin proteger que pide `deploy`.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 02 completada · Teoría [04](../1-teoria/04-etiquetas-y-alcance.md) y [05](../1-teoria/05-runners-protegidos.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | `deploy-infra` creado en el grupo `infra` | `deploy-solo-ramas-protegidas`, `deploy-con-tiempo-maximo` |
| 2 | `deploy-infra` registrado en el mismo proceso | `deploy-en-linea` |
| 3 | `desplegar` pide la etiqueta `deploy` | — |
| 4 | `infra/entornos` sin `docker-app` ni runners de instancia | `infra-sin-runners-de-proyecto`, `infra-sin-runners-compartidos` |
| 5 | Un despliegue en `staging` desde `deploy-infra` | `desplegar-en-runner-protegido` |
| 6 | La prueba: una rama sin proteger no llega | — |

Si has cerrado la terminal: el paso 0 de la [práctica 01](01-la-cache-compartida.md#paso-0-preparar-el-terreno).

---

## Paso 1: El runner en el grupo `infra`

**Por qué**: un runner de grupo atiende a todos los proyectos del grupo y de sus subgrupos (teoría 04, apartado 2.1). Hoy `infra` tiene un proyecto, `entornos`; el día que tenga dos, el segundo despliega con el mismo runner sin asignarle nada. `ref_protected` hace que solo lleguen jobs de ramas y tags protegidos, y `maximum_timeout=900` corta un despliegue colgado antes de que retenga el `resource_group` una hora (teoría 05). Crear un runner de grupo pide ser Owner del grupo.

```bash
R=$(curl -s --request POST "$API/user/runners" -H "$H" \
  --data "runner_type=group_type" --data "group_id=$GI" \
  --data-urlencode "description=deploy-infra" --data "tag_list=deploy" \
  --data "run_untagged=false" --data "access_level=ref_protected" --data "maximum_timeout=900")
RID_DEPLOY=$(jq -r .id <<<"$R"); RT=$(jq -r .token <<<"$R"); unset R
echo "export RID_DEPLOY=$RID_DEPLOY" >> ~/.bc-gitlab-s15
```

**Verifica**:

```bash
curl -s -H "$H" "$API/runners/$RID_DEPLOY" \
  | jq -c '{description, runner_type, tag_list, run_untagged, access_level, maximum_timeout}'
# {"description":"deploy-infra","runner_type":"group_type","tag_list":["deploy"],"run_untagged":false,"access_level":"ref_protected","maximum_timeout":900}
```

Si responde `403`, no eres Owner de `infra`: tu token de la Semana 01 lo es.

---

## Paso 2: El tercer `[[runners]]`

**Por qué**: el mismo `register` de la práctica 02, sin privilegios ni volumen de certificados, con `limit = 2`: `staging` y `production` tienen cada uno su `resource_group` y pueden desplegarse a la vez (Semana 14). `concurrent = 3` sigue siendo el techo: la suma de los `limit` (2 + 1 + 2) lo pasa a propósito (teoría 02, apartado 2.2).

```bash
cd /ruta/a/bc-gitlab
CK=$(grep '^RUNNER_CACHE_SECRET_KEY=' .env | cut -d= -f2)
docker compose exec gitlab-runner gitlab-runner register --non-interactive \
  --url http://gitlab:8888 --clone-url http://gitlab:8888 --token "$RT" \
  --name deploy-infra --executor docker --docker-image alpine:3.24.2 \
  --docker-network-mode bc-gitlab-network --docker-volumes /cache --limit 2 \
  --cache-type s3 --cache-shared --cache-s3-server-address cache-s3:8333 \
  --cache-s3-access-key runnercache --cache-s3-secret-key "$CK" \
  --cache-s3-bucket-name runner-cache --cache-s3-insecure 2>&1 | grep -E 'registered|FATAL'
unset RT CK
```

**Verifica**:

```bash
GE=$(printf '%s' "$GRUPO/infra" | jq -sRr @uri)
curl -s -H "$H" "$API/groups/$GE/runners?type=group_type&tag_list=deploy&status=online" \
  | jq -c '.[] | {description, status}'
# {"description":"deploy-infra","status":"online"}
docker compose exec gitlab-runner grep -c '^\[\[runners\]\]' /etc/gitlab-runner/config.toml
# 3
curl -s -H "$H" "$API/runners/$RID_DEPLOY/managers" | jq -r '.[].system_id'
```

El `system_id` es el mismo que el de `docker-app` y `dind-app` (práctica 02, paso 3).

---

## Paso 3: `desplegar` pide `deploy`

**Por qué**: un runner con `run_untagged=false` solo coge jobs que pidan su etiqueta (teoría 04, apartado 2.2). Sin la línea, `desplegar` se quedaría en `pending` en cuanto `infra/entornos` suelte `docker-app` en el paso 4. Por eso va antes.

```bash
cd /ruta/a/tus/clones/entornos && git switch main && git pull --ff-only
sed -i '/^desplegar:$/a\  tags: [deploy]   # solo el runner protegido de infra (Semana 15)' .gitlab-ci.yml
sed -n '/^desplegar:$/,/^  image:/p' .gitlab-ci.yml
```

**Verifica**:

```
desplegar:
  tags: [deploy]   # solo el runner protegido de infra (Semana 15)
  image: alpine:3.24.2
```

```bash
jq -n --rawfile c .gitlab-ci.yml '{content: $c}' \
  | curl -s --request POST "$API/projects/$PI/ci/lint" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '{valid, errors}'
git add .gitlab-ci.yml
git commit -S -m "ci: desplegar en el runner protegido deploy-infra"
git push origin main
```

`{"valid":true,"errors":[]}`. Como en la Semana 14, el push a `main` de `infra/entornos` no crea pipeline.

---

## Paso 4: `infra/entornos` suelta lo que sobra

**Por qué**: con `docker-app` asignado, cualquier job sin etiqueta de `infra/entornos` caería en un runner que también ejecuta ramas de `app`. Y un runner de instancia que acepte jobs sin etiqueta, igual. `infra/entornos` solo despliega: su único runner es `deploy-infra`. `docker-app` sigue asignado a `ci/componentes`, que lo necesita para probar sus componentes.

```bash
RID_DOCKER=$(curl -s -H "$H" "$API/projects/$P/runners?type=project_type&tag_list=docker" | jq -r '.[0].id')
echo "export RID_DOCKER=$RID_DOCKER" >> ~/.bc-gitlab-s15
curl -s --request DELETE "$API/projects/$PI/runners/$RID_DOCKER" -H "$H" -o /dev/null -w '%{http_code}\n'
curl -s --request PUT "$API/projects/$PI" -H "$H" --data "shared_runners_enabled=false" | jq '.shared_runners_enabled'
```

**Verifica**: `204` y `false`. Lo que ve ahora `infra/entornos`:

```bash
jq -n --arg p "$GRUPO/infra/entornos" '{query: "query($p: ID!){ project(fullPath: $p){ runners{ nodes{ description runnerType accessLevel } } } }", variables: {p: $p}}' \
  | curl -s --request POST "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '.data.project.runners.nodes[]'
# {"description":"deploy-infra","runnerType":"GROUP_TYPE","accessLevel":"REF_PROTECTED"}
curl -s -H "$H" "$API/runners/$RID_DOCKER" | jq -r '.projects[].path_with_namespace'
# plataforma-<tu-dominio>/app
# plataforma-<tu-dominio>/ci/componentes
```

Un solo runner, y heredado del grupo: por eso la API REST de proyecto con `type=project_type` ya no devuelve nada.

---

## Paso 5: Desplegar desde `deploy-infra`

**Por qué**: hasta ver un despliegue en verde en el runner nuevo, todo lo anterior es configuración. Un pipeline de `main` de `app` dispara `infra/entornos` con `entorno=staging` (Semana 14).

```bash
PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode "ref=main" | jq -r .id)
esperar "$P" "$PIPE"
PIPE_I=$(curl -s -H "$H" "$API/projects/$PI/pipelines?source=pipeline&per_page=1" | jq -r '.[0].id')
esperar "$PI" "$PIPE_I"
curl -s -H "$H" "$API/projects/$PI/pipelines/$PIPE_I/jobs" \
  | jq -c '.[] | {name, status, tag_list, runner: .runner.description, tipo: .runner.runner_type}'
```

**Verifica**:

```
{"name":"desplegar","status":"success","tag_list":["deploy"],"runner":"deploy-infra","tipo":"group_type"}
```

Y en el destino, como siempre, la verdad:

```bash
curl -s localhost:8095/staging/salud | jq -r .sha
git -C /ruta/a/tu/clon/de/app rev-parse HEAD        # el mismo
```

---

## Paso 6: La prueba de la protección

**Por qué**: un runner protegido se demuestra intentando saltárselo. Una rama sin proteger de `infra/entornos`, con un job que pide `deploy`, tiene que quedarse en `pending` para siempre (teoría 05, apartado 2.1). La rama solo existe para la prueba: se borra al final.

```bash
cd /ruta/a/tus/clones/entornos
git switch -c prueba-runner-protegido
cat > .gitlab-ci.yml <<'EOF'
# Prueba de la Semana 15: esta rama no está protegida y deploy-infra no debe cogerla.
intento:
  tags: [deploy]
  image: alpine:3.24.2
  script: echo "si lees esto, deploy-infra ha ejecutado una rama sin proteger"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
EOF
git commit -S -am "test: un job de rama sin proteger que pide deploy"
git push -u origin HEAD
sleep 60
J=$(curl -s -H "$H" "$API/projects/$PI/jobs?per_page=1" | jq -r '.[0].id')
curl -s -H "$H" "$API/projects/$PI/jobs/$J" | jq -c '{name, ref, status, runner, failure_reason}'
```

**Verifica**:

```
{"name":"intento","ref":"prueba-runner-protegido","status":"pending","runner":null,"failure_reason":null}
```

En la UI, el job sale como atascado: ningún runner `online` del proyecto puede cogerlo. Ahora, limpieza. Cancela el pipeline y borra la rama, que solo existía para esto:

```bash
PIPE_X=$(curl -s -H "$H" "$API/projects/$PI/jobs/$J" | jq -r .pipeline.id)
curl -s --request POST "$API/projects/$PI/pipelines/$PIPE_X/cancel" -H "$H" | jq -r .status   # canceled
git switch main && git push origin --delete prueba-runner-protegido && git branch -D prueba-runner-protegido
curl -s -H "$H" "$API/runners/$RID_DEPLOY/jobs?per_page=5" | jq -r '.[].ref' | sort -u   # solo main
```

---

## ✅ Resultado

- [ ] `deploy-infra` en el grupo `infra`: etiqueta `deploy`, sin jobs sin etiqueta, `ref_protected`, 900 segundos
- [ ] Tres `[[runners]]` en un `config.toml`, un solo `system_id`
- [ ] `desplegar` con `tags: [deploy]` en `main` de `infra/entornos`
- [ ] `infra/entornos` sin `docker-app` ni runners de instancia
- [ ] `staging` desplegado desde `deploy-infra`
- [ ] Un job de rama sin proteger que se quedó en `pending`, cancelado, y la rama borrada

```bash
./scripts/verificar-semana.sh 15     # trece comprobaciones en verde
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `POST /user/runners` con `group_type` da `403` | No eres Owner del grupo `infra` | Tu token de la Semana 01 |
| `desplegar` se queda en `pending` | Falta `tags: [deploy]`, o el pipeline de `infra/entornos` no corre en `main` | Paso 3; y `ref` del pipeline: tiene que ser `main`, protegida |
| `desplegar` cae en `docker-app` | El job no pide `deploy`: el `sed` del paso 3 no entró, y `docker-app` coge los jobs sin etiqueta | `tag_list` del job vacío lo confirma; repite el paso 3 |
| `DELETE /projects/$PI/runners/$RID_DOCKER` da `403 … owner project` | `RID_DOCKER` es otro runner, dueño de `infra/entornos` | Comprueba `RID_DOCKER` con `GET /runners/$RID_DOCKER` |
| El job `intento` del paso 6 **se ejecutó** | La rama está protegida (¿un comodín `*` en las ramas protegidas?) o el runner no es `ref_protected` | `GET /projects/$PI/protected_branches` y el paso 1 |
| `ci/componentes` deja de tener runner | Quitaste `docker-app` de `ci/componentes` en vez de `infra/entornos` | `POST /projects/<ci/componentes>/runners --data runner_id=$RID_DOCKER` |

---

[← Anterior: El runner dind](02-el-runner-dind.md) · [Volver a la Semana 15](../README.md) · [Siguiente: Operar la flota →](04-operar-la-flota.md)
