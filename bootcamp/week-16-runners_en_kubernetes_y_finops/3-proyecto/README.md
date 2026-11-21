# Proyecto — Semana 16: lo que cuesta un pipeline

> Hasta la Semana 15, la respuesta a "¿cuánto cuesta nuestro CI?" era "una máquina". Desde esta, `app` corre en pods que nacen y mueren con cada job, y la respuesta tiene cifras: tanto por minuto de job, tanto por pipeline, tanto al mes, y cuánto de eso es capacidad que nadie usa. Las cifras salen de tus medidas, no de un artículo.

---

## 🎯 Objetivo

Dejar en pie la **capa 16** de tu plataforma: el runner de Kubernetes atendiendo a `app`, `docker-app` en pausa como vuelta atrás, la línea base versionada, los values del runner en `infra/entornos`, y `docs/finops.md`, que explica a quien llegue después cuánto cuesta la ejecución y por qué `concurrent` vale lo que vale.

---

## 📦 Qué añade esta capa

| Lo que creas esta semana | Se usa a partir de |
|---|---|
| El clúster `bootcamp` de k3d | Todas: desde la S17 ejecuta los jobs de `app`. S25 (el agente de Kubernetes y GitOps despliegan en el mismo clúster) |
| `k8s-app` con la etiqueta `docker` | S19 (los escáneres corren en pods sin privilegios), S20 (Cosign y Conftest, ídem) |
| `docs/linea-base-s16.json` | S21 (el umbral del SLO de duración de pipeline parte de estas medias), S26 (la defensa) |
| `docs/finops.md` | S26 (la defensa: cuánto cuesta la plataforma y por qué) |
| `runners/k8s-app.values.yaml` | S22 (reconstruir el runner es la práctica 01, dos `Secret` y este archivo) |
| `docker-app` en pausa | S22 (la vuelta atrás si el clúster no vuelve) |

Lo que esta semana deja a medias, a propósito: los nodos no crecen con la cola. En k3d todos los nodos comparten tu máquina, así que el autoescalado de nodos se queda en la teoría 05 y en tu `docs/finops.md`, como lo que pagarías en una nube.

---

## ✅ Requisitos verificables

Los comprueba `./scripts/verificar-semana.sh 16` contra la API de tu instancia.

1. app tiene en linea un runner de proyecto con la etiqueta docker y ejecutor kubernetes
2. El runner de Kubernetes corre la version fijada del runner, 19.2.2
3. docker-app sigue registrado, en pausa, como vuelta atras
4. Solo un runner de app sin pausar tiene la etiqueta docker
5. El runner dind de la Semana 15 sigue en linea y sin pausar
6. El ultimo pipeline de main en verde construyo en el runner de Kubernetes
7. app versiona docs/linea-base-s16.json con tres pipelines antes y tres despues
8. La linea base mide docker-app antes y el runner de Kubernetes despues
9. Todos los pipelines de la linea base terminaron en verde
10. infra/entornos versiona los values de Helm del runner de Kubernetes con la cache en S3
11. Los values del runner no contienen ningun token de runner ni claves S3
12. app versiona docs/finops.md con el coste por minuto y por pipeline

Las prácticas 01 a 04 dejan en verde todos menos el 12. Ese es este proyecto.

---

## 🛠️ Lo que haces en el proyecto

### 0. Preparar el terreno

Desde la terminal de las prácticas, o repitiendo el paso 0 de la práctica 01.

### 1. El precio

Elige un proveedor de nube y una máquina parecida a la tuya (4 vCPU y 16 GB, o lo que tengas). Apunta su **precio por hora publicado**, la región, la fecha y el enlace a la página de precios. Una sola máquina, sin descuentos por compromiso: es la cifra que cualquiera puede comprobar.

### 2. Los números del mes

```bash
DESDE=$(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)
curl -s -H "$H" "$API/projects/$P/pipelines?updated_after=$DESDE&per_page=100" | jq length
jq -r '"antes: \(.antes.pipelines | map(.minutos_de_job) | add / length) min de job por pipeline",
       "despues: \(.despues.pipelines | map(.minutos_de_job) | add / length) min de job por pipeline"' \
  /ruta/a/tus/clones/app/docs/linea-base-s16.json
```

El primer número son los pipelines de `app` del último mes (con `per_page=100`, si sale 100 hay más: dilo). Los otros dos, los minutos de job por pipeline con cada runner. Con el precio del paso 1 y tu `concurrent` (práctica 04, paso 5), aplica las dos fórmulas de la teoría 06, apartado 2.2.

### 3. `docs/finops.md`

En `app`, por merge request con su issue, como la línea base (práctica 03, paso 6). Tiene que contar, con tus palabras y tus cifras:

- **La ejecución hoy**: qué runner coge cada job (`k8s-app`, `dind-app`, `deploy-infra`), y `docker-app` en pausa y por qué
- **La línea base**: un enlace a `linea-base-s16.json`, una tabla con duración media, cola media y minutos de job antes y después, y qué cambió y qué no
- **El coste por minuto de job**: la máquina, el precio con su enlace y su fecha, `concurrent`, y la cuenta
- **El coste por pipeline y por mes**: con los pipelines del último mes, y las horas encendidas sin jobs para un runner fijo frente a un clúster que baja a cero nodos
- **`concurrent`**: la cifra, los máximos de memoria de la práctica 04, paso 3, y la memoria libre que la justifica
- **Lo que no se mide aquí**: los minutos de `deploy-infra` (están en `infra/entornos`), el tiempo de las personas esperando, y lo que costaría la cuota de minutos de pago

---

## 🎨 Criterios de calidad

Lo que la API no ve y la rúbrica sí:

- Las seis medidas de la línea base se tomaron con la caché caliente, una detrás de otra y sin nada más en marcha (práctica 03, pasos 1 y 5)
- El precio es de un proveedor real, con enlace y fecha, y la cuenta se puede rehacer con una calculadora
- `docs/finops.md` distingue "más rápido" de "más barato": si los minutos de job no bajaron, lo dice
- El `concurrent` de `runners/k8s-app.values.yaml` es el de `docs/finops.md`, y la justificación usa la memoria medida
- `diff -B` entre lo versionado y lo aplicado sale vacío (práctica 04, paso 6)
- Ningún archivo fuera de `~/.bc-gitlab*` contiene un token `glrt-` ni la clave de `cache-s3`, y `~/bc-s16` tampoco

---

## 💡 Adaptación a tu dominio

| Dominio | Qué cambia en las cifras |
|---|---|
| Biblioteca (el del ejemplo) | Pocos pushes al día: las horas encendidas sin jobs son casi toda la factura de un runner fijo |
| Clínica veterinaria | Si `app` tiene tests de integración con base de datos, el servicio cuenta en la memoria de cada pod: súmalo al calcular `concurrent` |
| Tienda en línea | Picos en campañas: estima el mes de más pushes, no el medio |
| Gestión de incidencias | Pipelines cortos y muchos: la cola pesa más que la duración. Pon la cola media en primer plano |

---

## 🚦 Cómo entregarlo

No hay nada que subir a ningún sitio. El entregable **es el estado de `app`, de `infra/entornos`, de sus runners y de tu clúster**.

```bash
cd /ruta/a/bc-gitlab
./scripts/verificar-semana.sh 16
```

```
12 de 12 verificaciones superadas.
```

---

## 🧯 Errores comunes

| Error | Cómo se detecta | Solución |
|---|---|---|
| `runner-kubernetes-en-linea` en rojo con el gestor `Running` | `k8s-app` sigue en pausa | Práctica 03, paso 4 |
| `docker-app-en-pausa` en rojo | `docker-app` se borró en vez de pausarse | Vuelve a crearlo como en la Semana 09 y pásalo a pausa: la vuelta atrás tiene que existir |
| `main-en-kubernetes` en rojo | El último `main` en verde es anterior al relevo, o `build` corrió en `docker-app` | Lanza un pipeline de `main` y comprueba el paso 4 de la práctica 03 |
| `linea-base-compara-runners` en rojo | Alguna medida de `despues` incluye `docker-app`: aún no estaba en pausa | Repite el paso 5 de la práctica 03 y vuelve a versionar |
| `values-sin-secretos` en rojo | Un `glrt-` en el archivo de valores | Quítalo del archivo y **rota el token**: ya está en el historial |
| `finops-versionado` en rojo con el archivo escrito | Falta la palabra `minuto`, `pipeline` o el nombre `linea-base-s16` | El archivo tiene que enlazar la línea base y hablar de coste por minuto |

---

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [Proyecto Semana 15](../../week-15-runners_ejecutores_y_configuracion/3-proyecto/README.md) | **Proyecto Semana 16** | [Proyecto Semana 17](../../week-17-api_webhooks_y_chatops/3-proyecto/README.md) |

[← Volver a la Semana 16](../README.md)
