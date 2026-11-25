# Práctica 01 — Las reglas y los escáneres

> Antes de meter un escáner en un pipeline, se ejecuta a mano. Así sabes qué encuentra, cuánto tarda, qué código de salida devuelve y qué escribe, sin esperar a un job ni pelearte con su YAML. Pasas los cuatro por `app` desde tu terminal, con las mismas imágenes y los mismos digests que usará el componente, y escribes las tres reglas de Semgrep de la plataforma con sus pruebas.

**Duración estimada**: 50 min
**Prerrequisitos**: Semana 18 completada (`~/.bc-gitlab-s18`) · Docker en tu máquina · Teoría [01](../1-teoria/01-el-pipeline-como-superficie.md) a [05](../1-teoria/05-imagenes-con-trivy.md) leídas

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 0 | Variables, el token de `revisor` y las cuatro imágenes | — |
| 1 | Gitleaks sobre el historial de `app` | — |
| 2 | OSV-Scanner sobre el lockfile de `app` | — |
| 3 | Trivy sobre la imagen de `app` | — |
| 4 | Semgrep con las reglas del registro | — |
| 5 | Las tres reglas propias y sus pruebas | `reglas-propias` (en la práctica 02) |
| 6 | Las reglas contra `app` | — |

Esta práctica no cambia nada en tu instancia: el entregable empieza en la 02. Lo que sí deja es una rama local en `ci/componentes` y la lista de lo que cada escáner encuentra hoy en `app`, que necesitas en la 03.

---

## Paso 0: Preparar el terreno

**Por qué**: las variables de siempre, las rutas de `app` (`P`) y `ci/componentes` (`PC`), y un token de `revisor` para aprobar las merge requests de las prácticas 02 a 04, como en la Semana 13. Y las cuatro imágenes en variables, con el digest: si el escáner de tu terminal no es exactamente el del job, sus resultados no se pueden comparar.

```bash
source ~/.bc-gitlab
source ~/.bc-gitlab-s18
export H="PRIVATE-TOKEN: $GITLAB_TOKEN"
export API="$GITLAB_URL/api/v4"
export P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)
export PC=$(printf '%s' "$G/ci/componentes" | jq -sRr @uri)
export REV=revisor-<tu-dominio>
export UID_REV=$(curl -s -H "$H" "$API/users?username=$REV" | jq -r '.[0].id // empty')
[[ "$UID_REV" =~ ^[0-9]+$ ]] || { echo "Falta $REV: NO sigas"; return 1 2>/dev/null || exit 1; }
# Si repites este paso, el token flujo-s19 anterior se revoca antes de crear otro: no quedan dos vivos.
for ID in $(curl -s -H "$H" "$API/personal_access_tokens?user_id=$UID_REV&state=active&search=flujo-s19" | jq -r '.[].id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$ID" -H "$H" -o /dev/null
done
T_REV=$(curl -s --request POST "$API/users/$UID_REV/personal_access_tokens" -H "$H" \
  --data-urlencode "name=flujo-s19" --data-urlencode "scopes[]=api" \
  --data-urlencode "expires_at=$(date -d '+7 days' +%F)" | jq -r '.token')
[ -n "$T_REV" ] && [ "$T_REV" != null ] || { echo "No se creó el token: revisa el scope admin_mode y NO sigas"; return 1 2>/dev/null || exit 1; }
export HR="PRIVATE-TOKEN: $T_REV"

cat > ~/.bc-gitlab-s19 <<EOF
export G=$G P=$P PC=$PC REV=$REV UID_REV=$UID_REV
export I_SEMGREP=semgrep/semgrep:1.185.0@sha256:67518c174185a2043fdbed16c70631b79209499b3671178e7194379b48295a0d
export I_GITLEAKS=zricethezav/gitleaks:v8.30.0@sha256:691af3c7c5a48b16f187ce3446d5f194838f91238f27270ed36eef6359a574d9
export I_OSV=ghcr.io/google/osv-scanner:v2.7.0@sha256:4f3b7e2c64b9d38a5febc5a7e4a3dfef1d1362f726dea7a2ef4762b46469fcd0
export I_TRIVY=aquasec/trivy:0.76.2@sha256:8f6bb947dbc528902e11f2f5be52f7b519f6a39d5d148f41166f2040499768fb
EOF
chmod 600 ~/.bc-gitlab-s19
source ~/.bc-gitlab-s19
mkdir -p ~/bc-s19/trivy-cache && chmod 700 ~/bc-s19
for i in "$I_SEMGREP" "$I_GITLEAKS" "$I_OSV" "$I_TRIVY"; do docker pull -q "$i"; done
```

Copia `esperar` y `fusionar` del [paso 0 de la práctica 01 de la Semana 13](../../week-13-registry_de_contenedores_y_paquetes/2-practicas/01-el-registry-y-el-dockerfile.md#paso-0-preparar-el-terreno). `T_REV` y `HR` no se guardan en ningún archivo: si cierras la terminal, repite este bloque (crea otro token de siete días) y vuelve a pegar las dos funciones.

**Verifica**:

```bash
curl -s -H "$HR" "$API/user" | jq -r .username       # revisor-<tu-dominio>
type esperar fusionar | grep -c function            # 2
docker image ls --digests --format '{{.Repository}} {{.Digest}}' | grep -cE 'semgrep|gitleaks|osv-scanner|trivy'
```

`4` en la última línea, una por imagen. Si `docker pull` respondió `manifest unknown`, el digest está mal copiado.

---

## Paso 1: Los secretos del historial

**Por qué**: Gitleaks lee **commits** (teoría 03). Tu clon tiene el historial completo de `app`, así que lo que encuentre aquí es lo que encontrará el pipeline con `GIT_DEPTH: "0"`.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
git rev-list --all --count
docker run --rm -v "$PWD:/repo" -w /repo "$I_GITLEAKS" git --redact --no-banner .
echo "salida: $?"
```

**Verifica**: `N commits scanned.`, con N igual al número de la línea anterior (Gitleaks lee **todas** las ramas que tiene el clon, no solo `main`), `no leaks found` y `salida: 0`.

Si sale `leaks found`, **no es un fallo de la práctica**: hay algo en tu historial. Ejecuta la misma línea con `--report-format json --report-path /repo/gitleaks.json`, mira `RuleID`, `File` y `Commit` en `gitleaks.json`, y sigue el orden de la teoría 03: si es una credencial real, rótala hoy. La huella va a `.gitleaksignore` en la práctica 04. Borra `gitleaks.json` antes de seguir: no se versiona.

---

## Paso 2: Las dependencias del lockfile

**Por qué**: OSV-Scanner pregunta a `api.osv.dev` por cada paquete de `package-lock.json` (teoría 04). `app` solo tiene `typescript` y `@types/node` como dependencias de desarrollo, desde la Semana 09.

```bash
docker run --rm -v "$PWD:/src" -w /src "$I_OSV" scan source --lockfile package-lock.json
echo "salida: $?"
jq '.packages | length' package-lock.json
```

**Verifica**: `No issues found` y `salida: 0`. La última cifra es cuántos paquetes ha mirado (la raíz cuenta como uno).

El lockfile no se escanea solo cuando cambia: una CVE publicada mañana en `@types/node` haría fallar este mismo comando sin que toques nada. Es lo que la teoría 04 llama "vulnerable sin commit".

---

## Paso 3: La imagen que ya despliegas

**Por qué**: Trivy necesita la imagen, no el repositorio. La construyes desde el `Dockerfile` de `main`, el mismo que usa `imagen@1` (Semana 13), y la guardas como tarball: es lo que el componente le dará a Trivy en el pipeline (teoría 05, apartado 2.3).

```bash
docker build -q -t app-s19 .
docker save app-s19 -o ~/bc-s19/app.tar
docker run --rm -v ~/bc-s19:/w -w /w -v ~/bc-s19/trivy-cache:/cache "$I_TRIVY" \
  image --input app.tar --cache-dir /cache --severity HIGH,CRITICAL --format json --output trivy.json
jq -r '.Results[] | .Target as $t | .Vulnerabilities[]? | "\(.Severity)\t\(.PkgName)\t\(.VulnerabilityID)\t\($t)"' ~/bc-s19/trivy.json
```

La primera vez tarda uno o dos minutos: descarga la base de datos (143 MB comprimidos). La caché queda en `~/bc-s19/trivy-cache`.

**Verifica**: una lista de hallazgos `HIGH`. A fecha de este material, trece: `musl`, `musl-utils` y `zlib` en `app.tar (alpine 3.24.2)`, y diez en `Node.js` (`brace-expansion`, `ip-address`, `pacote`, `picomatch`, `sigstore`). El número exacto depende de la base del día; las de Alpine 3.24.2 no se van a ir.

Ahora, **dónde** están:

```bash
jq -r '[.Results[].Vulnerabilities[]?.PkgPath // "(paquete del sistema)"] | unique[]' ~/bc-s19/trivy.json
```

**Verifica**: las de Node.js, todas bajo `usr/local/lib/node_modules/npm/`. Ninguna es de `app`: son del `npm` que trae la imagen base. Apúntalo: la práctica 03 lo arregla.

---

## Paso 4: Semgrep con las reglas del registro

**Por qué**: antes de escribir reglas propias, lo que da el registro de Semgrep (teoría 02, apartado 2.3). Con un archivo fuera del repositorio que tiene un `eval` con datos de fuera.

```bash
PRUEBA=$(mktemp -d)
cat > "$PRUEBA/formula.ts" <<'EOF'
export function evaluar(expresion: string): unknown {
  return eval(expresion);
}
EOF
time docker run --rm -v "$PRUEBA:/src" -w /src "$I_SEMGREP" \
  semgrep scan --config p/javascript --config p/typescript --metrics=off --error formula.ts
echo "salida: $?"
```

**Verifica**: `Ran 74 rules on 1 file: 0 findings.` (o una cifra de reglas parecida) y `salida: 0`. El registro no ha encontrado el `eval`. El tiempo depende de tu red: las reglas se descargan en cada ejecución (en el laboratorio, entre 4 y 80 segundos). Y prueba la otra opción del registro:

```bash
docker run --rm -v "$PRUEBA:/src" -w /src "$I_SEMGREP" semgrep scan --config auto --metrics=off formula.ts
```

**Verifica**: `Cannot create auto config when metrics are off.` `--config auto` exige enviar telemetría, y la telemetría está prohibida en este laboratorio.

---

## Paso 5: Las tres reglas de la plataforma

**Por qué**: las reglas son de la plataforma, así que viven en `ci/componentes`, en el componente que escribes en la práctica 02. Ahora las escribes como archivo suelto para probarlas: `semgrep --test` necesita `reglas.yaml` y, al lado, `reglas.ts` con el código anotado (teoría 02, apartado 2.4). Las pruebas sí se versionan; el archivo de reglas no, porque en la práctica 02 su contenido pasa dentro del componente y el pipeline lo regenera desde ahí.

```bash
cd /ruta/a/tus/clones/componentes && git switch main && git pull --ff-only
IIDC=$(curl -s --request POST "$API/projects/$PC/issues" -H "$H" \
  --data-urlencode "title=Componente seguridad: Semgrep, Gitleaks, OSV-Scanner y Trivy" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=Cuarto componente. Los cuatro escáneres con imagen por digest, umbral como input e informes JUnit y SARIF. Ver Semana 19." \
  | jq -r .iid)
echo "export IIDC=$IIDC" >> ~/.bc-gitlab-s19
git switch -c "$IIDC-componente-seguridad"
mkdir -p tests/seguridad
printf '# Se genera desde templates/seguridad.yml en el pipeline. Ver Semana 19.\ntests/seguridad/reglas.yaml\n' >> .gitignore

cat > tests/seguridad/reglas.yaml <<'EOF'
rules:
  - id: eval-con-datos
    languages: [typescript, javascript]
    severity: ERROR
    message: eval ejecuta como código lo que recibe. Con datos de fuera, es ejecución remota (CWE-95)
    patterns:
      - pattern-either:
          - pattern: eval($X)
          - pattern: new Function(...)
      - pattern-not: eval("...")
  - id: comando-con-shell
    languages: [typescript, javascript]
    severity: ERROR
    message: exec y execSync pasan la cadena a una shell. Con datos de fuera, es inyección de comandos (CWE-78). Usa execFile con argumentos
    patterns:
      - pattern-either:
          - pattern: $CP.exec($CMD, ...)
          - pattern: $CP.execSync($CMD, ...)
          - pattern: exec($CMD, ...)
          - pattern: execSync($CMD, ...)
      - pattern-not: $CP.exec("...", ...)
      - pattern-not: $CP.execSync("...", ...)
      - pattern-not: exec("...", ...)
      - pattern-not: execSync("...", ...)
  - id: tls-sin-verificar
    languages: [typescript, javascript]
    severity: ERROR
    message: Desactivar la verificación TLS acepta cualquier certificado, también el de un atacante en medio (CWE-295)
    pattern-either:
      - pattern: "{..., rejectUnauthorized: false, ...}"
      - pattern: process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
EOF

cat > tests/seguridad/reglas.ts <<'EOF'
// Pruebas de las reglas de Semgrep del componente seguridad: semgrep --test tests/seguridad
import * as child_process from "node:child_process";
import { exec } from "node:child_process";
import * as https from "node:https";

declare const entrada: string;
declare const dir: string;
declare const url: string;

// ruleid: eval-con-datos
eval(entrada);
// ok: eval-con-datos
eval("2 + 2");
// ruleid: eval-con-datos
new Function("a", entrada);

// ruleid: comando-con-shell
child_process.exec(`ls ${dir}`);
// ruleid: comando-con-shell
exec("ls " + dir);
// ok: comando-con-shell
child_process.exec("ls");
// ok: comando-con-shell
child_process.execFile("ls", [dir]);

// ruleid: tls-sin-verificar
https.get(url, { rejectUnauthorized: false });
// ok: tls-sin-verificar
https.get(url, { rejectUnauthorized: true });
// ruleid: tls-sin-verificar
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
EOF

docker run --rm -v "$PWD:/src" -w /src "$I_SEMGREP" semgrep --validate --metrics=off --config tests/seguridad/reglas.yaml
docker run --rm -v "$PWD:/src" -w /src "$I_SEMGREP" semgrep --test --metrics=off tests/seguridad
```

**Verifica**: `Configuration is valid - found 0 configuration error(s), and 3 rule(s).` y `3/3: ✓ All tests passed`. Si una regla falla, Semgrep dice qué línea anotada no se cumplió (`missed lines` o `incorrect lines`). Prueba a romperla: quita el `pattern-not` de `eval-con-datos`, repite `--test`, y verás `eval("2 + 2")` como línea incorrecta. Déjalo como estaba.

---

## Paso 6: Las reglas contra `app`

**Por qué**: una regla nueva se estrena contra el código que va a vigilar. Si da hallazgos el primer día, o son reales (arréglalos antes de la práctica 03) o la regla está mal.

```bash
cd /ruta/a/tu/clon/de/app
time docker run --rm -v "$PWD:/src" -w /src \
  -v /ruta/a/tus/clones/componentes/tests/seguridad/reglas.yaml:/plataforma/semgrep.yml:ro "$I_SEMGREP" \
  semgrep scan --config /plataforma/semgrep.yml --metrics=off --error
echo "salida: $?"
docker run --rm -v "$PRUEBA:/src" -w /src \
  -v /ruta/a/tus/clones/componentes/tests/seguridad/reglas.yaml:/plataforma/semgrep.yml:ro "$I_SEMGREP" \
  semgrep scan --config /plataforma/semgrep.yml --metrics=off --error -q formula.ts
echo "salida: $?"
rm -rf "$PRUEBA"
```

**Verifica**: contra `app`, `Ran 3 rules on N files: 0 findings.`, `salida: 0`, en unos segundos. Contra `formula.ts`, el hallazgo `plataforma.eval-con-datos` en la línea 2 y `salida: 1`. Tres reglas que encuentran lo que 74 no, sin salir a internet.

Deja la rama de `ci/componentes` como está, sin commit: la práctica 02 sigue en ella.

```bash
cd /ruta/a/tus/clones/componentes && git status --short
```

**Verifica**: `.gitignore` (modificado, o nuevo si `ci/componentes` no tenía) y `tests/seguridad/` sin seguimiento. `tests/seguridad/reglas.yaml` **no** aparece: ya lo ignora el `.gitignore`.

---

## ✅ Resultado

- [ ] `~/.bc-gitlab-s19` con las cuatro imágenes por digest, en `chmod 600`
- [ ] Gitleaks, OSV-Scanner y Trivy ejecutados sobre `app`, y sabes qué encuentra cada uno hoy
- [ ] Las diez CVE de Node.js localizadas en el `npm` de la imagen base
- [ ] Comprobado que el registro de Semgrep no encuentra el `eval` y que `--config auto` exige telemetría
- [ ] `tests/seguridad/reglas.ts` con sus pruebas pasando, en una rama de `ci/componentes`

Esta práctica no tiene comprobaciones propias. La primera llega con la práctica 02:

```bash
./scripts/verificar-semana.sh 19
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `Detected Docker environment without a code volume` | Semgrep dentro de su imagen sin código en `/src` | El `-v "$PWD:/src" -w /src` de los comandos; en el pipeline, `unset SEMGREP_IN_DOCKER` (práctica 02) |
| OSV-Scanner sale con `128` | No ha encontrado paquetes en el lockfile | `jq '.packages \| length' package-lock.json`: si es `1`, falta `npm install` desde la Semana 09 |
| Trivy se queda en `Downloading vulnerability DB` | Sin salida a `mirror.gcr.io` ni a `ghcr.io` | Comprueba la red de Docker; la caché sirve para la siguiente vez |
| `semgrep --test`: `only one target (directory or file) allowed for tests` | Le has pasado dos rutas | Solo la carpeta: `semgrep --test tests/seguridad` |
| `--test` no encuentra pruebas | `reglas.yaml` y `reglas.ts` no se llaman igual | El mismo nombre base, en la misma carpeta |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [README de la semana](../README.md) | [Práctica 02 — El componente `seguridad`](02-el-componente-seguridad.md) |
