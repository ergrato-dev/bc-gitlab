# SAST con Semgrep

> Un escáner de código no entiende tu programa: busca formas. `eval` con algo que no es un literal, `exec` con una cadena construida, un objeto con `rejectUnauthorized: false`. Semgrep escribe esas formas en el mismo lenguaje que el código, y por eso una regla que nadie más tiene, la de tu dominio, cabe en diez líneas.

---

## 🎯 Objetivos

- Leer y escribir una regla de Semgrep: `pattern`, metavariables, `pattern-not` y `pattern-either`
- Decidir entre reglas propias y conjuntos del registro, sabiendo lo que cuesta cada uno
- Probar una regla con `semgrep --test` antes de que la sufra un pipeline
- Ejecutar Semgrep en un job de GitLab sin red, sin telemetría y con informes JUnit y SARIF

---

## 1. Qué problema resuelve

`grep eval src/` encuentra `evaluarPrestamo`, los comentarios que dicen "eval" y `eval("2 + 2")`, que es inofensivo. Y no encuentra `globalThis["ev" + "al"]`. Un buscador de texto da tantos falsos positivos que se deja de mirar.

Semgrep parsea el archivo y compara **árboles**: `eval($X)` coincide con cualquier llamada a `eval` con un argumento, da igual cómo esté formateada, y `pattern-not: eval("...")` descarta las que reciben un literal. El resultado es una regla que se equivoca poco, y una regla que se equivoca poco es una regla que puede parar un pipeline.

---

## 2. Cómo funciona

### 2.1 Anatomía de una regla

```yaml
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
```

| Pieza | Qué hace |
|---|---|
| `$X` | Metavariable: coincide con cualquier expresión, y se puede reutilizar en la misma regla |
| `...` | Cualquier número de argumentos o sentencias. `"..."` es cualquier cadena literal |
| `patterns` | Todas tienen que cumplirse (Y) |
| `pattern-either` | Basta una (O) |
| `pattern-not` | Quita lo que coincida |
| `severity` | `ERROR`, `WARNING` o `INFO`. El componente trata todas sus reglas como bloqueantes: por eso todas son `ERROR` |

El `message` es lo que el revisor lee en el widget de la merge request (teoría 06). Tiene que decir **qué** pasa y **por qué** importa, con la CWE si la hay: el revisor no va a abrir la documentación de Semgrep.

### 2.2 Las tres reglas del componente

| Regla | Qué encuentra | Por qué en `app` |
|---|---|---|
| `eval-con-datos` | `eval` con algo que no es un literal, `new Function` | Una fórmula de multa configurable es la tentación clásica |
| `comando-con-shell` | `exec` y `execSync` con una cadena que no es literal | Pasan la cadena a `/bin/sh`: `` `ls ${dir}` `` con `dir = "; rm -rf ~"` hace lo que parece |
| `tls-sin-verificar` | `rejectUnauthorized: false`, `NODE_TLS_REJECT_UNAUTHORIZED = "0"` | El "arreglo" que se copia cuando el laboratorio usa un certificado propio |

Son tres a propósito. Una regla nueva se gana su sitio cuando alguien la habría necesitado: después de un incidente, de una revisión que encontró algo, de una CWE que se repite. Cien reglas importadas de golpe dan cien hallazgos el primer día, y el primer día es cuando se decide si el equipo se toma en serio el escáner.

### 2.3 Reglas propias o el registro

Semgrep publica conjuntos de reglas en su registro (`--config p/javascript`, `--config p/typescript`, `--config auto`). Medido en el laboratorio el 2026-11-24 contra el código de `app` con un `eval(expr)` plantado:

| | `p/javascript` + `p/typescript` | Las tres reglas del componente |
|---|---|---|
| Reglas | 74 | 3 |
| Tiempo | De 4 a 82 s, según la red: las descarga en cada ejecución | 3 s |
| Red | Sí, en cada job | No |
| Encuentra el `eval(expr)` | **No** | Sí |
| Cambian sin que lo decidas | Sí: el registro se actualiza | No: van con la versión del componente |

Que 74 reglas genéricas no encuentren un `eval` no es un fallo del registro: sus reglas de `eval` están pensadas para código de navegador y otros contextos. Es la razón para escribir las tuyas. `--config auto`, además, exige enviar métricas a Semgrep para elegir reglas, y choca con el `--metrics=off` que se exige aquí (cero telemetría, como el laboratorio).

### 2.4 Probar una regla

Semgrep trae su propio banco de pruebas. En una carpeta, `reglas.yaml` con las reglas y `reglas.ts` con código anotado:

```typescript
// ruleid: eval-con-datos
eval(entrada);
// ok: eval-con-datos
eval("2 + 2");
```

`// ruleid:` dice "la línea siguiente **tiene** que dar hallazgo"; `// ok:`, "no puede darlo". `semgrep --test <carpeta>` compara y responde `3/3: ✓ All tests passed`, o qué anotación no se cumplió. Una regla con su prueba es una regla que se puede cambiar sin miedo, igual que una función con su test.

---

## 3. Cómo se configura

En el job, cuatro detalles que no se ven en la documentación de Semgrep:

```yaml
semgrep:
  extends: .componente-seguridad   # stage, needs y rules: práctica 02, paso 2
  image: semgrep/semgrep:1.185.0@sha256:67518c174185a2043fdbed16c70631b79209499b3671178e7194379b48295a0d
  script:
    # Las reglas viajan dentro del componente; el job las escribe en un archivo.
    - mkdir -p /plataforma && cat > /plataforma/semgrep.yml <<'REGLAS' …
    # La imagen da por hecho que el código está montado en /src.
    - unset SEMGREP_IN_DOCKER
    - >-
      semgrep scan --config /plataforma/semgrep.yml --metrics=off --disable-version-check --error
      --junit-xml-output=semgrep.junit.xml --sarif-output=semgrep.sarif
```

| Detalle | Por qué |
|---|---|
| `unset SEMGREP_IN_DOCKER` | La imagen define esa variable, y con ella Semgrep exige que haya código en `/src`. En un job el código está en `$CI_PROJECT_DIR`: sin el `unset`, el job muere con `Detected Docker environment without a code volume` y `exit 2` |
| `/plataforma/semgrep.yml` | El `id` de la regla en el informe lleva delante la carpeta del archivo: `plataforma.eval-con-datos`. Con `/tmp/` saldría `tmp.eval-con-datos` |
| `--error` | Sin él, Semgrep termina con `0` aunque encuentre algo |
| `--disable-version-check` | Si no, consulta en cada job si hay versión nueva: una petición a internet que no aporta nada con la versión fijada |

Semgrep solo escanea los archivos **versionados** en Git (`Scan was limited to files tracked by git`): lo que está en `.gitignore`, como `node_modules/`, no cuenta. En un job el clon es exactamente lo versionado.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `--config auto` en el pipeline | Reglas elegidas por un servicio externo, con telemetría, que cambian solas | Reglas propias, fijadas con el componente |
| Una regla sin prueba | El día que alguien la "mejora", deja de encontrar lo que encontraba y nadie se entera | `semgrep --test` en el pipeline de `ci/componentes` |
| `// nosemgrep` sin decir por qué | Se convierte en la forma de que el pipeline pase | `// nosemgrep: eval-con-datos -- <motivo>`, y la revisión de esa línea (teoría 07) |
| Mensajes como "Dangerous code" | El revisor no sabe si importa | Qué pasa, por qué y la CWE |
| Reglas `WARNING` que no paran nada | Ruido que se deja de leer | Si importa, `ERROR`; si no, fuera |

---

## 5. Trucos

- `semgrep --validate --config reglas.yml` comprueba la sintaxis sin escanear nada: `Configuration is valid - found 0 configuration error(s), and 3 rule(s).`
- `semgrep scan --config reglas.yml --dataflow-traces` enseña por qué una regla con `taint` (seguir un dato desde la petición hasta `eval`) coincidió. Las tres reglas del componente no usan `taint`, pero es el siguiente paso cuando una regla da demasiados falsos positivos.
- [semgrep.dev/playground](https://semgrep.dev/playground) prueba una regla en el navegador sin instalar nada. No pegues ahí código de tu empresa.

---

## 📚 Recursos Adicionales

- [Rule syntax](https://semgrep.dev/docs/writing-rules/rule-syntax) — todos los operadores de una regla
- [Testing rules](https://semgrep.dev/docs/writing-rules/testing-rules) — `ruleid`, `ok` y `todoruleid`
- [CWE-95](https://cwe.mitre.org/data/definitions/95.html), [CWE-78](https://cwe.mitre.org/data/definitions/78.html), [CWE-295](https://cwe.mitre.org/data/definitions/295.html) — las tres debilidades de las reglas del componente

---

## ✅ Checklist de Verificación

- [ ] Sabes leer `patterns`, `pattern-either` y `pattern-not` y decir qué encuentra una regla
- [ ] Has ejecutado `semgrep --test` sobre las reglas del componente y pasan las tres
- [ ] Sabes por qué el job necesita `unset SEMGREP_IN_DOCKER`
- [ ] Puedes explicar por qué el componente no usa `--config auto`
