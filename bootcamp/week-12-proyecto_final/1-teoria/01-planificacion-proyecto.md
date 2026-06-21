# 01 — Planificación del Proyecto Final

El proyecto final integra todos los conocimientos del bootcamp en una plataforma DevOps funcional. Una buena planificación es crítica para el éxito.

## Definición del alcance

Antes de empezar, define claramente:

1. **¿Qué aplicación vas a desplegar?** — Puede ser una app propia (Node.js, Python, Go) o una app de ejemplo (como el proyecto de la Semana 07-08). Debe tener al menos: tests unitarios, Dockerfile, dependencias externas.

2. **¿Qué entorno(s) tendrás?** — Mínimo staging y production, separados por ramas o por etiquetas git. Staging se despliega automáticamente en cada merge a `main`, production requiere trigger manual.

3. **¿Qué herramientas de seguridad usarás?** — SAST para el lenguaje de tu app, Secret Detection para detectar tokens hardcodeados, Container Scanning para vulnerabilidades en la imagen Docker.

## Arquitectura propuesta

```
[Internet] → [HTTPS:443]
                ↓
         [Nginx Reverse Proxy]
                ↓
    ┌──────────┼──────────┐
    ↓          ↓          ↓
[GitLab CE] [Runner] [Registry]
    ↓          ↓          ↓
[PostgreSQL] [Docker] [MinIO/S3]
    ↓
[Redis]
    
[Monitoreo: Prometheus + Grafana]
[Backup: Script diario + S3]
```

## Plan de trabajo (4 sesiones)

| Sesión | Duración | Objetivo |
|--------|---------|----------|
| Sesión 1 | 4h | Infraestructura: Docker Compose, HTTPS, Runner, Registry |
| Sesión 2 | 4h | CI/CD: Pipeline multi-stage, templates, environments |
| Sesión 3 | 4h | Seguridad + Monitoreo: SAST, MFA, RBAC, Grafana |
| Sesión 4 | 4h | Documentación + Defensa: docs, presentación, ensayo |

## Checklist pre-entrega

- [ ] `docker-compose up -d` levanta toda la plataforma
- [ ] `curl https://gitlab.local` responde 200
- [ ] Pipeline se ejecuta en push a cualquier rama
- [ ] SAST y Secret Detection jobs pasan (o reportan hallazgos)
- [ ] Dashboard Grafana muestra métricas con datos reales
- [ ] Backup script se ejecuta sin errores
- [ ] `docker-compose down -v && docker-compose up -d` + restore funcional
- [ ] README.md explica cómo levantar todo desde cero
