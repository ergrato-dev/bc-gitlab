# `include`: un pipeline en varios archivos

> `include` pega otros archivos YAML en tu pipeline antes de evaluarlo. No crea pipelines ni jobs nuevos: el resultado es **un** YAML, el mismo que si lo hubieras escrito en un archivo. Sirve para ordenar y para compartir, y casi todo lo que sale mal tiene que ver con cómo se fusionan las piezas.

---

## 🎯 Objetivos

- Partir un `.gitlab-ci.yml` en archivos con `include:local` sin cambiar lo que se ejecuta
- Elegir entre `local`, `project`, `remote` y `template`, y saber qué versión del archivo entra en cada caso
- Predecir el resultado de la fusión cuando dos archivos definen la misma clave
- Ver el YAML final con `merged_yaml` y la lista de archivos incluidos con `includes`

---

## 1. Qué problema resuelve

El `.gitlab-ci.yml` de `app` ha crecido una semana tras otra: `workflow`, `.npm`, `build`, `test`, `package`, `gobernanza`, `docs`, `caducidades`, `.deploy`, dos despliegues con su `resource_group` y el disparo a `infra/entornos`. Más de cien líneas, con tres tipos de cambio que no tienen nada que ver:

| Parte | Quién la cambia | Cada cuánto |
|---|---|---|
| Construir y probar | Quien desarrolla `app` | Cuando cambian las herramientas |
| Gobernanza | Quien gobierna el flujo | Casi nunca |
| Desplegar y disparar `infra` | Quien opera los entornos | Cuando cambia un entorno |

En un solo archivo, cada merge request que toca el despliegue enseña el diff en medio de la construcción, y CODEOWNERS no puede dar un dueño a cada parte: el dueño es del archivo entero. La Semana 11 ya separó `ci/docs.yml`, pero como **pipeline hijo**, porque la documentación tenía otro `workflow`. Para ordenar sin cambiar cuándo se ejecuta nada, la herramienta es `include` (Semana 11, teoría 03, apartado 4).

---

## 2. Cómo funciona

### 2.1 Cuatro orígenes

```yaml
include:
  - local: ci/deploy.yml                       # del mismo repositorio y el mismo commit
  - project: plataforma-<tu-dominio>/ci/plantillas
    ref: 1.0.0                                  # una rama, un tag o un SHA
    file: [deploy.yml]
  - remote: https://ejemplo.example/ci.yml      # una URL pública, sin autenticación
    integrity: sha256-<HASH_EN_BASE64>
  - template: Jobs/Code-Quality.gitlab-ci.yml   # las plantillas que trae GitLab
```

| Origen | Qué versión entra | Riesgo |
|---|---|---|
| `local` | La del mismo commit que el pipeline | Ninguno: viaja con el cambio |
| `project` | `ref`; sin `ref`, la punta de la rama por defecto de ese proyecto | Sin `ref` fijo, otro equipo cambia tu pipeline sin merge request en tu repositorio |
| `remote` | Lo que la URL devuelva al crear el pipeline | Cualquiera que controle la URL controla tu pipeline. `integrity` (desde 17.9) hace fallar el pipeline si el contenido cambia |
| `template` | La de la versión de GitLab instalada | Cambia cuando actualizas la instancia |

Una quinta forma, `component`, es un `include` con versión semántica y contrato: la teoría 04.

`include:local` admite comodines: `ci/*.yml` incluye los `.yml` de `ci/`, sin subcarpetas; `ci/**/*.yml`, también las subcarpetas. Cómodo y peligroso: un archivo nuevo en `ci/` entra en el pipeline sin que nadie lo nombre.

### 2.2 Permisos de `include:project`

El archivo se lee **con los permisos del usuario que crea el pipeline**, no con los del proyecto. Si el proyecto incluido es privado, ese usuario necesita al menos Reporter en él. Un Developer de `app` que no es nadie en el proyecto de plantillas rompe el pipeline de `app` con su primer push: `Project ... not found or access denied!`.

### 2.3 Cuándo se resuelve

Una vez, **al crear el pipeline**, en el servidor. El contenido queda guardado con el pipeline: si alguien cambia el archivo incluido un minuto después, ese pipeline no se entera, y un reintento de un job tampoco. El siguiente pipeline, sí.

Por eso en `include` solo valen las variables que existen antes de ejecutar nada: las de proyecto, grupo e instancia, las predefinidas `CI_PROJECT_*`, `CI_COMMIT_REF_NAME`, `CI_PIPELINE_SOURCE`, y las de un pipeline lanzado a mano o programado. Nunca una de `dotenv`, ni una que defina un job.

### 2.4 Cómo se fusiona

GitLab lee los `include` en orden, los fusiona entre sí (el último gana) y después fusiona el archivo principal **encima**. La fusión es profunda:

| Si la clave está en... | Resultado |
|---|---|
| Solo en lo incluido | Se queda |
| En los dos, y en los dos es un mapa | Se fusionan los mapas, clave a clave |
| En los dos, y en alguno no es un mapa | Gana el archivo principal, entero |

La tercera fila es la que sorprende: **las listas no se fusionan, se sustituyen**. `script`, `rules`, `needs` y `before_script` son listas.

```yaml
# ci/deploy.yml
deploy-staging:
  image: alpine:3.24.2
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# .gitlab-ci.yml
include:
  - local: ci/deploy.yml
deploy-staging:
  rules:
    - if: $CI_COMMIT_BRANCH =~ /^release\//
```

`deploy-staging` sale con `image: alpine:3.24.2` y **una** regla, la de `release/*`. La de `main` ha desaparecido.

### 2.5 Anidados y límites

Un archivo incluido puede incluir otros. Se fusionan primero los de más adentro. El límite es de **150 includes por pipeline** por defecto, contando los anidados. Si lo alcanzas, el problema no es el límite.

### 2.6 `include` con `rules`

```yaml
include:
  - local: ci/release.yml
    rules:
      - if: $CI_COMMIT_TAG
```

Solo admite `if`, `exists` y `changes`, y con las variables del apartado 2.3. Úsalo con cuidado: un archivo que entra a veces es un pipeline que cambia de forma según el contexto, y `merged_yaml` solo te enseña uno de los casos.

---

## 3. Cómo se configura

El resultado de la fusión lo da `ci/lint`. `merged_yaml` es el YAML final, el que ve el runner; `includes`, la lista de archivos que entraron y de dónde:

```bash
curl -s -H "$H" "$API/projects/$P/ci/lint?ref=main&include_merged_yaml=true" \
  | jq -c '.includes[] | {type, location}'
# {"type":"local","location":"ci/deploy.yml"}
```

Para comparar antes y después de partir un archivo, guarda los dos `merged_yaml` y compáralos con `diff`. Si lo único que has hecho es mover jobs, el diff solo tiene cambios de orden, no de contenido (práctica 01, paso 3).

En la UI: `Build → Pipeline editor → Full configuration` muestra el mismo `merged_yaml`, y el icono de cada `include` en la pestaña `Edit` abre el archivo incluido.

CODEOWNERS ya tiene `/ci/` con su dueño desde la Semana 11. Un archivo nuevo dentro de `ci/` lo hereda sin tocar nada.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `include:project` sin `ref` | El pipeline de `app` cambia cuando otro equipo empuja a su rama | `ref` con un tag, o un componente con versión |
| `include:remote` de una URL de terceros | Quien controle la URL ejecuta código en tu runner con tus secretos | Copia el archivo a tu instancia, o al menos `integrity` |
| Sobrescribir `rules` de un job incluido "para añadir una regla" | Las listas se sustituyen: pierdes las reglas originales sin aviso | `!reference` para componer la lista (teoría 02) |
| `ci/*.yml` en un repositorio donde muchos crean archivos | Un archivo nuevo entra en el pipeline sin que nadie lo vea | Nombrar cada archivo |
| Partir el YAML en diez archivos de diez líneas | Para entender un job hay que abrir cinco pestañas | Un archivo por dueño o por ritmo de cambio, no por job |
| Un pipeline hijo para ordenar | Crea pipelines, estados y permisos que no necesitas | `include`: no cambia cuándo se ejecuta nada |

---

## 5. Trucos

- **¿De dónde ha salido este job?** `includes[]` de `ci/lint` lleva `blob`, el enlace al archivo exacto en el commit exacto, también para un componente.
- **Probar un `include` antes de fusionarlo**: `GET .../ci/lint?content_ref=<rama>` lee `.gitlab-ci.yml` y sus `include:local` de esa rama; `?ref=` no cambia de rama. Con `POST` y un `content` propio, hace falta `dry_run: true` y `ref`. En los dos casos, de la rama empujada, no de tu disco.
- **Un `include` que no aparece**: si sus `rules` no se cumplen con las variables de `ci/lint`, no entra. `ci/lint` usa las de un push a ese `ref`.

---

## 📚 Recursos Adicionales

- [Use CI/CD configuration from other files](https://docs.gitlab.com/ci/yaml/includes/) — el método de fusión, en el apartado *Merge method for include*
- [`include`](https://docs.gitlab.com/ci/yaml/#include) y [`include:integrity`](https://docs.gitlab.com/ci/yaml/#includeintegrity)
- [Validate GitLab CI/CD configuration](https://docs.gitlab.com/ci/yaml/lint/)

---

## ✅ Checklist de Verificación

- [ ] Sabes qué versión de un archivo entra con `include:project` sin `ref`
- [ ] Sabes qué le pasa a la lista `rules` de un job incluido si la redefines en el archivo principal
- [ ] Sabes qué variables puedes usar dentro de `include` y por qué no las de `dotenv`
- [ ] Sabes leer `includes` y `merged_yaml` de `ci/lint`

---

[Volver a la Semana 12](../README.md) · [Siguiente: `extends` y `!reference` →](02-extends-y-reference.md)
