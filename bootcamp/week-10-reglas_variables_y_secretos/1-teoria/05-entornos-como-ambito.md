# Entornos como ámbito

> `staging` y `production` necesitan credenciales distintas con el mismo nombre, para que `scripts/deploy.sh` no tenga que saber dónde está. `environment_scope` lo resuelve: la misma variable, un valor por entorno. Lo que no resuelve es la seguridad, y en CE hay que saber exactamente por qué.

---

## 🎯 Objetivos

- Declarar un entorno en un job con `environment`
- Dar a una variable un valor distinto por entorno con `environment_scope`
- Explicar por qué `environment_scope` no es una barrera de seguridad sin `protected`
- Montar el despliegue manual a producción que CE permite sin entornos protegidos

---

## 1. Qué problema resuelve

Sin ámbitos, un despliegue a dos entornos necesita dos variables (`STAGING_TOKEN`, `PRODUCTION_TOKEN`) y un script que elija entre ellas. Un error en esa elección despliega en `production` con la credencial de `staging`, o al revés. Con ámbitos, el job de `staging` recibe `DEPLOY_TOKEN` con el valor de `staging`, y el de `production` con el suyo. El script es el mismo.

---

## 2. Cómo funciona

### 2.1 `environment` en un job

```yaml
deploy-staging:
  extends: .deploy
  environment:
    name: staging
    url: https://staging.app.example
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

| Lo que hace | Dónde se ve |
|---|---|
| Crea el entorno la primera vez que el job se ejecuta | `Operate → Environments`, `GET .../environments` |
| Registra un **despliegue** por cada ejecución | `GET .../deployments?environment=staging` |
| Entrega `CI_ENVIRONMENT_NAME`, `CI_ENVIRONMENT_URL` y `CI_ENVIRONMENT_TIER` al job | En el job |
| Selecciona las variables cuyo ámbito coincide con el nombre | En el job |

GitLab deduce el *tier* del nombre: `staging` es `staging`, `production` es `production`. Los entornos de esta semana son solo eso: un nombre, una URL y un historial de despliegues. La Semana 14 les pone algo vivo detrás.

### 2.2 `environment_scope`

Cada variable de proyecto tiene un ámbito, `*` por defecto. Un job recibe la variable si el ámbito coincide con el nombre de **su** entorno:

| Ámbito de la variable | `deploy-staging` | `deploy-production` | Un job sin `environment` |
|---|:--:|:--:|:--:|
| `*` | ✅ | ✅ | ✅ |
| `staging` | ✅ | ❌ | ❌ |
| `production` | ❌ | ✅ | ❌ |
| `review/*` | ❌ | ❌ | ❌ |

Varias variables pueden tener la misma clave con ámbitos distintos: eso es `DEPLOY_TOKEN` en `app`. Si coinciden varias, gana la del ámbito más específico.

Un job sin `environment` no recibe ninguna variable con ámbito. En el laboratorio, la sonda sin entorno recibió `DEPLOY_TOKEN` con longitud 0; `deploy-staging`, 32; `deploy-production`, 40.

### 2.3 Por qué no es una barrera

El nombre del entorno lo escribe **el YAML del job**. Cualquiera que pueda cambiar el YAML puede escribir `environment: production`:

```yaml
intento:
  environment:
    name: production
    action: prepare
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - echo "${#SOLO_PRODUCTION}"
```

En el laboratorio, una variable **no protegida** con ámbito `production` llegó entera a este job, en la merge request de un Developer. `action: prepare` ni siquiera registra un despliegue.

Lo que sí la frenó fue `protected`: `DEPLOY_TOKEN`, protegida y con ámbito `production`, llegó vacía a ese mismo job. Por eso las dos variables de `app` son **protegidas y con ámbito**:

| Atributo | Decide |
|---|---|
| `protected` | Si el secreto sale de las refs protegidas. **Seguridad** |
| `environment_scope` | Cuál de los dos secretos recibe cada job. **Organización** |

### 2.4 Lo que en CE falta: entornos protegidos

En Premium, un **entorno protegido** (*protected environment*) decide quién puede desplegar en `production`, y las **aprobaciones de despliegue** (*deployment approvals*) exigen que alguien lo apruebe antes. Ninguna de las dos existe en CE.

| Premium | Sustituto en CE, en `app` |
|---|---|
| Solo ciertos usuarios despliegan en `production` | `deploy-production` solo corre en `main`, que es ref protegida; solo los Maintainers fusionan en `main` |
| Una aprobación antes de desplegar | `when: manual`: alguien con permiso para lanzar jobs en `main` lo lanza a propósito |
| El secreto de `production` solo para ese entorno | `DEPLOY_TOKEN` protegida y con ámbito `production` |

¿Y quién puede lanzar el job manual? Lanzar un job de una rama protegida exige poder fusionar en ella. En el laboratorio, un Developer recibió `403` al lanzar `deploy-production` de `main`. El sustituto, por tanto, vale lo que vale la protección de `main`: si algún día das permiso de fusión a Developers, también les das el despliegue a `production`. Y no hay segunda persona: quien puede fusionar puede desplegar solo. Escríbelo en el ADR.

### 2.5 El despliegue manual

```yaml
deploy-production:
  extends: .deploy
  environment:
    name: production
    url: https://app.example
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
      allow_failure: true
```

| Línea | Por qué |
|---|---|
| `if: ... DEFAULT_BRANCH` | Solo desde `main`, una ref protegida |
| `when: manual` | Nadie despliega en `production` sin querer |
| `allow_failure: true` | Sin ella el pipeline se queda en `manual`, no en `success` (teoría 01) |
| `interruptible: false` en `.deploy` | Un commit nuevo no corta un despliegue a la mitad (teoría 02) |

---

## 3. Cómo se configura

```bash
# Un valor por entorno, sin que el valor se vea
for e in staging production; do
  openssl rand -hex 32 | tr -d '\n' \
    | curl -s --request POST "$API/projects/$P/variables" -H "$H" \
        --data "key=DEPLOY_TOKEN" --data "environment_scope=$e" \
        --data-urlencode "value@-" --data "protected=true" \
        --data "masked_and_hidden=true" --data "masked=true" \
    | jq -c '{key, environment_scope, protected, masked, hidden}'
done

# Cambiar la de un solo entorno
curl -s --request PUT "$API/projects/$P/variables/DEPLOY_TOKEN?filter%5Benvironment_scope%5D=production" ...
```

Sin `filter[environment_scope]`, un `PUT` o un `DELETE` sobre una clave repetida no sabe cuál tocar.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `environment_scope` sin `protected` | Cualquier merge request escribe `environment: production` y recibe el secreto | Protegida **y** con ámbito |
| `STAGING_TOKEN` y `PRODUCTION_TOKEN` | El script elige, y un día elige mal | Una clave, un valor por ámbito |
| `deploy-production` automático en `main` | Cada fusión despliega en producción sin que nadie lo decida | `when: manual` hasta que haya entornos de verdad (Semana 14) |
| Llamar "protegido" a un entorno de CE | En CE no existe; el que lo lea pensará que alguien aprueba | Escribir el sustituto y su hueco |

---

## 5. Trucos

- **Los despliegues de un entorno**: `GET .../deployments?environment=production&status=success&order_by=id&sort=desc`.
- **Qué entornos hay**: `GET .../environments | jq -r '.[] | "\(.name) \(.tier) \(.state)"'`.
- **Las variables de un ámbito**: `GET .../variables | jq '.[] | select(.environment_scope == "production") | .key'`.

---

## 📚 Recursos Adicionales

- [Environments](https://docs.gitlab.com/ci/environments/) — `environment`, tiers y despliegues
- [Limit the environment scope of a CI/CD variable](https://docs.gitlab.com/ci/environments/#limit-the-environment-scope-of-a-cicd-variable) — ámbitos y comodines
- [Protected environments](https://docs.gitlab.com/ci/environments/protected_environments/) — Premium: lo que CE no tiene
- [Deployments API](https://docs.gitlab.com/api/deployments/) — filtros por entorno y estado

---

## ✅ Checklist de Verificación

- [ ] Sabes qué variables recibe un job según su `environment`
- [ ] Sabes por qué `environment_scope` sin `protected` no protege nada
- [ ] Sabes qué sustituye en CE a los entornos protegidos y qué hueco deja
- [ ] Sabes por qué `deploy-production` es manual, no bloquea y no se interrumpe

---

[← Anterior: Proteger, enmascarar, ocultar](04-proteger-enmascarar-ocultar.md) · [Volver a la Semana 10](../README.md) · [Siguiente: Variables de archivo y *secure files* →](06-variables-de-archivo-y-secure-files.md)
