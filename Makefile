# Makefile para gestión del MVP Fintech

.PHONY: setup setup-credentials start-api start-frontend stop build-images k8s-deploy k8s-secrets help

setup: setup-credentials ## Instalar dependencias de API y Frontend (genera credenciales si no existen)
	@cd api && bundle install && bin/rails db:prepare
	@cd frontend && npm install

setup-credentials: ## Generar master.key y credenciales de Rails (ejecutar si no tienes master.key)
	@if [ ! -f "api/config/master.key" ]; then \
		echo "⚙️  Generando master.key y credenciales de Rails..."; \
		openssl rand -hex 32 > api/config/master.key; \
		SECRET_KEY=$$(openssl rand -hex 64) && \
		cd api && RAILS_MASTER_KEY=$$(cat config/master.key) EDITOR="true" bundle exec rails credentials:edit && \
		echo "✅ Credenciales generadas en api/config/master.key"; \
	else \
		echo "✅ master.key ya existe, no se requiere acción."; \
	fi

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

k8s-secrets: ## Crear el secreto rails-secrets desde el master.key local
	@echo "Creando secreto rails-secrets..."
	@kubectl create secret generic rails-secrets --from-literal=master-key=$(cat api/config/master.key) --dry-run=client -o yaml | kubectl apply -f -

k8s-deploy: k8s-secrets ## Desplegar a Kubernetes (Incluye creación de secretos)
	kubectl apply -f k8s/postgres.yaml
	kubectl apply -f k8s/api.yaml
	kubectl apply -f k8s/worker.yaml
	kubectl apply -f k8s/frontend.yaml

help: ## Mostrar esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
