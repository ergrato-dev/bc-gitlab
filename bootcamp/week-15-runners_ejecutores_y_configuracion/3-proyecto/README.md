# Proyecto — Semana 15: la flota de runners

> Hasta la Semana 14, un runner hacía de todo y nadie sabía qué podía tocar cada job. Desde esta, cada job cae en un runner elegido a propósito: los genéricos en `docker-app`, el que necesita Docker en `dind-app` y los despliegues en `deploy-infra`, que no acepta nada que no venga de una rama protegida. La caché ya no depende de qué runner te toque.

---

## 🎯 Objetivo

Dejar en pie la **capa 15** de tu plataforma: tres runners en un proceso, enrutados por etiquetas y protección, con la caché en `cache-s3`, la plantilla de su configuración en `infra/entornos`, y el ADR-012 que explica a quien llegue después por qué la flota es así y cuánto ganó la caché compartida.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| Las etiquetas `docker`, `dind` y `deploy` | S16 (el runner de Kubernetes entra en la flota con las mismas etiquetas y los pipelines no cambian) |
| La duración de cada job por runner, medida en el ADR-012 | S16 (la línea base de `docs/linea-base-s16.json` la vuelve a medir, tres pipelines por runner, y `docs/finops.md` la convierte en coste) |
| `deploy-infra`, `ref_protected` | S18 (el informe de endurecimiento audita quién puede llegar a la máquina de despliegue), S25 (el agente de Kubernetes sustituye al SSH, el runner protegido se queda) |
| `dind-app` con privilegio limitado | S19 (los escáneres de imágenes corren sin privilegios; `dind` sigue siendo la excepción documentada) |
| La caducidad de los tokens de runner | S18 (rotación de credenciales) |
| `runners/config.toml.plantilla` | S22 (reconstruir la flota tras un desastre es la plantilla más los tokens nuevos) |
| `cache-s3` | S21 (sus métricas y las del runner, en Prometheus) |

Lo que esta semana deja a medias, a propósito: la flota no crece con la cola. Tres runners fijos en una máquina tienen un techo, `concurrent = 3`. La Semana 16 añade un runner con ejecutor Kubernetes que crea un pod por job.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 15` contra la API de tu instancia.

1. app tiene en linea su runner de proyecto con la etiqueta docker
2. Los runners de proyecto de app los atiende un solo proceso gitlab-runner
3. Los runners de app corren la version fijada del runner, 19.2.2
4. app tiene en linea un runner de proyecto con la etiqueta dind
5. El runner dind de app no acepta jobs sin etiqueta
6. app ha ejecutado con exito el job probar-imagen en el runner dind
7. app no usa runners de instancia
8. El grupo infra tiene en linea un runner de grupo con la etiqueta deploy
9. El runner deploy solo ejecuta jobs de ramas y tags protegidos
10. El runner deploy corta cualquier job que pase de 30 minutos
11. infra/entornos ya no usa el runner docker-app
12. infra/entornos no usa runners de instancia
13. infra/entornos ha desplegado con exito desde el runner deploy
14. infra/entornos versiona la plantilla del config.toml con la cache en S3
15. La plantilla del config.toml no contiene ningun token de runner
16. La wiki de app tiene el ADR-012 sobre la flota de runners

Las prácticas 01 a 04 dejan en verde todos menos el 16. Ese es este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo antes el paso 0 de la práctica 01 y `source ~/.bc-gitlab-s15`.

### 1. Medir lo que ganó la caché compartida

Un ADR sin números es una opinión. Mide `build` de `app` con la caché en frío y con la caché caliente, los dos con `docker-app` contra `cache-s3`:

```bash
med() {   # lanza un pipeline de main y escribe la duración de build y de dónde salió la caché
  local PIPE J
  PIPE=$(curl -s --request POST "$API/projects/$P/pipeline" -H "$H" --data-urlencode "ref=main" | jq -r .id)
  esperar "$P" "$PIPE" > /dev/null
  J=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name == "build") | .id')
  printf '%s s · ' "$(curl -s -H "$H" "$API/projects/$P/jobs/$J" | jq -r '.duration | floor')"
  curl -s -H "$H" "$API/projects/$P/jobs/$J/trace" | sed 's/\x1b\[[0-9;]*[mK]//g' \
    | grep -oE 'Downloading cache from|Failed to extract cache|No URL provided' | head -1
}
jq -n --arg id "gid://gitlab/Project/$ID_APP" \
  '{query: "mutation($id: ProjectID!) { runnerCacheClear(input: {projectId: $id}) { errors } }", variables: {id: $id}}' \
  | curl -s --request POST "$GITLAB_URL/api/graphql" -H "$H" -H "Content-Type: application/json" -d @- > /dev/null
med    # en frío: Failed to extract cache
med    # caliente: Downloading cache from
med    # caliente otra vez, para tener dos medidas
```

Y lo que ha hecho cada runner en la semana, para el ADR:

```bash
for R in $RID_DOCKER $RID_DIND $RID_DEPLOY; do
  curl -s -H "$H" "$API/runners/$R/jobs?per_page=100" | jq -r --arg r "$R" \
    '"\($r): \(length) jobs, \([.[] | .duration // 0] | add | floor) s en total"'
done
```

### 2. El ADR-012

En la wiki de `app`, con el mismo formato que los anteriores (título, estado, contexto, decisión, consecuencias, alternativas descartadas):

```bash
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-012 La flota de runners" \
  --data-urlencode "content@docs/adr-012.md" | jq -r .slug
```

El ADR tiene que contar, con tus palabras y tus cifras:

- **Contexto**: un runner para todo, con caché local, y lo que podía tocar una rama cualquiera
- **Decisión**: un proceso con tres `[[runners]]`; qué etiqueta, alcance y `limit` tiene cada uno, y por qué el de despliegue es de grupo y protegido
- **`dind`**: por qué `probar-imagen` necesita un daemon y kaniko no, y por qué el privilegio está limitado al servicio
- **La caché**: `Shared = true` en `cache-s3`, la separación por protección que ves como `-protected`, y la tabla de duraciones del paso 1
- **Consecuencias**: `concurrent = 3` como techo, la plantilla en `infra/entornos`, la rotación de tokens
- **Alternativas descartadas**: tres contenedores `gitlab-runner`, el socket del host, MinIO

`docs/adr-012.md` es un archivo local de trabajo: la wiki es el entregable. No lo subas a `app` si no subiste los anteriores.

---

## 🎨 Criterios de calidad

Lo que la API no ve y la rúbrica sí:

- El ADR-012 explica la flota a alguien que no ha hecho esta semana: con leerlo sabe qué runner coge un job dado
- La tabla de duraciones tiene al menos una medida en frío y dos calientes, y dice qué línea del log lo demuestra
- `concurrent` y los `limit` del `config.toml` real coinciden con lo que dice el ADR, y el ADR justifica la cifra con la memoria de tu máquina
- La plantilla de `infra/entornos` reconstruye tu `config.toml` sin diferencias (práctica 04, paso 5)
- Ningún archivo fuera de `~/.bc-gitlab*` contiene un token `glrt-` ni la clave de `cache-s3`
- La prueba de la práctica 03, paso 6, se hizo y su rama está borrada

---

## 💡 Adaptación a tu dominio

| Dominio | Qué cambia en la flota |
|---|---|
| Biblioteca (el del ejemplo) | `probar-imagen` comprueba que `prestamos.ts` exporta `calcularMulta` |
| Clínica veterinaria | Lo mismo con el módulo de citas; si `app` guarda datos sensibles, el ADR explica por qué `deploy-infra` no comparte caché con ramas sin proteger |
| Tienda en línea | Un cuarto runner para pruebas de carga sería tentador: el ADR dice por qué no esta semana (`concurrent = 3`) |
| Gestión de incidencias | `deploy-infra` con `maximum_timeout` más corto si tus despliegues son de segundos: justifica la cifra |

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de `app`, de `infra/entornos`, del grupo `infra`, de sus runners y de la wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 15
```

```
16 de 16 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `una-gestora-para-app` en rojo | Dos `systemId` en la consulta de la práctica 02, paso 3 | `dind-app` está registrado en otro contenedor: bórralo y vuelve a registrarlo en `gitlab-runner` |
| `flota-en-version-fijada` en rojo | Un gestor con otra versión | Un proceso viejo tiene el token: rótalo (práctica 04, paso 3) |
| `imagen-probada-en-dind` en rojo con el job verde | El job corrió en `docker-app`: le falta `tags: [dind]` | Práctica 02, paso 5 |
| `infra-sin-runners-de-proyecto` en rojo | `docker-app` sigue asignado a `infra/entornos` | Práctica 03, paso 4 |
| `desplegar-en-runner-protegido` en rojo con `staging` desplegado | El último despliegue fue anterior al paso 3, o el job no pide `deploy` | Lanza otro pipeline de `main` de `app` |
| `plantilla-sin-secretos` en rojo | El `awk` de la práctica 04 no reconoció un bloque | Busca `glrt-` en la plantilla y sustitúyelo por su `${TOKEN_…}`; **rota ese token**: ya está en el historial |
| `adr-012-flota` en rojo con la página escrita | El slug no empieza por `ADR-012`, o falta `dind`, `protegid…` o `caché` | El título fija el slug: `ADR-012 …` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 14](../../week-14-entornos_review_apps_y_feature_flags/3-proyecto/README.md) | **Proyecto Semana 15** | [Proyecto Semana 16](../../week-16-runners_en_kubernetes_y_finops/3-proyecto/README.md) |

[← Volver a la Semana 15](../README.md)
