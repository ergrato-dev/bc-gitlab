#!/usr/bin/env python3
# ============================================
# Practica 04 — Automatizacion con python-gitlab
# ============================================
# pip install python-gitlab python-dotenv
# Crea .env con GITLAB_URL y GITLAB_TOKEN
# ============================================

import os
import sys
from datetime import datetime, timezone
from dotenv import load_dotenv
import gitlab
import gitlab.exceptions

load_dotenv()

GITLAB_URL = os.environ.get("GITLAB_URL", "http://localhost")
GITLAB_TOKEN = os.environ.get("GITLAB_TOKEN", "")

def connect():
    """Conectar a GitLab y autenticar"""
    gl = gitlab.Gitlab(GITLAB_URL, private_token=GITLAB_TOKEN)
    gl.auth()
    return gl

def list_failed_pipelines(gl):
    """Listar proyectos con pipelines fallidas"""
    print("\n=== Pipelines Fallidas ===")
    projects = gl.projects.list(owned=True, per_page=50)
    for project in projects:
        try:
            pipelines = project.pipelines.list(per_page=3, status="failed")
            if pipelines:
                print(f"  {project.name}: {len(pipelines)} failed")
                for p in pipelines:
                    print(f"    #{p.id} - {p.ref} ({p.created_at})")
        except gitlab.exceptions.GitlabError as e:
            print(f"  Error en {project.name}: {e}")

def create_issues_batch(gl, project_id):
    """Crear issues de mantenimiento en lote"""
    print("\n=== Crear Issues en Lote ===")
    project = gl.projects.get(project_id)
    issues_data = [
        {"title": "Auditar dependencias", "description": "Revisar y actualizar dependencias.", "labels": ["maintenance", "backend"]},
        {"title": "Actualizar documentacion", "description": "Agregar docs de nuevos endpoints.", "labels": ["documentation"]},
        {"title": "Limpiar artifacts viejos", "description": "Purgar artifacts > 30 dias.", "labels": ["maintenance", "devops"]},
    ]
    for data in issues_data:
        issue = project.issues.create(data)
        print(f"  Creando #{issue.iid}: {issue.title}")

def audit_members(gl):
    """Auditar miembros de grupos"""
    print("\n=== Auditoria de Miembros ===")
    groups = gl.groups.list(all=True)
    for group in groups:
        members = group.members.list()
        for member in members:
            print(f"  {group.full_path} | {member.username} | access_level={member.access_level}")

def report_open_mrs(gl):
    """Reporte de MRs abiertos por antiguedad"""
    print("\n=== MRs Abiertos (> 5 dias) ===")
    projects = gl.projects.list(owned=True, per_page=50)
    now = datetime.now(timezone.utc)
    for project in projects:
        try:
            mrs = project.mergerequests.list(state="opened", per_page=20)
            for mr in mrs:
                created = datetime.fromisoformat(mr.created_at.replace("Z", "+00:00"))
                days_open = (now - created).days
                if days_open > 5:
                    print(f"  !{mr.iid} en {project.name}: {mr.title} ({days_open} dias)")
        except gitlab.exceptions.GitlabError:
            pass

def main():
    try:
        gl = connect()
        print(f"Conectado a {GITLAB_URL} como usuario autenticado")
    except gitlab.exceptions.GitlabAuthenticationError:
        print("ERROR: Token invalido o expirado")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

    list_failed_pipelines(gl)
    # create_issues_batch(gl, PROJECT_ID)  # Descomenta con tu project ID
    audit_members(gl)
    report_open_mrs(gl)

if __name__ == "__main__":
    main()
