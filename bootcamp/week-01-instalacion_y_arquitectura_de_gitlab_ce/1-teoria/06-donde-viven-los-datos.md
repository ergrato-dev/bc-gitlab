# Dónde viven los datos

> Tu código no está en la base de datos. Y tu repositorio no está en una carpeta con su nombre.

## 🎯 Objetivos

- Saber qué guarda PostgreSQL y qué guarda el disco
- Explicar por qué los repositorios se almacenan en `@hashed` y no por nombre
- Localizar en disco el repositorio de un proyecto concreto
- Saber dónde acaban artefactos, adjuntos, imágenes del registry y backups

---

## 1. Qué problema resuelve saber esto

Tres situaciones muy reales:

- Vas a hacer un backup y quieres saber qué entra y qué no
- El disco se llena y tienes que averiguar quién se lo está comiendo
- Alguien renombró un proyecto y quieres entender por qué el repositorio no se movió de sitio

Las tres se resuelven sabiendo dónde vive cada cosa.

---

## 2. La división fundamental

| Dónde | Qué |
|---|---|
| **PostgreSQL** | Todo lo que **describe** algo: usuarios, proyectos, issues, merge requests, comentarios, pipelines, permisos, tokens, configuración |
| **Disco (`/var/opt/gitlab`)** | Todo lo que **es** algo: repositorios Git, artefactos de CI, adjuntos, imágenes del registry, backups |

La consecuencia que más sorprende: **la base de datos de GitLab no contiene ni una línea de tu código**. Guarda que existe un proyecto llamado `app`, quién puede verlo y que su rama por defecto apunta a cierto SHA. El contenido de ese SHA está en el disco, y solo Gitaly lo lee.

Por eso una restauración necesita las dos mitades: si restauras la base de datos sin los repositorios, GitLab te enseña una lista de proyectos que al abrirlos dan error.

---

## 3. El mapa del disco

Todo cuelga de `/var/opt/gitlab` (el volumen `gitlab-data`):

| Ruta | Qué guarda | Suele crecer |
|---|---|:--:|
| `git-data/repositories/` | **Los repositorios** | ●●● |
| `postgresql/data/` | Los archivos de PostgreSQL | ●● |
| `gitlab-rails/shared/artifacts/` | Artefactos de CI | ●●● |
| `gitlab-rails/uploads/` | Adjuntos: imágenes en issues, avatares | ● |
| `gitlab-rails/shared/lfs-objects/` | Objetos de Git LFS | ●● |
| `gitlab-rails/shared/packages/` | Package Registry | ●● |
| `gitlab-rails/shared/pages/` | Sitios de GitLab Pages | ● |
| `gitlab-rails/shared/registry/` | Imágenes del Container Registry | ●●● |
| `backups/` | Los backups que generes | ●●● |
| `redis/` | El volcado de Redis | ● |

Los tres con más puntos son los que llenan discos en la vida real: artefactos, imágenes del registry y backups viejos. Las semanas 13 y 22 tratan precisamente de mantenerlos a raya.

---

## 4. `@hashed`: por qué tu repositorio no está donde esperas

Vas a buscar tu proyecto en disco y encuentras esto:

```bash
docker compose exec gitlab ls /var/opt/gitlab/git-data/repositories/@hashed/
```

```
0b  2c  4b  6a  93  d4  fc
```

No hay ninguna carpeta llamada `plataforma-biblioteca`. Los repositorios están en rutas como:

```
@hashed/93/50/9350c2b0c4b7b1c88ba5e5f0f7b2d2d1c8e4a5f6....git
```

### Cómo se construye esa ruta

Se toma el **ID numérico** del proyecto en la base de datos y se calcula su SHA-256:

```
ID del proyecto: 7
SHA-256 de "7": 9350c2b0c4b7b1c88ba5e5f0f7b2d2d1c8e4a5f6...
Ruta: @hashed/93/50/9350c2b0c4b7....git
```

Los dos primeros caracteres del hash son el primer nivel de carpeta, los dos siguientes el segundo, y el hash completo el nombre del repositorio.

### Por qué se hace así

Cuatro razones, todas prácticas:

1. **Renombrar un proyecto no mueve nada en disco.** El ID no cambia, luego la ruta no cambia. Antes de `@hashed`, renombrar un grupo con 300 proyectos significaba mover 300 directorios y rezar.
2. **Reparte la carga en el sistema de archivos.** 256 × 256 subdirectorios posibles: ningún directorio acumula decenas de miles de entradas.
3. **No hay colisiones de nombre.** Dos grupos pueden tener un proyecto `app` sin pisarse.
4. **No filtra información.** Quien tenga acceso al disco no ve los nombres de los proyectos privados en las rutas.

Los dos niveles intermedios (`93/50/`) existen porque muchos sistemas de archivos se degradan cuando un directorio tiene demasiadas entradas.

### Encontrar el repositorio de un proyecto

La API te da la ruta directamente:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp" \
  | jq '{id, path_with_namespace, repository_storage}'
```

Y si prefieres calcularlo tú, sabiendo el ID:

```bash
echo -n "7" | sha256sum
# 9350c2b0c4b7... → @hashed/93/50/9350c2b0c4b7....git
```

> [!TIP]
> Este cálculo es el que salva una recuperación de emergencia: si tienes el disco pero no la base de datos, `@hashed` no te dice qué repositorio es cuál. Sin la base de datos, tienes los datos y no sabes de quién son. Otra razón para que el backup incluya las dos mitades.

---

## 5. Qué entra en un backup y qué no

`gitlab-backup create` produce un solo archivo `.tar` en `/var/opt/gitlab/backups`.

| Entra | No entra |
|---|---|
| Base de datos completa | **`/etc/gitlab/gitlab-secrets.json`** |
| Repositorios y wikis | `/etc/gitlab/gitlab.rb` |
| Adjuntos y avatares | Los logs |
| Artefactos de CI | El contenido de Redis (colas en vuelo) |
| Objetos LFS | |
| Packages y Container Registry | |
| Sitios de Pages | |

> [!WARNING]
> La columna derecha es la que arruina recuperaciones. Sin `gitlab-secrets.json` restauras la instancia y descubres que **todas las variables de CI enmascaradas, los tokens y las credenciales de integraciones son ilegibles**: están cifradas con una clave que ya no tienes.
>
> ```bash
> docker compose exec gitlab /opt/lab/lab-backup
> docker compose cp gitlab:/etc/gitlab/gitlab-secrets.json ./gitlab-secrets.json
> ```
>
> Dos comandos, siempre juntos. La Semana 22 lo practica con el reloj corriendo.

---

## 6. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Tocar un repositorio directamente en `@hashed` | Gitaly mantiene estado propio; lo corrompes | Todo pasa por Gitaly o por la API |
| Backup sin `gitlab-secrets.json` | La restauración deja los secretos ilegibles | Copiarlo aparte, siempre |
| Restaurar solo la base de datos | Los proyectos aparecen y no se pueden abrir | Base de datos y repositorios van juntos |
| Buscar el repositorio por su nombre en disco | No existe esa carpeta y crees que se perdió | Consultar el ID por API y calcular la ruta `@hashed` |
| Dejar artefactos y backups sin política de expiración | El disco se llena y GitLab deja de escribir | Políticas de expiración (S13) y rotación de backups (S22) |

---

## 7. Trucos

**Ver qué ocupa el disco, ordenado:**

```bash
docker compose exec gitlab du -sh /var/opt/gitlab/* | sort -rh | head
```

El primer sitio donde mirar cuando el disco se llena.

**Ver el tamaño de tus repositorios por API**, sin entrar al contenedor:

```bash
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp?statistics=true" \
  | jq '.statistics'
```

El parámetro `statistics=true` es poco conocido y devuelve el desglose completo: tamaño del repositorio, de los artefactos, de LFS y de los packages.

**Comprobar que Gitaly ve bien el almacenamiento:**

```bash
docker compose exec gitlab gitlab-rake gitlab:gitaly:check
```

**Listar los backups existentes:**

```bash
docker compose exec gitlab ls -lh /var/opt/gitlab/backups/
```

---

## 📚 Recursos Adicionales

- [Almacenamiento de repositorios](https://docs.gitlab.com/ee/administration/repository_storage_paths.html) — la explicación oficial de `@hashed`
- [Backup y restauración](https://docs.gitlab.com/ee/administration/backup_restore/) — qué incluye exactamente el backup. Léelo entero antes de la Semana 22
- [Configuración de almacenamiento de objetos](https://docs.gitlab.com/ee/administration/object_storage.html) — cómo se sacan artefactos y registry a S3 en instalaciones grandes
- [Requisitos de disco](https://docs.gitlab.com/ee/install/requirements.html) — cuánto espacio prever

---

## ✅ Checklist de Verificación

- [ ] Sabes qué guarda PostgreSQL y qué guarda el disco
- [ ] Puedes explicar por qué los repositorios están en `@hashed`
- [ ] Sabes localizar el repositorio de un proyecto concreto
- [ ] Sabes qué **no** entra en un backup de GitLab
- [ ] Sabes qué comando te dice qué se está comiendo el disco

---

| Anterior | Siguiente |
|---|---|
| [← 05 — Anatomía de una petición](05-anatomia-de-una-peticion.md) | [07 — Salud, logs y diagnóstico →](07-salud-logs-y-diagnostico.md) |

[← Volver a la Semana 01](../README.md)
