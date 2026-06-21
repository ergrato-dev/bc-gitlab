# 05 — Artifacts y Cache

## Artifacts

Los artifacts son archivos o directorios generados por un job que se pasan a jobs posteriores. Se almacenan en GitLab y pueden descargarse desde la UI o API.

```yaml
build:
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
      - coverage/
    expire_in: 7 days

deploy:
  stage: deploy
  needs:
    - build
  script:
    - rsync -av dist/ server:/var/www/
```

### Opciones importantes
- `paths`: Archivos/directorios a incluir
- `exclude`: Archivos a excluir de los paths
- `expire_in`: Tiempo de retencion (por defecto 30 dias en CE)
- `when`: `on_success`, `on_failure`, `always`
- `reports`: Artifacts especiales (JUnit, SAST, etc.)

## Cache

El cache almacena dependencias entre ejecuciones del mismo job para acelerar pipelines:

```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .m2/repository/
```

### Cache vs Artifacts

| Caracteristica | Artifacts | Cache |
|---------------|-----------|-------|
| Proposito | Pasar resultados entre stages | Acelerar builds |
| Almacenamiento | Por pipeline | Compartido entre pipelines |
| Gestion | Explicitamente definidos | Automatico cuando existe |
| Acceso | UI y API | Solo dentro del pipeline |
| Retencion | Configurable por tiempo | No garantizada |

El cache es un "best effort" — GitLab no garantiza su disponibilidad. Para datos criticos entre stages, usar artifacts.
