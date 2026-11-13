# Etiquetas priorizadas y exclusividad

> Una taxonomía sin reglas se degrada en un mes. CE no impone "una etiqueta por familia", así que la regla la impones tú: el tablero la aplica al mover y la API la vigila.

## 🎯 Objetivos

- Priorizar etiquetas en un proyecto y ordenar el backlog por esa prioridad
- Distinguir la prioridad de una etiqueta de la familia `prioridad::`
- Explicar los tres mecanismos de CE que mantienen una familia exclusiva
- Escribir la comprobación por API que detecta un issue con dos etiquetas de la misma familia
- Saber cuándo una violación de exclusividad es un error de datos y cuándo un error de proceso

---

## 1. Qué problema resuelve

Dos problemas distintos que se resuelven juntos.

**El primero es el orden.** Un backlog de quince issues cabe en una pantalla. Uno de ochenta, no. Cuando alguien termina un issue y pregunta "¿cuál cojo ahora?", la respuesta tiene que salir del propio listado, no de una reunión. Para eso el listado necesita un orden que signifique algo.

**El segundo es la coherencia.** Con la taxonomía de la teoría [02](02-taxonomia-de-etiquetas.md), un issue debería tener una sola etiqueta `prioridad::`. En Premium lo garantiza GitLab. En CE nadie lo garantiza, y basta un reetiquetado descuidado para que un issue sea a la vez `prioridad::alta` y `prioridad::baja`. A partir de ese momento el filtro "prioridad alta" devuelve un issue de prioridad baja, y el tablero lo pinta en dos columnas.

---

## 2. Etiquetas priorizadas

### 2.1 Qué son

Cada proyecto puede marcar algunas etiquetas como **priorizadas** y ordenarlas entre sí. Es una característica Free y es **del proyecto**: la misma etiqueta de grupo puede estar priorizada en `app` y no en `infra`.

Cuando un listado de issues se ordena por **Label priority**, GitLab coloca primero los issues que llevan la etiqueta priorizada más alta, luego los de la siguiente, y al final los que no llevan ninguna priorizada.

### 2.2 Prioridad de etiqueta no es la familia `prioridad::`

Son dos cosas con un nombre parecido:

| | Familia `prioridad::` | Etiqueta priorizada |
|---|---|---|
| Qué es | Una etiqueta que pones en un issue | Una propiedad de la **etiqueta**, en un proyecto |
| Dónde se ve | En el issue | En el orden del listado |
| Quién la decide | Quien tría el issue | Quien mantiene el proyecto, una vez |

La combinación útil es priorizar **las etiquetas de la familia `prioridad::`**, en su orden natural: `prioridad::alta` primero, `prioridad::media` después, `prioridad::baja` al final. Con eso, "ordenar por prioridad de etiqueta" hace exactamente lo que dice.

Y se puede añadir `tipo::bug` por encima de todas, si en tu proyecto un fallo conocido va siempre antes que una funcionalidad nueva. Esa es una decisión de equipo, y queda escrita en la configuración del proyecto en vez de en la memoria de alguien.

### 2.3 Cómo se configura

**Con la UI**: `Proyecto → Manage → Labels`, botón de la estrella junto a cada etiqueta, y arrastrar dentro de *Prioritized labels* para ordenar.

Priorizar es la única modificación que el proyecto puede hacer sobre una etiqueta heredada del grupo, y no afecta a los demás proyectos.

**Con la API**, solo a medias. El campo `priority` existe en `PUT /projects/:id/labels/:label_id`, y **menor número es más prioridad**, pero ese endpoint busca la etiqueta **solo entre las del proyecto**, sin las heredadas. Con una etiqueta de grupo devuelve `404 Label Not Found`:

```bash
source ~/.bc-gitlab
H="PRIVATE-TOKEN: $GITLAB_TOKEN"; API="$GITLAB_URL/api/v4"
P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

curl -s --request PUT "$API/projects/$P/labels/prioridad::alta" -H "$H" \
  --data-urlencode "priority=0" | jq .
# { "message": "404 Label Not Found" }   ← si prioridad::alta es del grupo
```

Está en el código de la instancia: el helper `update_label` llama a `find_label` con `include_ancestor_groups: false`. Con una etiqueta **del proyecto**, en cambio, funciona, y `priority=` vacío le quita la prioridad.

> [!IMPORTANT]
> Como tu taxonomía vive en el grupo raíz, **la prioridad se pone desde la UI**, con la estrella. Es de las pocas cosas de este bootcamp que no tienen camino por API REST ni por GraphQL en 19.2. Lo que sí tiene API es la **lectura**, y eso basta para verificarlo.

Leer la prioridad:

```bash
curl -s -H "$H" "$API/projects/$P/labels?per_page=100" \
  | jq -r 'map(select(.priority != null)) | sort_by(.priority)[] | "\(.priority)\t\(.name)"'
```

El campo `priority` solo lo devuelve el endpoint del **proyecto**. En `GET /groups/:id/labels` no aparece, porque la prioridad no es del grupo.

---

## 3. Exclusividad sin Premium

En CE hay tres mecanismos que, juntos, mantienen una familia exclusiva. Ninguno basta solo.

### 3.1 El tablero, al mover

Cuando arrastras una tarjeta de la columna `estado::preparado` a la columna `estado::en-curso`, GitLab **quita la etiqueta de la columna de origen y pone la de la de destino**. Es un reetiquetado atómico, y por eso el tablero mantiene la familia `estado::` coherente siempre que se use para moverla.

Lo mismo hace la acción rápida `/board_move ~"estado::en-curso"`, que quita del issue **todas** las etiquetas que son columna de algún tablero del proyecto y pone la indicada. Tiene una condición, sacada del código de la instancia: solo está disponible si el proyecto tiene **exactamente un** tablero.

Límite: solo protege las familias que son columnas. `tipo::` y `prioridad::` no lo son.

### 3.2 `/relabel` en vez de `/label`

`/label ~"prioridad::baja"` **añade** una etiqueta y deja las que hubiera. `/relabel ~"tipo::bug" ~"prioridad::baja"` **sustituye** todas las etiquetas del issue por las indicadas.

| Acción | Efecto | Riesgo |
|---|---|---|
| `/label ~"prioridad::baja"` | Añade | Deja `prioridad::alta` puesta: dos de la misma familia |
| `/unlabel ~"prioridad::alta"` + `/label ~"prioridad::baja"` | Cambia una | Ninguno, si no se olvida la primera línea |
| `/relabel ~"tipo::bug" ~"prioridad::baja"` | Sustituye todas | Borra las `area::` si no se repiten |

La costumbre segura al cambiar una prioridad son las dos líneas juntas, `/unlabel` y `/label`, en el mismo comentario.

### 3.3 La comprobación por API

Los dos mecanismos anteriores evitan el error; este lo **detecta**. Es una expresión de `jq` sobre el listado de issues abiertos:

```bash
curl -s -H "$H" "$API/projects/$P/issues?issue_type=issue&state=opened&per_page=100" \
  | jq -r '.[] | select([.labels[] | select(startswith("prioridad::"))] | length > 1)
           | "#\(.iid)\t\(.labels | join(", "))"'
```

Si no imprime nada, la familia está sana. Si imprime algo, cada línea es un issue que arreglar.

La misma idea, en forma de booleano, es la que usa el autograding de esta semana:

```bash
... | jq 'all(.[]; ([.labels[] | select(startswith("prioridad::"))] | length) <= 1)'
# true
```

Y para `tipo::` la regla es más estricta: **exactamente una**, porque un issue sin tipo tampoco está triado.

> [!TIP]
> En la Semana 11 esta comprobación pasa a un **pipeline programado** que se ejecuta cada noche, y en la Semana 17 a un script del proyecto `ci/automatizacion` que comenta en el issue culpable. Ahora la ejecutas a mano; lo importante es que ya existe y es una línea.

---

## 4. Error de datos o error de proceso

Cuando la comprobación encuentra un issue con dos `prioridad::`, hay dos lecturas posibles, y conviene no confundirlas:

| Si… | Es un error de… | Se arregla… |
|---|---|---|
| Pasa una vez, en un issue antiguo | Datos | Quitando una de las dos, a mano |
| Pasa cada semana, en issues nuevos | Proceso | Cambiando cómo se reetiqueta: plantillas con `/relabel`, tablero para `estado::` |
| Pasa en issues creados por API | Herramienta | Revisando el script que los crea |

Corregir los datos sin mirar el proceso convierte la comprobación en un trabajo semanal.

---

## 5. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Priorizar todas las etiquetas | El orden deja de significar nada | Solo la familia `prioridad::`, y como mucho `tipo::bug` encima |
| `/label` para cambiar una prioridad | Deja dos de la misma familia | `/unlabel` y `/label` en el mismo comentario |
| Mover el estado reetiquetando a mano | Salta la exclusividad que da el tablero | Arrastrar en el tablero, o `/board_move` |
| Varios tableros "por si acaso" | `/board_move` deja de estar disponible | Un tablero, salvo necesidad real |
| Confiar en que "ya lo hará Premium" | La instancia es CE y lo va a seguir siendo | Comprobación por API |
| Arreglar las violaciones sin preguntar por qué pasan | Vuelven la semana siguiente | Mirar si es datos, proceso o herramienta |

---

## 6. Trucos

- **El orden por prioridad de etiqueta se queda en la URL**: elige *Label priority* en el desplegable de orden del listado de issues y copia la URL del navegador. Es el enlace que pones en la portada de la wiki como "qué hacer ahora".
- **En la API**, `order_by=label_priority` en `GET /projects/:id/issues` devuelve el mismo orden. Útil para un script que diga "el siguiente issue es #N".
- **Encontrar issues sin tipo**: `.../issues?state=opened&issue_type=issue&per_page=100 | jq -r '.[] | select(any(.labels[]; startswith("tipo::")) | not) | .iid'`.

---

## 📚 Recursos Adicionales

- [Etiquetas priorizadas](https://docs.gitlab.com/ee/user/project/labels.html#set-label-priority) — cómo se ordena y qué se puede priorizar
- [Acciones rápidas](https://docs.gitlab.com/ee/user/project/quick_actions.html) — `/label`, `/unlabel`, `/relabel`, `/board_move`
- [Etiquetas con ámbito](https://docs.gitlab.com/ee/user/project/labels.html#scoped-labels) — lo que hace Premium, para saber qué se está sustituyendo

---

## ✅ Checklist de Verificación

- [ ] La familia `prioridad::` está priorizada en `app`, en su orden natural
- [ ] El listado de issues ordenado por *Label priority* pone primero los de prioridad alta
- [ ] Sabes por qué `/board_move` deja de funcionar con dos tableros
- [ ] Has ejecutado la comprobación de exclusividad y sabes leer su salida
- [ ] Puedes distinguir una violación de datos de una de proceso

---

[← Anterior: Taxonomía de etiquetas](02-taxonomia-de-etiquetas.md) · [Volver a la Semana 05](../README.md) · [Siguiente: Hitos →](04-hitos.md)
