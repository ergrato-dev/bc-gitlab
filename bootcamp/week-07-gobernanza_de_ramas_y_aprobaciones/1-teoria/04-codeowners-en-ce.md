# CODEOWNERS en CE

> `CODEOWNERS` dice quién responde de cada parte del repositorio. En Premium, GitLab lo lee y exige la aprobación de esa persona. En CE no lo lee. Sigue mereciendo la pena escribirlo: lo lee una persona y lo lee tu auditoría.

---

## 🎯 Objetivos

- Escribir un `CODEOWNERS` con regla por defecto, reglas por ruta y dueño del propio archivo
- Saber cómo se resuelve qué regla aplica a un archivo: la última que coincide
- Distinguir lo que hace GitLab Premium con `CODEOWNERS` de lo que hace CE, que es nada
- Usarlo como fuente de verdad de un script que comprueba las aprobaciones

---

## 1. Qué problema resuelve

`app` va a crecer. La lógica de préstamos la conoce bien `revisor`, la documentación cualquiera puede revisarla, y los archivos que definen las reglas del propio repositorio (`CODEOWNERS`, el hook, la plantilla de merge request) no deberían cambiar sin que lo vea alguien distinto de quien los toca.

Sin un sitio donde escribirlo, ese reparto vive en la cabeza de alguien. La persona nueva no sabe a quién pedir revisión, y nadie puede comprobar después si un cambio en `src/` lo aprobó quien debía.

`CODEOWNERS` es ese sitio: un archivo de texto, versionado, con una línea por ruta y sus dueños.

---

## 2. Cómo funciona

### 2.1 La sintaxis

```
# Comentario
<patrón>  <dueño> [<dueño> ...]
```

Un dueño es `@usuario`, `@grupo/subgrupo` o un correo. Ejemplo para `app`:

```
# Por defecto: cualquiera de los dos
*                      @ana @revisor-biblioteca

# La lógica del dominio la revisa siempre revisor
/src/                  @revisor-biblioteca

# Las reglas no las cambia solo quien las sufre
/CODEOWNERS            @revisor-biblioteca
/scripts/              @revisor-biblioteca
/.gitlab/              @revisor-biblioteca
```

### 2.2 Qué regla se aplica: la última que coincide

GitLab y GitHub resuelven igual: para cada archivo se recorren las reglas de arriba abajo y **gana la última que coincide**. No se suman.

| Archivo | Reglas que coinciden | Dueños |
|---|---|---|
| `README.md` | `*` | `@ana @revisor-biblioteca` |
| `src/prestamos.ts` | `*`, `/src/` | `@revisor-biblioteca` |
| `CODEOWNERS` | `*`, `/CODEOWNERS` | `@revisor-biblioteca` |
| `scripts/hooks/pre-receive` | `*`, `/scripts/` | `@revisor-biblioteca` |

De ahí sale la convención de orden: **lo general arriba, lo específico abajo**. Si pones `*` al final, anula todas las demás.

### 2.3 Los patrones

Siguen las reglas de `.gitignore`, con matices:

| Patrón | Coincide con |
|---|---|
| `*` | Todo |
| `/src/` | El directorio `src` de la raíz y todo lo que contiene |
| `src/` | Cualquier directorio llamado `src`, a cualquier profundidad |
| `/README.md` | Ese archivo en la raíz |
| `*.md` | Cualquier `.md`, en cualquier sitio |

El script de esta semana solo entiende los tres primeros tipos de la forma `/ruta/` o `/archivo`, más `*`. Es suficiente para `app`, y cuando no lo sea, el comentario `ponytail:` del script dice qué añadir.

### 2.4 Dónde va el archivo

GitLab busca `CODEOWNERS` en la raíz, en `docs/` y en `.gitlab/`, y usa el primero que encuentra. Este bootcamp lo pone en la **raíz**, donde lo ve cualquiera que abra el repositorio y donde lo busca la comprobación `codeowners-en-la-raiz`.

### 2.5 Lo que hace Premium y lo que hace CE

| Qué | Tier | En CE |
|---|---|---|
| Mostrar los dueños de un archivo al abrirlo | **Premium** | No se muestra |
| Mostrar los dueños en el widget de la merge request | **Premium** | No se muestra |
| Avisar de errores de sintaxis en `CODEOWNERS` | **Premium** | Sin aviso: un error pasa desapercibido |
| *Require approval from code owners* en la rama protegida | **Premium** | No existe |
| Secciones `[Docs]`, secciones opcionales `^[Docs]` y número de aprobaciones `[Docs][2]` | **Premium** | Se pueden escribir, nadie las interpreta |

En CE, GitLab trata `CODEOWNERS` como cualquier otro archivo de texto. **No hay ni una línea de código en CE que lo lea.** Todo lo de la tabla está en la parte de EE del código fuente.

### 2.6 Entonces, ¿para qué en CE?

1. **Para las personas.** Quien abre una merge request sabe a quién pedir revisión sin preguntar.
2. **Para la auditoría.** El script `gobernanza` de la [práctica 02](../2-practicas/02-codeowners-y-la-auditoria.md) lo lee y comprueba que cada archivo tocado lo aprobó uno de sus dueños. Lo que Premium bloquea, CE lo detecta.
3. **Para el futuro.** Si algún día la organización paga Premium, el archivo ya está escrito y probado. Y GitHub usa la misma sintaxis.

### 2.7 Quién es dueño de `CODEOWNERS`

La línea más importante del archivo es la que lo protege a él mismo. Sin ella, quien quiera saltarse la revisión de `src/` solo tiene que añadirse como dueño en la misma merge request.

Por eso el script lee el `CODEOWNERS` de la **rama de destino**, no el de la merge request: los cambios a la lista de dueños solo cuentan cuando ya están fusionados, y para fusionarlos hace falta la aprobación del dueño actual del archivo.

---

## 3. Cómo se configura

Es un archivo: se crea en una rama y entra por merge request, como cualquier cambio.

```bash
git switch -c 12-codeowners
$EDITOR CODEOWNERS
git add CODEOWNERS
git commit -S -m "chore: add CODEOWNERS"
```

Leerlo desde la API, el de `main`:

```bash
curl -s -H "$H" "$API/projects/$P/repository/files/CODEOWNERS/raw?ref=main"
```

Los dueños de un archivo concreto, con la regla de la última coincidencia, en una línea de `awk`:

```bash
duenos() { awk -v f="/$1" '/^[[:space:]]*(#|$)/ {next} $1=="*" || index(f,$1)==1 {d=$0}
                          END {sub(/^[^ ]+ +/,"",d); print d}' CODEOWNERS; }
duenos src/prestamos.ts     # @revisor-biblioteca
```

En la UI no hay nada que configurar en CE. En Premium, `Settings → Repository → Protected branches` añade la columna *Code owner approval*.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| `*` al final del archivo | Gana la última: anula todas las reglas específicas | `*` la primera |
| Sin dueño para `/CODEOWNERS` | Cualquiera se nombra dueño de lo que toca | `/CODEOWNERS` con un dueño distinto del autor habitual |
| Una sola persona dueña de todo | Cuello de botella y vacaciones bloqueadas | Al menos dos dueños en la regla por defecto |
| Nombrar a quien no es miembro del proyecto | No puede aprobar; en Premium la regla se ignora | Solo miembros con Developer o más |
| Escribir secciones `[Backend][2]` en CE creyendo que exigen dos aprobaciones | En CE no las interpreta nadie | Reglas planas y la auditoría que las comprueba |
| Leer `CODEOWNERS` de la rama de la merge request | La MR puede cambiar sus propios dueños | Leerlo de la rama de destino |

---

## 5. Trucos

- **Los dueños de todos los archivos de una merge request** en un bucle: los nombres salen de `GET .../merge_requests/<iid>/diffs | jq -r '.[].new_path'` y cada uno pasa por la función `duenos`.
- **Grupos como dueños** (`@plataforma-biblioteca/app`) funcionan en Premium; para el script de CE se expanden a mano o se usan usuarios.
- **Revisa `CODEOWNERS` cuando muevas archivos.** Un `git mv src/ lib/` deja `/src/` apuntando a nada y todo cae en la regla por defecto sin aviso.

---

## 📚 Recursos Adicionales

- [Code Owners](https://docs.gitlab.com/user/project/codeowners/) — documentación de GitLab (Premium)
- [Code Owners syntax](https://docs.gitlab.com/user/project/codeowners/reference/) — patrones, secciones y prioridad
- [About code owners — GitHub](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) — misma idea, misma regla de la última coincidencia

---

## ✅ Checklist de Verificación

- [ ] Sabes qué regla gana cuando dos coinciden con un archivo
- [ ] Sabes por qué `/CODEOWNERS` necesita su propio dueño
- [ ] Puedes enumerar tres cosas que Premium hace con `CODEOWNERS` y CE no
- [ ] Sabes por qué la auditoría lee el `CODEOWNERS` de la rama de destino

---

[← Anterior: Tags protegidos](03-tags-protegidos.md) · [Volver a la Semana 07](../README.md) · [Siguiente: Server hooks →](05-server-hooks.md)
