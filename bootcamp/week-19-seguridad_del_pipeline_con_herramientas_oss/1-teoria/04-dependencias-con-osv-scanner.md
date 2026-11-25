# Dependencias con OSV-Scanner

> Tu código es una parte pequeña de lo que ejecutas. El resto lo escribió otra gente, y su versión está escrita en el lockfile. Cuando se publica una vulnerabilidad en una de esas versiones, tu repositorio pasa de seguro a vulnerable **sin que nadie haga un commit**. El escáner de dependencias convierte ese cambio invisible en un job rojo.

---

## 🎯 Objetivos

- Explicar por qué el escáner lee el lockfile y no `package.json`
- Saber de dónde salen los datos de OSV y qué significa el CVSS de cada hallazgo
- Interpretar los códigos de salida de OSV-Scanner y convertir su informe en JUnit con un umbral
- Aceptar una vulnerabilidad con `osv-scanner.toml` y una fecha de caducidad

---

## 1. Qué problema resuelve

`package.json` dice `"lodash": "^4.17.0"`: cualquier 4.x desde la 4.17.0. Lo que se instala de verdad, en tu máquina y en el job, lo dice `package-lock.json`, con la versión exacta de cada paquete **y de cada dependencia de cada paquete**. Una aplicación con cinco dependencias directas suele tener cientos de transitivas, y una vulnerabilidad en cualquiera de ellas es tuya.

Nadie revisa cientos de paquetes a mano cada día. La base de datos sí: cuando alguien publica un aviso para `lodash 4.17.20`, el siguiente escaneo de cualquier lockfile que la contenga falla.

---

## 2. Cómo funciona

### 2.1 La base de datos OSV

[OSV](https://osv.dev/) (Open Source Vulnerabilities) es una base de datos abierta, mantenida por Google, que **agrega** avisos de otras fuentes en un mismo formato: GitHub Security Advisories (`GHSA-…`), la base de PyPI, la de Go, RustSec, las distribuciones Linux… Cada aviso dice qué paquete, qué rango de versiones y en cuál está arreglado.

OSV-Scanner lee el lockfile, saca la lista de paquetes y versiones, y pregunta a `api.osv.dev` por ellos. Solo envía nombres y versiones, no tu código. Por eso el job necesita salida a internet (`--offline` existe, pero exige descargar antes la base de datos local y mantenerla al día, que es otro job).

### 2.2 Lo que encuentra

Con el `lodash 4.17.20` que la práctica 04 planta en `app`, el 2026-11-24:

| Aviso | CVSS | Arreglado en |
|---|:--:|---|
| GHSA-29mw-wpgm-hmr9 | 5.3 | 4.17.21 |
| GHSA-35jh-r3h4-6jhm | 7.2 | 4.17.21 |
| GHSA-r5fr-rjxr-66jc | 8.1 | 4.18.0 |
| GHSA-xxjr-mmjv-4gpg | 6.9 | 4.17.23 |

El **CVSS** (Common Vulnerability Scoring System) es una puntuación de 0 a 10 que resume la gravedad: cómo se explota (por red o en local), si hace falta autenticarse, qué se pierde (confidencialidad, integridad, disponibilidad). Las bandas habituales: 9,0 o más es crítica, 7,0-8,9 alta, 4,0-6,9 media, menos de 4 baja.

El CVSS mide la vulnerabilidad **en abstracto**, no en tu aplicación. Un 8,1 en una función de `lodash` que `app` no llama sigue siendo 8,1. Ahí es donde entra la decisión humana (teoría 07): el escáner no sabe si te afecta; sabe que la tienes.

### 2.3 Directas y transitivas

En un lockfile v3 de npm, cada paquete aparece en `packages` con su ruta (`node_modules/a/node_modules/b`). OSV-Scanner los lee todos, sin distinguir directas de transitivas en el resultado. Para arreglar una transitiva:

| Situación | Qué hacer |
|---|---|
| La directa tiene versión nueva que trae la transitiva arreglada | Subir la directa |
| La directa no se ha actualizado | `overrides` en `package.json` fuerza la versión de la transitiva, y `npm install` rehace el lockfile |
| No hay versión arreglada | Excepción con fecha (sección 3.2) y vigilar el aviso |

`npm ls <paquete>` dice por qué camino llega cada versión.

### 2.4 Lo que no da: JUnit y umbral

OSV-Scanner `2.7.0` escribe tabla, JSON, Markdown, SARIF, HTML, CycloneDX y SPDX. **No escribe JUnit**, y no tiene un `--severity`: falla si hay **cualquier** vulnerabilidad. Sus códigos de salida:

| Código | Significa |
|:--:|---|
| `0` | Ninguna vulnerabilidad |
| `1` | Hay vulnerabilidades |
| `128` | El lockfile no tiene paquetes (`No package sources found`) |
| `127` y otros | Error del propio escáner |

El componente los separa: `0`, `1` y `128` son resultados válidos, cualquier otro hace fallar el job como error. Y la decisión de bloquear no la toma OSV-Scanner sino el propio job: lee la tabla Markdown, convierte cada fila en un caso de test, y marca como fallo los que llegan al umbral de CVSS. Un hallazgo sin CVSS (pasa con avisos recientes) bloquea: sin puntuación no se puede decir que sea leve.

```text
| https://osv.dev/GHSA-r5fr-rjxr-66jc | 8.1 | npm | lodash | 4.17.20 | 4.18.0 | package-lock.json |
                                       ↓
<testcase classname="lodash@4.17.20" name="[CVSS 8.1] GHSA-r5fr-rjxr-66jc"><failure …/></testcase>
```

Son quince líneas de `awk` en el componente, y es la única traducción que escribe esta semana: Semgrep, Gitleaks y Trivy ya hablan JUnit.

---

## 3. Cómo se configura

### 3.1 El job

```yaml
osv-scanner:
  extends: .componente-seguridad   # stage, needs y rules: práctica 02, paso 2
  image:
    name: ghcr.io/google/osv-scanner:v2.7.0@sha256:4f3b7e2c64b9d38a5febc5a7e4a3dfef1d1362f726dea7a2ef4762b46469fcd0
    entrypoint: [""]
  script:
    - |
      for formato in sarif markdown; do
        rc=0
        /osv-scanner scan source --lockfile "$LOCKFILE" --format $formato --output-file osv.$formato || rc=$?
        case $rc in 0|1|128) ;; *) exit $rc ;; esac
      done
    - # awk: osv.markdown → osv.junit.xml, falla desde $CVSS_MIN
```

`--lockfile` explícito y no `-r .` (buscar todos los lockfiles del repositorio) para que el job escanee **lo que se despliega**, no los `package-lock.json` de fixtures o de ejemplos. Un repositorio con varios servicios pasa el input `lockfile` una vez por cada uno.

### 3.2 Aceptar una vulnerabilidad

OSV-Scanner busca `osv-scanner.toml` junto al lockfile y lo aplica solo:

```toml
[[IgnoredVulns]]
id = "GHSA-35jh-r3h4-6jhm"
ignoreUntil = 2026-12-24
reason = "La función afectada (template) no se usa en app. Revisado por @revisor-biblioteca, MR !<iid>."
```

En el log: `GHSA-35jh-r3h4-6jhm and 1 alias have been filtered out because: <reason>`. Pasada la fecha, la vulnerabilidad vuelve a contar y el job vuelve a fallar; OSV-Scanner avisa además de que el archivo tiene entradas que ya no se usan (`has unused ignores`). Comprobado en el laboratorio con una fecha pasada.

`ignoreUntil` es lo que hace que una excepción no sea un olvido: obliga a volver a decidir. Las versiones posteriores a la fijada aquí renombran la clave a `EffectiveUntil`; en `2.7.0` es `ignoreUntil`.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Escanear `package.json` | Dice rangos, no versiones; no ve las transitivas | El lockfile, versionado |
| `npm install` en el job en vez de `npm ci` | Rehace el lockfile y escaneas otra cosa que la que se instala | `npm ci` y el lockfile del commit (Semana 09) |
| Una excepción sin `ignoreUntil` | Para siempre es nunca revisarla | Fecha, motivo y quién lo revisó |
| Subir de versión mayor para quitar un aviso medio un viernes | El arreglo rompe más que la vulnerabilidad | El umbral decide qué es urgente; lo demás, al backlog con plazo (teoría 07) |
| `-r .` en un monorepo | Fixtures y ejemplos bloquean el pipeline de producción | Un `--lockfile` por lo que se despliega |

---

## 5. Trucos

- `osv-scanner scan source -r .` en tu clon enumera **todos** los lockfiles que encuentra: útil para descubrir qué tienes, no para el pipeline.
- `--format vertical` en local da cada aviso en bloque, legible en una terminal estrecha.
- `https://osv.dev/<id>` abre el aviso con los rangos afectados y las referencias; es la primera parada antes de decidir.

---

## 📚 Recursos Adicionales

- [OSV-Scanner](https://google.github.io/osv-scanner/) — uso, formatos, configuración y códigos de salida
- [Esquema OSV](https://ossf.github.io/osv-schema/) — el formato común de los avisos
- [CVSS v3.1 specification](https://www.first.org/cvss/v3.1/specification-document) — qué mide cada componente de la puntuación

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué el escáner necesita el lockfile y no `package.json`
- [ ] Puedes explicar qué mide el CVSS y qué no sabe de tu aplicación
- [ ] Sabes qué significan los códigos `0`, `1` y `128`
- [ ] Sabes qué pasa con una entrada de `osv-scanner.toml` cuando llega su `ignoreUntil`
