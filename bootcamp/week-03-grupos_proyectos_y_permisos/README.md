# Semana 03 — Grupos, subgrupos, roles y namespaces

> Un permiso mal puesto no da error: da acceso. Esta semana modelas tu organización en
> namespaces y roles, y compruebas con tokens reales quién puede hacer qué, en vez de suponerlo.

---

## 🎯 Objetivos de la Semana

Al terminar serás capaz de:

- Explicar qué es un namespace y por qué la ruta de un proyecto **es** su identidad en la API
- Construir un árbol de grupos y subgrupos, y decir qué hereda cada nivel del de arriba
- Enumerar los ocho niveles de acceso de GitLab y qué desbloquea exactamente cada uno en la versión fijada
- Distinguir membresía **directa** de **heredada**, y predecir qué rol efectivo tiene alguien en un proyecto
- Poner fecha de caducidad a una membresía y saber qué pasa cuando llega
- Compartir un proyecto con otro grupo, y calcular el acceso resultante sin abrir la interfaz
- Decidir la visibilidad de cada nivel del árbol y saber qué ve un anónimo en cada caso
- Mover y renombrar grupos y proyectos sabiendo qué se redirige solo y qué se rompe
- Crear usuarios y tokens de laboratorio por la API de administración
- Auditar por API quién tiene acceso a qué, y retirar lo que sobra
- Diseñar el árbol de tu plataforma con el menor privilegio que aún permite trabajar

---

## 📋 Prerrequisitos

- **Semana 02 completada**: `app` con código, tests, historia lineal y firmada, y `~/.bc-gitlab` con `GITLAB_URL`, `PROYECTO` y `GITLAB_TOKEN`
- **Tu usuario es administrador de la instancia** — en el laboratorio eres `root`. Las prácticas 02, 03 y 04 crean usuarios y tokens, y eso es API de administración
- **`jq` instalado** — esta semana se leen respuestas de la API en casi todos los pasos
- **Perfil de laboratorio**: `base` — ver [perfiles-de-laboratorio](../../docs/perfiles-de-laboratorio.md)
- Haber leído [proyecto-hilo-conductor](../../docs/proyecto-hilo-conductor.md): el árbol que montas hoy es el que usan las veintitrés semanas siguientes

---

## 🗂️ Estructura de la Semana

```
week-03-grupos_proyectos_y_permisos/
├── README.md                  # Este archivo
├── rubrica-evaluacion.md      # Cómo se evalúa
├── checks.json                # Las 15 comprobaciones automáticas
├── 0-assets/                  # Diagramas
├── 1-teoria/                  # 8 archivos, un concepto cada uno
├── 2-practicas/               # 4 prácticas sobre tu instancia
├── 3-proyecto/                # La capa 3 de tu plataforma
├── 4-recursos/                # Libros, vídeos y enlaces
└── 5-glosario/                # Términos de esta semana
```

---

## 📝 Contenidos

### Teoría

| Archivo | Tema | Duración |
|---|---|:--:|
| [01 — Namespaces y rutas](1-teoria/01-namespaces-y-rutas.md) | Qué es un namespace, ruta contra nombre, y el `%2F` que aparece en toda la API | 15 min |
| [02 — Grupos y subgrupos](1-teoria/02-grupos-y-subgrupos.md) | Jerarquía, límite de anidamiento, ajustes del grupo y borrado programado | 15 min |
| [03 — Los roles y qué puede cada uno](1-teoria/03-los-roles-y-que-puede-cada-uno.md) | Los ocho niveles, las fronteras reales de cada rol y qué es de pago | 20 min |
| [04 — Herencia de membresía](1-teoria/04-herencia-de-membresia.md) | Directa contra heredada, el rol más alto gana, caducidad y solicitudes de acceso | 20 min |
| [05 — Compartir grupos y proyectos](1-teoria/05-compartir-grupos-y-proyectos.md) | Grupos invitados, el mínimo de los dos accesos, y cuándo compartir en vez de mover | 15 min |
| [06 — Visibilidad: quién ve qué](1-teoria/06-visibilidad-quien-ve-que.md) | Private, internal y public; la restricción del padre; qué ve un anónimo | 15 min |
| [07 — Mover y renombrar sin romper](1-teoria/07-mover-y-renombrar-sin-romper.md) | Transferencias, redirecciones, y la lista de lo que sí se rompe | 10 min |
| [08 — Diseñar el árbol con menor privilegio](1-teoria/08-disenar-el-arbol-con-menor-privilegio.md) | Patrones, antipatrones, identidades de bot y auditoría periódica | 10 min |

### Prácticas

| Práctica | Qué haces | Duración |
|---|---|:--:|
| [01 — El árbol de la organización](2-practicas/01-el-arbol-de-la-organizacion.md) | Subgrupos `infra` y `ci`, ajustes de creación, visibilidad y descripciones | 50 min |
| [02 — Tres usuarios y sus roles](2-practicas/02-tres-usuarios-y-sus-roles.md) | Tres usuarios de laboratorio, roles en el grupo, caducidad y una elevación directa | 50 min |
| [03 — Probar los permisos de verdad](2-practicas/03-probar-los-permisos-de-verdad.md) | Un token por usuario y once intentos reales contra la API, con su código HTTP | 50 min |
| [04 — Compartir, auditar y recortar](2-practicas/04-compartir-auditar-y-recortar.md) | Grupo invitado con caducidad, auditoría completa por API y retirada de lo que sobra | 50 min |

### Proyecto

La **capa 3** de tu plataforma: el árbol de namespaces donde van a nacer `infra` y `ci`, tres identidades con roles distintos y la primera auditoría de accesos. Detalles en [3-proyecto](3-proyecto/README.md).

---

## ⏱️ Distribución del Tiempo (8 horas)

| Bloque | Tiempo |
|---|:--:|
| Teoría (8 archivos) | 2 h 00 |
| Prácticas (4 × 50 min) | 3 h 20 |
| Proyecto | 2 h 00 |
| Revisión y verificación | 40 min |
| **Total** | **8 h 00** |

> [!TIP]
> Lee la teoría [04](1-teoria/04-herencia-de-membresia.md) antes de la práctica 02. Es la única dependencia estricta: si añades a alguien al grupo y también al proyecto sin entender qué rol acaba ganando, la práctica 03 te va a devolver códigos HTTP que no esperas y vas a culpar al token.

---

## 🧭 El árbol que montas hoy

```
plataforma-<tu-dominio>/          ← grupo raíz (Semana 01)
├── app                           ← proyecto (Semana 01). Se queda donde está
├── infra/                        ← subgrupo nuevo. Su proyecto nace en la Semana 11
└── ci/                           ← subgrupo nuevo. componentes en la S12, automatizacion en la S17
```

Los subgrupos nacen **vacíos** y eso es correcto: un namespace es una decisión de organización y de permisos, no una carpeta que necesite contenido. Crearlos hoy significa que en la Semana 11 el proyecto `infra` nace ya con los permisos bien puestos, en vez de heredarlos de una decisión tomada con prisa.

`app` **no se mueve**. Mover un proyecto cambia su ruta, y su ruta es lo que tienen configurado tu `~/.bc-gitlab`, tus remotos de Git y todas las comprobaciones del autograding. La teoría [07](1-teoria/07-mover-y-renombrar-sin-romper.md) explica qué se redirige solo y qué no; la conclusión práctica es que la ruta de `app` se decidió en la Semana 01 y se respeta.

---

## 🎩 Trucos y atajos

| Truco | Cómo |
|---|---|
| Ver el árbol entero de un grupo de una vez | `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/groups/$G/descendant_groups" \| jq -r '.[].full_path'` |
| Saber si una ruta está libre antes de crear | `curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/namespaces/infra/exists?parent_id=<id>" \| jq` |
| El rol **efectivo** de alguien aquí, herencia incluida | `.../projects/$P/members/all/<user_id>` — `members/<user_id>` a secas solo ve los directos |
| Qué toca una persona en toda la instancia | `.../users/<id>/memberships` — solo administradores |
| Dónde soy al menos Developer | `.../groups?min_access_level=30` — también vale para `/projects` |
| Ver qué añade **exactamente** cada rol en tu versión | `docker compose exec gitlab cat /opt/gitlab/embedded/service/gitlab-rails/config/authz/roles/developer.yml` |
| Comparar dos roles sin leerlos enteros | `docker compose exec gitlab bash -c 'cd /opt/gitlab/embedded/service/gitlab-rails/config/authz/roles && comm -13 reporter.yml developer.yml'` |
| Buscar un namespace por ruta completa, no por nombre | `.../namespaces?search=plataforma/app&full_path_search=true` |
| Listar solo los grupos raíz | `.../groups?top_level_only=true` |
| Los proyectos del grupo **sin** los que solo están compartidos | `.../groups/$G/projects?with_shared=false&include_subgroups=true` |
| Quién invitó a quién a este proyecto | `.../projects/$P \| jq '.shared_with_groups'` |
| Los grupos invitados de un grupo, directos y heredados | `.../groups/$G/invited_groups?relation=direct,inherited` |
| A dónde puedo mover este grupo | `.../groups/$G/transfer_locations` — la lista real, no la que te imaginas |
| Recuperar un grupo borrado por error | `curl --request POST .../groups/$G/restore` — el `DELETE` solo lo **programa** para borrado |
| Filtrar la lista de miembros por herencia, en la interfaz | `Group → Manage → Members`, filtro *Membership: Inherited* |
| Ver un miembro sin conocer su ID | `.../groups/$G/members?query=revisor` |
| Contar de golpe cuántos Owners tiene el árbol | `.../groups/$G/members/all \| jq '[.[] \| select(.access_level==50)] \| length'` |

---

## 📌 Entregables

1. Subgrupo `infra` dentro del grupo raíz, privado y con descripción
2. Subgrupo `ci` dentro del grupo raíz, privado y con descripción
3. El proyecto `app` sigue colgando del grupo raíz
4. El grupo raíz con `project_creation_level` en `maintainer`
5. El grupo raíz con `subgroup_creation_level` en `owner`
6. Tres usuarios de laboratorio creados, con rol distinto cada uno
7. Un miembro Developer y un miembro Guest en el grupo raíz
8. Al menos una membresía con fecha de caducidad
9. Un único Owner en todo el árbol
10. Una elevación directa a Maintainer en `app` sobre alguien que en el grupo es menos
11. El proyecto `app` compartido con un grupo invitado, con acceso máximo Reporter
12. `docs/organizacion.md` en `app`, con el árbol, la tabla de roles y la fecha de la auditoría

---

## ✅ Verificación

```bash
./scripts/verificar-semana.sh 03
```

Las 15 comprobaciones tienen que pasar. Si alguna falla, la pista te dice en qué práctica y en qué paso se arregla.

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Semana 02 — Git quirúrgico y commits firmados](../week-02-git_avanzado_y_firma_de_commits/README.md) | **Semana 03** | [Semana 04 — El repositorio como producto](../week-04-repositorio_como_producto/README.md) |

[← Volver al inicio del bootcamp](../README.md)
