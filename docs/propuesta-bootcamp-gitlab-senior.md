# Propuesta — Bootcamp GitLab CE Senior / Platform Engineering

## Estado
Propuesta. No implementado. Nada de lo descrito aquí existe todavía como contenido.

## Fecha
Julio 2026

---

## 1. Resumen ejecutivo

El bootcamp actual (`bootcamp/`, 12+1 semanas / 78h) lleva a un estudiante de cero a
**Administrador DevOps Junior** sobre GitLab CE. Es intencionalmente amplio y no profundiza
en escenarios de producción a escala (HA multi-nodo real, seguridad enterprise, SRE). Esta
propuesta define un **segundo track, para audiencia distinta**, que retoma donde el junior
termina y va a profundidad de **Platform Engineer / SRE senior** sobre GitLab CE (y, donde
sea necesario para enseñar features enterprise, GitLab EE en modo trial).

## 2. Público objetivo y prerrequisitos

- Ya completó el bootcamp junior de este repo, o tiene equivalente: administra GitLab CE
  básico, escribe pipelines `.gitlab-ci.yml`, conoce Docker/Docker Compose sin apoyo.
- Objetivo profesional: roles Platform Engineer, SRE, DevOps Senior — no "primer empleo
  DevOps" sino "llevar una plataforma GitLab a producción real con SLA".
- Prerrequisito duro: Linux intermedio (systemd, networking básico), Docker Compose sin
  guía, Git sin guía.

## 3. Qué NO se repite del bootcamp junior

Los fundamentos que el junior enseña desde cero (Git, instalación Docker Compose,
proyectos/grupos, issues/MR) se comprimen a **1 semana de nivelación** en vez de 3 — no se
re-enseñan, se asumen y se verifican con una evaluación diagnóstica al inicio.

## 4. Estructura temática propuesta

No se fijan aún líneas/horas exactas por semana — esto es alcance temático, el diseño
detallado (como el que ya existe para el junior en `docs/decision-renombre-semanas.md`)
se hace si se aprueba avanzar.

| Etapa | Tema | Por qué no está en el junior |
|-------|------|-------------------------------|
| Nivelación | Git avanzado (rerere, bisect, filter-repo) + arquitectura interna GitLab CE a fondo | El junior enseña uso, no arquitectura interna |
| HA/DR real | Patroni + etcd multi-nodo real, Gitaly Cluster + Praefect multi-nodo real, **Geo** (requiere licencia EE trial) | Junior semana 11 lo deja en diseño conceptual — "excede Docker Compose single-host" es literal en su README |
| Seguridad avanzada | SAML SSO, Vault/secret rotation a escala, compliance frameworks a profundidad (SOC2/ISO auditoría real), image signing con Cosign | Junior semana 10 cubre RBAC/MFA/scanning CE; SAML y Vault quedan fuera |
| Observabilidad SRE | Logging centralizado (ELK/Loki), SLO/error budgets, incident response y postmortems | No cubierto en el junior (era el gap P0 detectado en semana 11-12) |
| IaC/GitOps a profundidad | Terraform provider + GitLab Kubernetes Agent con policy-as-code y multi-entorno (superset de la semana 13 del junior) | Junior semana 13 cubre lo básico; aquí se llega a multi-entorno y políticas |
| Fleet/costo de runners | Autoscaling a escala, gestión de costo de infraestructura de runners, multi-región | Junior semana 07 cubre lo básico de autoscaling; no gestión de costo/fleet a escala |
| Capstone | Arquitectura multi-nodo productiva real (no docker-compose single-host) | El capstone del junior (semana 12) es explícitamente single-host |

## 5. Stack adicional vs junior

| Herramienta | Uso | Nota |
|---|---|---|
| GitLab **EE trial license** | Geo, DAST, aprobaciones avanzadas, group SSO sync | Solo features imposibles de enseñar en CE; se marca explícitamente cada vez que se usa |
| HashiCorp Vault | Secret rotation a escala | Nuevo respecto al junior |
| ELK o Loki | Logging centralizado | Nuevo respecto al junior |
| Terraform | Ya aparece en semana 13 del junior; aquí se profundiza (multi-entorno, policy-as-code) | — |
| Cosign / sigstore | Image signing | Nuevo respecto al junior |

## 6. Relación con el bootcamp junior

Se posiciona como **ruta 2 / continuación**, no como reemplazo ni versión "mejorada" del
junior — ambos públicos son distintos y el junior sigue siendo el punto de entrada. Requiere
haber completado el junior (o acreditar equivalente) como prerrequisito de acceso.

## 7. Siguientes pasos (decisiones pendientes antes de producir contenido)

- ¿Repo separado (`bc-gitlab-senior`) o carpeta `bootcamp-senior/` dentro de este mismo repo?
- ¿Es viable conseguir licencia GitLab EE trial reutilizable para grabar contenido de canal
  sin que expire a mitad de producción (trials suelen ser 30 días)?
- ¿Cuántas semanas/horas reales, con el mismo formato de evidencias (30/40/30%) que usa el
  junior, o un formato distinto para audiencia senior?
- Validar si hay demanda real para este track antes de invertir tiempo de producción
  (encuesta a egresados del bootcamp junior).
