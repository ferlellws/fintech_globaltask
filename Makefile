# Makefile para gestión del MVP Fintech

.DEFAULT_GOAL := all

.PHONY: all build-images k8s-deploy help

all: clean build-images k8s-deploy ## Construir imágenes y desplegar en Kubernetes

build-images: ## Construir imágenes Docker localmente
	docker build -t fintech-api ./api
	docker build -t fintech-frontend ./frontend

k8s-deploy: ## Desplegar todo el stack a Kubernetes en el orden correcto
	kubectl apply -f k8s/

clean: ## Limpiar recursos de Kubernetes
	kubectl delete -f k8s/
	docker rmi fintech-api fintech-frontend

help: ## Mostrar esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
