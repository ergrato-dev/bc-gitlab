# El registro de paquetes

> El `.tgz` de `app` vive hoy como artefacto del job `package`: caduca en una semana, y para descargarlo `infra/entornos` necesita el ID de ese job, que viaja como variable desde la Semana 11. El registro de paquetes guarda el mismo archivo con un nombre y una versión, sin caducidad, en una URL que se puede escribir sin conocer ningún job. Es gratis en CE, para una docena de formatos.

---

## 🎯 Objetivos

- Elegir entre el paquete genérico y el formato nativo (npm) para `app`
- Subir y descargar un paquete genérico desde un job con `CI_JOB_TOKEN`
- Decidir qué versiones se pueden sobrescribir y cuáles no
- Proteger un paquete para que solo un Maintainer publique

---

## 1. Qué problema resuelve

| Lo que necesita `infra/entornos` | Con el artefacto (Semana 11) | Con el paquete |
|---|---|---|
| Saber qué descargar | `APP_PACKAGE_JOB_ID`, por dotenv y por variable | El SHA del commit, que ya recibe |
| Que siga ahí mañana | Caduca en 1 semana | No caduca |
| Que siga ahí si se relanza el job | Otro ID de job | La misma URL |
| Instalarlo con un gestor de paquetes | No | Con el formato nativo |

---

## 2. Cómo funciona

### 2.1 Formatos

El registro de paquetes habla el protocolo de cada gestor: npm, Maven, PyPI, NuGet, Composer, Conan, Helm, Go, RubyGems, Cargo, módulos de Terraform… y **genérico**, para cualquier archivo. Todos Free.

### 2.2 Genérico o npm, para `app`

`app` es un paquete npm con nombre de ámbito desde la Semana 02 (`@plataforma-<tu-dominio>/app`). Las dos opciones son reales:

| | Registro npm | Paquete genérico |
|---|---|---|
| Versión | La del `package.json`, semver, una vez | La que tú decidas en la URL |
| Un paquete por cada commit de `main` | Exige inventar `0.2.0-main.3f2a9c1e` en cada build | `app/<SHA>/app.tgz` |
| Lo instala | `npm install @plataforma-…/app` | `curl`, o `npm install <URL del .tgz>` |
| Para | Publicar una librería que otros instalan | Pasar un binario concreto entre proyectos |

Lo que necesita `infra/entornos` es **el binario de un commit concreto**, no la última versión de una librería. Esta semana: **genérico**, versión el SHA en `main` y la versión sin `v` en un tag. El registro npm queda descrito en el ADR-010 como lo que se usaría el día que alguien instale `app` como dependencia.

### 2.3 La URL

```text
PUT  /projects/:id/packages/generic/:nombre/:version/:archivo     subir
GET  /projects/:id/packages/generic/:nombre/:version/:archivo     descargar
```

```bash
curl --fail-with-body -sS -H "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file app.tgz \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/generic/app/$CI_COMMIT_SHA/app.tgz"
# {"message":"201 Created"}
```

- **El archivo se sube con nombre fijo**, `app.tgz`, aunque `npm pack` lo llame `plataforma-biblioteca-app-0.0.0.tgz`. Quien lo descarga no tiene que adivinar nada.
- El `CI_JOB_TOKEN` sube con los permisos de quien lanzó el pipeline: Developer o más.
- `--fail-with-body`: sin él, un `400` deja el job en verde.

### 2.4 Duplicados: qué versión se puede sobrescribir

Por defecto, subir otra vez `app/0.2.0/app.tgz` **añade** un segundo archivo a la misma versión, y la descarga devuelve el último. La versión `0.2.0` ya no dice qué contiene.

Es un ajuste del grupo raíz, y lo cambia su Owner:

| Ajuste | Valor | Efecto |
|---|---|---|
| Permitir duplicados genéricos | **No** | `400 Bad request - Duplicate package is not allowed` |
| Excepciones | `^[0-9a-f]{40}$` | Las versiones por SHA sí se pueden volver a subir |

¿Por qué la excepción? Si relanzas el job `package` de un commit, vuelve a subir el mismo SHA. Sin la excepción, el reintento falla. Con ella, el SHA admite reintentos y `0.2.0` no admite nada.

```bash
curl -s -H "Authorization: Bearer $GITLAB_TOKEN" -H "Content-Type: application/json" \
  "$GITLAB_URL/api/graphql" -d '{"query":"mutation { updateNamespacePackageSettings(input: {
    namespacePath: \"plataforma-<tu-dominio>\", genericDuplicatesAllowed: false,
    genericDuplicateExceptionRegex: \"^[0-9a-f]{40}$\" }) { errors } }"}'
```

No hay REST para esto: es GraphQL o la interfaz (`Settings → Packages and registries → Duplicate packages`, en el grupo).

### 2.5 La limpieza de paquetes

La política de paquetes de un proyecto tiene un solo criterio: **cuántos archivos repetidos** conservar dentro de cada versión (`keepNDuplicatedPackageFiles`: todos, 1, 10, 20, 30, 40 o 50). No borra versiones antiguas. Con los duplicados prohibidos salvo por SHA, `ONE_PACKAGE_FILE` deja un archivo por versión.

Borrar versiones viejas por SHA es a mano o por API (`DELETE /projects/:id/packages/:package_id`). La Semana 17 lo automatiza.

### 2.6 Paquetes protegidos

Igual que las imágenes (teoría 03), un paquete puede exigir un rol mínimo para publicarse. Free, y vale para el genérico:

```bash
curl -s --request POST "$API/projects/$P/packages/protection/rules" -H "$H" -H "Content-Type: application/json" \
  -d '{"package_name_pattern": "app", "package_type": "generic", "minimum_access_level_for_push": "maintainer"}'
```

En `app` **no** la usas: el paquete por SHA lo sube cada pipeline de `main`, que puede lanzar un Developer al fusionar. Es la diferencia con las imágenes, donde la regla mira el tag (`0.2.0`) y no el nombre.

---

## 3. Cómo se configura

```bash
# Qué paquetes y versiones hay
curl -s -H "$H" "$API/projects/$P/packages?package_type=generic&package_name=app&per_page=5&order_by=created_at&sort=desc" \
  | jq -r '.[] | "\(.version)  \(.created_at)"'

# Descargarlo como lo hará infra/entornos, con tu token en lugar del del job
curl --fail -sS -o app.tgz -H "$H" "$API/projects/$P/packages/generic/app/<SHA>/app.tgz" && tar tzf app.tgz | head -3
```

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| El artefacto como única copia | Caduca | El paquete |
| Duplicados permitidos para versiones | `0.2.0` cambia de contenido sin cambiar de nombre | Prohibidos, con excepción para el SHA |
| Duplicados prohibidos sin excepción | Un reintento del job falla | `genericDuplicateExceptionRegex` |
| `curl` sin `--fail-with-body` | El job queda en verde con un `400` | `--fail-with-body` |
| Versionar por número de pipeline | Dice cuándo, no qué | El SHA |
| Nombre de archivo con la versión dentro | Quien descarga tiene que construir dos veces el mismo dato | Nombre fijo |

---

## 5. Trucos

- **El SHA256 de lo publicado**, sin descargarlo: `GET /projects/:id/packages/:package_id/package_files` devuelve `file_sha256` de cada archivo.
- **Instalar el `.tgz` con npm** en otra máquina: `npm install "$API/projects/<id>/packages/generic/app/0.2.0/app.tgz"` funciona si el proyecto es público; si es privado, `curl` con token y `npm install ./app.tgz`.

---

## 📚 Recursos Adicionales

- [Package registry](https://docs.gitlab.com/user/packages/package_registry/)
- [Generic packages](https://docs.gitlab.com/user/packages/generic_packages/)
- [npm packages in the package registry](https://docs.gitlab.com/user/packages/npm_registry/) — la alternativa
- [Protected packages](https://docs.gitlab.com/user/packages/package_registry/package_protection_rules/)

---

## ✅ Checklist de Verificación

- [ ] Sabes por qué `app` publica un paquete genérico y no en el registro npm
- [ ] Sabes qué pasa al subir dos veces la misma versión, con y sin duplicados
- [ ] Sabes por qué el SHA tiene una excepción y `0.2.0` no
- [ ] Sabes qué borra y qué no la limpieza de paquetes

---

[← Anterior: La limpieza](04-la-limpieza.md) · [Volver a la Semana 13](../README.md) · [Siguiente: El dependency proxy →](06-el-dependency-proxy.md)
