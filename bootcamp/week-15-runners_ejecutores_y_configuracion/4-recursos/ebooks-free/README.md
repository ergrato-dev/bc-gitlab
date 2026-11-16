# 📚 Lecturas gratuitas — Semana 15

Ninguno es un manual de GitLab Runner: son las fuentes de las ideas que la semana aplica. Todas gratuitas y accesibles sin registro. Comprobados en noviembre de 2026.

| Recurso | Qué aporta a esta semana |
|---|---|
| [Docker Engine security](https://docs.docker.com/engine/security/) | Qué protege un contenedor y qué deja de proteger `--privileged`. Es la base de la teoría 06 |
| [Docker daemon attack surface](https://docs.docker.com/engine/security/#docker-daemon-attack-surface) | Por qué quien controla el socket de Docker controla el host. Dos párrafos que cierran la discusión sobre montar `docker.sock` en los jobs |
| [OWASP CI/CD Security Top 10](https://owasp.org/www-project-top-10-ci-cd-security-risks/) | CICD-SEC-7 (configuración insegura del sistema) y CICD-SEC-9 (integridad de artefactos): runners compartidos y cachés envenenadas, con nombre |
| [Site Reliability Engineering — Eliminating Toil](https://sre.google/sre-book/eliminating-toil/) | Por qué la flota se opera por API y con una plantilla, y no a mano cada vez |

> [!TIP]
> Si solo lees una cosa esta semana, que sea la superficie de ataque del daemon de Docker. Después de leerla, la diferencia entre el socket del host y `dind` con listas deja de ser un detalle.

---

[← Volver a la Semana 15](../../README.md)
