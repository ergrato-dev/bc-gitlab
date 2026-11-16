# Semana 14 — Entornos, review apps y feature flags

> Desde la Semana 10, `deploy-staging` y `deploy-production` demuestran que reciben sus secretos y no despliegan nada. Esta semana hay una máquina de verdad al otro lado: `infra/entornos` despliega en `staging` y en `production` con una clave por entorno, cada merge request de `app` levanta su propia copia viva y la borra al cerrarse, volver a la versión anterior es reintentar un job, y una función nueva llega a `main` apagada y se enciende sin desplegar. La documentación de `app` se publica en Pages, solo para sus miembros. Todo es Free.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Explicar qué registra GitLab de un despliegue, y por qué el SHA de un despliegue de `infra/entornos` no es el de `app`
- Desplegar por SSH en un destino que solo acepta lo que cada clave tiene permitido, con la huella del servidor fijada
- Mover las credenciales de los entornos de `app` a `infra/entornos` y sustituir los entornos protegidos (Premium) con lo que da CE
- Dar a cada merge request un entorno dinámico que se para solo al fusionarse y caduca si nadie lo para
- Deshacer un despliegue reintentando su job, y saber cuándo GitLab lo impide y cuándo no
- Separar desplegar de activar con un feature flag que cambia por entorno y por usuario sin tocar el pipeline
- Publicar un sitio en GitLab Pages que no lea cualquiera
- Medir la frecuencia de despliegue con despliegues, no con releases

---

## 📋 Prerrequisitos

- **Semana 13 completada**: `app` publica su paquete por SHA, `infra/entornos` lo descarga con `scripts/registrar.sh` y su último pipeline multiproyecto está en verde
- **Entornos `staging` y `production` en `app`** con `DEPLOY_TOKEN` por entorno y `DEPLOY_SSH_KEY` como archivo (Semana 10), y los `resource_group` de la Semana 11
- **`ci/deploy.yml` en `app`** con `infra`, que dispara `infra/entornos` con el input `entorno` (Semana 12)
- **`main` de `infra/entornos` protegida para Maintainer**: la protección por defecto con que nació en la Semana 11; la práctica 01 lo comprueba en el paso 0, y `revisor-<dominio>` con la aprobación que exige `gobernanza` en `app`
- **`docs/metricas.md` y `scripts/metricas.sh`** de la Semana 08, y el logo de `app` de la Semana 04
- **Perfil `base` levantado con el `docker-compose.yml` actual del repositorio**: trae el servicio `destino` y el control de acceso de Pages — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- **`jq`**, `ssh-keygen` en el host y clones locales de `app` e `infra/entornos` que firman commits

---

## 🗂️ Estructura de la Semana

```
week-14-entornos_review_apps_y_feature_flags/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 18 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 14 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — Entornos y despliegues](1-teoria/01-entornos-y-despliegues.md) | Qué es un entorno, qué guarda un despliegue, tiers, URL y el SHA que registra | 15 min |
| [02 — El destino](1-teoria/02-el-destino.md) | El servicio `destino`, SSH con comando forzado, la huella, el cambio atómico de versión | 15 min |
| [03 — Los secretos viven en `infra`](1-teoria/03-secretos-en-infra.md) | El corte entre `app` e `infra`, una clave por entorno, y qué sustituye a los entornos protegidos | 15 min |
| [04 — Review apps](1-teoria/04-review-apps.md) | Entornos dinámicos, el slug, `on_stop`, `auto_stop_in` y la limpieza | 15 min |
| [05 — El despliegue reversible](1-teoria/05-despliegue-reversible.md) | Rollback por reintento, despliegues obsoletos, resource groups y congelaciones | 15 min |
| [06 — Feature flags](1-teoria/06-feature-flags.md) | Desplegar no es activar, la API Unleash, estrategias por entorno y por usuario | 15 min |
| [07 — GitLab Pages](1-teoria/07-gitlab-pages.md) | El job `pages`, el dominio único, el control de acceso y lo que es Premium | 15 min |
| [08 — Medir despliegues](1-teoria/08-medir-despliegues.md) | La frecuencia de despliegue de verdad, la API de despliegues y lo que es Ultimate | 15 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — El destino y staging](2-practicas/01-el-destino-y-staging.md) | Levantas el destino, `app` aprende a responder por HTTP e `infra/entornos` despliega en `staging` | 50 min |
| [02 — Producción y rollback](2-practicas/02-produccion-y-rollback.md) | `app` suelta sus secretos, dispara `production` a mano, y `staging` vuelve atrás | 50 min |
| [03 — Review apps](2-practicas/03-review-apps.md) | Cada merge request de `app` tiene su copia viva, y desaparece al fusionarse | 50 min |
| [04 — El feature flag y Pages](2-practicas/04-feature-flag-y-pages.md) | Una función nueva apagada en `production`, encendida en `staging`, y la documentación en Pages | 50 min |

### Proyecto

La **capa 14** de tu plataforma: cada merge request tiene entorno vivo y cada despliegue se puede deshacer. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (8 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!IMPORTANT]
> Esta semana cambia el `docker-compose.yml`: hay un servicio nuevo, `destino`, y una línea nueva en la configuración de Pages. Actualiza tu clon del repositorio del bootcamp y vuelve a levantar el perfil `base` antes de la práctica 01. GitLab se reconfigura al arrancar: cuenta tres minutos.

---

## 🧭 Lo que entra esta semana y lo que espera

| Lo que quieres | Semana 14 | Después |
|---|---|---|
| Que solo ciertas personas desplieguen en `production` | `main` de `infra/entornos` protegida para Maintainer | Entornos protegidos y aprobaciones de despliegue: Premium |
| Desplegar la imagen del registry, no el paquete | El destino ejecuta el paquete con Node | La imagen en Kubernetes, con el agente (Semana 25) |
| Volver atrás solo cuando algo va mal | Rollback a mano, reintentando un job | Rollback automático por métricas (Semana 25) |
| Encender un flag para el 10 % de los usuarios | Por entorno y por lista de usuarios | Despliegue por porcentaje y canario (Semana 25) |
| Una review app por cada versión del sitio de Pages | Una review app de `app` por merge request | Despliegues paralelos de Pages: Premium |
| Saber qué versión de `app` corre en cada entorno sin abrir el destino | El nombre del pipeline de `infra/entornos` | Auditoría por API (Semana 17) |
| Las cuatro métricas DORA en un panel | `scripts/metricas.sh` | El panel de DORA de GitLab: Ultimate. Grafana (Semana 21) |

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Ver qué hay desplegado en cada entorno, sin GitLab | `curl -s localhost:8095/ \| jq` |
| Abrir un sitio `*.pages.localhost` con un `curl` antiguo | `curl --resolve <sitio>.pages.localhost:8090:127.0.0.1 http://<sitio>.pages.localhost:8090/` |
| Una clave SSH que solo sirve para una cosa | `command="…",restrict` delante de la clave en `authorized_keys` |
| Una variable de tipo archivo que ssh acepte | `chmod 600 "$DEPLOY_SSH_KEY"`: el runner la escribe con `0666` |
| Rollback sin buscar el botón | `POST /projects/:id/jobs/<job del despliegue viejo>/retry` |
| Saber qué estrategias ve un entorno | `GET /api/v4/feature_flags/unleash/<id>/client/features` con `UNLEASH-APPNAME: <entorno>` |
| Borrar de golpe las review apps viejas | `DELETE /projects/:id/environments/review_apps?before=<fecha>&dry_run=false`; sin `dry_run=false` solo simula, y sin `before` solo mira las de hace más de 30 días |
| Qué versión de `app` desplegó cada pipeline de `infra` | `GET …/pipelines?per_page=5`, campo `name`: el SHA del despliegue es el de `infra` |

---

## 📌 Entregables

1. El servicio `destino` con una clave por entorno limitada por comando forzado, y su huella en `infra/entornos`
2. `infra/entornos` desplegando de verdad en `staging`, con resource group por entorno y sus claves como archivo protegido
3. `app` sin credenciales de `staging` ni de `production`, disparando `production` a mano con `infra-production`
4. Un despliegue en `production`, y un rollback de `staging` a una versión anterior
5. Review apps en `app`, con su clave limitada a `review/*`, una desplegada y una parada al fusionar
6. `src/flags.ts` en `app` y el flag `multa-progresiva`, con estrategias distintas en `staging` y en `production`
7. La documentación de `app` en Pages, visible solo para sus miembros
8. `scripts/metricas.sh` contando despliegues de `production`, y el ADR-011 en la wiki de `app`

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 14
```

Las 18 comprobaciones tienen que pasar.

Lo que el script **no** puede comprobar es que el destino rechace de verdad lo que una clave no tiene permitido, que el flag se apague sin desplegar, ni que el ADR-011 explique a quien llegue después por qué `production` se despliega desde `infra/entornos`. Eso lo evalúa la rúbrica.

> [!NOTE]
> Desde esta semana, varias comprobaciones de las Semanas 10, 11 y 12 fallan **a propósito**: miraban en `app` los jobs `deploy-staging` y `deploy-production` y las variables `DEPLOY_TOKEN` y `DEPLOY_SSH_KEY`, y esas piezas se han mudado a `infra/entornos`. Cada una de esas semanas lo dice en su sección de verificación.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 13 — Registry de contenedores y paquetes](../week-13-registry_de_contenedores_y_paquetes/README.md) | **Semana 14** | [Semana 15 — Runners: ejecutores y configuración](../week-15-runners_ejecutores_y_configuracion/README.md) |

[← Volver al inicio del bootcamp](../README.md)
