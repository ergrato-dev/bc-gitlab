# Variables de archivo y *secure files*

> Algunos secretos no son una cadena: una clave SSH, un certificado, un almacén de claves. Tienen varias líneas, o son binarios, y no caben en una variable que se pueda enmascarar. GitLab ofrece dos sitios para ellos. Tienen nombres parecidos y garantías muy distintas, y la documentación no lo deja tan claro como el laboratorio.

---

## 🎯 Objetivos

- Usar una variable de tipo archivo y saber qué recibe el job
- Subir, listar y descargar un *secure file*
- Explicar quién puede descargar un *secure file*, y por qué eso lo descarta para una clave privada
- Elegir entre los dos con un criterio que puedas defender

---

## 1. Qué problema resuelve

Una clave SSH tiene varias líneas. Como variable de texto no se puede enmascarar (teoría 04), y el job tendría que escribirla en un archivo con el formato exacto antes de usarla: un salto de línea perdido y `ssh` la rechaza sin decir por qué. Las herramientas quieren una **ruta**, no un valor.

---

## 2. Cómo funciona

### 2.1 Variable de tipo archivo

Una variable de proyecto con `variable_type=file`. El runner escribe el valor en un archivo temporal y entrega al job **la ruta**:

```
$ echo "$DEPLOY_SSH_KEY"
/builds/<grupo>/app.tmp/DEPLOY_SSH_KEY
```

El archivo vive fuera del directorio del repositorio (`$CI_PROJECT_DIR.tmp/`), así que no acaba en un artefacto ni en la caché por accidente, y el runner lo borra al terminar el job.

| Atributo | ¿Disponible? |
|---|:--:|
| `protected` | ✅ |
| `environment_scope` | ✅ |
| `masked` | ❌ si tiene varias líneas, que es el caso habitual |
| `hidden` | ✅ solo si se puede enmascarar |

Hereda todo lo de las teorías 04 y 05: protegida y con ámbito `production`, solo llega a `deploy-production` en `main`. Es lo que usa `app` para `DEPLOY_SSH_KEY`.

Se crea igual que cualquier variable, con el archivo como valor:

```bash
curl -s --request POST "$API/projects/$P/variables" -H "$H" \
  --data "key=DEPLOY_SSH_KEY" --data "variable_type=file" \
  --data "protected=true" --data "environment_scope=production" \
  --data-urlencode "value@$CLAVES/deploy_app" | jq '{key, variable_type, protected, environment_scope}'
rm -f "$CLAVES/deploy_app"
```

`$CLAVES` es un directorio temporal (`mktemp -d`) fuera del repositorio: la clave privada se borra en cuanto está subida, como en la práctica 04.

### 2.2 *Secure files*

`Settings → CI/CD → Secure files`. Archivos de hasta 5 MB, hasta 100 por proyecto, guardados cifrados fuera del repositorio. Es **Free**.

Un job los descarga con la API y su `CI_JOB_TOKEN`:

```bash
curl -s -H "JOB-TOKEN: $CI_JOB_TOKEN" \
  "$CI_API_V4_URL/projects/$CI_PROJECT_ID/secure_files/<id>/download" -o archivo
```

La documentación propone un instalador (`download-secure-files`) que se ejecuta con `curl ... | bash`. No lo necesitas: hace lo mismo que esa línea, y ejecutar un script descargado sin leerlo es justo lo que este bootcamp no enseña.

### 2.3 Quién descarga un *secure file*

Lo que comprobó el laboratorio en 19.2.4:

| Quién | Listar | Descargar | Subir o borrar |
|---|:--:|:--:|:--:|
| Un Developer, con su token personal | `200` | `200` | `403` |
| Un job de la merge request de un Developer | `200` | `200` | — |
| Un job de `main` | `200` | `200` | — |

No hay `protected`, no hay ámbito de entorno. **Cualquiera con rol Developer en el proyecto descarga cualquier *secure file***, por API o desde el pipeline de cualquier rama.

Eso no es un fallo: es el diseño. Los *secure files* nacieron para compilar apps móviles, donde cada desarrollador necesita el perfil de firma de depuración. Pero descarta guardar ahí nada que un Developer no deba tener.

### 2.4 Cuál usar

| Pregunta | Variable de archivo | *Secure file* |
|---|---|---|
| ¿Puede verlo cualquier Developer del proyecto? | No, si es protegida | **Sí** |
| ¿Llega solo a refs protegidas? | Sí, si es protegida | No |
| ¿Un valor por entorno? | Sí, con `environment_scope` | No |
| ¿Binario? | No: texto | Sí |
| ¿Tamaño? | Hasta 10 000 caracteres | Hasta 5 MB |

La regla de `app`: **una clave privada nunca es un *secure file***. `DEPLOY_SSH_KEY` es una variable de archivo protegida con ámbito `production`, y `checks.json` comprueba que ningún *secure file* tenga nombre de clave.

¿Y para qué sirven, entonces? Para lo que es secreto **fuera** del equipo pero no **dentro**: una licencia de una herramienta de pago, un certificado de firma de pruebas, un archivo de configuración de un servicio compartido de desarrollo. `app` hoy no tiene ninguno.

---

## 3. Cómo se configura

```bash
# Subir
curl -s --request POST "$API/projects/$P/secure_files" -H "$H" \
  --form "name=licencia.lic" --form "file=@licencia.lic" | jq '{id, name, checksum}'

# Listar, sin descargar
curl -s -H "$H" "$API/projects/$P/secure_files" | jq -r '.[] | "\(.id) \(.name) \(.created_at)"'

# Borrar
curl -s --request DELETE "$API/projects/$P/secure_files/<id>" -H "$H" -w '%{http_code}\n'
```

Borrar un *secure file* no deshace las descargas: si una clave privada pasó por ahí, se considera expuesta y se rota.

---

## 4. Antipatrones

| Antipatrón | Por qué duele | Qué hacer en su lugar |
|---|---|---|
| Una clave privada como *secure file* | Cualquier Developer la descarga, desde la API o desde una rama | Variable de archivo protegida con ámbito |
| Una clave como variable de texto | No se enmascara, y el job tiene que reconstruir el archivo | Variable de tipo archivo |
| `curl ... \| bash` del instalador | Ejecuta código remoto sin leerlo | Una línea de `curl` con `JOB-TOKEN` |
| `cat "$DEPLOY_SSH_KEY"` para comprobar que llegó | La clave entera en el log, sin enmascarar | `ssh-keygen -lf "$DEPLOY_SSH_KEY"`: la huella |
| Borrar el *secure file* y dar el asunto por cerrado | Ya pudo descargarse | Rotar la clave |

---

## 5. Trucos

- **Comprobar que una clave llegó sin mostrarla**: `ssh-keygen -lf "$DEPLOY_SSH_KEY"` imprime la huella, que es pública.
- **Comprobar que un *secure file* no cambió**: `GET .../secure_files/<id> | jq .checksum` contra `sha256sum` del original.
- **El valor de una variable de archivo con un salto de línea final**: la API lo conserva; la clave SSH lo necesita.

---

## 📚 Recursos Adicionales

- [Use file type CI/CD variables](https://docs.gitlab.com/ci/variables/#use-file-type-cicd-variables) — qué recibe el job
- [Project-level secure files](https://docs.gitlab.com/ci/secure_files/) — límites y uso
- [Secure files API](https://docs.gitlab.com/api/secure_files/) — subir, listar, descargar y borrar

---

## ✅ Checklist de Verificación

- [ ] Sabes qué recibe un job de una variable de tipo archivo
- [ ] Sabes quién puede descargar un *secure file* en `app`
- [ ] Sabes por qué `DEPLOY_SSH_KEY` no es un *secure file*
- [ ] Sabes comprobar que una clave llegó sin enseñarla

---

[← Anterior: Entornos como ámbito](05-entornos-como-ambito.md) · [Volver a la Semana 10](../README.md) · [Siguiente: Secretos fuera del YAML y del log →](07-secretos-fuera-del-yaml-y-del-log.md)
