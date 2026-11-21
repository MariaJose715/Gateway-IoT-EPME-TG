# Evidencias de la validación

Esta carpeta reúne los registros y las vistas de referencia utilizados para documentar la sesión de validación del caso de uso.

## Contenido

| Archivo | Descripción |
|---|---|
| `logs/docker-ps.txt` | Estado de los cuatro servicios del stack. |
| `logs/mqtt-sample.log` | Muestras publicadas en el tópico `datos`. |
| `logs/influx-query.json` | Registros consultados en InfluxDB. |
| `logs/test-results.txt` | Resumen consolidado de las pruebas T01–T10. |
| `screenshots/01-dashboard.png` | Vista de referencia del dashboard de Grafana. |
| `screenshots/02-nodered.png` | Vista de referencia del flujo de Node-RED. |
| `screenshots/03-gateway-config.png` | Vista de referencia de la configuración del gateway. |

## Cómo regenerar las evidencias

1. Levante el stack:
   ```bash
   docker compose up -d
   ```
2. Verifique el estado de los servicios:
   ```bash
   docker compose ps | tee evidence/logs/docker-ps.txt
   ```
3. Publique una muestra y suscríbase al tópico:
   ```bash
   ./scripts/publish-test.sh
   mosquitto_sub -h localhost -t datos -C 5 | tee evidence/logs/mqtt-sample.log
   ```
4. Consulte InfluxDB:
   ```bash
   ./scripts/verify.sh
   ```
5. Ejecute el plan de pruebas y actualice `logs/test-results.txt`.

> Las imágenes de `screenshots/` son vistas de referencia generadas para el informe y la documentación. Las capturas definitivas deben reemplazarse por las del entorno de laboratorio cuando se repita la sesión.
