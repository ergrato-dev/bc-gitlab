# 🔬 Prácticas — Semana 04

Issues, Merge Requests y Code Review en entornos reales de GitLab CE.

---

## 📋 Índice de Prácticas

| # | Práctica | Tiempo | Nivel |
|---|----------|--------|-------|
| 01 | [Crear y Gestionar Issues](./01-crear-issues/README.md) | 45 min | ⭐⭐ Intermedio |
| 02 | [Crear y Configurar Merge Requests](./02-crear-merge-requests/README.md) | 50 min | ⭐⭐ Intermedio |
| 03 | [Code Review Práctico](./03-code-review-practico/README.md) | 45 min | ⭐⭐⭐ Avanzado |
| 04 | [Issue Boards (Kanban)](./04-issue-boards/README.md) | 30 min | ⭐ Básico |

**Total estimado: ~2h 50min**

---

## 🔄 Flujo entre Prácticas

```
Práctica 01 (Issues + Labels + Milestones)
         ↓
    Issues creados con labels workflow::*
         ↓
Práctica 02 (Crear MR vinculado a issue)
         ↓
    MR en estado "Ready" con commits reales
         ↓
Práctica 03 (Code Review: comentarios, sugerencias, approve, merge)
         ↓
    MR mergeado, issue cerrado automáticamente
         ↓
Práctica 04 (Issue Board: visualizar flujo completo)
         ↓
    Board Kanban con estado del sprint
```

---

## ⚙️ Configuración Inicial

Antes de empezar, tener disponible:

```bash
# Token de autenticación (creado en Semana 03)
export GITLAB_TOKEN="<tu-personal-access-token>"

# Verificar acceso al servidor
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  http://localhost/api/v4/user \
  | python3 -c "import sys,json; u=json.load(sys.stdin); print(f'Conectado como: {u[\"username\"]}')"
```

```
Usuarios necesarios (creados en Semana 03):
  - developer1   (rol Developer en api-gateway)
  - maintainer1  (rol Maintainer en api-gateway)

Proyecto necesario:
  - bootcamp-org/backend/api-gateway (Semana 03)
```

---

## ⚠️ Notas Importantes

- Las prácticas son **secuenciales** — cada una asume que la anterior está completada
- Los comandos usan `python3` para parsear JSON (no requiere `jq`)
- El `$GITLAB_TOKEN` debe ser del usuario `root` o un admin para poder crear labels y usuarios
- Los MRs creados en la Práctica 02 se usan directamente en la Práctica 03

---

⬅️ **Teoría:** [1-teoria/](../1-teoria/)
➡️ **Proyecto:** [3-proyecto/instrucciones.md](../3-proyecto/instrucciones.md)
