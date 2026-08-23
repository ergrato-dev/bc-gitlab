# Rúbrica de Evaluación — Semana 04

## 📊 Distribución de Evidencias

| Tipo | Peso | Instrumento | Quién juzga |
|---|:--:|---|---|
| 🧠 Conocimiento | 30% | 10 preguntas conceptuales, 10 pts cada una | Autoevaluación |
| 💪 Desempeño | 40% | Las 4 prácticas, 10 pts cada una | La API de tu instancia |
| 📦 Producto | 30% | La capa 4 de tu plataforma: 60 pts por API + 40 pts de calidad | Mixto |

**Criterio de aprobación: mínimo 70% en cada evidencia**, no en el promedio.

---

## 🧠 Conocimiento (30%)

| # | Pregunta |
|:--:|---|
| 1 | El archivo `LICENSE` está en la raíz con texto correcto, y `GET /projects/:id` devuelve una respuesta sin campo `license`. ¿Qué está pasando, y por qué GitLab lo diseñó así? |
| 2 | Tienes el mismo texto en `docs/decisiones.md` y en la wiki. ¿Cuál sobra, y qué regla lo decide sin recurrir al gusto personal? |
| 3 | ¿Por qué el avatar del proyecto sacado de `logo.png` es mejor que el mismo archivo subido por la interfaz, si visualmente el resultado es idéntico? |
| 4 | Un compañero edita el ADR-002 para reflejar la decisión nueva, en vez de escribir un ADR-003. ¿Qué se pierde exactamente, y por qué eso importa más que la duplicación que se evita? |
| 5 | Alguien clona el repositorio y `assets/logo-grande.png` pesa 133 bytes. Da dos causas posibles y di cómo distinguirlas. |
| 6 | ¿Por qué el `.gitattributes` tiene que entrar en un commit anterior al del binario, si el resultado final del árbol de archivos es el mismo en los dos casos? |
| 7 | Una insignia con la ruta escrita a mano y otra con `%{project_path}` producen hoy exactamente la misma URL. ¿En qué tres situaciones dejan de producirla, y por qué ninguna de las tres da un aviso? |
| 8 | Un snippet público y un proyecto público exponen las dos cosas a un anónimo. ¿Por qué el snippet es más peligroso en la práctica? |
| 9 | ¿Qué tienen en común el hecho de que la wiki sea un repositorio Git aparte y el hecho de que no dispare pipelines? Explica qué problema resuelven juntas esas dos propiedades. |
| 10 | La detección de licencia es Free y las políticas de aprobación de licencias son Ultimate. ¿Qué distingue conceptualmente a las dos, y cómo se sustituye la segunda en CE? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Falta el parámetro `?license=true`. Los campos `license` y `license_url` **solo se exponen si se piden**, porque calcularlos obliga a leer el blob de la licencia del repositorio y compararlo contra el catálogo de Licensee: es trabajo que no tiene sentido hacer en cada listado de proyectos. El diseño es el habitual de la API v4 —lo caro es opcional, como `statistics=true`— y la trampa es que la ausencia del campo se parece exactamente a "no hay licencia". Es la diferencia entre "no lo he preguntado" y "he preguntado y no hay", y solo la segunda es información.

**2.** Sobra el del repositorio, **si es una decisión**. La regla es: si el texto tiene que quedar obsoleto cuando cambia el código, va en el repositorio; si no, va en la wiki. Una decisión de arquitectura no envejece: sigue siendo cierta en su fecha aunque el código haya cambiado entero, y por eso ponerla junto al código invita a "actualizarla", que es justo lo que destruye su valor. Al revés también aplica: unas instrucciones de instalación en la wiki envejecen sin que nadie las revise, porque el merge request que rompe el arranque no toca la wiki. La regla no es de gusto: es de ciclo de vida.

**3.** Porque el archivo del repositorio **viaja, se revisa y se recupera**, y el subido no. Viaja: quien clone se lo lleva, y si el proyecto se exporta o se recrea, el avatar vuelve solo. Se revisa: cambiarlo es un commit que alguien puede ver en un merge request, frente a un clic que no deja rastro. Y se recupera: un `git checkout` lo devuelve, mientras que el avatar subido vive en el almacenamiento de la instancia y depende de que el backup lo incluya. Es el mismo criterio que ordena todo el bootcamp: entre dos formas de conseguir lo mismo, gana la que vive en el repositorio.

**4.** Se pierde **la foto de lo que se sabía entonces**, que es todo el valor del ADR. Un ADR no documenta el estado actual —para eso está el código—, documenta el razonamiento en una fecha: qué restricciones había, qué alternativas se veían y qué se aceptó perder. Editado, deja de responder "¿por qué se decidió así?" y pasa a responder "¿qué hacemos ahora?", que es una pregunta que ya responde el repositorio. Y se pierde algo más: la cadena `ADR-002 → ADR-003` cuenta cómo evolucionó el criterio del equipo, y esa información no está en ningún otro sitio. La duplicación que se evita al editar es aparente: no son dos versiones del mismo texto, son dos decisiones distintas tomadas en momentos distintos.

**5.** O bien ese clon no tiene `git-lfs` instalado —o se clonó con `GIT_LFS_SKIP_SMUDGE=1`—, y lo que hay en el disco es el puntero sin resolver; o bien el archivo nunca entró en LFS y lo que hay en el servidor es otra cosa. Se distinguen mirando el contenido: si las 133 bytes son las tres líneas `version`, `oid` y `size`, es un puntero legítimo y el problema es local, y `git lfs install && git lfs pull` lo arregla. Si el archivo del servidor no es un puntero —`GET /repository/files/<ruta>` decodificado no empieza por `version https://git-lfs.github.com/spec/v1`—, el problema es del repositorio y el arreglo es reescribir la historia. La primera se arregla en diez segundos; la segunda, no.

**6.** Porque el árbol final es el mismo pero **la historia no**, y en Git la historia es lo que se clona. El filtro `clean` actúa en el momento del `git add`, y solo si el archivo encaja con un patrón que ya está en el `.gitattributes` **de ese momento**. Si el binario entra antes, sus bytes quedan en un objeto de la historia para siempre: añadir el `.gitattributes` después cambia lo que pasa a partir de ahí, pero cada `git clone` seguirá bajando el objeto viejo. La única forma de sacarlo es `git lfs migrate import`, que reescribe todos los SHA y obliga a todo el mundo a rehacer su clon. Un orden de dos commits evita una operación que se paga en coordinación.

**7.** Dejan de coincidir si el proyecto cambia de ruta —una transferencia o un renombrado, Semana 03—, si cambia la rama por defecto, y si la insignia se copia a otro proyecto. Ninguna avisa porque el fallo es **una imagen que no carga**: el navegador la muestra rota o no la muestra, GitLab no comprueba que la URL de una insignia siga resolviendo, y no hay pipeline ni alerta detrás. Es un fallo silencioso por naturaleza, y por eso la solución no es acordarse de revisarlo sino no crear el problema: los marcadores se resuelven en el momento de renderizar, con los valores actuales del proyecto.

**8.** Porque el proyecto público **es una decisión** y el snippet público es **un descuido**. Publicar un proyecto se hace una vez, se ve en los ajustes, y normalmente alguien lo revisa. Un snippet se crea en veinte segundos para pasarle algo a un compañero, nadie lo revisa después, y no pasa por la detección de secretos que el pipeline aplica al repositorio (Semana 19). El resultado es una página web con contenido sin auditar, indexable, que sobrevive años a la conversación que la originó. El riesgo no está en el mecanismo: está en que el coste de equivocarse es cero en el momento y alto después.

**9.** Las dos propiedades hacen que **escribir en la wiki sea barato**, y ese es el punto. Que sea un repositorio aparte significa que un cambio no toca la historia del código, no aparece en un `git log` del proyecto y no obliga a nadie a revisar nada. Que no dispare pipelines significa que corregir una errata en un runbook no consume minutos de runner ni espera a que un job pase. Juntas resuelven el problema real de la documentación operativa: **si actualizarla cuesta un ciclo de revisión, no se actualiza**. Un runbook que nadie corrige a los tres meses es peor que no tenerlo, porque alguien lo va a seguir a las tres de la mañana.

**10.** Una **lee un dato**, la otra **decide la política de la organización**. Detectar la licencia es comparar un archivo con un catálogo y exponer el resultado: está en el código abierto de CE, con su API y su campo. Las políticas de aprobación de licencias son un motor de reglas sobre dependencias —qué licencias se admiten, qué pasa cuando entra una que no, quién puede aprobar la excepción— y eso es gobernanza, que es lo que GitLab vende. La sustitución en CE tiene dos piezas y las dos son de este bootcamp: **generar el inventario**, con un SBOM producido por el pipeline y cada dependencia con su identificador SPDX; y **aplicar la regla como código**, con Conftest evaluando ese SBOM y fallando el job cuando aparece una licencia no permitida (Semana 20). Se pierde la interfaz y el flujo de excepciones; se conserva lo que importa, que es que nada se despliega sin pasar por la regla.

</details>

---

## 💪 Desempeño (40%)

| Práctica | Criterio | Puntos |
|---|---|:--:|
| [01 — La portada del proyecto](2-practicas/01-la-portada-del-proyecto.md) | README con índice, arranque verificable y diagrama; licencia detectada; `CONTRIBUTING.md`; descripción, temas y avatar; y la prueba del clon limpio superada | 10 |
| [02 — La wiki y el primer ADR](2-practicas/02-la-wiki-y-el-primer-adr.md) | Wiki clonada por Git, portada que es índice, `_sidebar`, ADR-001 y ADR-002 con las dos caras de las consecuencias, y un runbook fechado | 10 |
| [03 — Snippets e insignias](2-practicas/03-snippets-e-insignias.md) | Snippet multiarchivo y privado, leído por API; dos insignias con marcadores, con sus URLs devolviendo 200 | 10 |
| [04 — Binarios con Git LFS](2-practicas/04-binarios-con-git-lfs.md) | `git-lfs` instalado, LFS activado, patrón preciso, `.gitattributes` en un commit anterior, puntero verificado por API y avatar intacto | 10 |

---

## 📦 Producto (30%)

### Verificable por API — 60 puntos

| Requisito | Comprobación | Puntos |
|---|---|:--:|
| README reconocido en la raíz | `readme-en-la-raiz` | 5 |
| Licencia detectada | `licencia-detectada` | 5 |
| `CONTRIBUTING.md` en la raíz | `contributing-en-la-raiz` | 4 |
| Descripción del proyecto | `descripcion-del-proyecto` | 3 |
| Temas del proyecto | `temas-del-proyecto` | 3 |
| Avatar del proyecto | `avatar-del-proyecto` | 4 |
| Portada de la wiki | `wiki-con-portada` | 4 |
| ADR-001 en la wiki | `wiki-con-adr-001` | 5 |
| Cuatro páginas en la wiki | `wiki-con-cuatro-paginas` | 3 |
| Snippet en el proyecto | `snippet-en-el-proyecto` | 4 |
| Ningún snippet público | `ningun-snippet-publico` | 3 |
| Dos insignias propias | `dos-insignias-de-proyecto` | 4 |
| Insignia con marcador | `insignia-con-marcador` | 3 |
| Git LFS activado | `lfs-activado-en-el-proyecto` | 4 |
| `.gitattributes` en la raíz | `gitattributes-en-la-raiz` | 3 |
| Binario guardado en LFS | `binario-guardado-en-lfs` | 3 |

### Calidad — 40 puntos

| Criterio | Qué se mira | Puntos |
|---|---|:--:|
| La prueba del clon limpio pasa | Clonar en vacío y seguir solo el README lleva hasta los tests en verde, sin improvisar | 8 |
| Los ADR están pensados, no anunciados | Contexto escrito para quien no conoce el proyecto, alternativas reales y consecuencias en las dos direcciones | 8 |
| Cero duplicación entre wiki y repositorio | Cada contenido en un solo sitio, y el otro enlaza | 7 |
| `CONTRIBUTING.md` describe el flujo real | Firma, convención de commits y ciclo de merge request tal como se practican aquí | 6 |
| El patrón de LFS es el más estrecho que sirve | Por carpeta, no por extensión suelta; el avatar sigue siendo una imagen | 6 |
| Las insignias y el snippet informan | Insignias que cambiarán de valor, y un snippet que no es documentación disfrazada | 5 |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una insignia con la ruta o la rama escritas a mano | −3 |
| El README documenta lo que se va a hacer, no lo que hay | −5 |
| Un ADR sin consecuencias negativas | −5 |
| Documentación duplicada palabra por palabra en la wiki y en el repositorio | −5 |
| Un ADR aceptado editado en vez de sustituido | −8 |
| `.gitattributes` con un patrón que se lleva `logo.png` | −8 |
| Un snippet público | −15 |
| Un binario de más de un megabyte dentro de la historia de Git | −15 |
| `LICENSE` copiado de otro proyecto con el titular de otro | −20 |
| Un token —cualquiera— versionado en el repositorio, en la wiki o en un snippet | −25 |

---

[← Volver a la Semana 04](README.md)
