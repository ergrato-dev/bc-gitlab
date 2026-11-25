# Imágenes con Trivy

> Lo que se despliega no es tu repositorio: es una imagen. Y la imagen lleva dentro una distribución entera que no escribiste, con su libc, su zlib y, en las imágenes de Node, un `npm` con sus propias doscientas dependencias. Trivy abre las capas y cuenta lo que hay. La primera vez, en la imagen de `app` de la Semana 13, encuentra trece vulnerabilidades altas, y ninguna está en tu código.

---

## 🎯 Objetivos

- Distinguir los paquetes del sistema operativo de los del lenguaje dentro de una imagen, y saber cuál arregla quién
- Explicar por qué la imagen base es la decisión de seguridad más grande del `Dockerfile`
- Escanear en el pipeline **la misma** imagen que se sube, sin depender del registry
- Mantener la base de datos de Trivy en caché y entender por qué el resultado cambia sin cambiar la imagen

---

## 1. Qué problema resuelve

El `Dockerfile` de la Semana 13 empieza con `FROM node:22.23.3-alpine3.24`. Esa línea trae, sin que la escribas:

- Alpine 3.24.2 con 18 paquetes `apk`: `musl`, `zlib`, `libssl3`, `busybox`…
- El binario de Node.
- `npm`, `npx`, `corepack` y `yarn`, con sus dependencias en `/usr/local/lib/node_modules/`.

`app` solo necesita el binario de Node (la Semana 13 lo decidió: no hay `RUN npm` en la imagen final). Todo lo demás es superficie: código que nadie de tu equipo usa, que nadie actualiza y que un atacante dentro del contenedor sí puede usar.

---

## 2. Cómo funciona

### 2.1 Dos clases de paquetes

Trivy detecta la distribución (`Detected OS family="alpine" version="3.24.2"`), lee su base de paquetes instalados y busca en su base de datos. Después busca archivos de lenguajes: `package.json` dentro de `node_modules`, `requirements.txt`, binarios de Go…

Escaneo del 2026-11-24 de la imagen de `app` de la Semana 13, solo `HIGH` y `CRITICAL`:

| Origen | Paquete | Hallazgos | Quién lo arregla |
|---|---|:--:|---|
| Alpine | `musl`, `musl-utils` | CVE-2026-107891 | La imagen base: Alpine publica `musl` nuevo y Node reconstruye su imagen |
| Alpine | `zlib` | CVE-2026-85091 | Ídem |
| Node.js | `brace-expansion`, `ip-address`, `pacote`, `picomatch`, `sigstore` | 10 | Nadie en tu equipo: son dependencias de `npm`, que viene con la imagen |

Las de Alpine se arreglan **cambiando de base**: `node:22.23.4-alpine3.24` (publicada el 2026-11-05) ya trae Alpine 3.24.4 y ninguna de las tres. Las de Node.js no se arreglan subiendo de versión: siguen en `22.23.4` y en `22.23.5`, porque son del `npm` que la imagen incluye. Se arreglan **quitando** lo que sobra:

```dockerfile
FROM node:22.23.4-alpine3.24
# npm, npx, corepack y yarn no hacen falta para ejecutar app, y traen sus propias CVE.
RUN rm -rf /usr/local/lib/node_modules /opt/yarn-* /usr/local/bin/npm /usr/local/bin/npx \
           /usr/local/bin/corepack /usr/local/bin/yarn /usr/local/bin/yarnpkg
```

Con esas dos líneas, la imagen pasa de 13 hallazgos altos a cero. Quedan 7 `MEDIUM` y 4 `LOW` en `libssl3`, `libcrypto3` y `zlib`, todos con arreglo publicado en Alpine; bajo el umbral `alta` no paran el pipeline, y caen solos con la siguiente imagen base.

Una regla que sale de aquí: **lo que no está dentro no tiene CVE**. Una imagen *distroless* o `scratch`, sin shell ni gestor de paquetes, tiene casi nada que escanear. Es la Semana 20 la que cuenta lo que lleva una imagen (el SBOM); aquí basta con quitar lo que se ve.

### 2.2 La base cambia sin que cambies nada

Trivy usa su propia base de datos (`trivy-db`), que se publica varias veces al día como imagen OCI en `mirror.gcr.io/aquasec/trivy-db` y `ghcr.io/aquasecurity/trivy-db`. Consecuencias:

- **La misma imagen da hoy un resultado y mañana otro.** No es un fallo de reproducibilidad: es el motivo de escanear.
- La primera descarga son 143 MB comprimidos, que ocupan 1,8 GB en disco (medido el 2026-11-24). En el laboratorio, un job de Trivy sin caché tardó 151 s; con la base en caché, 33 s.
- La versión de Trivy y la de su base son independientes: fijar `0.76.2` no congela los datos.

### 2.3 El mismo artefacto

¿Qué imagen escanear? La respuesta tiene que ser **la que se sube**, no una parecida.

| Opción | Problema |
|---|---|
| Construir otra vez en el job de Trivy | Otra construcción, otra imagen: puede no ser idéntica |
| Descargar del registry | En una merge request `imagen` no sube nada (Semana 13: no se sube código sin revisar). Y desde el job, el registry pide token por el *realm* de la Semana 13 |
| **El tarball que deja `imagen`** | Ninguno: kaniko escribe la misma imagen que sube, también en MR |

El componente `imagen` gana un input `tar` (por defecto `false`, para no cambiar nada a quien ya lo usa): con `true`, kaniko añade `--tar-path imagen.tar` y el job deja el archivo como artefacto de una hora. En `main` la sube **y** la escribe; en una MR solo la escribe. Trivy lo lee con `trivy image --input imagen.tar`. El artefacto de `app` ocupa unos 60 MB, por debajo de los 100 MB por defecto de `max_artifacts_size`.

---

## 3. Cómo se configura

```yaml
trivy:
  extends: .componente-seguridad   # stage, needs y rules: práctica 02, paso 2
  needs:
    - job: imagen
      artifacts: true
  image:
    name: aquasec/trivy:0.76.2@sha256:8f6bb947dbc528902e11f2f5be52f7b519f6a39d5d148f41166f2040499768fb
    entrypoint: [""]
  variables:
    TRIVY_CACHE_DIR: .trivycache
    TRIVY_NO_PROGRESS: "true"
  cache:
    key: trivy-db
    when: always
    paths: [.trivycache/]
  script:
    - trivy image --input imagen.tar $IGNORAR --format json --output trivy.json
    - trivy convert --format sarif --output trivy.sarif trivy.json
    - trivy convert --format template --template @/contrib/junit.tpl --severity "$SEVERIDADES" --output trivy.junit.xml trivy.json
    - trivy convert --format table --severity "$SEVERIDADES" --exit-code 1 trivy.json
```

| Detalle | Por qué |
|---|---|
| Un escaneo, tres `convert` | `trivy convert` vuelve a pintar el JSON en otro formato sin escanear otra vez |
| `@/contrib/junit.tpl` | La plantilla JUnit viene dentro de la imagen, junto a `gitlab.tpl` y `gitlab-codequality.tpl` |
| `--severity` solo en JUnit y tabla | El SARIF lleva todo; el widget y el fallo, solo lo que llega al umbral |
| `cache: when: always` | Por defecto la caché solo se guarda si el job termina bien. El primer escaneo de una imagen vulnerable **falla**, y sin `when: always` el siguiente vuelve a descargar los 143 MB |
| `TRIVY_NO_PROGRESS` | Sin él, la barra de progreso de la descarga llena el log de líneas |

`.trivyignore.yaml`, si existe en la raíz del repositorio, se pasa con `--ignorefile` (teoría 07).

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `FROM node:22-alpine` "para tener siempre la última" | Cada pull es otra imagen; no sabes qué escaneaste ni qué desplegaste | Versión completa (y digest en producción), cambiada a propósito |
| Arreglar las CVE de Alpine con `RUN apk upgrade` | La imagen deja de ser reproducible: depende del día en que se construye | Cambiar de base cuando Node publica la nueva |
| Dejar `npm` en la imagen de ejecución | Diez CVE altas de un programa que `app` no usa | Quitarlo, o una base sin él |
| Escanear `:latest` del registry | No es la imagen del commit que se revisa | El tarball del mismo pipeline |
| Sin caché de la base de datos | 143 MB por job, y un pipeline que depende de que GHCR responda | `cache` con `when: always` |

---

## 5. Trucos

- `trivy image --input imagen.tar --format json | jq -r '.Results[].Vulnerabilities[]?.PkgPath' | sort -u` dice **dónde** está cada paquete vulnerable. Así se descubrió que las diez de Node.js estaban en `/usr/local/lib/node_modules/npm/`.
- `--ignore-unfixed` quita las vulnerabilidades sin arreglo publicado. Es una política, no un truco: decide que lo que nadie puede arreglar no para el pipeline. Si la adoptas, escríbelo en `docs/seguridad.md`.
- `trivy config .` escanea el `Dockerfile` en busca de malas prácticas (`USER root`, `ADD` desde URL). Es otra clase de escáner (configuración); no entra en el gate de esta semana.

---

## 📚 Recursos Adicionales

- [Trivy: vulnerability scanning](https://trivy.dev/docs/v0.76/guide/scanner/vulnerability/) — qué detecta en el sistema y en cada lenguaje
- [Trivy: report formats](https://trivy.dev/docs/v0.76/guide/configuration/reporting/) — `convert`, plantillas y SARIF
- [Container scanning de GitLab](https://docs.gitlab.com/user/application_security/container_scanning/) — la plantilla Free, con Trivy por dentro

---

## ✅ Checklist de Verificación

- [ ] Sabes qué hallazgos de una imagen arregla la imagen base y cuáles no
- [ ] Puedes explicar por qué el componente escanea el tarball y no el registry
- [ ] Sabes por qué la caché de Trivy lleva `when: always`
- [ ] Sabes por qué el mismo escaneo puede dar otro resultado mañana
