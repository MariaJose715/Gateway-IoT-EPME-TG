# 03 · Despliegue

[← Anterior: Arquitectura](02-arquitectura.md) · [Siguiente: Configuración del gateway →](04-configuracion-gateway.md)

Esta guía describe el despliegue del servidor autoalojado en un equipo con Docker. Al finalizar, los cuatro servicios estarán activos y el dashboard podrá abrirse en el navegador.

## 3.1 Requisitos

| Recurso | Mínimo | Recomendado |
|---|---|---|
| Sistema operativo | Windows 10/11, macOS 12 o Linux con kernel reciente | Windows 11 con WSL2 o Ubuntu 22.04/24.04 |
| Docker | Docker Desktop 4.x o Docker Engine 24+ | Docker Desktop actualizado |
| Docker Compose | v2 | v2.20 o superior |
| Memoria RAM | 4 GB | 8 GB |
| Disco libre | 10 GB | 20 GB |
| Red | Acceso a Internet para descargar imágenes | Puerto 1883 accesible desde el gateway |
| Git | 2.30 o superior | Última versión estable |
| Python (solo pruebas) | 3.10 | 3.12 |

Verifique las versiones:

```bash
docker --version
docker compose version
git --version
python --version
```

## 3.2 Obtener el repositorio

```bash
git clone https://github.com/MariaJose715/Gateway-IoT-EPME-TG.git
cd Gateway-IoT-EPME-TG
```

También puede descargar el ZIP desde GitHub y descomprimirlo. La carpeta debe contener `docker-compose.yml`, `config/`, `scripts/` y `docs/`.

## 3.3 Crear el archivo de entorno

El archivo `.env` guarda las contraseñas y el token de InfluxDB. No se publica en Git.

```bash
cp .env.example .env
```

En Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Edite `.env` y reemplace los valores de ejemplo:

| Variable | Ejemplo | Obligatoria | Descripción |
|---|---|---|---|
| `INFLUXDB_ADMIN_USER` | `admin` | No | Usuario administrador de InfluxDB. |
| `INFLUXDB_ADMIN_PASSWORD` | valor propio | Sí | Contraseña de al menos 8 caracteres. |
| `INFLUXDB_ORG` | `seriot` | No | Organización de InfluxDB. |
| `INFLUXDB_BUCKET` | `datos` | No | Bucket de telemetría. |
| `INFLUXDB_RETENTION` | `30d` | No | Retención de los datos. |
| `INFLUXDB_TOKEN` | token propio | Sí | Token con permisos de lectura y escritura. |
| `GRAFANA_ADMIN_USER` | `admin` | No | Usuario administrador de Grafana. |
| `GRAFANA_ADMIN_PASSWORD` | valor propio | Sí | Contraseña de Grafana. |
| `TZ` | `America/Bogota` | No | Zona horaria de los contenedores. |

Para generar valores aleatorios:

```bash
# Linux / macOS / WSL
openssl rand -base64 24
```

```powershell
# Windows PowerShell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
```

El token de InfluxDB debe ser una cadena larga y aleatoria. Puede generarlo con el mismo comando y usarlo tanto en `.env` como en la configuración del nodo de Node-RED.

> **Nunca** suba `.env` al repositorio. `.gitignore` ya lo excluye, igual que `flows_cred.json` y los certificados.

## 3.4 Levantar el stack

```bash
docker compose up -d
```

El primer arranque descarga las imágenes y crea la base de datos. Puede tardar varios minutos según la conexión. Verifique el estado:

```bash
docker compose ps
```

Resultado esperado:

```text
NAME               IMAGE                       SERVICE     STATUS
seriot-grafana     grafana/grafana:11.2.0      grafana     Up (healthy)
seriot-influxdb    influxdb:2.7                influxdb    Up (healthy)
seriot-mosquitto   eclipse-mosquitto:2.0       mosquitto   Up (healthy)
seriot-nodered     nodered/node-red:4.0        nodered     Up
```

Si algún servicio no inicia, revise sus registros:

```bash
docker compose logs -f influxdb
docker compose logs -f nodered
```

En Windows también puede usar el script de arranque:

```powershell
.\scripts\start.ps1
```

El script crea `.env` a partir de la plantilla si no existe y recuerda configurar las credenciales antes de continuar.

## 3.5 Verificar los servicios

| Servicio | URL | Verificación |
|---|---|---|
| Node-RED | <http://localhost:1880> | Se abre el editor de flujos. |
| InfluxDB | <http://localhost:8086> | Se abre la interfaz de InfluxDB. |
| Grafana | <http://localhost:3000> | Se abre la pantalla de inicio de sesión. |
| Mosquitto | `localhost:1883` | Acepta conexiones MQTT. |

Verificación rápida desde la terminal:

```bash
curl http://localhost:8086/health
curl http://localhost:3000/api/health
curl -I http://localhost:1880
```

También puede ejecutar:

```bash
bash scripts/verify.sh
```

El script consulta la salud de InfluxDB y Grafana, el estado de Node-RED y publica un mensaje de prueba en el tópico `datos`.

## 3.6 Configurar Node-RED

El flujo incluido utiliza el nodo `node-red-contrib-influxdb`, que no viene en la imagen base. Instálelo una sola vez:

1. Abra <http://localhost:1880>.
2. Menú **≡ → Manage palette → Install**.
3. Busque `node-red-contrib-influxdb` e instálelo.
4. Espere el mensaje de confirmación.

El archivo [`config/nodered/flows.json`](../config/nodered/flows.json) se carga automáticamente porque la carpeta está montada en `/data`. Si no aparece el flujo:

1. Menú **≡ → Import**.
2. Seleccione `config/nodered/flows.json`.
3. Confirme la importación y pulse **Deploy**.

Configure el nodo de InfluxDB:

1. Abra el nodo **Escribir InfluxDB**.
2. En la pestaña del servidor, seleccione **InfluxDB 2.0**.
3. URL: `http://influxdb:8086`.
4. Organización: `seriot`.
5. Bucket: `datos`.
6. Token: el valor de `INFLUXDB_TOKEN` definido en `.env`.
7. Guarde y despliegue con **Deploy**.

El nodo MQTT ya apunta al host `mosquitto` y al puerto `1883`, que es el nombre del servicio dentro de la red de Docker.

## 3.7 Verificar la escritura en InfluxDB

Publique una muestra de prueba:

```bash
bash scripts/publish-test.sh
```

O manualmente:

```bash
docker compose exec -T mosquitto mosquitto_pub -h localhost -t datos -q 1 \
  -m '{"voltaje":121.5,"corriente":5.2,"energia":12.34,"timestamp":"2026-11-20T15:30:00-05:00"}'
```

En la interfaz de InfluxDB (<http://localhost:8086>), abra **Data Explorer**, seleccione el bucket `datos` y consulte:

```flux
from(bucket: "datos")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "energia")
  |> last()
```

También puede usar la CLI dentro del contenedor:

```bash
docker compose exec -T influxdb influx query \
  'from(bucket:"datos") |> range(start:-1h) |> filter(fn:(r) => r._measurement == "energia") |> last()' \
  --org seriot --token "$INFLUXDB_TOKEN"
```

## 3.8 Verificar Grafana

1. Abra <http://localhost:3000>.
2. Ingrese con `GRAFANA_ADMIN_USER` y `GRAFANA_ADMIN_PASSWORD`.
3. Abra la carpeta **SerIoT**.
4. Seleccione el dashboard **SerIoT · Medidor Eastron SDM630MCT-RC**.
5. Verifique que los paneles de tensión, corriente, potencia y energía muestren datos.
6. Cambie el rango de tiempo a **Last 1 hour** y confirme la actualización automática.

La fuente de datos `InfluxDB SerIoT` y el dashboard `seriot-main` se aprovisionan desde [`config/grafana/`](../config/grafana/). Si el dashboard aparece vacío, revise que el token de InfluxDB tenga permisos de lectura sobre el bucket `datos`.

## 3.9 Conectar el gateway

El gateway debe apuntar al host y puerto donde se expone Mosquitto. En el laboratorio se usa un túnel TCP; en producción, un VPS con FRP. La configuración completa se describe en [`04-configuracion-gateway.md`](04-configuracion-gateway.md).

Resumen de parámetros:

| Parámetro | Valor |
|---|---|
| Servidor | Host del túnel o VPS, sin `http://` ni `mqtt://`. |
| Puerto | `1883` |
| Tópico | `datos` |
| Periodo | `10 s` |
| Formato | JSON |

Cuando el gateway publique, los mensajes aparecerán en el nodo de depuración de Node-RED y en el dashboard de Grafana.

## 3.10 Actualizar el stack

```bash
git pull
docker compose pull
docker compose up -d
```

Las versiones de imagen están fijadas en `docker-compose.yml` para evitar cambios inesperados. Si actualiza una imagen, revise las notas de la versión y vuelva a ejecutar el plan de pruebas.

## 3.11 Detener y eliminar

Detener sin borrar datos:

```bash
docker compose down
```

Detener y eliminar contenedores, redes y volúmenes:

```bash
docker compose down -v
```

> `docker compose down -v` elimina la base de datos y el estado de Grafana. Úselo solo en un entorno de pruebas o después de crear un respaldo.

## 3.12 Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| `Defina INFLUXDB_ADMIN_PASSWORD en .env` | Falta la variable o el archivo `.env`. | Cree `.env` a partir de `.env.example` y defina la variable. |
| El puerto 1883 está ocupado | Otro broker se ejecuta en el host. | Detenga el otro servicio o cambie el mapeo de puertos. |
| Node-RED muestra un nodo desconocido | Falta `node-red-contrib-influxdb`. | Instálelo desde **Manage palette**. |
| El dashboard no muestra datos | Token inválido, bucket vacío o consulta fuera del rango. | Verifique el token, publique una muestra y amplíe el rango de tiempo. |
| Grafana no abre | El contenedor aún está iniciando. | Espere 30 segundos y consulte `docker compose ps`. |
| El gateway no conecta | URL, puerto o APN incorrectos; el túnel no está activo. | Verifique la conectividad y el estado del túnel o VPS. |
| InfluxDB reinicia en bucle | Contraseña o token inválidos en `.env`. | Revise los registros y corrija las variables. |

## 3.13 Checklist de despliegue

- [ ] Docker y Docker Compose instalados.
- [ ] Repositorio clonado.
- [ ] `.env` creado con contraseñas y token propios.
- [ ] `docker compose up -d` ejecutado sin errores.
- [ ] Cuatro servicios activos.
- [ ] `node-red-contrib-influxdb` instalado.
- [ ] Nodo de InfluxDB configurado con URL, organización, bucket y token.
- [ ] Flujo desplegado.
- [ ] Mensaje de prueba publicado y visible en InfluxDB.
- [ ] Dashboard de Grafana con datos.
- [ ] Gateway apuntando al host y puerto correctos.
- [ ] Respaldo inicial creado con `scripts/backup.sh`.
