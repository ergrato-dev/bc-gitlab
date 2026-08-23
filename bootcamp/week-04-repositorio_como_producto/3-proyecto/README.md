# Proyecto Semana 04 — El repositorio que otro puede arrancar

> `app` deja de ser un repositorio con código y pasa a ser un producto: alguien que no eres tú lo clona, entiende qué hace, lo arranca y sabe cómo proponer un cambio.

---

## 🎯 Objetivo

Dejar en pie la **capa 4** de tu plataforma: la portada del proyecto —README, licencia, guía de contribución, descripción, temas y avatar—, la wiki con las dos primeras decisiones registradas, un snippet y dos insignias que sobreviven a un cambio de ruta, y los binarios guardados donde no envenenan la historia.

---

## 📦 Qué añade esta capa

La Semana 03 dejó una organización con permisos probados. Esta decide **qué encuentra quien llega**, y dónde vive cada tipo de documentación durante las veintidós semanas que quedan.

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| `README.md` con arranque verificado | S09 (el pipeline ejecuta los mismos comandos), S26 (defensa) |
| `LICENSE` con identificador SPDX | S13 (metadatos del paquete), S20 (SBOM y política de licencias) |
| `CONTRIBUTING.md` | S06 (plantilla de merge request), S07 (CODEOWNERS y aprobaciones) |
| Descripción y temas | S17 (auditoría por API del inventario de proyectos) |
| `logo.png` como avatar | S14 (sitio de documentación en Pages) |
| Wiki con portada y barra lateral | Todas: es donde van las decisiones y los runbooks |
| `ADR-001` y `ADR-002` | S08 (changelog y contexto), S22 (postmortem), S26 (auditoría) |
| Runbook de recuperación | S22 (respuesta a incidentes, con el runbook ya escrito) |
| Snippet de arranque | S15 (el mismo guion, contra la flota de runners) |
| Insignias con marcadores | S08 (insignia de release), S09 (pipeline y cobertura pasan a verde) |
| Git LFS y `.gitattributes` | S09 (clon del runner), S13 (qué va al registry y qué no) |

La decisión con más recorrido de esta semana no es cuánta documentación escribes: es **dónde decides que vive cada tipo**. Una vez que el equipo aprende que las decisiones están en la wiki y las instrucciones en el repositorio, se mantiene solo. Si los dos sitios contienen lo mismo, en tres meses contienen dos verdades distintas y ya no sirve ninguno.

Y hay una que no se arregla después: el patrón de `.gitattributes`. Un binario grande que entra en la historia de Git solo sale reescribiéndola.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 04` contra la API de tu instancia.

1. GitLab reconoce un README en la raiz del repositorio
2. GitLab detecta la licencia del repositorio
3. Existe CONTRIBUTING.md en la raiz del repositorio
4. El proyecto tiene una descripcion de al menos 30 caracteres
5. El proyecto tiene al menos tres temas asignados
6. El proyecto tiene avatar
7. La wiki del proyecto tiene pagina de portada (home)
8. La wiki tiene una pagina cuyo slug empieza por adr-001
9. La wiki tiene al menos cuatro paginas
10. El proyecto tiene al menos un snippet
11. Ningun snippet del proyecto es publico
12. El proyecto tiene al menos dos insignias propias
13. Al menos una insignia usa un marcador en vez de una ruta escrita a mano
14. Git LFS esta activado en el proyecto
15. Existe .gitattributes en la raiz del repositorio
16. assets/logo-grande.png esta guardado en LFS, no en la historia de Git

---

## 🎨 Criterios de calidad

Lo que la API confirma que existe pero no puede juzgar:

- **La prueba del clon limpio pasa.** Clonar en un directorio vacío y seguir solo lo que dice el README lleva hasta los tests en verde, sin improvisar ni abrir otro archivo.
- **El README responde las cuatro preguntas en la primera pantalla**: qué es, cómo se arranca, cómo se sabe que fue bien y cómo se propone un cambio.
- **Los ADR tienen las dos caras de las consecuencias.** Un ADR que solo lista ventajas no se ha pensado: es un anuncio.
- **El ADR-001 se entiende sin haber hecho el bootcamp.** El contexto está escrito para alguien de 2028 que no sabe nada de esto.
- **La wiki y el repositorio no dicen lo mismo.** Cero duplicación: cada contenido está en un solo sitio, y el otro enlaza.
- **`CONTRIBUTING.md` describe tu flujo real**, no uno copiado. Si tus commits van firmados, lo dice; si tus ramas se borran al fusionar, lo dice.
- **Las insignias informan.** Una que siempre dirá lo mismo es un adorno con coste de mantenimiento.
- **El patrón de `.gitattributes` es el más estrecho que resuelve el problema.** `assets/*.png`, no `*.png`.
- **El snippet no es documentación disfrazada.** Si lo que contiene necesita revisión antes de cambiarse, es un archivo del repositorio.

---

## 💡 Adaptación a tu dominio

La estructura es la misma en los cuatro casos; lo que cambia es qué se documenta.

| Dominio | Frase del README | ADR-001 decide | Runbook más útil |
|---|---|---|---|
| 📖 Biblioteca | Cálculo de multas y disponibilidad de préstamos | Dominio biblioteca, librería TypeScript | Recuperar el acceso de administración |
| 🏋️ Gimnasio | Reservas de clase con control de cupo | Dominio gimnasio, y por qué no una app completa | Qué hacer si el cupo queda inconsistente |
| 🎥 Cine | Asignación de asientos sin dobles reservas | Dominio cine, y el modelo de asientos elegido | Liberar reservas colgadas de una función |
| 💊 Farmacia | Control de lotes y caducidades | Dominio farmacia, y por qué se validan lotes | Bloquear un lote retirado por el fabricante |

El patrón se repite: **una frase que dice qué hace, una decisión de fondo que explica todo lo demás, y un procedimiento que alguien va a leer con prisa**. Los tres existen en cualquier proyecto real.

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de tu proyecto y de su wiki**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 04
```

```
16 de 16 verificaciones superadas.
```

Si alguna falla, la pista dice en qué práctica y en qué paso se arregla.

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `LICENSE` escrito a mano o retocado | Falla el requisito 2 aunque el archivo exista | Regenerarlo desde `GET /templates/licenses/mit`, sin editarlo |
| Se consultó el proyecto sin `?license=true` | El campo `license` no aparece y parece que no hay | Es un parámetro obligatorio para ese campo |
| `Logo.png` con mayúscula | Falla el requisito 6 | El patrón distingue mayúsculas: `logo.png` exacto |
| La portada de la wiki se llamó `Home` | Falla el requisito 7 y la wiki se queda sin portada | Renombrar la página a `home` |
| El ADR se tituló `adr-001-...` en minúsculas | El requisito 8 lo acepta, pero los enlaces del `_sidebar` no | Usar el slug tal cual sale de `GET /wikis` |
| La wiki tiene tres páginas | Falla el requisito 9 | Faltan el segundo ADR o el runbook |
| El snippet quedó público | Falla el requisito 11 | `PUT` sobre el snippet con `visibility=private` |
| La insignia lleva la ruta escrita a mano | Falla el requisito 13, y se romperá al transferir el proyecto | Marcadores: `%{project_path}`, `%{default_branch}` |
| `.gitattributes` con `*.png` | Pasa los requisitos y rompe el avatar del proyecto | Patrón por carpeta y sacar `logo.png` de LFS |
| El binario entró antes que el `.gitattributes` | Falla el requisito 16: en el repositorio hay bytes, no un puntero | Rehacer los dos commits en el orden correcto |
| `lfs_objects_size` a cero recién empujado | No falla nada: las estadísticas van en segundo plano | Esperar unos segundos |
| Documentación duplicada en wiki y `docs/` | No lo detecta ninguna comprobación; lo detecta la rúbrica | Un contenido, un sitio, y el otro enlaza |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 03](../../week-03-grupos_proyectos_y_permisos/3-proyecto/README.md) | **Proyecto Semana 04** | Proyecto Semana 05 |

[← Volver a la Semana 04](../README.md)
