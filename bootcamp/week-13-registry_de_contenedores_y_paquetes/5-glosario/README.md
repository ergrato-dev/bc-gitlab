# 📖 Glosario — Semana 13

Términos que aparecen esta semana. El nombre real de la feature va en inglés entre paréntesis, y el **tier** cuando aplica.

El glosario acumulado de toda la plataforma está en [glosario-global](../../../docs/glosario-global.md).

---

## B

**Base de metadatos del registry** (*Container registry metadata database*) — Free. PostgreSQL para los metadatos del registry, en lugar de solo el sistema de archivos. En 19.2.4 viene en `prefer`. Sin ella no hay tags protegidos ni recolección de basura en línea.

**Borrado masivo** (*Delete registry repository tags in bulk*) — `DELETE /projects/:id/registry/repositories/:id/tags` con `name_regex_delete`, `name_regex_keep`, `keep_n` y `older_than`. Actúa ya, en segundo plano, una vez por hora por repositorio. Nunca borra `latest`.

## C

**Container registry** — Free. Registry de imágenes integrado en GitLab, con las rutas de los proyectos y los permisos de sus miembros. En el laboratorio, `localhost:5050`.

## D

**Dependency proxy** — Free. Caché de imágenes de Docker Hub por grupo raíz, servida por la propia instancia. Se usa con `${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/imagen:versión`.

**Deploy token** — Credencial de proyecto o grupo para máquinas fuera de GitLab, con `read_registry`, `read_package_registry` y sus equivalentes de escritura. No ocupa un usuario. No puede subir a lo protegido.

**Digest** — Hash del manifiesto de una imagen (`sha256:…`). A diferencia de un tag, no se mueve: es lo que se despliega y lo que se firma.

## K

**kaniko** — Construye imágenes desde un `Dockerfile` dentro de un contenedor sin privilegios y sin daemon. El proyecto original se archivó el 3 de junio de 2025; el fork mantenido es `osscontainertools/kaniko`.

## P

**Paquete genérico** (*Generic package*) — Free. Cualquier archivo en el registro de paquetes, con nombre y versión en la URL: `/projects/:id/packages/generic/:nombre/:version/:archivo`.

**Política de limpieza** (*Cleanup policy*) — Free. Reglas por proyecto que borran tags del registry según `name_regex`, `name_regex_keep`, `keep_n` y `older_than`. Desactivada por defecto. Nunca borra `latest` ni los tags protegidos.

## R

**Realm** — URL a la que el registry manda a pedir el token, en la cabecera `Www-Authenticate` del `401`. Sale de `external_url`, y tiene que poder alcanzarla el cliente.

**Recolección de basura** (*Garbage collection*) — Borra las capas que ya no usa ningún tag. Con la base de metadatos, en línea y automática a las 24 h; sin ella, `gitlab-ctl registry-garbage-collect`.

**`registrytoken`** — Campo del `config.json` de Docker con un token que se envía tal cual al registry, sin pasar por el realm. Lo que usa el componente `imagen` dentro de un job.

## T

**Tag protegido del registry** (*Protected container tag*) — Free. Regla que exige un rol mínimo (Maintainer, Owner o administrador) para subir y borrar los tags que cumplen una expresión. Los **inmutables**, que nadie puede tocar, son Ultimate.

---

[← Volver a la Semana 13](../README.md)
