# Práctica 04 — Documentación y Defensa

## Objetivo

Producir la documentación completa del proyecto y preparar la presentación de defensa.

## Instrucciones

### Paso 1: Documentar la arquitectura

Crea `docs/arquitectura.md` con:

```markdown
# Arquitectura de la Plataforma DevOps

## Diagrama
[Inserta tu diagrama aquí — recomendado: exportar desde draw.io a SVG]

## Componentes
| Componente | Tecnología | Propósito |
|-----------|-----------|----------|
| GitLab CE | Docker | Repositorio, CI/CD, Issues, Registry |
| GitLab Runner | Docker | Ejecutar jobs de CI/CD |
| PostgreSQL | GitLab interno | Base de datos |
| Redis | GitLab interno | Cache y colas |
| Prometheus | Docker | Recolección de métricas |
| Grafana | Docker | Visualización y alertas |

## Flujo de CI/CD
1. Developer hace push a una rama
2. Pipeline se ejecuta: build → test → security → deploy
3. Si la rama es `main`: deploy automático a staging
4. Si es un tag: deploy manual a production

## Decisiones técnicas
- Docker Compose: simplicidad, no requiere orquestador complejo
- GitLab CE: auto-administrado, control total
- Certificados auto-firmados: entorno de laboratorio
- MinIO: almacenamiento S3-compatible para backups off-site
```

### Paso 2: Escribir el manual de operaciones

`docs/manual-operaciones.md`:

Cubre al menos:
- **Requisitos**: Docker 24+, Docker Compose v2, 8GB RAM, 20GB disco
- **Instalación**: `git clone`, `cp .env.example .env`, `docker-compose up -d`
- **Primer acceso**: Obtener contraseña root, cambiarla, crear usuarios
- **Backup**: Ejecutar `./backup/backup.sh`
- **Restore**: Ejecutar `./backup/restore.sh <timestamp>`
- **Actualización**: Cambiar versión en `.env`, `docker-compose pull`, `docker-compose up -d`
- **Solución de problemas**: Errores comunes y sus soluciones

### Paso 3: Escribir el plan de Disaster Recovery

`docs/disaster-recovery.md`:

| Escenario | RTO | RPO | Procedimiento |
|-----------|-----|-----|--------------|
| Caída de GitLab | 5 min | 0 | Reiniciar contenedor |
| Corrupción DB | 30 min | 24h | Restore desde backup |
| Pérdida total | 2h | 24h | Recrear infraestructura + restore |

Incluye:
- Script de restore automatizado
- Contactos de emergencia (simulados)
- Checklist de verificación post-recuperación

### Paso 4: Crear el README.md del proyecto

README.md raíz con:
- Descripción del proyecto (1-2 párrafos)
- Requisitos previos
- Instalación rápida (3 comandos)
- Estructura de archivos
- Arquitectura (link a docs/arquitectura.md)
- Capturas de pantalla (pipeline, Grafana, Security dashboard)
- Tecnologías utilizadas
- Autor y fecha

### Paso 5: Preparar la defensa

1. **Slides**: Prepara 5-7 diapositivas con:
   - Portada (título, autor, fecha)
   - Arquitectura (diagrama)
   - Pipeline CI/CD (captura de pantalla)
   - Seguridad (Security Dashboard)
   - Monitoreo (Dashboard Grafana)
   - Lecciones aprendidas

2. **Demo script**: Escribe EXACTAMENTE los comandos que ejecutarás en la demo:
   ```
   docker-compose ps
   git push origin feature/demo
   # Mostrar pipeline en UI
   # Mostrar Security Dashboard
   # Mostrar Grafana
   # Ejecutar backup
   ```

3. **Ensayo**: Grábate y revisa. Ajusta el tiempo. 15 minutos máximo.

## Verificación

- [ ] `docs/arquitectura.md` incluye diagrama y tabla de componentes
- [ ] `docs/manual-operaciones.md` permite a alguien nuevo levantar la plataforma
- [ ] `docs/disaster-recovery.md` cubre 3+ escenarios con RTO/RPO
- [ ] `README.md` raíz tiene instalación rápida funcional
- [ ] Slides preparados y ensayados
- [ ] Demo ensayada en 15 minutos o menos
