# Licencia y procedencia

> Un repositorio sin licencia no es libre: es "todos los derechos reservados" con el código a la vista.

## 🎯 Objetivos

- Explicar qué puede hacer legalmente alguien con un repositorio sin licencia
- Elegir entre las tres familias de licencia libre con un criterio que se pueda defender
- Aplicar la licencia desde la plantilla que sirve tu propia instancia
- Comprobar que GitLab la ha detectado, y saber por qué a veces no la detecta
- Decir qué parte del cumplimiento de licencias es de pago y con qué se sustituye en CE

---

## 1. Qué problema resuelve

El derecho de autor se aplica por defecto y sin registrar nada: en cuanto escribes código, es tuyo y **nadie más puede copiarlo, modificarlo ni redistribuirlo**. Publicarlo en un repositorio visible no cambia eso. La licencia es el permiso explícito que dice qué sí se puede hacer.

Consecuencias prácticas de no tener una:

- Nadie puede usar tu código legalmente, ni siquiera aunque lo tenga delante
- Ninguna empresa con departamento legal aceptará una dependencia sin licencia
- Un contribuidor externo no sabe bajo qué términos entrega su parche
- Tú mismo, dentro de dos años y en otra empresa, no puedes reutilizarlo con seguridad

Y en el sentido contrario: si tu proyecto es interno y **no** quieres que se redistribuya, eso también hay que escribirlo. Un `LICENSE` que dice "propiedad de X, uso interno" informa igual de bien que uno permisivo, y evita la ambigüedad que se acaba resolviendo preguntando a alguien de legal.

> [!NOTE]
> Este bootcamp construye un proyecto de laboratorio en una instancia privada. Aun así se le pone licencia, por la misma razón por la que se firman los commits en un repositorio que solo tú ves: el hábito viaja al trabajo real, y ahí sí importa.

---

## 2. Cómo funciona

### 2.1 Las tres familias

| Familia | Ejemplos | Qué exige a quien la usa | Cuándo compensa |
|---|---|---|---|
| **Permisiva** | MIT, BSD-3-Clause, Apache-2.0 | Conservar el aviso de copyright | Quieres máxima adopción, incluida la comercial y cerrada |
| **Copyleft débil** | MPL-2.0, LGPL-3.0 | Publicar los cambios **sobre tus archivos**, no sobre todo el programa | Librería que quieres que siga siendo libre sin obligar al que la enlaza |
| **Copyleft fuerte** | GPL-3.0, AGPL-3.0 | Publicar el código de la obra derivada entera | Quieres que las mejoras vuelvan; AGPL cubre además el uso como servicio en red |

Dos matices que deciden la mayoría de los casos reales:

- **MIT contra Apache-2.0**: las dos son permisivas y casi equivalentes en la práctica. Apache-2.0 añade una **concesión expresa de patentes** y una cláusula que la retira si quien la recibe te demanda por patentes. Si el proyecto puede tocar algo patentable, o si va a usarlo una empresa grande, Apache-2.0 es la respuesta prudente. Si buscas el texto más corto que todo el mundo reconoce, MIT.
- **GPL-3.0 contra AGPL-3.0**: la GPL se activa cuando **distribuyes** el programa. Si tu software solo se ofrece como servicio web, nunca lo distribuyes, y la GPL no obliga a publicar nada. La AGPL cierra ese hueco: usarlo a través de la red cuenta.

> [!IMPORTANT]
> Elegir licencia no es un trámite de última hora. Cambiarla después exige el consentimiento de **todos** los que han contribuido, porque cada uno entregó su parte bajo la licencia que había entonces. En un proyecto de una persona es un commit; en uno de treinta, un proyecto en sí mismo.

### 2.2 Cómo detecta GitLab la licencia

GitLab usa **Licensee**, la misma librería que emplea GitHub. El procedimiento tiene tres partes y las tres importan:

1. Busca en la raíz un archivo que encaje con el patrón `LICENSE`, `LICENCE`, `COPYING` o `UNLICENSE`, con o sin extensión (`Gitlab::FileDetector`).
2. Normaliza su contenido —quita el año, el titular y los espacios de más— y lo compara con el texto de las licencias conocidas.
3. Si el parecido supera el umbral, devuelve la licencia identificada. Si no, no devuelve nada.

Por eso **el archivo tiene que llevar el texto completo y sin retocar**. Un `LICENSE` que dice solo "MIT" no se detecta: no se parece al texto de la MIT. Uno con un párrafo añadido en medio, tampoco.

Lo que devuelve la API cuando lo consigue:

```bash
source ~/.bc-gitlab
H="PRIVATE-TOKEN: $GITLAB_TOKEN"; API="$GITLAB_URL/api/v4"
P=$(printf '%s' "$PROYECTO" | jq -sRr @uri)

curl -s -H "$H" "$API/projects/$P?license=true" | jq '{license, license_url}'
```

```json
{
  "license": {
    "key": "mit",
    "name": "MIT License",
    "nickname": null,
    "html_url": "http://choosealicense.com/licenses/mit/",
    "source_url": null
  },
  "license_url": "http://localhost:8888/plataforma-biblioteca/app/-/blob/main/LICENSE"
}
```

`key` es el identificador **SPDX en minúsculas**: `mit`, `apache-2.0`, `gpl-3.0`, `agpl-3.0`, `mpl-2.0`. Lo entiende cualquier herramienta de inventario, y es el que aparecerá en el SBOM de la Semana 20.

> [!WARNING]
> Sin `?license=true` los campos `license` y `license_url` **no aparecen en la respuesta**, y su ausencia se parece mucho a "no hay licencia". No lo es. Es el error más frecuente al escribir la comprobación de esta semana.

### 2.3 Las plantillas las sirve tu instancia

No hace falta buscar el texto en internet: tu GitLab trae las licencias dentro y las sirve por API, ya con tu nombre y el del proyecto sustituidos.

```bash
# Las disponibles, solo las populares
curl -s -H "$H" "$API/templates/licenses?popular=true" | jq -r '.[] | "\(.key)\t\(.name)"'

# El texto de una, con los huecos rellenos
curl -s -H "$H" "$API/templates/licenses/mit?project=app&fullname=Tu%20Nombre" \
  | jq -r '.content' | head -5
```

```
MIT License

Copyright (c) 2026 Tu Nombre

Permission is hereby granted, free of charge, to any person obtaining a copy
```

La respuesta de una plantilla trae además tres listas que permiten decidir sin leerse el texto legal entero:

```bash
curl -s -H "$H" "$API/templates/licenses/apache-2.0" \
  | jq '{permissions, conditions, limitations}'
```

**Con la interfaz**: en un repositorio sin licencia, la portada del proyecto ofrece un botón `Add LICENSE` que abre el mismo catálogo.

### 2.4 Procedencia: de dónde viene lo que no escribiste

La licencia de tu código es la mitad. La otra mitad es la de tus dependencias: un proyecto MIT que depende de una librería GPL-3.0 y la distribuye junta hereda obligaciones que no puso en su `LICENSE`.

Esta semana solo deja el terreno preparado, con dos cosas baratas:

- El `package.json` declara `"license": "MIT"` con el mismo identificador SPDX que el archivo. Cuando no coinciden, gana la confusión.
- `CONTRIBUTING.md` dice bajo qué licencia entra lo que aporta alguien de fuera. Una línea: "al abrir un merge request aceptas que tu aportación se publique bajo la licencia de este repositorio".

El inventario automático llega en la Semana 20, con el SBOM: ahí cada dependencia aparece con su identificador SPDX y su licencia, generado por el pipeline.

### 2.5 Qué es de pago

| Feature | Tier | Qué resuelve | Sustituto en CE (este bootcamp) |
|---|---|---|---|
| Detección de licencia del repositorio | **Free** | El campo `license` de la API y la portada | — |
| Plantillas de licencia | **Free** | `GET /templates/licenses` | — |
| Políticas de aprobación de licencias de dependencias | **Ultimate** | Bloquear una fusión si entra una dependencia con licencia no permitida | SBOM con Syft y gate de política con Conftest (S20) |

Comprobado en agosto de 2026 contra la versión fijada `19.2.4-ce.0`.

---

## 3. Cómo se configura

Tres pasos, y ninguno lleva más de dos minutos:

1. **Elegir.** Para este bootcamp, MIT: es la más corta, la más reconocida y no impone nada al que lea tu repositorio de prácticas. Si tu proyecto puede tocar algo patentable, Apache-2.0.
2. **Escribir el archivo**, con el texto completo que sirve tu instancia, en `LICENSE` sin extensión y en la raíz.
3. **Declararlo también donde se lea sin abrir el archivo**: el campo `license` del `package.json` y una línea al final del README.

La comprobación final no es "existe el archivo" sino "GitLab lo ha reconocido":

```bash
curl -s -H "$H" "$API/projects/$P?license=true" | jq -e '.license.key != null'
# true
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| No poner licencia "porque es interno" | Interno hoy, publicado o auditado mañana, y sin permiso escrito | Una licencia, aunque sea propietaria y de tres líneas |
| `LICENSE` que dice solo "MIT" | Licensee no lo detecta: `license` sale `null` | El texto completo, desde `GET /templates/licenses/mit` |
| Retocar el texto de la licencia | Deja de encajar con ninguna conocida y deja de detectarse | Texto íntegro; las aclaraciones van en `NOTICE` |
| `LICENSE.md` con encabezados y formato | Puede bajar el parecido por debajo del umbral | `LICENSE` sin extensión, texto plano |
| Licencia en el README pero no en un archivo | La API no la ve y las herramientas de inventario tampoco | Las dos cosas: archivo y mención |
| `package.json` con una licencia y `LICENSE` con otra | Cualquier auditoría lo marca como incidencia | El mismo identificador SPDX en los dos sitios |
| Cambiar de licencia sin preguntar a los contribuidores | No es válido para las aportaciones anteriores | Elegir bien al principio; cambiar exige consentimiento |
| Poner GPL a una librería que quieres que adopten | El copyleft fuerte frena la adopción en producto cerrado | Permisiva para adopción, copyleft si quieres las mejoras de vuelta |

---

## 5. Trucos

- **El catálogo entero de tu instancia**: `GET /templates/licenses | jq -r '.[].key'`. No hace falta internet.
- **Decidir sin leer el texto legal**: `GET /templates/licenses/apache-2.0 | jq '{permissions, conditions, limitations}'` resume la licencia en tres listas.
- **La licencia ya rellenada**: `?project=<nombre>&fullname=<titular>` sustituye los huecos del texto antes de devolvértelo.
- **Comprobar que se detectó** sin abrir la interfaz: `GET /projects/:id?license=true | jq '.license.key'`.
- **Auditar la instancia entera**: el listado `GET /projects` **no** devuelve la licencia por mucho que se le pase `license=true`: ese parámetro solo lo honra la consulta de un proyecto concreto. Hay que preguntar uno a uno:

  ```bash
  for id in $(curl -s -H "$H" "$API/projects?per_page=100" | jq -r '.[].id'); do
    curl -s -H "$H" "$API/projects/$id?license=true" \
      | jq -r 'select(.license == null) | .path_with_namespace'
  done
  ```
- **`choosealicense.com`** mantiene los textos que usa Licensee. Si dudas entre dos, su comparador responde en un minuto.

---

## 📚 Recursos Adicionales

- [Choose a License](https://choosealicense.com/) — el comparador que alimenta la propia librería de detección
- [Lista SPDX de licencias](https://spdx.org/licenses/) — los identificadores oficiales, los que van en el `package.json` y en el SBOM
- [API de plantillas de licencia](https://docs.gitlab.com/ee/api/templates/licenses.html) — el catálogo que sirve tu instancia
- [Licensee](https://github.com/licensee/licensee) — cómo se decide si un texto "es" una licencia conocida
- [tl;dr Legal](https://www.tldrlegal.com/) — las licencias en lenguaje llano, sin sustituir al texto

---

## ✅ Checklist de Verificación

- [ ] Puedes explicar qué puede hacer alguien con un repositorio sin licencia
- [ ] Sabes en qué se diferencian MIT y Apache-2.0, y GPL y AGPL
- [ ] Tu `LICENSE` viene del catálogo de tu instancia, con el texto íntegro
- [ ] `GET /projects/:id?license=true` devuelve un `key` no nulo
- [ ] El `package.json` declara el mismo identificador SPDX

---

[← Anterior: Escribir el README](02-escribir-el-readme.md) · [Volver a la Semana 04](../README.md) · [Siguiente: La wiki del proyecto →](04-la-wiki-del-proyecto.md)
