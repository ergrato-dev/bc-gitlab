# Etiquetas, digests y protección

> Un tag de imagen es una etiqueta adhesiva: cualquiera con permiso de escritura puede despegarla y pegarla en otra imagen. Esta teoría decide qué tags lleva cada imagen de `app`, cuáles se pueden mover y cuáles no, y quién puede escribir los que importan.

---

## 🎯 Objetivos

- Elegir los tags de una imagen según de dónde sale: rama, merge request o tag de Git
- Explicar por qué `latest` no aparece en ningún pipeline de este bootcamp
- Proteger los tags de versión con reglas de protección del registry
- Distinguir tags protegidos (Free) de tags inmutables (Ultimate)

---

## 1. Qué problema resuelve

Sin una convención, cada pipeline sube lo que se le ocurre: `app:dev`, `app:prueba`, `app:latest`, `app:final2`. Al mes nadie sabe cuál está en `staging`, la limpieza no sabe qué borrar, y un Developer puede subir `app:0.2.0` desde su rama y sustituir la versión publicada sin que nadie lo note.

---

## 2. Cómo funciona

### 2.1 Qué tag lleva cada imagen

| Origen del pipeline | Tags | Se puede borrar | Ejemplo |
|---|---|:--:|---|
| Merge request | Ninguno: se construye con `--no-push` | — | — |
| `main` | El SHA corto | ✅ por la limpieza | `app:3f2a9c1e` |
| Tag `v0.2.0` | El SHA corto y la versión **sin `v`** | La versión, nunca | `app:3f2a9c1e`, `app:0.2.0` |

- **El SHA corto** (`$CI_COMMIT_SHORT_SHA`, ocho caracteres) une la imagen con el commit sin consultar nada. Es lo que la limpieza borra.
- **La versión sin `v`**: los tags de Git de `app` llevan `v` desde la Semana 08; los de imagen no, por la convención de Docker y porque la limpieza (teoría 04) la reconoce con una sola expresión. `${CI_COMMIT_TAG#v}` la quita.
- **En una merge request no se sube nada**: el código aún no está revisado. Se construye para saber que el `Dockerfile` funciona.

### 2.2 Por qué no `latest`

| `latest` promete | Lo que hace en realidad |
|---|---|
| "La última versión" | Apunta a lo último que alguien subió con ese tag, sea lo que sea |
| Comodidad al desplegar | Un despliegue que cambia solo al reiniciarse un contenedor |
| — | La limpieza **nunca** lo borra: es la primera regla de la política (teoría 04) |

Es la misma regla que el repositorio aplica a sus propias imágenes desde la Semana 01. Quien quiera "la última versión" la pide por API: el último tag que cumple semver.

### 2.3 Etiquetas OCI

Además de tags, una imagen lleva **etiquetas** (*labels*) en su configuración. Dos estándar, y kaniko las pone con `--label`:

| Etiqueta | Valor |
|---|---|
| `org.opencontainers.image.revision` | `$CI_COMMIT_SHA`: el commit completo, aunque el tag sea el corto |
| `org.opencontainers.image.source` | `$CI_PROJECT_URL`: de dónde salió |

Las lee cualquier herramienta, sin GitLab. El escáner de la Semana 19 y la firma de la Semana 20 las usan.

### 2.4 Tags protegidos

Una regla de protección dice qué rol mínimo puede **subir** y **borrar** los tags que cumplen una expresión. Es Free, y necesita la base de metadatos del registry (teoría 01, apartado 2.5).

```bash
curl -s --request POST "$API/projects/$P/registry/protection/tag/rules" -H "$H" \
  -H "Content-Type: application/json" \
  -d '{"tag_name_pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$",
       "minimum_access_level_for_push": "maintainer",
       "minimum_access_level_for_delete": "maintainer"}'
```

| Campo | Valores | Obligatorio |
|---|---|:--:|
| `tag_name_pattern` | Expresión RE2 | ✅ |
| `minimum_access_level_for_push` | `maintainer`, `owner`, `admin` | ✅ |
| `minimum_access_level_for_delete` | `maintainer`, `owner`, `admin` | ✅ |

Encaja con lo que ya tenías:

- Los tags de Git `v*` de `app` solo los crea un Maintainer (Semana 07).
- El job que sube `app:0.2.0` corre con los permisos de quien creó el tag de Git: un Maintainer.
- Un Developer que intente subir `app:0.3.0` lo ve rechazado por el propio registry: `insufficient permissions to push or delete protected tag - tag "0.3.0" is protected`. Su `app:3f2a9c1e` sí entra.
- La limpieza **no borra** tags protegidos, aunque cumplan todas sus condiciones.

### 2.5 Lo que no es CE

| Funcionalidad | Tier | Qué haces en CE |
|---|---|---|
| Tags protegidos | Free | Lo de arriba |
| Repositorios protegidos (`registry/protection/repository/rules`) | Free | Proteger una ruta entera; los deploy tokens no pueden subir a ella |
| **Tags inmutables**: nadie, ni un Owner, puede sobrescribirlos ni borrarlos | **Ultimate** | Tags protegidos para Maintainer, y los Maintainer de `app` son pocos |

En CE, la API lo deja claro: una regla sin niveles de acceso, que es como se declara una inmutable, se rechaza con `minimum_access_level_for_push is missing`.

---

## 3. Cómo se configura

Varios tags con una sola construcción:

```bash
DESTINOS="--destination $REGISTRO/$RUTA:$CI_COMMIT_SHORT_SHA"
if [ -n "$CI_COMMIT_TAG" ]; then
  DESTINOS="$DESTINOS --destination $REGISTRO/$RUTA:${CI_COMMIT_TAG#v}"
fi
/kaniko/executor … $DESTINOS
```

Las reglas que tienes:

```bash
curl -s -H "$H" "$API/projects/$P/registry/protection/tag/rules" \
  | jq -c '.[] | {tag_name_pattern, minimum_access_level_for_push, minimum_access_level_for_delete}'
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `latest` | Se mueve solo y la limpieza no lo toca | SHA y versión |
| Tags con nombre de rama (`app:main`) | Otro tag que se mueve | El SHA corto |
| Subir imágenes desde merge requests | Código sin revisar en el registry, y basura para la limpieza | `--no-push` |
| `0.2.0` sin proteger | Un Developer puede sustituir la versión publicada | Regla para Maintainer |
| `v0.2.0` como tag de imagen | Dos convenciones en las expresiones de limpieza y protección | `${CI_COMMIT_TAG#v}` |

---

## 5. Trucos

- **Qué commit lleva una imagen**: `docker pull localhost:5050/…/app:0.2.0` y `docker inspect --format '{{json .Config.Labels}}' localhost:5050/…/app:0.2.0`.
- **Comprobar una expresión de protección o de limpieza** antes de guardarla: `printf '0.2.0\n3f2a9c1e\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'`.

---

## 📚 Recursos Adicionales

- [Protected container tags](https://docs.gitlab.com/user/packages/container_registry/protected_container_tags/)
- [Container repository protection rules](https://docs.gitlab.com/user/packages/container_registry/container_repository_protection_rules/)
- [Immutable container tags](https://docs.gitlab.com/user/packages/container_registry/immutable_container_tags/) — Ultimate
- [OCI image annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md)

---

## ✅ Checklist de Verificación

- [ ] Sabes qué tags lleva la imagen de un pipeline de `main` y la de uno de tag
- [ ] Sabes tres razones para no usar `latest`
- [ ] Sabes qué impide una regla de tags protegidos y qué no
- [ ] Sabes qué añade Ultimate con los tags inmutables

---

[← Anterior: Construir imágenes sin privilegios](02-construir-sin-privilegios.md) · [Volver a la Semana 13](../README.md) · [Siguiente: La limpieza →](04-la-limpieza.md)
