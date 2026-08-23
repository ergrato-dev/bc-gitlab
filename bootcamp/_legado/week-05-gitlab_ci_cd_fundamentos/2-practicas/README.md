# 🔬 Prácticas — Semana 05

Pipelines de CI/CD desde cero hasta un pipeline completo con tests, services, artifacts y cache.

---

## 📋 Índice de Prácticas

| # | Práctica | Tiempo | Nivel |
|---|----------|--------|-------|
| 01 | [Primer Pipeline](./01-primer-pipeline/README.md) | 30 min | ⭐ Básico |
| 02 | [Múltiples Stages y Jobs Paralelos](./02-stages-y-jobs/README.md) | 40 min | ⭐⭐ Intermedio |
| 03 | [Imágenes Docker y Services](./03-imagenes-personalizadas/README.md) | 45 min | ⭐⭐ Intermedio |
| 04 | [Artifacts y Cache](./04-artifacts-y-cache/README.md) | 45 min | ⭐⭐⭐ Avanzado |

**Total estimado: ~2h 40min**

---

## 🔄 Flujo entre Prácticas

```
Práctica 01 — Primer pipeline mínimo + variables predefinidas
         ↓
Práctica 02 — Stages secuenciales + jobs paralelos + DAG con needs
         ↓
Práctica 03 — Imágenes Docker por job + services (PostgreSQL, Redis)
         ↓
Práctica 04 — Artifacts entre stages + cache de dependencias + JUnit reports
         ↓
Proyecto — Pipeline completo: validate → test → build → deploy
```

---

## ⚙️ Requisitos del Entorno

```bash
# Runner debe estar activo con executor Docker:
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "http://localhost/api/v4/runners?type=instance_type&status=online" \
  | python3 -c "
import sys,json
runners=json.load(sys.stdin)
print(f'Runners online: {len(runners)}')
for r in runners:
    print(f'  #{r[\"id\"]}: {r.get(\"description\",\"N/A\")} executor={r.get(\"executor\",\"unknown\")}')
"

# Si el resultado es 0 runners, contactar al instructor para configurar el runner
```

---

## ⚠️ Notas Importantes

- El runner debe ser **executor: docker** para que funcionen `image:` y `services:`
- Los pipelines tardan tiempo en ejecutarse — lanzar el push y revisar la UI mientras corren
- El cache puede no estar disponible en el primer run — es normal
- Los logs de los jobs son la fuente principal de debug

---

⬅️ **Teoría:** [1-teoria/](../1-teoria/)
➡️ **Proyecto:** [3-proyecto/README.md](../3-proyecto/README.md)
