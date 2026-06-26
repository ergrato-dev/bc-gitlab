# 🛠️ Práctica 03 — Configuración Post-Instalación

⏱️ **Tiempo estimado:** 45 minutos  
⭐ **Dificultad:** Básico-Intermedio  
📋 **Prerrequisitos:** Práctica 02 completada — GitLab CE corriendo y accesible en `http://localhost`

---

## 🎯 Objetivo

Dejar GitLab CE completamente configurado para el bootcamp: contraseña cambiada, apariencia personalizada, registro deshabilitado, usuario de trabajo creado y proyecto de prueba funcionando.

---

## Paso 1: Cambiar la contraseña de root

La contraseña inicial es temporal y debe cambiarse en el primer login.

**Navegación:** `http://localhost` → login como `root` → avatar (esquina superior derecha) → **Edit profile** → menú lateral → **Password**

1. En el campo **Current password**: introduce la contraseña inicial
2. En **New password**: una contraseña segura (mínimo 8 caracteres, mayúsculas, números)
3. En **Password confirmation**: repite la nueva contraseña
4. Haz clic en **Save password**
5. GitLab te redirigirá al login — inicia sesión con la nueva contraseña

✅ **Verificación:** Puedes iniciar sesión con la nueva contraseña.

---

## Paso 2: Configurar la apariencia de la instancia

**Navegación:** menú lateral izquierdo (ícono de escudo/llave) → **Admin Area** → **Settings** → **Appearance**

Configura los siguientes campos:

| Campo | Valor |
|-------|-------|
| **Title** | `Bootcamp DevOps Lab` |
| **Description** | `Instancia de práctica GitLab CE` |
| **Sign-in page description** | `Bienvenido al Bootcamp. Usa tus credenciales de práctica.` |
| **New project guidelines** | `Sigue las convenciones de nomenclatura del bootcamp: kebab-case, inglés.` |

Haz clic en **Save changes** al fondo de la página.

✅ **Verificación:** Cierra sesión y verifica que la página de login muestra el texto que configuraste.

---

## Paso 3: Deshabilitar el registro público

**Navegación:** **Admin Area** → **Settings** → **General** → expandir **Sign-up restrictions**

```
Desmarcar: [ ] Sign-up enabled
```

Haz clic en **Save changes**.

En la misma sección, también configura:

**Visibility and access controls** (en Settings → General):
- **Default project visibility:** `Private`
- **Default group visibility:** `Private`

✅ **Verificación:** Abre una ventana de incógnito en el navegador y ve a `http://localhost`. La página de login NO debe mostrar el botón "Register" ni "Create an account".

---

## Paso 4: Configurar zona horaria

**Navegación:** **Admin Area** → **Settings** → **Preferences** → **Localization**

Selecciona tu zona horaria (ejemplo: `(UTC-06:00) Guadalajara, Mexico City, Monterrey`).

Haz clic en **Save changes**.

Alternativamente, agrégalo directamente en el `docker-compose.yml`:

```yaml
# En GITLAB_OMNIBUS_CONFIG:
gitlab_rails['time_zone'] = 'America/Mexico_City'
```

---

## Paso 5: Crear usuario de trabajo (no usar root)

Es una mala práctica usar `root` para el trabajo diario. Crea un usuario personal.

**Navegación:** **Admin Area** → **Overview** → **Users** → **New user**

| Campo | Valor |
|-------|-------|
| **Name** | Tu nombre completo |
| **Username** | tu-nombre (sin espacios, minúsculas) |
| **Email** | Tu email de contacto |
| **Access level** | Regular |

Haz clic en **Create user**.

### Establecer contraseña para el nuevo usuario

Después de crear el usuario, haz clic en su nombre → **Edit** → sección **Password** → introduce una contraseña y confirma → **Save changes**.

✅ **Verificación:** Abre una ventana de incógnito, ve a `http://localhost` e inicia sesión con el nuevo usuario. Debes poder entrar al dashboard.

---

## Paso 6: Verificar servicios internos con gitlab-rake

```bash
# ¿QUÉ HACE?: Ejecuta el check oficial de GitLab que valida ~20 aspectos del sistema
# ¿POR QUÉ?: Detecta problemas de permisos, configuración de red y conectividad
# ¿PARA QUÉ?: Confirmar que la instalación está correcta antes de usarla en el bootcamp
docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true
```

✅ **Output esperado:** Todo en verde (`... OK`) o con solo advertencias menores.

```bash
# ¿QUÉ HACE?: Muestra el estado de cada servicio interno (Puma, Sidekiq, PostgreSQL, etc.)
# ¿POR QUÉ?: Confirma que todos los servicios internos están activos
# ¿PARA QUÉ?: Tener una foto del estado "sano" antes de continuar
docker compose exec gitlab gitlab-ctl status
```

---

## Paso 7: Crear un proyecto de prueba con un commit

Inicia sesión como tu usuario de trabajo (no root) y crea un proyecto:

**Navegación:** Dashboard → **New project** → **Create blank project**

| Campo | Valor |
|-------|-------|
| **Project name** | `hello-gitlab` |
| **Project slug** | `hello-gitlab` (se autorrellena) |
| **Visibility Level** | Private |
| **Initialize repository** | ✅ Marcado |

Haz clic en **Create project**.

### Agregar un archivo desde la UI

1. En la página del proyecto → **+ (botón)** → **New file**
2. Nombre del archivo: `README.md`
3. Contenido:
   ```markdown
   # Hello GitLab
   
   Mi primer proyecto en el bootcamp de GitLab CE.
   Instancia instalada el: [fecha de hoy]
   ```
4. En **Commit message:** `Initial commit — bootcamp week 02`
5. Haz clic en **Commit changes**

✅ **Verificación:** El proyecto debe mostrar el `README.md` con el contenido que escribiste, y el contador de commits debe ser `1`.

---

## Paso 8: Documentar el proceso en INSTALL.md

Como parte del entregable de la semana, debes crear un `INSTALL.md` en el proyecto `hello-gitlab` documentando tu instalación.

**Navegación:** En el proyecto → **+ (botón)** → **New file** → nombre: `INSTALL.md`

El `INSTALL.md` debe incluir:

```markdown
# Instalación de GitLab CE — Bootcamp Week 02

## Fecha de instalación
[Fecha]

## Versión de GitLab CE instalada
[Output de: docker compose exec gitlab gitlab-ce --version]

## Sistema operativo del host
[Output de: uname -a]

## Recursos del sistema
- RAM: [X GB]
- CPU: [X cores]
- Disco disponible: [X GB]

## Puertos configurados
- HTTP: 80
- HTTPS: 443
- SSH: 2224

## Pasos realizados
1. Cloné el repositorio bc-gitlab
2. Copié .env.example a .env
3. Ejecuté docker compose up -d
4. Esperé ~[N] minutos a que el healthcheck dijera "healthy"
5. Cambié la contraseña de root
6. Configuré la apariencia
7. Deshabilité el registro público
8. Creé el usuario de trabajo: [username]
9. Ejecuté gitlab-rake gitlab:check (todo OK)

## Problemas encontrados y soluciones
[Si tuviste algún problema, documentarlo aquí]

## Comandos útiles de administración
- docker compose ps — ver estado
- docker compose logs -f gitlab — ver logs
- docker compose exec gitlab gitlab-ctl status — servicios internos
- docker compose exec gitlab gitlab-rake gitlab:check — sanity check
```

Commitea el archivo: **Commit message:** `docs: add INSTALL.md with installation notes`

---

## 🚨 Troubleshooting

| Problema | Causa | Solución |
|---------|-------|----------|
| No aparece **Admin Area** en el menú | Sesión como usuario no-admin | Inicia sesión como `root` |
| El nuevo usuario no puede iniciar sesión | Contraseña no configurada | Admin Area → Users → [usuario] → Edit → Password |
| `gitlab:check` muestra errores de permisos | Primer inicio aún no completó | Esperar y volver a ejecutar |
| El proyecto no aparece en el dashboard | Creado con otro usuario | Verificar que estás logueado con el usuario correcto |
| No puedo crear el proyecto | Límite de proyectos | Admin Area → Settings → General → Limits → aumentar |

---

## 📝 Entregable

1. Screenshot de **Admin Area → Appearance** con tu configuración
2. Screenshot de la página de login en modo incógnito (sin botón de registro)
3. Screenshot del proyecto `hello-gitlab` con el README.md y al menos 2 commits
4. Output del comando `docker compose exec gitlab gitlab-ctl status` (todos en `run:`)
5. El `INSTALL.md` creado en el proyecto `hello-gitlab`

---

➡️ **Siguiente práctica:** [04 — Backup y Restore](../04-backup-y-restore/README.md)
