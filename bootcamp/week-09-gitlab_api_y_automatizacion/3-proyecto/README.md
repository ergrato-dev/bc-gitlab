# Proyecto Semana 09 — Bot de Automatización DevOps

## Objetivo

Crear un bot en Python que automatice tareas operativas comunes usando la API de GitLab.

## Requisitos funcionales

1. **Cierre automático de issues inactivos**: El bot debe detectar issues que no hayan tenido actividad en más de 30 días, añadir un comentario de aviso y, si pasan 7 días más sin respuesta, cerrarlos automáticamente con la etiqueta `stale`.

2. **Reporte semanal de actividad**: Generar un reporte (Markdown o HTML) con:
   - Merge requests abiertos por más de 5 días
   - Pipelines fallidas en la última semana
   - Issues creados vs cerrados esta semana

3. **Notificación vía webhook**: Enviar el reporte a un canal de Slack/Discord usando su webhook URL.

4. **Ejecución programada**: El script debe poder ejecutarse vía cron o systemd timer.

## Estructura del proyecto

```
3-proyecto/
├── src/
│   ├── bot.py           # Script principal
│   ├── gitlab_client.py # Cliente de GitLab API
│   ├── reporters.py     # Generación de reportes
│   └── notifiers.py     # Notificaciones webhook
├── config.yaml          # Configuración
├── requirements.txt     # Dependencias
└── README.md
```

## Criterios de evaluación

- [ ] Script funcional con todas las features
- [ ] Manejo de errores robusto
- [ ] Configuración externalizada (no hardcodeada)
- [ ] Documentación clara de instalación y uso
- [ ] Logs informativos durante la ejecución

## Extras opcionales

- Tests unitarios con pytest
- Empaquetado como CLI con Click/Typer
- Dockerfile para ejecución containerizada
