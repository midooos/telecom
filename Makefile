# Raccourcis (macOS / Linux / WSL). Sous Windows sans make : utiliser les tâches VS Code
# (Ctrl+Shift+P -> "Tasks: Run Task") qui exécutent les mêmes commandes.
.PHONY: help up airflow ps logs down reset

help:
	@echo "make up       - démarre Postgres, Kafka, Debezium, MinIO"
	@echo "make airflow  - démarre aussi Airflow (http://localhost:8081, admin/admin)"
	@echo "make ps       - état des conteneurs"
	@echo "make logs     - logs de tous les services"
	@echo "make down     - arrête tout"
	@echo "make reset    - arrête tout ET efface les volumes (repart de zéro)"

up:
	docker compose up -d

airflow:
	docker compose --profile airflow up -d --build

ps:
	docker compose --profile airflow ps

logs:
	docker compose logs -f

down:
	docker compose --profile airflow down

reset:
	docker compose --profile airflow down -v
