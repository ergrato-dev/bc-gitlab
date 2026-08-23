# 📖 01 — Métodos de Instalación de GitLab CE

## 🎯 Objetivos de aprendizaje

- ✅ Conocer los cuatro métodos oficiales de instalación de GitLab CE
- ✅ Comparar ventajas y desventajas de cada método según el contexto
- ✅ Entender por qué Docker Compose es la elección ideal para este bootcamp
- ✅ Identificar los requisitos de hardware mínimos para una instalación funcional

---

## 🤔 ¿Por qué hay varios métodos de instalación?

GitLab es una aplicación enorme. Por dentro incluye: un servidor web (Nginx), una base de datos (PostgreSQL), un sistema de caché (Redis), un servidor Git (Gitaly), un procesador de trabajos en segundo plano (Sidekiq) y docenas de servicios más. Instalar todo eso de forma coherente y reproducible es un desafío de ingeniería.

Por eso GitLab ofrece múltiples métodos de instalación, cada uno optimizado para un caso de uso distinto.

**Analogía del mundo real:** Imagina que quieres montar una oficina. Puedes construirla desde cero ladrillo a ladrillo (más control, más trabajo), comprar una oficina prefabricada modular (más rápida, portátil), rentar un coworking en la nube (sin mantenimiento) o contratar a alguien que la administre por ti. Cada opción tiene su lugar.

---

## 🛠️ Los cuatro métodos oficiales

### 1. Omnibus Package (paquete nativo Linux)

El método tradicional y más probado. Un único paquete `.deb` o `.rpm` instala GitLab directamente en el sistema operativo, incluyendo todos sus componentes como un bloque monolítico.

```bash
# ¿QUÉ HACE?: Agrega el repositorio oficial de GitLab al sistema de paquetes
# ¿POR QUÉ?: Para poder instalar con apt/yum el paquete gitlab-ce
# ¿PARA QUÉ?: Obtener la versión más reciente directamente de GitLab Inc.
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

# ¿QUÉ HACE?: Instala GitLab CE con la URL de acceso configurada desde el inicio
# ¿POR QUÉ?: EXTERNAL_URL determina cómo GitLab construye sus URLs internas (webhooks, SSH, emails)
# ¿PARA QUÉ?: Después de este comando GitLab queda operativo en el servidor
sudo EXTERNAL_URL="http://gitlab.example.com" apt-get install gitlab-ce
```

La configuración se centraliza en `/etc/gitlab/gitlab.rb` y se aplica con `sudo gitlab-ctl reconfigure`.

> **Analogía:** Instalar Omnibus es como instalar un electrodoméstico empotrado en tu casa. Funciona muy bien y es eficiente, pero está integrado al inmueble: si quieres moverlo a otro servidor o reinstalarlo, es un proceso de demolición y reconstrucción.

---

### 2. Docker / Docker Compose

Utiliza la imagen oficial `gitlab/gitlab-ce` de Docker Hub. GitLab corre dentro de un contenedor completamente aislado del sistema operativo anfitrión.

```bash
# ¿QUÉ HACE?: Levanta todos los servicios definidos en docker-compose.yml en segundo plano
# ¿POR QUÉ?: Docker Compose orquesta múltiples contenedores como una unidad coherente
# ¿PARA QUÉ?: Tener GitLab CE + Runner + monitoreo listos con un solo comando
docker compose up -d
```

> **Analogía:** Docker es como una "casa prefabricada modular". Llega lista para habitar, puedes moverla de un terreno a otro sin tocar el suelo, y si algo falla puedes reemplazar solo esa habitación sin afectar a los vecinos.

**Este es el método que usamos en el bootcamp.** Veremos todos los detalles en la siguiente lección.

---

### 3. Kubernetes / Helm

Para organizaciones que ya tienen un clúster de Kubernetes. El Helm chart oficial de GitLab despliega cada componente como un pod separado, permitiendo escalabilidad horizontal e independiente de cada servicio.

```bash
# ¿QUÉ HACE?: Agrega el repositorio de Helm charts oficial de GitLab
# ¿POR QUÉ?: Helm gestiona dependencias y versiones de los charts de Kubernetes
# ¿PARA QUÉ?: Poder instalar y actualizar GitLab declarativamente en k8s
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# ¿QUÉ HACE?: Instala GitLab en Kubernetes usando la configuración del archivo values.yaml
# ¿POR QUÉ?: values.yaml centraliza dominios, TLS, tamaños de réplicas, storage class
# ¿PARA QUÉ?: Despliegue en alta disponibilidad con escalado automático de pods
helm install gitlab gitlab/gitlab -f values.yaml
```

> **Analogía:** Kubernetes es como un edificio de oficinas administrado profesionalmente. Tienes conserje, elevadores redundantes y generador de emergencia, pero también pagas renta corporativa y necesitas conocer el reglamento del edificio de 200 páginas.

---

### 4. GitLab Operator (OpenShift)

Operador de Kubernetes diseñado específicamente para Red Hat OpenShift. Automatiza el ciclo de vida completo: instalación, actualización, backup y recuperación ante desastres.

Orientado a empresas que ya tienen infraestructura OpenShift y quieren gestionar GitLab como un "ciudadano de primera clase" en su plataforma enterprise.

---

## 📊 Comparativa completa de métodos

| Criterio | Omnibus | Docker Compose | Kubernetes/Helm | GitLab Operator |
|----------|---------|----------------|-----------------|-----------------|
| **Complejidad inicial** | Baja | Baja | Alta | Muy alta |
| **Complejidad operativa** | Media | Baja | Alta | Alta |
| **Aislamiento del SO** | ❌ Sin aislamiento | ✅ Contenedor | ✅ Pods | ✅ Pods |
| **Portabilidad** | ❌ Ligado al SO | ✅ Cualquier host Docker | ✅ Cualquier k8s | ⚠️ Solo OpenShift |
| **Alta disponibilidad** | ⚠️ Manual y complejo | ❌ No nativo | ✅ Nativo | ✅ Nativo |
| **Actualizaciones** | `apt upgrade` | Cambiar imagen + `up` | `helm upgrade` | Operator automático |
| **Caso de uso principal** | Servidor dedicado | Dev / staging / PYMES | Grandes organizaciones | Empresas OpenShift |
| **Requisito previo** | Linux + sudo | Docker instalado | Clúster Kubernetes | OpenShift + Operator |
| **Ideal para bootcamp** | ⚠️ Posible | ✅ **Perfecto** | ❌ Excesivo | ❌ Excesivo |

---

## 🚀 Docker Compose vs Omnibus — La elección del bootcamp

```
╔══════════════════════════════════════════════════════════════╗
║         ¿POR QUÉ DOCKER COMPOSE Y NO OMNIBUS?              ║
╠══════════════════════════════════════════════════════════════╣
║  Factor              │ Docker Compose       │ Omnibus        ║
║──────────────────────┼──────────────────────┼────────────────║
║  Instalación         │ docker compose up    │ Script + apt   ║
║  Desinstalación      │ docker compose down  │ apt remove +   ║
║                      │       -v             │ limpieza manual║
║  Aislamiento         │ ✅ Contenedor        │ ❌ En el SO    ║
║  Múltiples versiones │ ✅ Cambiar imagen    │ ❌ Muy complejo║
║  Reproducibilidad    │ ✅ Mismo compose.yml │ ⚠️ Script propio║
║  Telemetría          │ ✅ Deshabilitada     │ ⚠️ Revisar cfg ║
║  Portabilidad        │ ✅ Mac/Linux/WSL2    │ ❌ Solo Linux  ║
║  Precio del error    │ 🟢 Bajo (down -v)   │ 🔴 Alto        ║
║  Transferible a prod │ ✅ Mismos conceptos  │ ✅ Mismos cmds ║
╚══════════════════════════════════════════════════════════════╝
```

La experiencia con Docker Compose es **directamente transferible a producción**: los mismos volúmenes, puertos y variables de entorno aplican en servidores reales. Lo que aprendes hoy lo puedes usar el primer día de trabajo en una empresa.

---

## 📊 Requisitos de hardware

| Componente | Mínimo (funciona) | Recomendado (bootcamp) | Producción pequeña |
|------------|-------------------|------------------------|--------------------|
| **CPU** | 2 cores | 4 cores | 8+ cores |
| **RAM** | 4 GB | 8 GB | 16+ GB |
| **Disco libre** | 10 GB | 20 GB SSD | 50+ GB SSD |
| **Red** | 1 Mbps | 10 Mbps | 100+ Mbps |
| **Docker Engine** | 20+ | 27+ | 27+ |
| **Docker Compose** | 2.20+ | 2.32+ | 2.32+ |

⚠️ **GitLab CE es famoso por su consumo de RAM**. Con menos de 4 GB verás errores 502 frecuentes y el contenedor se reiniciará de forma impredecible. Con 8 GB funciona de forma estable para todas las prácticas del bootcamp.

> **Nota sobre macOS con Docker Desktop:** Asegúrate de asignar al menos 8 GB de RAM al daemon en `Docker Desktop → Settings → Resources → Memory`. Por defecto Docker Desktop solo asigna la mitad de la RAM del sistema.

---

## 💡 ¿Qué pasa "debajo del capó"?

Cuando instalas GitLab CE (por cualquier método), obtienes todos estos servicios integrados:

```
┌─────────────────────────────────────────────────────┐
│                 GitLab CE (Omnibus)                 │
│                                                     │
│  ┌─────────┐    ┌──────────┐    ┌──────────────┐   │
│  │  Nginx  │    │   Puma   │    │   Sidekiq    │   │
│  │(web srv)│    │(app Ruby)│    │(jobs async)  │   │
│  └────┬────┘    └────┬─────┘    └──────┬───────┘   │
│       │              │                  │            │
│  ┌────┴──────────────┴──────────────────┴────────┐  │
│  │                GitLab Rails                   │  │
│  └────┬──────────────┬──────────────────┬────────┘  │
│       │              │                  │            │
│  ┌────┴────┐  ┌──────┴──────┐  ┌───────┴──────┐    │
│  │PostgreSQL│  │    Redis    │  │    Gitaly    │    │
│  │  (DB)   │  │  (caché)    │  │(repos Git)   │    │
│  └──────────┘  └────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────┘
```

Con Docker Compose, este bloque completo vive dentro de un único contenedor `gitlab`, lo que simplifica enormemente la gestión sin sacrificar funcionalidad.

---

## 🤔 Preguntas de reflexión

1. ¿Qué ventaja específica tiene Docker Compose sobre Omnibus cuando un desarrollador quiere probar dos versiones distintas de GitLab en la misma máquina simultáneamente?

2. Si tu empresa ya tiene Kubernetes en producción, ¿por qué podría seguir eligiendo Docker Compose para el entorno de desarrollo local en lugar del Helm chart?

3. ¿Por qué el campo `external_url` es crítico en la instalación de GitLab? ¿Qué ocurre si lo configuras incorrectamente y ya tienes proyectos con miles de commits?

4. Los requisitos mínimos indican 4 GB de RAM, pero la recomendación del bootcamp es 8 GB. ¿Cómo se manifiesta en la práctica esa diferencia de 4 GB?

5. ¿Qué significa que Docker Compose tenga "bajo precio del error"? Da un ejemplo concreto de un error de configuración que en Omnibus costaría horas corregir y en Docker se resuelve en 30 segundos.

---

## 📚 Recursos adicionales

- [Documentación oficial: métodos de instalación de GitLab](https://about.gitlab.com/install/)
- [Documentación oficial: instalación con Docker](https://docs.gitlab.com/ee/install/docker/)
- [Imagen oficial en Docker Hub — gitlab/gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce)
- [Requisitos de sistema de GitLab CE](https://docs.gitlab.com/ee/install/requirements.html)
- [Comparativa de ediciones: CE vs EE](https://about.gitlab.com/pricing/feature-comparison/)

---

➡️ **Siguiente lección:** [02 — Instalación con Docker Compose paso a paso](./02-instalacion-docker.md)
