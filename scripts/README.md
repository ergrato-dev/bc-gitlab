# Scripts de Automatizacion — Bootcamp GitLab CE

## Scripts Disponibles

| Script | Descripcion |
|--------|-------------|
| `autocommit.sh` | Auto-commit de cambios en el repositorio |
| `install-autocommit.sh` | Instalador del timer systemd para auto-commit |

## Uso

### Auto-commit manual

```bash
./scripts/autocommit.sh
```

### Instalar timer automatico

```bash
./scripts/install-autocommit.sh install
./scripts/install-autocommit.sh install 1h  # cada hora
```

### Verificar estado

```bash
./scripts/install-autocommit.sh status
```

### Ejecutar manualmente

```bash
./scripts/install-autocommit.sh run
```

### Desinstalar

```bash
./scripts/install-autocommit.sh uninstall
```
