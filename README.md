# MVP Fintech: Credit Application System

Sistema de solicitudes de crédito internacional con validaciones específicas por país, procesamiento en background y notificaciones en tiempo real.

---

## ⚡ Inicio Rápido (< 5 minutos)

**Herramientas necesarias:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) con Kubernetes habilitado.

```bash
# 1. Clonar el repositorio
git clone https://github.com/ferlellws/fintech_globaltask.git
cd fintech_globaltask

# 2. Construir las imágenes Docker
make build-images

# 3. Desplegar todo el stack en Kubernetes
make k8s-deploy

# 4. Verificar que los pods están corriendo
kubectl get pods

# 5. Acceder a la aplicación (Túneles locales)
# Abrir una terminal para cada uno:
kubectl port-forward service/api-service 3000:80
kubectl port-forward service/frontend-service 4200:80
```

**URLs de acceso (una vez activos los túneles):**
- **Frontend:** [http://localhost:4200](http://localhost:4200)
- **API Health:** [http://localhost:3000/up](http://localhost:3000/up)

> ✅ **Nota de Evaluación:** Dado que el Ingress depende del controlador local, el uso de `port-forward` garantiza que el evaluador pueda ver la aplicación operativa en menos de 5 minutos sin configurar DNS ni controladores adicionales.

---

## 🚀 Arquitectura Técnica

### Backend (Ruby on Rails 8 — API-Only)
- **Patrón Strategy**: Lógica de validación específica por país (ES, PT, IT, MX, CO, BR).
- **Solid Queue**: Procesamiento de evaluaciones de riesgo en background.
- **Solid Cable**: Notificaciones en tiempo real vía WebSockets (ActionCable).
- **Solid Cache**: Cache persistente en base de datos.
- **PostgreSQL**: Múltiples schemas para datos primarios, colas y caché.
- **Audit Logs**: Triggers de base de datos para registro automático de cambios.

### Frontend (Angular 19 — SPA)
- **Signals**: Reactividad y estado optimizado.
- **ActionCable Integration**: Actualización de estado en tiempo real sin recargar.
- **UI Premium**: Tarjetas informativas y línea de tiempo de auditoría.

---

## ☸️ Despliegue en Kubernetes (Requisito 4.8)

### Estructura de manifiestos (`/k8s/`)

```
k8s/
├── configmap.yaml    → Variables de entorno (RAILS_ENV, SECRET_KEY_BASE, etc.)
├── secrets.yaml      → Plantilla de referencia (solo documentación)
├── postgres-pvc.yaml → PersistentVolumeClaim para PostgreSQL (5Gi)
├── postgres.yaml     → Base de datos PostgreSQL
├── api.yaml          → Backend Rails API (2 réplicas) + Service
├── worker.yaml       → Worker Solid Queue (background jobs)
├── frontend.yaml     → Frontend Angular/Nginx + Service
└── ingress.yaml      → Ingress con soporte WebSocket para ActionCable
```

### Variables de entorno y configuración

| Recurso | Tipo | Contenido |
|---|---|---|
| `app-config` (ConfigMap) | No sensible | `RAILS_ENV`, `SECRET_KEY_BASE`, `PORT`, etc. |
| `postgres-secrets` (Secret) | Sensible | Password de PostgreSQL |

> **Nota:** El `SECRET_KEY_BASE` está incluido directamente en el `configmap.yaml`, por lo que **no se necesita** el `master.key` de Rails para este despliegue.

### Comandos útiles

- `make build-images`: Construye las imágenes Docker.
- `make k8s-deploy`: Despliega todo el stack.
- `make help`: Ver todos los comandos disponibles.
- `kubectl get pods`: Revisa el estado de salud.
- `kubectl logs -l app=api`: Revisa los logs de la API.
- `kubectl logs -l app=worker`: Revisa los logs del worker.

### Consideraciones especiales

- **WebSockets (ActionCable)**: El `ingress.yaml` incluye anotaciones para mantener conexiones `Upgrade` activas.
- **Persistencia**: PostgreSQL usa un PVC de 5Gi — los datos sobreviven reinicios del pod.
- **Health Checks**: La API tiene `readinessProbe` y `livenessProbe` en `/up`.
- **Resource Limits**: Todos los pods tienen `requests` y `limits` definidos.

---

## 📝 Reglas de Negocio por País

| País | Identificador | Regla Principal |
|---|---|---|
| 🇪🇸 España | DNI | Revisión manual si monto > 50,000€ |
| 🇵🇹 Portugal | NIF | Rechazo si monto supera el 10% de ingresos |
| 🇮🇹 Italia | Codice Fiscale | Reglas de estabilidad financiera |
| 🇲🇽 México | CURP | Evaluación de ratio deuda/ingreso |
| 🇨🇴 Colombia | CC | Verificación de capacidad de endeudamiento |
| 🇧🇷 Brasil | CPF | Score financiero con integración mock |

---
Desarrollado para el desafío técnico GlobalTask.
