# Glosario — Semana 03

## A

- **Approval Rule**: Regla que requiere un numero minimo de aprobadores antes de permitir un merge.
- **Archivar (Archive)**: Poner un proyecto en modo solo-lectura (no se puede modificar, pero se conserva).

## B

- **Branch Protection**: Configuracion que restringe quien puede hacer push o merge a una rama especifica.

## C

- **Code Owner**: Persona o equipo designado como responsable de ciertos archivos/directorios. Su aprobacion es requerida para MRs que modifiquen esos archivos.

## D

- **Developer**: Rol en GitLab que permite push a ramas no protegidas, crear MRs y gestionar issues.

## G

- **Git Flow**: Estrategia de branching con ramas main, develop, feature, release y hotfix.
- **GitHub Flow**: Estrategia simplificada con una rama main siempre desplegable.
- **GitLab Flow**: Extension de GitHub Flow con ramas de ambiente (staging, production).
- **Group (Grupo)**: Namespace que agrupa proyectos y subgrupos. Permite gestionar permisos a nivel organizacional.
- **Guest**: Rol con permisos minimos. Puede ver issues pero no codigo.

## I

- **Internal (Visibilidad)**: Proyectos visibles solo para usuarios autenticados en la instancia.

## M

- **Maintainer**: Rol con permisos avanzados. Puede mergear, push a ramas protegidas, gestionar miembros y configurar el proyecto.

## N

- **Namespace**: Espacio de nombres que organiza proyectos (puede ser usuario, grupo o subgrupo).

## O

- **Owner**: Rol maximo a nivel grupo. Control total sobre el grupo y todos sus proyectos y subgrupos.

## P

- **Private (Visibilidad)**: Proyecto visible solo para miembros explicitos.
- **Protected Branch**: Rama con restricciones de push y merge.
- **Public (Visibilidad)**: Proyecto visible para cualquier persona, incluso sin autenticacion.

## R

- **Reporter**: Rol que permite ver codigo, issues y MRs, pero no hacer push.

## S

- **Subgroup (Subgrupo)**: Grupo anidado dentro de otro grupo. Hereda miembros y configuracion del grupo padre.

## T

- **Trunk-Based Development**: Estrategia donde todos trabajan directamente en main (o ramas de vida muy corta < 24h).
