# Proyecto Semana 03 — La organización y sus permisos

> La plataforma deja de ser un repositorio con dueño y pasa a ser una organización: namespaces donde nacerá lo que falta, identidades con roles distintos y una auditoría escrita.

---

## 🎯 Objetivo

Dejar en pie la **capa 3** de tu plataforma: el árbol de namespaces sobre el que se van a apoyar veintitrés semanas, tres identidades con el mínimo privilegio que les permite trabajar, un acceso externo con techo y con fecha, y el script que comprueba todo lo anterior en diez segundos.

---

## 📦 Qué añade esta capa

La Semana 02 dejó un repositorio con código y una historia firmada. Esta decide **quién puede tocarlo** y **dónde va a vivir lo que aún no existe**.

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| Subgrupo `infra` | S11 (proyecto `infra` y disparo entre proyectos), S24 (Terraform y estado remoto) |
| Subgrupo `ci` | S12 (componentes publicados en el catálogo), S17 (automatización por API) |
| `project_creation_level` y `subgroup_creation_level` restringidos | Todas: impiden que aparezcan proyectos fuera del inventario |
| Tres identidades con roles distintos | S06 (revisión de merge requests con otro usuario), S07 (CODEOWNERS y aprobaciones) |
| La elevación directa en `app` | S07 (quién puede saltarse una protección), S18 (revisión de privilegios) |
| Grupo invitado con techo | S13 (quién descarga del registry), S18 (auditoría de accesos externos) |
| `scripts/auditar-accesos.sh` | S17 (el mismo script como job de pipeline), S26 (auditoría del capstone) |
| `docs/organizacion.md` | S04 (documentación del repositorio), S26 (defensa) |

La decisión con más recorrido no es cuántos subgrupos creas: es **cuánto rol pones en la raíz**. Todo lo que se concede arriba baja a todo el árbol y no se puede recortar abajo. Es la única decisión de esta semana que, tomada mal, no se arregla con un ajuste: se arregla quitando accesos a personas que ya se acostumbraron a tenerlos.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 03` contra la API de tu instancia.

1. Existe el subgrupo infra dentro de tu grupo raiz
2. Existe el subgrupo ci dentro de tu grupo raiz
3. El subgrupo infra es privado, como su grupo padre
4. El proyecto app sigue colgando del grupo raiz, no de un subgrupo
5. Solo los Maintainers pueden crear proyectos en el grupo raiz
6. Solo los Owners pueden crear subgrupos en el grupo raiz
7. El grupo raiz tiene al menos cuatro miembros directos: tu y los tres usuarios de laboratorio
8. Al menos un miembro del grupo raiz tiene el rol Developer
9. Al menos un miembro del grupo raiz tiene el rol Guest
10. Al menos una membresia del grupo raiz tiene fecha de caducidad
11. Solo una persona es Owner del grupo raiz
12. Alguien tiene rol Maintainer directo en el proyecto app sin serlo del grupo
13. Los miembros del grupo raiz se ven heredados en el subgrupo ci
14. El proyecto app esta compartido con un grupo invitado
15. Ningun grupo invitado en app tiene mas que Reporter

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **Los roles se reparten por lo que la persona hace, no por lo que es.** Tres identidades con el mismo rol no enseñan nada y no modelan nada.
- **La elevación directa está justificada.** Si `revisor` pudiera hacer su trabajo con Developer en el grupo, la excepción sobra. La excepción se defiende o se retira.
- **Las descripciones dicen para qué existe cada namespace y desde cuándo.** "infra" no es una descripción; "Terraform, manifiestos y estado remoto, su proyecto nace en la Semana 11" sí.
- **`docs/organizacion.md` se puede leer sin haber hecho la semana.** Árbol, tabla de identidades con el porqué de cada rol, accesos externos y fecha de la última auditoría.
- **El script de auditoría no lleva credenciales dentro.** Lee `~/.bc-gitlab`. Un token en un archivo versionado es un incidente, aunque el laboratorio sea local.
- **Ningún token de prueba sigue vivo.** Los de la práctica 03 se revocan al terminarla.
- **El árbol es el más plano que resuelve el problema.** Cada nivel de más es un sitio donde alguien puede conceder permisos sin que se vea desde arriba.

---

## 💡 Adaptación a tu dominio

El árbol es el mismo en los cuatro casos; lo que cambia es qué representan las identidades.

| Dominio | `dev-<dominio>` | `revisor-<dominio>` | `auditor-<dominio>` |
|---|---|---|---|
| 📖 Biblioteca | Desarrolla el cálculo de multas | Revisa antes de que llegue al mostrador | Inspección municipal, tres meses |
| 🏋️ Gimnasio | Desarrolla las reservas de clase | Valida los cambios de cupo | Auditoría de protección de datos |
| 🎥 Cine | Desarrolla el mapa de asientos | Revisa las reglas de precio | Consultoría de accesibilidad |
| 💊 Farmacia | Desarrolla el control de lotes | Valida las reglas de dispensación | Inspección sanitaria, temporal |

El patrón se repite: **alguien que escribe, alguien que aprueba y alguien que solo mira y se va**. Los tres roles existen en cualquier organización real, y son exactamente los tres niveles que necesitas para que las semanas 06 y 07 tengan sentido.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu instancia**, más dos archivos en `app`.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 03
```

```
15 de 15 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| Los subgrupos se crearon sin `parent_id` | Aparecen dos grupos raíz y fallan los requisitos 1 y 2 | Borrarlos y repetir el `POST` con `parent_id` |
| `app` se movió a un subgrupo "para ordenar" | Falla el requisito 4 y el autograding deja de encontrar el proyecto | Transferirlo de vuelta al grupo raíz y revisar `PROYECTO` en `~/.bc-gitlab` |
| Las membresías se pusieron en el subgrupo | Falla el requisito 13: el subgrupo no hereda nada | Quitarlas del subgrupo y ponerlas en el grupo raíz |
| Un usuario de laboratorio quedó como Owner | Falla el requisito 11 | `PUT` a su membresía con el rol correcto |
| `revisor` se subió a Maintainer en el grupo | Pasa el 12 por el motivo equivocado, y rompe el menor privilegio | Guest en el grupo, Maintainer directo en `app` |
| El grupo invitado se creó dentro de tu plataforma | Compartir se rechaza: sus miembros ya heredan acceso | Crearlo en la raíz de la instancia |
| La compartición se hizo con techo Maintainer | Falla el requisito 15 | Retirarla y volver a compartir con `group_access=20` |
| Falta la fecha de caducidad | Falla el requisito 10 | `PUT` a la membresía de `auditor` con `expires_at` |
| El token de prueba sigue vivo | No lo detecta ninguna comprobación; lo detecta la rúbrica | `GET /personal_access_tokens?user_id=<id>` y revocar |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 02](../../week-02-git_avanzado_y_firma_de_commits/3-proyecto/README.md) | **Proyecto Semana 03** | Proyecto Semana 04 |

[← Volver a la Semana 03](../README.md)
