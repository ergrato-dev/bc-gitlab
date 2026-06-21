# 05 — Presentación y Defensa del Proyecto

La defensa del proyecto final es una presentación de 15 minutos donde demuestras tu competencia como Administrador DevOps Junior. Aquí tienes una guía para estructurarla.

## Estructura de la presentación

### 1. Introducción (2 min)
- Quién eres y tu trayectoria en el bootcamp
- Objetivo del proyecto: "Desplegar una plataforma DevOps completa y funcional"
- Aplicación de ejemplo que usarás para la demo (breve descripción)

### 2. Arquitectura (3 min)
- Mostrar el diagrama de arquitectura
- Explicar cada componente y por qué lo elegiste
- Tecnologías: Docker, GitLab CE, Runner, Registry, Prometheus, Grafana

### 3. Demo en vivo (5 min) — La parte más importante

Preparar una secuencia de comandos que muestren:
1. **Infraestructura**: `docker-compose ps` mostrando todos los servicios up
2. **GitLab**: Abrir navegador, loguearse, mostrar proyectos
3. **Pipeline**: Hacer un push y ver el pipeline ejecutándose en vivo, mostrando cada stage
4. **Seguridad**: Mostrar el Security Dashboard con hallazgos de SAST
5. **Registry**: Mostrar imágenes en el Container Registry
6. **Monitoreo**: Abrir Grafana y mostrar dashboards con métricas en tiempo real
7. **Backup**: Ejecutar el script de backup, mostrar el archivo generado
8. **Environments**: Mostrar deploy a staging y production en GitLab UI

### 4. Decisiones técnicas (3 min)
- ¿Por qué Docker Compose y no Kubernetes? (alcance del bootcamp, simplicidad)
- ¿Por qué GitLab CE y no SaaS? (control, aprendizaje de administración)
- ¿Por qué elegiste X lenguaje/framework para tu app demo?
- ¿Qué harías diferente con más tiempo?

### 5. Lecciones aprendidas (2 min)
- Mayor desafío técnico encontrado
- Lo que más te sorprendió de GitLab
- Habilidad más valiosa adquirida
- Consejo para futuros estudiantes del bootcamp

## Preparación técnica

**Ensayo cronometrado**: Practica la presentación al menos 3 veces con cronómetro. Los 15 minutos pasan muy rápido.

**Ambiente de demo**: Tener todo pre-ejecutado excepto lo que vas a mostrar en vivo. El comando `docker-compose up -d` debe ejecutarse antes de la presentación.

**Plan B**: Tener screenshots o una grabación de respaldo por si algo falla en vivo. La tecnología puede fallar en el peor momento.

## Preguntas frecuentes que te pueden hacer

- "¿Cómo manejarías un pico de 1000 usuarios repentinos?"
- "¿Qué pasaría si se corrompe la base de datos?"
- "¿Cómo actualizarías GitLab sin downtime?"
- "¿Por qué no usaste GitLab SaaS?"
- "¿Cómo aseguras que los secrets no se filtren en el pipeline?"
- "¿Qué métricas son más importantes para ti?"

Prepara respuestas concisas (30-60 segundos) para cada una.

## Criterios de evaluación de la defensa

- Claridad de exposición (hablar pausado, estructurado)
- Dominio técnico demostrado (responder preguntas con seguridad)
- Demo funcional (todo lo mostrado funciona)
- Manejo del tiempo (ni muy corto ni excedido)
- Profesionalismo (presentación ordenada, sin errores de ortografía)
