# 07 · Seguridad

[← Anterior: Resultados](06-resultados.md) · [Siguiente: Reproducibilidad →](08-reproducibilidad.md)

## 7.1 Principios

- **Mínima exposición.** Solo el broker debe ser accesible desde la red del gateway; los servicios de administración quedan en la red local o en una VPN.
- **Mínimo privilegio.** Cada usuario y token tiene acceso únicamente a los tópicos y buckets que necesita.
- **Secretos fuera del repositorio.** Contraseñas, tokens, certificados y `flows_cred.json` no se versionan.
- **Capas de defensa.** Autenticación, ACL, TLS, respaldos y actualizaciones se aplican en conjunto.
- **Trazabilidad.** Los accesos y los cambios de configuración se registran y se revisan.

## 7.2 Laboratorio vs. producción

| Control | Laboratorio | Producción |
|---|---|---|
| Autenticación MQTT | Anónima (`allow_anonymous true`). | Usuario y contraseña obligatorios. |
| ACL | No aplica. | Lista por usuario y tópico. |
| TLS | No. | Puerto 8883 con certificado válido. |
| Puertos publicados | Todos, para demostración. | Solo 8883; administración por VPN o proxy. |
| Contraseñas | Valores de ejemplo en `.env`. | Valores aleatorios y rotación periódica. |
| Respaldos | Manuales. | Programados y verificados. |
| Registros | Nivel informativo. | Retención y revisión periódica. |

La configuración incluida en [`config/mosquitto/mosquitto.conf`](../config/mosquitto/mosquitto.conf) es de **laboratorio**. La variante de producción está en [`config/mosquitto/mosquitto.prod.conf.example`](../config/mosquitto/mosquitto.prod.conf.example).

## 7.3 Gestión de secretos

| Secreto | Ubicación | Rotación |
|---|---|---|
| Contraseña de InfluxDB | `.env` | Cada 90 días o ante sospecha. |
| Token de InfluxDB | `.env` y nodo de Node-RED | Cada 90 días; token separado por servicio. |
| Contraseña de Grafana | `.env` | Cada 90 días. |
| Contraseña MQTT | `config/mosquitto/passwd` | Cada 90 días. |
| Clave TLS | `config/mosquitto/certs/server.key` | Según la vigencia del certificado. |

Reglas:

1. `.env` nunca se sube al repositorio; `.gitignore` lo excluye.
2. `flows_cred.json` se omite porque contiene credenciales serializadas de Node-RED.
3. Los certificados (`*.pem`, `*.key`, `*.crt`, `*.p12`) están excluidos.
4. No se imprimen tokens en capturas, registros o mensajes de commit.
5. Si un secreto se expone, se rota de inmediato y se revisa el historial de Git.

## 7.4 Autenticación y ACL en Mosquitto

Genere el archivo de contraseñas con la imagen oficial:

```bash
docker run --rm -it \
  -v "$PWD/config/mosquitto:/mosquitto/config" \
  eclipse-mosquitto:2.0 \
  mosquitto_passwd -c /mosquitto/config/passwd seriot-gateway
```

Agregue el usuario de Node-RED:

```bash
docker run --rm -it \
  -v "$PWD/config/mosquitto:/mosquitto/config" \
  eclipse-mosquitto:2.0 \
  mosquitto_passwd /mosquitto/config/passwd seriot-nodered
```

Copie la lista de control de acceso:

```bash
cp config/mosquitto/aclfile.example config/mosquitto/aclfile
```

Contenido de referencia:

```text
user seriot-gateway
topic write datos
topic read $SYS/broker/version
```

Active la configuración de producción:

```bash
cp config/mosquitto/mosquitto.prod.conf.example config/mosquitto/mosquitto.conf
docker compose restart mosquitto
```

Ajuste las credenciales del gateway y del nodo MQTT de Node-RED. Verifique que un cliente anónimo sea rechazado:

```bash
docker compose exec -T mosquitto mosquitto_pub -h localhost -t datos -m "prueba"
```

El comando debe fallar con `Connection Refused: not authorised`.

## 7.5 TLS

Para un despliegue permanente utilice un certificado emitido por una autoridad confiable (Let's Encrypt, la CA institucional o el proveedor del VPS). Para pruebas locales puede generar un certificado autofirmado:

```bash
mkdir -p config/mosquitto/certs

openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout config/mosquitto/certs/server.key \
  -out config/mosquitto/certs/server.crt \
  -subj "/CN=seriot.local" \
  -addext "subjectAltName=DNS:seriot.local,IP:192.168.1.10"
```

Proteja la clave:

```bash
chmod 600 config/mosquitto/certs/server.key
```

Publique el puerto 8883 en `docker-compose.yml`:

```yaml
ports:
  - "8883:8883"
```

Rutas esperadas por la configuración de producción:

```text
/mosquitto/config/certs/ca.crt
/mosquitto/config/certs/server.crt
/mosquitto/config/certs/server.key
```

Si el gateway valida el certificado, importe la CA o use un certificado de una autoridad pública cuyo nombre coincida con el host del servidor. Evite desactivar la verificación TLS en producción.

Compruebe la conexión:

```bash
docker compose exec -T mosquitto mosquitto_pub \
  -h localhost -p 8883 --cafile /mosquitto/config/certs/ca.crt \
  -t datos -m "prueba tls"
```

## 7.6 Exposición de puertos

| Servicio | Puerto | Recomendación |
|---|---|---|
| Mosquitto MQTT | `1883` | Solo red interna o VPN; migrar a 8883 con TLS. |
| Mosquitto WebSockets | `9001` | Red interna o proxy con TLS. |
| Node-RED | `1880` | No exponer; acceso por VPN. |
| InfluxDB | `8086` | No exponer; acceso por VPN. |
| Grafana | `3000` | Publicar por reverse proxy con HTTPS y autenticación. |

Ejemplo de proxy inverso para Grafana (Nginx):

```nginx
server {
    listen 443 ssl;
    server_name grafana.example.org;

    ssl_certificate     /etc/letsencrypt/live/grafana.example.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/grafana.example.org/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 7.7 Tokens de InfluxDB

- Use un token distinto para Node-RED (escritura) y para Grafana (lectura).
- Restrinja cada token a la organización `seriot` y al bucket `datos`.
- No use el token de administrador en los clientes.
- Rote el token si aparece en un registro, una captura o un commit.

Creación desde la interfaz:

1. Abra **Load Data → API Tokens**.
2. Seleccione **Generate API Token → Custom API Token**.
3. Asigne lectura y escritura solo al bucket `datos`.
4. Copie el token una única vez y guárdelo en `.env`.

## 7.8 Grafana

- Cambie la contraseña de administrador en el primer ingreso.
- Mantenga `GF_USERS_ALLOW_SIGN_UP=false`.
- Cree usuarios con rol **Viewer** para consulta y **Editor** solo para administración.
- Publique Grafana detrás de HTTPS.
- Desactive el acceso anónimo si se habilita en el futuro.
- Revise los registros de inicio de sesión.

La contraseña se define en `.env` como `GRAFANA_ADMIN_PASSWORD`. Si se cambia, actualice la variable y reinicie el servicio:

```bash
docker compose up -d grafana
```

## 7.9 Respaldos

Detenga el stack para obtener una copia consistente:

```bash
docker compose stop
bash scripts/backup.sh
docker compose start
```

El script genera `backups/seriot-AAAAMMDD-HHMMSS.tar.gz` con `data/` y `config/`. No incluye `.env`; guárdelo en un gestor de secretos.

Restauración:

```bash
docker compose down
tar -xzf backups/seriot-AAAAMMDD-HHMMSS.tar.gz
docker compose up -d
```

Verifique después de restaurar:

```bash
docker compose ps
bash scripts/verify.sh
```

Programe respaldos diarios o semanales según el volumen de datos y conserve al menos dos generaciones.

## 7.10 Actualizaciones

- Las imágenes están fijadas por versión en `docker-compose.yml`.
- Antes de actualizar, cree un respaldo y revise las notas de la versión.
- Actualice en un entorno de pruebas y repita el plan de pruebas.
- Revise periódicamente las vulnerabilidades reportadas para las imágenes base.
- No actualice en producción sin una ventana de mantenimiento.

```bash
docker compose pull
docker compose up -d
docker compose ps
```

## 7.11 Checklist de endurecimiento

- [ ] Mosquitto con `allow_anonymous false`.
- [ ] Archivo `passwd` generado y con permisos restringidos.
- [ ] ACL aplicada por usuario y tópico.
- [ ] TLS habilitado en el puerto 8883.
- [ ] Certificado vigente y con nombre correcto.
- [ ] Puertos 1880, 8086 y 3000 no expuestos a Internet.
- [ ] Grafana detrás de HTTPS.
- [ ] Token de InfluxDB con mínimo privilegio.
- [ ] Contraseñas y tokens fuera de Git.
- [ ] `flows_cred.json` ausente del repositorio.
- [ ] Respaldos programados y restauración probada.
- [ ] Registros revisados periódicamente.
- [ ] Plan de rotación de credenciales documentado.

## 7.12 Reporte de vulnerabilidades

No publique vulnerabilidades, credenciales ni datos sensibles en los *issues* públicos. Use el reporte privado de vulnerabilidades de GitHub descrito en [`SECURITY.md`](../SECURITY.md):

1. Abra la pestaña **Security** del repositorio.
2. Seleccione **Report a vulnerability**.
3. Describa el impacto, los pasos para reproducirlo y una propuesta de mitigación.
