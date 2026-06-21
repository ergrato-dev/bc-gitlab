# 05 — Automatización con Python y GitLab

Python ofrece dos enfoques principales para interactuar con la API de GitLab: la librería `python-gitlab` (recomendada) y requests directos.

## python-gitlab

`python-gitlab` es la librería oficial mantenida por la comunidad. Proporciona una interfaz orientada a objetos sobre la API REST.

```python
import gitlab

gl = gitlab.Gitlab("https://gitlab.example.com", private_token="<token>")
gl.auth()

# Listar proyectos
for project in gl.projects.list(owned=True):
    print(project.name)

# Crear un issue
project = gl.projects.get("namespace/project")
issue = project.issues.create({
    "title": "Bug crítico en producción",
    "description": "Detalles del bug...",
    "labels": ["bug", "crítico"]
})
```

## Operaciones comunes

- CRUD de proyectos, issues, merge requests, milestones, labels
- Disparar pipelines y consultar su estado
- Gestionar miembros de grupos y proyectos
- Buscar recursos con filtros avanzados
- Subir archivos y gestionar el repositorio

## Requests directo (alternativa)

Si no se desea instalar dependencias adicionales, se puede usar `requests`:

```python
import requests

headers = {"PRIVATE-TOKEN": "<token>"}
url = "https://gitlab.example.com/api/v4/projects"
resp = requests.get(url, headers=headers)
projects = resp.json()
```

## Manejo de errores

La API devuelve códigos HTTP estándar. Con `python-gitlab`, las excepciones heredan de `GitlabError`:
- `GitlabAuthenticationError` (401)
- `GitlabGetError` (errores en GET, usualmente 404)
- `GitlabCreateError`, `GitlabUpdateError`, `GitlabDeleteError`
- `GitlabHttpError` para otros códigos

Siempre implementar try/except para manejar rate limits y reintentos con backoff exponencial.
