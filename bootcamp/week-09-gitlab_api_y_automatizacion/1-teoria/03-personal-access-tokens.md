# 03 — Personal Access Tokens (PAT)

Los Personal Access Tokens son el mecanismo principal de autenticación para la API de GitLab. Funcionan como sustitutos de contraseña con alcances limitados.

## Tipos de tokens

| Tipo | Alcance | Creación |
|------|---------|----------|
| Personal Access Token | Usuario individual | Settings → Access Tokens |
| Project Access Token | Proyecto específico (no ligado a usuario) | Project → Settings → Access Tokens |
| Group Access Token | Grupo y subgrupos | Group → Settings → Access Tokens |
| Impersonation Token | Admin actuando como otro usuario | Admin area |

## Scopes disponibles

- `api` — Acceso completo a la API REST y GraphQL (más amplio)
- `read_api` — Solo lectura en la API
- `read_user` — Leer información del usuario autenticado
- `create_runner` — Crear runners
- `read_repository` — Clonar y leer repositorios
- `write_repository` — Push al repositorio
- `read_registry` — Leer imágenes del container registry
- `write_registry` — Publicar imágenes

## Project y Group Tokens

Los project tokens permiten automatización sin depender de un usuario humano. Son ideales para CI/CD y bots. Un project token actúa como un miembro del proyecto con el rol que se le asigne (Guest, Reporter, Developer, Maintainer, Owner). Los group tokens extienden este concepto a nivel de grupo, heredando permisos a todos los proyectos dentro.

## Rotación de tokens

Es buena práctica rotar los tokens periódicamente (cada 30-90 días). GitLab no fuerza la rotación automática en CE, pero se puede:
1. Crear un nuevo token
2. Migrar los sistemas al nuevo token
3. Revocar el token antiguo

## Buenas prácticas

- Usar el mínimo scope necesario (principio de menor privilegio)
- No hardcodear tokens en código fuente — usar variables de entorno
- Configurar fecha de expiración para todos los tokens
- Auditar tokens activos periódicamente desde `/profile/personal_access_tokens`
