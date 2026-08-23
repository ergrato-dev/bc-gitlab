# Proyecto Semana 01 — La instancia y el primer repositorio

> Al terminar tendrás un GitLab que es tuyo y un repositorio que dice qué vas a construir en él durante seis meses.

---

## 🎯 Objetivo

Dejar en pie la **capa 1** de tu plataforma: una instancia GitLab CE operativa y mínimamente endurecida, un grupo raíz que va a contener todo lo demás, y el proyecto `app` con un README que declara tu dominio.

---

## 📦 Qué añade esta capa

Es la primera, así que no se apoya en nada. Pero **todo lo demás se apoya en ella**:

| Lo que creas hoy | Se usa a partir de |
|---|---|
| La instancia | Todas las semanas |
| El grupo raíz | S03 (subgrupos y roles), S12 (`ci/componentes`), S17 (`ci/automatizacion`), S24 (`infra`) |
| El proyecto `app` | S02 (el código), S09 (el primer pipeline), S13 (la imagen), S14 (los despliegues) |
| La rama `main` | S07, donde se protege |
| Tu clave SSH | S02, donde además firma tus commits |
| El token en `~/.bc-gitlab` | El autograding de las 26 semanas |

La decisión que más peso tiene hoy es la más fácil de pasar por alto: **el proyecto cuelga del grupo, no de tu espacio personal**. Un proyecto en `root/app` funciona igual esta semana y obliga a rehacer rutas, permisos y URLs en la Semana 03.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 01` contra la API de tu instancia.

1. Tu instancia responde y corre la version fijada del bootcamp
2. El registro publico de usuarios esta desactivado en la instancia
3. Tu usuario tiene al menos una clave SSH registrada
4. Existe el grupo raiz de tu plataforma
5. El grupo tiene una descripcion que dice de que va tu plataforma
6. Existe el proyecto app dentro de ese grupo
7. El proyecto cuelga del grupo, no de tu espacio personal
8. El proyecto es privado
9. La descripcion del proyecto declara el dominio que elegiste
10. La rama por defecto del proyecto se llama main
11. El repositorio tiene al menos un commit tuyo
12. Hay un README.md en la raiz del repositorio

---

## 🎨 Criterios de calidad

Lo que la API no puede ver y sí puntúa la rúbrica:

- **El dominio es concreto.** "Gestión de préstamos de una biblioteca: socios, libros y fechas de devolución" sirve. "Aplicación web" no: dentro de cuatro semanas no sabrás qué issues inventar.
- **El README explica, no rellena.** Un lector que no sepa nada de ti debería entender de qué va el proyecto en treinta segundos.
- **Las descripciones del grupo y del proyecto dicen cosas distintas.** El grupo describe la plataforma; el proyecto, el producto. Copiar la misma frase en los dos sitios cumple la comprobación y no dice nada.
- **El mensaje del commit sigue Conventional Commits** y explica qué hace, no qué archivo toca.
- **La contraseña de `root` no es la inicial** y tu correo de GitLab coincide con el de Git.

---

## 💡 Adaptación a tu dominio

| Dominio | Grupo | Descripción del proyecto `app` |
|---|---|---|
| 📖 Biblioteca | `plataforma-biblioteca` | Gestión de préstamos: socios, libros y fechas de devolución |
| 🏋️ Gimnasio | `plataforma-gimnasio` | Reserva de clases: miembros, rutinas y cupos por sesión |
| 🎥 Cine | `plataforma-cine` | Venta de entradas: funciones, salas y asientos |
| 💊 Farmacia | `plataforma-farmacia` | Control de inventario: medicamentos, lotes y caducidades |

El patrón del grupo es `plataforma-<dominio>`, en minúsculas y con guiones. El proyecto siempre se llama `app`: así los comandos del material te sirven tal cual.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu instancia**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 01
```

```
12 de 12 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| El proyecto quedó en tu espacio personal | Falla `El proyecto cuelga del grupo, no de tu espacio personal` | Bórralo y créalo de nuevo con `namespace_id` del grupo |
| Descripción demasiado corta | Falla el requisito 5 o el 9 | Mínimo 20 caracteres, y que digan algo |
| La rama se llama `master` | Falla el requisito 10 | `git branch -m master main`, empuja, y cambia la rama por defecto en `Settings → Repository` |
| El repositorio está vacío | Fallan los requisitos 10, 11 y 12 | La rama por defecto no existe hasta el primer push |
| Reutilizaste un proyecto anterior | Comprobaciones que pasan sin que hayas hecho nada | Empieza limpio: la historia del proyecto es el entregable del bootcamp |
| `PROYECTO=` mal escrito | El script verifica contra otro proyecto | Formato `<grupo>/<proyecto>`, sin URL y sin `.git` |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| — | **Proyecto Semana 01** | [Proyecto Semana 02](../../week-02-git_avanzado_y_firma_de_commits/3-proyecto/README.md) |

[← Volver a la Semana 01](../README.md)
