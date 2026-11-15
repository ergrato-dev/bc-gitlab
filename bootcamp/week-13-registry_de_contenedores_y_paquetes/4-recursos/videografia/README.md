# 🎥 Vídeos — Semana 13

## Registry e imágenes

| Recurso | Canal | Por qué vale la pena |
|---|---|---|
| [GitLab container registry tutorial](https://www.youtube.com/results?search_query=gitlab+container+registry+ci+cd) | Varios | Casi todos usan Docker-in-Docker con `privileged`. Quédate con cómo usan `CI_REGISTRY_IMAGE` y las credenciales del job, no con el runner |
| [Kaniko build without Docker daemon](https://www.youtube.com/results?search_query=kaniko+build+image+without+docker+daemon) | Varios | Para entender por qué kaniko no necesita privilegios. Los anteriores a junio de 2025 usan la imagen de Google, hoy archivada |

## Limpieza, paquetes y proxy

| Recurso | Canal | Por qué vale la pena |
|---|---|---|
| [GitLab container registry cleanup policy](https://www.youtube.com/results?search_query=gitlab+container+registry+cleanup+policy) | Varios | Comprueba que expliquen `name_regex_keep` y que la recolección de basura es aparte |
| [GitLab generic package registry](https://www.youtube.com/results?search_query=gitlab+generic+package+registry) | Varios | Fíjate en si tratan los duplicados: si suben dos veces la misma versión sin comentarlo, le falta lo importante |
| [GitLab dependency proxy](https://www.youtube.com/results?search_query=gitlab+dependency+proxy+docker+hub+rate+limit) | Varios | Busca uno que use la variable del prefijo y no la ruta escrita a mano |

> [!NOTE]
> Los enlaces son búsquedas, no vídeos concretos: el registry ha cambiado mucho desde la 17 (base de metadatos, tags protegidos) y un enlace fijo acaba enseñando lo de antes. El criterio para elegir está en la última columna.

---

[← Volver a la Semana 13](../../README.md)
