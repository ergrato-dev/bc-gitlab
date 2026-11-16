# 🎥 Vídeos — Semana 15

## Runners y su configuración

| Recurso | Canal | Por qué vale la pena |
|---|---|---|
| [GitLab Runner config.toml](https://www.youtube.com/results?search_query=gitlab+runner+config.toml+concurrent+limit) | Varios | Quédate con cómo reparten `concurrent` y `limit`. Si registran con `--registration-token`, el vídeo es anterior al flujo de tokens `glrt-`: lo de las etiquetas ya no se hace así |
| [GitLab runner tags and protected runners](https://www.youtube.com/results?search_query=gitlab+runner+tags+protected+run+untagged) | Varios | Busca uno que enseñe un job atascado por etiquetas y cómo se diagnostica |

## Docker dentro de Docker y caché

| Recurso | Canal | Por qué vale la pena |
|---|---|---|
| [GitLab CI docker-in-docker TLS](https://www.youtube.com/results?search_query=gitlab+ci+docker+in+docker+tls+certs) | Varios | Comprueba que usen `DOCKER_TLS_CERTDIR` y el puerto 2376. Si usan 2375 sin TLS o montan `docker.sock`, ya sabes por qué no copiarlo |
| [GitLab Runner distributed cache S3](https://www.youtube.com/results?search_query=gitlab+runner+distributed+cache+s3+shared) | Varios | Fíjate en `Shared`: la mitad de los tutoriales lo dejan en `false` y no se dan cuenta de que cada runner sigue con su caché |

> [!NOTE]
> Los enlaces son búsquedas, no vídeos concretos: la forma de registrar runners cambió por completo con los tokens `glrt-`, y un enlace fijo acaba enseñando lo de antes. El criterio para elegir está en la última columna.

---

[← Volver a la Semana 15](../../README.md)
