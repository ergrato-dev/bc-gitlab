# Proyecto Semana 10 — Stack de Seguridad DevOps

## Objetivo

Diseñar e implementar un stack completo de seguridad para una organización simulada con 3 equipos de desarrollo.

## Escenario

Empresa "SecureSoft" con 3 equipos:
- **Equipo Backend** (5 devs): microservicios en Python
- **Equipo Frontend** (3 devs): aplicación React
- **Equipo Mobile** (2 devs): app Flutter

Requisitos de seguridad:
- SOC2 compliance (auditoría trimestral)
- Separación de entornos (staging no accesible públicamente)
- Todos los commits deben pasar SAST y Secret Detection

## Entregables

### 1. Estructura de grupos y RBAC
```
securesoft/
├── backend/          # Developers: Equipo Backend
├── frontend/         # Developers: Equipo Frontend
└── mobile/           # Developers: Equipo Mobile
```
Documentar la matriz de permisos para cada rol.

### 2. Pipeline de seguridad
- SAST en todos los proyectos
- Secret Detection con escaneo histórico
- Dependency Scanning en proyectos con dependencias
- Compliance pipeline a nivel de grupo padre

### 3. Políticas de protección
- Protected branches en `main` y `release/*`
- Merge request approvals: mínimo 2 aprobaciones
- MFA obligatorio para todos los miembros

### 4. Reporte de auditoría
Script Python que genere un reporte semanal incluyendo:
- Vulnerabilidades abiertas por severidad
- Miembros sin MFA
- Proyectos sin SAST configurado
- Tokens próximos a expirar

### 5. Documentación
- Runbook de respuesta a incidentes de seguridad
- Política de gestión de vulnerabilidades
- Matriz RBAC documentada

## Criterios de evaluación

- [ ] RBAC implementado correctamente
- [ ] SAST y Secret Detection funcionando en al menos un proyecto
- [ ] Reporte de auditoría generado vía API
- [ ] Documentación completa y profesional
- [ ] Compliance pipeline funcional a nivel de grupo
