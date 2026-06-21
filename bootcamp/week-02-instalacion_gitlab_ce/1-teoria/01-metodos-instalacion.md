# 01 — Metodos de Instalacion de GitLab CE

## Objetivos

- Conocer los diferentes metodos de instalacion de GitLab CE
- Evaluar ventajas y desventajas de cada metodo
- Seleccionar el metodo adecuado segun el contexto

## Metodos de Instalacion

### 1. Omnibus Package (Linux)

El metodo oficial y mas probado. Un paquete que incluye todos los componentes necesarios (GitLab Rails, PostgreSQL, Redis, Nginx, Gitaly, Sidekiq) en un solo instalador.

**Ventajas:**
- Instalacion simple con un solo comando
- Actualizaciones automaticas via apt/yum
- Configuracion centralizada en `/etc/gitlab/gitlab.rb`
- Soporte oficial completo

**Desventajas:**
- Requiere sistema Linux dedicado
- Consume recursos incluso sin usarse
- Actualizaciones pueden ser complejas en entornos personalizados

**Comando de instalacion tipico (Ubuntu):**
```bash
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo EXTERNAL_URL="http://gitlab.example.com" apt-get install gitlab-ce
```

### 2. Docker

Usa la imagen oficial `gitlab/gitlab-ce` para desplegar GitLab en contenedores. Ideal para entornos de desarrollo, pruebas y produccion pequena.

**Ventajas:**
- Aislamiento de dependencias
- Rapido de levantar y destruir
- Portabilidad entre maquinas
- Facil integracion con Docker Compose

**Desventajas:**
- Rendimiento ligeramente inferior al Omnibus nativo
- Configuracion de red mas compleja (HTTP/HTTPS, puertos)
- Persistencia de datos requiere configuracion de volumenes

### 3. Kubernetes / Helm

Para despliegues a gran escala en clusters de Kubernetes usando el Helm chart oficial de GitLab.

**Ventajas:**
- Escalabilidad horizontal
- Alta disponibilidad (HA)
- Gestion declarativa de infraestructura
- Integracion nativa con ecosistema cloud-native

**Desventajas:**
- Complejidad operativa elevada
- Requiere conocimientos de Kubernetes
- Mayor consumo de recursos (overhead de orquestacion)

### 4. GitLab Operator (OpenShift)

Operador para Red Hat OpenShift que automatiza el ciclo de vida de GitLab.

## Recomendacion para el Bootcamp

Usaremos **Docker Compose** por ser el equilibrio ideal entre simplicidad y fidelidad al entorno real. Permite levantar una instancia completa en minutos y es facil de destruir/recrear durante las practicas.
