# Proyecto Semana 02 — El código y la historia que lo cuenta

> El repositorio pasa de tener un README a tener un producto: tres funciones con reglas de tu dominio, sus tests, y una historia firmada que se lee de arriba abajo.

---

## 🎯 Objetivo

Dejar en pie la **capa 2** de tu plataforma: el código mínimo que todas las semanas siguientes van a construir, probar, empaquetar, escanear y desplegar; y la disciplina de historia con la que va a entrar todo lo demás durante veinticuatro semanas.

---

## 📦 Qué añade esta capa

La Semana 01 dejó una instancia y un repositorio vacío. Esta lo llena, y fija las reglas de cómo se llena.

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| `src/` con la lógica de tu dominio | S09 (el pipeline la prueba), S13 (la imagen la contiene), S19 (los escáneres la analizan) |
| `src/*.test.ts` | S09 (el job `test`), S16 (la duración del pipeline se mide sobre ellos) |
| `package.json` | S09 (`npm ci`), S13 (paquete en el registry), S20 (SBOM) |
| Clave SSH de firma registrada | Todas: cada commit del bootcamp va firmado |
| Historia lineal y convencional | S07 (server hook que la exige), S08 (el tipo decide la versión; el trailer `Changelog:`, el CHANGELOG) |
| `.gitignore` | Todas: es lo que impide que un `.env` acabe en la historia |
| `.git-blame-ignore-revs` | S06 y S26, cuando el `blame` tenga que señalar a la lógica y no al formateo |

La decisión con más recorrido de esta semana no es el código: es la **historia**. Un repositorio con commits `wip` y `arreglos` sigue funcionando, y hace inútiles `git bisect` (S02), el CHANGELOG automático (S08) y la mitad de la revisión de código (S06). Se paga en la semana en que algo se rompe, no ahora.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 02` contra la API de tu instancia.

1. Tienes una clave SSH registrada solo para firmar (usage_type signing)
2. El ultimo commit de main tiene una firma que GitLab da por verificada
3. La firma del ultimo commit de main es SSH, no GPG ni X.509
4. La historia de main es lineal: ningun commit tiene dos padres
5. Todos los commits de main siguen Conventional Commits en el titulo
6. main tiene al menos 8 commits
7. Al menos un commit explica el porque en el cuerpo del mensaje
8. Al menos un commit lleva el trailer Signed-off-by
9. Existe un package.json en la raiz del repositorio
10. Hay al menos un modulo TypeScript de tu dominio en src/
11. Hay al menos un archivo de tests junto al codigo en src/
12. Hay un .gitignore en la raiz del repositorio
13. node_modules no esta versionado en el repositorio
14. Solo queda la rama main: las ramas de trabajo se borraron al integrarlas

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **Las funciones tienen reglas de negocio de verdad.** `calcularMulta(dias)` con un límite, un caso de error y una unidad decidida a conciencia sirve. `sumar(a, b)` no: no hay nada que revisar, nada que romper y nada que bisecar.
- **Los tests cubren los bordes, no el caso feliz.** Cero, negativo, fraccionario, el límite exacto. Un test que solo comprueba `2 + 2` no detecta la regresión de la Semana 09.
- **Los mensajes de commit explican el porqué.** "Se guarda en céntimos porque el mostrador cobra en efectivo" es información que no está en el diff y no se recupera después.
- **Un commit, una idea.** Si el título necesita una "y", probablemente eran dos commits.
- **La historia se lee de arriba abajo** y cuenta cómo se construyó el producto. Ese es el criterio final: si `git log --oneline` no se entiende sin abrir diffs, la cirugía de la práctica 03 no se hizo del todo.
- **La clave de firma tiene contraseña.** Una clave de firma sin contraseña en un portátil firma como tú para siempre.

---

## 💡 Adaptación a tu dominio

| Dominio | Funciones sugeridas | Regla que hace interesante el test |
|---|---|---|
| 📖 Biblioteca | `calcularMulta`, `puedePrestar`, `ejemplaresDisponibles` | El límite de préstamos y la multa pendiente |
| 🏋️ Gimnasio | `cupoDisponible`, `puedeReservar`, `penalizacionPorNoAsistir` | El cupo por clase y las faltas acumuladas |
| 🎥 Cine | `asientosLibres`, `puedeReservar`, `precioConDescuento` | El asiento ya vendido y el descuento por día |
| 💊 Farmacia | `diasHastaCaducar`, `puedeDispensar`, `stockDisponible` | El lote caducado y la receta obligatoria |

El patrón es el mismo en los cuatro: **una función de cálculo, una de decisión y una de conteo**, con al menos un caso que lance error. Con eso hay material para tests, para revisión, para el pipeline y para el escaneo de las semanas siguientes.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu repositorio en la instancia**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 02
```

```
14 de 14 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| La clave de firma se registró con uso `auth` | Falla el requisito 1, y el 2 devuelve `unknown_key` | Bórrala y regístrala con `usage_type=signing` |
| El último commit salió sin firmar | El requisito 2 falla; la API devuelve 404 | `git commit --amend --no-edit -S` y `git push --force-with-lease` |
| Un rebase dejó commits con `N` | El requisito 2 falla tras la práctica 03 | `rebase.gpgSign true` y `git rebase --gpg-sign origin/main` |
| Un `git pull` generó un merge | Falla el requisito 4 | `git config --global pull.rebase true`; rehacer con `git rebase` |
| Un título no sigue la convención | Falla el requisito 5 | `git rebase -i` y `reword` sobre ese commit |
| Todos los mensajes son de una línea | Falla el requisito 7 | `git commit --amend` y añadir cuerpo tras una línea en blanco |
| `node_modules` versionado | Falla el requisito 13 | `git rm -r --cached node_modules`, comprometer, y `.gitignore` primero la próxima vez |
| Quedó una rama de pruebas | Falla el requisito 14 | `git push origin --delete <rama>` y `git branch -D <rama>` |
| Falla el requisito 10 pero el archivo existe | Está fuera de `src/`, o no acaba en `.ts` | El comprobador mira `src/` y la extensión |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 01](../../week-01-instalacion_y_arquitectura_de_gitlab_ce/3-proyecto/README.md) | **Proyecto Semana 02** | [Proyecto Semana 03](../../week-03-grupos_proyectos_y_permisos/3-proyecto/README.md) |

[← Volver a la Semana 02](../README.md)
