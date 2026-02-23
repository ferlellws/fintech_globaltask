# Makefile para gestión del MVP Fintech

.PHONY: setup start-api start-frontend stop build-images k8s-deploy help

setup: ## Instalar dependencias de API y Frontend
	@cd api && bundle install && bin/rails db:prepare
	@cd frontend && npm install

start-api: ## Iniciar el backend (API + Worker)
	@echo "Iniciando API y Worker..."
	@cd api && bin/dev & cd api && bin/jobs

start-frontend: ## Iniciar el frontend (Angular)
	@echo "Iniciando Frontend..."
	@cd frontend && npm start

start: start-api start-frontend ## Iniciar todo el ecosistema localmente

stop: ## Detener procesos locales
	@echo "Deteniendo procesos..."
	@pkill -f "puma" || true
	@pkill -f "solid_queue" || true
	@pkill -f "ng serve" || true

build-images: ## Construir imágenes Docker (Simulado)
	docker build -t fintech-api ./api
	docker build -t fintech-frontend ./frontend

k8s-deploy: ## Desplegar a Kubernetes (Simulado)
	kubectl apply -f k8s/postgres.yaml
	kubectl apply -f k8s/api.yaml
	kubectl apply -f k8s/worker.yaml
	kubectl apply -f k8s/frontend.yaml

help: ## Mostrar esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
