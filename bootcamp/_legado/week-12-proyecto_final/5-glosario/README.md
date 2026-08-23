# Glosario General — Bootcamp GitLab CE

Glosario completo con todos los términos cubiertos durante el bootcamp (Semanas 01-12).

## A
| Término | Definición | Semana |
|---------|-----------|--------|
| **API** | Interfaz de programación que permite interactuar con GitLab mediante peticiones HTTP | 09 |
| **Artifact** | Archivos generados por un job que se preservan para jobs posteriores o descarga | 06-07 |
| **Audit Event** | Registro de acciones realizadas en GitLab para propósitos de cumplimiento | 10 |

## B
| Término | Definición | Semana |
|---------|-----------|--------|
| **Backup** | Copia de seguridad de los datos de GitLab para recuperación ante desastres | 11 |
| **Branch** | Rama de desarrollo independiente del código principal | 04 |

## C
| Término | Definición | Semana |
|---------|-----------|--------|
| **CI/CD** | Continuous Integration / Continuous Delivery: práctica de integrar y desplegar código automáticamente | 06 |
| **CI_JOB_TOKEN** | Token efímero disponible dentro de un job de CI/CD para autenticarse contra la API | 09 |
| **Compliance Pipeline** | Pipeline definido a nivel de grupo que garantiza el cumplimiento de políticas | 10 |
| **Container Registry** | Registro integrado para almacenar imágenes Docker dentro de GitLab | 08 |
| **Container Scanning** | Análisis de seguridad de imágenes Docker para detectar vulnerabilidades | 10 |
| **CVE** | Common Vulnerabilities and Exposures: identificador estándar para vulnerabilidades | 10 |

## D
| Término | Definición | Semana |
|---------|-----------|--------|
| **DAST** | Dynamic Application Security Testing: análisis de seguridad en tiempo de ejecución | 10 |
| **Dependency Scanning** | Análisis de dependencias para identificar vulnerabilidades y licencias | 10 |
| **Developer** | Rol con permisos de escritura en el repositorio (nivel 30) | 10 |
| **Docker Compose** | Herramienta para definir y ejecutar aplicaciones multi-contenedor | 02 |
| **DR** | Disaster Recovery: estrategia para recuperar sistemas tras un desastre mayor | 11 |

## E
| Término | Definición | Semana |
|---------|-----------|--------|
| **Endpoint** | URL de la API que expone un recurso específico | 09 |
| **Environment** | Entorno de despliegue (staging, production) configurado en GitLab | 07 |
| **Executor** | Motor que ejecuta los jobs de CI/CD (Docker, Shell, Kubernetes) | 06 |
| **Exporter** | Componente que expone métricas en formato Prometheus | 11 |

## F-G
| Término | Definición | Semana |
|---------|-----------|--------|
| **Failover** | Cambio automático a un sistema de respaldo cuando el primario falla | 11 |
| **Fragment** | En GraphQL, conjunto reutilizable de campos entre queries | 09 |
| **Gitaly** | Servicio de GitLab que maneja operaciones de git (clone, push, pull) | 01-05 |
| **Gitaly Cluster** | Solución de HA para repositorios git con Praefect | 11 |
| **Grace Period** | Período de gracia para activar MFA antes de ser bloqueado | 10 |
| **Grafana** | Plataforma de visualización de métricas con dashboards y alertas | 11 |
| **GraphQL** | Lenguaje de query para APIs que permite al cliente especificar los datos necesarios | 09 |
| **Guest** | Rol mínimo en GitLab (nivel 10): acceso limitado a ver issues | 10 |

## H-I
| Término | Definición | Semana |
|---------|-----------|--------|
| **HA** | High Availability: capacidad de permanecer operativo ante fallos de componentes | 11 |
| **Healthcheck** | Verificación periódica de que un servicio está funcionando correctamente | 12 |
| **IP Restriction** | Límite de acceso a GitLab por rangos IP específicos | 10 |

## J-K-L
| Término | Definición | Semana |
|---------|-----------|--------|
| **Job** | Unidad de trabajo dentro de un pipeline que ejecuta comandos específicos | 06 |
| **Keepalived** | Herramienta para IP virtual compartida entre servidores para failover | 11 |
| **License Compliance** | Verificación de licencias de dependencias contra políticas corporativas | 10 |

## M
| Término | Definición | Semana |
|---------|-----------|--------|
| **Maintainer** | Rol de liderazgo técnico (nivel 40): gestiona CI/CD, miembros, protected branches | 10 |
| **Merge Request** | Solicitud para integrar cambios de una rama a otra con revisión de código | 04 |
| **MFA** | Multi-Factor Authentication: autenticación de dos o más factores | 10 |
| **Milestone** | Agrupación de issues y MRs que comparten un objetivo o fecha | 04 |
| **Mutation** | En GraphQL, operación que modifica datos (crear, actualizar, eliminar) | 09 |

## O-P
| Término | Definición | Semana |
|---------|-----------|--------|
| **Owner** | Propietario total del grupo/proyecto (nivel 50): control absoluto | 10 |
| **Package Registry** | Registro para almacenar paquetes (npm, Maven, PyPI, etc.) | 08 |
| **Paginación** | División de respuestas API en páginas con parámetros page/per_page | 09 |
| **PAT** | Personal Access Token: token de autenticación personal para API | 09 |
| **Patroni** | Herramienta de HA para PostgreSQL con failover automático | 11 |
| **PgBouncer** | Connection pooler para PostgreSQL que reduce conexiones | 11 |
| **Pipeline** | Conjunto de stages y jobs que definen el flujo CI/CD | 06 |
| **PITR** | Point-In-Time Recovery: restauración de BD a un momento exacto | 11 |
| **Praefect** | Proxy de Gitaly que maneja replicación entre nodos | 11 |
| **Prometheus** | Sistema de monitoreo que recolecta métricas en series temporales | 11 |
| **Protected Branch** | Rama con restricciones de push/merge según roles | 10 |

## Q-R
| Término | Definición | Semana |
|---------|-----------|--------|
| **Query** | En GraphQL, operación de solo lectura. En general, consulta a una API | 09 |
| **Rate Limit** | Límite de peticiones por unidad de tiempo impuesto por la API | 09 |
| **RBAC** | Role-Based Access Control: control de acceso basado en roles | 10 |
| **Repmgr** | Herramienta de replicación y failover para PostgreSQL | 11 |
| **Reporter** | Rol de solo lectura extendida (nivel 20): clonar, ver pipelines | 10 |
| **RPO** | Recovery Point Objective: máxima pérdida de datos aceptable | 11 |
| **RTO** | Recovery Time Objective: tiempo máximo para restaurar el servicio | 11 |
| **Runner** | Agente que ejecuta los jobs definidos en el pipeline CI/CD | 06 |

## S
| Término | Definición | Semana |
|---------|-----------|--------|
| **SAST** | Static Application Security Testing: análisis de seguridad del código fuente | 10 |
| **SBOM** | Software Bill of Materials: inventario de componentes y dependencias | 10 |
| **Scope** | Alcance de permisos de un token (api, read_api, read_repository, etc.) | 09 |
| **Secret Detection** | Detección de secretos hardcodeados en código fuente | 10 |
| **Sidekiq** | Sistema de procesamiento de trabajos asíncronos de GitLab | 01-03 |
| **SPDX** | Estándar para identificación consistente de licencias de software | 10 |
| **SPOF** | Single Point of Failure: componente único cuya falla detiene el servicio | 11 |
| **Stage** | Fase del pipeline que agrupa jobs (build, test, deploy, etc.) | 06 |

## T-V
| Término | Definición | Semana |
|---------|-----------|--------|
| **TOTP** | Time-based One-Time Password: algoritmo para códigos MFA temporales | 10 |
| **Trigger** | Mecanismo para iniciar pipelines desde otro pipeline o vía API | 07 |
| **Variable CI/CD** | Valor configurable usado en pipelines (protegida, enmascarada) | 06 |
| **VIP** | Virtual IP: dirección IP flotante compartida entre servidores | 11 |
| **Volumen** | Almacenamiento persistente en Docker para datos que sobreviven reinicios | 02 |

## W
| Término | Definición | Semana |
|---------|-----------|--------|
| **WAL** | Write-Ahead Log: registro de cambios PostgreSQL para replicación | 11 |
| **Webhook** | Callback HTTP que GitLab dispara ante eventos configurados | 09 |

---

*Bootcamp GitLab CE — Administración DevOps — v1.0*
