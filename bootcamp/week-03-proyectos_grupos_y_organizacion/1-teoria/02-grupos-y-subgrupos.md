# 02 — Grupos y Subgrupos en GitLab

## Objetivos

- Entender la organizacion jerarquica en GitLab
- Crear grupos y subgrupos
- Gestionar proyectos dentro de grupos
- Configurar ajustes compartidos a nivel de grupo

## Que son los Grupos?

Un grupo en GitLab funciona como un namespace que agrupa proyectos relacionados. Es analogo a una organizacion o departamento.

### Jerarquia de Grupos

GitLab soporta hasta 20 niveles de subgrupos, permitiendo estructuras como:

```
mi-empresa/                          (grupo raiz)
├── frontend/                        (subgrupo)
│   ├── web-app/                     (proyecto)
│   └── landing-page/                (proyecto)
├── backend/                         (subgrupo)
│   ├── api-gateway/                 (proyecto)
│   └── auth-service/                (proyecto)
└── devops/                          (subgrupo)
    ├── infrastructure/              (proyecto - codigo terraform)
    └── pipelines/                   (proyecto - shared CI configs)
```

## Beneficios de los Grupos

- **Organizacion**: Agrupa proyectos relacionados
- **Permisos heredados**: Miembros de un grupo heredan acceso a subgrupos
- **Configuracion compartida**: CI/CD variables, runners, webhooks a nivel grupo
- **Visibilidad por area**: Diferentes niveles de acceso por grupo
- **Milestones compartidos**: Issues y MRs pueden compartir milestones entre proyectos

## Crear un Grupo

### Via Web UI
1. **Groups → New Group** (o desde dashboard)
2. Completar:
   - **Group name**: Nombre del grupo
   - **Group URL**: Namespace en la URL
   - **Visibility level**: Private, Internal o Public
   - **Role**: Que rol tendras en el grupo
   - Opcionalmente elegir grupo padre para crear subgrupo

### Via API
```bash
curl --request POST \
  --header "PRIVATE-TOKEN: <tu-token>" \
  --data "name=backend&path=backend&parent_id=123" \
  "http://localhost/api/v4/groups"
```

## Configuracion de Grupo

En la pagina del grupo, sidebar izquierdo:

- **Group information**: Nombre, descripcion, avatar
- **Members**: Gestionar miembros y roles
- **Projects**: Proyectos en este grupo
- **Subgroups**: Subgrupos anidados
- **Settings**: General, CI/CD, Integrations, Webhooks, Access Tokens

## Subgrupos

Los subgrupos heredan:
- Miembros del grupo padre (con mismo rol o superior)
- Permisos y restricciones del grupo padre
- Configuracion de CI/CD (runners, variables)

Pueden sobrescribir: visibilidad (mas restrictiva, no mas permisiva)

## Buenas Practicas

1. **Estructura por producto/dominio**: `empresa/producto-a/`, `empresa/producto-b/`
2. **Estructura por equipo**: `empresa/frontend/`, `empresa/backend/`
3. **Estructura mixta**: `empresa/producto-a/backend/`, `empresa/producto-b/frontend/`
4. Mantener maximo 3-4 niveles de profundidad
5. Usar visibilidad Private como default, solo exponer lo necesario
