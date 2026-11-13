# Proyecto Semana 08 — Hay versiones y el flujo se mide

> En la Semana 07 las reglas empezaron a cumplirse solas. Esta semana `app` tiene por fin algo que entregar: una `v0.1.0` con su CHANGELOG, un parche publicado desde su rama de release, y cuatro números que dicen, con datos propios, cómo fluye un cambio desde que se propone hasta que alguien lo usa.

---

## 🎯 Objetivo

Dejar en pie la **capa 8** de tu plataforma: un modelo de ramas escrito y protegido, versiones SemVer con tags firmados, un CHANGELOG generado desde la historia, releases con notas, y las métricas DORA-lite calculadas y definidas en el propio repositorio.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| ADR-006 y `release/*` protegidas | S10 (las variables protegidas también llegan a `release/*`), S14 (los entornos se modelan como entornos, no como ramas) |
| Trailer `Changelog:` y plantilla de squash | Cada merge request a partir de hoy |
| `.gitlab/changelog_config.yml` | Cada versión; en la Fase 3, desde un job |
| Tags `v0.1.0` y `v0.1.1` y sus releases | S13 (los paquetes se enlazan desde la release), S20 (se firman los artefactos de cada versión) |
| `scripts/metricas.sh` y `docs/metricas.md` | S11 (pipeline programado que añade la medición), S14 (la frecuencia pasa a contar despliegues) |

La decisión con más recorrido es **qué cuenta como fallo**. Hoy, una versión que necesitó un parche. Cuando haya despliegues, será un despliegue revertido o un incidente. Si cambias la definición sin decirlo, la serie histórica de `docs/metricas.md` deja de significar nada: por eso la definición está escrita al lado de los números.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 08` contra la API de tu instancia.

1. Las ramas release/* estan protegidas
2. En release/* nadie empuja y solo los Maintainers fusionan
3. Nadie puede forzar el push sobre release/*
4. El archivo .gitlab/changelog_config.yml esta en main
5. La plantilla de squash conserva los trailers del commit con %{first_multiline_commit_description}
6. Al menos tres commits de main llevan el trailer Changelog
7. CHANGELOG.md en main tiene la seccion de la 0.1.0
8. El tag v0.1.0 existe y es anotado
9. La release v0.1.0 tiene notas generadas con al menos una categoria
10. La release v0.1.0 esta asociada al hito v0.1.0
11. El hito v0.1.0 esta cerrado
12. La rama release/0.1 existe y esta protegida
13. release/0.1 tiene un commit traido de main con cherry-pick -x
14. El tag v0.1.1 tiene commits que no estan en main: sale de release/0.1
15. La release v0.1.1 tiene notas generadas con al menos una categoria
16. El script scripts/metricas.sh esta en main
17. docs/metricas.md en main define las cuatro metricas
18. La wiki tiene una pagina cuyo slug empieza por adr-006

Las prácticas 01 a 04 dejan en verde los requisitos 1 a 15 y el 18. El 16 y el 17 son este proyecto. Ninguno comprueba que los tags estén **firmados**: la API no lo distingue. Lo comprueba `git tag -v` y lo puntúa la rúbrica.

---

## 🛠️ Lo que haces en el proyecto

### 1. Las métricas, en el repositorio

Una merge request desde un issue `tipo::mantenimiento` que añade dos archivos:

- **`scripts/metricas.sh`**: el script de la teoría [07](../1-teoria/07-dora-lite-con-la-api.md), apartado 2.1, sin cambios. Ejecútalo antes de abrir la merge request.
- **`docs/metricas.md`**: la plantilla de la teoría 07, apartado 2.5, con **tus** números en la primera fila de la tabla y tu contexto: cuántas releases, cuántas merge requests, qué bug.

Añade al final de `docs/metricas.md` una sección **Previsto frente a invertido**, con las estimaciones que pusiste en la Semana 05 a los issues del hito:

```bash
curl -s -H "$H" "$API/projects/$P/issues?milestone=v0.1.0&state=closed&per_page=100" \
  | jq '[.[].time_stats] | {previsto_h: (map(.time_estimate) | (add // 0) / 3600), invertido_h: (map(.total_time_spent) | (add // 0) / 3600)}'
```

No es una métrica DORA: es la comprobación de lo bien que estimas. Si no registraste tiempo invertido con `/spend`, sale `0`, y eso también va en el documento.

`/scripts/` es de `revisor` en `CODEOWNERS`: necesita su aprobación. Ningún archivo lleva trailer `Changelog:`: a quien usa `app` no le cambia nada.

Después de fusionar, ejecuta el script **desde `main`** y comprueba que da lo mismo que pegaste. Si no, la diferencia es la propia merge request que acabas de fusionar: anótalo en el contexto.

### 2. La auditoría, sin el falso positivo

En la práctica 04, `gobernanza.sh` marcó `❌ no cierra ningún issue` en la merge request del parche, porque GitLab solo asocia issues a cerrar cuando el destino es la rama por defecto. Cambia esas dos líneas del script para que la regla solo se aplique a `main`:

```bash
if [ "$destino" = main ]; then
  [ "$(api "merge_requests/$IID/closes_issues" | jq length)" -gt 0 ] \
    && bien "cierra un issue" || falla "no cierra ningún issue"
else
  echo "➖ destino $destino: GitLab solo cierra issues al fusionar en main, no se comprueba"
fi
```

Por merge request, con la aprobación de `revisor` (es suyo). Antes de fusionarla, ejecuta la versión nueva contra la merge request del parche de la práctica 04 (`$MR_PARCHE`): tiene que dar `0 problema(s)`. Y contra una de `main` de la práctica 02: tiene que seguir dando `✅ cierra un issue`.

### 3. `CONTRIBUTING.md`: cómo se publica

Añade una sección "Versiones, CHANGELOG y parches" que responda, en este orden:

1. Cuándo poner `Changelog:` en un commit y con qué categoría (tabla con las de `changelog_config.yml`).
2. Por qué el trailer va en el primer commit con cuerpo de la merge request.
3. Qué cifra de la versión sube cada tipo de commit mientras `MAYOR` sea `0`.
4. Cómo se lleva un arreglo a `release/X.Y`, con los comandos.
5. Quién puede crear un tag `v*` y por qué tiene que ir firmado.

Enlaza el ADR-006 en lugar de copiarlo. Va en la **misma** merge request que el punto 2: los dos explican cómo se contribuye.

### 4. La wiki

Enlaza el ADR-006 desde la barra lateral de la wiki, junto al ADR-005.

### 5. Revocar el token de `revisor`

Cuando las merge requests de los puntos 1 a 3 estén fusionadas. Desde la misma terminal en la que creaste `$HR`; si es otra, repite antes el paso 0 de la práctica 01, o la comprobación del `401` pasará por el motivo equivocado:

```bash
source ~/.bc-gitlab && source ~/.bc-gitlab-s08
export API="$GITLAB_URL/api/v4"
[ -n "${T_REV:-}" ] && [[ "${UID_REV:-}" =~ ^[0-9]+$ ]] || { echo "Falta \$T_REV o \$UID_REV: NO sigas"; return 1 2>/dev/null || exit 1; }
HA="PRIVATE-TOKEN: ${GITLAB_ADMIN_TOKEN:-$GITLAB_TOKEN}"
for id in $(curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
              | jq -r '.[] | select(.name == "flujo-s08" and .active) | .id'); do
  curl -s --request DELETE "$API/personal_access_tokens/$id" -H "$HA" -o /dev/null -w "revocado $id: %{http_code}\n"
done

curl -s -o /dev/null -w '%{http_code}\n' -H "$HR" "$API/user"     # 401: el token existía y ya no vale
curl -s -H "$HA" "$API/personal_access_tokens?user_id=$UID_REV" \
  | jq '[.[] | select(.name == "flujo-s08" and .active)] | length'  # 0
unset T_REV HR HA
rm -f ~/.bc-gitlab-s08
```

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **Los dos tags están firmados con tu clave**: `git tag -v v0.1.0` y `git tag -v v0.1.1` dicen `Good`.
- **Cada entrada del CHANGELOG se entiende sin contexto**: el título de la merge request se escribió para quien usa `app`.
- **`v0.1.1` no lleva nada más que el arreglo**: el `compare` con `main` solo muestra el parche y su CHANGELOG.
- **El arreglo se hizo primero en `main`**: el commit de `release/0.1` dice `cherry picked from commit` con un SHA que está en `main`.
- **`docs/metricas.md` define antes de medir**, y cada métrica nombra lo que no captura.
- **Los números de `docs/metricas.md` coinciden con los del script** ejecutado el mismo día.
- **El ADR-006 dice qué se descartó y por qué**, no solo qué se eligió.
- **El token de `revisor` está revocado**, comprobado en negativo.

---

## 💡 Adaptación a tu dominio

El flujo es el mismo. Lo que cambia es qué bug justifica un parche y qué categoría lleva cada cambio.

| Dominio | Un parche típico | Un `changed`, no un `fixed` |
|---|---|---|
| 📖 Biblioteca | Multa calculada con días de retraso negativos | Cambiar el tope de libros por socio |
| 🏋️ Gimnasio | Clase que admite una reserva por encima del cupo | Cambiar la antelación mínima para cancelar |
| 🎥 Cine | Asiento que se puede reservar dos veces | Cambiar el precio del día del espectador |
| 💊 Farmacia | Lote caducado que se da por válido el día de su caducidad | Cambiar los días de aviso antes de caducar |

El patrón: **un `fixed` hace que el código cumpla lo que ya prometía; un `changed` cambia la promesa**. Un `changed` nunca va en un parche.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu proyecto, sus tags, sus releases y su wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 08
```

```
18 de 18 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| Fusionar algo antes de cambiar la plantilla de squash | Falla el requisito 6 aunque los commits lleven el trailer en su rama | El trailer no se recupera: un cambio más con trailer (requisito 6 pide tres) |
| Tag `v0.1.0` antes de fusionar el CHANGELOG | `git show v0.1.0:CHANGELOG.md` no existe | Si la release aún no existe, borrar el tag por API y repetir la práctica 03 desde el paso 3. Si ya existe, no se toca: se anota en el ADR-006 y la siguiente versión lo corrige |
| Arreglo hecho directamente en `release/0.1` | Falla el requisito 13: no hay `cherry picked from commit` | Llevarlo a `main` por merge request y rehacer el parche con `cherry-pick -x` |
| `release/0.1` creada desde `main` en vez de desde `v0.1.0` | Falla el requisito 14 o el `compare` muestra más commits | Borrar la rama (`DELETE` desde la web, está protegida) y crearla desde el tag |
| `docs/metricas.md` sin las cuatro métricas por su nombre | Falla el requisito 17 | Usar los títulos de la plantilla de la teoría 07 |
| Tag sin firmar | No lo detecta ninguna comprobación; `git tag -v` dice `no signature found` | No se puede mover: publicar la siguiente versión firmada y anotarlo en el ADR-006 |
| El token del revisor sin revocar | No lo detecta ninguna comprobación | Punto 5 de este proyecto |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 07](../../week-07-gobernanza_de_ramas_y_aprobaciones/3-proyecto/README.md) | **Proyecto Semana 08** | Proyecto Semana 09 |

[← Volver a la Semana 08](../README.md)
