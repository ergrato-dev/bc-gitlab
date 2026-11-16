# El chart del runner

> En la Semana 15 escribías `config.toml` a mano y reiniciabas el contenedor. En Kubernetes, el `config.toml` lo genera el chart de Helm a partir de un archivo de valores, el token vive en un `Secret`, y "reiniciar" es `helm upgrade`. El archivo de valores no lleva ningún secreto, así que se puede versionar en `infra/entornos`, igual que la plantilla de la Semana 15.

---

## 🎯 Objetivos

- Instalar el runner con el chart oficial, en una versión fijada que corresponde a `19.2.2`
- Separar lo que va en el archivo de valores de lo que va en un `Secret`
- Escribir `[runners.kubernetes]` y la caché S3 dentro de `runners.config`
- Saber qué pasa con el gestor y con los jobs en curso en cada `helm upgrade`

---

## 1. Qué problema resuelve

Un Deployment del runner escrito a mano son una cuenta de servicio, un rol con permiso para crear pods, un `ConfigMap` con la configuración, un `Secret` y el propio Deployment. El chart `gitlab/gitlab-runner` los genera todos, y su versión fija la del runner:

| Chart | Runner (`appVersion`) |
|---|---|
| `0.91.2` | `19.2.2` |
| `0.91.4` | `19.2.4` |
| `0.94.3` | `19.5.3` |

```bash
helm repo add gitlab https://charts.gitlab.io
helm search repo gitlab/gitlab-runner --versions | awk '$3 ~ /^19\.2/'
```

La regla de la Semana 15 sigue: el runner va en la misma serie que GitLab. Con `19.2.4-ce.0`, el chart `0.91.2`.

---

## 2. Cómo funciona

### 2.1 Lo que va en cada sitio

| Dato | Dónde | Por qué |
|---|---|---|
| URL de GitLab, `concurrent`, `rbac`, nombre | Archivo de valores | No es secreto: se versiona |
| `config.toml` del runner, sin token | `runners.config` del archivo de valores | Ídem |
| Token `glrt-…` | `Secret` `runner-token`, claves `runner-token` y `runner-registration-token` | Un `glrt-` en Git es un runner robado |
| Clave de `cache-s3` | `Secret` `cache-s3`, claves `accesskey` y `secretkey` | Ídem |

```bash
printf '%s' "$RT" | kubectl -n gitlab-runner create secret generic runner-token \
  --from-literal=runner-registration-token="" --from-file=runner-token=/dev/stdin
```

El token entra por la entrada estándar: no queda en el historial, ni en los argumentos de `kubectl`, que cualquiera ve con `ps` mientras corre. `printf '%s'` y no `echo`, ni un archivo escrito con `jq -r`: los dos acaban en salto de línea, y el `Secret` lo arrastraría. `runner-registration-token` va vacío: el chart lo pide, pero los tokens de registro están retirados desde la Semana 09.

### 2.2 El archivo de valores

```yaml
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
```

| Clave | Qué hace |
|---|---|
| `gitlabUrl` | La URL con la que el gestor habla con GitLab. Desde el clúster, `gitlab:8888` |
| `clone_url` | La que usa el `helper` para clonar, por la misma razón que en la Semana 09 |
| `rbac.create` y `rbac.rules` | Una cuenta de servicio y un rol en el namespace `gitlab-runner`. **Sin `rules`, el rol del chart da `*` sobre `*`** en el namespace; con estas, solo lo que el ejecutor usa: crear y borrar pods, crear y leer por nombre los secretos de cada job (sin listarlos), `exec`/`attach` para ejecutar el `script`, leer logs y eventos |
| `runners.secret` | El `Secret` con el token: el chart lo inyecta al arrancar |
| `runners.cache.secretName` | El `Secret` con la clave S3: el chart la pasa como `CACHE_S3_ACCESS_KEY`/`CACHE_S3_SECRET_KEY` |
| `runners.config` | El `[[runners]]` sin `url`, sin `token` y sin `executor`: esos los pone el chart. Pasa por `tpl`, de ahí `{{ .Release.Namespace }}` |

`ServerAddress`, `BucketName`, `Shared` e `Insecure` son los de la plantilla de la Semana 15. Los tres runners de entonces y este escriben en el mismo bucket.

### 2.3 Instalar y actualizar

```bash
helm install k8s-app gitlab/gitlab-runner --version 0.91.2 -n gitlab-runner -f k8s-app.values.yaml
helm upgrade k8s-app gitlab/gitlab-runner --version 0.91.2 -n gitlab-runner -f k8s-app.values.yaml
```

`--version` siempre: sin él, Helm instala el último chart, que hoy trae un runner de la serie 19.5 contra un GitLab 19.2.

Cada `upgrade` cambia el `ConfigMap` y el chart reinicia el pod del gestor. El pod nuevo es un gestor nuevo: GitLab lo ve con otro `system_id` (el del pod empieza por `r_`), y el viejo desaparece de `GET /runners/:id/managers` al apagarse. El runner, su ID y su token no cambian. Tampoco `helm uninstall` los borra: se lleva el gestor, y el runner se queda en GitLab sin ninguno hasta que lo borras por API. El pod viejo espera a que acaben sus jobs hasta `terminationGracePeriodSeconds` (3600 s por defecto en el chart).

---

> [!WARNING]
> Las reglas recortan, pero no aíslan del todo: el gestor sigue pudiendo leer **por nombre** `runner-token` y `cache-s3`, porque viven en su mismo namespace, y con `create pods` podría montarlos en un pod. Es inevitable mientras el gestor y los jobs compartan namespace. El siguiente paso, fuera del alcance de esta semana, es `runners.jobNamespace`: los pods de los jobs en otro namespace, con un rol allí y sin acceso a los `Secret` del gestor.

## 3. Cómo se comprueba

```bash
kubectl -n gitlab-runner logs deploy/k8s-app-gitlab-runner | grep 'is valid'
# Verifying runner... is valid  runner=CqofORiPv runner_name=k8s-app
glab api "runners/<id>/managers" | jq -c '.[] | {system_id, version, status}'
# {"system_id":"r_pgqHfi1CBwAQ","version":"19.2.2","status":"online"}
```

Y en GraphQL, el ejecutor de cada gestor:

```graphql
{ project(fullPath: "plataforma-biblioteca/app") {
    runners(type: PROJECT_TYPE) { nodes { description paused managers { nodes { executorName version } } } } } }
```

`executorName: "kubernetes"` para este, `"docker"` para `docker-app` y `dind-app`. El campo está en el gestor, no en el runner: un mismo token puede tener gestores con ejecutores distintos.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `runnerToken: glrt-…` en el archivo de valores | El archivo se versiona y el token va con él | `runners.secret` |
| `helm install` sin `--version` | El runner sube de serie sin que nadie lo decida | `--version 0.91.2` |
| `helm upgrade --set` para cada cambio | Lo que corre deja de coincidir con lo versionado | Cambiar el archivo, `helm upgrade -f` |
| `rbac.create: true` sin `rules` | El rol por defecto da todos los verbos sobre todos los recursos del grupo core del namespace: listar y leer cualquier `Secret`, cambiar `ConfigMaps`, borrar el gestor | `rbac.rules` con lo que el ejecutor usa (apartado 2.2), comprobado con un pipeline entero |

---

## 5. Trucos

- `helm get values k8s-app -n gitlab-runner` enseña lo que está aplicado; un `diff` contra el archivo de `infra/entornos` dice si alguien cambió algo a mano.
- `kubectl -n gitlab-runner get cm k8s-app-gitlab-runner -o jsonpath='{.data.config\.template\.toml}'` enseña el `[[runners]]` tal como lo recibe el runner, después de `tpl`.

---

## 📚 Recursos Adicionales

- [GitLab Runner Helm chart](https://docs.gitlab.com/runner/install/kubernetes/)
- [Configure the GitLab Runner Helm chart](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/)
- [The Kubernetes executor — configuration settings](https://docs.gitlab.com/runner/executors/kubernetes/)

---

## ✅ Checklist de Verificación

- [ ] Sé qué versión del chart corresponde a mi runner y cómo buscarla
- [ ] Sé qué va en el archivo de valores y qué en un `Secret`
- [ ] Sé por qué `runners.config` no lleva `url` ni `token`
- [ ] Sé qué le pasa al gestor y a sus jobs en cada `helm upgrade`
