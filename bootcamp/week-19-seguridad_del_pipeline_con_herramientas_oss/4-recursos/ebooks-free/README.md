# 📚 Lecturas gratuitas — Semana 19

Ninguna es un manual de GitLab: son las fuentes de las ideas que la semana aplica. Todas gratuitas y accesibles sin registro. Comprobadas en noviembre de 2026.

| Recurso | Qué aporta a esta semana |
|---|---|
| [OWASP — Top 10 CI/CD Security Risks](https://owasp.org/www-project-top-10-ci-cd-security-risks/) | El pipeline como superficie de ataque: dependencias, credenciales, imágenes y controles de flujo. Es el mapa de la teoría 01 |
| [NIST SP 800-218 — Secure Software Development Framework](https://csrc.nist.gov/pubs/sp/800/218/final) | Las prácticas PW.7 (revisar y analizar el código) y RV.1 (identificar vulnerabilidades de forma continua): por qué el escaneo va en cada cambio y no una vez al año |
| [OWASP — Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) | Qué hacer cuando un secreto se filtra: rotar primero. La base del paso 6 de la práctica 04 |
| [FIRST — CVSS v3.1 Specification](https://www.first.org/cvss/v3.1/specification-document) | Qué mide una puntuación CVSS y qué no: el umbral de OSV-Scanner del componente es un corte sobre ella |
| [OpenSSF — Concise Guide for Developing More Secure Software](https://best.openssf.org/Concise-Guide-for-Developing-More-Secure-Software) | Una página: dependencias mínimas, herramientas en el pipeline y no guardar secretos en el repositorio. La práctica 04 entera, en diez líneas |

> [!TIP]
> Si solo lees una cosa esta semana, que sea el riesgo CICD-SEC-3 (*Dependency Chain Abuse*) del Top 10 de OWASP: es la razón de que OSV-Scanner mire el lockfile y de que las imágenes vayan por digest.

---

[← Volver a la Semana 19](../../README.md)
