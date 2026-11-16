# Práctica 02 — El runner dind

> Creas en `app` un segundo runner, `dind-app`, y lo registras en el mismo proceso que `docker-app`. Le das Docker dentro de Docker con el privilegio limitado al servicio del daemon, y escribes `probar-imagen`: un job que construye la imagen de `app` y comprueba que arranca antes de que kaniko la publique. Terminas apagando los runners de instancia en `app`.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [04](../1-teoria/04-etiquetas-y-alcance.md) y [06](../1-teoria/06-docker-in-docker.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La issue y la rama | — |
| 2 | El runner `dind-app` creado en GitLab | `dind-solo-etiquetado` |
| 3 | `dind-app` registrado en el mismo proceso | `dind-en-linea`, `una-gestora-para-app`, `flota-en-version-fijada` |
| 4 | El privilegio, solo para el daemon | — |
| 5 | `probar-imagen` en verde en `dind-app` | `imagen-probada-en-dind` |
| 6 | `app` sin runners de instancia | `app-sin-runners-compartidos` |

Si has cerrado la terminal: el paso 0 de la [práctica 01](01-la-cache-compartida.md#paso-0-preparar-el-terreno).

---

## Paso 1: La issue y la rama

**Por qué**: el job nuevo es un cambio de `app` como cualquier otro: issue, rama, merge request, aprobación de `revisor`.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Probar que la imagen arranca antes de publicarla" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Job probar-imagen en el runner dind: docker build y docker run del Dockerfile. imagen@1 espera a que pase. Ver Semana 15." \
  | jq -r .iid)
git switch -c "$IID-probar-imagen"
```

**Verifica**: `git branch --show-current` da `<IID>-probar-imagen`.

---

## Paso 2: El runner en GitLab

**Por qué**: lo que decide qué jobs coge un runner se fija en GitLab (teoría 02, apartado 2.3). `dind-app` solo coge jobs que pidan `dind` (`run_untagged=false`), y nace bloqueado (`locked=true`): un runner privilegiado no debe acabar asignado a otro proyecto sin que lo decidas.

```bash
R=$(curl -s --request POST "$API/user/runners" -H "$H" \
  --data "runner_type=project_type" --data "project_id=$ID_APP" \
  --data-urlencode "description=dind-app" --data "tag_list=dind" \
  --data "run_untagged=false" --data "locked=true")
RID_DIND=$(jq -r .id <<<"$R"); RT=$(jq -r .token <<<"$R"); unset R
echo "export RID_DIND=$RID_DIND" >> ~/.bc-gitlab-s15
```

El token `glrt-…` solo se ve ahora. No lo guardes en ningún archivo: el paso 3 lo usa y se queda en `config.toml`.

**Verifica**:

```bash
curl -s -H "$H" "$API/runners/$RID_DIND" | jq -c '{description, tag_list, run_untagged, locked, status}'
# {"description":"dind-app","tag_list":["dind"],"run_untagged":false,"locked":true,"status":"never_contacted"}
```

---

## Paso 3: En el mismo proceso

**Por qué**: un proceso, varias identidades (teoría 01). `register` añade un `[[runners]]` al `config.toml` que ya tiene `docker-app`. Todo lo local va en la línea: privilegios, los volúmenes (`/certs/client` para el TLS de `dind`, teoría 06, apartado 2.3), `limit = 1` porque cada job arranca un daemon entero, y la misma caché S3 que `docker-app`. Las etiquetas no: con un token `glrt-`, `--tag-list` es un `FATAL` (teoría 02).

```bash
cd /ruta/a/bc-gitlab
CK=$(grep '^RUNNER_CACHE_SECRET_KEY=' .env | cut -d= -f2)
docker compose exec gitlab-runner gitlab-runner register --non-interactive \
  --url http://gitlab:8888 --clone-url http://gitlab:8888 --token "$RT" \
  --name dind-app --executor docker --docker-image alpine:3.24.2 \
  --docker-network-mode bc-gitlab-network --docker-privileged \
  --docker-volumes /certs/client --docker-volumes /cache --limit 1 \
  --cache-type s3 --cache-shared --cache-s3-server-address cache-s3:8333 \
  --cache-s3-access-key runnercache --cache-s3-secret-key "$CK" \
  --cache-s3-bucket-name runner-cache --cache-s3-insecure 2>&1 | grep -E 'registered|FATAL'
unset RT CK
```

**Verifica**:

```bash
# Runner registered successfully. …
curl -s -H "$H" "$API/runners/$RID_DIND" | jq -r .status        # online
jq -n --arg p "$PROYECTO" '{query: "query($p: ID!){ project(fullPath: $p){ runners(type: PROJECT_TYPE){ nodes{ description managers{ nodes{ systemId version } } } } } }", variables: {p: $p}}' \
  | curl -s --request POST "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '.data.project.runners.nodes[] | {description, m: .managers.nodes}'
# {"description":"dind-app","m":[{"systemId":"r_…","version":"19.2.2"}]}
# {"description":"docker-app","m":[{"systemId":"r_…","version":"19.2.2"}]}
```

El mismo `systemId` en los dos: un proceso. Si salen dos distintos, has registrado `dind-app` en otro contenedor.

---

## Paso 4: El privilegio, solo para el daemon

**Por qué**: `--docker-privileged` hace privilegiados a todos los contenedores de cada job de `dind-app`, también al del `script` (teoría 06, apartado 2.2). Las dos listas lo dejan solo en el servicio `docker:29.9.3-dind`, y de paso fijan la versión del daemon. `register` no tiene opción para ellas: se editan, como en la práctica 01.

```bash
docker compose cp gitlab-runner:/etc/gitlab-runner/config.toml ~/.bc-gitlab-runner.toml
chmod 600 ~/.bc-gitlab-runner.toml
grep -n 'privileged = true' ~/.bc-gitlab-runner.toml      # una sola línea: la de dind-app
```

Debajo de esa línea, en el bloque `[runners.docker]` de `dind-app`:

```toml
    allowed_privileged_images = ["docker:29.9.3-dind"]
    allowed_privileged_services = ["docker:29.9.3-dind"]
```

```bash
docker compose cp ~/.bc-gitlab-runner.toml gitlab-runner:/etc/gitlab-runner/config.toml
sleep 5
docker compose logs --since 1m gitlab-runner 2>&1 | grep -E 'Configuration loaded|Failed to load' | tail -1
```

**Verifica**: `Configuration loaded … max_builds=3`, y

```bash
docker compose exec gitlab-runner grep -cE 'allowed_privileged_(images|services) = \["docker:29.9.3-dind"\]' /etc/gitlab-runner/config.toml
# 2
```

---

## Paso 5: `probar-imagen`

**Por qué**: kaniko construye y publica sin daemon, y por eso nadie comprueba que la imagen arranca (teoría 06, apartado 1). `probar-imagen` la construye en `dind` y la ejecuta. El `CMD` de la Semana 13 lista los módulos de `src/` y sus exportaciones: si `prestamos.ts` no sale, la imagen no sirve. Con `needs` del componente `imagen`, kaniko no publica hasta que `probar-imagen` pasa.

```bash
cat > ci/probar-imagen.yml <<'EOF'
# Construye la imagen de app en un daemon propio y comprueba que arranca.
# Solo en el runner dind-app (tags: [dind]), el único con Docker dentro.
probar-imagen:
  stage: test
  needs: []
  tags: [dind]
  image: docker:29.9.3-cli
  services:
    - name: docker:29.9.3-dind
      # Las imágenes base, por el espejo del laboratorio y no por Docker Hub.
      command: ["--registry-mirror=http://registry-cache:5000"]
  variables:
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: /certs
    DOCKER_TLS_VERIFY: "1"
    DOCKER_CERT_PATH: /certs/client
  script:
    # La frontera del privilegio: este contenedor no debe poder crear interfaces.
    - ip link add prueba0 type dummy 2>/dev/null && echo "job PRIVILEGIADO" || echo "job sin privilegios"
    - docker build -t app:prueba .
    - docker run --rm app:prueba | tee salida.txt
    - grep -q prestamos.ts salida.txt
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
EOF
```

En `.gitlab-ci.yml`, la línea nueva en `include` y `probar-imagen` en los `needs` del componente `imagen`:

```yaml
include:
  - local: ci/deploy.yml
  - local: ci/probar-imagen.yml
  # … npm@1 y gobernanza@1 sin cambios
  - component: $CI_SERVER_FQDN/plataforma-<tu-dominio>/ci/componentes/imagen@1
    inputs:
      needs: [build, test, probar-imagen]
      registro: gitlab:5050
      inseguro: true
```

```bash
git add ci/probar-imagen.yml .gitlab-ci.yml
git commit -S -m "ci: probar que la imagen arranca en dind antes de publicarla"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="ci: probar que la imagen arranca en dind" -o merge_request.description="Closes #$IID"
RAMA=$(git branch --show-current)
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$RAMA&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
```

**Verifica**: el pipeline de `main` tras la fusión, y en qué runner corrió el job:

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
J=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "probar-imagen") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$J" | jq -c '{status, tag_list, runner: .runner.description}'
# {"status":"success","tag_list":["dind"],"runner":"dind-app"}
curl -s -H "$H" "$API/projects/$P/jobs/$J/trace" | sed 's/\x1b\[[0-9;]*[mK]//g' \
  | grep -E 'job (sin privilegios|PRIVILEGIADO)|prestamos.ts' | cut -c1-80
# job sin privilegios
# prestamos.ts [ 'calcularMulta' ]
```

Si dice `job PRIVILEGIADO`, el paso 4 no ha entrado: el `script` tiene privilegios que no necesita.

---

## Paso 6: Fuera los runners de instancia

**Por qué**: si tu instancia tiene un runner de instancia que acepta jobs sin etiqueta, compite con `docker-app` por los de `app` (teoría 04, apartado 2.4). Con la flota propia, sobra.

```bash
curl -s --request PUT "$API/projects/$P" -H "$H" --data "shared_runners_enabled=false" \
  | jq '.shared_runners_enabled'
```

**Verifica**: `false`, y que `app` sigue funcionando sin ellos:

```bash
PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode "ref=main" | jq -r .id)
esperar "$P" "$PIPE"                                         # success
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs?per_page=50" \
  | jq -r '[.[] | .runner.description // empty] | unique | join(" ")'
# dind-app docker-app
```

Los jobs `trigger` (`infra`) no son jobs de runner y esta lista no los trae; los manuales sin lanzar (`infra-production`) no tienen runner todavía.

---

## ✅ Resultado

- [ ] `dind-app` en `app`: etiqueta `dind`, sin jobs sin etiqueta, bloqueado
- [ ] `dind-app` y `docker-app` en el mismo proceso, con la versión `19.2.2`
- [ ] El privilegio limitado al servicio `docker:29.9.3-dind`
- [ ] `probar-imagen` en verde en `dind-app`, sin privilegios en el job, y `imagen` esperando por él
- [ ] `app` sin runners de instancia

```bash
./scripts/verificar-semana.sh 15     # siete comprobaciones en verde
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `register` dice `FATAL: Runner configuration other than name and executor configuration is reserved` | Has añadido `--tag-list`, `--locked` o `--run-untagged` | Quítalos: van en el paso 2, en GitLab |
| `probar-imagen` se queda en `pending` | `dind-app` no está `online`, o no tiene la etiqueta `dind` | `GET /projects/$P/runners?tag_list=dind&status=online` |
| `Cannot connect to the Docker daemon at tcp://docker:2376` | El servicio no arrancó privilegiado: la versión del job no coincide con la lista | La misma `docker:29.9.3-dind` en el YAML y en las dos listas |
| `x509: certificate signed by unknown authority` | Falta el volumen `/certs/client` en `dind-app` | `--docker-volumes /certs/client` en el paso 3, o añádelo a `volumes` |
| `toomanyrequests` al descargar `node:22.23.3-alpine3.24` | El daemon fue a Docker Hub sin pasar por el espejo | `command: ["--registry-mirror=http://registry-cache:5000"]` en el servicio |
| `grep -q prestamos.ts` falla | `.dockerignore` deja fuera `src/`, o el `CMD` cambió | Lee `salida.txt` en el log: es lo que imprime la imagen |
| `una-gestora-para-app` falla con dos `systemId` | Registraste `dind-app` en otro contenedor | Bórralo (`DELETE /runners/$RID_DIND`), repite los pasos 2 y 3 contra `gitlab-runner` |

---

[← Anterior: La caché compartida](01-la-cache-compartida.md) · [Volver a la Semana 15](../README.md) · [Siguiente: El runner protegido →](03-el-runner-protegido.md)
