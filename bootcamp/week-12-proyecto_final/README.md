# Semana 12 — Proyecto Final: Plataforma DevOps Completa

## Objetivos

- Integrar todos los conocimientos del bootcamp
- Desplegar una plataforma DevOps completa con GitLab CE
- Implementar CI/CD, seguridad, monitoreo y backup
- Demostrar competencia como Administrador DevOps Junior
- Presentar y defender el proyecto

## Requisitos Previos

- Todas las semanas anteriores completadas

## Descripción del Proyecto

Desplegar y configurar una plataforma DevOps completa que incluya:

### Infraestructura (30%)
- GitLab CE con Docker Compose
- GitLab Runner con ejecutor Docker
- Container Registry configurado
- HTTPS con certificados auto-firmados o Let's Encrypt

### CI/CD (25%)
- Pipeline multi-stage: build → test → security → package → deploy
- Variables CI/CD protegidas
- Reutilización con `include` y templates
- Environments (staging, production)

### Seguridad (20%)
- SAST y Secret Detection en pipeline (templates CE)
- RBAC con roles definidos
- MFA habilitado
- Container Scanning (template CE)

### Monitoreo y Respaldo (15%)
- Prometheus + Grafana dashboards
- Backup automático diario
- Restore probado
- Logs centralizados

### Documentación (10%)
- README.md del proyecto completo
- Diagrama de arquitectura
- Manual de operaciones
- Plan de Disaster Recovery

## Estructura de Entrega

```
proyecto-final/
├── docker-compose.yml          # Infraestructura principal
├── .env.example                # Variables de entorno
├── .gitlab-ci.yml              # Pipeline completo
├── ci-templates/               # Templates de CI reutilizables
├── monitoring/                 # Configuración Prometheus/Grafana
├── backup/                     # Scripts de backup
├── docs/                       # Documentación
│   ├── arquitectura.md         # Diagrama de arquitectura
│   ├── manual-operaciones.md   # Manual de operaciones
│   └── disaster-recovery.md    # Plan de DR
└── README.md                   # Documentación del proyecto
```

## Criterios de Evaluación

### Infraestructura (30%)
- [ ] GitLab CE accesible vía HTTPS
- [ ] Runner registrado y funcional
- [ ] Container Registry operativo
- [ ] Volúmenes persistentes

### Pipeline CI/CD (25%)
- [ ] Pipeline con 5+ stages
- [ ] Deploy a staging funcionando
- [ ] Templates reutilizables
- [ ] Cache y artifacts optimizados

### Seguridad (20%)
- [ ] SAST ejecutándose en pipeline
- [ ] Secret Detection sin falsos positivos
- [ ] Container Scanning
- [ ] RBAC documentado

### Monitoreo (15%)
- [ ] Dashboard Grafana con métricas GitLab
- [ ] Alertas configuradas
- [ ] Backup funcionando
- [ ] Logs accesibles

### Documentación (10%)
- [ ] README.md completo
- [ ] Diagrama de arquitectura
- [ ] Manual de operaciones
- [ ] Plan de DR

## Defensa del Proyecto

Presentación de 15 minutos cubriendo:
1. Demo en vivo de la plataforma
2. Explicación de decisiones técnicas
3. Demostración del pipeline CI/CD
4. Backup y restore en vivo

---

[← Semana 11](../week-11-monitoreo_backup_y_alta_disponibilidad/README.md) | [Bootcamp completado](../README.md)
