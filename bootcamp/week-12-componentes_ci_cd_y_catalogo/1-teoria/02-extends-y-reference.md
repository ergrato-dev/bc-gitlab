# `extends` y `!reference`

> `include` junta archivos; `extends` y `!reference` reutilizan trozos **dentro** del YAML ya junto. `extends` hereda un job entero y lo fusiona clave a clave; `!reference` copia una sola pieza donde la pidas. Juntos resuelven lo que la fusión de `include` no resuelve: componer listas.

---

## 🎯 Objetivos

- Predecir el job resultante de un `extends`, también con varios padres
- Quitar una clave heredada sin redefinir el job entero
- Componer `rules` y `script` de varios sitios con `!reference`
- Explicar por qué las anclas de YAML no sirven entre archivos

---

## 1. Qué problema resuelve

Desde la Semana 09, `build` y `test` heredan de `.npm`, y desde la 10 los dos despliegues heredan de `.deploy`. En la Semana 11 apareció un caso que `extends` no resolvía: `.npm`, `package`, los despliegues e `infra` necesitaban **la misma primera regla** (fuera de los programados) delante de **sus propias** reglas. Heredar no vale, porque `rules` es una lista y la lista del hijo sustituye a la del padre. La solución fue `!reference`.

Esta semana, al partir `.gitlab-ci.yml` en archivos, `.fuera-de-programados` vive en un archivo y los despliegues que la usan en otro. Hay que saber si eso funciona y por qué.

---

## 2. Cómo funciona

### 2.1 `extends`: fusión profunda, el hijo gana

```yaml
.deploy:
  stage: deploy
  image: alpine:3.24.2
  interruptible: false
  variables:
    DESTINO: simulado
  script:
    - scripts/deploy.sh

deploy-staging:
  extends: .deploy
  variables:
    ENTORNO: staging
  script:
    - echo "antes"
    - scripts/deploy.sh
```

| Clave | Resultado en `deploy-staging` | Por qué |
|---|---|---|
| `stage`, `image`, `interruptible` | Las de `.deploy` | Solo están en el padre |
| `variables` | `DESTINO` **y** `ENTORNO` | Es un mapa: se fusiona |
| `script` | Las dos líneas del hijo | Es una lista: se sustituye |

Es la misma regla que la fusión de `include` (teoría 01, apartado 2.4), aplicada de job a job. `extends` se resuelve **después** de juntar todos los `include`, así que un job puede heredar de un job oculto de otro archivo:

```yaml
# ci/deploy.yml
deploy-staging:
  extends: .deploy     # .deploy puede estar en .gitlab-ci.yml o en otro include
```

### 2.2 Varios padres

```yaml
deploy-staging:
  extends: [.deploy, .con-candado]
```

Se aplican en orden: `.con-candado` encima de `.deploy`, y el job encima de los dos. Si los dos padres definen la misma lista, gana la del último. Hasta once niveles de herencia; la documentación recomienda no pasar de tres. Más allá, nadie sabe de dónde sale un valor sin abrir `merged_yaml`.

### 2.3 Quitar una clave heredada

```yaml
.npm:
  cache:
    key:
      files: [package-lock.json]
    paths: [.npm/]

lint:
  extends: .npm
  cache: null          # este job no usa la caché
```

`null` borra la clave. Un mapa vacío (`{}`) no la borra: se fusiona con el del padre y no cambia nada.

### 2.4 `!reference`: copiar una pieza

```yaml
.fuera-de-programados:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never

deploy-staging:
  extends: .deploy
  rules:
    - !reference [.fuera-de-programados, rules]
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

`!reference [job, clave, subclave...]` es el valor de esa ruta. Dentro de una lista, una lista referenciada se aplana un nivel: `deploy-staging` sale con dos reglas, no con una lista dentro de otra. En `script`, `before_script` y `after_script` se pueden anidar hasta diez niveles.

| Herramienta | Copia | Fusiona | Entre archivos |
|---|---|---|:--:|
| `extends` | Un job entero | Sí, mapas en profundidad | ✅ |
| `!reference` | Una clave concreta | No: pega el valor donde lo pones | ✅ |
| Ancla de YAML (`&x`, `*x`, `<<:`) | Un nodo | Solo un nivel con `<<:` | ❌ |

### 2.5 Por qué las anclas no sirven aquí

Un ancla es YAML puro: el analizador la resuelve al leer **un** archivo. Cuando GitLab junta los `include`, cada archivo ya se ha leído por separado y sus anclas ya no existen. `extends` y `!reference` son de GitLab y se resuelven sobre el YAML ya junto. Las anclas siguen siendo útiles para repetir un bloque dentro del mismo archivo, pero la Semana 09 ya eligió `extends` por legibilidad.

### 2.6 El orden: `include`, después `!reference` y `extends`, después `inputs`

`!reference` se evalúa **antes** de sustituir los `inputs` (teoría 03). Por eso un `!reference` no puede apuntar dentro de un componente a algo que dependa de un input del consumidor, ni un componente debería apoyarse en un `!reference` a un job del consumidor: el componente no sabe si ese job existe (teoría 04, apartado 2.5).

---

## 3. Cómo se configura

Lo que salió de un `extends` y de un `!reference` se ve en `merged_yaml`, ya resuelto:

```bash
curl -s -H "$H" "$API/projects/$P/ci/lint?ref=main&include_merged_yaml=true" \
  | jq -r .merged_yaml | awk '/^deploy-staging:/{f=1; print; next} /^[^ ]/{f=0} f'
```

`merged_yaml` escribe la regla referenciada como una lista dentro de la lista (`- - if: ...`): es solo cómo la serializa. El job la evalúa aplanada, y `ci/lint` con `include_jobs=true` lista los jobs que entrarían.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Redefinir `rules` en el hijo creyendo que suma a las del padre | Las del padre desaparecen | `!reference [.padre, rules]` como primera regla |
| `extends` de un job visible | El job padre también se ejecuta | El padre, oculto (`.nombre`) |
| Cadenas de cuatro o cinco `extends` | Para saber qué imagen usa un job hay que recorrerlas todas | Dos niveles, y lo demás explícito |
| Anclas entre archivos | El `include` falla: `An alias referenced an unknown anchor` | `extends` o `!reference` |
| `variables: {}` para quitar las heredadas | Se fusiona: no quita nada | `variables: null` |
| Un componente que hace `!reference` a un job del consumidor | Se rompe en cualquier proyecto que no tenga ese job | Lo que necesite, dentro del componente o como input |

---

## 5. Trucos

- **¿De qué padre viene esta clave?** No hay una vista que lo diga. Compara el job en `merged_yaml` con el padre: lo que coincide, salvo que el hijo lo repita, viene de él.
- **Un padre para las reglas y otro para el resto**: `extends: [.deploy, .solo-main]` con `.solo-main` que solo tiene `rules`. Pero si el job necesita **añadir** una regla, vuelves a `!reference`.
- **`!reference` en `variables`**: `variables: { X: !reference [.otro, variables, X] }` copia una sola variable de otro job sin heredar el job entero.

---

## 📚 Recursos Adicionales

- [Optimize GitLab CI/CD configuration files](https://docs.gitlab.com/ci/yaml/yaml_optimization/) — `extends`, anclas y `!reference`, con los detalles de fusión
- [`extends`](https://docs.gitlab.com/ci/yaml/#extends)
- [Hidden jobs](https://docs.gitlab.com/ci/jobs/#hide-a-job)

---

## ✅ Checklist de Verificación

- [ ] Sabes qué pasa con `variables` y con `script` cuando un hijo los redefine
- [ ] Sabes quitar una clave heredada
- [ ] Sabes componer la primera regla de un job con `!reference` y por qué `extends` no basta
- [ ] Sabes por qué un ancla de YAML no cruza un `include`

---

[← Anterior: `include`](01-include.md) · [Volver a la Semana 12](../README.md) · [Siguiente: `spec:inputs` →](03-spec-inputs.md)
