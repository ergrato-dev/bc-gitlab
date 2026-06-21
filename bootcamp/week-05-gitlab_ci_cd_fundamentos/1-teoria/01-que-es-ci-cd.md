# 01 — ¿Que es CI/CD?

## Definiciones

- **Continuous Integration (CI):** Practica de integrar cambios de codigo en un repositorio compartido varias veces al dia. Cada integracion dispara una construccion y pruebas automatizadas para detectar errores tempranamente.

- **Continuous Delivery (CD):** Extension de CI donde el codigo que pasa las pruebas se mantiene en un estado "entregable" en cualquier momento. El despliegue a produccion es un paso manual.

- **Continuous Deployment (CDep):** Cada cambio que pasa las pruebas se despliega automaticamente a produccion sin intervencion humana. Requiere un alto nivel de confianza en las pruebas automatizadas.

## Beneficios de CI/CD

1. **Deteccion temprana de errores:** Los problemas se identifican minutos despues del commit, no dias despues.
2. **Reduccion de integraciones dolorosas:** Evita el "merge hell" de ramas longevas.
3. **Calidad consistente:** Pruebas automatizadas en cada cambio garantizan estandares minimos.
4. **Velocidad de entrega:** Automatizacion elimina procesos manuales repetitivos.
5. **Trazabilidad:** Cada build se asocia a un commit especifico.

## Pipeline as Code

La configuracion del pipeline vive en el repositorio como codigo (`.gitlab-ci.yml`). Esto significa:
- Versionado junto al codigo fuente
- Revisable en merge requests
- Reproducible en diferentes proyectos
- Auditoria completa de cambios
