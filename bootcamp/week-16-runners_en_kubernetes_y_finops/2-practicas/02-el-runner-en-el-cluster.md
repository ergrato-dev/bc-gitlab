# Práctica 02 — El runner en el clúster

> Creas en GitLab el runner `k8s-app`, con la misma etiqueta que `docker-app` pero **en pausa**, para que no le quite ningún job antes de medir la línea base. Guardas su token en un `Secret`, escribes el archivo de valores sin un solo secreto, e instalas el chart en la versión que corresponde a tu runner. Al final compruebas qué ve GitLab: un gestor nuevo, con ejecutor `kubernetes`, y qué puede hacer su cuenta de servicio en el clúster.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada · Teoría [03](../1-teoria/03-el-chart-del-runner.md) y [04](../1-teoria/04-el-pod-de-un-job.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | La versión del chart para `19.2.2` | — |
| 2 | El runner `k8s-app` en GitLab, en pausa | — |
| 3 | Su token en el `Secret` `runner-token` | — |
| 4 | El archivo de valores, y el chart instalado | `runner-kubernetes-en-version-fijada` |
| 5 | El gestor visto desde GitLab | — |
| 6 | Lo que puede y lo que no puede la cuenta de servicio | — |

Desde la terminal de la práctica 01, o repitiendo su paso 0.

---

## Paso 1: La versión del chart

**Por qué**: la versión del chart fija la del runner. Sin `--version`, Helm instala el último, de otra serie (teoría 03, apartado 1).

```bash
helm repo add gitlab https://charts.gitlab.io
helm repo update gitlab
helm search repo gitlab/gitlab-runner --versions | awk 'NR == 1 || $3 == "19.2.2"'
```

**Verifica**: una fila, `gitlab/gitlab-runner 0.91.2 19.2.2`. Es la misma serie que `RUNNER_VERSION` en tu `.env`.

---

## Paso 2: El runner, en pausa

**Por qué**: `k8s-app` va a sustituir a `docker-app`, así que nace con su etiqueta `docker` y `run_untagged`. Pero la línea base de la práctica 03 tiene que medir a `docker-app` solo: con los dos activos, cada job caería en uno u otro. Por eso nace en pausa. El token sale **una vez**, en esta respuesta.

```bash
R=$(curl -s --request POST "$API/user/runners" -H "$H" \
  --data runner_type=project_type --data project_id="$ID_APP" \
  --data description=k8s-app --data tag_list=docker --data run_untagged=true \
  --data paused=true)
RID_K8S=$(jq -r .id <<<"$R"); RT=$(jq -r .token <<<"$R"); unset R
echo "export RID_K8S=$RID_K8S" >> ~/.bc-gitlab-s16
```

**Verifica**:

```bash
curl -s -H "$H" "$API/runners/$RID_K8S" | jq -c '{description, tag_list, run_untagged, paused, status}'
```

`{"description":"k8s-app","tag_list":["docker"],"run_untagged":true,"paused":true,"status":"never_contacted"}`. `never_contacted`: existe en GitLab, pero ningún gestor ha presentado su token todavía. Y `${RT:0:5}` dice `glrt-`.

---

## Paso 3: El token, en un `Secret`

**Por qué**: el chart lee el token de un `Secret` con dos claves; `runner-registration-token` va vacía (teoría 03, apartado 2.1). El token entra por la entrada estándar y sin salto de línea: ni en el historial ni en los argumentos que enseña `ps`.

```bash
printf '%s' "$RT" | kubectl -n gitlab-runner create secret generic runner-token \
  --from-literal=runner-registration-token="" --from-file=runner-token=/dev/stdin
unset RT
```

**Verifica**:

```bash
kubectl -n gitlab-runner get secret runner-token -o jsonpath='{.data.runner-token}' | base64 -d | cut -c1-5; echo
```

`glrt-`, y nada más. El token ya no está en ninguna variable de tu terminal.

---

## Paso 4: El archivo de valores y el chart

**Por qué**: todo lo que no es secreto, en un archivo que la práctica 04 versiona en `infra/entornos`. La caché es la de la Semana 15; los recursos, los de la teoría 04; el rol, solo lo que el ejecutor usa (teoría 03, apartado 2.2).

```bash
cat > ~/bc-s16/k8s-app.values.yaml <<'EOF'
# Runner k8s-app de app: chart gitlab/gitlab-runner 0.91.2 (runner 19.2.2).
# Sin secretos: el token está en el Secret runner-token y la clave S3 en cache-s3.
gitlabUrl: http://gitlab:8888
concurrent: 6
checkInterval: 3
rbac:
  create: true
  rules:
    - resources: ["pods"]
      verbs: ["create", "delete", "get", "list", "watch"]
    - resources: ["secrets"]
      verbs: ["create", "delete", "get", "update"]
    - resources: ["pods/exec", "pods/attach"]
      verbs: ["create", "get", "patch", "delete"]
    - resources: ["pods/log", "events"]
      verbs: ["get", "list", "watch"]
    - resources: ["serviceaccounts"]
      verbs: ["get"]
runners:
  secret: runner-token
  name: k8s-app
  cache:
    secretName: cache-s3
  config: |
    [[runners]]
      clone_url = "http://gitlab:8888"
      [runners.kubernetes]
        namespace = "{{ .Release.Namespace }}"
        image = "alpine:3.24.2"
        cpu_request = "100m"
        memory_request = "128Mi"
        memory_limit = "1Gi"
        helper_memory_request = "32Mi"
      [runners.cache]
        Type = "s3"
        Shared = true
        [runners.cache.s3]
          ServerAddress = "cache-s3:8333"
          BucketName = "runner-cache"
          Insecure = true
EOF
helm install k8s-app gitlab/gitlab-runner --version 0.91.2 -n gitlab-runner -f ~/bc-s16/k8s-app.values.yaml
kubectl -n gitlab-runner rollout status deploy/k8s-app-gitlab-runner --timeout=180s
```

**Verifica**:

```bash
kubectl -n gitlab-runner logs deploy/k8s-app-gitlab-runner | grep -m1 'is valid'
curl -s -H "$H" "$API/runners/$RID_K8S/managers" | jq -c '.[] | {system_id, version, status}'
```

`Verifying runner... is valid … runner_name=k8s-app`, y un gestor `online` con `version` `19.2.2`. Su `system_id` empieza por `r_`, distinto del de `docker-app` y `dind-app`: es otro proceso, en otra máquina.

---

## Paso 5: Lo que ve GitLab

**Por qué**: ahora `app` tiene dos runners con la etiqueta `docker`, uno en pausa. GraphQL enseña de qué ejecutor es cada gestor; ese campo es el que miran las comprobaciones de la semana (teoría 03, apartado 3).

```bash
jq -n --arg p "$PROYECTO" '{query: "query($p: ID!) { project(fullPath: $p) { runners(type: PROJECT_TYPE) { nodes { description tagList paused managers { nodes { executorName version } } } } } }", variables: {p: $p}}' \
  | curl -s --request POST "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- \
  | jq -c '.data.project.runners.nodes[] | {description, tagList, paused, ejecutor: [.managers.nodes[].executorName]}'
```

**Verifica**: tres líneas. `docker-app` y `dind-app` con `["docker"]`, sin pausa; `k8s-app` con `["kubernetes"]` y `paused: true`. Lanza un pipeline de `main` si quieres comprobar que nada cambia: todos sus jobs siguen en `docker-app` y `dind-app`.

---

## Paso 6: Lo que puede la cuenta de servicio

**Por qué**: el gestor crea pods con la cuenta de servicio del chart. Con `rbac.rules` puede lo que el ejecutor necesita, no todo el namespace (teoría 03, antipatrones). `kubectl auth can-i` lo pregunta en su nombre.

```bash
SA=system:serviceaccount:gitlab-runner:k8s-app-gitlab-runner
while read -r verbo recurso ns; do
  printf '%-8s %-12s %-14s %s\n' "$verbo" "$recurso" "$ns" "$(kubectl auth can-i "$verbo" "$recurso" -n "$ns" --as=$SA)"
done <<'EOF'
create pods gitlab-runner
create pods/exec gitlab-runner
get secrets gitlab-runner
list configmaps gitlab-runner
create deployments gitlab-runner
create pods default
EOF
```

**Verifica**: `yes` en las tres primeras líneas y `no` en las tres últimas. El rol vale solo en `gitlab-runner`: en `default` no puede crear nada. Sin `rules` en el archivo de valores, `list configmaps` también daría `yes` (el rol por defecto da todo el grupo core); `create deployments` no, porque `Deployment` está en el grupo `apps`. Y `kubectl auth can-i list secrets -n gitlab-runner --as=$SA` da `no`: lee un `Secret` si sabe su nombre, pero no puede listarlos.

---

## ✅ Resultado

- [ ] `k8s-app` creado en `app` con `docker` y `run_untagged`, en pausa, con `RID_K8S` guardado
- [ ] El token en el `Secret` `runner-token`, y en ninguna variable ni archivo
- [ ] `~/bc-s16/k8s-app.values.yaml` sin secretos
- [ ] El chart `0.91.2` instalado, con un gestor `online` en `19.2.2`
- [ ] GraphQL enseña `kubernetes` para `k8s-app` y `docker` para los otros dos
- [ ] La cuenta de servicio no puede tocar `configmaps`, `deployments` ni otros namespaces

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| El pod del gestor en `CrashLoopBackOff` con `is not valid` o `403 Forbidden` | El token del `Secret` está mal o lleva un salto de línea | `kubectl -n gitlab-runner delete secret runner-token`; `RT=$(curl -s --request POST "$API/runners/$RID_K8S/reset_authentication_token" -H "$H" \| jq -r .token)`, sin imprimirlo; el paso 3 con él, y `kubectl -n gitlab-runner rollout restart deploy/k8s-app-gitlab-runner` |
| `CreateContainerConfigError` en el pod del gestor | El `Secret` no tiene alguna de las dos claves | `kubectl -n gitlab-runner get secret runner-token -o jsonpath='{.data}' \| jq keys` debe dar `runner-registration-token` y `runner-token` |
| El gestor arranca pero no sale en `/managers` | `gitlabUrl` no llega desde el clúster | El paso 5 de la práctica 01 |
| `version` distinta de `19.2.2` | Instalaste sin `--version` | `helm upgrade … --version 0.91.2 -f …` |
| `helm install` dice `cannot re-use a name that is still in use` | Ya hay una instalación `k8s-app` | `helm upgrade` con los mismos argumentos |

---

[← Volver a la Semana 16](../README.md)
