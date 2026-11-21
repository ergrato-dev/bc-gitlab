# Proyecto Semana 13 — Los binarios viven en tu instancia

> Hasta la Semana 12, lo único que `app` dejaba al terminar un pipeline era un `.tgz` que caducaba en una semana. Desde esta, cada commit de `main` deja una imagen y un paquete con nombre y versión, una política decide cuándo sobran, y las imágenes de Docker Hub pasan por tu instancia. El proyecto lo junta en lo que ve alguien de fuera: la versión `v0.2.0`, con su imagen y su paquete protegidos, una release que enlaza a los dos, y el ADR que explica dónde vive cada binario y por qué.

---

## 🎯 Objetivo

Dejar en pie la **capa 13** de tu plataforma: el componente `imagen` publicado en `ci/componentes`; `app` subiendo su imagen y su paquete en cada commit de `main`, con limpieza y con el dependency proxy; `infra/entornos` descargando por SHA; la versión `v0.2.0` publicada; y el ADR-010 en la wiki de `app`.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| La imagen de `app` en el registry | S19 (Trivy la escanea), S20 (Cosign la firma por digest) |
| El componente `imagen` | S19 (un componente de escaneo la recibe por digest), S20 (añade firma y SBOM) |
| El paquete genérico por SHA | S14 (`infra/entornos` despliega lo que descarga), S20 (SBOM del `.tgz`) |
| La política de limpieza | S17 (la auditoría por API comprueba que todos los proyectos la tienen), S22 (cuánto ocupa el backup) |
| El dependency proxy | S16 (los jobs en Kubernetes descargan del mismo sitio), S19 (inventario de imágenes externas) |
| Los tags y paquetes protegidos | S20 (solo se firma lo que subió un Maintainer) |

Lo que esta semana deja a medias, a propósito: el `FROM` de kaniko sigue saliendo a Docker Hub, y los paquetes por SHA no caducan. El primero es la red del laboratorio; el segundo, la Semana 17.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 13` contra la API de tu instancia.

1. app tiene Dockerfile y .dockerignore en main
2. Solo Maintainer puede subir o borrar en app una imagen con etiqueta de version
3. componentes tiene el componente imagen
4. El ultimo pipeline de main en componentes esta en verde
5. Hay una version publicada de componentes que incluye el componente imagen
6. app consume el componente imagen por version, no por rama ni por ~latest
7. El registry de app tiene una imagen etiquetada con el SHA corto de un commit
8. app tiene activa una politica de limpieza que borra las imagenes por SHA y conserva las versiones
9. El dependency proxy del grupo esta activo y borra lo que no se usa
10. app descarga sus imagenes de Docker Hub a traves del dependency proxy
11. El grupo rechaza paquetes genericos duplicados salvo las versiones por SHA
12. infra/entornos descarga el paquete del registry de paquetes por su SHA
13. app publica su paquete generico con el SHA del commit como version
14. El disparo a infra/entornos ya no pasa el ID del job de package
15. El ultimo pipeline multiproyecto de infra/entornos esta en verde
16. La release v0.2.0 de app enlaza el paquete y la imagen de esa version
17. La wiki de app tiene el ADR-010 sobre el registry

Las prácticas 01 a 04 dejan en verde todos menos el 16 y el 17. Esos dos son este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo antes el paso 0 de la práctica 01 (necesitas `$HR`, `$HA`, `esperar` y `fusionar`):

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s13
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
```

### 1. El CHANGELOG de la 0.2.0

Como en la Semana 08 (práctica 03, pasos 1 y 2): un issue, una rama, el `POST` del changelog contra la rama, el commit firmado que sube `package.json` a `0.2.0`, y la merge request.

```bash
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Publicar v0.2.0" --data-urlencode "labels=tipo::mantenimiento" | jq -r .iid)
RAMA="$IID-changelog-0.2.0"
curl -s --request POST "$API/projects/$P/repository/branches" -H "$H" \
  --data-urlencode "branch=$RAMA" --data-urlencode "ref=main" | jq -r .name
curl -s --request POST "$API/projects/$P/repository/changelog" -H "$H" \
  --data-urlencode "version=0.2.0" --data-urlencode "from=v0.1.0" \
  --data-urlencode "branch=$RAMA" --data-urlencode "message=docs: changelog de la 0.2.0" \
  -o /dev/null -w '%{http_code}\n'

cd /ruta/a/tu/clon/de/app && git fetch && git switch "$RAMA"
npm pkg set version=0.2.0 && npm install --package-lock-only --no-audit --no-fund
git add package.json package-lock.json && git commit -S -m "chore: versión 0.2.0" && git push
MR=$(curl -s --request POST "$API/projects/$P/merge_requests" -H "$H" \
  --data-urlencode "source_branch=$RAMA" --data-urlencode "target_branch=main" \
  --data-urlencode "title=docs: changelog y versión 0.2.0" --data-urlencode "description=Closes #$IID" | jq -r .iid)
fusionar "$P" "$MR"
git switch main && git pull --ff-only
```

Esta merge request sí construye la imagen en el pipeline: cambia `package.json`, que está en las `rutas` del componente.

### 2. El tag, y lo que deja

```bash
git tag -s v0.2.0 -m "v0.2.0"
git tag -v v0.2.0
git push origin v0.2.0
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=v0.2.0&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"

RID=$(curl -s -H "$H" "$API/projects/$P/registry/repositories" | jq -r --arg p "$PROYECTO" '.[] | select(.path == $p) | .id')
DIGEST=$(curl -s -H "$H" "$API/projects/$P/registry/repositories/$RID/tags/0.2.0" | jq -r .digest)
echo "$DIGEST"
curl -s -H "$H" "$API/projects/$P/packages?package_type=generic&package_version=0.2.0" | jq -r '.[0].version'
```

`success`, un digest `sha256:…` y `0.2.0`: la imagen y el paquete de la versión. Los subió el pipeline de un tag que solo puede crear un Maintainer, la imagen está protegida y el paquete no admite una segunda subida.

### 3. La release, con sus enlaces

Las notas, como en la Semana 08, y dos enlaces: el paquete con URL estable bajo la release, y la imagen por digest (teoría 08, apartado 2.3).

```bash
NOTAS=$(curl -s -G -H "$H" "$API/projects/$P/repository/changelog" \
  --data-urlencode "version=0.2.0" --data-urlencode "from=v0.1.0" --data-urlencode "to=v0.2.0" | jq -r .notes)

curl -s --request POST "$API/projects/$P/releases" -H "$H" \
  --data-urlencode "tag_name=v0.2.0" --data-urlencode "name=v0.2.0" \
  --data-urlencode "description=$NOTAS" \
  --data-urlencode "assets[links][][name]=app.tgz" \
  --data-urlencode "assets[links][][url]=$API/projects/$P/packages/generic/app/0.2.0/app.tgz" \
  --data-urlencode "assets[links][][direct_asset_path]=/paquete/app.tgz" \
  --data-urlencode "assets[links][][link_type]=package" \
  --data-urlencode "assets[links][][name]=imagen localhost:5050/$PROYECTO@$DIGEST" \
  --data-urlencode "assets[links][][url]=$GITLAB_URL/$PROYECTO/container_registry/$RID" \
  --data-urlencode "assets[links][][link_type]=image" \
  | jq '{tag_name, enlaces: [.assets.links[] | {name, link_type, direct_asset_url}]}'
```

Comprueba la URL estable con tu token:

```bash
curl -s -o /dev/null -w '%{http_code} → %{redirect_url}\n' -H "$H" "$GITLAB_URL/$PROYECTO/-/releases/v0.2.0/downloads/paquete/app.tgz"
```

`302`, hacia el paquete `0.2.0`.

### 4. El ADR-010: dónde vive cada binario

Una página nueva de la wiki de `app`, **ADR-010**, con el formato de los anteriores. Tiene que responder:

1. **Qué va al registry, qué al registro de paquetes, qué se queda en artefactos y qué en la release**, con la tabla de `app`. La palabra `registry` aparece literalmente.
2. **Cómo se construye la imagen**: kaniko y no Docker-in-Docker, por qué el fork y no el original archivado, y qué haría cambiar la decisión (la Semana 15 trae un runner `dind`).
3. **La trampa del realm** y por qué el componente pide su propio token en lugar de cambiar `registry['token_realm']`.
4. **Los tags**: SHA corto en `main`, versión sin `v` en un tag, nada en merge requests, nunca `latest`. Y por qué la versión está protegida para Maintainer.
5. **La limpieza**: los valores de las dos políticas, por qué distintos, por qué la expresión de conservación además de los tags protegidos, y qué pasa con el disco. La palabra `limpieza` aparece literalmente.
6. **El paquete**: genérico y no npm, versión por SHA, la excepción de duplicados, y por qué eso permite quitar `APP_PACKAGE_JOB_ID`.
7. **Descartado**: al menos dos. Por ejemplo, Docker-in-Docker, Buildah, Docker Hub como registry, el registro npm, `latest`, duplicados permitidos, o los tags inmutables (Ultimate).

```bash
cat > adr-010.md <<'EOF'
# ADR-010 — Dónde viven los binarios
…
EOF
curl -s --request POST "$API/projects/$P/wikis" -H "$H" \
  --data-urlencode "title=ADR-010 Dónde viven los binarios" \
  --data-urlencode "content@adr-010.md" | jq -r .slug
rm adr-010.md
```

### 5. Recoger

Los tokens de esta semana se revocan y el archivo de identificadores se borra: lo que importa ya está en la instancia.

```bash
YO=$(curl -s -H "$H" "$API/user" | jq -r .id)
for U in "$UID_REV" "$YO"; do
  for id in $(curl -s -H "$HA" "$API/personal_access_tokens?user_id=$U" \
                | jq -r '.[] | select((.name == "flujo-s13" or .name == "registry-s13") and .active) | .id'); do
    curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$HA" -o /dev/null -w "revocado $id: %{http_code}\n"
  done
done
[ -n "${HR:-}" ] && curl -s -o /dev/null -w 'revisor: %{http_code}\n' -H "$HR" "$API/user"      # 401
unset T_REV HR HA T_REG
rm -f ~/.bc-gitlab-s13
```

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **La imagen no lleva nada que no necesite**: ni tests, ni `.git`, ni `assets/`. `docker run` de la imagen lista solo los módulos de `src/`.
- **El componente `imagen` no sabe que existe `app`**: ningún nombre de proyecto, ninguna ruta fija, y `registro` e `inseguro` con valores por defecto de producción.
- **`1.2.0` es una *minor***: quien seguía con `npm@1` y `gobernanza@1` no notó nada.
- **La release dice qué es `0.2.0` para siempre**: el paquete por su URL estable y la imagen por digest, no por tag.
- **El ADR-010 explica la trampa del realm** de forma que alguien que no la ha sufrido entienda por qué el componente pide su propio token.
- **Las dos políticas de limpieza son distintas por un motivo** que el ADR dice.

---

## 💡 Adaptación a tu dominio

Lo técnico es igual en los cuatro dominios. Lo que cambia es **cuánto tiempo hay que poder volver a una versión antigua**, y eso decide `keep_n`, `older_than` y si los paquetes por SHA se borran algún día.

| Dominio | Cuánto hay que poder volver atrás | En la política de `app` |
|---|---|---|
| 📖 Biblioteca | Hasta el siguiente despliegue: nadie audita una multa calculada hace un año | `keep_n: 10`, `older_than: 30d` |
| 🏋️ Gimnasio | Un ciclo de facturación, por si una cuota se calculó mal | `older_than: 60d` |
| 🎥 Cine | Lo que dure la cartelera: una sesión mal programada se reclama esa semana | `older_than: 14d` |
| 💊 Farmacia | Años: una dispensación tiene que poder reproducirse con la versión que la hizo | Las versiones, protegidas y fuera de la limpieza; los SHA, `older_than: 90d` |

El patrón: **la política de limpieza es una política de negocio escrita con expresiones regulares**. Si no sabes cuánto hay que conservar, pregúntalo antes de escribir `older_than`.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de `app`, de `ci/componentes`, de `infra/entornos`, del grupo, de sus registries y de la wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 13
```

```
17 de 17 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `release-enlaza-paquete` en rojo con la release creada | Falta `link_type` o `direct_asset_path` en un enlace | `PUT …/releases/v0.2.0/assets/links/<id>` con lo que falta |
| El pipeline de `v0.2.0` falla en `imagen` con `tag "0.2.0" is protected` | Lo lanzó alguien sin Maintainer en `app` | El tag de Git lo crea un Maintainer (Semana 07): quien lo creó no lo era, o tiene Maintainer solo heredado de otro sitio |
| `publicar-paquete` del tag falla con `Duplicate package is not allowed` | Ya hay un `0.2.0`: el pipeline del tag se relanzó, o subiste uno a mano | Si el contenido es el mismo, no hace falta nada; si no, es la `0.2.1` |
| `Url is blocked: Only allowed schemes are http, https, ftp` al crear la release | La URL de la imagen es `localhost:5050/…` | La página del repositorio de imágenes; la referencia, en el nombre |
| `adr-010-registry` en rojo con la página escrita | El slug no empieza por `ADR-010`, o falta `registry` o `limpieza` literal | El título fija el slug: `ADR-010 …` |
| `imagen-por-sha` en rojo tras unas semanas | La limpieza borró todos los SHA cortos: `keep_n` se aplica a los que cumplen la expresión | Con `keep_n: 10` siempre quedan diez; revisa que no lo bajaste a mano |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 12](../../week-12-componentes_ci_cd_y_catalogo/3-proyecto/README.md) | **Proyecto Semana 13** | [Proyecto Semana 14](../../week-14-entornos_review_apps_y_feature_flags/3-proyecto/README.md) |

[← Volver a la Semana 13](../README.md)
