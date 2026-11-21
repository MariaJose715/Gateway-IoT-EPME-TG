# 04 · Configuración del gateway y del medidor

[← Anterior: Despliegue](03-despliegue.md) · [Siguiente: Plan de pruebas →](05-plan-de-pruebas.md)

Este documento describe la puesta en marcha del kit **EPME-TG**: el medidor trifásico Eastron SDM630MCT-RC, el bus RS485, el mapa de registros Modbus, la configuración del Gateway SerIoT y el formato del mensaje publicado.

## 4.1 Medidor Eastron SDM630MCT-RC

| Característica | Valor |
|---|---|
| Tipo | Medidor de energía trifásico con entrada para bobinas Rogowski. |
| Sistema | 3P4W (tres fases y neutro). |
| Tensión de servicio | 3×230/400 V CA (verificar placa del equipo). |
| Entrada de corriente | Bobinas Rogowski de 85 mV/kA. |
| Clase de exactitud | Clase 1. |
| Interfaz | RS485, Modbus RTU. |
| Velocidad | 2400 a 38400 bps; en el caso de uso, 9600 bps. |
| Formato de trama | 8 bits de datos, sin paridad, 1 bit de parada (8N1). |
| Dirección Modbus | 1 a 247; en el caso de uso, esclavo 1. |
| Variables | Tensión, corriente, potencia, frecuencia y energía. |

El medidor se instala en el tablero con las bobinas Rogowski alrededor de los conductores de fase. La orientación de la bobina y la relación configurada deben coincidir con la corriente nominal de la instalación.

## 4.2 Montaje de campo y bus RS485

| Paso | Acción | Verificación |
|---|---|---|
| 1 | Verificar la alimentación del medidor y de las bobinas. | La pantalla del medidor enciende y muestra lecturas. |
| 2 | Conectar las bobinas L1, L2 y L3 según la orientación indicada por el fabricante. | La corriente medida es coherente con la carga. |
| 3 | Conectar el bus RS485: A hacia A y B hacia B. | La pantalla y el gateway intercambian tramas. |
| 4 | Verificar la continuidad y la ausencia de cortos en el bus. | Sin ruido ni lecturas erráticas. |
| 5 | Conectar el blindaje a tierra en un solo extremo. | Se reduce el ruido electromagnético. |
| 6 | Instalar terminación de 120 Ω si el bus es largo o tiene derivaciones. | Comunicación estable a 9600 bps. |
| 7 | Fijar los cables y rotular el bus. | Trazabilidad para mantenimiento. |

El bus RS485 es semidúplex y compartido. El gateway actúa como único maestro; no deben existir otros maestros en el mismo segmento durante la validación.

## 4.3 Parámetros del medidor

| Parámetro | Valor utilizado | Observación |
|---|---|---|
| Dirección Modbus | `1` | Holding register 40001 (0x0000) = 1. |
| Velocidad | `9600 bps` | Holding register 40019 (0x0012). |
| Paridad / bits de parada | `None / 1` | Trama 8N1. |
| Tipo de sistema | `3P4W` | Holding register 40011 (0x000A) = 3. |
| Relación de bobinas | `0,5 kA / 1 kA / 5 kA` | Según la corriente nominal de la instalación. |
| Contraseña de acceso | `1000` | Valor de fábrica. |

La configuración se realiza desde el menú del medidor o con la herramienta del fabricante. Después de cambiar un parámetro, confirme que la pantalla y el gateway sigan comunicándose.

## 4.4 Mapa de registros Modbus

Las magnitudes se leen como **Input Registers** con el código de función **04**. Cada valor ocupa dos registros consecutivos en formato **FLOAT-32 IEEE 754**.

| Variable | Registro (hex) | Decimal | Tipo | Función | Unidad |
|---|---|---|---|---|---|
| Tensión L1-N | `0x0000` | 0 | FLOAT-32 | 04 | V |
| Corriente L1 | `0x0006` | 6 | FLOAT-32 | 04 | A |
| Potencia activa L1 | `0x000C` | 12 | FLOAT-32 | 04 | W |
| Potencia activa total | `0x0034` | 52 | FLOAT-32 | 04 | W |
| Frecuencia | `0x0046` | 70 | FLOAT-32 | 04 | Hz |
| Energía importada | `0x0048` | 72 | FLOAT-32 | 04 | kWh |
| Energía total | `0x0156` | 342 | FLOAT-32 | 04 | kWh |

Cada variable se configura con:

- **Esclavo:** 1.
- **Tipo de registro:** Input.
- **Función:** 04.
- **Escalador:** 1,0.
- **Offset:** 0,0.
- **Formato:** FLOAT-32.

Si el medidor entrega las palabras en orden invertido, active la opción **Invertir bytes** del gateway y compare de nuevo con la pantalla del medidor.

## 4.5 Decodificación FLOAT-32

Un valor FLOAT-32 se compone de dos registros de 16 bits. El registro alto contiene el signo, el exponente y la parte alta de la mantisa; el registro bajo completa la mantisa. La interpretación correcta depende del orden de palabras configurado.

Ejemplos usados en las pruebas:

| Variable | Registro alto | Registro bajo | Valor |
|---|---:|---:|---:|
| Tensión L1-N | `0x42F3` | `0x0000` | 121,5 V |
| Corriente L1 | `0x40A6` | `0x6666` | 5,20 A |
| Energía | `0x4145` | `0x70A4` | 12,34 kWh |
| Potencia activa | `0x441D` | `0xC000` | 631,0 W |
| Frecuencia | `0x4270` | `0x0000` | 60,0 Hz |

La función de referencia está implementada en [`tests/test_modbus.py`](../tests/test_modbus.py):

```python
import struct


def decode_float32(registers, word_order="big"):
    if len(registers) != 2:
        raise ValueError("Se esperaban exactamente dos registros")
    hi, lo = registers
    raw = hi.to_bytes(2, "big") + lo.to_bytes(2, "big")
    if word_order == "little":
        raw = raw[2:] + raw[:2]
    return struct.unpack(">f", raw)[0]
```

Las pruebas verifican los cinco valores de la tabla y el caso de orden de palabras invertido.

## 4.6 Configuración del Gateway SerIoT

La configuración se realiza desde la aplicación **SerIoT Config**. Los valores utilizados en el laboratorio se resumen a continuación.

| Parámetro | Valor utilizado | Observación |
|---|---|---|
| APN | APN del operador local | Verificar cobertura y asignación de IP. |
| Usuario / contraseña APN | Según el operador | Puede quedar vacío si el operador no lo exige. |
| IOT Server URL | Host del túnel o VPS | Sin prefijo `http://` ni `mqtt://`. |
| Puerto | `1883` | Puerto del broker Mosquitto. |
| Token | Vacío en laboratorio | En producción se utiliza autenticación. |
| Tópico | `datos` | Tópico de publicación de telemetría. |
| Usuario / contraseña MQTT | Vacío en laboratorio | En producción se configuran credenciales. |
| Periodo de muestreo | `10 s` | Adecuado para monitoreo energético. |
| Formato | JSON | Objeto con variables y marca de tiempo. |
| Esclavo Modbus | `1` | Dirección del medidor Eastron. |
| Función Modbus | `04` | Input Registers. |

Pasos sugeridos:

1. Conectar el gateway a la red celular y confirmar que obtiene dirección IP.
2. Registrar el APN y las credenciales del operador.
3. Definir la URL y el puerto del broker.
4. Configurar el tópico `datos` y el periodo de 10 s.
5. Crear las variables Modbus con la dirección, el tipo y la función de la tabla 4.4.
6. Verificar que cada variable muestre un valor coherente con la pantalla del medidor.
7. Guardar la configuración y reiniciar el servicio de adquisición.

## 4.7 Mensaje publicado

El gateway construye un objeto JSON con las variables y la marca de tiempo:

```json
{
  "voltaje": 121.5,
  "corriente": 5.2,
  "energia": 12.34,
  "timestamp": "2026-11-20T15:30:00-05:00"
}
```

| Campo | Tipo | Unidad | Obligatorio | Descripción |
|---|---|---|---|---|
| `voltaje` | número | V | Sí | Tensión de fase L1-N. |
| `corriente` | número | A | Sí | Corriente de línea L1. |
| `energia` | número | kWh | Sí | Energía acumulada. |
| `timestamp` | cadena ISO 8601 | — | Recomendado | Marca de tiempo del gateway. |
| `potencia` | número | W | No | Potencia activa total. |
| `frecuencia` | número | Hz | No | Frecuencia de la red. |

El flujo de Node-RED acepta campos adicionales y los escribe en InfluxDB. Si el gateway no envía `timestamp`, InfluxDB asigna la hora de recepción.

## 4.8 Conectividad hacia el broker

| Modalidad | Componente | Uso | Características |
|---|---|---|---|
| Laboratorio | Túnel TCP | Demostración y pruebas | Sin configuración del router; puerto temporal. |
| Producción | VPS + FRP | Despliegue permanente | Puerto fijo, TLS, autenticación y monitoreo. |

En ambas modalidades el broker escucha en el puerto `1883` dentro del servidor. La diferencia está en la capa de exposición: el túnel temporal simplifica la demostración; el VPS con FRP ofrece las condiciones necesarias para operación continua.

Ejemplo de verificación desde el servidor:

```bash
docker compose exec -T mosquitto mosquitto_sub -h localhost -t datos -C 1 -W 30
```

El comando queda a la espera de un mensaje del gateway. Si no llega, revise la URL, el puerto, el APN y el estado del túnel.

## 4.9 Verificación en campo

| Paso | Acción | Resultado esperado |
|---|---|---|
| 1 | Comparar la tensión del dashboard con la pantalla del medidor. | Diferencia ≤ 1 %. |
| 2 | Comparar la corriente del dashboard con la pinza o la pantalla. | Diferencia ≤ 1 %. |
| 3 | Revisar la potencia activa total. | Coherente con tensión × corriente × factor de potencia. |
| 4 | Confirmar el incremento de la energía. | La curva es monótona y consistente con la carga. |
| 5 | Verificar la frecuencia. | 60,0 Hz en la red colombiana. |
| 6 | Publicar durante 10 minutos. | Un mensaje cada 10 s. |
| 7 | Revisar la marca de tiempo. | Zona horaria y hora correctas. |

## 4.10 Seguridad

La configuración descrita corresponde a un entorno de laboratorio con `allow_anonymous true` en Mosquitto y sin TLS. Antes de exponer el broker a Internet:

- active autenticación por usuario y contraseña;
- aplique una lista de control de acceso por tópico;
- habilite TLS en el puerto `8883`;
- restrinja los puertos de administración a la red local o a una VPN.

El procedimiento completo se encuentra en [`07-seguridad.md`](07-seguridad.md).
