# Práctica 02 — El producto mínimo

> El repositorio deja de estar vacío. Tres funciones de tu dominio, sus tests, y una historia de commits que se lee como una explicación.

**Duración estimada**: 50 min
**Prerrequisitos**: Práctica 01 completada (firmas verificadas) · [Node.js 22 o superior](../../../docs/setup-entorno.md) instalado · Teoría [05](../1-teoria/05-conventional-commits-y-trailers.md) leída

---

## Contexto

A partir de la Semana 09, cada commit dispara un pipeline que construye, prueba y empaqueta. En la 13 hay una imagen que se firma; en la 19, cuatro escáneres que analizan código. Todo eso necesita **algo que morder**.

Este no es un bootcamp de programación y el código va a ser diminuto a propósito: tres o cuatro funciones con lógica de tu dominio y sus tests. Lo que sí importa aquí es **cómo entra ese código en la historia**: un commit por idea, firmado, con un mensaje que explica el porqué.

> [!NOTE]
> Los ejemplos usan el dominio *biblioteca*. Sustituye por el tuyo: si elegiste gimnasio, las funciones serán `puedeReservar`, `cupoDisponible`, `calcularPenalizacion`. La forma es la misma.

---

## Paso 1: Preparar el terreno

**Por qué**: vas a comprometer varios archivos en varios commits. Antes de empezar, conviene tener la rama limpia y actualizada, y confirmar que Node ejecuta TypeScript sin compilarlo.

```bash
cd ~/ruta/a/app
git switch main
git pull --rebase
git status -sb
# ## main...origin/main
```

**Verifica** que tienes Node 22 o superior y que ejecuta TypeScript directamente:

```bash
node --version
echo 'const x: number = 41; console.log(x + 1);' > /tmp/prueba.ts
node --experimental-strip-types /tmp/prueba.ts && rm /tmp/prueba.ts
# 42
```

Node 22 necesita el flag `--experimental-strip-types`; desde Node 23 ya no hace falta, pero el flag se sigue aceptando. Por eso los scripts de este material lo llevan siempre: funcionan en las dos versiones.

---

## Paso 2: `.gitignore` y `package.json`

**Por qué**: el `.gitignore` va **primero**. Si haces `npm install` antes de tenerlo, `node_modules` acaba en el índice, y sacarlo de la historia después es la cirugía de la teoría 08. Son 3.000 archivos: se nota.

```bash
cat > .gitignore <<'EOF'
node_modules/
dist/
coverage/
*.log
.env
.env.*
EOF

git add .gitignore
git commit -m "chore: ignorar dependencias, artefactos de construccion y secretos"
```

Ahora el manifiesto del paquete:

```bash
cat > package.json <<'EOF'
{
  "name": "@plataforma-biblioteca/app",
  "version": "0.0.0",
  "description": "Gestion de prestamos de biblioteca",
  "type": "module",
  "license": "MIT",
  "engines": {
    "node": ">=22"
  },
  "scripts": {
    "test": "node --experimental-strip-types --test 'src/*.test.ts'"
  }
}
EOF

git add package.json
git commit -m "build: declarar el paquete y el comando de tests"
```

**Verifica** que los dos commits salieron firmados:

```bash
git log --pretty='%h %G? %s' -2
# 7b2a4e6 G build: declarar el paquete y el comando de tests
# 9d1f3c5 G chore: ignorar dependencias, artefactos de construccion y secretos
```

> [!TIP]
> `"type": "module"` evita el lío de `require` frente a `import` durante veinticuatro semanas. Y `engines` documenta la versión mínima: en la Semana 09, la imagen del runner tendrá que cumplirla.

---

## Paso 3: La lógica de tu dominio

**Por qué**: tres funciones con reglas de negocio de verdad. Con reglas, no con `return a + b`: los tests tienen que poder fallar por un motivo interesante, y en la Semana 06 alguien (tú, con otro sombrero) tendrá que revisar un cambio en ellas.

```bash
mkdir -p src
cat > src/prestamos.ts <<'EOF'
/** Tarifa diaria de multa, en centimos, para no arrastrar decimales. */
export const MULTA_POR_DIA_CENTIMOS = 50;

/** Prestamos simultaneos que un socio puede tener abiertos. */
export const LIMITE_PRESTAMOS = 3;

export interface Socio {
  id: string;
  prestamosAbiertos: number;
  multaPendienteCentimos: number;
}

/**
 * Multa acumulada por devolver con retraso.
 * Los dias tienen que ser enteros: medio dia de retraso no existe en el mostrador.
 */
export function calcularMulta(diasRetraso: number): number {
  if (!Number.isInteger(diasRetraso)) {
    throw new TypeError("diasRetraso tiene que ser un numero entero");
  }
  return diasRetraso <= 0 ? 0 : diasRetraso * MULTA_POR_DIA_CENTIMOS;
}

/** Un socio puede llevarse un libro si no llego al limite y no debe nada. */
export function puedePrestar(socio: Socio): boolean {
  return socio.prestamosAbiertos < LIMITE_PRESTAMOS
    && socio.multaPendienteCentimos === 0;
}
EOF

git add src/prestamos.ts
git commit
```

Se abre el editor: escribe un mensaje con **título, línea en blanco y cuerpo**. Algo así:

```
feat(prestamos): calcular multas y decidir si un socio puede llevarse un libro

La multa se guarda en centimos porque el mostrador cobra en efectivo y
con euros en coma flotante 0.1 + 0.2 no da 0.3.

El limite de tres prestamos y la exigencia de no deber nada salen del
reglamento de la biblioteca, no de una decision tecnica.
```

**Verifica** que el mensaje tiene cuerpo de verdad:

```bash
git log -1 --format='%B'
```

Tienen que salir el título, una línea en blanco y al menos una línea más. Ese es uno de los requisitos verificables de la semana.

---

## Paso 4: Los tests

**Por qué**: sin tests, `git bisect run` (práctica 04) no tiene con qué juzgar un commit, y el pipeline de la Semana 09 no tiene qué ejecutar. Los tests no son un extra: son lo que hace que la historia sea diagnosticable.

```bash
cat > src/prestamos.test.ts <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { calcularMulta, puedePrestar, MULTA_POR_DIA_CENTIMOS } from "./prestamos.ts";

test("sin retraso no hay multa", () => {
  assert.equal(calcularMulta(0), 0);
});

test("una devolucion adelantada tampoco genera multa", () => {
  assert.equal(calcularMulta(-2), 0);
});

test("la multa crece un dia cada vez", () => {
  assert.equal(calcularMulta(3), 3 * MULTA_POR_DIA_CENTIMOS);
});

test("medio dia de retraso no es un caso valido", () => {
  assert.throws(() => calcularMulta(1.5), TypeError);
});

test("un socio al dia y por debajo del limite puede llevarse un libro", () => {
  assert.equal(puedePrestar({ id: "s1", prestamosAbiertos: 2, multaPendienteCentimos: 0 }), true);
});

test("un socio con multa pendiente no puede", () => {
  assert.equal(puedePrestar({ id: "s2", prestamosAbiertos: 0, multaPendienteCentimos: 150 }), false);
});

test("un socio en el limite no puede", () => {
  assert.equal(puedePrestar({ id: "s3", prestamosAbiertos: 3, multaPendienteCentimos: 0 }), false);
});
EOF

npm test
```

**Verifica**:

```
ℹ tests 7
ℹ pass 7
ℹ fail 0
```

```bash
git add src/prestamos.test.ts
git commit -m "test(prestamos): cubrir limites, retraso negativo y dias fraccionarios"
```

> [!TIP]
> Fíjate en el import: `from "./prestamos.ts"`, **con** la extensión `.ts`. Con módulos ESM y ejecución directa de TypeScript, la extensión es obligatoria. Es el error de arranque más común y el mensaje (`ERR_MODULE_NOT_FOUND`) no lo dice claro.

---

## Paso 5: Una función más, en su propio commit

**Por qué**: para tener historia sobre la que operar en la práctica 03, y para practicar el ciclo completo una segunda vez.

```bash
cat >> src/prestamos.ts <<'EOF'

/** Un libro esta disponible si queda al menos un ejemplar sin prestar. */
export function ejemplaresDisponibles(total: number, prestados: number): number {
  if (prestados > total) {
    throw new RangeError("hay mas ejemplares prestados que existentes");
  }
  return total - prestados;
}
EOF

cat >> src/prestamos.test.ts <<'EOF'

test("quedan ejemplares cuando no estan todos prestados", () => {
  assert.equal(ejemplaresDisponibles(4, 1), 3);
});

test("prestar mas ejemplares de los que hay es un error de datos", () => {
  assert.throws(() => ejemplaresDisponibles(2, 3), RangeError);
});
EOF
```

Falta añadir la nueva función al import del archivo de tests:

```bash
sed -i 's/import { calcularMulta, puedePrestar, MULTA_POR_DIA_CENTIMOS }/import { calcularMulta, puedePrestar, ejemplaresDisponibles, MULTA_POR_DIA_CENTIMOS }/' src/prestamos.test.ts
npm test
```

**Verifica** que ahora pasan nueve tests, y compromételo en **dos** commits separados con `git add -p`:

```bash
git add -p src/prestamos.ts       # solo la función: responde 'y'
git commit -m "feat(prestamos): contar los ejemplares disponibles de un titulo"

git add src/prestamos.test.ts
git commit -m "test(prestamos): cubrir el conteo de ejemplares disponibles"
```

> [!NOTE]
> Separar código y tests en dos commits es discutible y aquí se hace **a propósito**: en la práctica 03 vas a unirlos con `fixup`. Un repositorio real puede preferir un solo commit con las dos cosas; lo importante es que la decisión sea consciente.

---

## Paso 6: Un commit con `Signed-off-by`

**Por qué**: el *Developer Certificate of Origin* es requisito habitual en proyectos libres, y es uno de los requisitos verificables de la semana. También sirve para ver la diferencia con la firma criptográfica: los dos van en el mismo commit y significan cosas distintas.

```bash
cat > CONTRIBUTING.md <<'EOF'
# Cómo contribuir

## Commits

- **Conventional Commits**: `tipo(ambito): resumen en imperativo`.
- **Firmados**: todo commit va firmado con SSH y verificado por la instancia.
- **Con DCO**: `git commit -s` añade el `Signed-off-by`, con el que declaras
  que tienes derecho a aportar ese código.

## Tests

`npm test` antes de cada commit. Cada commit de `main` tiene que pasar los tests
por sí solo: es lo que permite usar `git bisect` cuando algo se rompe.
EOF

git add CONTRIBUTING.md
git commit -s -m "docs: documentar las reglas de contribucion del repositorio"
```

**Verifica** que el trailer está y que la firma también:

```bash
git log -1 --format='%(trailers:key=Signed-off-by,valueonly)'
# Tu Nombre <tu@correo.com>

git log -1 --pretty='%h %G? %s'
# c4e8b1a G docs: documentar las reglas de contribucion del repositorio
```

Dos cosas distintas en el mismo commit: `Signed-off-by` es una **declaración** en texto plano; `G` es una **prueba** criptográfica.

---

## Paso 7: Empujar y comprobar por la API

```bash
git push
```

**Verifica** el estado completo desde la instancia:

```bash
source ~/.bc-gitlab
P="${PROYECTO//\//%2F}"

# Cuántos commits y si alguno tiene dos padres.
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/commits?ref_name=main&per_page=100" \
  | jq '{commits: length, fusiones: (map(select(.parent_ids | length > 1)) | length)}'
# {"commits": 8, "fusiones": 0}

# Los archivos de src/, y que node_modules no se colo.
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$P/repository/tree?ref=main&recursive=true&per_page=100" \
  | jq '{src: [.[] | select(.type == "blob" and (.path | startswith("src/"))) | .name],
         dependencias_versionadas: [.[] | select(.path | startswith("node_modules"))] | length}'
# {"src": ["prestamos.test.ts", "prestamos.ts"], "dependencias_versionadas": 0}
```

---

## ✅ Resultado

- [ ] `.gitignore` cubre `node_modules/`, `dist/` y `.env` **antes** del primer `npm install`
- [ ] `package.json` en la raíz, con el script `test`
- [ ] `src/prestamos.ts` con al menos tres funciones de tu dominio
- [ ] `src/prestamos.test.ts` con nueve tests, y `npm test` en verde
- [ ] Al menos un commit con cuerpo que explica el **porqué**
- [ ] Al menos un commit con `Signed-off-by`
- [ ] Todos los commits salen con `G` en `git log --pretty='%h %G? %s'`
- [ ] `main` tiene ocho commits o más, ninguno con dos padres

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 02
```

---

## 🧯 Si algo sale mal

| Síntoma | Causa | Solución |
|---|---|---|
| `ERR_MODULE_NOT_FOUND` al importar | Falta la extensión `.ts` en el import | `from "./prestamos.ts"` |
| `Unknown file extension ".ts"` | Node 22 sin el flag | `node --experimental-strip-types --test 'src/*.test.ts'` |
| `ejemplaresDisponibles is not defined` en los tests | Falta añadirla al import | El `sed` del paso 5, o edítalo a mano |
| `npm test` no encuentra ningún test | El patrón con comillas se expandió en el shell | Comillas simples alrededor de `'src/*.test.ts'` |
| `node_modules` aparece en `git status` | Se hizo `npm install` antes del `.gitignore` | `git rm -r --cached node_modules` y comprometer |
| El commit sale con `N` | `commit.gpgsign` no está activo en este repositorio | Revisa la práctica 01, paso 3 |
| `git commit` no abre editor | `core.editor` sin configurar y `EDITOR` vacío | `git config --global core.editor nano` |
| El cuerpo del mensaje se perdió | No hay línea en blanco tras el título | Reescríbelo: `git commit --amend` |
| `fusiones: 1` en la comprobación | Un `git pull` sin rebase generó un merge | `git config --global pull.rebase true`; se arregla en la práctica 03 |

---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| [← Práctica 01 — Firmar tus commits](01-firmar-tus-commits.md) | [Práctica 03 — Cirugía sobre la historia →](03-cirugia-sobre-la-historia.md) |

[← Volver a la Semana 02](../README.md)
