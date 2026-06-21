# Glosario — Semana 05: CI/CD Fundamentos

| Termino | Definicion |
|---------|------------|
| **Pipeline** | Secuencia automatizada de stages y jobs que se ejecutan al hacer push al repositorio |
| **Stage** | Etapa del pipeline; define el orden de ejecucion. Jobs en la misma stage corren en paralelo |
| **Job** | Unidad de trabajo dentro de una stage; ejecuta comandos en un entorno aislado |
| **Runner** | Agente que ejecuta los jobs del pipeline; puede ser compartido, de grupo o especifico |
| **Script** | Comandos que se ejecutan dentro de un job |
| **Artifact** | Archivos generados por un job que se pasan a jobs posteriores o se descargan |
| **Cache** | Almacenamiento temporal de dependencias para acelerar ejecuciones futuras |
| **Image** | Imagen Docker que define el entorno de ejecucion del job |
| **Service** | Contenedor auxiliar que se ejecuta junto al job (ej: base de datos, redis) |
| **DIND** | Docker-in-Docker; tecnica para ejecutar comandos Docker dentro de un contenedor |
| **before_script** | Comandos que se ejecutan antes del script principal en cada job |
| **after_script** | Comandos que se ejecutan despues del script, incluso si el job falla |
| **YAML** | Lenguaje de serializacion usado para escribir `.gitlab-ci.yml` |
| **CI Lint** | Herramienta integrada de GitLab para validar la sintaxis del pipeline |
| **expire_in** | Tiempo de retencion de artifacts antes de ser eliminados automaticamente |
| **allow_failure** | Permite que un job falle sin detener el pipeline completo |
