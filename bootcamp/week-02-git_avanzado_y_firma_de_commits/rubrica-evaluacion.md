# Rúbrica de Evaluación — Semana 02

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 2 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | Cambias una letra del mensaje del commit más antiguo de una rama de veinte. ¿Cuántos SHA cambian y por qué? |
| 2 | ¿Qué diferencia hay entre `git restore <archivo>` y `git reset --hard`, y cuál de las dos cosas que destruyen puede recuperar el reflog? |
| 3 | Tu commit está firmado, `git verify-commit` dice `Good "git" signature`, y GitLab lo muestra como *Unverified*. Da dos causas posibles y cómo distinguirlas. |
| 4 | ¿Por qué un rebase deja los commits sin firmar, y por qué Git no avisa de ello? |
| 5 | ¿Qué diferencia hay entre `Signed-off-by:` y una firma SSH? ¿Cuál de las dos puede escribir cualquiera en nombre de cualquiera? |
| 6 | Buscas el commit que cambió `<` por `<=` en una comparación. `git log -S` no lo encuentra y `git log -G` sí. ¿Por qué? |
| 7 | ¿Por qué `--force-with-lease` es preferible a `--force`, y contra qué escenario **no** te protege ninguno de los dos? |
| 8 | Un script de `git bisect run` sale con código 1 en un commit que ni siquiera compila. ¿Qué consecuencia tiene y qué código debería devolver? |
| 9 | Se filtró un token en un commit de hace tres meses. Ordena los pasos y justifica por qué la limpieza de la historia **no** es el primero. |
| 10 | ¿Por qué la verificación de firmas es Free en GitLab CE y rechazar automáticamente los commits sin firmar es Premium? ¿Con qué se sustituye en este bootcamp? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Cambian **veinte**: el del commit tocado y el de los diecinueve descendientes. El SHA de un commit es el hash de su texto, y ese texto contiene el SHA del padre. Cambiar el mensaje cambia el texto, luego cambia el SHA; el hijo nombraba el SHA viejo, así que su propio texto cambia, y así en cascada hasta la punta. Los commits antiguos no se modifican: siguen existiendo, huérfanos, alcanzables por el reflog hasta que pase el recolector de basura. Y como cada firma cubre un SHA concreto, las veinte firmas dejan de valer: hay que refirmar.

**2.** `git restore <archivo>` sobrescribe el archivo en el **directorio de trabajo** con la versión del índice. `git reset --hard` mueve `HEAD`, vacía el índice y arrasa el directorio de trabajo, los tres a la vez. El reflog registra movimientos de referencias, así que **recupera los commits** que `reset --hard` dejó atrás (`git reset --hard HEAD@{1}`), pero **no** los cambios que nunca llegaron a ser un objeto: lo que `restore` descarta, o lo que `reset --hard` tira del directorio de trabajo, no está en ningún sitio. Por eso `git stash` antes de cualquiera de los dos.

**3.** Git verifica matemáticas; GitLab verifica identidad dentro de la instancia. Dos causas frecuentes: (a) la clave está registrada con `usage_type: auth`, y GitLab solo busca entre las de uso `signing` o `auth_and_signing` → `unknown_key`; (b) el correo del committer no pertenece a la cuenta dueña de la clave → `other_user`, o le pertenece sin estar confirmado → `same_user_different_email`. La interfaz agrupa los tres bajo "Unverified" y no los distingue: el diagnóstico está en `GET /projects/:id/repository/commits/:sha/signature`, que devuelve el `verification_status` exacto.

**4.** Porque el rebase **no mueve** commits: los recrea. Los commits resultantes tienen otro SHA, y una firma que cubría el SHA anterior no vale para ellos, así que Git simplemente no la copia. No avisa porque, desde su punto de vista, no ha pasado nada anómalo: ha creado commits nuevos y, como no se le pidió firmarlos, no los firma. La opción que lo arregla es `rebase.gpgSign true` (o `--gpg-sign` en cada rebase), y la comprobación que lo detecta es `git log --pretty='%h %G? %s'` antes de empujar.

**5.** `Signed-off-by:` es un **trailer de texto plano** en el mensaje: declara, en el sentido del Developer Certificate of Origin, que tienes derecho a aportar ese código. No lo respalda nada: cualquiera puede escribir el nombre y el correo de cualquiera, y de hecho `git commit -s` solo copia lo que haya en `user.name` y `user.email`. La firma SSH es una **prueba criptográfica** de que quien creó el commit poseía una clave privada concreta, y GitLab la ata a una cuenta. Uno declara intención; la otra demuestra identidad. Conviven en el mismo commit y no se sustituyen.

**6.** Porque `-S` (*pickaxe*) no busca texto: cuenta **apariciones**. Enseña los commits donde el número de veces que aparece la cadena cambia, es decir, dónde se introdujo o se eliminó. Cambiar `<` por `<=` no altera cuántas veces aparece el identificador de al lado, así que `-S` no ve nada. `-G` acepta una expresión regular y enseña los commits cuyo **diff** la contiene, cambie o no el recuento. Regla práctica: `-S` para "¿cuándo se introdujo esto?", `-G` para "¿quién tocó esta línea?".

**7.** `--force` sobrescribe la rama remota pase lo que pase: si alguien empujó entre tu último `fetch` y tu push, su trabajo desaparece sin aviso. `--force-with-lease` comprueba primero que el remoto sigue en el commit que tú creías; si se movió, falla y te obliga a mirar. Contra lo que **no** protege ninguno: contra la gente que ya clonó. Sus repositorios siguen teniendo la historia vieja, y su próximo `pull` mezcla las dos. Eso no lo arregla ninguna opción de `push`: se arregla no reescribiendo lo que ya salió de tu máquina.

**8.** Si sale con 1, Git lo marca como **`bad`** y sigue bisecando por la mitad equivocada: el resultado señalará un commit inocente, y no habrá ninguna señal de que la búsqueda se torció. El código correcto es **125**, que significa "no puedo juzgar este commit": Git lo salta y busca otro punto de prueba. Los códigos 0 significan `good`; de 1 a 124, más 126 y 127, `bad`; de 128 a 255, abortar. Un script de bisect serio empieza por `npm ci || exit 125`.

**9.** El orden es: **(1) revocar el token, (2) rotar lo que dependiera de él, (3) limpiar la historia** con `git filter-repo`, y (4) forzar el push y ejecutar el mantenimiento del repositorio en GitLab para purgar los objetos huérfanos. La limpieza no es el primer paso porque **reescribir la historia no invalida una credencial**: mientras el token siga siendo válido, da igual que ya no aparezca en el repositorio, porque puede estar en un clon, en un log de CI, en un backup, en un fork o en el portapapeles de alguien. Revocar corta el acceso en segundos; limpiar la historia solo quita el rastro, cuesta que todos vuelvan a clonar y deja la historia entera sin firmar.

**10.** Porque son dos cosas distintas: **verificar** es leer un dato del commit y compararlo con las claves registradas, y eso está en el código abierto de CE junto con su API y su distintivo *Verified*. **Rechazar** automáticamente un push que incumple una política es una *push rule*, que es la feature Premium. El sustituto libre son los **server hooks**: un `pre-receive` de unas pocas líneas que consulta la firma y devuelve un código distinto de cero, en el mismo punto del recorrido y con el mismo efecto (Semana 07). El complemento es un job de pipeline que audita las firmas por API y falla la merge request (Semana 09): detecta en vez de bloquear, y es el patrón que este bootcamp repite cada vez que una feature de gobernanza es de pago.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| 01 — Firmar tus commits | Clave dedicada creada y registrada con `usage_type=signing`, las cinco opciones de firma configuradas, `allowed_signers` funcionando, y la API devolviendo `verified` para `main` | 10 |
| 02 — El producto mínimo | `.gitignore` antes del primer `npm install`, `package.json` con script `test`, tres funciones con reglas reales, nueve tests en verde, y cada cambio en su propio commit firmado | 10 |
| 03 — Cirugía sobre la historia | Cinco commits de trabajo reducidos a dos con `--fixup`/`--autosquash`, `--exec` recorriendo la serie sin fallos, firmas conservadas, `range-diff` revisado e integración con `--ff-only` | 10 |
| 04 — Arqueología y auditoría | `bisect run` localizando el commit culpable, contraste `--grep`/`-S`/`-G` entendido, `blame` con `-w -C -C`, árbol de trabajo secundario creado y eliminado, y auditoría de firmas por API | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

Los ejecuta `./scripts/verificar-semana.sh 02`. Aproximadamente 4,3 puntos por comprobación.

| # | Requisito | Puntos |
|:--:|---|:--:|
| 1 | Tienes una clave SSH registrada solo para firmar (usage_type signing) | 4 |
| 2 | El ultimo commit de main tiene una firma que GitLab da por verificada | 5 |
| 3 | La firma del ultimo commit de main es SSH, no GPG ni X.509 | 4 |
| 4 | La historia de main es lineal: ningun commit tiene dos padres | 5 |
| 5 | Todos los commits de main siguen Conventional Commits en el titulo | 5 |
| 6 | main tiene al menos 8 commits | 4 |
| 7 | Al menos un commit explica el porque en el cuerpo del mensaje | 4 |
| 8 | Al menos un commit lleva el trailer Signed-off-by | 4 |
| 9 | Existe un package.json en la raiz del repositorio | 4 |
| 10 | Hay al menos un modulo TypeScript de tu dominio en src/ | 5 |
| 11 | Hay al menos un archivo de tests junto al codigo en src/ | 5 |
| 12 | Hay un .gitignore en la raiz del repositorio | 4 |
| 13 | node_modules no esta versionado en el repositorio | 3 |
| 14 | Solo queda la rama main: las ramas de trabajo se borraron al integrarlas | 4 |

### Calidad — 40 puntos

Lo que la API confirma que existe pero no puede juzgar.

| Criterio | Qué se valora | Puntos |
|---|---|:--:|
| Reglas de negocio reales | Las funciones tienen límites, unidades decididas y al menos un caso de error. `sumar(a, b)` no puntúa | 10 |
| Tests de los bordes | Cero, negativo, fraccionario, el límite exacto. No solo el caso feliz | 10 |
| Mensajes que explican el porqué | Al menos un cuerpo con una decisión justificada que el diff no puede contar | 10 |
| Historia legible | `git log --oneline` se entiende sin abrir un solo diff, y cada commit es una idea | 10 |

---

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un secreto real o con formato válido en la historia, aunque esté borrado del último commit | **-100 (revocar, rotar y rehacer)** |
| La clave privada de firma versionada en el repositorio | **-100 (generar otra y revocar la registrada)** |
| Clave de firma sin contraseña | -30 |
| `node_modules` o `dist/` versionados | -25 |
| Commits sin firmar mezclados con firmados en `main` | -20 |
| Historia con commits de fusión pudiendo ser lineal | -15 |
| Títulos que cumplen la convención sin decir nada (`fix: cambios`) | -15 |
| Todos los commits del mismo tipo (`chore:` para todo) | -10 |
| Tests que solo cubren el caso feliz | -10 |
| `git push --force` en vez de `--force-with-lease` | -10 |
| Ramas de pruebas abandonadas en la instancia | -5 |

Las dos primeras anulan la semana. Un secreto en un repositorio se **revoca primero** y se explica después: mientras exista, es válido, y reescribir la historia no lo invalida.

---

[← Volver a la Semana 02](README.md)
