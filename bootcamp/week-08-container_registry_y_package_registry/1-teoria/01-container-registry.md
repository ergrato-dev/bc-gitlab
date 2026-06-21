# 01 — GitLab Container Registry

## Que es

El Container Registry de GitLab es un registro privado de imagenes Docker integrado en cada proyecto y grupo. Cada proyecto en GitLab tiene su propio espacio para almacenar imagenes de contenedores.

## Activacion

### GitLab CE Omnibus
```ruby
# /etc/gitlab/gitlab.rb
registry_external_url 'https://registry.example.com'
```

Luego:
```bash
sudo gitlab-ctl reconfigure
```

### Verificar estado
En Proyecto → Packages & Registries → Container Registry

## URL del Registry

Depende del ambito:
- **Proyecto**: `registry.example.com/group/project`
- **Grupo**: `registry.example.com/group`
- **Instancia**: `registry.example.com`

## Autenticacion

### Login con Personal Access Token
```bash
docker login registry.example.com
# Username: <tu-username>
# Password: <personal-access-token>
```

### Login con CI Job Token (dentro de pipelines)
```bash
docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY
```

### Login con Deploy Token
Settings → Repository → Deploy Tokens → Crear token con scope `read_registry` y/o `write_registry`

## Nombres de imagenes

Convencion:
```
registry.example.com/group/subgroup/project/image-name:tag
```

Variables predefinidas utiles:
- `$CI_REGISTRY`: URL del registry (ej: `registry.example.com`)
- `$CI_REGISTRY_IMAGE`: URL completa de la imagen del proyecto (ej: `registry.example.com/group/project`)
- `$CI_REGISTRY_USER`: Usuario para autenticacion
- `$CI_JOB_TOKEN`: Token temporal del job

## Visualizacion y gestion

En Packages & Registries → Container Registry:
- Lista de imagenes y sus tags
- Tamano de cada imagen
- Fecha de publicacion
- Opcion de eliminar tags manualmente
