# Proyecto Semana 10 — Cero secretos en el YAML, cero pipelines que no hacen falta

> En la Semana 09 `app` tuvo un pipeline. Esta semana el pipeline decide qué ejecuta en cada caso, y cada secreto llega solo a donde tiene que llegar. El proyecto deja por escrito qué secretos existen, quién puede leerlos de verdad y cuándo caducan, y ensaya la rotación del único que llega a las merge requests.

---

## 🎯 Objetivo

Dejar en pie la **capa 10** de tu plataforma: reglas que evitan trabajo inútil, secretos protegidos y separados por entorno, una clave como variable de archivo, un inventario de secretos en el repositorio, el ADR-007 ampliado y `GOBERNANZA_TOKEN` rotado sin que nadie lo viera.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| `workflow` con `name` y `auto_cancel` | S11 (los pipelines hijos y programados se distinguen por su nombre) |
| Reglas con `changes` en `.npm` | S12 (las reglas viajan con el componente) |
| Entornos `staging` y `production` | S14 (despliegue real, review apps y *rollback*) |
| `DEPLOY_TOKEN` y `DEPLOY_SSH_KEY` | S14 (credenciales del destino real) |
| `scripts/deploy.sh` | S14 (despliega de verdad, con los mismos secretos) |
| `docs/secretos.md` | S11 (un pipeline programado avisa antes de cada caducidad), S19 (Gitleaks comprueba que ningún secreto se escapa al repositorio), S22 (respuesta a incidentes) |
| Variables de pipeline solo para Maintainer | Toda la plataforma |

La decisión con más recorrido es **qué secreto se acepta que llegue a una merge request**. Hoy, uno: `GOBERNANZA_TOKEN`. Cada secreto que se añada a esa lista necesita su fila en el inventario y su línea en el ADR-007.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 10` contra la API de tu instancia.

1. workflow da nombre a cada pipeline
2. Un commit nuevo cancela los jobs interrumpibles del pipeline anterior
3. build y test solo se ejecutan en una merge request si cambia el codigo
4. deploy-production es manual, no bloquea el pipeline y no se interrumpe
5. Existen los entornos staging y production
6. Hay un despliegue correcto en staging
7. Hay un despliegue correcto en production
8. DEPLOY_TOKEN existe para staging y para production, protegida y enmascarada en los dos
9. DEPLOY_SSH_KEY es una variable de tipo archivo, protegida y solo para production
10. Todas las variables del proyecto son protegidas, salvo GOBERNANZA_TOKEN
11. Todas las variables de texto del proyecto son enmascaradas
12. Ningun secure file tiene nombre de clave privada
13. Solo Maintainer o mas puede pasar variables al lanzar un pipeline
14. El token gobernanza-ci se ha rotado: uno activo y al menos uno revocado
15. El ultimo pipeline de main esta en verde
16. El .gitlab-ci.yml de main no contiene nada con forma de token o de clave
17. docs/secretos.md existe en main y nombra cada secreto del pipeline
18. El ADR-007 de la wiki explica los secretos por entorno

Las prácticas 01 a 04 dejan en verde los requisitos 1 a 13, el 15 y el 16. El 14, el 17 y el 18 son este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo antes el paso 0 de la práctica 01 (necesitas `$HR` y `fusionar`), y el bloque del token de `dev` del paso 4 de la práctica 02 (necesitas `$HD`):

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s10
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
```

### 1. Rotar `GOBERNANZA_TOKEN`

Es el único secreto que llega a las merge requests: el que más probabilidades tiene de filtrarse. Rótalo ahora, antes de que caduque, para que la primera rotación no sea con prisa.

```bash
TID=$(curl -s -H "$H" "$API/projects/$P/access_tokens" \
  | jq -r '.[] | select(.name == "gobernanza-ci" and .active) | .id')
[[ "$TID" =~ ^[0-9]+$ ]] || { echo "No hay un gobernanza-ci activo: NO sigas"; return 1 2>/dev/null || exit 1; }
curl -s --request POST "$API/projects/$P/access_tokens/$TID/rotate" -H "$H" \
  --data "expires_at=$(date -d '+180 days' +%F)" \
  | jq -j '.token // empty' \
  | curl -s --request PUT "$API/projects/$P/variables/GOBERNANZA_TOKEN" -H "$H" \
      --data-urlencode "value@-" \
  | jq '{key, masked, hidden, value}'

curl -s -H "$H" "$API/projects/$P/access_tokens" \
  | jq -r '.[] | select(.name == "gobernanza-ci") | "\(.id) active=\(.active) revoked=\(.revoked) \(.expires_at) \(.scopes | join(","))"'
```

**Verifica**: la variable sigue con `masked: true`, `hidden: true` y `value: null`; hay un `gobernanza-ci` activo con fecha nueva y `read_api`, y el anterior con `revoked=true`. Si el `PUT` falló, la variable tiene el token viejo, ya revocado: `gobernanza` fallará con `exit code 22` hasta que repitas la rotación del token nuevo (otro `rotate` sobre el activo).

La prueba de que funciona es el punto 2: su merge request no se fusiona si `gobernanza` no está en verde.

### 2. El inventario: `docs/secretos.md`

Una merge request desde un issue `tipo::mantenimiento`. Una fila por secreto del pipeline, con las columnas de la teoría 07:

| Secreto | Tipo | Ámbito | Protegido | Quién puede leerlo de verdad | De dónde sale y quién lo revoca | Caduca o se rota | Si se filtra |
|---|---|---|:--:|---|---|---|---|
| `GOBERNANZA_TOKEN` | Texto, oculto | `*` | ❌ | … | … | … | … |
| `DEPLOY_TOKEN` | Texto, oculto | `staging` | ✅ | … | … | … | … |
| `DEPLOY_TOKEN` | Texto, oculto | `production` | ✅ | … | … | … | … |
| `DEPLOY_SSH_KEY` | Archivo | `production` | ✅ | … | … | … | … |

Lo que se evalúa es la columna **"Quién puede leerlo de verdad"**. "Nadie" no es una respuesta: el job lo lee, quien puede cambiar el YAML de una ref que lo recibe lo lee, y en el caso de `GOBERNANZA_TOKEN`, cualquiera que abra una merge request. Escribe lo que viste en la práctica 04, no lo que dice la casilla.

Debajo de la tabla, tres cosas más:

1. **Lo que no es un secreto y está en el YAML a propósito**: las URL de los entornos, `GIT_LFS_SKIP_SMUDGE`.
2. **Lo que se descartó**: los *secure files* para claves, con la huella que viste descargar a `dev`.
3. **Cómo se rota cada uno**: para `GOBERNANZA_TOKEN`, el bloque del punto 1; para los demás, generar otro y `PUT .../variables/<key>?filter%5Benvironment_scope%5D=<entorno>` por una tubería.

Fusiónala con `fusionar`. Si `gobernanza` está en verde, el punto 1 funcionó.

### 3. El ADR-007, ampliado

En la wiki, la página del ADR-007 crece con una sección **"Reglas y secretos (Semana 10)"**. No es un ADR nuevo: es la misma decisión (cómo funciona el pipeline de `app`), con lo que esta semana añadió. Tiene que responder:

1. **Qué entra en cada pipeline**: el `workflow:rules` explicado línea a línea, y por qué `changes` solo en merge requests.
2. **Dónde va cada variable**: qué va al YAML, qué al proyecto, qué a la instancia, y por qué ninguna se repite.
3. **Secretos por entorno**: `protected` y `environment_scope`, qué decide cada uno, y la frase exacta "`environment_scope` no es una barrera de seguridad" con su porqué.
4. **El despliegue a `production`**: manual, desde `main`, y el hueco del sustituto de CE: quien puede fusionar en `main` puede desplegar solo.
5. **Los riesgos aceptados**, cada uno con su mitigación: `GOBERNANZA_TOKEN` sin proteger (y su rotación), y `CI_DEBUG_TRACE` al alcance de los Maintainers.
6. **Descartado**: al menos dos. Por ejemplo, *secure files* para la clave, `secrets:` con Vault (Premium), o `STAGING_TOKEN` y `PRODUCTION_TOKEN` por separado.

```bash
SLUG=$(curl -s -H "$H" "$API/projects/$P/wikis" | jq -r '.[] | select(.slug | test("^adr-007"; "i")) | .slug')
curl -s -H "$H" "$API/projects/$P/wikis/$SLUG" | jq -r .content > adr-007.md
# … añade la sección al final de adr-007.md …
curl -s --request PUT "$API/projects/$P/wikis/$SLUG" -H "$H" \
  --data-urlencode "content@adr-007.md" | jq -r .slug
rm adr-007.md
```

### 4. Revocar los tokens de `revisor` y `dev`

Cuando la merge request del punto 2 esté fusionada:

```bash
[[ "${UID_REV:-}" =~ ^[0-9]+$ ]] && [[ "${UID_DEV:-}" =~ ^[0-9]+$ ]] || { echo "Falta \$UID_REV o \$UID_DEV (source ~/.bc-gitlab-s10): NO sigas"; return 1 2>/dev/null || exit 1; }
HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
for u in "$UID_REV" "$UID_DEV"; do
  for id in $(curl -s -H "$HA" "$API/personal_access_tokens?user_id=$u" \
                | jq -r '.[] | select(.name == "flujo-s10" and .active) | .id'); do
    curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$HA" -o /dev/null -w "revocado $id: %{http_code}\n"
  done
done

[ -n "${HR:-}" ] && curl -s -o /dev/null -w 'revisor: %{http_code}\n' -H "$HR" "$API/user"     # 401
[ -n "${HD:-}" ] && curl -s -o /dev/null -w 'dev: %{http_code}\n' -H "$HD" "$API/user"         # 401
for u in "$UID_REV" "$UID_DEV"; do
  curl -s -H "$HA" "$API/personal_access_tokens?user_id=$u" | jq '[.[] | select(.name == "flujo-s10" and .active)] | length'
done                                                                       # 0 y 0
unset T_REV T_DEV HR HD HA
rm -f ~/.bc-gitlab-s10
```

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **El inventario dice quién puede leer cada secreto de verdad**, con lo que mostró la práctica 04, no con lo que promete la casilla.
- **El ADR-007 dice qué no protege `environment_scope`** y cuál es el hueco del despliegue manual.
- **Ningún secreto pasó por tu terminal**: ni `DEPLOY_TOKEN`, ni el token nuevo de `gobernanza`, ni la clave privada, que ya no está en tu disco.
- **La merge request de la fuga está cerrada sin fusionar** y su rama borrada.
- **Los tokens de `revisor` y `dev` están revocados**, comprobado en negativo.

---

## 💡 Adaptación a tu dominio

El pipeline es el mismo en los cuatro dominios. Lo que cambia es qué significaría el secreto de `production` si fuera real, y eso es lo que el inventario tiene que transmitir en la columna "Si se filtra".

| Dominio | Lo que abriría `DEPLOY_TOKEN` de `production` |
|---|---|
| 📖 Biblioteca | El catálogo público: alguien publica una versión que borra préstamos |
| 🏋️ Gimnasio | Las reservas de mañana: alguien despliega una versión que no admite ninguna |
| 🎥 Cine | La venta de entradas en un estreno |
| 💊 Farmacia | El registro de dispensaciones, sujeto a normativa |

El patrón: **la columna "Si se filtra" la tiene que poder leer alguien que no sabe qué es un token**. Si no entiende el daño, no entenderá la prisa por rotarlo.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu proyecto, de sus variables, de sus entornos y de su wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 10
```

```
18 de 18 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| El último pipeline de `main` es del punto 2 y `deploy-staging` falló | Requisito 15 | Lee su log: casi siempre `DEPLOY_TOKEN` borrada o con otro ámbito |
| `ORIGEN` de la práctica 02 sigue en el proyecto | Requisito 11: no está enmascarada | Bórrala: no es un secreto |
| `gobernanza` en rojo en la merge request del punto 2 con `exit code 22` | El `PUT` de la rotación falló | Otro `rotate` sobre el token activo, con la misma tubería |
| `adr-007-ampliado` en rojo con la sección escrita | La sección no menciona `environment_scope` literalmente | Es la palabra clave de esta semana: tiene que estar |
| Dos tokens `gobernanza-ci` activos | Requisito 14: creaste uno nuevo en vez de rotar | La variable oculta no dice cuál lleva: revoca los dos (`DELETE .../access_tokens/<id>`), crea uno como en el paso 1 de la práctica 04 de la Semana 09 con `PUT` en vez de `POST` a la variable, y rótalo |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 09](../../week-09-ci_cd_fundamentos/3-proyecto/README.md) | **Proyecto Semana 10** | [Proyecto Semana 11](../../week-11-pipelines_dag_y_multiproyecto/3-proyecto/README.md) |

[← Volver a la Semana 10](../README.md)
