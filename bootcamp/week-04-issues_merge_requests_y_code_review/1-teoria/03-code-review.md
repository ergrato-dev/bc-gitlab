# 03 — Code Review Efectivo en GitLab

## Objetivos

- Entender el proposito y valor del code review
- Aprender a realizar code reviews constructivos
- Usar las herramientas de revision de GitLab
- Dar y recibir feedback efectivamente

## Por que Code Review?

El code review no es solo encontrar bugs. Sus beneficios incluyen:

- **Compartir conocimiento**: Todo el equipo entiende el codigo
- **Mejorar calidad**: Deteccion temprana de errores y malas practicas
- **Consistencia**: Mantener estandares de codigo en todo el proyecto
- **Mentoria**: Desarrolladores junior aprenden de seniors
- **Responsabilidad compartida**: El codigo es del equipo, no de una persona

## Herramientas de Revision en GitLab

### Vista de Cambios (Diffs)

En un MR, la pestana **Changes** muestra:
- Diffs lado a lado o inline
- Archivos modificados con estadisticas (+ lineas agregadas, - eliminadas)
- Navegacion entre archivos
- Colapsado de archivos grandes

### Comentarios en Linea

Puedes comentar en lineas especificas del diff:
1. Hover sobre el numero de linea
2. Click en el icono de comentario
3. Escribir feedback
4. Elegir: **Comment** (comentario normal) o **Start a review** (agrupar varios comentarios)

### Sugerencias (Suggested Changes)

Permite proponer cambios directamente en el diff que el autor puede aceptar con un click:

```markdown
```suggestion
const isAuthenticated = user && user.token !== null;
```
```

El autor vera un boton **Apply suggestion** que aplica el cambio automaticamente.

### Review Summary

Cuando terminas de revisar, envias un resumen:
- **Approve**: Apruebas el MR
- **Request changes**: Solicitas cambios antes de aprobar
- **Comment**: Solo dejas comentarios (sin aprobar ni rechazar)

## Mejores Practicas para el Revisor

### Que buscar

1. **Logica**: El codigo hace lo que deberia?
2. **Seguridad**: Vulnerabilidades? Datos expuestos? Inyecciones?
3. **Rendimiento**: Bucles innecesarios? Consultas N+1?
4. **Pruebas**: Pruebas adecuadas? Casos borde cubiertos?
5. **Estilo**: Sigue las convenciones del proyecto?
6. **Legibilidad**: Nombres claros? Codigo auto-documentado?
7. **Mantenibilidad**: Acoplamiento? Duplicacion?

### Como comunicar

**Bien:**
> "Considera usar `async/await` en lugar de `.then()` para mejorar la legibilidad de esta promesa. Es mas facil de seguir el flujo."

**Mal:**
> "Esto esta mal, no uses .then()"

**Bien:**
> "Podrias mover esta validacion a un middleware para no repetirla en cada endpoint?"

**Mal:**
> "Codigo duplicado. Arreglalo."

### Principio "Convention over Preference"

Si existe una guia de estilo o convencion del equipo, referenciarla. Si es solo preferencia personal, usar "Considera..." o "Sugiero..." y no bloquear el MR.

## Mejores Practicas para el Autor

1. **MRs pequenos** (< 400 lineas): Mas faciles de revisar, menos errores
2. **Descripcion clara**: Que, por que, como probar
3. **Commits atomicos**: Cada commit hace una cosa
4. **Responde a todos los comentarios**: Incluso con "Done" o "Fixed in commit X"
5. **No tomes el feedback personal**: Se trata del codigo, no de ti
6. **Agradece el feedback**: "Buen punto, gracias!"

## Velocidad de Revision

- **MRs pequenos**: Revisar en < 24 horas
- **MRs grandes**: Puede tomar mas, pero avisar al autor
- **Bugs criticos**: Revisar lo antes posible

Si no puedes revisar pronto, deja un comentario: "Lo reviso manana en la manana."

## Proceso de Revision en GitLab

```
1. Autor crea MR y asigna reviewer(s)
2. Reviewer revisa Changes
3. Reviewer comenta en lineas especificas
4. Autor responde/resuelve comentarios
5. Autor hace push de fixes
6. Reviewer re-revisa
7. Reviewer aprueba (Approval)
8. Author mergea (o Maintainer si esta protegido)
```
