# 📖 03 — Configuración Inicial de GitLab CE

## 🎯 Objetivos de aprendizaje

- ✅ Cambiar la contraseña de root y entender por qué es el primer paso obligatorio
- ✅ Configurar la apariencia de la instancia (nombre, descripción, mensajes)
- ✅ Restringir el registro público para un entorno controlado
- ✅ Configurar SMTP para notificaciones por email
- ✅ Crear un usuario de trabajo (no usar root para actividades diarias)

---

## 🤔 La analogía de las cerraduras

**La primera vez que entras a una casa nueva, lo primero es cambiar las cerraduras.**

No porque el anterior propietario sea malicioso, sino porque él (y potencialmente mucha gente) conoce las llaves originales. Con GitLab pasa exactamente lo mismo: la contraseña inicial de root se genera automáticamente y se almacena en un archivo de texto plano por 24 horas. Hasta que no la cambies, cualquiera que tenga acceso a tu terminal puede obtenerla con un simple `grep`.

---

## 🔑 Paso 1: Cambiar la contraseña de root

### Por la interfaz web (recomendado)

1. Abre `http://localhost` en el navegador
2. Inicia sesión con `root` y la contraseña inicial
3. Haz clic en tu **avatar** (esquina superior derecha) → **Edit profile**
4. En el menú lateral izquierdo → **Password**
5. Ingresa la contraseña actual y la nueva (mínimo 8 caracteres, mezcla de tipos)
6. Haz clic en **Save password**

GitLab te pedirá iniciar sesión de nuevo con la contraseña nueva. Esto confirma que el cambio fue exitoso.

### Por línea de comandos (alternativa si olvidaste la contraseña)

```bash
# ¿QUÉ HACE?: Abre la consola interactiva de Ruby on Rails de GitLab
# ¿POR QUÉ?: Permite manipular objetos de la base de datos directamente
# ¿PARA QUÉ?: Resetear la contraseña de root sin acceso a la UI
docker compose exec gitlab gitlab-rails console

# Dentro de la consola Rails:
# ¿QUÉ HACE?: Busca el usuario root en la base de datos
user = User.find_by_username('root')
# ¿QUÉ HACE?: Asigna la nueva contraseña (debe cumplir las reglas de complejidad)
user.password = 'NuevaContraseñaSegura123!'
user.password_confirmation = 'NuevaContraseñaSegura123!'
# ¿QUÉ HACE?: Guarda los cambios, omitiendo validación de email
user.save!(validate: false)
# Salir de la consola
exit
```

---

## 🛠️ Paso 2: Configurar la apariencia de la instancia

La apariencia es lo que ven tus usuarios al llegar a la instancia. Para un bootcamp, personalizar el nombre y los mensajes ayuda a que todos sepan que están en el entorno correcto.

**Ruta de navegación:** `Admin Area` → `Settings` → `Appearance`

> Para acceder al Admin Area: haz clic en el **ícono de llave/escudo** en la barra lateral izquierda inferior (solo visible para usuarios administradores).

### Configuraciones recomendadas para el bootcamp

| Campo | Valor sugerido | Propósito |
|-------|---------------|-----------|
| **Title** | `Bootcamp DevOps Lab` | Aparece en la pestaña del navegador y el encabezado |
| **Description** | `Entorno de práctica del bootcamp de GitLab CE` | Subtítulo en la página de inicio |
| **Sign-in page description** | `Bienvenido al Bootcamp DevOps. Usa tus credenciales de práctica.` | Texto en la página de login |
| **Header logo** | (opcional) | Logo de tu organización o bootcamp |
| **Favicon** | (opcional) | Ícono en la pestaña del navegador |

Guarda con el botón **Save changes** al fondo de la página.

---

## 🛠️ Paso 3: Restringir el registro público

Por defecto, GitLab permite que cualquier persona que llegue a la URL se registre como usuario. En un entorno de bootcamp o empresa, queremos control total sobre quién tiene acceso.

**Ruta de navegación:** `Admin Area` → `Settings` → `General` → expandir **Sign-up restrictions**

```
[ ] Sign-up enabled    ← DESMARCAR esta casilla
```

Al deshabilitarlo:
- La página de login ya no muestra el botón "Register"
- Solo un administrador puede crear nuevas cuentas
- Los usuarios existentes pueden seguir iniciando sesión normalmente

También configura en la misma sección:
- **Default project visibility:** `Private` (los nuevos proyectos son privados por defecto)
- **Restricted visibility levels:** Marca `Public` para que nadie pueda crear proyectos públicos

---

## 📧 Paso 4: Configurar SMTP (notificaciones por email)

Sin SMTP configurado, GitLab no puede enviar emails: ni confirmaciones de cuenta, ni notificaciones de issues, ni avisos de merge requests. Para el bootcamp es opcional, pero en producción es esencial.

### Configurar con Gmail (modo desarrollo)

Para usar Gmail necesitas una **App Password** (no tu contraseña normal):

1. Ve a `myaccount.google.com` → **Security**
2. Activa **2-Step Verification** (requerido para App Passwords)
3. Busca **App passwords** → crea una nueva para "GitLab"
4. Copia la contraseña de 16 caracteres generada

Luego agrega esto a `GITLAB_OMNIBUS_CONFIG` en tu `.env` o `docker-compose.yml`:

```yaml
GITLAB_OMNIBUS_CONFIG: |
  # ... configuración existente ...

  # ── SMTP con Gmail ──
  gitlab_rails['smtp_enable'] = true
  gitlab_rails['smtp_address'] = "smtp.gmail.com"
  gitlab_rails['smtp_port'] = 587
  gitlab_rails['smtp_user_name'] = "tu-cuenta@gmail.com"
  gitlab_rails['smtp_password'] = "xxxx xxxx xxxx xxxx"
  gitlab_rails['smtp_domain'] = "gmail.com"
  gitlab_rails['smtp_authentication'] = "login"
  gitlab_rails['smtp_enable_starttls_auto'] = true
  gitlab_rails['smtp_tls'] = false
  gitlab_rails['gitlab_email_from'] = 'tu-cuenta@gmail.com'
  gitlab_rails['gitlab_email_reply_to'] = 'noreply@gmail.com'
```

Después de editar, recrea el contenedor para aplicar:

```bash
# ¿QUÉ HACE?: Detiene y elimina el contenedor (sin tocar volúmenes)
# ¿POR QUÉ?: Los cambios en variables de entorno solo aplican al crear el contenedor
# ¿PARA QUÉ?: Aplicar la nueva configuración SMTP
docker compose up -d --force-recreate gitlab
```

### Verificar que el SMTP funciona

```bash
# ¿QUÉ HACE?: Envía un email de prueba desde la consola de Rails
# ¿POR QUÉ?: Para confirmar que la configuración SMTP es correcta antes de depender de ella
# ¿PARA QUÉ?: Detectar errores de credenciales, puertos o firewall
docker compose exec gitlab gitlab-rails runner \
  "Notify.test_email('destinatario@gmail.com', 'Test GitLab SMTP', 'Funciona!').deliver_now"
```

---

## 🕐 Paso 5: Configurar zona horaria

La zona horaria afecta cómo aparecen las fechas en issues, commits y logs.

```yaml
# En GITLAB_OMNIBUS_CONFIG:
gitlab_rails['time_zone'] = 'America/Mexico_City'
```

### Zonas horarias más usadas en LATAM

| País/Región | Zona horaria |
|-------------|-------------|
| México (Ciudad de México) | `America/Mexico_City` |
| México (Monterrey) | `America/Monterrey` |
| Colombia | `America/Bogota` |
| Argentina | `America/Argentina/Buenos_Aires` |
| Chile (Santiago) | `America/Santiago` |
| España (Madrid) | `Europe/Madrid` |
| UTC (sin zona) | `UTC` |

---

## 👤 Paso 6: Crear un usuario de trabajo (no usar root)

**Buena práctica fundamental:** No uses la cuenta `root` para el trabajo diario. `root` es el superadministrador — lo que en servidores Linux sería como trabajar siempre como `sudo`. Los errores como administrador tienen consecuencias mucho más graves.

### Crear el usuario en la UI

**Ruta:** `Admin Area` → `Overview` → `Users` → **New user**

| Campo | Valor ejemplo |
|-------|--------------|
| **Name** | `Dev User` (tu nombre real) |
| **Username** | `devuser` (sin espacios, en minúsculas) |
| **Email** | tu email real (o uno de prueba) |
| **Access level** | `Regular` (no Admin) |

Después de crear el usuario, recibirás (si SMTP está configurado) o verás en la UI un enlace para que el usuario establezca su contraseña.

### Dar permisos de administrador (opcional para el bootcamp)

Si quieres que tu usuario de trabajo también pueda administrar GitLab:

```bash
# ¿QUÉ HACE?: Cambia el nivel de acceso del usuario 'devuser' a administrador
# ¿POR QUÉ?: Permite gestionar la instancia sin usar root
# ¿PARA QUÉ?: Trabajar con una cuenta personal que tiene historial de actividad
docker compose exec gitlab gitlab-rails runner \
  "user = User.find_by_username('devuser'); user.admin = true; user.save!"
```

---

## ✅ Verificar la configuración completa

Después de todos los pasos anteriores, ejecuta este diagnóstico:

```bash
# ¿QUÉ HACE?: Ejecuta el check oficial de GitLab que verifica ~20 aspectos del sistema
# ¿POR QUÉ?: Detecta problemas de permisos, configuración y conectividad
# ¿PARA QUÉ?: Confirmar que la instalación está correctamente configurada
docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true
```

Output esperado (todo en verde):
```
Checking GitLab subtasks ...
Checking GitLab Shell ...
  GitLab Shell: ... GitLab Shell version ... OK
Checking Gitaly ...
  Gitaly: ... OK
Checking Sidekiq ...
  Sidekiq: ... Running? ... yes
  ...
GitLab subtasks are OK
```

---

## 💡 Configuraciones adicionales recomendadas

### Limitar el timeout de Git para repos grandes

```yaml
# En GITLAB_OMNIBUS_CONFIG:
gitlab_rails['git_timeout'] = 120   # segundos (default: 10)
```

### Reducir consumo de RAM en entornos limitados

```yaml
# En GITLAB_OMNIBUS_CONFIG:
puma['worker_processes'] = 1         # default: 2 workers
sidekiq['max_concurrency'] = 5       # default: 25 threads
postgresql['shared_buffers'] = '128MB'  # default: 256MB
```

> Estas reducciones afectan el rendimiento. Úsalas solo si tienes menos de 6 GB de RAM disponibles para GitLab.

---

## 🤔 Preguntas de reflexión

1. ¿Por qué el archivo `initial_root_password` tiene fecha de expiración de 24 horas? ¿Qué riesgo de seguridad mitigaría si alguien lo eliminara inmediatamente después del primer login?

2. ¿Qué consecuencias tiene configurar incorrectamente la `external_url` en relación con las notificaciones de email y los webhooks?

3. Si deshabilitas el registro público en GitLab, ¿cómo incorporas a un nuevo miembro del equipo? ¿Cuáles son las opciones?

4. ¿Por qué es importante crear un usuario de trabajo separado de `root`, incluso si eres el único administrador de la instancia?

5. Al reducir `puma['worker_processes'] = 1`, ¿qué escenario concreto de uso diario se vería degradado notablemente?

---

## 📚 Recursos adicionales

- [Configuración de SMTP en GitLab](https://docs.gitlab.com/omnibus/settings/smtp.html)
- [Restricciones de registro en GitLab](https://docs.gitlab.com/ee/administration/settings/sign_up_restrictions.html)
- [Apariencia e interfaz de GitLab](https://docs.gitlab.com/ee/administration/appearance.html)
- [gitlab-rake: comandos de administración](https://docs.gitlab.com/ee/administration/raketasks/)
- [Zonas horarias en GitLab](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-the-timezone)

---

➡️ **Siguiente lección:** [04 — Persistencia de datos y volúmenes Docker](./04-persistencia-y-volumenes.md)
