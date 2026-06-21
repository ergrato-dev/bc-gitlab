# Práctica 04 — Diseño de Arquitectura HA

## Objetivo

Diseñar una arquitectura de alta disponibilidad para GitLab CE con diagrama y justificación de decisiones.

## Instrucciones

### Paso 1: Requerimientos del escenario

Empresa "CloudServ" con los siguientes requisitos:
- 500 desarrolladores activos
- RTO: 10 minutos (máximo tiempo sin servicio)
- RPO: 1 hora (máximo de datos que pueden perderse)
- Presupuesto limitado para infraestructura (no usar servicios cloud administrados)
- GitLab CE (sin features Enterprise)

### Paso 2: Diseñar la arquitectura

Dibuja un diagrama de arquitectura (recomendado: draw.io, Excalidraw, o ASCII art) que incluya:

1. **Balanceadores de carga**: 2 HAProxy/Nginx con keepalived para VIP
2. **GitLab Rails**: 2-3 nodos para la aplicación web y API
3. **Sidekiq**: 2 nodos dedicados para procesamiento asíncrono
4. **PostgreSQL**: 3 nodos con Patroni (1 primario + 2 réplicas) + etcd para consenso
5. **Redis**: 3 nodos con Redis Sentinel
6. **Gitaly**: 3 nodos con Praefect
7. **Almacenamiento**: NFS o S3 para uploads, registry, backups
8. **Monitoreo**: Prometheus + Grafana

### Paso 3: Justificar decisiones

Para cada componente, responde:
- ¿Por qué elegiste esta cantidad de nodos?
- ¿Qué pasa si falla uno de ellos?
- ¿Qué limitaciones de GitLab CE impactan este diseño?

### Paso 4: Calcular costos

Si esta arquitectura se desplegara en VPS (servidores virtuales), estima:
- Cantidad de VPS necesarios
- Recursos por VPS (CPU, RAM, disco)
- Costo mensual estimado

### Paso 5: Documentar procedimientos operativos

Escribe runbooks para:
- **Failover de PostgreSQL**: Pasos para promover una réplica si el primario falla
- **Failover de Redis**: Cómo Redis Sentinel maneja la elección de nuevo maestro
- **Restore desde backup**: Procedimiento completo en caso de pérdida total
- **Escalamiento**: Cómo agregar un nuevo nodo Rails cuando la carga aumenta

### Entregables
- Diagrama de arquitectura en formato PNG o SVG
- Documento con justificaciones y cálculos de costos
- Runbooks en formato Markdown

## Preguntas de reflexión
- ¿Cuál es el componente más difícil de hacer HA en GitLab CE y por qué?
- ¿Cómo manejarías actualizaciones de versión en esta arquitectura sin downtime?
- ¿Qué cambiarías si el presupuesto aumentara 3x?
