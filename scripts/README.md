# Scripts

| Script | Para quién | Qué hace |
|---|---|---|
| `start.sh` | Estudiante | Levanta el laboratorio y espera a que GitLab responda de verdad |
| `stop.sh` | Estudiante | Lo para conservando los datos. Nunca borra volúmenes |
| `verificar-semana.sh` | Estudiante | Autograding: ejecuta el `checks.json` de una semana contra tu instancia |
| `verificar-enlaces.sh` | Autor | Contrato estructural del repositorio: nombres, enlaces, navegación, SVG, JSON |
| `lab/lab-health` | Estudiante | Estado de la instancia, desde dentro del contenedor |
| `lab/lab-backup` | Estudiante | Backup de la instancia |
| `lab/lab-audit` | Estudiante | Auditoría de configuración de la instancia |
| `autocommit.sh` | Autor | Commit automático de los cambios del repositorio |
| `install-autocommit.sh` | Autor | Instalador del timer de systemd para `autocommit.sh` |

---

## Para el estudiante

### Arrancar y parar

```bash
./scripts/start.sh                  # perfil base
./scripts/start.sh observabilidad   # base + Prometheus/Grafana/Loki (Semana 21)
./scripts/stop.sh                   # para, conservando los datos
```

`start.sh` espera a que `/-/readiness` responda antes de darte por listo, que no
es lo mismo que "el contenedor está arriba".

`stop.sh` **nunca borra volúmenes**. Si de verdad quieres destruir la instancia,
escribe el comando a mano: esa fricción es deliberada.

### Autograding

```bash
./scripts/verificar-semana.sh --doctor      # una vez, antes de la Semana 01
./scripts/verificar-semana.sh 09            # al terminar cada semana
./scripts/verificar-semana.sh 09 --proyecto otro-grupo/app
```

Configuración en `~/.bc-gitlab`. Contrato del `checks.json` y qué **no** puede
comprobar: [`docs/autograding.md`](../docs/autograding.md).

Solo lectura: nunca modifica nada.

### Utilidades dentro del contenedor

Se montan en `/opt/lab` desde `scripts/lab/`:

```bash
docker compose exec gitlab /opt/lab/lab-health
docker compose exec gitlab /opt/lab/lab-backup
docker compose exec gitlab /opt/lab/lab-audit
```

> [!WARNING]
> `lab-backup` **no** respalda `/etc/gitlab/gitlab-secrets.json`, y sin ese
> archivo el backup no se puede restaurar. Cópialo aparte:
> `docker compose cp gitlab:/etc/gitlab/gitlab-secrets.json ./gitlab-secrets.json`

---

## Para quien escribe contenido

### Verificación estructural

```bash
bash scripts/verificar-enlaces.sh
```

Comprueba cinco cosas: nombres de carpeta `week-NN-slug`, enlaces relativos que
resuelven, sección de navegación en cada README de semana, SVG de `0-assets/`
enlazados desde algún `.md`, y `checks.json` parseable.

Tiene que salir en verde antes de cerrar cualquier cambio.

`bootcamp/_legado/` está excluido a propósito mientras se absorbe. Cuando quede
vacío, borra también esas dos exclusiones del script.

### Auto-commit

```bash
./scripts/autocommit.sh                      # commit manual
./scripts/install-autocommit.sh install      # timer de systemd
./scripts/install-autocommit.sh install 1h   # cada hora
./scripts/install-autocommit.sh status
./scripts/install-autocommit.sh run
./scripts/install-autocommit.sh uninstall
```

> [!NOTE]
> El bootcamp se escribe en tandas de una semana completa, cerradas con un solo
> commit `feat(week-NN): …`. Si tienes el timer instalado, **desinstálalo
> mientras escribes contenido**: partiría la tanda en commits sueltos sin
> sentido.
