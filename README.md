# MVP Fintech: Credit Application System

Este proyecto es un MVP para un sistema de solicitudes de crédito internacional, diseñado con una arquitectura moderna, escalable y en tiempo real.

## 🚀 Arquitectura Técnica

### Backend (Ruby on Rails 8)
- **API-Only**: Diseñada para máxima eficiencia y desacoplamiento.
- **Patrón Strategy**: Implementado para manejar lógica de validación específica por país (ES, PT, IT, MX, CO, BR) de forma dinámica.
- **Solid Suite**:
  - **Solid Queue**: Procesamiento de evaluaciones de riesgo en segundo plano.
  - **Solid Cable**: Notificaciones en tiempo real vía WebSockets.
  - **Solid Cache**: Gestión de caché persistente en base de datos.
- **PostgreSQL**: Uso de múltiples bases de datos/schemas para separar datos primarios, colas y caché.
- **Audit Logs**: Registro automático de cambios de estado mediante Triggers de base de datos a nivel de motor.

### Frontend (Angular 21)
- **SPA Moderna**: Uso de Signals para reactividad y estado optimizado.
- **ActionCable Integration**: Notificaciones en tiempo real integradas para actualizar el estado de las solicitudes sin recargar.
- **Premium UI**: Diseño limpio, tarjetas informativas y línea de tiempo de auditoría.

## 🛠 Instalación y Gestión (Makefile)

### Primer uso (después de clonar)

> 💡 El archivo `api/config/master.key` no está en el repositorio por seguridad. Genera uno nuevo con el siguiente comando antes de hacer cualquier otra cosa:

```bash
# 1. Generar master.key y credenciales de Rails (solo la primera vez)
make setup-credentials

# 2. Instalar dependencias del backend y frontend
make setup

# 3. Iniciar el ecosistema completo (API + Worker + Angular)
make start
```

### Comandos disponibles

```bash
make setup-credentials  # Genera master.key y credenciales de Rails si no existen
make setup              # Instala dependencias (llama a setup-credentials automáticamente)
make start              # Inicia API + Worker + Angular simultáneamente
make stop               # Detiene todos los procesos locales
make build-images       # Construye las imágenes Docker (api y frontend)
make k8s-deploy         # Despliega todo el stack a Kubernetes
make help               # Muestra todos los comandos disponibles con descripción
```

## ☸️ Despliegue en Kubernetes (Sección 4.8)

Los manifiestos se encuentran en la carpeta `/k8s/`. La estructura completa es:

```
k8s/
├── configmap.yaml     → Variables de entorno compartidas (RAILS_ENV, DATABASE_URL, etc.)
├── secrets.yaml       → Plantilla de referencia de Secrets (solo para documentación)
├── postgres-pvc.yaml  → PersistentVolumeClaim para datos de PostgreSQL (5Gi)
├── postgres.yaml      → Deployment + Service de la Base de Datos
├── api.yaml           → Deployment + Service del Backend (Rails API, 2 réplicas)
├── worker.yaml        → Deployment del Worker de Background (Solid Queue)
├── frontend.yaml      → Deployment + Service del Frontend (Angular/Nginx)
└── ingress.yaml       → Ingress con rutas diferenciadas y soporte WebSocket
```

### Variables de entorno y configuración

| Recurso | Tipo | Descripción |
|---|---|---|
| `app-config` (ConfigMap) | No sensible | `RAILS_ENV`, `DATABASE_URL`, `PORT`, etc. |
| `rails-secrets` (Secret) | Sensible | `RAILS_MASTER_KEY` para descifrar credenciales |
| `postgres-secrets` (Secret) | Sensible | Password de PostgreSQL |

> **⚠️ IMPORTANTE:** El archivo `secrets.yaml` incluido en el repositorio es solo una **plantilla de referencia** con valores placeholder. Nunca subas el `master.key` ni passwords reales al repositorio. Los secretos deben crearse manualmente en el cluster con los comandos de abajo.

### Prerrequisitos

- Docker Desktop con Kubernetes habilitado (o cualquier cluster K8s)
- `kubectl` configurado y apuntando al cluster correcto
- Imágenes Docker construidas localmente:

```bash
make build-images
```

### Paso 1 — Crear los Secrets en el cluster *(solo una vez)*

> ⚠️ Este paso es **obligatorio** antes de cualquier despliegue. Los pods no iniciarán sin los secretos.

```bash
# Crear el secreto de Rails con el master.key real (descifra las credenciales)
MASTER_KEY=$(cat api/config/master.key) && \
kubectl create secret generic rails-secrets \
  --from-literal=master-key="$MASTER_KEY"

# Crear el secreto de PostgreSQL
kubectl create secret generic postgres-secrets \
  --from-literal=postgres-password=TU_PASSWORD_SEGURA
```

> 💡 **¿Por qué este paso falla sin esto?**
> Rails necesita el `RAILS_MASTER_KEY` para desencriptar `config/credentials.yml.enc` y obtener el `secret_key_base`. Si el secreto está vacío o no existe, Rails lanza: `Missing secret_key_base for 'production' environment`.

### Paso 2 — Desplegar todo el stack

```bash
make k8s-deploy
```

Esto aplica los manifiestos en el orden correcto:
1. ConfigMap (variables de entorno)
2. PersistentVolumeClaim (almacenamiento de datos)
3. PostgreSQL (base de datos)
4. API Rails (backend)
5. Worker (procesamiento en background)
6. Frontend (Angular/Nginx)
7. Ingress (rutas y WebSockets)

### Paso 3 — Verificar el estado

```bash
kubectl get pods        # Ver estado de los pods
kubectl get services    # Ver servicios y puertos
kubectl get ingress     # Ver reglas de Ingress
kubectl logs -l app=api # Ver logs del backend
```

### Consideraciones especiales

- **WebSockets (ActionCable)**: El `ingress.yaml` incluye anotaciones para mantener conexiones `Upgrade` activas, necesarias para las notificaciones en tiempo real.
- **PersistentVolumeClaim**: PostgreSQL usa un PVC de 5Gi para que los datos persistan entre reinicios del pod.
- **Health Checks**: La API tiene `readinessProbe` y `livenessProbe` en `/up` para que el tráfico no llegue a pods no listos.
- **Resource Limits**: Todos los pods tienen `requests` y `limits` definidos para scheduling predecible y estabilidad del cluster.
- **Hosts de Ingress**: Por defecto están configurados como `fintech.example.com` y `api.fintech.example.com`. En producción, debes apuntar tu DNS a la IP del Ingress Controller.

---

## 📝 Reglas de Negocio Implementadas
- **España (ES)**: Validación de DNI. Revisión manual si el monto > 50,000€.
- **Portugal (PT)**: Validación de NIF. Rechazo automático si el monto solicitado excede el 10% de los ingresos.
- **Italia (IT)**: Validación de Codice Fiscale. Reglas de estabilidad financiera.
- **México (MX)**: Validación de CURP. Evaluación de ratio deuda/ingreso.
- **Colombia (CO)**: Validación de CC. Verificación de capacidad de endeudamiento.
- **Brasil (BR)**: Validación de CPF. Integración con mock de score financiero.

---
Desarrollado para el desafío técnico GlobalTask.
