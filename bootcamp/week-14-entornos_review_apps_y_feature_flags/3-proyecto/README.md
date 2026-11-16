# Proyecto Semana 14 — Cada merge request tiene entorno vivo y cada despliegue se deshace

> Hasta la Semana 13, `app` construía binarios que nadie ejecutaba. Desde esta, `infra/entornos` los despliega en una máquina que solo acepta lo que cada clave tiene permitido, cada merge request se ve funcionando antes de fusionarla, volver a ayer es un reintento, y una función nueva se enciende sin desplegar. El proyecto cierra la capa con lo que mide y lo que explica: `scripts/metricas.sh` cuenta despliegues, y el ADR-011 deja escrito por qué `production` se despliega desde `infra/entornos`.

---

## 🎯 Objetivo

Dejar en pie la **capa 14** de tu plataforma: el destino con una clave por entorno; `infra/entornos` desplegando en `staging` y en `production`, con resource groups y un rollback hecho; `app` sin credenciales de entornos, con review apps y el flag `multa-progresiva`; la documentación en Pages solo para miembros; la frecuencia de despliegue medida con despliegues; y el ADR-011 en la wiki de `app`.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| El servicio `destino` y sus claves con comando forzado | S18 (rotación de credenciales en el informe de endurecimiento), S22 (el destino entra en el backup) |
| `infra/entornos` desplegando, con su `DEPLOY_SSH_KEY` por entorno | S20 (Conftest bloquea en `infra/entornos` lo que no está firmado), S24 (`infra/terraform` a su lado), S25 (GitOps sustituye al SSH) |
| `infra-production` manual y la rama protegida de `infra/entornos` | S18 (quién es Maintainer de qué, auditado), S25 (despliegue por fases con rollback automático) |
| Las review apps | S19 (los escáneres dicen su veredicto en la misma merge request) |
| El flag `multa-progresiva` | S25 (porcentajes y canario) |
| Pages con control de acceso | S26 (el sitio de documentación de la plataforma) |
| La frecuencia de despliegue | S21 (la misma cifra en Grafana, junto a los SLO) |

Lo que esta semana deja a medias, a propósito: el destino ejecuta el paquete con Node y no la imagen del registry, y el rollback es manual. Las dos cosas cambian en la Semana 25, cuando el destino sea un clúster.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 14` contra la API de tu instancia.

1. infra/entornos tiene una clave SSH de despliegue por entorno, como archivo y protegida
2. infra/entornos conoce la huella del destino como variable de tipo archivo
3. infra/entornos serializa los despliegues con un resource group por entorno
4. infra/entornos ha desplegado con exito en staging
5. app ya no guarda las credenciales de staging ni de production
6. app dispara production a mano, como input de infra/entornos
7. infra/entornos ha desplegado con exito en production
8. staging ha vuelto con exito a una version anterior a la ultima que se desplego
9. app tiene una clave SSH propia para las review apps, limitada a review/*
10. app crea un entorno review/ por merge request, con su job de parada y caducidad
11. Una merge request de app ha desplegado su review app
12. Una review app de app se ha parado al cerrarse su merge request
13. app pregunta a GitLab por sus feature flags con el nombre del entorno
14. app tiene un feature flag activo con estrategias distintas segun el entorno
15. app publica su documentacion en GitLab Pages
16. El sitio de Pages de app solo lo ven sus miembros
17. scripts/metricas.sh cuenta los despliegues de production, no las releases
18. La wiki de app tiene el ADR-011 sobre entornos y despliegues

Las prácticas 01 a 04 dejan en verde todos menos el 17 y el 18. Esos dos son este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo antes el paso 0 de la práctica 01 (necesitas `$HR`, `$HA`, `$PI`, `esperar` y `fusionar`).

### 1. La frecuencia de despliegue

La Semana 08 dejó escrito que la frecuencia pasaría a contar despliegues. En una merge request desde un issue `tipo::mantenimiento`:

**`scripts/metricas.sh`**: debajo de la línea `bugs=$(api …)`, la consulta de despliegues de `infra/entornos` (teoría 08, apartado 2.3):

```bash
GRUPO_RAIZ=${CI_PROJECT_ROOT_NAMESPACE:-${PROYECTO%%/*}}
INFRA=$(printf '%s/infra/entornos' "$GRUPO_RAIZ" | jq -sRr @uri)
if [ -n "${CI_JOB_TOKEN:-}" ]; then CAB_INFRA="JOB-TOKEN: $CI_JOB_TOKEN"
else CAB_INFRA="PRIVATE-TOKEN: ${METRICAS_TOKEN:-$GITLAB_TOKEN}"; fi
despliegues=$(curl -sf -H "$CAB_INFRA" \
  "$API/projects/$INFRA/deployments?environment=production&status=success&updated_after=$DESDE&per_page=100") \
  || { echo "La API no respondió a los despliegues de infra/entornos" >&2; exit 1; }
```

Y el bloque `# 1. Frecuencia de entrega` entero (comentario y `jq`) se sustituye por:

```bash
# 1. Frecuencia de despliegue: despliegues con éxito en production en la ventana (Semana 14)
jq -r --argjson dias "$DIAS" '
  "Frecuencia de despliegue: \(length * 70 / $dias | round / 10) por semana (n = \(length))"' <<<"$despliegues"
```

`releases` se queda: la tasa de fallo sigue contando releases con parche.

**`docs/metricas.md`**: la definición de la primera métrica cambia, y eso se escribe. Una sección **"Frecuencia de despliegue (Semana 14)"** con qué cuenta ahora, por qué deja de contar releases, por qué un rollback cuenta, y la primera medición:

```bash
scripts/metricas.sh 30
```

Fusiona con `fusionar`, como siempre. El pipeline hijo de documentación de la Semana 11 revisa `docs/metricas.md`.

### 2. El ADR-011: entornos y despliegues

Una página nueva de la wiki de `app`, **ADR-011**, con el formato de los anteriores. Tiene que responder:

1. **Dónde vive cada credencial y por qué**: `DEPLOY_SSH_KEY` por entorno en `infra/entornos`, `REVIEW_SSH_KEY` sin proteger en `app`, y los dos cerrojos de cada una. Por qué `DEPLOY_TOKEN` desapareció.
2. **Quién despliega en `production`**: el job `trigger` manual, la rama protegida de `infra/entornos` y la prueba del `403` de `revisor`. Qué daría Premium (entornos protegidos, aprobaciones de despliegue) y por qué no hace falta todavía.
3. **El rollback**: cómo se hace, qué necesita un despliegue viejo para repetirse, y por qué la protección de despliegues obsoletos no actúa en `infra/entornos`. La palabra `rollback` aparece literalmente.
4. **El orden**: `oldest_first` en los dos resource groups de `infra/entornos`, y por qué no `newest_first` como en la Semana 11.
5. **Las review apps**: qué las para, cuánto viven, y qué pasaría si `REVIEW_SSH_KEY` se filtrara.
6. **El feature flag**: qué separa de qué, cómo lo lee `app`, dónde vive el identificador de instancia y cuándo se borra. La expresión `feature flag` aparece literalmente.
7. **Descartado**: al menos dos. Por ejemplo, ramas por entorno, una sola clave para todos, `StrictHostKeyChecking=no`, desplegar desde `app`, un SDK de Unleash, `newest_first` en `infra/entornos`, o Pages sin control de acceso.

```bash
cat > adr-011.md <<'EOF'
# ADR-011 — Entornos, despliegues y feature flags
…
EOF
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-011 Entornos, despliegues y feature flags" \
  --data-urlencode "content@adr-011.md" | jq -r .slug
rm adr-011.md
```

### 3. Recoger

El token de `revisor` se revoca, y el archivo de identificadores se borra. Las claves privadas también: GitLab y el destino ya tienen lo que necesitan, y rotar una clave es generar otra, no recuperar la vieja.

```bash
for id in $(curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
              | jq -r '.[] | select(.name == "flujo-s14" and .active) | .id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$HA" -o /dev/null -w "revocado $id: %{http_code}\n"
done
curl -s -o /dev/null -w 'revisor: %{http_code}\n' -H "$HR" "$API/user"      # 401
unset T_REV HR HA
rm -f ~/.bc-gitlab-s14 ~/.ssh/destino-staging ~/.ssh/destino-production ~/.ssh/destino-review
```

`~/.ssh/destino-*.pub` y `~/.ssh/destino-known-hosts` pueden quedarse: no son secretos.

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **El destino rechaza de verdad lo que no toca**: la clave de `staging` no para `production`, la de las review apps no toca `staging`, y ninguna abre una shell. Lo probaste en las prácticas 01 y 03.
- **Ningún `StrictHostKeyChecking=no`** en ningún job ni script.
- **El rollback se comprobó en el destino**, no solo en el color del job.
- **El flag se apagó sin pipeline**, y tiene un issue de limpieza enlazado en su descripción.
- **`docs/secretos.md` dice dónde vive cada clave hoy** y qué se borró, con fechas que `caducidades.sh` sabe leer.
- **El ADR-011 explica el `403` de `revisor`** a alguien que no conoce la regla de los jobs `trigger`.

---

## 💡 Adaptación a tu dominio

Lo técnico es igual en los cuatro dominios. Lo que cambia es **qué cuesta un error en `production`**, y eso decide quién pulsa `infra-production` y para quién se enciende primero un flag.

| Dominio | El flag de ejemplo | Primero, en `production`, para… |
|---|---|---|
| 📖 Biblioteca | `multa-progresiva` | Dos socios del personal, que saben que es una prueba |
| 🏋️ Gimnasio | `reserva-con-lista-de-espera` | Las clases de un solo monitor |
| 🎥 Cine | `butacas-numeradas` | Una sala, la de menos aforo |
| 💊 Farmacia | `aviso-de-caducidad` | Nadie: se prueba en `staging` con datos reales anonimizados, y en `production` se enciende para todos a la vez con un plan de vuelta atrás |

El patrón: **un flag reduce el riesgo de activar, no el de desplegar**. Si el código nuevo rompe al cargarse, el flag no lo salva: lo salva el rollback.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de `app`, de `infra/entornos`, de sus entornos, de sus variables, de Pages y de la wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 14
```

```
18 de 18 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `rollback-en-staging` en rojo con el rollback hecho | El reintento fue del último despliegue, no de uno anterior | Práctica 02, paso 6: `status=success` y el más reciente de esos |
| `review-parada` en rojo | Borraste los entornos parados con `dry_run=false` | Abre y cierra otra merge request: se crea y se para otra |
| `flag-por-entorno` en rojo con el flag creado | Lo dejaste apagado en el paso 4, o las dos estrategias tienen el mismo ámbito | `active=true`; una estrategia por ámbito |
| `metricas.sh` falla con `La API no respondió a los despliegues de infra/entornos` | `PROYECTO` no tiene la forma `grupo/app`, o el token no ve `infra/entornos` | `echo "$PROYECTO"`; prueba la URL con `curl` |
| `pages-publicado` en rojo tras fusionar | El job `pages` no corrió: la fusión no cambió nada de su `changes` | Lanza un pipeline de `main`, o cambia el README |
| `adr-011-entornos` en rojo con la página escrita | El slug no empieza por `ADR-011`, o falta `rollback` o `feature flag` literal | El título fija el slug: `ADR-011 …` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 13](../../week-13-registry_de_contenedores_y_paquetes/3-proyecto/README.md) | **Proyecto Semana 14** | Proyecto Semana 15 |

[← Volver a la Semana 14](../README.md)
