# ============================================
# Documentos — Plantillas para el Proyecto Final
# ============================================

echo "=== Documentacion Proyecto Final ==="
echo ""

# ── docs/arquitectura.md ──
cat > docs/arquitectura.md << 'EOF'
# Arquitectura de la Plataforma DevOps

## Diagrama
[Inserta tu diagrama de arquitectura aqui]

## Componentes
| Componente | Tecnologia | Proposito |
|-----------|-----------|----------|
| GitLab CE | Docker | Repositorio, CI/CD, Issues, Registry |
| GitLab Runner | Docker | Ejecutar jobs de CI/CD |
| Prometheus | Docker | Recoleccion de metricas |
| Grafana | Docker | Visualizacion y alertas |

## Flujo CI/CD
1. Developer hace push a rama
2. Pipeline: build → test → security → package → deploy
3. main → deploy automatico a staging
4. tag v* → deploy manual a production

## Decisiones Tecnicas
- Docker Compose: simplicidad, portabilidad
- GitLab CE auto-administrado: control total
- Certificados auto-firmados: entorno laboratorio
EOF

# ── docs/manual-operaciones.md ──
cat > docs/manual-operaciones.md << 'EOF'
# Manual de Operaciones

## Requisitos
- Docker 27+, Docker Compose 2.32+
- 8 GB RAM, 20 GB disco

## Instalacion
```bash
git clone <repo-url>
cp .env.example .env
docker compose up -d
docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

## Backup
```bash
docker compose exec gitlab gitlab-backup create STRATEGY=copy
```

## Restore
```bash
docker compose exec gitlab gitlab-ctl stop puma sidekiq
docker compose exec gitlab gitlab-backup restore BACKUP=<timestamp>
docker compose exec gitlab gitlab-ctl reconfigure restart
```

## Actualizacion
```bash
# Cambiar GITLAB_VERSION en .env
docker compose pull gitlab
docker compose up -d
```
EOF

# ── docs/disaster-recovery.md ──
cat > docs/disaster-recovery.md << 'EOF'
# Plan de Disaster Recovery

| Escenario | RTO | RPO | Procedimiento |
|-----------|-----|-----|--------------|
| Caida de servicio | 5 min | 0 | Reiniciar contenedor |
| Corrupcion DB | 30 min | 24h | Restore desde backup |
| Perdida total | 2h | 24h | Recrear infra + restore |

## Contactos
- DevOps Lead: [nombre] - [telefono]
- Backup: [nombre] - [telefono]
EOF

echo "Documentos generados en docs/"
echo ""
echo "=== Checklist Final ==="
cat << 'CHECKLIST'
[ ] docker compose up -d levanta todo
[ ] Pipeline 6 stages ejecutandose
[ ] SAST + Secret Detection + Container Scanning
[ ] RBAC con 3+ roles documentados
[ ] MFA habilitado
[ ] Grafana dashboard con metricas
[ ] Backup script funcional
[ ] Restore probado
[ ] docs/ (arquitectura, ops, DR) completos
[ ] README.md con instalacion rapida
[ ] Defensa ensayada (15 min)
CHECKLIST
