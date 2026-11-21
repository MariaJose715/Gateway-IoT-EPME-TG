# Política de seguridad

## Versiones soportadas

| Versión | Soporte |
|---|---|
| 1.0.x | Sí |

## Reportar una vulnerabilidad

No publique vulnerabilidades, credenciales ni datos sensibles en los *issues*
públicos. Utilice el reporte privado de vulnerabilidades de GitHub:

1. Abra la pestaña **Security** del repositorio.
2. Seleccione **Report a vulnerability**.
3. Describa el impacto, los pasos para reproducirlo y una propuesta de
   mitigación.

## Buenas prácticas incluidas

- El archivo `.env` está excluido del control de versiones.
- Los tokens y contraseñas se inyectan por variables de entorno.
- El flujo de Node-RED no incluye `flows_cred.json`.
- La configuración de Mosquitto para producción usa autenticación, ACL y TLS.
- Los servicios se ejecutan con políticas de reinicio y *healthchecks*.

## Si sospecha una exposición

1. Rote el token de InfluxDB y las contraseñas de Grafana/InfluxDB.
2. Revise los registros de acceso de Mosquitto y Grafana.
3. Elimine las credenciales del historial de Git si fueron confirmadas.
4. Abra un reporte privado de seguridad.
