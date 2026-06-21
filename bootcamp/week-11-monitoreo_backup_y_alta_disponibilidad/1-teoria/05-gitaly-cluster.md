# 05 — Gitaly Cluster: HA para Repositorios Git

Gitaly es el servicio de GitLab que maneja todas las operaciones de git (clone, push, pull, etc.). Gitaly Cluster proporciona alta disponibilidad y balanceo de carga para repositorios git usando Praefect como proxy.

## Arquitectura Gitaly Cluster

```
Clientes (Rails/Shell) → Praefect → Gitaly Nodes (3+)
                            ↓
                      PostgreSQL (metadata)
```

## Componentes

**Praefect**: Proxy inteligente que enruta peticiones a los Gitaly nodes correctos. Mantiene un registro de réplicas y maneja la replicación entre nodos. Se despliega como servicio separado.

**Gitaly Nodes**: Mínimo 3 nodos (número impar para quorum). Cada nodo almacena réplicas de los repositorios. La replicación es asíncrona por defecto (eventual consistency).

**PostgreSQL para metadata**: Praefect usa PostgreSQL para almacenar metadata de réplicas (qué nodos contienen qué repositorios, estado de replicación, etc.). Esta instancia PostgreSQL debe ser HA también.

## Configuración de Praefect en gitlab.rb

```ruby
# En cada nodo Gitaly
gitaly['configuration'] = {
  storage: [
    { name: 'default', path: '/var/opt/gitlab/git-data' }
  ]
}

# En el nodo Praefect
praefect['enable'] = true
praefect['virtual_storages'] = {
  'default' => {
    'nodes' => {
      'gitaly-1' => { 'address' => 'tcp://192.168.1.21:8075' },
      'gitaly-2' => { 'address' => 'tcp://192.168.1.22:8075' },
      'gitaly-3' => { 'address' => 'tcp://192.168.1.23:8075' }
    }
  }
}
```

## Replication Factor

Define cuántas copias de cada repositorio se mantienen:
- `replication_factor: 1` — Sin HA, solo un nodo tiene el repo
- `replication_factor: 2` — Una réplica adicional, tolera fallo de 1 nodo
- `replication_factor: 3` — Dos réplicas adicionales, tolera fallo de 2 nodos

## Modos de operación de Praefect

**Modo estricto (per_repository)**: Cada repositorio se asigna a un Gitaly primario específico. Las lecturas van al primario, las escrituras se replican a secundarios.

**Modo distribuido (distributed)**: Las lecturas pueden ir a cualquier réplica, mejorando el rendimiento de lectura. Requiere consistencia eventual y no es adecuado para operaciones que requieren datos inmediatamente actualizados.

## Limitaciones en CE

Gitaly Cluster está disponible en GitLab CE pero con limitaciones:
- No incluye balanceo de carga automático de lecturas distribuido
- La configuración y mantenimiento es más manual que en EE
- Se recomienda solo para escenarios donde HA de repositorios es crítico
