# Propuesta — Bootcamp GitLab CE Senior / Platform Engineering

## Estado
Propuesta completa de temario y estructura. **No implementado** — ningún archivo de
contenido (`1-teoria/`, `2-practicas/`, etc.) existe todavía. Este documento es el
equivalente, para el track senior, de lo que `README.md` (raíz) +
`docs/decision-renombre-semanas.md` son para el bootcamp junior.

## Fecha
Julio 2026

---

## 1. Resumen ejecutivo

El bootcamp actual (`bootcamp/`, 13 semanas / 78h a 6h-semana) lleva a un estudiante de cero
a **Administrador DevOps Junior** sobre GitLab CE. Es intencionalmente amplio y dosifica los
temas de infraestructura a escala como diseño conceptual, no implementación real — su propio
README de la semana 11 lo dice explícitamente ("excede Docker Compose single-host").

Esta propuesta define un **segundo track, para audiencia distinta**, que retoma donde el
junior termina y va a profundidad de **Platform Engineer / SRE senior** sobre GitLab CE
(y, donde sea necesario para enseñar features enterprise, GitLab EE en modo trial). A
diferencia del junior, aquí todo lo "conceptual" se implementa de verdad: HA multi-nodo real,
SSO federado real, GitOps multi-cluster real.

## 2. Público objetivo y prerrequisitos

- Ya completó el bootcamp junior de este repo, o tiene equivalente demostrable: administra
  GitLab CE básico, escribe pipelines `.gitlab-ci.yml`, conoce Docker/Docker Compose sin
  apoyo, y completó la semana 13 (Terraform/GitOps básico) o equivalente.
- Objetivo profesional: roles Platform Engineer, SRE, DevOps Senior — no "primer empleo
  DevOps" sino "llevar una plataforma GitLab a producción real con SLA".
- Prerrequisito duro: Linux intermedio (systemd, networking, iptables básico), Docker Compose
  sin guía, Git sin guía, nociones de Kubernetes (se usa Minikube ya en el junior).
- Evaluación diagnóstica de entrada (no cubierta en este documento — a diseñar si se aprueba
  avanzar) para verificar que el prerrequisito se cumple antes de empezar la semana 1.

## 3. Qué NO se repite del bootcamp junior

Los fundamentos que el junior enseña desde cero (Git básico, instalación Docker Compose,
proyectos/grupos, issues/MR, CI/CD básico) **no se re-enseñan**. La única semana de
nivelación (semana 1) asume Git funcional y usa el tiempo en profundizar comandos avanzados
y arquitectura interna — no en repasar `git add`/`git commit`.

---

## 4. Cálculo de duración a 8h/semana

**Metodología:** se partió de las 7 etapas temáticas ya identificadas (ver versión previa de
esta propuesta) y se estimó cuántas semanas de 8h necesita cada una para pasar de "diseño
conceptual" (que es lo que el junior ya cubre) a "implementación real, medida y documentada"
— el criterio diferencial de este track. Etapas con infraestructura multi-nodo real (HA/DR)
requieren más semanas porque desplegar y validar un cluster real (no un contenedor único) no
es comprimible a una sesión de 8h sin sacrificar profundidad.

| Etapa | Semanas | Horas | Justificación de la duración |
|---|---|---|---|
| Nivelación | 1 | 8h | Una sola sesión de diagnóstico + arquitectura interna, no requiere más |
| HA/DR real | 3 | 24h | 3 subsistemas distintos con topología multi-nodo real (PostgreSQL, Gitaly, Geo) — cada uno necesita su propio ciclo completo desplegar→fallar→medir |
| Seguridad avanzada | 2 | 16h | SSO+Vault y supply-chain+compliance son suficientemente distintos para no comprimirse en 1 semana sin perder profundidad |
| Observabilidad SRE | 2 | 16h | Logging/tracing a escala es una semana; SLO/incident response es una disciplina aparte (no es "más monitoreo", es proceso operativo) |
| IaC/GitOps a profundidad | 2 | 16h | Terraform multi-entorno+policy y GitOps multi-cluster son ampliaciones independientes de la semana 13 del junior |
| Fleet/costo de runners | 1 | 8h | Tema acotado, no requiere más de una semana a este nivel |
| Capstone | 2 | 16h | Construcción (semana 12) y DR drill+defensa (semana 13) son fases distintas — el junior ya usa 1 semana solo para *un* proyecto single-host; aquí hay que sumar el drill |
| **Total** | **13 semanas** | **104h** | — |

**Resultado: 13 semanas a 8h/semana → 104 horas totales** (vs. 13 semanas / 78h del junior a
6h/semana — mismo número de semanas, pero 33% más horas por la profundidad hands-on de cada
tema).

### Distribución de tiempo por semana (propuesta, más cargada en práctica que el junior)

| Componente | Horas | % |
|---|---|---|
| Teoría | 2.5h | ~31% |
| Prácticas guiadas | 4h | ~50% |
| Proyecto semanal | 1.5h | ~19% |
| **Total** | **8h** | 100% |

---

## 5. Estructura completa de 13 semanas

Mismo esquema de carpetas que el bootcamp junior (`week-XX-tema_principal/` con
`README.md`, `rubrica-evaluacion.md`, `0-assets/`, `1-teoria/` 5 archivos, `2-practicas/` 4
subcarpetas, `3-proyecto/`, `4-recursos/`, `5-glosario/`), prefijado para no chocar con las
13 semanas del junior si ambos tracks conviven en el mismo repo (ver sección 8).

| # | Carpeta propuesta | Tema | Horas |
|---|---|---|---|
| 01 | `week-s01-git_avanzado_y_arquitectura_interna` | Git Avanzado y Arquitectura Interna de GitLab CE | 8h |
| 02 | `week-s02-postgresql_ha_multinodo` | PostgreSQL HA Multi-Nodo Real | 8h |
| 03 | `week-s03-gitaly_cluster_multinodo` | Gitaly Cluster Multi-Nodo Real | 8h |
| 04 | `week-s04-geo_y_dr_multiregion` | GitLab Geo y Disaster Recovery Multi-Región | 8h |
| 05 | `week-s05-sso_federado_y_secretos` | SSO Federado y Gestión de Secretos a Escala | 8h |
| 06 | `week-s06-supply_chain_y_compliance` | Supply Chain Security y Compliance Profundo | 8h |
| 07 | `week-s07-logging_y_observabilidad` | Logging Centralizado y Observabilidad Avanzada | 8h |
| 08 | `week-s08-slo_y_incident_response` | SLO, Error Budgets e Incident Response | 8h |
| 09 | `week-s09-terraform_multientorno_policy` | Terraform Multi-Entorno y Policy as Code | 8h |
| 10 | `week-s10-gitops_multicluster` | GitOps a Escala con GitLab Kubernetes Agent | 8h |
| 11 | `week-s11-fleet_y_finops_runners` | Fleet Management y FinOps de Runners | 8h |
| 12 | `week-s12-capstone_construccion` | Capstone — Diseño e Implementación de Plataforma Multi-Nodo | 8h |
| 13 | `week-s13-capstone_dr_drill_defensa` | Capstone — DR Drill, Validación y Defensa | 8h |

---

## 6. Contenido propuesto por semana

Cada semana sigue la misma estructura que el junior: 5 archivos de teoría, 4 prácticas, 1
proyecto semanal, glosario y recursos. Lo listado abajo es el temario — no el contenido
redactado (eso se produce solo si se aprueba avanzar, ver sección 9).

### Semana 01 — Git Avanzado y Arquitectura Interna de GitLab CE
**Objetivo:** verificar dominio de Git más allá del uso diario y entender GitLab CE a nivel
de "puedo diagnosticar por qué falla", no solo "sé usarlo".

- **Teoría:** (1) Git avanzado — `rerere`, `bisect`, `filter-repo`/BFG, worktrees,
  submodules vs subtrees · (2) Arquitectura interna — flujo de una petición HTTP end-to-end
  (Nginx → Workhorse → Puma → PostgreSQL/Redis/Gitaly) · (3) Gitaly a fondo — protocolo RPC,
  cómo cada comando `git` real pasa por Gitaly · (4) Sidekiq a fondo — colas, prioridades,
  troubleshooting de jobs atascados, `sidekiq-cluster` · (5) Diagnóstico de instancia —
  `gitlab-rails console`, `gitlab-ctl tail`, logs JSON estructurados, `gitlab-rake gitlab:check`
- **Prácticas:** reparar historia corrupta con reflog/filter-repo · `git bisect` sobre un bug
  inyectado · diagnosticar Sidekiq atascado en instancia de laboratorio · encontrar causa raíz
  de un incidente simulado leyendo logs JSON con `jq`
- **Proyecto:** informe de diagnóstico de una instancia GitLab CE con 3 fallos inyectados
  (datos, proceso, configuración), documentando causa raíz de cada uno
- **Requisitos previos:** bootcamp junior completo (semanas 01-13)

### Semana 02 — PostgreSQL HA Multi-Nodo Real
**Objetivo:** implementar HA real (3 nodos, failover automático medido), no el diseño
conceptual que cubre el junior en su semana 11.

- **Teoría:** replicación streaming a fondo (WAL, slots, síncrona vs asíncrona) · Patroni —
  arquitectura, etcd, bootstrap, REST API · PgBouncer — `pool_mode`, reconexión transparente
  durante failover · topologías de quorum, failover automático vs switchover planificado ·
  troubleshooting — split-brain, lag, fencing
- **Prácticas:** desplegar cluster Patroni de 3 nodos con etcd · configurar PgBouncer delante
  del cluster · matar el nodo líder y medir RTO real · simular y resolver split-brain
- **Proyecto:** cluster PostgreSQL HA de 3 nodos sirviendo una instancia GitLab CE real, con
  runbook de failover y RTO/RPO medidos empíricamente
- **Requisitos previos:** Semana 01; PostgreSQL HA conceptual (junior, semana 11)

### Semana 03 — Gitaly Cluster Multi-Nodo Real
**Objetivo:** el Gitaly Cluster que el junior deja "fuera de alcance" (su propio README lo
dice), aquí se despliega y se valida con carga real.

- **Teoría:** arquitectura Gitaly Cluster a fondo · Praefect — routing, votación,
  reconciliación · replication factor y asignación de repos a nodos · gestión de nodos —
  añadir/remover/reemplazar sin downtime · troubleshooting — repos divergentes, dataloss,
  verificación de consistencia
- **Prácticas:** desplegar Gitaly Cluster de 3 nodos + Praefect · migrar repos de Gitaly
  standalone a cluster · simular pérdida de un nodo y verificar reconciliación automática ·
  añadir un 4º nodo en caliente
- **Proyecto:** GitLab CE con Gitaly Cluster de 3 nodos, prueba de carga con clones/pushes
  concurrentes verificando distribución real entre nodos
- **Requisitos previos:** Semana 02; Gitaly Cluster conceptual (junior, semana 11)

### Semana 04 — GitLab Geo y Disaster Recovery Multi-Región
**Objetivo:** DR real entre "regiones" simuladas, usando licencia EE trial — la única semana
que depende de una licencia temporal (ver riesgo en sección 9).

- **Teoría:** qué es Geo y cuándo se justifica (multi-datacenter, latencia de lectura) ·
  arquitectura Geo — qué replica primary→secondary (PostgreSQL, Gitaly, object storage,
  Redis) · configuración de un site secundario · failover planificado vs de emergencia entre
  sites · verificación de salud Geo (`gitlab-rake geo:check`)
- **Prácticas:** activar licencia EE trial y habilitar Geo · configurar site secundario
  simulando otra región · ejecutar failover planificado (promote secondary) · medir RPO real
  de la replicación Geo
- **Proyecto:** plan de DR multi-región documentado + failover Geo ejecutado y medido,
  comparado explícitamente contra el DR single-site del junior (semana 11)
- **Requisitos previos:** Semana 03; licencia GitLab EE trial activa

### Semana 05 — SSO Federado y Gestión de Secretos a Escala
**Objetivo:** SAML real contra un IdP real (no solo la config de `gitlab.rb` que el junior
agregó como callout en su semana 10) y cero secretos estáticos en CI/CD.

- **Teoría:** SAML SSO con un IdP real (Keycloak de laboratorio) · Group SAML SSO (EE) vs
  SAML de instancia (CE) · HashiCorp Vault — arquitectura, unseal, políticas · secret
  rotation automatizada — Vault + dynamic secrets en CI/CD · integración Vault-GitLab CI
  (JWT auth, sin variables estáticas)
- **Prácticas:** desplegar Keycloak como IdP y federar login SAML a GitLab CE · configurar
  Vault con políticas · pipeline que obtiene secretos dinámicos de Vault vía JWT · rotar
  automáticamente una credencial de base de datos con Vault
- **Proyecto:** GitLab CE con login federado SAML + pipeline productivo con todos sus
  secretos servidos dinámicamente desde Vault (cero CI/CD variables estáticas)
- **Requisitos previos:** SAML/LDAP básico (junior, semana 10)

### Semana 06 — Supply Chain Security y Compliance Profundo
**Objetivo:** llevar Cosign/SBOM (que el junior deja como sección corta en su semana 10) a
enforcement real, y compliance de "conocer los conceptos" a "generar evidencia de auditoría".

- **Teoría:** modelo de amenazas de supply chain (SolarWinds, dependency confusion) ·
  Cosign/sigstore a fondo — keyless signing, Rekor transparency log, políticas de admisión
  que exigen firma · SBOM avanzado — generación, diffing entre versiones, attestation ·
  compliance frameworks reales — mapeo de controles SOC2/ISO27001 a evidencia técnica en
  GitLab · preparación de evidencia para un auditor externo
- **Prácticas:** firmar imágenes con Cosign keyless y verificar con política de admisión
  Kubernetes (Kyverno/Gatekeeper) · generar y diffear SBOM entre 2 versiones de una imagen ·
  compliance pipeline + approval rules mapeados a un control SOC2 específico · generar
  paquete de evidencia de auditoría desde audit events de GitLab
- **Proyecto:** pipeline donde ninguna imagen no firmada puede desplegarse, con SBOM y
  evidencia de compliance generados automáticamente
- **Requisitos previos:** Container Scanning/Cosign básico (junior, semana 10)

### Semana 07 — Logging Centralizado y Observabilidad Avanzada
**Objetivo:** el logging centralizado que el junior cubre a nivel single-stack (semana 11)
aquí escala a multi-tenant y se correlaciona con métricas y trazas.

- **Teoría:** logging centralizado a escala — índices, retención, costos, ELK vs Loki en
  producción real · los 3 pilares de observabilidad — correlación logs-métricas-trazas ·
  tracing distribuido — OpenTelemetry, instrumentación básica · alerting basado en logs vs
  en métricas · diseño de dashboards operacionales para on-call
- **Prácticas:** desplegar Loki+Promtail+Tempo+Grafana multi-tenant · instrumentar una app
  con OpenTelemetry y correlacionar traza→log→métrica en Grafana · crear alertas LogQL ·
  diseñar dashboard operacional real para on-call
- **Proyecto:** stack de observabilidad completo (logs+métricas+trazas correlacionados) para
  la plataforma HA construida en semanas 02-04
- **Requisitos previos:** logging centralizado básico (junior, semana 11)

### Semana 08 — SLO, Error Budgets e Incident Response
**Objetivo:** la disciplina operativa que el junior no cubre en absoluto — no es "más
monitoreo", es proceso.

- **Teoría:** SLI/SLO/error budget — definición, cómo elegirlos para una plataforma GitLab ·
  error budget y burn rate — relación con velocidad de despliegue · incident response —
  severidad, roles (incident commander), comunicación · runbooks operacionales — qué los
  hace útiles · postmortems blameless — estructura, timeline, action items
- **Prácticas:** definir SLO reales con alertas de burn rate · simular un incidente
  (fallo inyectado) y responder con roles asignados · escribir un runbook real para un
  escenario de semanas 02-04 · escribir un postmortem blameless del incidente simulado
- **Proyecto:** simulacro de incidente end-to-end (detección→respuesta→resolución→postmortem)
  sobre la plataforma HA construida en el bootcamp, con MTTR real medido
- **Requisitos previos:** Semana 07

### Semana 09 — Terraform Multi-Entorno y Policy as Code
**Objetivo:** superset real de la semana 13 del junior — de "un módulo" a "multi-entorno con
gates de política obligatorios".

- **Teoría:** Terraform workspaces y estructura multi-entorno (dev/staging/prod) · policy as
  code con OPA/Conftest real · Terraform Sentinel (concepto, alternativa enterprise) ·
  módulos versionados y registry privado · CI/CD de Terraform con aprobación manual por
  entorno y drift detection automatizada
- **Prácticas:** estructurar proyecto Terraform multi-entorno con workspaces · escribir
  políticas Conftest que bloqueen recursos inseguros · publicar un módulo versionado en
  registry privado · pipeline con aprobación manual obligatoria en prod + drift detection
  programado
- **Proyecto:** infraestructura GitLab completa gestionada por Terraform multi-entorno con
  policy gates, extendiendo el trabajo de la semana 13 del junior
- **Requisitos previos:** IaC/Terraform básico (junior, semana 13)

### Semana 10 — GitOps a Escala con GitLab Kubernetes Agent
**Objetivo:** superset real de la semana 13 del junior — de "un cluster" a "multi-cluster con
progressive delivery".

- **Teoría:** GitOps multi-cluster — un Agent por cluster vs fan-out · multi-tenancy en
  GitOps — aislamiento por namespace/RBAC del Agent · progressive delivery — canary con
  Flagger o Argo Rollouts sobre GitOps · rollback automático basado en métricas · GitLab
  Agent-native GitOps vs Argo CD/Flux (cuándo usar cada uno)
- **Prácticas:** registrar 2+ Agents en 2 clusters distintos desde un mismo proyecto ·
  configurar multi-tenancy con RBAC restringido por Agent · desplegar canary con Flagger +
  rollback automático por métrica · comparar el mismo despliegue con Argo CD
- **Proyecto:** despliegue multi-cluster con progressive delivery y rollback automático,
  demostrado con inyección de un despliegue defectuoso
- **Requisitos previos:** GitOps/Kubernetes Agent básico (junior, semana 13)

### Semana 11 — Fleet Management y FinOps de Runners
**Objetivo:** superset real de la semana 07 del junior (autoscaling básico) — costo y escala
multi-región, no solo "que autoescale".

- **Teoría:** fleet management a escala — cientos de runners, múltiples regiones · FinOps
  aplicado a CI/CD — costo por minuto de pipeline, chargeback por equipo/proyecto ·
  spot/preemptible fleets con manejo de interrupciones · multi-región — latencia de runners
  vs ubicación de artefactos/registry · capacity planning — proyección de demanda
- **Prácticas:** configurar fleet autoscaling multi-región con Fleeting · implementar spot
  fleet con manejo de interrupción sin fallar pipelines · construir dashboard de costo por
  proyecto/equipo (chargeback) · ejercicio de capacity planning con datos históricos
  simulados
- **Proyecto:** propuesta de arquitectura de fleet de runners optimizada en costo para una
  organización simulada de 50+ equipos, con dashboard de FinOps
- **Requisitos previos:** fleet/costo de runners (junior, semana 07, ya ampliada en el gap-fix
  de 2026-07-09)

### Semana 12 — Capstone: Diseño e Implementación de Plataforma Multi-Nodo
**Objetivo:** construir la plataforma que integra todo lo anterior — HA real, seguridad,
observabilidad, IaC/GitOps, fleet — no un docker-compose single-host como el capstone junior.

- **Teoría (más ligera, semana de ejecución):** metodología de diseño de arquitectura de
  referencia · checklist de producción real (consolidado de semanas 01-11) · trade-offs de
  arquitectura (costo vs resiliencia vs complejidad operativa) · documentación de arquitectura
  para stakeholders no técnicos · preparación de la defensa técnica
- **Prácticas:** construcción guiada por bloques integrados — infra HA (PostgreSQL+Gitaly),
  seguridad (SSO+Vault+signing), observabilidad, IaC/GitOps, fleet de runners — todo en la
  misma plataforma, no ejercicios aislados
- **Proyecto:** plataforma GitLab CE multi-nodo productiva completa
- **Requisitos previos:** semanas 01-11

### Semana 13 — Capstone: DR Drill, Validación y Defensa
**Objetivo:** cerrar con una validación real de todo lo construido y una defensa más exigente
que la del junior (15 min → 30-45 min con Q&A adversarial).

- **Teoría (ligera):** repaso de criterios de evaluación · cómo estructurar la defensa técnica
- **Prácticas:** DR drill real sobre la plataforma construida (RTO/RPO medidos) · prueba de
  carga/stress test · revisión de pares simulando review de arquitectura senior · ensayo de
  defensa
- **Proyecto/Entregable final:** defensa técnica de 30-45 min con Q&A adversarial, plan de DR
  ejecutado y medido, documentación completa de arquitectura
- **Requisitos previos:** Semana 12

---

## 7. Evaluación

Mismo modelo de tres evidencias que el junior (Conocimiento 30% / Desempeño 40% / Producto
30%, mínimo 70% en cada una) — se mantiene por consistencia entre tracks, salvo en la semana
13 donde la defensa técnica pesa más dentro de "Producto" por ser la validación final del
capstone completo (semanas 02-11), no solo de una semana aislada.

## 8. Stack adicional vs junior

| Herramienta | Uso | Nota |
|---|---|---|
| GitLab **EE trial license** | Geo, DAST, aprobaciones avanzadas, group SSO sync | Solo semana 04 depende de ella; se marca explícitamente cada vez que se usa |
| Keycloak | IdP de laboratorio para SAML SSO real | Nuevo respecto al junior |
| HashiCorp Vault | Secret rotation a escala | Nuevo respecto al junior |
| Cosign / sigstore | Image signing, keyless + Rekor | El junior lo introduce; aquí se lleva a enforcement real |
| Kyverno o Gatekeeper | Políticas de admisión Kubernetes | Nuevo respecto al junior |
| Loki/Tempo/OpenTelemetry | Observabilidad correlacionada (logs+métricas+trazas) | El junior cubre logging básico; aquí se agrega tracing |
| Terraform (OPA/Conftest, Sentinel) | Policy as code multi-entorno | El junior cubre Terraform básico (semana 13); aquí se profundiza |
| Flagger o Argo Rollouts | Progressive delivery / canary | Nuevo respecto al junior |
| Argo CD (comparación) | GitOps alternativo al Agent-native de GitLab | Solo para comparación, no como herramienta principal del track |

## 9. Relación con el bootcamp junior

Se posiciona como **ruta 2 / continuación**, no como reemplazo ni versión "mejorada" del
junior — ambos públicos son distintos y el junior sigue siendo el punto de entrada único.
Acceso condicionado a haber completado el junior (o acreditar equivalente).

## 10. Siguientes pasos y riesgos pendientes

- **Decisión de ubicación:** ¿repo separado (`bc-gitlab-senior`) o carpetas `week-s01`...
  `week-s13` dentro de este mismo repo (prefijo `s` ya reflejado en la sección 5 para evitar
  colisión con `week-01`...`week-13` del junior)?
- **Riesgo de la semana 04 (Geo):** depende de una licencia GitLab EE trial que normalmente
  expira en 30 días — si la producción de contenido (grabación, redacción) toma más que eso,
  la semana 04 se bloquea a mitad de camino. Mitigación a decidir: producir esa semana primero
  y de forma acelerada, o conseguir una licencia EE de evaluación extendida antes de empezar.
- **Validar demanda real** antes de invertir tiempo de producción (encuesta a egresados del
  bootcamp junior) — 104h de contenido nuevo es una inversión significativa.
- Una vez aprobado el temario de este documento, el siguiente artefacto a producir es el
  equivalente de `docs/decision-renombre-semanas.md` para este track (ADR formal de
  nombres de carpeta), y luego sí, contenido semana por semana siguiendo el mismo patrón
  usado para cerrar los gaps del junior el 2026-07-09 (agentes en paralelo, una semana por
  agente, sin cruces).
