# Practica 02 — Grupos y Subgrupos

## Objetivo
Crear una estructura organizacional jerarquica con grupos y subgrupos, y asignar proyectos dentro de ella.

## Instrucciones

### 1. Crear grupo raiz

1. **Groups → New Group**
2. Nombre: `Bootcamp-Org`
3. URL: `bootcamp-org`
4. Visibility: Private
5. Crear

### 2. Crear subgrupos

Dentro de Bootcamp-Org, crea la siguiente estructura:

```
Bootcamp-Org/
├── frontend/
├── backend/
└── devops/
```

Para cada subgrupo:
1. Entrar a **Bootcamp-Org**
2. **New subgroup**
3. Nombre y visibilidad Private
4. Repetir para los 3

### 3. Crear proyectos dentro de los subgrupos

| Subgrupo | Proyecto | Descripcion |
|----------|---------|-------------|
| frontend | web-app | Aplicacion web principal |
| frontend | mobile-app | Aplicacion movil |
| backend | api-gateway | API Gateway |
| backend | auth-service | Servicio de autenticacion |
| devops | infrastructure | IaC con Terraform |
| devops | ci-cd-pipelines | Shared CI/CD configs |

### 4. Verificar la estructura

1. Ve a **Bootcamp-Org**
2. Sidebar → **Subgroups and projects**
3. Verifica que se vea la jerarquia completa

## Entregable
- Captura de la pagina de **Bootcamp-Org** mostrando subgrupos y proyectos
- URL de 2 proyectos (ej: `http://localhost/bootcamp-org/backend/auth-service`)
