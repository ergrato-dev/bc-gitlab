# Ramas protegidas

> Una rama protegida separa dos permisos que Git no distingue: escribir directamente en la rama y fusionar en ella a través de una merge request. Esa separación sostiene todo el flujo de revisión.

---

## 🎯 Objetivos

- Explicar los tres controles de una rama protegida: push, merge y force push
- Leer y escribir los niveles de acceso por número (`0`, `30`, `40`, `60`) y saber a quién deja pasar cada uno
- Proteger varias ramas con un comodín y saber qué regla gana cuando coinciden varias
- Configurar la protección por defecto de las ramas de los proyectos nuevos del grupo
- Cambiar una protección existente por API sabiendo lo que CE permite editar y lo que no

---

## 1. Qué problema resuelve

Git no tiene permisos por rama. Si puedes escribir en el repositorio, puedes escribir en cualquier rama, reescribirla con `--force` o borrarla. Para Git, `main` es una rama como otra.

GitLab añade la protección por encima: antes de aceptar un `push`, comprueba si la rama coincide con alguna regla y si tu rol la cumple. Si no, rechaza el cambio con un mensaje y Git no llega a escribir nada.

```
remote: GitLab: You are not allowed to push code to protected branches on this project.
 ! [remote rejected] main -> main (pre-receive hook declined)
```

Ese mensaje lo verás esta semana, dirigido a ti, que eres Owner.

---

## 2. Cómo funciona

### 2.1 Tres controles por rama

| Control | Qué permite | Campo de la API |
|---|---|---|
| *Allowed to push and merge* | `git push` directo, commits desde la Web IDE o desde la API de archivos | `push_access_level` |
| *Allowed to merge* | Fusionar una merge request cuyo destino es esta rama | `merge_access_level` |
| *Allowed to force push* | Reescribir la historia de la rama | `allow_force_push` |

La separación entre los dos primeros es lo que importa. Con `push = No one` y `merge = Maintainers`, **la única forma de que algo entre en `main` es una merge request** que un Maintainer fusiona. No hay otro camino.

Una rama protegida tampoco se puede borrar con `git push origin :main`. GitLab responde que solo se borra desde la interfaz web, y solo un Maintainer:

```
remote: GitLab: You can only delete protected branches using the web interface.
```

### 2.2 Los niveles de acceso

| Número | Nombre en la UI | Quién pasa |
|:--:|---|---|
| `0` | *No one* | Nadie. **Tampoco el administrador de la instancia** |
| `30` | *Developers + Maintainers* | Developer, Maintainer y Owner |
| `40` | *Maintainers* | Maintainer y Owner |
| `60` | *Instance admins* | Solo los administradores de la instancia. Existe en autohospedado, no en gitlab.com |

La comparación es con el **rol efectivo** del usuario en el proyecto: el mayor entre el heredado del grupo y el directo. Por eso Owner (50) pasa donde se pide Maintainer (40), y por eso `revisor-<dominio>`, que es Guest en el grupo y Maintainer en `app`, también pasa.

`0` es especial. En el código de GitLab, la comprobación de *No one* va antes que la de administrador: ni siquiera un admin puede empujar a una rama con `push = 0`. Lo que sí puede un admin, o un Maintainer, es **quitar la protección**, empujar y volver a ponerla. La [teoría 07](07-lo-que-no-se-puede-bloquear.md) vuelve sobre esto.

### 2.3 Comodines y reglas que se solapan

El nombre puede llevar `*`: `release/*` protege `release/1.0`, `release/2.0` y cualquier otra que empiece así. Útil para las ramas de mantenimiento que llegan en la Semana 08.

Cuando una rama coincide con varias reglas, **gana la más permisiva** para cada control. Si `main` tiene `push = No one` y además existe una regla `*` con `push = Developers`, un Developer puede empujar a `main`. Revisa siempre la lista completa, no solo la regla que acabas de crear.

### 2.4 Lo que CE no tiene

| Feature | Tier | En CE |
|---|---|---|
| *Allowed to push* a usuarios o grupos concretos | **Premium** | Solo roles, y claves de despliegue (`allowed_to_push` con `deploy_key_id`) |
| *Allowed to unprotect* | **Premium** | Cualquier Maintainer puede desproteger |
| *Require approval from code owners* | **Premium** | No existe: [teoría 04](04-codeowners-en-ce.md) |
| Ramas protegidas a nivel de grupo | **Premium** | Solo la protección por defecto de la rama por defecto (2.5) |

### 2.5 La protección que nace con cada proyecto

Cuando se crea un proyecto, su rama por defecto se protege sola según un ajuste de la instancia, que cada grupo puede sobrescribir: `default_branch_protection_defaults`. GitLab trae cuatro combinaciones predefinidas:

| Opción en la UI | push | merge | force push |
|---|:--:|:--:|:--:|
| *Not protected* | Developers | Developers | Sí |
| *Protected against pushes* | Developers | Maintainers | No |
| *Fully protected* | Maintainers | Maintainers | No |
| *Fully protected after initial push* | Developers en el primer push, luego Maintainers | Maintainers | No |

Ninguna pone `push = No one`, y con razón: alguien tiene que hacer el primer `push` a un proyecto vacío. El patrón es dejar la protección por defecto del grupo en *Fully protected* y endurecer `main` a mano en cada proyecto que ya tenga flujo de merge requests.

Solo afecta a proyectos **nuevos** y solo a su rama por defecto. Cambiarla hoy no toca `app`.

---

## 3. Cómo se configura

### 3.1 Con la UI

`Settings → Repository → Protected branches`. *Add protected branch*, elige la rama o escribe el comodín, y los dos desplegables. El interruptor *Allowed to force push* está en la fila de la regla, ya creada.

La protección por defecto del grupo: `Settings → Repository → Default branch` del grupo.

### 3.2 Con la API

Leer:

```bash
curl -s -H "$H" "$API/projects/$P/protected_branches/main" \
  | jq '{name, push: [.push_access_levels[].access_level], merge: [.merge_access_levels[].access_level], allow_force_push}'
```

Crear (devuelve `409` si la regla ya existe):

```bash
curl -s --request POST "$API/projects/$P/protected_branches" -H "$H" \
  --data-urlencode "name=release/*" \
  --data-urlencode "push_access_level=0" \
  --data-urlencode "merge_access_level=40" \
  --data-urlencode "allow_force_push=false"
```

**Cambiar una regla existente** tiene truco. En CE, `PATCH .../protected_branches/:name` solo cambia `allow_force_push` y las claves de despliegue; el `push_access_level` y el `merge_access_level` no se editan. Para cambiar los roles hay que borrar la regla y crearla otra vez:

```bash
curl -s --request DELETE "$API/projects/$P/protected_branches/main" -H "$H" -o /dev/null -w '%{http_code}\n'   # 204
curl -s --request POST "$API/projects/$P/protected_branches" -H "$H" \
  --data-urlencode "name=main" --data-urlencode "push_access_level=0" \
  --data-urlencode "merge_access_level=40" --data-urlencode "allow_force_push=false"
```

En la UI no hace falta: los desplegables de cada fila de `Settings → Repository → Protected branches` se editan en el sitio, sin desproteger. La limitación es solo de la API.

Entre las dos llamadas, `main` está desprotegida. Son milisegundos si van seguidas, pero hazlo cuando nadie esté empujando, y nunca dejes la segunda para "luego".

La protección por defecto de un grupo va en JSON, porque es un objeto:

```bash
curl -s --request PUT "$API/groups/<id-del-grupo>" -H "$H" -H "Content-Type: application/json" \
  --data '{"default_branch_protection_defaults": {
             "allowed_to_push":  [{"access_level": 40}],
             "allowed_to_merge": [{"access_level": 40}],
             "allow_force_push": false}}' \
  | jq .default_branch_protection_defaults
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `push = Maintainers` en `main` "porque solo empujan los de confianza" | Los de confianza son los que más prisa tienen. Y tú eres Owner | `push = No one`: todo por merge request, también lo tuyo |
| Una regla `*` con permisos amplios "para no ir rama por rama" | Gana la más permisiva: anula la protección de `main` | Reglas concretas: `main`, `release/*` |
| `allow_force_push = true` en la rama compartida | Un `--force` borra trabajo de otros sin aviso | Solo en ramas personales, que no se protegen |
| Borrar y recrear la regla en dos pasos separados | La rama queda abierta en medio | Las dos llamadas seguidas, y verificar después |
| Proteger con `merge = No one` sin querer | Nadie puede fusionar: las MR se quedan bloqueadas | `merge = Maintainers`; `No one` solo para congelar una rama a propósito |

---

## 5. Trucos

- **Qué te deja hacer una rama concreta**, con todas las reglas que coinciden ya combinadas: `GET .../repository/branches/main | jq '{protected, can_push, developers_can_push, developers_can_merge}'`. `can_push` es para el usuario del token, no en general.
- **El mensaje de rechazo dice qué capa falló.** `GitLab: You are not allowed to push...` es la rama protegida. `GL-HOOK-ERR: ...` es un server hook. Si no sale ninguno de los dos y el push falla, es Git o la red.
- **Una rama protegida no se puede borrar por `git push`**, ni siquiera con permisos: solo desde la interfaz web. Es la red de seguridad contra `git push origin :main` tecleado deprisa.

---

## 📚 Recursos Adicionales

- [Protected branches](https://docs.gitlab.com/user/project/repository/branches/protected/) — reglas, comodines y permisos
- [Protected branches API](https://docs.gitlab.com/api/protected_branches/) — referencia de los endpoints
- [Default branch protection](https://docs.gitlab.com/user/project/repository/branches/default/#protect-initial-default-branches) — la protección inicial de proyectos nuevos

---

## ✅ Checklist de Verificación

- [ ] Sabes qué número de nivel de acceso corresponde a *No one*, *Developers + Maintainers*, *Maintainers* e *Instance admins*
- [ ] Puedes explicar por qué un Owner no puede empujar a una rama con `push = 0`
- [ ] Sabes qué regla gana cuando una rama coincide con dos
- [ ] Has leído la protección actual de `main` en `app` por API
- [ ] Sabes por qué cambiar los roles de una regla en CE exige borrarla y crearla otra vez

---

[← Anterior: De la convención a la regla](01-de-la-convencion-a-la-regla.md) · [Volver a la Semana 07](../README.md) · [Siguiente: Tags protegidos →](03-tags-protegidos.md)
