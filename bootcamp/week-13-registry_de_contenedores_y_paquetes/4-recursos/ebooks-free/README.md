# 📚 Lecturas gratuitas — Semana 13

Ninguno es un manual de GitLab: son las fuentes de las ideas que la semana aplica. Todas gratuitas y accesibles sin registro. Comprobados en noviembre de 2026.

| Recurso | Qué aporta a esta semana |
|---|---|
| [OCI Image Format Specification](https://github.com/opencontainers/image-spec/blob/main/spec.md) | Qué es de verdad una imagen: un manifiesto que apunta a una configuración y a capas, todo por digest. Después de leerlo, que borrar un tag no libere disco deja de sorprender |
| [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec/blob/main/spec.md) | El protocolo que hablan `docker push` y kaniko con cualquier registry. La sección de autenticación remite al flujo de tokens del apartado 2.3 de la teoría 01 |
| [Docker registry v2 token authentication](https://distribution.github.io/distribution/spec/auth/token/) | El 401, el realm y el token, paso a paso. Es la trampa del laboratorio contada por quien diseñó el mecanismo |
| [The Twelve-Factor App — Build, release, run](https://12factor.net/es/build-release-run) | Por qué un binario se construye una vez y se promueve, en lugar de reconstruirse en cada entorno: la idea detrás de la imagen por SHA y el paquete por SHA |

> [!TIP]
> Si solo lees una cosa esta semana, que sea la del token. Son cuatro pantallas, y con ellas la teoría 02 se entiende sola.

---

[← Volver a la Semana 13](../../README.md)
