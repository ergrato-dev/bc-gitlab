# Qué es GitLab CE

> Una sola aplicación que hace lo que normalmente hacen cinco, instalada en una máquina que controlas tú.

## 🎯 Objetivos

- Explicar qué problema resuelve una plataforma DevOps unificada
- Distinguir GitLab.com de GitLab autohospedado, y CE de EE
- Saber qué te dan Premium y Ultimate, y qué haremos en su lugar
- Justificar por qué este bootcamp se autohospeda

---

## 1. Qué problema resuelve

Un equipo de diez personas que escribe software necesita, como mínimo:

- Un sitio donde vivan los repositorios
- Un sitio donde se discutan los cambios antes de entrar
- Un sitio donde se anote qué hay que hacer
- Algo que compile y pruebe cada cambio
- Un sitio donde guardar los binarios que salen de ahí
- Algo que despliegue
- Algo que avise cuando se rompe

Durante quince años eso se resolvió comprando cinco o seis productos y pegándolos con cinta adhesiva: GitHub más Jira más Jenkins más Nexus más Ansible más Nagios. Cada uno con su modelo de usuarios, sus permisos, sus tokens, su lenguaje de configuración y su forma de entender qué es un "proyecto".

El coste de eso no está en las licencias. Está en las **costuras**:

| Costura | Qué duele |
|---|---|
| Cinco sistemas de identidad | Alguien se va del equipo y hay que darle de baja en cinco sitios. Se olvida uno |
| Cinco modelos de permisos | "Puede leer el repo pero no ver el pipeline que lo construye" |
| Trazabilidad rota | El ticket vive en Jira, el commit en GitHub, el build en Jenkins. Nadie sabe qué versión desplegada arregla qué ticket |
| Integraciones frágiles | Un webhook que nadie mantiene y que lleva seis meses fallando en silencio |
| Cinco actualizaciones | Y cinco ventanas de mantenimiento que coordinar |

**GitLab existe para eliminar esas costuras.** Es una sola aplicación donde el issue, la rama, el merge request, el pipeline, la imagen resultante, el despliegue y la métrica son objetos del mismo sistema, con los mismos usuarios y los mismos permisos.

Cuando en GitLab escribes `Closes #42` en un commit, no hay integración de por medio: el issue 42 y ese commit viven en la misma base de datos.

> [!NOTE]
> Esto no significa que GitLab sea mejor que la suma de sus partes. Jenkins es más flexible que GitLab CI, y Jira modela procesos que GitLab ni intenta. Lo que ofrece GitLab es **coherencia**, y para la mayoría de los equipos eso vale más que la profundidad de cada pieza.

---

## 2. Dos ejes que se confunden todo el tiempo

Hay dos decisiones independientes y casi todo el mundo las mezcla.

### Eje 1 — Dónde corre

| Modalidad | Qué es | Quién opera |
|---|---|---|
| **GitLab.com** | El SaaS de GitLab Inc. | GitLab Inc. |
| **Self-managed** (autohospedado) | Tú instalas GitLab en tu máquina o servidor | Tú |
| **Dedicated** | Instancia aislada gestionada por GitLab Inc. | GitLab Inc., pero solo para ti |

### Eje 2 — Qué edición

| Edición | Qué es |
|---|---|
| **CE** (Community Edition) | Código abierto, licencia MIT. Solo funcionalidad libre |
| **EE** (Enterprise Edition) | El mismo código más las features propietarias. Sin licencia se comporta como Free |

Y sobre EE se aplican los **tiers**: Free, Premium y Ultimate.

La confusión habitual es creer que autohospedado significa gratis y SaaS significa de pago. No: puedes pagar Ultimate en tu propio servidor, y puedes usar GitLab.com gratis.

**Este bootcamp es CE autohospedado**: la esquina de arriba a la izquierda de las dos tablas. Código abierto, en tu máquina, sin licencia.

---

## 3. Qué incluye CE

Casi todo lo que un equipo necesita. La lista corta de lo que vas a usar en estas 26 semanas:

- Repositorios Git, con ramas y tags protegidos
- Issues, etiquetas, hitos y tableros
- Merge requests con revisión y sugerencias
- CI/CD completo: pipelines, runners, artefactos, caché, entornos
- **Componentes CI/CD y catálogo** — reutilización de pipelines entre proyectos
- Container Registry y Package Registry
- **Dependency Proxy** — caché de Docker Hub
- **GitLab Pages** — sitios estáticos
- **Feature flags** — servicio completo basado en Unleash
- Wiki, snippets, Service Desk
- **Terraform state backend** y registro de módulos
- **Auto DevOps** — pipeline preconfigurado
- **Server hooks** — el único mecanismo de CE que bloquea un push de verdad
- API REST v4 y GraphQL completas
- **Gitaly Cluster con Praefect** — alta disponibilidad de repositorios

Los que van en negrita son los que casi nadie usa **porque los da por premium**. No lo son. Es el error más caro de esta lista: equipos pagando por una herramienta externa que GitLab CE ya trae.

---

## 4. Qué no incluye, y qué haremos en su lugar

Aquí está la honestidad que este bootcamp se toma en serio. Estas features existen, son útiles, cuestan dinero, y **no las vas a tener**:

| Feature | Tier | Qué resuelve | Qué hacemos aquí |
|---|:--:|---|---|
| Approval rules | Premium | Exigir N aprobaciones antes de fusionar | CODEOWNERS + un job que detecta, y un server hook que bloquea (S07) |
| Push rules | Premium | Rechazar pushes que no cumplen un patrón | Server hook `pre-receive` (S07) |
| Scoped labels | Premium | Etiquetas mutuamente excluyentes `tipo::bug` | Convención `tipo/bug` + job que valida (S05) |
| Epics, iteraciones, roadmaps | Premium | Planificación por encima del hito | Hitos y etiquetas (S05, S08) |
| Merge trains | Premium | Probar cada MR contra el resultado de fusionar los anteriores | Rebase obligatorio antes de fusionar (S07) |
| Entornos protegidos | Premium | Restringir quién despliega a producción | Job manual sobre rama protegida (S14) |
| SAST, DAST, Dependency Scanning | Ultimate | Escaneo de seguridad integrado en el MR | Semgrep, Gitleaks, OSV-Scanner, Trivy (S19) |
| Security Dashboard | Ultimate | Panel agregado de vulnerabilidades | Artefactos SARIF e informes de pipeline (S19) |
| Compliance frameworks | Ultimate | Políticas obligatorias por grupo | OPA / Conftest como gate (S20) |
| Audit events de instancia | Premium | Registro de auditoría completo | Volcado de `/events`, con menos campos (S18) |
| Geo, DR multi-región | Premium | Réplica geográfica y recuperación | Backup frío de una región, con el RPO medido (S22) |
| DORA API, VSA de grupo | Premium | Métricas de flujo oficiales | Métricas calculadas por API, con su definición documentada (S08) |

> [!IMPORTANT]
> **Sustituir no es igualar.** Un job que detecta que falta la aprobación de un propietario no es lo mismo que una plataforma que impide fusionar sin ella: lo primero avisa, lo segundo bloquea. Cada vez que sustituyamos algo, el material dirá exactamente qué se pierde. Saber dónde está el límite de tu montaje es parte del trabajo.

---

## 5. Por qué autohospedar, si GitLab.com existe y es gratis

Para aprender a **operar** una plataforma, tienes que tener una que operar.

En GitLab.com no puedes:

- Ver los procesos que la sostienen ni sus logs
- Cambiar la configuración del servidor
- Provocar un fallo y arreglarlo
- Hacer un backup y restaurarlo
- Montar alta disponibilidad
- Actualizar la versión y ver qué se rompe

Todo eso es el trabajo de un Platform Engineer, y todo eso es lo que hace este bootcamp a partir de la Semana 18.

Hay además una razón de mercado: las empresas que autohospedan GitLab lo hacen porque tienen requisitos de soberanía del dato, de aislamiento de red o de cumplimiento. Son precisamente las que necesitan a alguien que sepa operarlo, y son las que peor lo tienen para encontrarlo.

### El precio de autohospedar

No es gratis, es distinto:

| Coste | En GitLab.com | Autohospedado |
|---|---|---|
| Dinero | Por usuario y mes | Servidor, disco, backup |
| Actualizaciones | Automáticas | Tuyas, y con ruta de versiones obligatoria |
| Caída a las 3 de la mañana | De GitLab Inc. | Tuya |
| Backup | De GitLab Inc. | Tuyo, y no existe hasta que lo restauras |

La Semana 22 trata precisamente de la última fila.

---

## 6. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Tratar GitLab como "GitHub pero de la empresa" | Se acaba usando el 10% y pagando el 100% del coste de operarlo | Si solo quieres repositorios, usa repositorios. GitLab compensa cuando usas la integración |
| Dar por premium lo que es Free | Se paga una herramienta externa para algo que ya tienes | Comprueba el tier en la documentación antes de buscar alternativa |
| Dar por Free lo que es Premium | Se diseña un proceso que no se puede implementar y se descubre tarde | Comprueba el tier **antes** de prometer un flujo de trabajo |
| Instalar EE "por si acaso" | Sin licencia se comporta como Free, pero arrastra código y superficie que no usas | En CE puro sabes exactamente qué tienes |
| Autohospedar sin plan de backup | El primer incidente serio es también el último | El backup no existe hasta que lo has restaurado una vez |

---

## 7. Trucos

**Comprobar el tier de una feature sin salir de la documentación.** Cada página de `docs.gitlab.com` lleva una insignia de tier justo debajo del título. Si dice `All tiers` es Free. Si dice `Premium, Ultimate`, no lo tienes.

**Ver qué edición corre tu instancia.** El endpoint de versión lo dice:

```bash
curl -s "$GITLAB_URL/api/v4/version" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" | jq
# {
#   "version": "19.1.1",
#   "revision": "abc123",
#   "enterprise": false
# }
```

`"enterprise": false` es CE. En una EE sin licencia sería `true`, aunque se comporte como Free.

**La comparativa oficial de planes** está en `about.gitlab.com/pricing/feature-comparison/`. Es larga y cambia; consúltala en vez de fiarte de la memoria.

---

## 📚 Recursos Adicionales

- [Comparativa de tiers](https://about.gitlab.com/pricing/feature-comparison/) — la fuente de verdad de qué es de pago. Cambia varias veces al año
- [Documentación de GitLab](https://docs.gitlab.com/) — con el selector de versión arriba a la derecha; úsalo, la de `latest` no es la tuya
- [Repositorio de GitLab CE](https://gitlab.com/gitlab-org/gitlab-foss) — el código que estás corriendo
- [Glosario global del bootcamp](../../../docs/glosario-global.md) — con el tier de cada término

---

## ✅ Checklist de Verificación

- [ ] Sabes explicar la diferencia entre autohospedado y CE sin mezclarlas
- [ ] Puedes nombrar tres features de pago y su sustituto libre en este bootcamp
- [ ] Puedes nombrar tres features Free que suelen darse por premium
- [ ] Sabes dónde mirar el tier de una feature en la documentación oficial
- [ ] Entiendes por qué este bootcamp se autohospeda en vez de usar GitLab.com

---

| Anterior | Siguiente |
|---|---|
| — | [02 — Los procesos por dentro →](02-arquitectura-los-procesos.md) |

[← Volver a la Semana 01](../README.md)
