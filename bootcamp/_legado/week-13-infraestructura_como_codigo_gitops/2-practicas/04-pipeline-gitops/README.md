# Práctica 04 — Pipeline GitOps: del Commit al Clúster vía el Agent

## Objetivo

Construir un pipeline `.gitlab-ci.yml` que, en lugar de desplegar directamente con `kubectl` (push-based), actualiza el tag de imagen en un manifiesto de Kubernetes y hace commit al repositorio de manifiestos — dejando que el GitLab Kubernetes Agent (práctica 03) sincronice el cambio al clúster Minikube.

## Requisitos

- Agent registrado y conectado (práctica 03)
- Un proyecto GitLab que aloje el código de una app demo (puede ser el mismo `api-pagos` de las semanas 07/09, o cualquier app trivial)
- Tiempo estimado: 60-90 minutos

---

## Instrucciones

### Paso 1: Preparar el repositorio de manifiestos

```bash
mkdir -p manifests/produccion/demo-app
cp /ruta/al/starter/deployment.yaml manifests/produccion/demo-app/
cp /ruta/al/starter/service.yaml manifests/produccion/demo-app/
git add manifests/
git commit -m "chore(gitops): manifiestos iniciales de demo-app"
git push origin main
```

### Paso 2: Apuntar el `config.yaml` del agent a este proyecto

Actualiza `.gitlab/agents/minikube-bootcamp/config.yaml` (creado en la práctica 03) para incluir este proyecto como `manifest_projects` si es distinto del proyecto donde vive el agent.

### Paso 3: Completar el pipeline GitOps

Copia y completa `starter/.gitlab-ci.yml` — el job `actualizar_manifiesto` debe:

1. Clonar el repo de manifiestos usando `CI_JOB_TOKEN`
2. Reemplazar el tag de imagen con `sed`
3. Hacer commit y push

```yaml
# .gitlab-ci.yml
# ¿QUÉ HACE?: Actualiza el tag de imagen en el manifiesto y lo empuja a Git — NO despliega directamente
# ¿POR QUÉ?: El agent, no el runner de CI, tiene las credenciales de escritura hacia el clúster
# ¿PARA QUÉ?: Que el pipeline nunca necesite kubeconfig ni acceso de red hacia Minikube
actualizar_manifiesto:
  stage: deploy
  image: alpine/git:latest
  script:
    - git clone "https://gitlab-ci-token:${CI_JOB_TOKEN}@localhost/plataforma/gitops-manifiestos.git" repo
    - cd repo
    - sed -i "s|image: .*|image: registry.local/plataforma/demo-app:${CI_COMMIT_SHORT_SHA}|" manifests/produccion/demo-app/deployment.yaml
    - git config user.email "ci@bootcamp.local"
    - git config user.name "GitLab CI"
    - git commit -am "deploy(demo-app): ${CI_COMMIT_SHORT_SHA}"
    - git push origin main
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### Paso 4: Disparar el pipeline y observar la reconciliación

```bash
git commit --allow-empty -m "test: disparar pipeline gitops"
git push origin main
```

Observa el pipeline en la UI (Build → Pipelines). Cuando el job `actualizar_manifiesto` termine, el agent debe recoger el cambio en su próximo ciclo (hasta ~1 minuto):

```bash
kubectl get deployment demo-app -n produccion -o jsonpath='{.spec.template.spec.containers[0].image}'
# → debe mostrar el tag con el SHA del commit recién pusheado
```

### Paso 5: Provocar y observar drift

```bash
# Modificar manualmente el clúster, sin pasar por Git
kubectl scale deployment demo-app --replicas=5 -n produccion

# Esperar un ciclo de reconciliación y verificar
sleep 90
kubectl get deployment demo-app -n produccion -o jsonpath='{.spec.replicas}'
# → debe volver al valor declarado en el manifiesto (drift corregido automáticamente)
```

### Paso 6 (opcional — reto): revertir con `git revert`

```bash
# En vez de un deploy manual, revertir el último commit de deploy
git log --oneline -5
git revert <sha-del-commit-de-deploy> --no-edit
git push origin main
# El agent reconcilia hacia el estado anterior automáticamente
```

---

## Preguntas de reflexión

1. ¿Por qué este pipeline nunca necesita un `kubeconfig` como variable protegida?
2. ¿Cuánto tiempo pasó entre el `git push` y el cambio real en el clúster? ¿Cómo se relaciona con el `reconcile_timeout` del `config.yaml`?
3. Compara este pipeline con el `deploy_produccion` push-based que construiste en la semana 06. ¿Qué job es más simple y por qué?

---

## Entregables

- [ ] Manifiestos versionados en `manifests/produccion/demo-app/`
- [ ] Pipeline que actualiza el manifiesto en cada push a `main`, sin usar `kubectl` directamente
- [ ] Evidencia de que el agent reconcilió el cambio (captura de `kubectl get deployment`)
- [ ] Evidencia de drift corregido automáticamente tras un cambio manual con `kubectl scale`
