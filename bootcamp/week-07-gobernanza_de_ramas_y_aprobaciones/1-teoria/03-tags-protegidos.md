# Tags protegidos

> Un tag `v1.2.0` es una promesa: "esto es exactamente lo que se publicó". Si cualquiera puede crearlo, moverlo o borrarlo, la promesa no vale nada. Proteger los tags de versión cuesta una llamada y se hace antes de la primera release.

---

## 🎯 Objetivos

- Explicar por qué un tag de versión necesita más protección que una rama
- Proteger un patrón de tags (`v*`) y elegir quién puede crearlos
- Saber qué operaciones bloquea un tag protegido: crear, mover y borrar
- Entender qué desbloquea la protección en semanas posteriores: releases y variables protegidas

---

## 1. Qué problema resuelve

Una rama se mueve por diseño: cada fusión la avanza. Un tag no debería moverse nunca. Cuando alguien instala `v0.1.0`, cuando un pipeline despliega `v0.1.0` o cuando una auditoría pregunta qué había en `v0.1.0`, todos dan por hecho que el tag apunta al mismo commit que el día que se creó.

Git no lo garantiza. Con permiso de escritura se puede:

```bash
git tag -f v0.1.0 HEAD           # mover el tag a otro commit
git push --force origin v0.1.0   # y publicarlo
git push origin :v0.1.0          # o borrarlo
```

Cualquier Developer de `app` puede hacer las tres cosas si los tags no están protegidos. Y no hace falta mala intención: basta un script de release que se ejecuta dos veces, o alguien que "corrige" un tag que apuntaba al commit equivocado sin avisar de que ya se había descargado.

---

## 2. Cómo funciona

### 2.1 Lo que bloquea un tag protegido

| Operación | Tag sin proteger | Tag protegido |
|---|---|---|
| Crear | Developer o más | Solo el rol de `create_access_level` |
| Mover (`git push --force` del tag) | Según permisos del proyecto | **Nadie**: `Protected tags cannot be updated.` |
| Borrar con `git push origin :v1` | Developer o más | Nadie: `You can only delete protected tags using the web interface.` |
| Borrar desde la UI o la API | Developer o más | Solo Maintainer u Owner |

Mover un tag protegido no lo permite ningún rol. Si un tag de versión está mal, se publica uno nuevo (`v0.1.1`), no se reescribe el viejo.

### 2.2 Patrones

Igual que en las ramas, el nombre admite `*`. Este bootcamp usa uno solo:

| Patrón | Protege | No protege |
|---|---|---|
| `v*` | `v0.1.0`, `v1.0.0-rc.1`, `v2` | `prueba`, `release-1`, `0.1.0` |

`v*` también protege `version-loca` o `vale`, porque empiezan por `v`. En la práctica no molesta, y un patrón más estricto (`v[0-9]*`) no existe: el comodín es solo `*`.

### 2.3 Quién crea versiones

| `create_access_level` | Quién | Cuándo tiene sentido |
|:--:|---|---|
| `0` (*No one*) | Nadie, ni Maintainer ni admin | Congelar: no habrá más versiones con ese patrón |
| `30` | Developer, Maintainer, Owner | Equipos donde cualquiera publica, con un pipeline que lo controla |
| `40` | Maintainer y Owner | **Lo de este bootcamp**: publicar es una decisión de quien mantiene |
| `60` | Solo administradores de la instancia | Raro; el admin no debería ser quien decide versiones |

En `app`, los Maintainers son tú (como Owner) y `revisor-<dominio>`. `dev-<dominio>` no puede crear `v*`.

Igual que en las ramas, *Allowed to create* para un usuario o un grupo concreto es **Premium**. En CE solo roles y claves de despliegue (`allowed_to_create` con `deploy_key_id`).

### 2.4 Lo que la protección desbloquea más adelante

Proteger los tags no es solo defensa. Varias features de GitLab tratan distinto las referencias protegidas:

| Semana | Qué usa la protección |
|:--:|---|
| S08 | La release `v0.1.0` se crea sobre un tag que ya nace protegido |
| S10 | Las **variables protegidas** de CI/CD solo se entregan a pipelines de ramas y tags protegidos. Sin tags protegidos, el job de release no ve sus secretos |
| S13 | Las imágenes con tag de versión se publican desde pipelines de tags protegidos |
| S15 | Los **runners protegidos** solo ejecutan jobs de referencias protegidas |

Por eso se protege ahora, antes de la primera versión. Proteger el patrón después de haber publicado no arregla los tags que ya se movieron.

---

## 3. Cómo se configura

### 3.1 Con la UI

`Settings → Repository → Protected tags`. Escribe `v*` en *Tag*, aparece *Create wildcard v\**; elige el rol en *Allowed to create* y *Protect*.

### 3.2 Con la API

```bash
curl -s --request POST "$API/projects/$P/protected_tags" -H "$H" \
  --data-urlencode "name=v*" \
  --data-urlencode "create_access_level=40" \
  | jq '{name, create: [.create_access_levels[].access_level]}'
```

Leer y quitar (el `*` va codificado en la ruta):

```bash
curl -s -H "$H" "$API/projects/$P/protected_tags" | jq -r '.[] | "\(.name)  create=\([.create_access_levels[].access_level])"'
curl -s --request DELETE "$API/projects/$P/protected_tags/v%2A" -H "$H" -o /dev/null -w '%{http_code}\n'
```

Igual que con las ramas, no hay `PATCH` para cambiar el rol: se borra la regla y se crea otra.

### 3.3 Crear y borrar un tag de prueba

Crear por Git, como harías con una versión:

```bash
git tag -a v0.0.0-prueba -m "prueba de protección"
git push origin v0.0.0-prueba
```

Intentar borrarlo por Git falla aunque seas Owner. Por la API sí puedes, porque la API es "la interfaz web" a efectos de esta regla:

```bash
git push origin :v0.0.0-prueba        # rechazado
curl -s --request DELETE "$API/projects/$P/repository/tags/v0.0.0-prueba" -H "$H" -o /dev/null -w '%{http_code}\n'   # 204
git tag -d v0.0.0-prueba
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Proteger los tags después de la primera release | Lo que ya se movió no se puede comprobar | Proteger `v*` antes de `v0.1.0` |
| `create_access_level = 30` sin pipeline que controle la release | Cualquier Developer publica una versión desde cualquier rama | `40`, o `30` solo si un pipeline valida el tag |
| "Arreglar" una versión moviendo su tag | Quien ya la descargó tiene otra cosa con el mismo nombre | Publicar `v0.1.1` |
| Tags ligeros para versiones | No guardan quién, cuándo ni por qué; no se pueden firmar | `git tag -a` o `-s` (firmado, Semana 02) |
| Usar `release-*` en un sitio y `v*` en otro | Medio repositorio queda sin proteger | Un patrón único, documentado en `CONTRIBUTING.md` |

---

## 5. Trucos

- **¿Está protegido este tag concreto?** `GET .../repository/tags/v0.1.0 | jq .protected`.
- **Los tags firmados de la Semana 02** se verifican igual que los commits: `GET .../repository/tags/<tag> | jq .commit` y la UI muestra *Verified* junto al tag.
- **Un patrón protege también lo que aún no existe.** No hace falta crear `v*` después de cada versión: la regla se aplica a cualquier tag nuevo que coincida.

---

## 📚 Recursos Adicionales

- [Protected tags](https://docs.gitlab.com/user/project/protected_tags/) — documentación oficial
- [Protected tags API](https://docs.gitlab.com/api/protected_tags/) — referencia de los endpoints
- [Git — Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging) — tags anotados y ligeros

---

## ✅ Checklist de Verificación

- [ ] Sabes qué tres operaciones sobre un tag cambian cuando está protegido
- [ ] Sabes por qué ni un Owner puede mover un tag protegido
- [ ] Puedes explicar qué features de semanas posteriores dependen de que `v*` esté protegido
- [ ] Sabes borrar un tag protegido cuando de verdad hace falta, y por qué es raro que haga falta

---

[← Anterior: Ramas protegidas](02-ramas-protegidas.md) · [Volver a la Semana 07](../README.md) · [Siguiente: CODEOWNERS en CE →](04-codeowners-en-ce.md)
