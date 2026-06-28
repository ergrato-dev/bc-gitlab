# 01 — Planificación del Proyecto Final

El proyecto final integra todos los conocimientos del bootcamp en una plataforma DevOps funcional. Semanas 01 a 11 construyeron piezas individuales — esta semana las ensamblas en un sistema cohesivo y demostrable. La planificación previa determina si el proyecto queda funcional o incompleto.

![Arquitectura integrada del proyecto final](../0-assets/01-arquitectura-final.svg)

---

## Definición del alcance

Antes de escribir una sola línea de configuración, responde estas tres preguntas con precisión:

**¿Qué aplicación vas a desplegar?**

La aplicación de ejemplo es el vehículo para demostrar la plataforma, no el objetivo en sí. Debe cumplir:
- Tiene tests unitarios ejecutables desde CLI
- Tiene `Dockerfile` para construir imagen
- Tiene dependencias declaradas (requirements.txt, package.json, go.mod, pom.xml)
- Sus tests terminan en menos de 3 minutos (para que el pipeline sea ágil en demos)

Opciones recomendadas:
| Lenguaje | Framework | Tests | Tiempo estimado |
|----------|----------|-------|----------------|
| Python | Flask | pytest | ✅ Fácil de configurar |
| Node.js | Express | jest | ✅ Ecosistema familiar |
| Go | net/http | go test | ✅ Compilación rápida |
| Java | Spring Boot | JUnit | ⚠️ Build más lento |

**¿Qué entornos tendrás?**

Mínimo: `staging` y `production`.

- **Staging**: deploy automático en cada merge a `main`
- **Production**: deploy manual (tag o botón en GitLab UI)

Pueden estar en el mismo Docker Compose (puertos diferentes) o en contenedores separados.

**¿Qué herramientas de seguridad incluirás?**

Para el proyecto final en CE son obligatorias:
- SAST (analyzer según el lenguaje elegido)
- Secret Detection (detecta tokens hardcodeados)
- Container Scanning (vulnerabilidades en la imagen)

Opcional pero recomendado: Dependency Scanning.

---

## Arquitectura del sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Servidor host (Docker)                           │
│                                                                      │
│  ┌────────────┐    ┌──────────────┐    ┌───────────────────────┐   │
│  │  GitLab CE │    │ GitLab Runner│    │ Prometheus + Grafana  │   │
│  │  :80/:443  │    │  (Docker)    │    │  :9090 / :3000        │   │
│  │            │    │              │    │                       │   │
│  │ PostgreSQL │    │ Ejecuta jobs │    │ Dashboard métricas    │   │
│  │ Redis      │    │ de CI/CD     │    │ de GitLab             │   │
│  │ Gitaly     │    └──────────────┘    └───────────────────────┘   │
│  │ Registry   │                                                      │
│  └────────────┘                                                      │
│                                                                      │
│  ┌────────────────────────┐    ┌──────────────────────────────┐    │
│  │   MinIO (S3 local)     │    │   App de ejemplo             │    │
│  │   :9000/:9001          │    │   staging: :5001             │    │
│  │   Destino de backups   │    │   production: :5000          │    │
│  └────────────────────────┘    └──────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

Flujo CI/CD:
Developer push → GitLab → Pipeline triggers → Runner ejecuta →
build → test → security → deploy-staging (automático) →
deploy-production (manual via tag)
```

---

## Plan de trabajo por sesiones

La semana 12 se estructura en 4 sesiones de trabajo. Cada sesión tiene un objetivo claro y entregables verificables.

| Sesión | Duración | Objetivo | Entregable verificable |
|--------|---------|----------|----------------------|
| Sesión 1 | 4h | Infraestructura + Runner | `docker-compose ps` muestra todos UP |
| Sesión 2 | 4h | Pipeline CI/CD completo | Pipeline corre sin errores en push |
| Sesión 3 | 4h | Seguridad + Monitoreo | SAST reporta hallazgos, Grafana muestra métricas |
| Sesión 4 | 4h | Documentación + Defensa | README funcional, demo ensayada |

---

## Estructura de directorios del proyecto

```
proyecto-final/
├── docker-compose.yml          # Infraestructura completa (GitLab, Runner, Prometheus, MinIO)
├── .env.example                # Plantilla de variables (SÍ commitear)
├── .env                        # Valores reales (NUNCA commitear, en .gitignore)
├── .gitignore                  # Excluye .env, __pycache__, *.pyc, node_modules
├── .gitlab-ci.yml              # Pipeline principal
│
├── app/                        # Aplicación de ejemplo
│   ├── Dockerfile
│   ├── src/                    # Código fuente
│   ├── tests/                  # Tests unitarios
│   └── requirements.txt        # o package.json, go.mod
│
├── ci-templates/               # Templates CI reutilizables
│   ├── build.yml
│   ├── test.yml
│   └── deploy.yml
│
├── monitoring/                 # Stack de monitoreo
│   ├── prometheus.yml
│   └── grafana-datasources.yml
│
├── backup/                     # Scripts de backup
│   ├── backup.sh
│   └── restore.sh
│
└── docs/                       # Documentación operacional
    ├── arquitectura.md         # Diagrama + tabla de componentes
    ├── manual-operaciones.md   # Guía para nuevos administradores
    └── disaster-recovery.md    # Runbooks de DR con RTO/RPO
```

---

## Criterios de aceptación obligatorios

Antes de la presentación, cada uno de estos puntos debe funcionar en un entorno limpio (sin datos residuales de sesiones anteriores):

```bash
# ¿QUÉ HACE?: Verifica la infraestructura desde cero
# ¿POR QUÉ?: El evaluador hará exactamente esto — levantará el proyecto desde git clone
# ¿PARA QUÉ?: Confirmar que la documentación es suficiente para reproducir el entorno

# Paso 1: Clonar y configurar
git clone http://gitlab.local/grupo/proyecto-final.git
cd proyecto-final
cp .env.example .env
# Editar .env con los valores de tu entorno

# Paso 2: Levantar infraestructura
docker compose up -d

# Paso 3: Esperar que GitLab inicie (2-4 minutos)
until curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "30[0-9]"; do
  echo "Esperando GitLab..."; sleep 15
done
echo "GitLab disponible"

# Paso 4: Verificar todos los servicios
docker compose ps
# → Todos deben estar en estado "healthy" o "Up"

# Paso 5: Push de código y verificar pipeline
git push origin main
# → Pipeline debe iniciar en < 30 segundos

# Paso 6: Verificar monitoreo
curl -s http://localhost:9090/-/healthy && echo "Prometheus OK"
curl -s http://localhost:3000/api/health | jq '.database'

# Paso 7: Ejecutar backup
./backup/backup.sh
ls -lh /tmp/gitlab-backup/  # o el directorio configurado
```

---

## Gestión de tiempo en la demo

El error más común en la defensa es quedarse sin tiempo. Prepara un cronómetro:

| Segmento | Tiempo | Contenido |
|---------|--------|-----------|
| Introducción | 2 min | Quién eres, objetivo del proyecto |
| Arquitectura | 2 min | Diagrama, componentes, decisiones |
| Demo infraestructura | 2 min | `docker compose ps`, GitLab UI |
| Demo pipeline | 3 min | Push en vivo, mostrar stages |
| Demo seguridad | 2 min | Security Dashboard, SAST findings |
| Demo monitoreo | 2 min | Grafana dashboard con datos reales |
| Preguntas y cierre | 2 min | Lecciones aprendidas |
| **Total** | **15 min** | |

Si algo falla durante la demo, ir al plan B (screenshots previamente preparados) sin entrar en pánico.

---

## Dependencias entre sesiones

```
Sesión 1 (Infraestructura)
    ↓
    └── GitLab accesible + Runner registrado
         ↓
         Sesión 2 (Pipeline)
             ↓
             └── Pipeline build+test funcionando
                  ↓
                  ├── Sesión 3 (Seguridad: SAST requiere pipeline)
                  └── Sesión 3 (Monitoreo: Prometheus scraping GitLab)
                           ↓
                           Sesión 4 (Docs + Defensa)
```

No puedes avanzar a la sesión 2 sin la infraestructura de la sesión 1. Si la sesión 1 toma más de 4h, recortar features opcionales (MinIO, Grafana avanzado) para no comprometer el pipeline.

---

## Riesgos y mitigaciones

| Riesgo | Probabilidad | Mitigación |
|--------|:-----------:|-----------|
| GitLab tarda en iniciar | Alta | Esperar 5-10 min, verificar con `docker compose logs gitlab` |
| Runner no registra | Media | Verificar URL interna, usar `http://gitlab` (nombre del contenedor) |
| Pipeline falla en SAST | Baja | Verificar que la imagen del SAST es compatible con el lenguaje |
| Demo falla en vivo | Media | Screenshots + grabación de respaldo lista de antemano |
| `.env` commiteado con secretos | Alta | Verificar `.gitignore` antes de cada push con `git status` |
