# Cómo contribuir

Gracias por su interés en el proyecto **Gateway IoT EPME-TG**.

## Reportar un problema

1. Revise los *issues* existentes para evitar duplicados.
2. Abra un *issue* con:
   - sistema operativo y versión de Docker;
   - versión de los servicios (`docker compose ps`);
   - pasos para reproducir el problema;
   - salida de `docker compose logs` (sin credenciales ni datos personales).

## Proponer un cambio

1. Cree una rama descriptiva:
   ```bash
   git checkout -b feat/nombre-corto
   ```
2. Mantenga los cambios enfocados y documentados.
3. Ejecute las pruebas:
   ```bash
   python -m pytest -q
   ```
4. Verifique que no se incluyan secretos:
   ```bash
   git diff --cached | Select-String -Pattern "token|password|secret"
   ```
5. Abra un *pull request* describiendo el problema, la solución y las pruebas
   realizadas.

## Estilo

- Español para documentación y nombres de archivos.
- Mensajes de commit claros, por ejemplo:
  - `feat: agrega verificación de salud del broker`
  - `docs: corrige el mapa de registros Modbus`
  - `fix: evita división por cero en el cálculo de potencia`
- No incluya credenciales, tokens, direcciones IP privadas ni datos personales.

## Licencia

Al contribuir, acepta que su aporte se publique bajo la licencia MIT para el
código y CC BY 4.0 para la documentación.
