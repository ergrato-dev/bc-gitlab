# Proyecto Final — Plataforma DevOps Completa

## Especificación detallada

El proyecto final consiste en desplegar y documentar una plataforma DevOps completa usando GitLab CE como núcleo. A diferencia de los proyectos semanales, este proyecto debe integrar TODOS los conocimientos adquiridos durante el bootcamp.

## Requisitos funcionales obligatorios

### 1. Infraestructura como Código
- `docker-compose.yml` funcional que levante toda la plataforma con un solo comando
- `.env.example` con todas las variables de entorno documentadas
- Volúmenes persistentes para todos los datos (configuración, logs, repositorios, base de datos)
- Healthchecks en todos los servicios

### 2. CI/CD Pipeline
- Pipeline con mínimo 5 stages: build, test, security, package, deploy
- Inclusión de templates reutilizables desde `ci-templates/`
- Uso de variables CI/CD protegidas para secretos
- Environments `staging` y `production` configurados en GitLab
- Deploy a staging automático, deploy a production manual
- Cache y artifacts correctamente configurados

### 3. Seguridad
- SAST, Secret Detection y Container Scanning ejecutándose en el pipeline
- RBAC con al menos 3 roles diferentes documentados
- MFA habilitado y forzado
- Variables CI/CD enmascaradas y protegidas

### 4. Monitoreo
- Prometheus recolectando métricas de GitLab
- Grafana con al menos 1 dashboard importado y 1 dashboard personalizado
- Al menos 1 alerta configurada en Grafana

### 5. Backup y DR
- Script de backup automático con rotación
- Restore probado exitosamente (documentar con captura de pantalla)
- Plan de Disaster Recovery documentado con RTO/RPO

### 6. Documentación
- `README.md` en la raíz del proyecto
- `docs/arquitectura.md` con diagrama
- `docs/manual-operaciones.md` 
- `docs/disaster-recovery.md`

## Aplicación demo

Debes incluir una aplicación de ejemplo (no solo "Hello World") que demuestre el pipeline. Puede ser:
- Una API REST simple (Python Flask/FastAPI, Node.js Express, Go)
- Una app web con frontend estático
- La aplicación que desarrollaste en el proyecto de la Semana 07/08

La aplicación debe tener:
- Tests unitarios (mínimo 3 tests)
- Dockerfile multi-stage
- Dependencias externas (demostrar Dependency Scanning)

## Estructura de archivos esperada

```
proyecto-final/
├── docker-compose.yml
├── .env.example
├── .gitlab-ci.yml
├── README.md
├── app/                        # Código de la aplicación demo
│   ├── Dockerfile
│   ├── src/
│   └── tests/
├── ci-templates/
│   ├── build.yml
│   └── deploy.yml
├── monitoring/
│   ├── prometheus.yml
│   └── grafana-datasources.yml
├── backup/
│   ├── backup.sh
│   └── restore.sh
└── docs/
    ├── arquitectura.md
    ├── manual-operaciones.md
    └── disaster-recovery.md
```

## Criterios de aprobación

- **Nota mínima**: 80% sobre 100%
- Cada requisito funcional debe estar implementado y funcionando
- La demo en vivo debe ejecutarse sin errores
- La documentación debe permitir a otra persona levantar la plataforma sin asistencia

## Recursos starter

En el directorio `starter/` encontrarás:
- Un esqueleto de `docker-compose.yml` con los servicios base
- Un `Makefile` con comandos útiles (up, down, logs, backup, restore)
- Un `.env.example` de referencia
