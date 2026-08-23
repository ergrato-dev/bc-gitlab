# Mover y renombrar sin romper

> GitLab redirige las URLs antiguas. No redirige tus imágenes, tus paquetes, tus componentes ni tus scripts. Saber dónde está la frontera es lo que separa una transferencia de un incidente.

## 🎯 Objetivos

- Transferir un proyecto a otro namespace y un grupo a otro padre
- Consultar los destinos válidos antes de intentar la operación
- Distinguir lo que se redirige solo de lo que hay que arreglar a mano
- Renombrar sin transferir, y saber cuándo eso basta

---

## 1. Qué problema resuelve

El árbol que dibujaste en enero deja de servir en marzo: un proyecto pertenece a otro equipo, dos áreas se fusionan, un subgrupo se queda vacío. La alternativa a mover —crear un proyecto nuevo y empujar el código— pierde issues, merge requests, pipelines, releases y toda la trazabilidad. Es decir, pierde justo lo que hace que valga la pena tener GitLab.

Transferir conserva **todo el contenido de la base de datos**. Lo que cambia es la ruta, y lo que la ruta toca. Por eso la operación es barata en GitLab y cara en todo lo que apunta a GitLab desde fuera.

---

## 2. Cómo funciona

### 2.1 Transferir un proyecto

**Con la interfaz**: `Proyecto → Settings → General → Advanced → Transfer project`. Pide escribir el nombre del proyecto para confirmar.

**Con la API** —fíjate en que es `PUT`, no `POST`:

```bash
source ~/.bc-gitlab
P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

# Primero: ¿a dónde puedo moverlo de verdad?
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$P/transfer_locations" \
  | jq -r '.[].full_path'

# Después: moverlo
curl -s --request PUT "$GITLAB_URL/api/v4/projects/$P/transfer" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "namespace=plataforma-biblioteca/infra" \
  | jq '{path_with_namespace}'
```

`transfer_locations` es la lista real de namespaces donde tienes rol suficiente para recibir el proyecto. Consultarla antes evita el `400 Bad Request` genérico que devuelve el destino inválido.

Requisitos que se olvidan y hacen fallar la operación:

- Necesitas **Maintainer o más en el proyecto** y **rol suficiente en el namespace de destino** (Maintainer u Owner, según cómo esté el `project_creation_level`).
- El destino no puede tener ya un proyecto con esa ruta.
- El destino tiene que admitir la visibilidad del proyecto: uno `internal` no cabe en un grupo `private` (teoría [06](06-visibilidad-quien-ve-que.md)). Restringe primero el proyecto, transfiere después.

### 2.2 Transferir un grupo

```bash
# A dónde puede ir este grupo
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/groups/$SUBID/transfer_locations" \
  | jq -r '.[].full_path'

# Convertirlo en subgrupo de otro
curl -s --request POST "$GITLAB_URL/api/v4/groups/$SUBID/transfer" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data-urlencode "group_id=$OTRO_GID" | jq '{full_path}'

# Sin group_id: lo convierte en grupo raíz
curl -s --request POST "$GITLAB_URL/api/v4/groups/$SUBID/transfer" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" | jq '{full_path}'
```

Mover un grupo mueve **todo su árbol**: subgrupos, proyectos, y las rutas de todos ellos. Es la operación con más radio de impacto de esta semana, y la que conviene ensayar en un grupo de pruebas antes de hacerla sobre nada real.

### 2.2.1 Qué viaja con el proyecto y qué se queda

Una transferencia conserva el contenido, pero **cambia de padre**, y todo lo que venía del padre viejo deja de aplicar:

| Elemento | Al transferir |
|---|---|
| Commits, issues, merge requests, pipelines, releases, wiki | Viajan enteros |
| Miembros **directos** del proyecto | Viajan |
| Miembros **heredados** del grupo antiguo | Se pierden. Los del grupo nuevo empiezan a aplicar |
| Variables de CI/CD **del proyecto** | Viajan |
| Variables de CI/CD **del grupo** antiguo | Dejan de aplicar; los pipelines fallan por variables ausentes (S10) |
| Runners de grupo | Dejan de servir al proyecto; sirven los del grupo nuevo (S15) |
| Etiquetas e hitos de grupo usados por los issues | Se convierten en etiquetas e hitos del proyecto |
| Imágenes y paquetes ya publicados | Su ruta antigua queda huérfana (S13) |

El renglón peligroso es el de las variables de grupo: nada falla en el momento de transferir. Falla en el siguiente pipeline, con un mensaje sobre una variable vacía que no menciona la transferencia por ningún lado.

### 2.3 Qué se redirige solo

GitLab guarda las rutas antiguas y redirige. La cobertura es buena y no es total:

| Qué | ¿Se redirige? | Detalle |
|---|:--:|---|
| URL web del proyecto o grupo | ✅ | Redirección permanente a la ruta nueva |
| `git clone` / `git push` por HTTP y SSH | ✅ | Git sigue funcionando con el remoto viejo, con un aviso |
| Llamadas a la API con la ruta antigua | ✅ | Resuelven mientras la ruta antigua no la ocupe otro |
| Imágenes del Container Registry | ❌ | La ruta de la imagen **es** la ruta del proyecto (S13) |
| Paquetes del Package Registry | ❌ | Mismo motivo; hay que republicar o reapuntar (S13) |
| Componentes CI/CD incluidos por ruta | ❌ | El `include: component:` de otros proyectos deja de resolver (S12) |
| Insignias y `pipeline.svg` incrustados | ❌ | La URL sigue existiendo por redirección, pero el markdown queda mintiendo |
| Webhooks y integraciones apuntando al proyecto | ⚠️ | Siguen configurados; lo que apunta **hacia** GitLab desde fuera hay que revisarlo |
| Tu `~/.bc-gitlab` y los scripts del bootcamp | ❌ | `PROYECTO=` es texto en un archivo tuyo |

> [!WARNING]
> **La redirección se pierde en cuanto alguien ocupa la ruta antigua.** Si mueves `plataforma-biblioteca/app` y luego creas otro proyecto con ese mismo nombre, las redirecciones dejan de funcionar y los clones antiguos empiezan a hablar con el proyecto equivocado. Es la razón por la que la ruta liberada no se reutiliza.

### 2.4 Renombrar sin mover

Son dos operaciones distintas y la confusión sale cara:

| Cambias | Campo | Consecuencia |
|---|---|---|
| El nombre visible | `name` | Cosmético. No toca ninguna URL |
| La ruta | `path` | Cambia todas las URLs. Equivale a una transferencia dentro del mismo padre |

```bash
# Solo cosmético
curl -s --request PUT "$GITLAB_URL/api/v4/projects/$P" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" --data-urlencode "name=App de Biblioteca" | jq '{name, path}'

# Esto sí cambia URLs
curl -s --request PUT "$GITLAB_URL/api/v4/projects/$P" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" --data-urlencode "path=app-biblioteca" | jq '{name, path_with_namespace}'
```

En este bootcamp **la ruta de `app` no se toca**: está en `~/.bc-gitlab`, en tus remotos y en las quince comprobaciones del autograding. El nombre visible, en cambio, es libre.

### 2.5 El caso del fork

Un fork es un proyecto nuevo en **otro namespace** que mantiene una relación con el original: comparte objetos de Git en disco y permite abrir merge requests hacia arriba. Es la vía normal para que alguien con rol de solo lectura proponga cambios sin poder escribir en el repositorio.

```bash
# ¿Este proyecto es un fork? ¿De quién?
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$P" \
  | jq '{forked_from: .forked_from_project.path_with_namespace, forks_count}'
```

Dos consecuencias que tocan lo de esta semana:

- **El fork hereda los permisos de su nuevo namespace, no los del original.** Quien forkea a su espacio personal se convierte en Owner de la copia, con todo lo que eso implica; el código privado que se lleva deja de estar bajo tu control de accesos.
- **Transferir o borrar el proyecto original no borra los forks.** La relación se rompe (`DELETE /projects/:id/fork`), pero las copias siguen existiendo con su historia completa.

En este bootcamp no se forkea: hay un solo proyecto y un solo árbol. El mecanismo se menciona porque es la respuesta correcta a "quiero que un externo proponga cambios sin darle Developer", y porque es la vía por la que el código privado sale de un namespace sin que nadie mueva nada.

---

## 3. Cómo se hace una transferencia sin sustos

Un procedimiento corto y suficiente:

1. **Inventario de lo que apunta al proyecto**: remotos de los clones, imágenes publicadas, paquetes, componentes incluidos desde otros proyectos, insignias en README, webhooks, y tu propia configuración.
2. **Comprobar el destino**: `transfer_locations`, y que la ruta esté libre (`namespaces/:id/exists`).
3. **Avisar**: quien tenga un clon va a ver el aviso de redirección; mejor que sepa por qué.
4. **Transferir** y comprobar `path_with_namespace` en la respuesta.
5. **Reapuntar lo que no se redirige**: `git remote set-url`, `PROYECTO=` en `~/.bc-gitlab`, insignias, componentes.
6. **Verificar**: `./scripts/verificar-semana.sh 03` sigue en verde, y un `git fetch` desde un clon antiguo funciona.

El paso 1 es el que se salta todo el mundo y el único que evita el incidente.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Mover un proyecto porque el árbol "queda más bonito" | Todo lo que apunta desde fuera se rompe a cambio de estética | Mover solo cuando cambia de dueño de verdad |
| Reutilizar la ruta antigua para otro proyecto | Mata las redirecciones y desvía clones antiguos al proyecto equivocado | Dejar la ruta libre |
| Renombrar la ruta creyendo que es cosmético | `path` cambia URLs; `name` no | Cambiar `name` si lo que quieres es que se lea mejor |
| Transferir sin mirar `transfer_locations` | Un `400` sin explicación y media hora perdida | Consultar la lista primero |
| Recrear el proyecto en vez de transferirlo | Se pierden issues, merge requests, pipelines y releases | Transferir, que conserva todo eso |
| Mover un grupo entero sin ensayo | Arrastra todos los descendientes y todas sus rutas | Ensayar con un grupo de pruebas, y luego borrarlo |

---

## 5. Trucos

- **Destinos válidos, no imaginados**: `GET /projects/:id/transfer_locations` y `GET /groups/:id/transfer_locations`.
- **Ver si una ruta antigua sigue redirigiendo**: `curl -sI "$GITLAB_URL/<ruta-antigua>" | head -1` devuelve `302` mientras la redirección viva.
- **Arreglar un clon después de mover**: `git remote set-url origin <url-nueva>` — Git avisa de la redirección pero no la guarda.
- **Buscar dónde se incrusta la ruta antigua**: `grep -rn "plataforma-biblioteca/app" .` en tus repositorios y en la documentación. Es el paso 1 hecho en un comando.
- **Diferenciar mover de renombrar en la respuesta**: mira `path_with_namespace`. Si cambió el prefijo, moviste; si cambió el último segmento, renombraste.

---

## 📚 Recursos Adicionales

- [Transferir un proyecto](https://docs.gitlab.com/ee/user/project/settings/migrate_projects.html) — requisitos y consecuencias
- [Transferir un grupo](https://docs.gitlab.com/ee/user/group/manage.html#transfer-a-group) — el caso del árbol entero
- [API de proyectos — transfer](https://docs.gitlab.com/ee/api/projects.html#transfer-a-project-to-a-new-namespace) — el `PUT` y sus errores

---

## ✅ Checklist de Verificación

- [ ] Sabes qué método HTTP transfiere un proyecto y cuál transfiere un grupo
- [ ] Sabes qué se redirige solo y qué no, y puedes nombrar tres cosas de cada lista
- [ ] Sabes por qué la ruta de `app` no se toca en este bootcamp
- [ ] Puedes decir la diferencia entre cambiar `name` y cambiar `path`

---

[← Anterior: Visibilidad](06-visibilidad-quien-ve-que.md) · [Volver a la Semana 03](../README.md) · [Siguiente: Diseñar el árbol →](08-disenar-el-arbol-con-menor-privilegio.md)
