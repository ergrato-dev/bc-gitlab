#!/usr/bin/env python3
# ============================================
# Proyecto Semana 09 — Bot DevOps
# ============================================
# Bot que automatiza tareas operativas en GitLab.
# Uso: python bot.py --report --cleanup-stale

import os
import sys
import argparse
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv
import gitlab
import gitlab.exceptions

load_dotenv()

# ── Configuracion ──
GITLAB_URL = os.environ["GITLAB_URL"]
GITLAB_TOKEN = os.environ["GITLAB_TOKEN"]

def connect():
    gl = gitlab.Gitlab(GITLAB_URL, private_token=GITLAB_TOKEN)
    gl.auth()
    return gl

def cleanup_stale_issues(gl):
    """Cerrar issues inactivos > 30 dias sin actividad"""
    print("=== Limpieza de Issues Inactivos ===")
    now = datetime.now(timezone.utc)
    projects = gl.projects.list(owned=True, per_page=50)

    for project in projects:
        try:
            issues = project.issues.list(state="opened", per_page=50)
            for issue in issues:
                updated = datetime.fromisoformat(issue.updated_at.replace("Z", "+00:00"))
                days_inactive = (now - updated).days
                if days_inactive > 30:
                    print(f"  #{issue.iid} {issue.title} — {days_inactive}d inactivo → cerrando")
                    issue.notes.create({"body": f"🔒 Cerrado automaticamente tras {days_inactive} dias sin actividad."})
                    issue.state_event = "close"
                    issue.save()
        except gitlab.exceptions.GitlabError as e:
            print(f"  Error en {project.name}: {e}")

def generate_report(gl):
    """Generar reporte de actividad semanal"""
    print("=== Reporte Semanal ===")
    now = datetime.now(timezone.utc)
    week_ago = now - timedelta(days=7)

    projects = gl.projects.list(owned=True, per_page=50)
    for project in projects:
        try:
            # MRs abiertos
            mrs = project.mergerequests.list(state="opened", per_page=20)
            old_mrs = [
                mr for mr in mrs
                if (now - datetime.fromisoformat(mr.created_at.replace("Z", "+00:00"))).days > 5
            ]
            if old_mrs:
                print(f"\n  {project.name} — {len(old_mrs)} MRs abiertos > 5 dias:")
                for mr in old_mrs:
                    days = (now - datetime.fromisoformat(mr.created_at.replace("Z", "+00:00"))).days
                    print(f"    !{mr.iid} {mr.title} ({days}d)")

            # Pipelines fallidas esta semana
            pipelines = project.pipelines.list(
                per_page=20,
                status="failed",
                updated_after=week_ago.isoformat()
            )
            if pipelines:
                print(f"  {project.name} — {len(pipelines)} pipelines fallidas esta semana")

        except gitlab.exceptions.GitlabError:
            pass

def main():
    parser = argparse.ArgumentParser(description="Bot DevOps — Bootcamp GitLab CE")
    parser.add_argument("--cleanup-stale", action="store_true", help="Cerrar issues inactivos")
    parser.add_argument("--report", action="store_true", help="Generar reporte semanal")
    args = parser.parse_args()

    try:
        gl = connect()
        print(f"Bot DevOps conectado a {GITLAB_URL}")
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

    if args.cleanup_stale:
        cleanup_stale_issues(gl)

    if args.report:
        generate_report(gl)

    if not (args.cleanup_stale or args.report):
        parser.print_help()

if __name__ == "__main__":
    main()
