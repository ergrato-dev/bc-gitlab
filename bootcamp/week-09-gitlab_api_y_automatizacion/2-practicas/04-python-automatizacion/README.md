# Práctica 04 — Automatización con Python

**Duración estimada:** 45 minutos
**Dificultad:** ⭐⭐⭐⭐ (Alta)

## 🎯 Objetivo

Crear un script Python completo que automatice cuatro tareas operativas comunes en GitLab: detección de pipelines fallidos, creación masiva de issues, auditoría de miembros en CSV, y reporte de MRs por antigüedad. El script debe tener manejo robusto de errores y rate limiting.

---

## 📋 Prerrequisitos

```bash
pip install python-gitlab python-dotenv

# .env
cat > .env << 'EOF'
GITLAB_URL=http://localhost
GITLAB_TOKEN=glpat-xxxxxxxxxxxx
GITLAB_PROJECT_ID=42
EOF

# Verificar instalación
python3 -c "import gitlab; print(f'python-gitlab {gitlab.__version__}')"
```

---

## Tarea 1: Proyectos con Pipelines Fallidos

```python
#!/usr/bin/env python3
"""Tarea 1: Detectar proyectos con pipelines fallidos."""

import gitlab, os, sys
from dotenv import load_dotenv

load_dotenv()

def get_gitlab_client():
    # ¿QUÉ HACE?: Crea el cliente con retry automático en errores transitorios
    # ¿POR QUÉ?: retry_transient_errors=True reintenta 429 y 5xx automáticamente
    # ¿PARA QUÉ?: Scripts resilientes que no fallan por rate limit momentáneo
    return gitlab.Gitlab(
        url=os.environ["GITLAB_URL"],
        private_token=os.environ["GITLAB_TOKEN"],
        retry_transient_errors=True,
    )

def detectar_pipelines_fallidos():
    gl = get_gitlab_client()
    gl.auth()
    print(f"Autenticado como: {gl.users.get_current().username}")

    proyectos_con_fallos = []
    proyectos = gl.projects.list(owned=True, all=True)
    print(f"\nAnalizando {len(proyectos)} proyectos...")

    for proyecto in proyectos:
        try:
            pipelines_recientes = proyecto.pipelines.list(
                per_page=5,
                order_by="updated_at",
                sort="desc",
            )
            pipelines_fallidos = [p for p in pipelines_recientes if p.status == "failed"]
            if pipelines_fallidos:
                proyectos_con_fallos.append({
                    "proyecto": proyecto.path_with_namespace,
                    "url": proyecto.web_url,
                    "pipelines_fallidos": len(pipelines_fallidos),
                    "ultima_rama": pipelines_fallidos[0].ref if pipelines_fallidos else "-",
                    "ultimo_fallo": pipelines_fallidos[0].created_at[:10] if pipelines_fallidos else "-",
                })
        except gitlab.exceptions.GitlabGetError:
            # Proyecto sin CI configurado — skip
            pass

    if proyectos_con_fallos:
        print(f"\n❌ Proyectos con pipelines fallidos ({len(proyectos_con_fallos)}):")
        print(f"  {'Proyecto':<40} {'Fallos':<8} {'Rama':<20} {'Último fallo'}")
        print(f"  {'-'*40} {'-'*8} {'-'*20} {'-'*12}")
        for p in sorted(proyectos_con_fallos, key=lambda x: x['pipelines_fallidos'], reverse=True):
            print(f"  {p['proyecto']:<40} {p['pipelines_fallidos']:<8} {p['ultima_rama']:<20} {p['ultimo_fallo']}")
    else:
        print("\n✅ No hay proyectos con pipelines fallidos")

    return proyectos_con_fallos

if __name__ == "__main__":
    detectar_pipelines_fallidos()
```

```bash
python3 tarea1_pipelines.py
```

---

## Tarea 2: Creación Masiva de Issues

```python
#!/usr/bin/env python3
"""Tarea 2: Crear issues de mantenimiento en lote."""

import gitlab, os, time
from dotenv import load_dotenv

load_dotenv()

ISSUES_MANTENIMIENTO = [
    {
        "title": "Revisar y actualizar dependencias del proyecto",
        "description": "Ejecutar `npm audit` / `pip list --outdated` y actualizar las dependencias con CVEs conocidos.\n\n**Criterio de éxito:** 0 vulnerabilidades HIGH o CRITICAL.",
        "labels": ["mantenimiento", "seguridad"],
        "weight": 3,
    },
    {
        "title": "Limpiar branches mergeadas",
        "description": "Eliminar todas las branches que ya fueron mergeadas a `main` y tienen más de 30 días.\n\n```bash\ngit branch --merged main | grep -v main | xargs git branch -d\n```",
        "labels": ["mantenimiento", "git"],
        "weight": 1,
    },
    {
        "title": "Actualizar documentación del README",
        "description": "Revisar que el README refleje el estado actual del proyecto:\n- Instrucciones de instalación\n- Variables de entorno requeridas\n- Ejemplos de uso actualizados",
        "labels": ["mantenimiento", "documentación"],
        "weight": 2,
    },
    {
        "title": "Configurar retention policy del Container Registry",
        "description": "Activar la Tag Cleanup Policy para eliminar imágenes más viejas de 90 días, manteniendo `latest`, `main` y tags semánticos.",
        "labels": ["mantenimiento", "infraestructura"],
        "weight": 2,
    },
    {
        "title": "Revisar logs de errores del último mes",
        "description": "Revisar los logs de producción del último mes y crear issues específicos para los errores más frecuentes.",
        "labels": ["mantenimiento", "observabilidad"],
        "weight": 3,
    },
]

def crear_issues_lote(project_id: str):
    gl = gitlab.Gitlab(
        url=os.environ["GITLAB_URL"],
        private_token=os.environ["GITLAB_TOKEN"],
        retry_transient_errors=True,
    )
    gl.auth()
    proyecto = gl.projects.get(project_id)
    print(f"Creando {len(ISSUES_MANTENIMIENTO)} issues en '{proyecto.path_with_namespace}'...")

    # Crear o reusar milestone "Q3 Mantenimiento"
    milestones = proyecto.milestones.list(title="Q3 Mantenimiento")
    if milestones:
        milestone = milestones[0]
        print(f"  Milestone existente: '{milestone.title}' (ID: {milestone.id})")
    else:
        milestone = proyecto.milestones.create({
            "title": "Q3 Mantenimiento",
            "description": "Sprint de mantenimiento trimestral — automatizado via python-gitlab",
        })
        print(f"  Milestone creado: '{milestone.title}' (ID: {milestone.id})")

    # Crear issues con pequeño delay para evitar rate limit
    creados = []
    for i, issue_data in enumerate(ISSUES_MANTENIMIENTO, 1):
        try:
            issue = proyecto.issues.create({
                **issue_data,
                "labels": issue_data["labels"],
                "milestone_id": milestone.id,
            })
            print(f"  ✅ [{i}/{len(ISSUES_MANTENIMIENTO)}] #{issue.iid}: {issue.title}")
            creados.append(issue)
            time.sleep(0.5)   # 2 req/s para no saturar el rate limit
        except gitlab.exceptions.GitlabCreateError as e:
            print(f"  ❌ Error al crear issue {i}: {e.error_message}")

    print(f"\nIssues creados: {len(creados)}/{len(ISSUES_MANTENIMIENTO)}")
    return creados

if __name__ == "__main__":
    project_id = os.environ.get("GITLAB_PROJECT_ID", "1")
    crear_issues_lote(project_id)
```

```bash
python3 tarea2_issues_lote.py
```

---

## Tarea 3: Auditoría de Miembros en CSV

```python
#!/usr/bin/env python3
"""Tarea 3: Auditoría de miembros de grupos — salida CSV."""

import gitlab, os, csv, sys
from io import StringIO
from dotenv import load_dotenv

load_dotenv()

ACCESS_LEVEL_NAMES = {
    10: "Guest",
    20: "Reporter",
    30: "Developer",
    40: "Maintainer",
    50: "Owner",
}

def auditar_miembros():
    gl = gitlab.Gitlab(
        url=os.environ["GITLAB_URL"],
        private_token=os.environ["GITLAB_TOKEN"],
        retry_transient_errors=True,
    )
    gl.auth()

    # ¿QUÉ HACE?: Itera sobre grupos visibles y recopila todos los miembros
    # ¿POR QUÉ?: La auditoría de accesos es un requerimiento de seguridad
    # ¿PARA QUÉ?: Generar un CSV para revisar quién tiene acceso a qué y con qué nivel

    grupos = gl.groups.list(all_available=False, all=True)   # solo grupos donde soy miembro
    print(f"Grupos encontrados: {len(grupos)}", file=sys.stderr)

    output = StringIO()
    writer = csv.writer(output)
    writer.writerow(["grupo", "grupo_id", "usuario", "email", "nivel_acceso", "nivel_nombre", "expires_at"])

    total_rows = 0

    for grupo in grupos:
        try:
            miembros = grupo.members.list(all=True)
            print(f"  {grupo.full_path}: {len(miembros)} miembros", file=sys.stderr)
            for m in miembros:
                nivel = m.access_level
                writer.writerow([
                    grupo.full_path,
                    grupo.id,
                    m.username,
                    getattr(m, "email", ""),
                    nivel,
                    ACCESS_LEVEL_NAMES.get(nivel, f"Level {nivel}"),
                    getattr(m, "expires_at", "") or "nunca",
                ])
                total_rows += 1
        except gitlab.exceptions.GitlabGetError as e:
            print(f"  ⚠️ No se pudieron listar miembros de {grupo.full_path}: {e}", file=sys.stderr)

    print(output.getvalue())   # CSV al stdout
    print(f"\nTotal filas en CSV: {total_rows}", file=sys.stderr)

if __name__ == "__main__":
    auditar_miembros()
```

```bash
# Guardar el CSV en un archivo
python3 tarea3_auditoria_miembros.py > auditoria_miembros.csv 2>auditoria.log

# Verificar el CSV
cat auditoria_miembros.csv
```

---

## Tarea 4: Reporte de MRs por Antigüedad

```python
#!/usr/bin/env python3
"""Tarea 4: Reporte de MRs abiertos ordenados por antigüedad."""

import gitlab, os
from dotenv import load_dotenv
from datetime import datetime, timezone

load_dotenv()

def calcular_dias(fecha_iso: str) -> int:
    dt = datetime.fromisoformat(fecha_iso.replace("Z", "+00:00"))
    return (datetime.now(timezone.utc) - dt).days

def reporte_mrs_antiguedad():
    gl = gitlab.Gitlab(
        url=os.environ["GITLAB_URL"],
        private_token=os.environ["GITLAB_TOKEN"],
        retry_transient_errors=True,
    )
    gl.auth()

    proyectos = gl.projects.list(owned=True, all=True)

    # ¿QUÉ HACE?: Recopila todos los MRs abiertos de todos los proyectos
    # ¿POR QUÉ?: Un MR que lleva semanas abierto está bloqueado o fue olvidado
    # ¿PARA QUÉ?: Identificar MRs que necesitan atención o cierre

    todos_los_mrs = []

    for proyecto in proyectos:
        try:
            mrs = proyecto.mergerequests.list(state="opened", all=True)
            for mr in mrs:
                dias = calcular_dias(mr.created_at)
                todos_los_mrs.append({
                    "proyecto": proyecto.path_with_namespace,
                    "iid": mr.iid,
                    "titulo": mr.title[:50],
                    "autor": mr.author["username"],
                    "dias_abierto": dias,
                    "source_branch": mr.source_branch,
                    "url": mr.web_url,
                })
        except Exception:
            pass

    if not todos_los_mrs:
        print("No hay MRs abiertos en ningún proyecto.")
        return

    # Ordenar por antigüedad descendente
    todos_los_mrs.sort(key=lambda x: x["dias_abierto"], reverse=True)

    print(f"\n📊 REPORTE DE MERGE REQUESTS ABIERTOS ({len(todos_los_mrs)} total)")
    print(f"\n  {'Días':>5}  {'Proyecto':<35} {'!MR':<6} {'Autor':<15} Título")
    print(f"  {'─'*5}  {'─'*35} {'─'*6} {'─'*15} {'─'*40}")

    alertas = {"critico": 0, "advertencia": 0, "ok": 0}

    for mr in todos_los_mrs:
        dias = mr["dias_abierto"]
        if dias >= 14:
            icono = "🔴"
            alertas["critico"] += 1
        elif dias >= 5:
            icono = "🟡"
            alertas["advertencia"] += 1
        else:
            icono = "🟢"
            alertas["ok"] += 1

        print(f"  {icono} {dias:>3}d  {mr['proyecto']:<35} !{mr['iid']:<5} {mr['autor']:<15} {mr['titulo']}")

    print(f"\n  🔴 Críticos (≥14 días): {alertas['critico']}")
    print(f"  🟡 Advertencia (5-13 días): {alertas['advertencia']}")
    print(f"  🟢 Recientes (<5 días): {alertas['ok']}")

if __name__ == "__main__":
    reporte_mrs_antiguedad()
```

```bash
python3 tarea4_mrs_antiguedad.py
```

---

## Script Integrado con Manejo de Errores

```python
#!/usr/bin/env python3
"""Script de automatización completo — Semana 09."""

import gitlab, os, sys, time, random
from dotenv import load_dotenv

load_dotenv()


def get_gl():
    try:
        gl = gitlab.Gitlab(
            url=os.environ["GITLAB_URL"],
            private_token=os.environ["GITLAB_TOKEN"],
            retry_transient_errors=True,
            timeout=30,
        )
        gl.auth()
        return gl
    except gitlab.exceptions.GitlabAuthenticationError:
        print("❌ Token inválido o expirado", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ No se puede conectar a GitLab: {e}", file=sys.stderr)
        sys.exit(1)


def run_with_retry(fn, description, max_retries=3):
    for attempt in range(max_retries):
        try:
            return fn()
        except gitlab.exceptions.GitlabHttpError as e:
            if e.response_code == 429:
                wait = (2 ** attempt) + random.uniform(0, 1)
                print(f"  ⚠️ Rate limit en '{description}' — esperando {wait:.1f}s")
                time.sleep(wait)
            else:
                print(f"  ❌ Error HTTP {e.response_code} en '{description}': {e.error_message}")
                return None
        except gitlab.exceptions.GitlabGetError as e:
            print(f"  ⚠️ Recurso no encontrado en '{description}': {e.error_message}")
            return None
    print(f"  ❌ Agotados {max_retries} reintentos en '{description}'")
    return None


if __name__ == "__main__":
    print("=== Script de automatización GitLab — Semana 09 ===")
    gl = get_gl()
    current_user = gl.users.get_current()
    print(f"Autenticado como: {current_user.username} (ID: {current_user.id})")

    project_id = os.environ.get("GITLAB_PROJECT_ID", "1")

    # Ejecutar tareas
    print("\n[1/4] Detectando proyectos con pipelines fallidos...")
    from tarea1_pipelines import detectar_pipelines_fallidos
    fallos = detectar_pipelines_fallidos()

    print("\n[2/4] Creando issues de mantenimiento...")
    from tarea2_issues_lote import crear_issues_lote
    issues = crear_issues_lote(project_id)

    print("\n[3/4] Generando auditoría de miembros...")
    from tarea3_auditoria_miembros import auditar_miembros
    auditar_miembros()

    print("\n[4/4] Generando reporte de MRs...")
    from tarea4_mrs_antiguedad import reporte_mrs_antiguedad
    reporte_mrs_antiguedad()

    print("\n✅ Automatización completada")
```

---

## ✅ Checklist de verificación

- [ ] `pip install python-gitlab python-dotenv` instalado
- [ ] `.env` configurado con `GITLAB_URL`, `GITLAB_TOKEN`, `GITLAB_PROJECT_ID`
- [ ] Tarea 1: script detecta proyectos con fallos o imprime "no hay fallos"
- [ ] Tarea 2: 5 issues de mantenimiento creados con milestone visible en la UI
- [ ] Tarea 3: `auditoria_miembros.csv` generado con filas de usuarios/grupos
- [ ] Tarea 4: tabla de MRs ordenada por antigüedad con íconos de alerta
- [ ] Manejo de errores: HTTP 401 manejado con mensaje claro + exit 1
- [ ] Rate limit: función `run_with_retry` implementada con backoff exponencial

---

## 🏆 Reto adicional

Convertir el script en una CLI con argumentos usando `argparse`:

```bash
python3 automate.py --task pipelines
python3 automate.py --task issues --project-id 42
python3 automate.py --task audit --output auditoria.csv
python3 automate.py --task mrs --min-days 7
```

---

⬅️ **Práctica anterior:** [03 — Webhooks](../03-webhooks-integracion/README.md)
➡️ **Proyecto:** [Bot de Automatización DevOps](../../3-proyecto/README.md)
