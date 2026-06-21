# Practica 01 — Container Registry Setup

## Objetivo

Habilitar y verificar el Container Registry de GitLab, autenticarse y subir una imagen manualmente.

## Instrucciones

### Paso 1: Habilitar Container Registry

En GitLab CE Omnibus:
```bash
sudo vim /etc/gitlab/gitlab.rb
```

Agregar/descomentar:
```ruby
registry_external_url 'https://registry.tudominio.com'
# O para desarrollo:
registry_external_url 'http://localhost:5050'
```

```bash
sudo gitlab-ctl reconfigure
sudo gitlab-ctl status | grep registry
```

### Paso 2: Login manual

```bash
# Crear Personal Access Token con scope read_registry + write_registry
# En: Settings → Access Tokens

docker login localhost:5050
# Username: tu-usuario
# Password: personal-access-token
```

### Paso 3: Subir imagen de prueba

```bash
# Construir imagen simple
docker pull alpine:latest
docker tag alpine:latest localhost:5050/tu-grupo/tu-proyecto/mi-alpine:latest
docker push localhost:5050/tu-grupo/tu-proyecto/mi-alpine:latest

# Tambien con commit SHA
docker tag alpine:latest localhost:5050/tu-grupo/tu-proyecto/mi-alpine:test
docker push localhost:5050/tu-grupo/tu-proyecto/mi-alpine:test
```

### Paso 4: Verificar en UI

Ve a Proyecto → Packages & Registries → Container Registry

Debes ver `tu-grupo/tu-proyecto/mi-alpine` con tags `latest` y `test`.

### Paso 5: Pull de la imagen

```bash
docker pull localhost:5050/tu-grupo/tu-proyecto/mi-alpine:latest
docker run --rm localhost:5050/tu-grupo/tu-proyecto/mi-alpine:latest cat /etc/os-release
```

## Verificacion

- [ ] Registry responde en el puerto configurado
- [ ] Login via docker exitoso
- [ ] Imagen visible en Packages & Registries → Container Registry
- [ ] Pull de la imagen funciona correctamente

## Reto adicional

Configura el registry con HTTPS usando certificados auto-firmados o Let's Encrypt:

```ruby
registry_external_url 'https://registry.tudominio.com'
registry_nginx['ssl_certificate'] = "/etc/gitlab/ssl/registry.tudominio.com.crt"
registry_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/registry.tudominio.com.key"
```
