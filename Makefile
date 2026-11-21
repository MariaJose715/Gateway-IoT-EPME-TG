.PHONY: help up down restart ps logs test verify backup clean

help:
	@echo "Gateway IoT EPME-TG"
	@echo ""
	@echo "  make up       Levanta el stack Docker"
	@echo "  make down     Detiene y elimina los contenedores"
	@echo "  make restart  Reinicia el stack"
	@echo "  make ps       Muestra el estado de los servicios"
	@echo "  make logs     Sigue los registros de Node-RED"
	@echo "  make test     Ejecuta las pruebas de Python"
	@echo "  make verify   Verifica el estado del stack y los servicios"
	@echo "  make backup   Comprime la carpeta data/"
	@echo "  make clean    Detiene el stack y elimina contenedores y volúmenes"

up:
	@test -f .env || (echo "Falta .env. Copie .env.example y configure sus credenciales." && exit 1)
	docker compose up -d
	@echo ""
	@echo "Node-RED: http://localhost:1880"
	@echo "InfluxDB: http://localhost:8086"
	@echo "Grafana:  http://localhost:3000"

down:
	docker compose down

restart:
	docker compose restart

ps:
	docker compose ps

logs:
	docker compose logs -f nodered

test:
	python -m pytest -q

verify:
	bash scripts/verify.sh

backup:
	bash scripts/backup.sh

clean:
	docker compose down -v
