# Proyecto — Semana 19: nada se fusiona sin pasar cuatro escáneres

> Las prácticas dejaron la puerta cerrada: cuatro escáneres en cada merge request de `app`, sin `allow_failure`, y una fusión que la API rechaza con `405` mientras haya algo alto. Lo que no dejaron es qué hace el equipo con lo que la puerta **deja pasar**: los hallazgos medios de la imagen, que siguen en el SARIF de cada pipeline, y las excepciones, que caducan aunque nadie mire el calendario. Este proyecto lo pone por escrito en `docs/seguridad.md`, con tus hallazgos de verdad y una caducidad que has visto pasar.

---

## 🎯 Objetivo

Dejar en pie la **capa 19** de tu plataforma: el componente `seguridad` publicado en `1.3.0`, `app` detrás de él con la imagen corregida, una merge request envenenada que no llegó a `main`, los archivos de excepción con dueño, y `docs/seguridad.md` con el umbral, los plazos, el proceso de excepciones y la lista de lo que queda abierto, cada cosa con su issue y su fecha.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| El componente `seguridad` | S20 (Syft, Cosign y Conftest se añaden detrás de Trivy, sobre la misma imagen), S24 (la plataforma declarada en Terraform lo exige en cada proyecto nuevo), S26 (la auditoría final) |
| El input `tar` de `imagen` | S20 (el SBOM se genera del mismo tarball que escanea Trivy) |
| Los archivos de excepción con dueño | S20 (las políticas de Conftest siguen el mismo modelo: archivo versionado, dueño, fecha) |
| `docs/seguridad.md` | S20 (la política de qué se firma y qué se despliega), S21 (los plazos se miden con las fechas de los issues), S26 |

Lo que esta semana deja a medias, a propósito: el escaneo corre cuando hay un pipeline. Una CVE publicada mañana contra una imagen que nadie reconstruye no la ve nadie hasta el siguiente commit. Las `rules` del componente descartan los pipelines programados porque un escaneo nocturno necesita otra decisión (¿a quién avisa?, ¿qué bloquea?), y se toma en la Semana 21 con las alertas. Y saber exactamente qué lleva la imagen, firmado, es el SBOM de la Semana 20.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 19` contra la API de tu instancia.

1. componentes tiene el componente seguridad
2. Las cuatro imagenes del componente seguridad van fijadas por digest
3. El componente seguridad trae reglas de Semgrep propias y no descarga reglas del registro
4. El componente imagen puede dejar la imagen como artefacto para escanearla
5. El ultimo pipeline de main en componentes esta en verde
6. Hay una version publicada de componentes que incluye el componente seguridad
7. app usa el componente seguridad del catalogo por su version mayor
8. El pipeline de app tiene los cuatro escaneres en el stage seguridad y ninguno admite fallo
9. El ultimo pipeline de main en app esta en verde y paso los cuatro escaneres
10. El ultimo pipeline de main en app publica un informe JUnit por escaner
11. La imagen de app ya no parte de node 22.23.3 y no lleva npm dentro
12. app sigue sin permitir fusionar con el pipeline en rojo ni con el pipeline saltado
13. Cada uno de los cuatro escaneres ha hecho fallar al menos un job de app
14. app versiona .gitleaksignore y cada huella lleva encima un comentario con el motivo
15. CODEOWNERS de app asigna dueno a los tres archivos de excepciones
16. app versiona docs/seguridad.md con el umbral, los plazos y el proceso de excepciones

Las prácticas 01 a 04 dejan en verde los 15 primeros. El 16 es este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo el paso 0 de la práctica 01 (crea otro token de `revisor`: el de la práctica 04 está revocado) y pegando `esperar` y `fusionar`.

### 1. Lo que la puerta deja pasar

El umbral `alta` no hace desaparecer los `MEDIUM`: los deja en el SARIF de cada pipeline, 30 días. Sin un plazo y un responsable, se quedan para siempre (teoría 07, apartado 2.4). Saca la lista del último pipeline de `main`:

```bash
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
J=$(curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.name=="trivy") | .id')
curl -s -H "$H" "$API/projects/$P/jobs/$J/artifacts/trivy.sarif" > ~/bc-s19/trivy-main.sarif
jq -r '[.runs[].results[] | {id: .ruleId, nivel: .level, paquete: (.message.text | capture("Package: (?<p>[^\n]+)").p)}]
  | group_by(.id)[] | "\(.[0].nivel)\t\(.[0].id)\t\(map(.paquete) | join(", "))"' ~/bc-s19/trivy-main.sarif
```

En SARIF, `warning` es `MEDIUM` y `note` es `LOW`. Con la imagen de la práctica 03, unas cuatro CVE medias y dos bajas, casi todas de OpenSSL (`libcrypto3`, `libssl3`). Las cifras exactas dependen del día: la base de datos de Trivy cambia cada pocas horas.

Cada `MEDIUM` es un issue con fecha. La fecha es la de tu tabla de plazos, y `due_date` es Free:

```bash
jq -r '[.runs[].results[] | select(.level=="warning") | {id: .ruleId, paquete: (.message.text | capture("Package: (?<p>[^\n]+)").p)}]
  | group_by(.id)[] | "\(.[0].id)\t\(map(.paquete) | join(", "))"' ~/bc-s19/trivy-main.sarif \
| while IFS=$'\t' read -r CVE PAQ; do
    curl -s --request POST "$API/projects/$P/issues" -H "$H" \
      --data-urlencode "title=$CVE en la imagen de app ($PAQ)" \
      --data-urlencode "labels=tipo::mantenimiento,seguridad" \
      --data-urlencode "due_date=$(date -d '+30 days' +%F)" \
      --data-urlencode "description=MEDIUM según Trivy en el pipeline $PIPE de main. Plazo: docs/seguridad.md." \
    | jq -r '"#\(.iid)\t\(.due_date)\t\(.title)"'
  done
```

Haz lo mismo con el `osv.markdown` del job `osv-scanner`, si tiene filas. Con el lockfile de `app` a fecha de hoy, no tiene ninguna.

Mira la columna *Fixed Version* (`trivy image … --severity MEDIUM` en tu terminal, como en la práctica 01, paso 3): una CVE con arreglo se cierra con la siguiente base de `node`; una sin arreglo es la que algún día necesitará excepción. Apúntalo en cada issue.

### 2. Ensayar una caducidad

Una excepción con fecha solo sirve si, al caducar, el escáner vuelve a fallar. Compruébalo antes de que te pase en un pipeline de verdad, en un clon de usar y tirar:

```bash
rm -rf ~/bc-s19/caducidad && git clone -q /ruta/a/tu/clon/de/app ~/bc-s19/caducidad && cd ~/bc-s19/caducidad
npm install --save-exact lodash@4.17.20 --no-audit --no-fund
cat > osv-scanner.toml <<EOF
[[IgnoredVulns]]
id = "GHSA-35jh-r3h4-6jhm"
ignoreUntil = $(date -d '+7 days' +%F)T00:00:00Z
reason = "Ensayo: vigente una semana"

[[IgnoredVulns]]
id = "GHSA-r5fr-rjxr-66jc"
ignoreUntil = $(date -d yesterday +%F)T00:00:00Z
reason = "Ensayo: caducó ayer"
EOF
docker run --rm -v "$PWD:/src" -w /src "$I_OSV" scan source --lockfile package-lock.json
echo "salida: $?"
cd - && rm -rf ~/bc-s19/caducidad
```

Antes de ejecutarlo, escribe qué esperas. Después, compáralo con lo que salió: la vigente, `filtered out because: Ensayo: vigente una semana`; la caducada, en la tabla otra vez con su CVSS 8.1, y un aviso que dice que su línea del archivo ya no hace nada. `salida: 1`: el pipeline volvería a estar rojo el día después de la fecha. Ese aviso es el que verás en el log del job cuando caduque una excepción real.

### 3. `docs/seguridad.md`

En `app`, por merge request. Es el documento que lee quien tiene que decidir sobre el siguiente hallazgo, y quien revisa una excepción para saber si la aprueba. Tiene que contar, con tus cifras:

- **`## Umbral`**: qué bloquea cada uno de los cuatro escáneres, con el umbral del componente que usa `app` (y su traducción a CVSS para OSV-Scanner); quién aprueba cambiarlo
- **`## Plazos`**: un plazo por gravedad (crítica, alta, media, baja), y qué se hace cuando no se puede cumplir. Las cifras las decides tú; la teoría 07 propone unas
- **`## Excepciones`**: el orden con un secreto (rotar primero), dónde va cada tipo de excepción y con qué campos (`ignoreUntil` y `reason`, `expired_at` y `statement`, el comentario encima de la huella, `nosemgrep` con motivo), quién las aprueba y cómo se renuevan
- **`## Hallazgos abiertos`**: la tabla del paso 1, con CVE, paquete, gravedad, issue y fecha límite
- **`## Ensayo de caducidad`**: qué esperabas, qué pasó y qué aviso deja el escáner en el log

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
git switch -c "$IID_S19-politica-de-seguridad"
mkdir -p docs && "${EDITOR:-nano}" docs/seguridad.md
git add docs/seguridad.md && git commit -S -m "docs: umbral, plazos y excepciones de seguridad"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="docs: política de seguridad del pipeline" \
  -o merge_request.description="Refs #$IID_S19"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
curl -s --request DELETE "$API/personal_access_tokens/self" -H "$HR" -w '%{http_code}\n'
```

`204`: el token de `revisor` de esta semana, revocado.

Un cambio en `docs/` no toca ninguna de las rutas de `imagen`: en esta merge request corren Semgrep, Gitleaks y OSV-Scanner, y Trivy no.

---

## 🎨 Criterios de calidad

Lo que la API no ve y la rúbrica sí:

- Las reglas de Semgrep del componente tienen prueba en `tests/seguridad/reglas.ts` con al menos un `ruleid` y un `ok` cada una, y el `message` de cada regla dice qué pasa, por qué importa y su CWE
- La contraseña de la práctica 04 se trató como quemada: el comentario de `.gitleaksignore` dice por qué no había nada que rotar
- Ningún job del componente ni de `app` lleva `allow_failure`, y ninguna imagen de los escáneres va por etiqueta sin digest. La base de `app` va por etiqueta exacta; su digest, firmado, es la Semana 20
- `docs/seguridad.md` tiene plazos que tus excepciones cumplen, y cada fila de *Hallazgos abiertos* tiene su issue con `due_date`
- El ensayo de caducidad tiene lo que pasó, no lo que debería pasar
- `docs/seguridad.md` se entiende sin haber hecho esta semana

---

## 💡 Adaptación a tu dominio

| Dominio | Qué cambia |
|---|---|
| Biblioteca (el del ejemplo) | La fórmula de multa es la tentación del `eval`. La regla `eval-con-datos` es la que más falta hace |
| Clínica veterinaria | Datos de clientes: el umbral se queda en `alta`, pero el plazo de una `MEDIUM` en una librería que toca historiales se acorta a 7 días. La tabla de plazos puede tener una fila por tipo de dato |
| Tienda en línea | Pagos: una cuarta regla de Semgrep que encuentre el número de tarjeta en un `console.log` (`console.log(..., $X.tarjeta, ...)`) se gana su sitio el primer día |
| Gestión de incidencias | Las incidencias llevan adjuntos de clientes: una regla para `exec` con nombres de archivo subidos, y el plazo de `comando-con-shell` sin excepción posible |

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu instancia**: `ci/componentes` con `seguridad` en `1.3.0`, y `app` con sus pipelines, su `CODEOWNERS`, su `.gitleaksignore`, sus issues y `docs/seguridad.md`.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 19
```

```
16 de 16 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `politica-de-seguridad` en rojo con el documento escrito | Faltan los títulos `## Umbral`, `## Plazos` o `## Excepciones` tal cual, o no está en `main` | Los tres títulos de segundo nivel, y la fusión |
| `main-escaneada` en rojo tras el proyecto | El último pipeline de `main` es el de `docs/`, y Trivy no corrió en él | En `main`, Trivy corre siempre: mira si `imagen` falló en ese pipeline |
| `los-cuatro-han-parado-algo` en rojo | Uno de los escáneres no ha fallado nunca en `app` | Práctica 04, pasos 2 y 3: los tres a la vez |
| `excepcion-con-motivo` en rojo | Hay una línea en blanco entre el comentario y la huella | El comentario justo encima |
| El paso 1 no lista nada | El último pipeline de `main` no tiene job `trivy` (pipeline de una etiqueta, o de un `schedule`) | `source=push` en la consulta, como está |
| `date: invalid date '+30 days'` | `date` de macOS | `date -v+30d +%F` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 18](../../week-18-administracion_hardening_y_actualizaciones/3-proyecto/README.md) | **Proyecto Semana 19** | Proyecto Semana 20 |

[← Volver a la Semana 19](../README.md)
