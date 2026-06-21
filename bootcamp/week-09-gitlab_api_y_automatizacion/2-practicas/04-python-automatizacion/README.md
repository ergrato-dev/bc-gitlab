# Práctica 04 — Automatización con Python

## Objetivo

Crear un script Python que automatice tareas comunes en GitLab.

## Instrucciones

1. Instala la dependencia: `pip install python-gitlab`
2. Crea un archivo `.env` con:
   ```
   GITLAB_URL=http://localhost:8080
   GITLAB_TOKEN=tu-token-aqui
   ```
3. Crea un script `automate.py` que realice las siguientes tareas:

### Tarea 1: Listar proyectos con pipelines fallidas
- Obtén todos los proyectos del usuario
- Para cada proyecto, consulta las pipelines más recientes
- Imprime los proyectos que tengan pipelines en estado `failed`

### Tarea 2: Crear issues de mantenimiento en lote
- Define una lista de issues de mantenimiento (títulos y descripciones)
- Crea cada issue en un proyecto específico
- Asigna labels y un milestone común

### Tarea 3: Auditoría de miembros
- Itera sobre todos los grupos visibles
- Lista los miembros de cada grupo con su nivel de acceso
- Genera un reporte CSV con: grupo, usuario, nivel_acceso

### Tarea 4: Reporte de merge requests abiertos
- Busca todos los MRs abiertos en los proyectos del usuario
- Calcula cuánto tiempo llevan abiertos (días desde creación)
- Genera una tabla ordenada por antigüedad

## Manejo de errores
Implementa manejo de excepciones para:
- Conexión rechazada (servicio caído)
- Token inválido (401)
- Rate limit (429)
- Reintentos con backoff exponencial

## Entrega
Script funcional con todas las tareas implementadas y documentación docstring.
