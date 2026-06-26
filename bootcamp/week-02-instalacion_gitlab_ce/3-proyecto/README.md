# 🚀 Proyecto Semana 02 — Instancia GitLab CE Funcional Documentada

⏱️ **Tiempo estimado:** 1 hora  
👤 **Modalidad:** Individual  
⭐ **Dificultad:** Básico-Intermedio

---

## 📋 Descripción

El proyecto de esta semana integra todo lo aprendido: tendrás una instancia de GitLab CE completamente funcional, configurada, respaldada y documentada. Esta instancia será la base sobre la que construirás durante todas las semanas siguientes del bootcamp.

Al finalizar este proyecto tendrás un entorno profesional listo para usar: GitLab CE corriendo en Docker Compose, con monitoreo opcional, backup configurado y documentación del proceso de instalación.

---

## ✅ Checklist de entregables

### Funcionalidad (40 puntos)

- [ ] `docker compose ps` muestra el contenedor `gitlab` con estado `(healthy)`
- [ ] Acceso web funcional en `http://localhost` — página de login visible
- [ ] Login exitoso como `root` con la contraseña cambiada
- [ ] Login exitoso como el usuario de trabajo (no root)
- [ ] `docker compose exec gitlab gitlab-ctl status` — todos los servicios en `run:`
- [ ] `docker compose exec gitlab gitlab-rake gitlab:check SANITIZE=true` — sin errores

### Backup (25 puntos)

- [ ] Al menos un backup ejecutado: `docker compose exec gitlab gitlab-backup list` muestra un archivo
- [ ] `gitlab-secrets.json` guardado en el host fuera del repositorio
- [ ] El backup fue restaurado exitosamente (flujo completo de restore verificado)

### Documentación (20 puntos)

- [ ] `INSTALL.md` creado en el proyecto `hello-gitlab` con el proceso documentado
- [ ] El `INSTALL.md` incluye: versión de GitLab, recursos del sistema, pasos realizados, problemas y soluciones
- [ ] El `INSTALL.md` tiene al menos 2 commits (borradores y versión final)

### Configuración (15 puntos)

- [ ] Contraseña de root cambiada (no la inicial)
- [ ] Nombre de la instancia personalizado en Appearance
- [ ] Registro público deshabilitado
- [ ] Usuario de trabajo creado (distinto de root)
- [ ] Proyecto `hello-gitlab` con al menos 2 commits

---

## 📊 Criterios de evaluación

| Criterio | Peso | Indicadores |
|----------|------|-------------|
| **Funcionalidad** | 40% | Healthcheck healthy, gitlab-ctl status todo en run, rake check sin errores |
| **Backup operativo** | 25% | Backup creado, secrets guardados, restore verificado con archivo pre-backup |
| **Documentación** | 20% | INSTALL.md completo, claro y con los campos requeridos |
| **Configuración** | 15% | Contraseña cambiada, usuario de trabajo, instancia personalizada |

---

## 🎯 ¿Por qué este proyecto importa?

Esta instancia de GitLab CE será tu **laboratorio personal** para el resto del bootcamp:

- **Semana 03:** Crearás grupos, proyectos y usuarios en esta instancia
- **Semana 04:** Configurarás CI/CD pipelines que corren en tu runner local
- **Semana 05+:** Explorarás GitLab Pages, Container Registry y Kubernetes integration

Si tu instancia no está bien configurada o los backups no funcionan, las semanas siguientes serán frustrantes. Invertir tiempo ahora en hacerlo bien paga dividendos durante todo el bootcamp.

---

## 📁 Estructura esperada del entregable

```
bc-gitlab/                        ← Repositorio clonado
├── .env                          ← Configuración local (no en git)
├── docker-compose.yml            ← Sin modificar
└── gitlab-secrets.json           ← FUERA del repo, en ~/gitlab-backups/

En GitLab (http://localhost):
└── [tu-usuario]/hello-gitlab/
    ├── README.md                 ← Descripción del proyecto
    ├── pre-backup-marker.txt     ← Verificación del restore
    └── INSTALL.md                ← Documentación de la instalación
```

---

## 🔗 Recursos para el proyecto

- [Instrucciones detalladas paso a paso](./instrucciones.md)
- [Rúbrica de evaluación completa](../rubrica-evaluacion.md)
- [Troubleshooting](../1-teoria/05-solucion-problemas.md)

---

## 📌 Nota sobre el entorno gl-epti

El bootcamp incluye un entorno avanzado llamado `gl-epti` (`docker-compose.gl-epti.yml`) que se usará en semanas posteriores para prácticas avanzadas de CI/CD, Pages y Kubernetes. Por ahora, trabaja exclusivamente con el `docker-compose.yml` de la raíz.
