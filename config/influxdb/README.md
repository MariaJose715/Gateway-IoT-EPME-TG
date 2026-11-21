# InfluxDB · inicialización y operación

[← Volver al README](../../README.md)

InfluxDB 2.7 se inicializa automáticamente en el primer arranque del contenedor. No requiere un archivo de configuración estático: los parámetros se inyectan por variables de entorno desde `.env`.

## Inicialización automática

El servicio de `docker-compose.yml` define:

| Variable | Valor por defecto | Función |
|---|---|---|
| `DOCKER_INFLUXDB_INIT_MODE` | `setup` | Ejecuta la configuración inicial una sola vez. |
| `DOCKER_INFLUXDB_INIT_USERNAME` | `admin` | Usuario administrador. |
| `DOCKER_INFLUXDB_INIT_PASSWORD` | obligatorio | Contraseña del administrador. |
| `DOCKER_INFLUXDB_INIT_ORG` | `seriot` | Organización. |
| `DOCKER_INFLUXDB_INIT_BUCKET` | `datos` | Bucket de telemetría. |
| `DOCKER_INFLUXDB_INIT_RETENTION` | `30d` | Retención de los datos. |
| `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` | obligatorio | Token inicial de administración. |

El modo `setup` solo actúa si la base está vacía. En arranques posteriores conserva los datos y los usuarios existentes.

## Estructura

```text
Organización: seriot
Bucket:       datos
Retención:    30d
Medición:     energia
Campos:       voltaje, corriente, potencia, energia, frecuencia
```

## Consultas de referencia

Último registro:

```flux
from(bucket: "datos")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "energia")
  |> last()
```

Promedio de tensión por minuto:

```flux
from(bucket: "datos")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "energia" and r._field == "voltaje")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

Energía acumulada:

```flux
from(bucket: "datos")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energia" and r._field == "energia")
  |> last()
```

## Consulta desde la CLI

```bash
docker compose exec -T influxdb influx query \
  'from(bucket:"datos") |> range(start:-1h) |> filter(fn:(r) => r._measurement == "energia") |> last()' \
  --org seriot --token "$INFLUXDB_TOKEN"
```

## Tokens

- El token de `.env` se usa para la inicialización y para Node-RED.
- Para Grafana se recomienda un token de solo lectura sobre `datos`.
- Para respaldos se recomienda un token con permisos de lectura de metadatos.
- No publique tokens en capturas, registros ni commits.

Creación de un token con permisos acotados:

1. Abra <http://localhost:8086>.
2. Vaya a **Load Data → API Tokens**.
3. Seleccione **Generate API Token → Custom API Token**.
4. Asigne lectura y escritura solo al bucket `datos`.
5. Copie el token y guárdelo en un lugar seguro.

## Retención

El valor `30d` define cuánto tiempo se conservan los datos. Para cambiarlo:

1. Edite `INFLUXDB_RETENTION` en `.env`.
2. Actualice la retención del bucket desde la interfaz o con la CLI.
3. Reinicie el servicio.

```bash
docker compose up -d influxdb
```

La retención no afecta los datos ya escritos hasta que el motor aplica la política. Planifique la capacidad de disco según el periodo de muestreo y el número de variables.

## Respaldo y restauración

Respaldo con el stack detenido:

```bash
docker compose stop influxdb
tar -czf backups/influxdb-$(date +%Y%m%d).tar.gz data/influxdb
docker compose start influxdb
```

Restauración:

```bash
docker compose stop influxdb
tar -xzf backups/influxdb-20261120.tar.gz
docker compose start influxdb
```

Para respaldos en caliente use la CLI oficial:

```bash
docker compose exec -T influxdb influx backup /tmp/influx-backup --token "$INFLUXDB_TOKEN"
docker compose cp influxdb:/tmp/influx-backup ./backups/influx-backup
```

## Recrear la base desde cero

> Esta operación elimina todos los datos y tokens.

```bash
docker compose down
rm -rf data/influxdb
docker compose up -d influxdb
```

Al arrancar con `DOCKER_INFLUXDB_INIT_MODE=setup`, InfluxDB vuelve a crear la organización, el bucket y el token definidos en `.env`.

## Verificación

```bash
curl http://localhost:8086/health
docker compose logs --tail=50 influxdb
```

La respuesta de salud debe incluir `"status":"pass"`. Si el contenedor reinicia en bucle, revise las variables obligatorias y los permisos de `data/influxdb`.
