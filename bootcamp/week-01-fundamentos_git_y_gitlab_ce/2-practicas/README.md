# 🛠️ Prácticas — Semana 01

## 📋 Índice de Prácticas

| # | Práctica | Tiempo | Dificultad | Prerrequisito |
|---|----------|--------|------------|---------------|
| 01 | [Configurar Git y SSH](./01-configuracion-git/README.md) | ⏱️ 45 min | ⭐⭐ | Git instalado |
| 02 | [Flujo Git Básico](./02-flujo-git-basico/README.md) | ⏱️ 60 min | ⭐⭐ | Práctica 01 |
| 03 | [Ramas y Merges](./03-ramas-y-merges/README.md) | ⏱️ 60 min | ⭐⭐⭐ | Práctica 02 |
| 04 | [Primer Proyecto en GitLab CE](./04-primer-proyecto-gitlab/README.md) | ⏱️ 30 min | ⭐ | GitLab CE corriendo |

---

## ✅ Requisitos Previos

Antes de empezar las prácticas:

- [ ] Git instalado (`git --version` debe funcionar)
- [ ] GitLab CE corriendo en Docker (`docker compose ps gitlab` muestra "healthy")
- [ ] Acceso a `http://localhost` con usuario `root`
- [ ] Haber leído la teoría de la semana (carpeta `1-teoria/`)

---

## 📝 Cómo Entregar las Prácticas

Cada práctica tiene un **Entregable** claramente definido. Los entregables son:
- Capturas de pantalla de comandos ejecutados
- URL de repositorios en GitLab CE
- Salida de comandos pegada en texto

Sube tus entregables a tu repositorio de portafolio (`mi-portafolio-devops`) en la carpeta `docs/semana-01/`.

---

## 🚨 Errores Frecuentes en Esta Semana

| Error | Causa Probable | Solución |
|-------|---------------|----------|
| `502 Bad Gateway` al abrir GitLab | GitLab aún iniciando | Esperar 3-5 minutos, ejecutar `docker compose ps gitlab` |
| `Permission denied (publickey)` | Clave SSH mal configurada | Verificar con `ssh-add -l` y que el puerto sea 2224 |
| `Repository not found` al clonar | URL incorrecta o sin permisos | Verificar URL en la UI del proyecto |
| `git push` pide contraseña | Usando HTTP en vez de SSH | Cambiar remote a SSH: `git remote set-url origin ssh://git@localhost:2224/...` |

---

## ➡️ Siguiente

Cuando completes todas las prácticas, ve al [Proyecto de la Semana](../3-proyecto/README.md).
