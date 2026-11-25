# Práctica 04 — La merge request envenenada

> Una merge request con tres problemas que un revisor con prisa no vería: una fórmula que se evalúa con `eval`, una dependencia con dos CVE altas y una contraseña que se pegó y se borró en el commit siguiente. Tres escáneres la paran, cada uno por lo suyo. La arreglas como se arregla de verdad: el código y la dependencia, corregidos; la contraseña, dada por quemada y su huella apuntada con motivo, en un archivo que ya tiene dueño.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 03 completada (`main` de `app` escaneada y en verde) · Teoría [03](../1-teoria/03-secretos-con-gitleaks.md), [04](../1-teoria/04-dependencias-con-osv-scanner.md) y [07](../1-teoria/07-excepciones-que-caducan.md) leídas · `npm` en tu máquina, como en la Semana 09

---

## Contexto

| Paso | Qué deja hecho | Comprobación |
|---|---|---|
| 1 | Los archivos de excepción, con dueño antes de existir | `excepciones-con-dueno` |
| 2 | La merge request envenenada | — |
| 3 | Lo que ve el revisor, y la fusión rechazada | `los-cuatro-han-parado-algo` |
| 4 | El `eval`, fuera | — |
| 5 | La dependencia, fuera | — |
| 6 | La contraseña: quemada, retirada y su huella con motivo | `excepcion-con-motivo` |
| 7 | La merge request fusionada | — |

Si has cerrado la terminal, repite el paso 0 de la práctica 01 y pega `esperar` y `fusionar`.

---

## Paso 1: Dueños para las excepciones

**Por qué**: una excepción cambia lo que la puerta deja pasar, así que no la aprueba quien la necesita (teoría 07, apartado 2.3). `gobernanza` lee el `CODEOWNERS` de la rama de **destino**: las tres líneas tienen que estar en `main` antes de la merge request que use cualquiera de los tres archivos. Por eso van en una merge request propia, ahora.

```bash
cd /ruta/a/tu/clon/de/app && git switch main && git pull --ff-only
IID=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Dueño para los archivos de excepciones de seguridad" \
  --data-urlencode "labels=tipo::mantenimiento" \
  --data-urlencode "description=.gitleaksignore, osv-scanner.toml y .trivyignore.yaml los aprueba revisor. Ver Semana 19, teoría 07." \
  | jq -r .iid)
git switch -c "$IID-duenos-de-excepciones"
cat >> CODEOWNERS <<EOF

# Las excepciones de seguridad no las aprueba quien las necesita (Semana 19)
/.gitleaksignore      @$REV
/osv-scanner.toml     @$REV
/.trivyignore.yaml    @$REV
EOF
tail -5 CODEOWNERS
git commit -S -am "chore: dueño para los archivos de excepciones de seguridad"
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="chore: dueño para las excepciones de seguridad" \
  -o merge_request.description="Closes #$IID"
MR=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
fusionar "$P" "$MR"
git switch main && git pull --ff-only
```

**Verifica**: `state: merged`. La merge request tocaba `CODEOWNERS`, que es de `revisor` desde la Semana 07: `fusionar` lo aprueba como `revisor` y `gobernanza` lo comprueba. Y:

```bash
curl -s -H "$H" "$API/projects/$P/repository/files/CODEOWNERS/raw?ref=main" | grep -E '^/(\.gitleaksignore|osv-scanner\.toml|\.trivyignore\.yaml) '
```

Tres líneas, con `@revisor-<tu-dominio>`.

---

## Paso 2: La merge request envenenada

**Por qué**: la petición de negocio es razonable: que la multa por día se pueda configurar con una fórmula. La implementación tiene los tres errores de la teoría 01. La contraseña la genera `openssl` (nunca fue credencial de nada) y va en su propio commit, y su retirada en el siguiente, como pasa de verdad.

```bash
IIDV=$(curl -s --request POST "$API/projects/$P/issues" -H "$H" \
  --data-urlencode "title=Multa configurable por fórmula" \
  --data-urlencode "labels=tipo::funcionalidad" \
  --data-urlencode "description=La multa por día se lee de una fórmula. MR de la práctica 04 de la Semana 19." \
  | jq -r .iid)
echo "export IIDV=$IIDV" >> ~/.bc-gitlab-s19
git switch -c "$IIDV-multa-configurable"

npm install --save-exact lodash@4.17.20 @types/lodash@4.17.26 --no-audit --no-fund   # sin los tipos, tsc no compila
cat > src/formulas.ts <<'EOF'
import { round } from "lodash";

// La fórmula llega de la configuración, por ejemplo "dias * 0.5".
export function multaPorFormula(formula: string, dias: number): number {
  return round(eval(formula.replaceAll("dias", String(dias))), 2);
}
EOF
git add package.json package-lock.json src/formulas.ts
git commit -S -m "feat: multa configurable por fórmula"

printf 'export const conexion = {\n  host: "db",\n  password: "%s",\n};\n' "$(openssl rand -hex 16)" > src/config.ts
git add src/config.ts
git commit -S -m "chore: configuración de la base de datos"
git rm -q src/config.ts
git commit -S -m "chore: la configuración no va en el repositorio"

git log --oneline main..HEAD
git push -u origin HEAD -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="feat: multa configurable por fórmula" \
  -o merge_request.description="Closes #$IIDV"
MRV=$(curl -s -H "$H" "$API/projects/$P/merge_requests?source_branch=$(git branch --show-current)&state=opened" | jq -r '.[0].iid')
echo "export MRV=$MRV" >> ~/.bc-gitlab-s19
```

**Verifica**: tres commits en `git log`. Y en la pestaña *Changes* de la merge request, en la UI: `package.json`, `package-lock.json` y `src/formulas.ts`. **No** aparece `src/config.ts`: entra y sale dentro de la misma MR, y la diferencia final no la enseña. Un revisor que solo mire *Changes* no la ve nunca.

---

## Paso 3: Lo que ve el revisor

```bash
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MRV" | jq -r .head_pipeline.id)
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r 'sort_by(.id) | .[] | select(.stage=="seguridad") | "\(.name)\t\(.status)"'
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/test_report" \
  | jq -r '.test_suites[] | .name as $s | .test_cases[] | select(.status=="failed") | "\($s)\t\(.classname)\t\(.name)"'
```

**Verifica**: `failed`, con `semgrep`, `gitleaks` y `osv-scanner` en `failed` y `trivy` en `success`. Los fallos, uno por línea:

| Suite | Qué dice | De dónde sale |
|---|---|---|
| `semgrep` | `src/formulas.ts` · `plataforma.eval-con-datos` | La regla de la práctica 01 |
| `gitleaks` | `generic-api-key has detected a secret in file src/config.ts, line 3, at commit …` | El commit 2, aunque el 3 lo borre |
| `osv-scanner` | `lodash@4.17.20` · `[CVSS 7.2] GHSA-35jh-r3h4-6jhm` y `[CVSS 8.1] GHSA-r5fr-rjxr-66jc` | Dos de sus cuatro avisos llegan al umbral; los de 5.3 y 6.9 salen como casos que pasan |

¿Por qué Trivy pasa? `lodash` está declarado en `package.json`, pero la imagen no lo instala (el `Dockerfile` solo copia `package.json` y `src/`): en la imagen no hay ningún `lodash` que escanear. OSV-Scanner lo ve en el lockfile; Trivy, no. Es la diferencia de la teoría 01, apartado 2.1, con tu propio código.

En la UI, el *Test summary* dice cuántos fallos son nuevos frente a `main` (todos: `main` está limpia). Y la fusión:

```bash
SHA=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MRV" | jq -r .sha)
curl -s --request PUT "$API/projects/$P/merge_requests/$MRV/merge" -H "$H" --data-urlencode "sha=$SHA" -w '  HTTP %{http_code}\n'
```

**Verifica**: `405`. Con este pipeline, los cuatro escáneres han parado ya algo en `app`: Trivy en la práctica 03, los otros tres ahora.

---

## Paso 4: El `eval`

**Por qué**: la regla no tiene excepción posible aquí: la fórmula llega de fuera (teoría 02, apartado 2.2). Lo que el negocio necesita no es evaluar código, es elegir entre tarifas. Una tabla lo hace sin ejecutar nada.

```bash
cat > src/formulas.ts <<'EOF'
// Tarifas por día de retraso. Se elige por nombre; no se evalúa ninguna expresión.
const TARIFAS = { normal: 0.5, reincidente: 1 } as const;

export type Tarifa = keyof typeof TARIFAS;

export function multaPorTarifa(tarifa: Tarifa, dias: number): number {
  return Math.round(TARIFAS[tarifa] * Math.max(dias, 0) * 100) / 100;
}
EOF
docker run --rm -v "$PWD:/src" -w /src \
  -v /ruta/a/tus/clones/componentes/tests/seguridad/reglas.yaml:/plataforma/semgrep.yml:ro "$I_SEMGREP" \
  semgrep scan --config /plataforma/semgrep.yml --metrics=off --error -q
echo "salida: $?"
```

Si borraste `tests/seguridad/reglas.yaml` de tu clon de `ci/componentes`, regénéralo como el job `reglas-semgrep`: `awk "/<<'REGLAS'/{f=1;next} /^ *REGLAS\$/{f=0} f" templates/seguridad.yml | sed 's/^      //' > tests/seguridad/reglas.yaml`.

**Verifica**: `salida: 0`, sin hallazgos.

---

## Paso 5: La dependencia

**Por qué**: `lodash` estaba para `round`, y `Math.round` hace lo mismo. La mejor versión de una dependencia es la que no se instala: no tiene CVE, ni transitivas, ni actualizaciones que vigilar.

```bash
npm uninstall lodash @types/lodash --no-audit --no-fund
grep -c lodash package.json package-lock.json
docker run --rm -v "$PWD:/src" -w /src "$I_OSV" scan source --lockfile package-lock.json
echo "salida: $?"
git add package.json package-lock.json src/formulas.ts
git commit -S -m "fix: multa por tarifa, sin eval ni lodash"
```

**Verifica**: `package.json:0` y `package-lock.json:0`, `No issues found` y `salida: 0`.

Si la dependencia hiciera falta de verdad, el arreglo sería subirla a la versión corregida (`4.18.0`, la columna *Fixed Version* de OSV-Scanner) con al menos siete días publicada. Solo si no hubiera versión corregida, una excepción con fecha en `osv-scanner.toml` (teoría 07).

---

## Paso 6: La contraseña

**Por qué**: el orden de la teoría 03: **rotar**, quitarla, decidir sobre el historial. Aquí la rotación es trivial (el valor lo generó `openssl` y nunca fue credencial de nada), pero en un caso real este paso es el primero y no se salta: el valor estuvo en el servidor desde el push.

Lo que ya está hecho no basta. Compruébalo:

```bash
git push
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MRV" | jq -r .head_pipeline.id)
esperar "$P" "$PIPE"
curl -s -H "$H" "$API/projects/$P/pipelines/$PIPE/jobs" | jq -r '.[] | select(.stage=="seguridad") | "\(.name)\t\(.status)"'
```

**Verifica**: `semgrep` y `osv-scanner` en `success`; `gitleaks` sigue en `failed`. `src/config.ts` ya no existe en la rama, pero sí en su segundo commit, y Gitleaks lee commits.

Dos salidas posibles (teoría 03, apartado 4): reescribir la rama o apuntar la huella. Reescribir no quita el valor del servidor: GitLab guarda la versión de la diff de la MR que lo contenía. Y la fusión con `squash` (la de `fusionar`) ya hace que ese commit no llegue nunca a `main`. Lo que queda es decidirlo por escrito, donde lo revise el dueño del paso 1:

```bash
docker run --rm -v "$PWD:/repo" -w /repo "$I_GITLEAKS" git --redact --no-banner \
  --log-opts="main..HEAD" --report-format json --report-path /repo/gitleaks.json .
HUELLA=$(jq -r '.[0].Fingerprint' gitleaks.json) && rm gitleaks.json
echo "$HUELLA"
cat >> .gitleaksignore <<EOF
# Contraseña generada con openssl en la práctica 04 de la Semana 19 (MR !$MRV). Nunca fue credencial
# de ningún sistema: no hay nada que rotar. Retirada en el commit siguiente; no llega a main (squash).
$HUELLA
EOF
cat .gitleaksignore
docker run --rm -v "$PWD:/repo" -w /repo "$I_GITLEAKS" git --redact --no-banner .
echo "salida: $?"
```

**Verifica**: una huella con la forma `<40 hex>:src/config.ts:generic-api-key:3`; el archivo con las dos líneas de comentario y la huella debajo; y `no leaks found` con `salida: 0`. El comentario va **justo encima** de la huella: es lo que comprueba `excepcion-con-motivo`.

```bash
git add .gitleaksignore
git commit -S -m "chore: huella de la contraseña de prueba, retirada y sin uso"
```

---

## Paso 7: La fusión

```bash
git push
sleep 10
PIPE=$(curl -s -H "$H" "$API/projects/$P/merge_requests/$MRV" | jq -r .head_pipeline.id)
esperar "$P" "$PIPE"
fusionar "$P" "$MRV"
git switch main && git pull --ff-only
PIPE=$(curl -s -H "$H" "$API/projects/$P/pipelines?ref=main&source=push&per_page=1" | jq -r '.[0].id')
esperar "$P" "$PIPE"
git log --oneline -2
git log main --oneline -- src/config.ts | wc -l
git log --all --oneline -- src/config.ts | head -3
```

**Verifica**: `success`, `state: merged` y el pipeline de `main` en `success`. La merge request tocaba `.gitleaksignore`: `gobernanza` exigió la aprobación de `revisor`, que `fusionar` da. Los dos últimos commits de `main` son el de fusión y, debajo, el squash de la MR con su título. `0`: ningún commit de `main` tocó nunca `src/config.ts`. Y las últimas líneas enseñan los dos commits de tu rama local que sí lo tocaron: siguen en tu clon y en el servidor (en `refs/merge-requests/$MRV/head`), aunque `main` no los tenga. Borra la rama local cuando termines: `git branch -D "$IIDV-multa-configurable"`.

Revoca el token de `revisor` de esta semana:

```bash
curl -s --request DELETE "$API/personal_access_tokens/self" -H "$HR" -w '%{http_code}\n'
```

`204`.

---

## ✅ Resultado

- [ ] Las tres rutas de excepciones en `CODEOWNERS` de `main`, con `revisor` como dueño
- [ ] La merge request envenenada rechazada con `405` por `semgrep`, `gitleaks` y `osv-scanner`
- [ ] El `eval` sustituido por una tabla y `lodash` desinstalado
- [ ] `.gitleaksignore` con la huella y su motivo encima, aprobado por `revisor`
- [ ] `main` en verde después de la fusión, y el token de `revisor` revocado

```bash
./scripts/verificar-semana.sh 19
```

Quince de dieciséis en verde. Falta `politica-de-seguridad`: `docs/seguridad.md` es el proyecto de la semana.

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `gitleaks` no falla en el paso 3 | El valor no tiene entropía suficiente o no tiene ningún dígito (la regla genérica lo descarta), o lo escribiste a mano | El `openssl rand -hex 16` del paso 2 |
| `trivy` falla en el paso 3 | Tu `Dockerfile` instala dependencias (`npm ci` en la imagen) | Entonces Trivy también ve `lodash`: es el comportamiento correcto; sigue con el paso 5 |
| `gitleaks` sigue fallando tras el paso 6 | La huella no coincide (commit reescrito, o copiada a mano) | Repite el `gitleaks … --report-format json` sobre la rama actual |
| `fusionar`: `gobernanza no está en verde` en el paso 7 | El `CODEOWNERS` de `main` no tiene `/.gitleaksignore` | El paso 1 se fusiona **antes** |
| `excepcion-con-motivo` en rojo | Hay una línea en blanco entre el comentario y la huella, o el comentario es muy corto | El comentario justo encima, con el motivo |
| `npm install` responde `ERR_PNPM`… | Usas pnpm con `minimumReleaseAge` | Esta práctica usa `npm`, como la Semana 09; `lodash 4.17.20` es de 2020 |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [Práctica 03 — `app` detrás de los cuatro](03-app-detras-de-los-cuatro.md) | [Proyecto de la semana](../3-proyecto/README.md) |
