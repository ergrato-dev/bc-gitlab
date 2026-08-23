#!/usr/bin/env python3
# ============================================
# Proyecto Semana 10 — Auditoria de Seguridad
# ============================================
# pip install python-gitlab python-dotenv
# Uso: python audit.py

import os
import sys
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv
import gitlab
import gitlab.exceptions

load_dotenv()

GITLAB_URL = os.environ["GITLAB_URL"]
GITLAB_TOKEN = os.environ["GITLAB_TOKEN"]

def connect():
    gl = gitlab.Gitlab(GITLAB_URL, private_token=GITLAB_TOKEN)
    gl.auth()
    return gl

def check_mfa(gl):
    """Verificar usuarios sin MFA"""
    print("=== Usuarios sin MFA ===")
    users = gl.users.list(per_page=100)
    for user in users:
        if not getattr(user, "two_factor_enabled", True):
            print(f"  ✗ {user.username} ({user.email}) — MFA deshabilitado")
    print("")

def check_vulnerabilities(gl):
    """Vulnerabilidades abiertas"""
    print("=== Vulnerabilidades por Proyecto ===")
    projects = gl.projects.list(owned=True, per_page=50)
    for project in projects:
        try:
            vulns = project.vulnerabilities.list(per_page=20, state="detected")
            if vulns:
                by_severity = {}
                for v in vulns:
                    sev = getattr(v, "severity", "unknown")
                    by_severity[sev] = by_severity.get(sev, 0) + 1
                print(f"  {project.name}: {len(vulns)} vulns {dict(by_severity)}")
        except gitlab.exceptions.GitlabError:
            pass
    print("")

def check_tokens(gl):
    """Tokens proximos a expirar"""
    print("=== Tokens Proximos a Expirar (< 30 dias) ===")
    try:
        tokens = gl.personal_access_tokens.list(per_page=100)
        now = datetime.now(timezone.utc)
        for token in tokens:
            if token.expires_at:
                expires = datetime.fromisoformat(token.expires_at.replace("Z", "+00:00"))
                days_left = (expires - now).days
                if 0 <= days_left <= 30:
                    print(f"  Token '{token.name}' expira en {days_left} dias")
    except:
        print("  (Requiere permisos de administrador)")
    print("")

def check_protected_branches(gl):
    """Proyectos sin proteccion de ramas"""
    print("=== Proyectos sin 'main' protegido ===")
    projects = gl.projects.list(owned=True, per_page=50)
    for project in projects:
        try:
            protected = project.protectedbranches.list()
            protected_names = [b.name for b in protected]
            if "main" not in protected_names and "master" not in protected_names:
                print(f"  ✗ {project.name} — rama principal sin proteger")
        except:
            pass
    print("")

def main():
    try:
        gl = connect()
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

    print(f"=== Reporte de Auditoria ===")
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    print(f"Instancia: {GITLAB_URL}")
    print("")

    check_mfa(gl)
    check_vulnerabilities(gl)
    check_tokens(gl)
    check_protected_branches(gl)

    print("=== Auditoria completada ===")

if __name__ == "__main__":
    main()
