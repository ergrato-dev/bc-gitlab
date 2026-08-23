# 🏗️ Proyecto — Semana 09: Bot de Automatización DevOps

## 📋 Descripción

Implementar un bot Python que automatice tres tareas operativas recurrentes en GitLab: marcar issues inactivos como `stale`, generar un reporte semanal de salud del proyecto (MRs lentos, pipelines fallidos, ratio issues abiertos/cerrados), y enviar ese reporte a Slack/Discord via webhook.

---

## 🎯 Objetivos del Proyecto

Al completar el proyecto habrás:
1. Construido un cliente GitLab reutilizable con retry automático
2. Implementado lógica de negocio sobre la API (issue staleness, detección de MRs lentos)
3. Generado un reporte Markdown desde datos de la API
4. Enviado el reporte a un sistema externo via webhook saliente
5. Estructurado el código en módulos cohesivos y testeables

---

## 🏗️ Paso 1: Estructura del Proyecto

```
gitlab-bot/
├── .env                     ← variables de entorno (no commitear)
├── .env.example             ← plantilla para otros developers
├── requirements.txt
├── bot.py                   ← entrypoint CLI
├── src/
│   ├── __init__.py
│   ├── client.py            ← cliente GitLab con retry
│   ├── stale_issues.py      ← módulo de issues inactivos
│   ├── reporter.py          ← generación del reporte Markdown
│   └── notifier.py          ← envío via webhook
└── tests/
    └── test_stale_issues.py ← tests con datos mock
```

---

## 📦 Paso 2: Configuración y Cliente

**`requirements.txt`:**
```
python-gitlab==4.4.0
python-dotenv==1.0.1
requests==2.32.3
```

**`.env.example`:**
```bash
GITLAB_URL=http://localhost
GITLAB_TOKEN=glpat-xxxxxxxxxxxx
GITLAB_PROJECT_ID=42
STALE_DAYS=30         # días sin actividad para marcar como stale
NOTIFY_DAYS=7         # días de aviso antes de cerrar automáticamente
SLACK_WEBHOOK_URL=    # opcional — dejar vacío para solo loguear
```

**`src/client.py`:**
```python
"""Cliente GitLab con retry automático y logging."""

import gitlab, logging, os

logger = logging.getLogger(__name__)


def get_client() -> gitlab.Gitlab:
    gl = gitlab.Gitlab(
        url=os.environ["GITLAB_URL"],
        private_token=os.environ["GITLAB_TOKEN"],
        retry_transient_errors=True,
        timeout=30,
    )
    gl.auth()
    current = gl.users.get_current()
    logger.info(f"Autenticado como: {current.username} (ID: {current.id})")
    return gl
```

---

## 🔄 Paso 3: Módulo de Issues Stale

**`src/stale_issues.py`:**
```python
"""Detecta y gestiona issues inactivos (stale)."""

import logging
from datetime import datetime, timezone, timedelta

import gitlab

logger = logging.getLogger(__name__)

STALE_LABEL = "stale"
STALE_COMMENT_MARKER = "<!-- stale-bot-warning -->"


def get_last_activity(issue) -> datetime:
    """Fecha de la última actividad del issue (updated_at o última nota)."""
    updated = datetime.fromisoformat(issue.updated_at.replace("Z", "+00:00"))
    try:
        notes = issue.notes.list(per_page=1, order_by="updated_at", sort="desc")
        if notes:
            note_dt = datetime.fromisoformat(notes[0].updated_at.replace("Z", "+00:00"))
            return max(updated, note_dt)
    except Exception:
        pass
    return updated


def find_stale_issues(proyecto, stale_days: int):
    """Devuelve issues abiertos sin actividad en los últimos stale_days días."""
    cutoff = datetime.now(timezone.utc) - timedelta(days=stale_days)
    issues_abiertos = proyecto.issues.list(state="opened", all=True)
    stale = []

    for issue in issues_abiertos:
        if STALE_LABEL in (issue.labels or []):
            continue   # ya marcado como stale

        last_activity = get_last_activity(issue)
        inactivity_days = (datetime.now(timezone.utc) - last_activity).days

        if last_activity < cutoff:
            stale.append({
                "issue": issue,
                "inactivity_days": inactivity_days,
                "last_activity": last_activity,
            })

    logger.info(f"Issues stale encontrados: {len(stale)}/{len(issues_abiertos)}")
    return stale


def warn_stale_issue(issue, inactivity_days: int, notify_days: int):
    """
    Añade un comentario de aviso al issue y le pone la label 'stale'.
    Si ya tiene el comentario de aviso y han pasado notify_days más, lo cierra.
    """
    # Ver si ya hay un comentario de aviso
    notes = issue.notes.list(all=True)
    aviso_existente = next((n for n in notes if STALE_COMMENT_MARKER in n.body), None)

    if aviso_existente:
        # Calcular tiempo desde el aviso
        aviso_dt = datetime.fromisoformat(aviso_existente.created_at.replace("Z", "+00:00"))
        dias_desde_aviso = (datetime.now(timezone.utc) - aviso_dt).days

        if dias_desde_aviso >= notify_days:
            # Cerrar el issue
            issue.state_event = "close"
            issue.save()
            issue.notes.create({"body": f"{STALE_COMMENT_MARKER}\n🔒 Issue cerrado automáticamente por inactividad ({inactivity_days + dias_desde_aviso} días). Reabrir si sigue siendo relevante."})
            logger.info(f"  Issue #{issue.iid} CERRADO — {inactivity_days + dias_desde_aviso} días de inactividad")
            return "closed"
        else:
            logger.info(f"  Issue #{issue.iid} ya tiene aviso desde hace {dias_desde_aviso}d — esperando {notify_days - dias_desde_aviso}d más")
            return "warned_already"
    else:
        # Primer aviso: añadir label stale + comentario
        labels_actuales = issue.labels or []
        if STALE_LABEL not in labels_actuales:
            issue.labels = labels_actuales + [STALE_LABEL]
            issue.save()

        issue.notes.create({"body": (
            f"{STALE_COMMENT_MARKER}\n"
            f"⚠️ **Issue marcado como stale** — sin actividad por {inactivity_days} días.\n\n"
            f"Si este issue sigue siendo relevante, añade un comentario o actualiza su estado. "
            f"De lo contrario, será cerrado automáticamente en {notify_days} días."
        )})
        logger.info(f"  Issue #{issue.iid} AVISADO — {inactivity_days} días de inactividad")
        return "warned"
```

---

## 📊 Paso 4: Generador de Reportes

**`src/reporter.py`:**
```python
"""Genera reporte Markdown semanal de salud del proyecto."""

from datetime import datetime, timezone, timedelta


def generar_reporte(proyecto, mrs_abiertos, pipelines_fallidos, issues_stats) -> str:
    now = datetime.now(timezone.utc)
    semana_anterior = now - timedelta(days=7)

    lineas = [
        f"# 📊 Reporte Semanal — {proyecto.name}",
        f"**Generado:** {now.strftime('%Y-%m-%d %H:%M')} UTC",
        f"**Período:** {semana_anterior.strftime('%Y-%m-%d')} → {now.strftime('%Y-%m-%d')}",
        "",
        "---",
        "",
        "## Merge Requests Lentos",
    ]

    mrs_lentos = [mr for mr in mrs_abiertos if mr["dias_abierto"] >= 5]
    if mrs_lentos:
        lineas.append(f"**{len(mrs_lentos)} MRs llevan más de 5 días sin merge:**")
        lineas.append("")
        for mr in sorted(mrs_lentos, key=lambda x: x["dias_abierto"], reverse=True):
            icono = "🔴" if mr["dias_abierto"] >= 14 else "🟡"
            lineas.append(f"- {icono} !{mr['iid']} **{mr['titulo']}** — {mr['dias_abierto']} días — @{mr['autor']}")
    else:
        lineas.append("✅ Ningún MR abierto por más de 5 días.")

    lineas += [
        "",
        "## Pipelines Fallidos (últimos 7 días)",
    ]

    if pipelines_fallidos:
        lineas.append(f"**{len(pipelines_fallidos)} pipelines fallidos:**")
        lineas.append("")
        for p in pipelines_fallidos:
            lineas.append(f"- ❌ #{p['id']} en `{p['ref']}` — {p['created_at'][:10]}")
    else:
        lineas.append("✅ Sin pipelines fallidos en la última semana.")

    lineas += [
        "",
        "## Issues",
        f"- **Abiertos:** {issues_stats['opened']}",
        f"- **Cerrados esta semana:** {issues_stats['closed_this_week']}",
        f"- **Creados esta semana:** {issues_stats['created_this_week']}",
        "",
    ]

    ratio = issues_stats.get("closed_this_week", 0) / max(issues_stats.get("created_this_week", 1), 1)
    if ratio >= 1:
        lineas.append("✅ Se cerró al menos 1 issue por cada issue creado.")
    else:
        lineas.append(f"⚠️ Ratio cierre/creación: {ratio:.1f} — deuda de issues creciendo.")

    return "\n".join(lineas)
```

---

## 📤 Paso 5: Notificador via Webhook

**`src/notifier.py`:**
```python
"""Envía notificaciones a Slack/Discord via webhook."""

import logging, os, requests

logger = logging.getLogger(__name__)


def send_to_slack(reporte_markdown: str, titulo: str = "Reporte GitLab") -> bool:
    """Envía el reporte a Slack como mensaje de bloque."""
    webhook_url = os.environ.get("SLACK_WEBHOOK_URL", "")
    if not webhook_url:
        logger.info("SLACK_WEBHOOK_URL no configurado — reporte solo en log")
        return False

    # Slack Incoming Webhook acepta texto plano o bloques
    payload = {
        "text": titulo,
        "blocks": [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": titulo}
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    # Slack usa mrkdwn (variante de Markdown) — convertir backticks y headers
                    "text": reporte_markdown[:2900]   # límite de Slack
                }
            }
        ]
    }

    try:
        resp = requests.post(webhook_url, json=payload, timeout=10)
        resp.raise_for_status()
        logger.info(f"Reporte enviado a Slack: HTTP {resp.status_code}")
        return True
    except requests.RequestException as e:
        logger.error(f"Error enviando a Slack: {e}")
        return False
```

---

## 🤖 Paso 6: Entrypoint del Bot

**`bot.py`:**
```python
#!/usr/bin/env python3
"""
Bot de automatización DevOps para GitLab.
Uso: python3 bot.py [--dry-run] [--task stale|report|all]
"""

import argparse, logging, os, sys
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s"
)
logger = logging.getLogger("gitlab-bot")

from src.client import get_client
from src.stale_issues import find_stale_issues, warn_stale_issue
from src.reporter import generar_reporte
from src.notifier import send_to_slack


def run_stale_task(proyecto, dry_run: bool):
    stale_days = int(os.environ.get("STALE_DAYS", 30))
    notify_days = int(os.environ.get("NOTIFY_DAYS", 7))

    logger.info(f"[STALE] Buscando issues sin actividad en {stale_days}+ días")
    stale = find_stale_issues(proyecto, stale_days)

    if not stale:
        logger.info("[STALE] No hay issues stale")
        return

    resultados = {"warned": 0, "closed": 0, "warned_already": 0}
    for item in stale:
        issue = item["issue"]
        if dry_run:
            logger.info(f"  [DRY-RUN] Issue #{issue.iid}: {item['inactivity_days']}d inactivo — se avisaría")
        else:
            resultado = warn_stale_issue(issue, item["inactivity_days"], notify_days)
            resultados[resultado] = resultados.get(resultado, 0) + 1

    if not dry_run:
        logger.info(f"[STALE] Avisados: {resultados['warned']} | Cerrados: {resultados['closed']} | Ya avisados: {resultados['warned_already']}")


def run_report_task(proyecto, dry_run: bool):
    logger.info("[REPORT] Generando reporte semanal")

    now = datetime.now(timezone.utc)
    semana_anterior = now - timedelta(days=7)

    # Recopilar datos
    mrs = proyecto.mergerequests.list(state="opened", all=True)
    mrs_data = []
    for mr in mrs:
        dias = (now - datetime.fromisoformat(mr.created_at.replace("Z", "+00:00"))).days
        mrs_data.append({"iid": mr.iid, "titulo": mr.title[:50], "autor": mr.author["username"], "dias_abierto": dias})

    pipelines_fallidos = []
    for p in proyecto.pipelines.list(status="failed", per_page=50):
        created = datetime.fromisoformat(p.created_at.replace("Z", "+00:00"))
        if created >= semana_anterior:
            pipelines_fallidos.append({"id": p.id, "ref": p.ref, "created_at": p.created_at})

    issues_opened = proyecto.issues.list(state="opened", all=True)
    issues_this_week = proyecto.issues.list(
        created_after=semana_anterior.isoformat(),
        all=True
    )
    issues_closed_week = proyecto.issues.list(
        state="closed",
        updated_after=semana_anterior.isoformat(),
        all=True
    )

    issues_stats = {
        "opened": len(issues_opened),
        "created_this_week": len(issues_this_week),
        "closed_this_week": len(issues_closed_week),
    }

    reporte = generar_reporte(proyecto, mrs_data, pipelines_fallidos, issues_stats)

    print("\n" + "="*60)
    print(reporte)
    print("="*60 + "\n")

    if not dry_run:
        send_to_slack(reporte, f"Reporte Semanal — {proyecto.name}")


def main():
    parser = argparse.ArgumentParser(description="Bot de automatización GitLab")
    parser.add_argument("--dry-run", action="store_true", help="Mostrar acciones sin ejecutarlas")
    parser.add_argument("--task", choices=["stale", "report", "all"], default="all")
    args = parser.parse_args()

    if args.dry_run:
        logger.info("🔍 DRY-RUN activado — no se modificará nada")

    gl = get_client()
    project_id = os.environ.get("GITLAB_PROJECT_ID", "1")
    proyecto = gl.projects.get(project_id)
    logger.info(f"Proyecto: {proyecto.path_with_namespace}")

    if args.task in ("stale", "all"):
        run_stale_task(proyecto, args.dry_run)

    if args.task in ("report", "all"):
        run_report_task(proyecto, args.dry_run)

    logger.info("✅ Bot completado")


if __name__ == "__main__":
    main()
```

---

## 🧪 Paso 7: Tests Básicos

**`tests/test_stale_issues.py`:**
```python
"""Tests del módulo stale_issues con datos mock."""

from unittest.mock import MagicMock, patch
from datetime import datetime, timezone, timedelta

from src.stale_issues import find_stale_issues, STALE_LABEL


def make_issue(iid, days_ago, labels=None):
    """Crea un mock de issue con updated_at configurado."""
    issue = MagicMock()
    issue.iid = iid
    issue.labels = labels or []
    dt = datetime.now(timezone.utc) - timedelta(days=days_ago)
    issue.updated_at = dt.isoformat().replace("+00:00", "Z")
    issue.notes.list.return_value = []
    return issue


def test_detecta_issue_stale():
    """Issues con más de STALE_DAYS días sin actividad deben aparecer."""
    proyecto = MagicMock()
    proyecto.issues.list.return_value = [
        make_issue(1, days_ago=35),   # stale
        make_issue(2, days_ago=10),   # no stale
        make_issue(3, days_ago=31),   # stale
    ]

    stale = find_stale_issues(proyecto, stale_days=30)
    stale_iids = [s["issue"].iid for s in stale]

    assert 1 in stale_iids
    assert 3 in stale_iids
    assert 2 not in stale_iids


def test_excluye_issues_ya_marcados():
    """Issues con label 'stale' no deben volver a procesarse."""
    proyecto = MagicMock()
    proyecto.issues.list.return_value = [
        make_issue(1, days_ago=50, labels=[STALE_LABEL]),   # ya marcado — skip
        make_issue(2, days_ago=40),                          # procesar
    ]

    stale = find_stale_issues(proyecto, stale_days=30)
    assert len(stale) == 1
    assert stale[0]["issue"].iid == 2
```

```bash
pip install pytest
pytest tests/ -v
```

---

## 🚀 Paso 8: Ejecución

```bash
# Instalar dependencias
pip install -r requirements.txt

# Ver qué haría (sin ejecutar nada)
python3 bot.py --dry-run --task all

# Solo la tarea stale
python3 bot.py --task stale

# Reporte completo + notificación Slack
python3 bot.py --task report

# Todo
python3 bot.py
```

---

## 📦 Entregables

- [ ] Módulo `src/stale_issues.py` funcional — detecta y avisa issues inactivos
- [ ] Módulo `src/reporter.py` — genera reporte Markdown con MRs, pipelines e issues
- [ ] Módulo `src/notifier.py` — envía a Slack (o loguea si no hay webhook configurado)
- [ ] `bot.py` con argumentos `--dry-run` y `--task`
- [ ] `tests/test_stale_issues.py` — al menos 2 tests pasan con `pytest -v`
- [ ] Logs informativos en cada tarea (nivel INFO con timestamps)
- [ ] `.env.example` con todas las variables documentadas
- [ ] `README.md` propio del bot con instrucciones de instalación y uso (en el directorio del bot)

---

⬅️ **Prácticas:** [2-practicas/README.md](../2-practicas/README.md)
➡️ **Glosario:** [5-glosario/README.md](../5-glosario/README.md)
