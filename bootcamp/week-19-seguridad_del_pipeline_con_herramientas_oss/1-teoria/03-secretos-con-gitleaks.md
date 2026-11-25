# Secretos con Gitleaks

> Un secreto en un commit no se arregla con otro commit. Git guarda todo, el servidor guarda las versiones de cada merge request, y cualquiera con permiso de lectura puede ir hacia atrás. Por eso el escáner de secretos lee el historial entero, y por eso, cuando encuentra algo, lo primero no es borrarlo: es darlo por perdido y cambiarlo.

---

## 🎯 Objetivos

- Explicar qué detecta Gitleaks y por qué lee commits, no archivos
- Configurar el job para que vea el historial completo y no escriba el secreto en el log
- Leer la huella de un hallazgo y usarla en `.gitleaksignore`
- Ordenar la respuesta a un secreto filtrado: rotar, después decidir qué hacer con el historial

---

## 1. Qué problema resuelve

La Semana 10 sacó los secretos del YAML y los metió en variables protegidas. Eso cubre los secretos que el equipo **sabe** que son secretos. No cubre la contraseña que alguien pega en `src/config.ts` para probar en local, ni el `.env` que se cuela en un `git add .`.

Y el revisor no lo ve. Si la MR tiene dos commits, uno que añade la contraseña y otro que la borra, la pestaña *Changes* enseña la diferencia entre el principio y el final: nada. La contraseña está en el commit 1, en `refs/merge-requests/<iid>/head` y en la versión 1 de la diff de la merge request. GitLab conserva las versiones de cada MR, así que **reescribir la rama tampoco la quita del servidor**.

---

## 2. Cómo funciona

### 2.1 Qué detecta

Gitleaks 8.30.0 trae 222 reglas en su configuración por defecto. Las hay de dos tipos:

| Tipo | Ejemplo | Cómo lo reconoce |
|---|---|---|
| Formato conocido | Tokens de GitLab, claves de AWS, claves privadas PEM, tokens de Slack | Un prefijo o una estructura fija (`-----BEGIN … PRIVATE KEY-----`) |
| Genérico (`generic-api-key`) | `password: "…"`, `apiKey = "…"` | Una palabra clave cerca (`password`, `secret`, `token`, `key`) y un valor con **entropía** alta: una cadena que parece aleatoria |

La entropía es la que hace que `password: "cambiame"` no salte y `password: "Xk3…"` con 24 caracteres aleatorios sí. La regla genérica, además, descarta un valor sin ningún dígito, aunque sea aleatorio: comprobado en 8.30.0, `password: "TGFJDKCJtkZpoXCsbskISucs"` no salta. En las prácticas el "secreto" lo genera `openssl rand -hex 16`: 32 caracteres hexadecimales, un valor aleatorio que nunca ha sido credencial de nada, y que Gitleaks detecta igual que una de verdad. Este material nunca escribe un token con formato válido (los de GitLab empiezan por `glpat-`): la propia instancia los detectaría, y un token falso con formato válido enseña a pegar tokens.

### 2.2 Historial, no carpeta

| Subcomando | Qué lee | Cuándo |
|---|---|---|
| `gitleaks git .` | Cada commit alcanzable, con su diff | En el pipeline |
| `gitleaks dir .` | Los archivos tal como están ahora | En tu máquina, antes de `git add` |
| `gitleaks stdin` | Lo que le llegue por la entrada | Para pasarle un log o un artefacto |

GitLab clona por defecto con `GIT_DEPTH: 20` (Semana 09): los últimos 20 commits. Un secreto del commit 21 no existe para el job. El componente pone `GIT_DEPTH: "0"`, el historial completo. En `app`, con unos cientos de commits, Gitleaks tarda menos de un segundo; el coste es el clon, y es pequeño.

¿Por qué el historial entero en cada pipeline y no solo los commits de la MR? Porque el escáner llega a un repositorio que ya tiene historia. La primera vez que se activa encuentra lo que hubiera, y ese hallazgo se decide una vez (teoría 07) y queda en `.gitleaksignore`. A partir de ahí, cualquier hallazgo nuevo es nuevo de verdad.

### 2.3 El informe sin el secreto

Sin `--redact`, Gitleaks escribe el valor encontrado en su salida, y su salida es el log del job: lo lee cualquiera con rol Reporter, y se queda mientras dure el job. El componente lo usa siempre:

```json
{
  "RuleID": "generic-api-key",
  "File": "src/config.ts",
  "StartLine": 3,
  "Secret": "REDACTED",
  "Fingerprint": "1f8f9d5bfe927180fe1c7ba1bcb2359c6d6d8ed8:src/config.ts:generic-api-key:3"
}
```

Comprobado en el laboratorio: con `--redact`, el valor no aparece ni en el log, ni en el JUnit, ni en el SARIF.

### 2.4 La huella

`Fingerprint` es `<commit>:<archivo>:<regla>:<línea>`. Identifica **ese** hallazgo en **ese** commit. `.gitleaksignore`, en la raíz del repositorio, es una lista de huellas que Gitleaks no vuelve a contar:

```
# Contraseña generada con openssl en la práctica 04, MR !<iid>. Nunca fue credencial de nada.
# Retirada en el commit siguiente. Revisada por @revisor-biblioteca el 2026-11-24.
1f8f9d5bfe927180fe1c7ba1bcb2359c6d6d8ed8:src/config.ts:generic-api-key:3
```

Como la huella lleva el commit, un secreto nuevo en el mismo archivo y la misma línea es **otro** hallazgo, y vuelve a parar el pipeline. Eso es lo que la hace segura frente a ignorar un archivo entero.

---

## 3. Cómo se configura

```yaml
gitleaks:
  extends: .componente-seguridad   # stage, needs y rules: práctica 02, paso 2
  image:
    name: zricethezav/gitleaks:v8.30.0@sha256:691af3c7c5a48b16f187ce3446d5f194838f91238f27270ed36eef6359a574d9
    entrypoint: [""]
  variables:
    GIT_DEPTH: "0"
  script:
    - gitleaks git --redact --no-banner --exit-code 0 --report-format sarif --report-path gitleaks.sarif .
    - gitleaks git --redact --no-banner --report-format junit --report-path gitleaks.junit.xml .
```

Dos pasadas porque Gitleaks escribe un formato por ejecución. La primera, con `--exit-code 0`, solo deja el SARIF; la segunda deja el JUnit y decide el resultado (`1` si encuentra algo). Las dos juntas tardan menos que descargar la imagen. `entrypoint: [""]` porque la imagen arranca con `gitleaks` como punto de entrada, y el runner necesita una shell para ejecutar el `script`.

En tu terminal, sobre tu clon de `app`, la misma comprobación:

```bash
docker run --rm -v "$PWD:/repo" -w /repo \
  zricethezav/gitleaks:v8.30.0@sha256:691af3c7c5a48b16f187ce3446d5f194838f91238f27270ed36eef6359a574d9 \
  git --redact .
# … INF N commits scanned.
# … INF no leaks found
```

---

## 4. Qué hacer cuando aparece uno

El orden importa, y es el de la Semana 10, teoría 07: **primero rotar, después investigar**.

1. **Rotar.** Cambia la credencial en el sistema al que pertenece. Desde el momento del push, el valor viejo está en el servidor y en cada clon: es público para todo el que tenga acceso, aunque nadie lo haya mirado.
2. **Quitarlo del código.** Un commit que lo saque, y el valor nuevo a una variable protegida (Semana 10).
3. **Decidir sobre el historial.**

| Opción | Cuándo | Lo que no arregla |
|---|---|---|
| La huella en `.gitleaksignore`, con motivo | El secreto ya está rotado. El caso normal | Nada: el valor viejo ya no vale |
| Reescribir la rama (`git rebase -i`, `git push --force-with-lease`) | La rama no se ha fusionado y no es protegida | GitLab conserva las versiones de la MR y su `refs/merge-requests/<iid>/head`. Sigue estando en el servidor |
| Reescribir `main` | Casi nunca: rompe todos los clones y la regla 3 del hilo conductor | Ídem, y además cada clon que ya existía |

La reescritura no sustituye a la rotación: solo hace más difícil encontrar un valor que ya no sirve.

---

## 5. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Borrar el secreto en otro commit y seguir | Sigue en el historial y en la MR; Gitleaks sigue fallando | Rotar, quitarlo, y la huella con motivo |
| Escanear sin `--redact` | El log del job publica el secreto que acabas de encontrar | `--redact` siempre |
| Clon superficial | El secreto del commit 21 no existe para el escáner | `GIT_DEPTH: "0"` |
| Ignorar `src/config.ts` entero | El próximo secreto de ese archivo también pasa | La huella: un commit, una línea, una regla |
| Pegar un token "de prueba" con formato válido en los tests | Lo detecta GitLab, lo detecta Gitleaks, y enseña el hábito | Valores generados y sin formato de credencial |

---

## 6. Trucos

- `gitleaks dir .` antes de `git add` es lo más barato que hay: el secreto ni llega a commit. En CE, la protección de secretos en el push es Ultimate; el sustituto libre es un server hook (Semana 07) que ejecute Gitleaks sobre lo que llega.
- `--log-opts="<rango>"` limita los commits: `--log-opts="main..HEAD"` solo mira lo que tu rama añade. Útil en local; en el pipeline, el historial entero.
- La huella exacta está en el SARIF del job (`results[].partialFingerprints`) y en el JUnit (el `name` del caso lleva el commit, el archivo y la línea).

---

## 📚 Recursos Adicionales

- [Gitleaks](https://github.com/gitleaks/gitleaks#readme) — subcomandos, configuración, `.gitleaksignore` y la configuración por defecto
- [Revoking a leaked credential](https://docs.gitlab.com/security/responding_to_security_incidents/#credential-exposure-to-public-internet) — la guía de GitLab para un token expuesto
- [Pipeline secret detection](https://docs.gitlab.com/user/application_security/secret_detection/pipeline/) — la plantilla Free de GitLab, el mismo motor

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué un secreto borrado en el commit siguiente sigue siendo un hallazgo
- [ ] Sabes qué hace `--redact` y lo has visto en un informe
- [ ] Puedes leer una huella y decir a qué commit, archivo y línea apunta
- [ ] Sabes el orden: rotar, quitar, decidir sobre el historial
