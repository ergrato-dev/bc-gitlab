# 📚 Lecturas gratuitas — Semana 10

Ninguno es un manual de GitLab: son las fuentes de las ideas que la semana aplica. Todas gratuitas y accesibles sin registro.

| Recurso | Qué aporta a esta semana |
|---|---|
| [OWASP Top 10 CI/CD Security Risks](https://owasp.org/www-project-top-10-ci-cd-security-risks/) | Los diez riesgos del pipeline. Esta semana toca de lleno dos: *Poisoned Pipeline Execution* (el YAML de una merge request que se lleva un secreto) e *Insufficient Credential Hygiene* (secretos sin inventario ni rotación) |
| [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) | Ciclo de vida de un secreto: creación, distribución, rotación, revocación y qué hacer cuando se filtra. Es el esqueleto de `docs/secretos.md` |
| [The Twelve-Factor App — Config](https://12factor.net/config) | Por qué la configuración que cambia entre entornos no va en el código, y la prueba de fuego: ¿podrías publicar el repositorio ahora mismo sin filtrar una credencial? |

> [!TIP]
> Si solo lees una cosa esta semana, que sea la ficha de *Poisoned Pipeline Execution* de OWASP. Describe exactamente el job `fuga` de la práctica 04, y explica por qué `protected` es la única defensa que no depende de que alguien revise el YAML a tiempo.

---

[← Volver a la Semana 10](../../README.md)
