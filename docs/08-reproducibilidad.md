# 08 · Reproducibilidad

[← Anterior: Seguridad](07-seguridad.md) · [Volver al README](../README.md)

## 8.1 Definición

Un despliegue es reproducible cuando otra persona puede obtener el mismo resultado siguiendo los archivos del repositorio, sin depender de configuraciones manuales ocultas. En este proyecto la reproducibilidad se apoya en:

- un `docker-compose.yml` con versiones de imagen fijadas;
- un `.env.example` con todas las variables necesarias;
- un flujo de Node-RED exportado;
- una fuente de datos y un dashboard de Grafana aprovisionados;
- scripts de arranque, verificación y respaldo;
- pruebas automatizadas de Modbus y del payload;
- un plan de pruebas y evidencias verificables.

## 8.2 Requisitos mínimos

| Recurso | Valor |
|---|---|
| Sistema operativo | Windows 10/11 con WSL2, macOS o Linux. |
| Docker | 24 o superior. |
| Docker Compose | v2.20 o superior. |
| Memoria | 4 GB libres. |
| Disco | 10 GB libres. |
| Red | Acceso a Internet para descargar imágenes. |
| Git | 2.30 o superior. |
| Python | 3.10 o superior (solo pruebas). |

## 8.3 Procedimiento en un equipo limpio

### Paso 1 · Obtener el código

```bash
git clone https://github.com/MariaJose715/Gateway-IoT-EPME-TG.git
cd Gateway-IoT-EPME-TG
```

### Paso 2 · Crear el entorno

```bash
cp .env.example .env
```

Edite `.env` y defina:

- `INFLUXDB_ADMIN_PASSWORD`
- `INFLUXDB_TOKEN`
- `GRAFANA_ADMIN_PASSWORD`

Mantenga `INFLUXDB_ORG=seriot` y `INFLUXDB_BUCKET=datos` para que coincidan con el dashboard y el flujo.

### Paso 3 · Levantar los servicios

```bash
docker compose up -d
docker compose ps
```

### Paso 4 · Instalar el nodo de InfluxDB en Node-RED

1. Abra <http://localhost:1880>.
2. **Manage palette → Install**.
3. Instale `node-red-contrib-influxdb`.
4. Abra el nodo **Escribir InfluxDB** y configure URL, organización, bucket y token.
5. Pulse **Deploy**.

### Paso 5 · Publicar una muestra

```bash
bash scripts/publish-test.sh
```

### Paso 6 · Verificar InfluxDB

```bash
docker compose exec -T influxdb influx query \
  'from(bucket:"datos") |> range(start:-1h) |> filter(fn:(r) => r._measurement == "energia") |> last()' \
  --org seriot --token "$INFLUXDB_TOKEN"
```

### Paso 7 · Verificar Grafana

1. Abra <http://localhost:3000>.
2. Ingrese con las credenciales de `.env`.
3. Abra **SerIoT → SerIoT · Medidor Eastron SDM630MCT-RC**.
4. Confirme que los paneles muestren la muestra publicada.

### Paso 8 · Ejecutar las pruebas

```bash
python -m pip install -r tests/requirements.txt
python -m pytest -q
```

### Paso 9 · Ejecutar la verificación integral

```bash
bash scripts/verify.sh
```

### Paso 10 · Registrar el resultado

Actualice `evidence/logs/` con la salida de su entorno y compare con [`06-resultados.md`](06-resultados.md).

## 8.4 Verificación automatizada

| Verificación | Comando | Resultado esperado |
|---|---|---|
| Pruebas unitarias | `python -m pytest -q` | Todas las pruebas pasan. |
| JSON del dashboard | `python -m json.tool config/grafana/dashboards/seriot-main.json` | JSON válido. |
| Flujo de Node-RED | `python -m json.tool config/nodered/flows.json` | JSON válido. |
| Compose | `docker compose config` | Configuración resuelta sin errores. |
| Scripts | `bash -n scripts/*.sh` | Sin errores de sintaxis. |
| Stack | `docker compose ps` | Cuatro servicios activos. |
| Salud | `bash scripts/verify.sh` | Servicios disponibles y mensaje publicado. |

El flujo de integración continua de GitHub Actions ejecuta las pruebas y las validaciones de JSON y Compose en cada push a `main` y en cada *pull request*. El archivo está en [`.github/workflows/ci.yml`](../.github/workflows/ci.yml).

## 8.5 Resultados esperados

| Elemento | Valor esperado |
|---|---|
| Contenedores activos | 4 |
| Broker MQTT | Mensaje de prueba recibido |
| InfluxDB | Registro consultable en `datos` |
| Grafana | Dashboard con datos |
| Pruebas unitarias | 14 aprobadas |
| Latencia de referencia | 1,8 s promedio |
| Continuidad de referencia | 99,7 % |

Los valores de latencia y continuidad dependen de la red y del entorno; los criterios de aceptación se mantienen.

## 8.6 Archivos necesarios

```text
docker-compose.yml
.env.example
config/
  mosquitto/
  nodered/flows.json
  grafana/
scripts/
tests/
docs/
diagrams/
evidence/
report/
```

No son necesarios para reproducir el stack:

- `data/` (se crea al arrancar);
- `backups/` (se crea al respaldar);
- `.env` (se crea a partir de la plantilla);
- `flows_cred.json` (se genera al configurar credenciales en Node-RED).

## 8.7 Checklist de reproducibilidad

- [ ] Repositorio clonado en un equipo sin el stack instalado.
- [ ] Docker y Docker Compose disponibles.
- [ ] `.env` creado con credenciales propias.
- [ ] `docker compose up -d` exitoso.
- [ ] Cuatro servicios activos.
- [ ] `node-red-contrib-influxdb` instalado.
- [ ] Nodo de InfluxDB configurado y flujo desplegado.
- [ ] Mensaje de prueba visible en InfluxDB.
- [ ] Dashboard con datos.
- [ ] Pruebas unitarias aprobadas.
- [ ] `scripts/verify.sh` sin errores.
- [ ] Evidencias actualizadas.

## 8.8 Diferencias entre laboratorio y producción

| Aspecto | Laboratorio | Producción |
|---|---|---|
| Exposición del broker | Túnel TCP temporal. | VPS con IP fija y FRP. |
| Seguridad MQTT | Anónima. | Autenticación, ACL y TLS. |
| Puertos de administración | Publicados en el host. | Restringidos por VPN o proxy. |
| Respaldos | Manuales. | Programados y monitoreados. |
| Actualizaciones | Según necesidad. | Ventana de mantenimiento. |
| Monitoreo | Dashboard. | Dashboard, alertas y registros. |

El procedimiento de laboratorio sirve para validar la arquitectura. Antes de pasar a producción, aplique el checklist de [`07-seguridad.md`](07-seguridad.md).

## 8.9 Versionado y mantenimiento

- Etiquete las versiones estables con `git tag -a v1.0.0 -m "Versión validada"`.
- Publique las versiones en GitHub Releases junto con el informe.
- Registre los cambios en `CHANGELOG.md` si el repositorio evoluciona.
- Mantenga las imágenes fijadas y actualice en una rama de prueba.
- Repita el plan de pruebas después de cada actualización relevante.

## 8.10 Licencia y cita

- Código y configuraciones: licencia MIT ([`LICENSE`](../LICENSE)).
- Documentación, diagramas e informe: CC BY 4.0 ([`LICENSE-DOCS.md`](../LICENSE-DOCS.md)).
- Cita del proyecto: [`CITATION.cff`](../CITATION.cff).

---

Si encuentra una diferencia entre el resultado esperado y el obtenido, revise los registros de los contenedores, la configuración de `.env` y la versión de las imágenes antes de modificar el código.
