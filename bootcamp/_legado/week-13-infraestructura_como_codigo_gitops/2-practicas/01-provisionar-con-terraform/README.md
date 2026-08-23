# Práctica 01 — Provisionar un Proyecto y Grupo GitLab con Terraform

## Objetivo

Instalar Terraform, configurar el provider de GitLab, y ejecutar el ciclo completo `init` → `plan` → `apply` para crear un grupo y un proyecto en la instancia GitLab CE del bootcamp, gestionando el state de forma remota con GitLab Managed Terraform State.

## Requisitos

- Terraform >= 1.7 instalado (`terraform version`)
- GitLab CE corriendo y accesible en `http://localhost`
- Un Personal Access Token con scope `api`
- Tiempo estimado: 45-60 minutos

---

## Instrucciones

### Paso 1: Preparar el directorio de trabajo

```bash
mkdir -p ~/terraform-gitlab-bootcamp && cd ~/terraform-gitlab-bootcamp
cp -r /ruta/al/starter/* .
```

Revisa los archivos del `starter/`: `providers.tf`, `variables.tf`, `main.tf`, `backend.tf`.

### Paso 2: Exportar el token como variable de entorno

```bash
# ¿QUÉ HACE?: Expone el token a Terraform vía la convención TF_VAR_<nombre>
# ¿POR QUÉ?: Nunca se escribe el token directamente en un archivo .tf versionado
# ¿PARA QUÉ?: Que provider "gitlab" { token = var.gitlab_token } lo reciba sin exponerlo en Git
export TF_VAR_gitlab_token="glpat-XXXXXXXXXXXXXXXXXXXX"
```

### Paso 3: Crear un proyecto para alojar el state remoto

Antes de usar el backend `http`, necesitas un proyecto GitLab que aloje el state. Créalo manualmente (o reutiliza uno existente) y anota su ID:

```bash
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=terraform-state" | jq '.[] | {id, name}'
```

### Paso 4: Configurar el backend remoto

Edita `backend.tf` con el ID del proyecto obtenido en el paso anterior, luego inicializa:

```bash
# ¿QUÉ HACE?: Descarga el provider de GitLab y conecta con el backend remoto
# ¿POR QUÉ?: init debe ejecutarse antes de cualquier plan/apply, y de nuevo si cambia el backend
# ¿PARA QUÉ?: Dejar el directorio listo, con el state gestionado por GitLab, no en local
terraform init \
  -backend-config="address=http://localhost/api/v4/projects/<ID>/terraform/state/practica-01" \
  -backend-config="lock_address=http://localhost/api/v4/projects/<ID>/terraform/state/practica-01/lock" \
  -backend-config="unlock_address=http://localhost/api/v4/projects/<ID>/terraform/state/practica-01/lock" \
  -backend-config="username=terraform-bot" \
  -backend-config="password=$TF_VAR_gitlab_token" \
  -backend-config="lock_method=POST" \
  -backend-config="unlock_method=DELETE"
```

### Paso 5: Revisar y aplicar el plan

```bash
# ¿QUÉ HACE?: Calcula qué recursos se crearán, sin tocar nada todavía
# ¿POR QUÉ?: Nunca se aplica un cambio de infraestructura sin ver el plan primero
# ¿PARA QUÉ?: Confirmar que solo se crean el grupo y el proyecto esperados (0 to change, 0 to destroy)
terraform plan -out=tfplan

# Revisa la salida: debe mostrar "Plan: 2 to add, 0 to change, 0 to destroy"

terraform apply tfplan
```

### Paso 6: Verificar en la UI y por API

```bash
# Verificar por API que el proyecto existe con los atributos declarados
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/projects?search=practica-terraform" | jq '.[] | {id, name, visibility}'
```

Abre **Operate → Terraform states** en la UI del proyecto que aloja el state y confirma que `practica-01` aparece listado con la fecha del último apply.

### Paso 7: Modificar y volver a aplicar (demostrar idempotencia)

```bash
# Cambia la descripción del proyecto en main.tf, luego:
terraform plan -out=tfplan
# → Plan: 0 to add, 1 to change, 0 to destroy  (solo el atributo modificado)
terraform apply tfplan

# Ejecuta apply de nuevo sin cambios en el código:
terraform apply -auto-approve
# → Apply complete! Resources: 0 added, 0 changed, 0 destroyed.  (idempotencia confirmada)
```

---

## Preguntas de reflexión

1. ¿Qué pasaría si dos personas ejecutan `terraform apply` sobre el mismo state remoto al mismo tiempo? ¿Cómo lo previene GitLab?
2. ¿Por qué `terraform.tfstate` nunca debe versionarse en Git, pero `terraform.lock.hcl` sí?
3. Si alguien borra el proyecto manualmente desde la UI de GitLab, ¿qué mostrará el próximo `terraform plan`?

---

## Entregables

- [ ] `terraform init` ejecutado con backend remoto configurado
- [ ] Grupo y proyecto creados vía `terraform apply`, visibles en la UI de GitLab
- [ ] State remoto visible en Operate → Terraform states
- [ ] Captura de un `plan` que muestre 0 cambios tras aplicar (idempotencia)
- [ ] Respuestas a las preguntas de reflexión
