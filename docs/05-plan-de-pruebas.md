# 05 · Plan de pruebas

[← Anterior: Configuración del gateway](04-configuracion-gateway.md) · [Siguiente: Resultados →](06-resultados.md)

## 5.1 Objetivo

Verificar de extremo a extremo que el sistema adquiere las variables eléctricas, las transmite por MQTT, las almacena en InfluxDB y las presenta en Grafana con la exactitud, continuidad y latencia requeridas.

## 5.2 Alcance

| Incluido | Excluido |
|---|---|
| Lectura Modbus de tensión, corriente, potencia, frecuencia y energía. | Calibración metrológica certificada. |
| Conectividad del gateway por red celular. | Pruebas de carga con miles de dispositivos. |
| Publicación y recepción MQTT. | Pruebas de penetración o auditoría de seguridad externa. |
| Escritura y consulta en InfluxDB. | Validación de aplicaciones móviles. |
| Visualización en Grafana. | Ensayos destructivos o de larga duración. |
| Reproducibilidad del despliegue. | Certificación del tablero eléctrico. |

## 5.3 Entorno de pruebas

| Elemento | Configuración |
|---|---|
| Medidor | Eastron SDM630MCT-RC, esclavo 1, 9600 8N1, 3P4W. |
| Gateway | SerIoT, 4G/LTE, tópico `datos`, muestreo 10 s. |
| Servidor | Docker Desktop sobre Windows 11 + WSL2 (también reproducible en Linux). |
| Broker | Mosquitto 2.0, puerto 1883. |
| Procesamiento | Node-RED 4.0 con `node-red-contrib-influxdb`. |
| Almacenamiento | InfluxDB 2.7, organización `seriot`, bucket `datos`. |
| Visualización | Grafana 11.2.0, dashboard `seriot-main`. |
| Red | Túnel TCP para el laboratorio. |
| Periodo de validación | 20 de noviembre de 2026. |

## 5.4 Criterios de aceptación

| ID | Criterio | Método | Meta |
|---|---|---|---|
| C1 | Lectura Modbus coherente con la pantalla del medidor. | Comparación directa de tensión y corriente. | Error ≤ 1 % |
| C2 | Publicación MQTT periódica. | Registro de mensajes en Mosquitto y Node-RED. | Un mensaje cada 10 s |
| C3 | Escritura y consulta en InfluxDB. | Consulta Flux del último registro. | 100 % de las muestras recibidas |
| C4 | Visualización en Grafana. | Apertura del dashboard y actualización automática. | Paneles con datos |
| C5 | Latencia extremo a extremo. | Marca de tiempo del gateway vs. recepción en Node-RED. | < 5 s |
| C6 | Reproducibilidad. | Despliegue desde el repositorio en un equipo limpio. | `docker compose up -d` |
| C7 | Documentación y evidencias. | Revisión del informe y del repositorio. | Completa |

## 5.5 Matriz de pruebas

| ID | Prueba | Procedimiento | Criterio | Evidencia |
|---|---|---|---|---|
| T01 | Stack Docker | `docker compose up -d` y `docker compose ps`. | 4/4 servicios activos. | `evidence/logs/docker-ps.txt` |
| T02 | Broker MQTT | Publicar y suscribirse con `mosquitto_pub` y `mosquitto_sub`. | Mensaje recibido. | `evidence/logs/mqtt-sample.log` |
| T03 | Conexión del gateway | Verificar la conexión del cliente en Mosquitto y en Node-RED. | Cliente conectado. | Registros de Mosquitto y Node-RED. |
| T04 | Lectura de tensión | Comparar dashboard y pantalla del medidor. | Error ≤ 1 %. | `evidence/logs/test-results.txt` |
| T05 | Lectura de corriente | Comparar dashboard y referencia del medidor. | Error ≤ 1 %. | `evidence/logs/test-results.txt` |
| T06 | Publicación periódica | Registrar la llegada de mensajes durante 10 minutos. | Un mensaje cada 10 s. | `evidence/logs/mqtt-sample.log` |
| T07 | Latencia | Medir la diferencia entre la marca de tiempo y la recepción. | < 5 s. | `evidence/logs/test-results.txt` |
| T08 | InfluxDB | Consultar el último registro con Flux. | Datos disponibles. | `evidence/logs/influx-query.json` |
| T09 | Grafana | Abrir el dashboard y verificar la actualización. | Paneles con datos. | `evidence/screenshots/01-dashboard.png` |
| T10 | Reproducibilidad | Desplegar desde el repositorio en un equipo limpio. | Stack operativo. | `evidence/logs/test-results.txt` |

## 5.6 Procedimiento de ejecución

### Preparación

```bash
docker compose up -d
docker compose ps
bash scripts/verify.sh
```

Registre la salida de `docker compose ps` en `evidence/logs/docker-ps.txt`.

### T01 · Stack Docker

1. Ejecute `docker compose ps`.
2. Confirme que los cuatro contenedores estén activos.
3. Revise los healthchecks de Mosquitto, InfluxDB y Grafana.

### T02 · Broker MQTT

```bash
docker compose exec -T mosquitto mosquitto_sub -h localhost -t datos -C 1 -W 30 &
bash scripts/publish-test.sh
```

El suscriptor debe recibir el mensaje publicado. Guarde una muestra en `evidence/logs/mqtt-sample.log`.

### T03 · Conexión del gateway

1. Encienda el gateway y espere la conexión celular.
2. Verifique en los registros de Mosquitto el evento de conexión del cliente.
3. Confirme en Node-RED que el nodo MQTT aparece conectado.

### T04 y T05 · Exactitud de tensión y corriente

1. Lea la tensión y la corriente en la pantalla del medidor.
2. Lea los mismos valores en el dashboard de Grafana.
3. Calcule el error relativo:

```text
error (%) = |valor_dashboard − valor_referencia| / valor_referencia × 100
```

4. Registre los valores en `evidence/logs/test-results.txt`.

### T06 · Publicación periódica

1. Deje el sistema en operación durante 10 minutos.
2. Cuente los mensajes recibidos en el tópico `datos`.
3. Confirme que el intervalo sea de 10 s.

Para la ventana de continuidad de dos horas, mantenga la operación y compare las muestras esperadas (720) con las válidas.

### T07 · Latencia

1. Registre la marca de tiempo `timestamp` del mensaje.
2. Registre la hora de recepción en Node-RED.
3. Calcule la diferencia para al menos 30 mensajes.
4. Reporte el promedio y el máximo.

### T08 · InfluxDB

```bash
docker compose exec -T influxdb influx query \
  'from(bucket:"datos") |> range(start:-1h) |> filter(fn:(r) => r._measurement == "energia") |> last()' \
  --org seriot --token "$INFLUXDB_TOKEN"
```

Confirme que el último registro corresponda al mensaje más reciente. Guarde la salida en `evidence/logs/influx-query.json`.

### T09 · Grafana

1. Abra <http://localhost:3000>.
2. Ingrese al dashboard `seriot-main`.
3. Verifique los paneles de tensión, corriente, potencia y energía.
4. Cambie el rango de tiempo y confirme la actualización.
5. Guarde una captura en `evidence/screenshots/01-dashboard.png`.

### T10 · Reproducibilidad

1. En un equipo limpio, clone el repositorio.
2. Cree `.env` a partir de `.env.example`.
3. Ejecute `docker compose up -d`.
4. Repita T01, T02 y T09.

El procedimiento detallado está en [`08-reproducibilidad.md`](08-reproducibilidad.md).

## 5.7 Registro de evidencias

| Evidencia | Archivo | Contenido |
|---|---|---|
| Estado del stack | `evidence/logs/docker-ps.txt` | Contenedores, imágenes y puertos. |
| Muestras MQTT | `evidence/logs/mqtt-sample.log` | Mensajes publicados en `datos`. |
| Consulta InfluxDB | `evidence/logs/influx-query.json` | Últimos registros del bucket. |
| Resumen de pruebas | `evidence/logs/test-results.txt` | Resultados T01–T10 y métricas. |
| Dashboard | `evidence/screenshots/01-dashboard.png` | Vista de referencia. |
| Flujo Node-RED | `evidence/screenshots/02-nodered.png` | Flujo implementado. |
| Configuración del gateway | `evidence/screenshots/03-gateway-config.png` | Variables Modbus y red celular. |

## 5.8 Gestión de incidencias

| Nivel | Descripción | Respuesta |
|---|---|---|
| Bajo | Diferencia de formato o de unidad. | Corregir la configuración y repetir la prueba. |
| Medio | Mensaje perdido o latencia alta. | Revisar la red, el túnel y los registros de Node-RED. |
| Alto | El gateway no conecta o el stack no inicia. | Verificar credenciales, puertos y estado de los contenedores. |
| Crítico | Pérdida de datos o exposición de credenciales. | Detener el servicio, rotar credenciales y restaurar el respaldo. |

Toda incidencia se registra con fecha, prueba afectada, causa, acción y resultado. Las pruebas se repiten después de la corrección.

## 5.9 Criterio de cierre

El plan se considera cerrado cuando:

- las diez pruebas tienen resultado registrado;
- los criterios C1 a C7 se cumplen;
- las evidencias están disponibles en el repositorio;
- el dashboard y el flujo pueden desplegarse desde cero;
- el informe de actividades recoge los resultados.

Los valores obtenidos se presentan en [`06-resultados.md`](06-resultados.md).
