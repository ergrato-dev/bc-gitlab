# Proyecto Semana 11 — Plan de Disaster Recovery

## Objetivo

Diseñar un plan completo de Disaster Recovery (DR) para una instancia GitLab CE que garantice continuidad de negocio ante diferentes escenarios de fallo.

## Escenarios de desastre a cubrir

1. **Fallo de disco**: El servidor principal pierde el disco de datos. El servicio está caído. Los datos están en backups.
2. **Fallo de base de datos**: PostgreSQL primario se corrompe. El servicio está caído. Las réplicas tienen los datos.
3. **Desastre de datacenter**: El datacenter completo queda inaccesible (incendio, inundación, corte de energía prolongado).
4. **Ataque de ransomware**: Datos encriptados en todos los servidores. Backups recientes disponibles en almacenamiento inmutable S3.
5. **Error humano**: Un administrador ejecuta `DROP DATABASE` accidentalmente en producción.

## Entregables

### 1. Plan de DR documentado

Documento `disaster-recovery-plan.md` que incluya:

#### Para cada escenario:
- **Detección**: ¿Cómo nos enteramos? (alertas, monitoreo)
- **Respuesta inicial**: Primeros pasos (comunicación, escalamiento)
- **Recuperación**: Procedimiento paso a paso
- **Verificación**: Checklist post-recuperación

#### Información general:
- **Contactos de emergencia**: Roles y datos de contacto
- **RTO y RPO por escenario**: Tabla con objetivos de recuperación
- **Dependencias**: Lista de sistemas externos (DNS, SMTP, S3)
- **Ubicación de backups**: Directorios, buckets S3, credenciales (referencia al gestor de secretos)
- **Versiones de software**: GitLab, PostgreSQL, Redis, dependencias

### 2. Script de DR Automatizado

Script `dr-restore.sh` que automatice la recuperación desde el escenario 3 (datacenter perdido). Debe:
- Recibir como parámetro el timestamp del backup a restaurar
- Levantar infraestructura con Docker Compose
- Restaurar backup desde S3
- Verificar integridad post-restore
- Enviar notificación de completado

### 3. Simulacro de DR

Ejecuta un simulacro documentado:
1. Toma un backup de tu instancia actual
2. Destruye la instancia (simula desastre)
3. Ejecuta el plan de DR para recuperarla
4. Mide: tiempo total de recuperación, datos perdidos (último commit no respaldado)
5. Documenta lecciones aprendidas y mejoras al plan

### 4. Dashboard de monitoreo de DR

Incluye en Grafana:
- Último backup exitoso (timestamp)
- Tamaño del último backup
- Estado de replicación PostgreSQL (lag en bytes)
- Estado de sincronización S3

## Criterios de evaluación

- [ ] Plan de DR cubre los 5 escenarios con procedimientos claros
- [ ] Script de DR automatizado funcional
- [ ] Simulacro ejecutado y documentado
- [ ] RTO real medido y comparado con objetivo
- [ ] Dashboard de monitoreo de DR implementado
