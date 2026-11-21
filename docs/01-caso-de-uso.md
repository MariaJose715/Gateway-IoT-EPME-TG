# 01 · Caso de uso

[← Volver al README](../README.md) · [Siguiente: Arquitectura →](02-arquitectura.md)

## Ficha del proyecto

| Campo | Valor |
|---|---|
| Proyecto | Prototipo de un Gateway IoT |
| Código Quipu | `202010047080` |
| Convocatoria | 930 |
| Resolución | 1129 de 2026 |
| Periodo de vinculación | 27 de octubre – 26 de noviembre de 2026 |
| Autora | Nayely María José Cuadros Ortega |
| Programa | Ingeniería Electrónica |
| Tutor | Prof. Gustavo Adolfo Osorio Londoño |
| Institución | Universidad Nacional de Colombia, Sede Manizales |

## 1.1 Contexto

El proyecto **Prototipo de un Gateway IoT** desarrolla una plataforma de adquisición y transmisión de datos para equipos industriales. El caso de uso documentado en este repositorio corresponde a la **telemetría eléctrica industrial** del kit **EPME-TG**, compuesto por un medidor trifásico **Eastron SDM630MCT-RC** y un **Gateway SerIoT** con conectividad celular 4G/LTE.

El medidor se instala en un tablero trifásico y entrega las variables eléctricas por un bus RS485 mediante el protocolo **Modbus RTU**. El gateway actúa como maestro Modbus, lee periódicamente los registros del medidor, construye un mensaje JSON y lo publica por **MQTT** a través de la red celular. En el servidor, un conjunto de servicios autoalojados recibe, normaliza, almacena y visualiza la información.

La solución emplea protocolos abiertos y componentes de código abierto, de modo que puede reproducirse sin depender de una plataforma IoT propietaria y puede adaptarse a otros medidores, tableros o variables de proceso.

## 1.2 Necesidad que atiende

La medición local de variables eléctricas exige presencia física para consultar el medidor y no conserva un histórico consultable. Para el monitoreo energético de una instalación se requiere:

- observar tensión, corriente, potencia, frecuencia y energía sin desplazarse al tablero;
- conservar un histórico con resolución de segundos o minutos;
- comparar el comportamiento entre fases y a lo largo del tiempo;
- detectar variaciones de carga o interrupciones del servicio;
- integrar los datos con herramientas de análisis, alertas o gestión energética.

El caso de uso resuelve estas necesidades con una arquitectura de cuatro capas: campo, gateway, transporte y servidor. La información viaja desde el medidor hasta un dashboard accesible desde el navegador y queda almacenada en una base de datos de series temporales.

## 1.3 Objetivo general

Implementar y validar un sistema de telemetría eléctrica industrial que adquiera variables del medidor Eastron SDM630MCT-RC mediante Modbus RTU, las transmita por MQTT a través de una red celular y las almacene y visualice en un servidor autoalojado con Mosquitto, Node-RED, InfluxDB y Grafana.

## 1.4 Objetivos específicos

1. Caracterizar las interfaces del medidor y del gateway: bus RS485, tramas Modbus RTU, registros FLOAT-32, módem 4G/LTE y cliente MQTT.
2. Configurar el medidor y el gateway para leer tensión, corriente, potencia, frecuencia y energía con un periodo de muestreo de 10 segundos.
3. Desplegar un stack de servicios autoalojado con Docker Compose que reciba, normalice, almacene y visualice la telemetría.
4. Definir y ejecutar un plan de pruebas que verifique la exactitud de las lecturas, la continuidad del flujo y la latencia extremo a extremo.
5. Documentar el procedimiento, los resultados y las evidencias en un repositorio reproducible.

## 1.5 Alcance

| Incluido | No incluido |
|---|---|
| Lectura Modbus RTU del medidor Eastron por RS485. | Diseño CAD, tolerancias de montaje y pruebas de impresión 3D de la carcasa. |
| Configuración del Gateway SerIoT y de la red celular. | Desarrollo de firmware propietario del gateway. |
| Publicación MQTT en el tópico `datos`. | Aplicaciones móviles o portales de usuario final. |
| Stack Docker con Mosquitto, Node-RED, InfluxDB y Grafana. | Integración con ERP, SCADA o sistemas de facturación. |
| Dashboard de tensión, corriente, potencia y energía. | Control de actuadores o maniobras sobre el tablero. |
| Plan de pruebas, resultados y evidencias. | Certificación metrológica oficial del medidor. |

El componente mecánico se desarrolla en otra línea del proyecto. Este repositorio documenta los requisitos de conectividad, puertos, antena y alimentación que ese componente debe respetar.

## 1.6 Actores y responsabilidades

| Actor | Responsabilidad |
|---|---|
| Autora del proyecto | Configuración del medidor y del gateway, despliegue del stack, ejecución de pruebas y documentación. |
| Tutor del proyecto | Acompañamiento técnico y revisión de entregables. |
| Personal de laboratorio | Verificación del montaje eléctrico y acompañamiento en la puesta en marcha. |
| Usuario operativo | Consulta del dashboard y seguimiento de las variables eléctricas. |
| Administrador del servidor | Gestión de credenciales, respaldos, actualizaciones y exposición de puertos. |

## 1.7 Variables monitoreadas

| Variable | Símbolo | Unidad | Uso |
|---|---|---|---|
| Tensión de fase L1-N | `voltaje` | V | Verificar el nivel de tensión y detectar caídas o sobretensiones. |
| Corriente de línea L1 | `corriente` | A | Estimar la carga y comparar con la capacidad del circuito. |
| Potencia activa total | `potencia` | W | Analizar el consumo instantáneo del tablero. |
| Energía acumulada | `energia` | kWh | Seguir el consumo en el tiempo y construir históricos. |
| Frecuencia | `frecuencia` | Hz | Verificar la calidad de la red. |

El flujo admite variables adicionales por fase (L2, L3), potencia reactiva, factor de potencia y energía exportada. El mapa de registros se presenta en [`04-configuracion-gateway.md`](04-configuracion-gateway.md).

## 1.8 Criterios de éxito

| ID | Criterio | Meta |
|---|---|---|
| C1 | Lectura Modbus coherente con la pantalla del medidor. | Error ≤ 1 % |
| C2 | Publicación MQTT periódica. | Un mensaje cada 10 s |
| C3 | Escritura y consulta en InfluxDB. | 100 % de las muestras recibidas |
| C4 | Visualización en Grafana. | Paneles con datos y actualización automática |
| C5 | Latencia extremo a extremo. | < 5 s |
| C6 | Reproducibilidad del despliegue. | `docker compose up -d` en un equipo limpio |
| C7 | Documentación y evidencias completas. | Repositorio e informe revisados |

El detalle de las pruebas y su relación con estos criterios se encuentra en [`05-plan-de-pruebas.md`](05-plan-de-pruebas.md).

## 1.9 Correspondencia con las actividades de la convocatoria

El informe se concentra en las actividades 1 a 4 y 8 de la Resolución 1129 de 2026, correspondientes al componente de comunicaciones, captura de datos, evaluación de desempeño y documentación.

| Actividad | Trabajo realizado | Evidencia |
|---|---|---|
| 1. Exploración y caracterización de módulos de radio e interfaces. | Caracterización del bus RS485/Modbus RTU y del módulo celular 4G; configuración de APN y MQTT. | [`02-arquitectura.md`](02-arquitectura.md), [`04-configuracion-gateway.md`](04-configuracion-gateway.md), diagramas. |
| 2. Desarrollo y prueba de rutinas de firmware para captura y transmisión. | Configuración de variables Modbus y publicación MQTT; validación de captura cada 10 s. | [`04-configuracion-gateway.md`](04-configuracion-gateway.md), `config/nodered/flows.json`. |
| 3. Evaluación técnica de desempeño y recolección de datos. | Plan de pruebas, medición de latencia, continuidad y comparación con el medidor. | [`05-plan-de-pruebas.md`](05-plan-de-pruebas.md), [`06-resultados.md`](06-resultados.md). |
| 4. Elaboración de informes con los resultados de las pruebas. | Informe técnico, manual de despliegue, plan de pruebas y repositorio. | `report/`, `docs/`, `README.md`. |
| 8. Elaboración del informe técnico de diseño estructural y físico. | Documentación de requisitos de conectividad, puertos y antena para el diseño de la carcasa. | [`02-arquitectura.md`](02-arquitectura.md), [`04-configuracion-gateway.md`](04-configuracion-gateway.md). |

Las actividades 5 a 7 (diseño CAD 3D, tolerancias de montaje y pruebas de impresión) pertenecen al componente de diseño mecánico. Los requisitos de puertos, disipación, alojamiento de antenas y acceso a conectores definidos aquí alimentan ese componente.

## 1.10 Resultados esperados

Al finalizar el recorrido documentado se espera:

- un stack de cuatro servicios operativo y verificable;
- un flujo de datos continuo entre el medidor y el dashboard;
- una lectura consistente con la referencia del medidor;
- un histórico consultable en InfluxDB;
- un dashboard reproducible desde el repositorio;
- un informe y un conjunto de evidencias que permitan auditar el trabajo.

Los valores obtenidos se documentan en [`06-resultados.md`](06-resultados.md).
