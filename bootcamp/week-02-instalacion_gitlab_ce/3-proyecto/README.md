# Proyecto Semana 02 — Instancia GitLab CE Documentada

## Objetivo
Levantar una instancia de GitLab CE completamente funcional y documentar el proceso de instalacion.

## Requisitos

1. GitLab CE corriendo en Docker con Docker Compose
2. Configuracion personalizada:
   - Nombre de instancia: "Bootcamp DevOps - [Tu Nombre]"
   - Contrasena root cambiada y segura
   - Registro publico deshabilitado
3. Al menos 1 proyecto de prueba creado y funcional
4. Backup inicial completado

## Entregables

1. **Archivo `docker-compose.yml`** documentado con comentarios
2. **Documento `INSTALL.md`** con:
   - Requisitos verificados
   - Pasos de instalacion ejecutados
   - Problemas encontrados y soluciones
   - Comandos de administracion utiles
3. **Evidencia visual:**
   - Captura del dashboard de GitLab CE funcionando
   - Captura del proyecto de prueba
   - Salida de `docker compose ps`
   - Salida de `docker compose exec gitlab gitlab-ctl status`

## Criterios de Evaluacion

- [ ] Docker Compose configurado correctamente
- [ ] GitLab CE accesible via web en http://localhost
- [ ] Contrasena root cambiada
- [ ] Proyecto de prueba creado con al menos 1 commit
- [ ] Backup realizado exitosamente
- [ ] Documentacion clara y completa
- [ ] Volumenes persistentes funcionando (reiniciar y verificar que datos persisten)

## Script de Verificacion

Ejecuta este script y adjunta la salida al entregable:

```bash
#!/bin/bash
echo "=== GitLab CE Bootcamp - Verificacion Semana 02 ==="
echo ""

echo "--- Docker Status ---"
docker compose -f ~/gitlab-bootcamp/gitlab-instance/docker-compose.yml ps
echo ""

echo "--- GitLab Services ---"
docker compose -f ~/gitlab-bootcamp/gitlab-instance/docker-compose.yml exec gitlab gitlab-ctl status
echo ""

echo "--- HTTP Check ---"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
echo "HTTP Status: $HTTP_CODE"
echo ""

echo "--- Backup List ---"
docker compose -f ~/gitlab-bootcamp/gitlab-instance/docker-compose.yml exec gitlab gitlab-backup list
echo ""

echo "=== Verificacion completada ==="
```
