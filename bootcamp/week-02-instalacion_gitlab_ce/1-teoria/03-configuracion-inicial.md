# 03 — Configuracion Inicial de GitLab CE

## Objetivos

- Completar la configuracion post-instalacion de GitLab CE
- Cambiar la contrasena de root
- Configurar apariencia y preferencias
- Configurar SMTP para notificaciones por email
- Registrar un GitLab Runner (opcional para CI/CD)

## Cambiar Contrasena de Root

1. Inicia sesion con usuario `root` y la contrasena inicial
2. Ve a **Avatar (esquina superior derecha) → Preferences**
3. En el sidebar izquierdo, selecciona **Password**
4. Ingresa la contrasena actual y la nueva
5. Guarda los cambios

## Configurar Apariencia de la Instancia

Como administrador (root):

1. Ve a **Admin Area** (icono de llave en el sidebar inferior)
2. **Settings → Appearance**
3. Configura:
   - **Title**: Nombre de tu instancia (ej: "Bootcamp DevOps")
   - **Description**: Descripcion corta
   - **Logo**: Sube un logo personalizado
   - **Favicon**: Icono de pestana del navegador
   - **Sign-in/Sign-up**: Personaliza mensajes de bienvenida

## Configuracion General del Sistema

En **Admin Area → Settings → General**:

- **Sign-up enabled**: Habilitar o deshabilitar registro publico
- **Default project visibility**: Internal o Private
- **Restricted visibility levels**: Limitar quienes pueden crear proyectos publicos
- **Account and limit**: Configurar limites de proyectos por usuario, tamano maximo de repositorios

## Configurar SMTP (Notificaciones por Email)

Edita el archivo `docker-compose.yml` para agregar configuracion SMTP:

```yaml
environment:
  GITLAB_OMNIBUS_CONFIG: |
    external_url 'http://gitlab.local'
    gitlab_rails['smtp_enable'] = true
    gitlab_rails['smtp_address'] = "smtp.gmail.com"
    gitlab_rails['smtp_port'] = 587
    gitlab_rails['smtp_user_name'] = "tu@email.com"
    gitlab_rails['smtp_password'] = "tu-app-password"
    gitlab_rails['smtp_domain'] = "gmail.com"
    gitlab_rails['smtp_authentication'] = "login"
    gitlab_rails['smtp_enable_starttls_auto'] = true
    gitlab_rails['gitlab_email_from'] = 'tu@email.com'
```

Despues de modificar, reconstruye:

```bash
docker compose down
docker compose up -d
```

## Configuraciones Recomendadas

### Limitar Creacion de Grupos

En **Admin Area → Settings → General → Account and limit**:
- **Default projects limit**: 10 (para evitar abuso en entornos compartidos)

### Configurar Timezone

```ruby
gitlab_rails['time_zone'] = 'America/Mexico_City'
```

### Aumentar Timeout para Repos Grandes

```ruby
gitlab_rails['git_timeout'] = 120
```
