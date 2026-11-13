# 🧵 Proyecto Hilo Conductor

Las 26 semanas construyen **una sola plataforma tuya**. No hay 26 ejercicios desechables: hay una instancia GitLab CE que empieza vacía en la Semana 01 y termina siendo una plataforma DevOps completa que puedes enseñar en una entrevista y defender.

Son **dos ejes trenzados**:

- **El producto** — una app pequeña de tu dominio, con código real que CI, el registry, los escáneres y los despliegues puedan morder.
- **La plataforma** — la instancia que la construye, la revisa, la firma, la despliega, la vigila y la recupera.

Cada semana añade una capa a uno de los dos. Ninguna semana empieza de cero.

---

## 1. Elige tu dominio

Tu plataforma necesita un dominio real. No importa cuál — importa que sea concreto y que te dure 26 semanas sin aburrirte.

| Dominio | Recurso principal | Ejemplo de issue real |
|---|---|---|
| 📖 Biblioteca | Libros, préstamos | "Un préstamo vencido no notifica" |
| 🏋️ Gimnasio | Miembros, rutinas | "Permite reservar una clase con el cupo lleno" |
| 🎥 Cine | Funciones, asientos | "Doble reserva del mismo asiento" |
| 🛠️ Taller | Órdenes de trabajo | "Falta el historial de piezas cambiadas" |
| 💊 Farmacia | Inventario, lotes | "Alertar de medicamentos por vencer" |
| 🏞️ Hotel | Habitaciones, reservas | "Overbooking en temporada alta" |

O el tuyo propio. La única regla: **que puedas inventar issues creíbles**, porque vas a escribir docenas.

> [!TIP]
> Elige algo que conozcas de la vida real. Los issues salen solos y la plataforma se lee como un proyecto de verdad, no como un ejercicio.

---

## 2. La estructura: un grupo, tres proyectos

```
plataforma-<tu-dominio>/          ← grupo raíz
├── app/                          ← el producto. Nace en la S01
├── infra/                        ← Terraform y manifiestos. Nace en la S11
└── ci/
    ├── componentes/              ← componentes CI/CD publicados. Nace en la S12
    └── automatizacion/           ← scripts de API, webhooks, ChatOps. Nace en la S17
```

`app/` es el que más se toca y el que apuntas en `~/.bc-gitlab`. Los otros tres aparecen cuando la semana que los necesita llega; no los crees antes.

---

## 3. El software

`app/` necesita **algo de código** para que CI, los escáneres, el registry y los despliegues tengan qué morder. Esto no es un bootcamp de programación: el código puede ser mínimo.

Mínimo suficiente: una librería o CLI en **TypeScript** con

- 3-5 funciones con lógica de tu dominio
- tests con el runner nativo de Node (`node:test`) o Vitest
- un `package.json` publicable
- un `Dockerfile` que produzca una imagen que arranque

Ejemplo (dominio biblioteca): `calcularMulta(diasRetraso)`, `estaDisponible(libro)`, `puedePrestar(socio)`. Suficiente para que haya tests que fallen, merge requests que revisar, imágenes que firmar y versiones que publicar.

> [!NOTE]
> ¿Ya tienes un proyecto propio? Úsalo, siempre que puedas reescribir su historia sin drama. Es la mejor opción: aplicas las 26 semanas sobre algo que te importa.

---

## 4. Qué capa añade cada semana

| Semana | Capa que se añade | Estado tras la semana |
|:--:|---|---|
| 01 | Instancia + grupo + proyecto `app` con el dominio elegido | Tienes un GitLab propio y un repositorio que declara tu dominio |
| 02 | La app mínima (3-5 funciones + tests), historia limpia, commits firmados | El repositorio tiene código real y verificable |
| 03 | Árbol de subgrupos `app`/`infra`/`ci`, 3 usuarios de laboratorio con roles | La organización existe y los permisos se prueban de verdad |
| 04 | README, LICENSE, CONTRIBUTING, wiki con ADR-001, snippet, insignias | Un tercero lo entiende y lo arranca sin preguntarte |
| 05 | Backlog de 12-15 issues, taxonomía de etiquetas, hito, tablero, plantillas | El trabajo está modelado, no improvisado |
| 06 | 3 merge requests fusionadas desde issues, plantilla de MR, estrategia de fusión | Nada entra a `main` sin revisión |
| 07 | `main` y tags `v*` protegidos, CODEOWNERS, server hook, script de auditoría `gobernanza` | Las reglas se cumplen aunque nadie mire |
| 08 | `release/*` protegidas, `v0.1.0` y el parche `v0.1.1` desde `release/0.1`, CHANGELOG generado, `docs/metricas.md` con DORA-lite | Hay versiones y el flujo se mide con números propios |
| 09 | Pipeline `build → test → package` en verde + runner Docker propio + job `gobernanza` | Cada commit se construye y se prueba solo |
| 10 | `rules`, variables por `environment_scope`, secure files | Cero secretos en el YAML, cero pipelines duplicados en MR |
| 11 | DAG con `needs`, pipelines hijos, disparo a `infra`, pipeline programado | El pipeline escala y deja de ser un tren en serie |
| 12 | `ci/componentes` con 2 componentes publicados en el catálogo | El YAML deja de duplicarse entre proyectos |
| 13 | Imagen en el registry + política de limpieza + paquete genérico + dependency proxy | Los binarios viven versionados dentro de tu instancia |
| 14 | `staging` y `production`, review app por MR, docs en Pages, 1 feature flag | Cada MR tiene entorno vivo y el despliegue es reversible |
| 15 | Flota de 3 runners etiquetados (`docker`, `dind`, protegido) + caché en SeaweedFS | La ejecución está enrutada y la caché es compartida |
| 16 | Runner con ejecutor Kubernetes en k3d + `docs/finops.md` | La ejecución autoescala y sabes lo que cuesta cada pipeline |
| 17 | `ci/automatizacion`: auditor por API, receptor de webhooks, job por ChatOps | La plataforma se opera por API, no a clics |
| 18 | Instancia endurecida + login OIDC con Keycloak + informe de actualización | La instancia está administrada como producción |
| 19 | Stage `seguridad` con Semgrep, Gitleaks, OSV-Scanner y Trivy | Nada se fusiona sin pasar cuatro escáneres |
| 20 | SBOM, firma con Cosign, gate de Conftest | Solo se despliega lo firmado y con inventario |
| 21 | Prometheus + Grafana + Loki + `docs/slo.md` con 3 SLO | La instancia tiene métricas, logs y umbrales declarados |
| 22 | Backup automatizado, restauración probada, postmortem escrito | El desastre está ensayado y el MTTR medido |
| 23 | Praefect + 3 Gitaly + PostgreSQL replicado + PgBouncer | La instancia sobrevive a la muerte de un nodo |
| 24 | `infra/terraform` con estado en GitLab, un módulo propio, gate de Conftest | La plataforma se reconstruye desde código |
| 25 | Agente de Kubernetes en k3d, GitOps, canario, rollback automático | El clúster se sincroniza solo y despliega por fases |
| 26 | Auditoría agregada, `v1.0.0` firmada, sitio de documentación, defensa | Plataforma completa, auditada y defendible |

---

## 5. Reglas del proyecto

1. **Una sola instancia.** No recrees el contenedor de GitLab entre semanas: el histórico de issues, merge requests, pipelines y releases **es** el entregable. Las únicas destrucciones permitidas son las de la Semana 22 (con backup) y la Semana 23 (con un nodo, no con todo).
2. **Un solo grupo.** Los subproyectos cuelgan de él. No hay repositorios sueltos.
3. **La historia se conserva.** La única reescritura permitida es la de la Semana 02, cuando aún no hay nada que perder.
4. **Nunca secretos reales.** Ni de prueba. El laboratorio es local, pero los hábitos viajan.
5. **Haz backup antes de las semanas destructivas.** La S22 te enseña a hacerlo; hazlo también antes de la S23.

---

## 6. Crearlo (Semana 01)

Con la instancia levantada y `glab` autenticado contra ella:

```bash
glab auth login --hostname localhost:8888
```

Creas el grupo y el proyecto, y guardas la ruta para las verificaciones:

```bash
cat > ~/.bc-gitlab <<'EOF'
GITLAB_URL=http://localhost:8888
PROYECTO=plataforma-<tu-dominio>/app
GITLAB_TOKEN=<tu-token>
EOF
chmod 600 ~/.bc-gitlab

./scripts/verificar-semana.sh 01
```

Los comandos exactos están en las prácticas de la Semana 01. Aquí solo se declara a dónde vas.

---

## 7. Cómo se ve al final

Al terminar la Semana 26 tu plataforma tiene:

- Una instancia GitLab CE en alta disponibilidad, con Gitaly replicado y PostgreSQL con réplica
- Un grupo con cuatro proyectos, roles reales y permisos probados
- Historia de commits firmados y convencionales, legible de principio a fin
- Issues y merge requests enlazados, con etiquetas y hitos que significan algo
- Pipelines en DAG, con componentes propios publicados en el catálogo y consumidos por otros proyectos
- Imágenes firmadas con Cosign, con SBOM, en tu propio registry y con política de limpieza
- Un entorno vivo por cada merge request y despliegues reversibles
- Una flota de runners etiquetada, autoescalada en Kubernetes, con su coste calculado
- Cuatro escáneres de seguridad bloqueando la fusión y un gate de política como código
- Métricas, logs y tres SLO con error budget declarado
- Un backup automatizado, una restauración cronometrada y un postmortem escrito
- Toda la plataforma declarada en Terraform, con el estado dentro de GitLab
- Un clúster que se sincroniza solo desde Git y despliega por fases con reversión automática

Eso no es un ejercicio. Es una plataforma.

---

[← Volver a docs](README.md)
