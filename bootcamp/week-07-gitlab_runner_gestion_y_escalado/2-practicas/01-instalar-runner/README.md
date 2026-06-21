# Practica 01 — Instalar y Registrar Runner

## Objetivo

Instalar GitLab Runner como contenedor Docker y registrarlo en nuestra instancia GitLab CE.

## Requisitos
- Instancia GitLab CE funcionando
- Docker instalado en el host del runner
- Registration token del proyecto/grupo/instancia

## Instrucciones

### Paso 1: Obtener registration token

1. Ve a GitLab → Admin Area → CI/CD → Runners (para shared runner)
2. O bien Settings → CI/CD → Runners en tu proyecto (para specific runner)
3. Copia el registration token

### Paso 2: Instalar Runner via Docker

```bash
docker run -d --name gitlab-runner \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine
```

### Paso 3: Registrar el Runner

```bash
docker run --rm -it \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:alpine register
```

Responde:
- URL: `http://IP_DE_GITLAB`
- Token: el registration token copiado
- Descripcion: `bootcamp-docker-runner`
- Tags: `docker, linux, bootcamp`
- Executor: `docker`
- Imagen default: `alpine:latest`

### Paso 4: Verificar

```bash
# Listar runners
docker exec gitlab-runner gitlab-runner list

# Ver logs
docker logs gitlab-runner
```

En GitLab UI, Settings → CI/CD → Runners → el runner debe aparecer con circulo **verde**.

## Verificacion

- [ ] Runner aparece en la UI de GitLab
- [ ] Circulo indicador esta **verde**
- [ ] `docker ps` muestra el contenedor corriendo
- [ ] `docker exec gitlab-runner gitlab-runner list` muestra el runner

## Reto adicional

Instala un segundo runner con el executor `shell` en el mismo host y registralo con tags diferentes (`shell, linux, legacy`).
