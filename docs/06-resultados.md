# 06 · Resultados

[← Anterior: Plan de pruebas](05-plan-de-pruebas.md) · [Siguiente: Seguridad →](07-seguridad.md)

## 6.1 Resumen ejecutivo

La validación se realizó con el medidor conectado al tablero y el gateway publicando cada 10 segundos durante una ventana de dos horas. Se registraron **720 muestras**, de las cuales **718** fueron válidas, para una continuidad del **99,7 %**. La latencia promedio extremo a extremo fue de **1,8 s** y las variables principales coincidieron con la referencia del medidor dentro del margen de la clase 1.

| Indicador | Resultado |
|---|---|
| Servicios activos | 4 de 4 |
| Muestras esperadas | 720 |
| Muestras válidas | 718 |
| Continuidad | 99,7 % |
| Latencia promedio | 1,8 s |
| Periodo de muestreo | 10,0 s |
| Resultado global | Conforme |

## 6.2 Resultados por prueba

| ID | Prueba | Resultado | Valor obtenido |
|---|---|---|---|
| T01 | Stack Docker | OK | 4/4 servicios activos |
| T02 | Broker MQTT | OK | Mensaje de prueba recibido |
| T03 | Conexión del gateway | OK | Cliente MQTT conectado |
| T04 | Lectura de tensión | OK | 121,4 V en dashboard vs. 121,5 V de referencia |
| T05 | Lectura de corriente | OK | 5,18 A en dashboard vs. 5,20 A de referencia |
| T06 | Publicación periódica | OK | Un mensaje cada 10 s |
| T07 | Latencia | OK | 1,8 s promedio |
| T08 | InfluxDB | OK | Último registro disponible en el bucket `datos` |
| T09 | Grafana | OK | Paneles con datos y actualización automática |
| T10 | Reproducibilidad | OK | Despliegue completo desde `docker-compose.yml` |

## 6.3 Comparación con la referencia

| Variable | Referencia del medidor | Dashboard | Error | Estado |
|---|---:|---:|---:|---|
| Tensión L1-N | 121,5 V | 121,4 V | 0,08 % | Conforme |
| Corriente L1 | 5,20 A | 5,18 A | 0,38 % | Conforme |
| Potencia activa | 631 W | 628 W | 0,48 % | Conforme |
| Energía | 12,34 kWh | 12,34 kWh | 0,00 % | Conforme |
| Frecuencia | 60,0 Hz | 60,0 Hz | 0,00 % | Conforme |
| Muestreo | 10 s | 10,0 s | — | Conforme |
| Latencia | — | 1,8 s (promedio) | — | Conforme |
| Continuidad | 720 muestras | 718 válidas | 99,7 % | Conforme |

Los errores de tensión, corriente y potencia son inferiores al 0,5 %, muy por debajo del límite del 1 % definido en los criterios de aceptación.

## 6.4 Continuidad y latencia

| Métrica | Valor | Interpretación |
|---|---:|---|
| Ventana de observación | 2 h | Periodo de validación. |
| Muestras esperadas | 720 | Una cada 10 s. |
| Muestras válidas | 718 | 99,7 % de continuidad. |
| Latencia mínima | 1,2 s | Mejor caso observado. |
| Latencia promedio | 1,8 s | Dentro del criterio de < 5 s. |
| Latencia máxima | 2,6 s | Sin picos relevantes. |

La continuidad y la latencia son adecuadas para monitoreo energético y para la generación de alertas operativas. El periodo de 10 s permite observar variaciones de carga sin saturar el almacenamiento.

## 6.5 Análisis de resultados

- **Exactitud de las lecturas.** La tensión, la corriente, la potencia y la energía coinciden con la referencia del medidor dentro del margen de la clase 1. Esto valida la configuración de los registros Modbus, el tipo FLOAT-32 y el orden de bytes.
- **Continuidad del flujo.** El 99,7 % de las muestras válidas confirma que la cadena gateway → broker → Node-RED → InfluxDB opera de forma estable durante la ventana de observación.
- **Latencia adecuada.** Un promedio de 1,8 s deja margen frente al umbral de 5 s y permite reaccionar ante cambios de carga.
- **Reproducibilidad.** El despliegue desde el repositorio se completó con un solo comando y sin pasos manuales adicionales, lo que demuestra que la solución puede transferirse a otro equipo.
- **Interoperabilidad.** El uso de Modbus RTU, MQTT, Flux y HTTP facilita la integración con otros medidores, sistemas SCADA, ERP o plataformas de analítica.
- **Visualización.** El dashboard reúne las variables principales y permite consultar el histórico por rango de tiempo, lo que reduce la dependencia de la pantalla local del medidor.

## 6.6 Cumplimiento de los criterios de aceptación

| ID | Criterio | Meta | Resultado | Estado |
|---|---|---|---|---|
| C1 | Lectura Modbus coherente. | Error ≤ 1 % | Error máximo 0,48 % | Cumple |
| C2 | Publicación MQTT periódica. | Cada 10 s | 10,0 s | Cumple |
| C3 | Escritura y consulta en InfluxDB. | 100 % de las muestras recibidas | 718/718 registros consultables | Cumple |
| C4 | Visualización en Grafana. | Paneles con datos | Dashboard operativo | Cumple |
| C5 | Latencia extremo a extremo. | < 5 s | 1,8 s promedio | Cumple |
| C6 | Reproducibilidad. | `docker compose up -d` | Despliegue exitoso | Cumple |
| C7 | Documentación y evidencias. | Completa | Informe, docs y evidencias | Cumple |

## 6.7 Conclusiones

1. La integración del medidor Eastron SDM630MCT-RC con el Gateway SerIoT mediante Modbus RTU es viable y estable para telemetría eléctrica industrial.
2. La publicación MQTT cada 10 segundos permite un monitoreo continuo con bajo consumo de ancho de banda.
3. InfluxDB y Grafana conforman una base sólida para almacenar y visualizar series temporales de energía.
4. La arquitectura de contenedores simplifica el despliegue, la actualización y la transferencia a otro entorno.
5. Los resultados de exactitud, continuidad y latencia cumplen los criterios definidos para el caso de uso.

## 6.8 Recomendaciones

| Área | Recomendación |
|---|---|
| Seguridad | Habilitar TLS, autenticación MQTT y ACL antes de exponer el broker a Internet. |
| Disponibilidad | Migrar el túnel temporal a un VPS con FRP y supervisión del servicio. |
| Almacenamiento | Ajustar la retención del bucket según la política de datos de la institución. |
| Analítica | Añadir paneles de potencia por fase, factor de potencia y energía diaria. |
| Alertas | Configurar umbrales de tensión, corriente y frecuencia con notificaciones. |
| Escalabilidad | Incorporar etiquetas (`site`, `meter`) para gestionar varios tableros. |
| Operación | Programar respaldos periódicos y probar la restauración. |

## 6.9 Evidencias

| Evidencia | Ubicación |
|---|---|
| Estado del stack | [`evidence/logs/docker-ps.txt`](../evidence/logs/docker-ps.txt) |
| Muestras MQTT | [`evidence/logs/mqtt-sample.log`](../evidence/logs/mqtt-sample.log) |
| Consulta InfluxDB | [`evidence/logs/influx-query.json`](../evidence/logs/influx-query.json) |
| Resumen de pruebas | [`evidence/logs/test-results.txt`](../evidence/logs/test-results.txt) |
| Dashboard | [`evidence/screenshots/01-dashboard.png`](../evidence/screenshots/01-dashboard.png) |
| Flujo Node-RED | [`evidence/screenshots/02-nodered.png`](../evidence/screenshots/02-nodered.png) |
| Configuración del gateway | [`evidence/screenshots/03-gateway-config.png`](../evidence/screenshots/03-gateway-config.png) |

El informe completo, con el análisis extendido y los anexos, está en [`report/`](../report/).
