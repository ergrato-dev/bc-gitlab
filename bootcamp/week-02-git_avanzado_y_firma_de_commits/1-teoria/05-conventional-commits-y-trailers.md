# Conventional Commits y trailers

> Un mensaje de commit tiene dos lectores: la persona que audita el año que viene y la máquina que genera el changelog. Conventional Commits sirve a los dos con la misma línea.

## 🎯 Objetivos

- Escribir un mensaje con título, cuerpo y trailers, y saber qué va en cada parte
- Aplicar Conventional Commits con los tipos que este bootcamp usa
- Marcar un cambio incompatible de forma que una máquina lo detecte
- Usar trailers (`Signed-off-by`, `Co-authored-by`, `Refs`) y leerlos por la API

---

## 1. Qué problema resuelve

`git log` de un repositorio real, sin convención:

```
arreglos
cambios pedidos
ahora sí
update
fix
```

Cinco líneas y cero información. Para saber qué hizo cada commit hay que abrir el diff — y si son doscientos, nadie los abre.

Con convención:

```
feat(prestamos): calcular la multa por retraso
fix(socios): permitir prestar con multa pagada
docs: documentar el calculo de multas
refactor(prestamos): extraer la tarifa a una constante
test(socios): cubrir el limite de tres prestamos
```

Se lee de arriba abajo y se entiende. Y además **una máquina puede clasificarlo**: eso es lo que en la Semana 08 genera el CHANGELOG y calcula la versión sin que nadie escriba nada a mano.

---

## 2. Anatomía de un mensaje

```
tipo(ambito)!: resumen en imperativo, minúscula, sin punto final
                                    <- línea en blanco obligatoria
Cuerpo: por qué era necesario y qué se decidió. Lo que el diff
no puede contar. Se envuelve a unos 72 caracteres.
                                    <- línea en blanco obligatoria
Refs: #14
Signed-off-by: Ana Ruiz <ana@ejemplo.com>
```

| Parte | Regla |
|---|---|
| Título | ≤ 50-72 caracteres, imperativo (*añade*, no *añadido*), sin punto final |
| Línea en blanco | **Obligatoria**. Sin ella, Git trata todo como título |
| Cuerpo | Opcional pero recomendado. El **porqué**, no el qué |
| Trailers | Bloque final, `Clave: valor`, uno por línea |

El título en imperativo no es capricho estético: los mensajes que Git genera solos (`Merge branch...`, `Revert "..."`) están en imperativo, y así el log queda coherente. Un truco para acertar: el título tiene que completar la frase *"al aplicarlo, este commit…"*.

> [!IMPORTANT]
> **El cuerpo cuenta el porqué.** El *qué* ya está en el diff, con más detalle y sin posibilidad de mentir. El *porqué* solo está en tu cabeza, y se pierde. "Se usa `Number.isInteger` en vez de `%` porque `0.5 % 1` es `0.5` y colaba días fraccionarios" es exactamente la clase de frase que salva a alguien dentro de dos años.

---

## 3. Los tipos

La especificación exige solo `feat` y `fix`; el resto es convención ampliamente adoptada. Estos son los que usa este bootcamp, y son los que valida el `checks.json` de la semana:

| Tipo | Cuándo | ¿Cambia la versión? (S08) |
|---|---|---|
| `feat` | Funcionalidad nueva para el usuario | minor |
| `fix` | Corrección de un comportamiento incorrecto | patch |
| `docs` | Solo documentación | no |
| `style` | Formato, espacios, comas. **Sin** cambio de comportamiento | no |
| `refactor` | Reorganiza el código sin cambiar comportamiento | no |
| `perf` | Mejora de rendimiento | patch |
| `test` | Añade o corrige tests | no |
| `build` | Sistema de construcción o dependencias | no |
| `ci` | Configuración de pipelines | no |
| `chore` | Mantenimiento que no encaja en los anteriores | no |
| `revert` | Revierte un commit anterior | según el revertido |

El **ámbito** entre paréntesis es libre y opcional: `feat(prestamos)`, `fix(api)`, `ci(runner)`. Conviene fijar tres o cuatro y respetarlos; veinte ámbitos distintos no clasifican nada.

### Cambios incompatibles

Dos formas, ambas válidas y equivalentes:

```
feat(prestamos)!: cobrar la multa en centimos, no en pesos
```

```
feat(prestamos): cobrar la multa en centimos

BREAKING CHANGE: calcularMulta ahora devuelve centimos.
Quien la consuma tiene que dividir entre 100.
```

El `!` es visible de un vistazo; el trailer `BREAKING CHANGE:` permite explicar la migración. Usa los dos a la vez cuando el cambio afecte a alguien más.

---

## 4. Trailers: metadatos que la máquina lee

Un trailer es una línea `Clave: valor` en el **último bloque** del mensaje, separado por una línea en blanco. Git los entiende de forma nativa (`git interpret-trailers`) y GitLab los expone en la API.

| Trailer | Para qué |
|---|---|
| `Signed-off-by:` | El *Developer Certificate of Origin*: declaras que tienes derecho a aportar ese código |
| `Co-authored-by:` | Atribuye el commit a más de una persona. GitLab lo muestra en la interfaz |
| `Refs:` / `Closes:` | Enlaza con un issue |
| `Reviewed-by:` | Quién revisó, cuando la revisión no pasa por una merge request |
| `BREAKING CHANGE:` | Cambio incompatible |
| `Cherry-picked-from:` | Lo pone `git cherry-pick -x` |

```bash
git commit -s -m "feat(prestamos): calcular la multa por retraso"
```

`-s` añade el `Signed-off-by:` con tu `user.name` y `user.email`. Es un requisito habitual en proyectos de software libre (el kernel de Linux, CNCF, la propia GitLab).

> [!NOTE]
> **`Signed-off-by` no es una firma criptográfica.** Es texto plano: cualquiera puede escribir el nombre de cualquiera. Declara intención, no identidad. La identidad la da la firma SSH de la teoría 06. Los dos conviven y significan cosas distintas, y confundirlos es el malentendido más común de esta semana.

Añadir un trailer a un commit ya escrito, sin editar el mensaje a mano:

```bash
git commit --amend --trailer "Refs: #14"
```

Y leerlos desde la API de GitLab —así es como el autograding de esta semana comprueba tu `Signed-off-by`—:

```bash
source ~/.bc-gitlab
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/plataforma-biblioteca%2Fapp/repository/commits?ref_name=main" \
  | jq '.[0].trailers'
# {"Signed-off-by": "Ana Ruiz <ana@ejemplo.com>"}
```

---

## 5. Palabras clave de GitLab en el mensaje

GitLab lee ciertas palabras en el mensaje de un commit y actúa:

| En el mensaje | Qué hace GitLab |
|---|---|
| `Closes #14` | Cierra el issue 14 cuando el commit llega a la rama por defecto |
| `Fixes #14`, `Resolves #14` | Lo mismo: son sinónimos |
| `Related to #14` | Enlaza sin cerrar |
| `Closes grupo/otro-proyecto#3` | Cierra un issue de otro proyecto |

Es Free y funciona igual desde el mensaje de un commit que desde la descripción de una merge request. Se explota a fondo en la Semana 05, cuando tengas issues que cerrar; hoy basta con saber que el mensaje **es** una interfaz con la plataforma, no solo prosa.

---

## 6. Escribirlos sin esfuerzo

**Una plantilla local**, para que el editor abra con la estructura delante:

```bash
cat > ~/.gitmessage <<'EOF'
# tipo(ambito): resumen en imperativo, <=72 caracteres
#
# Por qué era necesario (no qué hace: eso está en el diff).
#
# Refs: #
EOF
git config --global commit.template ~/.gitmessage
```

Las líneas que empiezan por `#` se descartan al guardar.

**El editor correcto**, porque el de por defecto es `vi` y mucha gente acaba escribiendo mensajes de una línea solo para salir:

```bash
git config --global core.editor "code --wait"   # o nano, vim, micro...
```

**Ver el diff mientras escribes:**

```bash
git commit -v
```

> [!TIP]
> ¿Y las herramientas que validan el formato (`commitlint`, `commitizen`)? Son útiles, pero un hook local se lo salta cualquiera y no es lo que gobierna el repositorio. Este bootcamp valida donde de verdad importa: un **job de pipeline** en la Semana 09 y un **server hook** en la Semana 07, que se ejecutan en el servidor y no dependen de la buena voluntad de cada clon.

---

## 7. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `fix: cambios` | Cumple el formato y no dice nada. Peor que no tener convención | El resumen dice **qué** se arregló |
| Título de 150 caracteres | `git log --oneline`, la lista de commits de GitLab y los correos lo cortan | ≤72, y el resto al cuerpo |
| Sin línea en blanco tras el título | Git trata el bloque entero como título | Línea en blanco, siempre |
| Explicar el *qué* en el cuerpo | Duplica el diff y envejece mal | El *porqué* |
| Un ámbito nuevo por commit | Veinte ámbitos no clasifican nada | Tres o cuatro, fijos |
| Todo `chore` | El changelog sale vacío y la versión no sube nunca | El tipo que corresponda |
| Creer que `Signed-off-by` firma | Es texto plano, no identidad | Firma SSH (teoría 06) |
| Un commit gigante "por si acaso" | No se puede revertir ni bisecar una parte | Un commit, un cambio |

---

## 8. Trucos

**Ver la historia en formato de revisión, con trailers incluidos:**

```bash
git log --format='%h %s%n%b%n---' -5
```

**Contar tus commits por tipo** — dice mucho de cómo trabajas:

```bash
git log --format='%s' | sed -E 's/^([a-z]+).*/\1/' | sort | uniq -c | sort -rn
```

**Buscar todos los cambios incompatibles de la historia:**

```bash
git log --grep='^BREAKING CHANGE' --grep='!:' --extended-regexp --oneline
```

**Extraer un trailer concreto de un commit:**

```bash
git log -1 --format='%(trailers:key=Signed-off-by,valueonly)'
```

**Reutilizar el mensaje de otro commit:**

```bash
git commit -c 8f0b6c1     # lo abre para editar
git commit -C 8f0b6c1     # lo usa tal cual
```

---

## 📚 Recursos Adicionales

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/es/v1.0.0/) — la especificación completa, en español. Se lee en diez minutos
- [How to Write a Git Commit Message](https://cbea.ms/git-commit/) — las siete reglas. El artículo más citado del tema, y con razón
- [`git interpret-trailers`](https://git-scm.com/docs/git-interpret-trailers) — cómo Git parsea el bloque final
- [Developer Certificate of Origin](https://developercertificate.org/) — qué declaras exactamente al poner `Signed-off-by`
- [Palabras clave de cierre en GitLab](https://docs.gitlab.com/ee/user/project/issues/managing_issues.html#closing-issues-automatically) — la lista oficial

---

## ✅ Checklist de Verificación

- [ ] Tu último commit tiene título en imperativo, ≤72 caracteres, sin punto final
- [ ] Al menos un commit tuyo explica el **porqué** en el cuerpo
- [ ] Sabes marcar un cambio incompatible de las dos formas
- [ ] Has añadido un `Signed-off-by` con `-s` y lo has visto en la API
- [ ] Sabes por qué `Signed-off-by` no sustituye a una firma

---

| Anterior | Siguiente |
|---|---|
| [← 04 — Mover y recuperar cambios](04-mover-y-recuperar-cambios.md) | [06 — Firmar commits con SSH →](06-firmar-commits-con-ssh.md) |

[← Volver a la Semana 02](../README.md)
