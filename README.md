# MVP Fintech: Credit Application System

Sistema de solicitudes de crédito internacional con validaciones específicas por país, procesamiento en background y notificaciones en tiempo real.

---

## Inicio Rápido (< 5 minutos)

**Herramientas necesarias:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) con Kubernetes habilitado.

```bash
# 1. Clonar el repositorio
git clone https://github.com/ferlellws/fintech_globaltask.git
cd fintech_globaltask

# 2. Construir imágenes y desplegar en Kubernetes
make

# 3. Verificar que los pods están corriendo
kubectl get pods -w

# 4. Acceder a la aplicación (Túneles locales)
# Abrir una terminal para cada uno:
kubectl port-forward service/api-service 3000:80
kubectl port-forward service/frontend-service 4200:80
```

**URLs de acceso (una vez activos los túneles):**
- **Frontend:** [http://localhost:4200](http://localhost:4200)
- **API Health:** [http://localhost:3000/up](http://localhost:3000/up)

---

## Supuestos y Consideraciones

1. **Entorno de Ejecución**: Se asume un cluster de Kubernetes estándar (local o nube) con capacidad para volúmenes persistentes (PVC).
2. **Moneda**: Los montos se manejan en la moneda local del país seleccionado, aunque para efectos de validación se asumen umbrales estandarizados.
3. **Autenticación**: El sistema es abierto para registro de usuarios; no hay roles de administrador predefinidos en este MVP.
4. **Validaciones Externas**: Las integraciones con centrales de riesgo (ej. Datacrédito, ASNEF) son simuladas (mocked) para garantizar la funcionalidad sin dependencias de terceros en la evaluación.

---

## Modelo de Datos

El esquema de base de datos está diseñado para ser robusto y auditable:

- **Users**: Gestión de identidad (email, password_digest).
- **CreditApplications**: Núcleo del sistema.
  - `amount`: Monto solicitado.
  - `country_code`: ISO code (ES, MX, CO, etc.).
  - `status`: Máquina de estados (`pending`, `analyzing`, `approved`, `rejected`, `manual_review`).
  - `document_id`: Identificador nacional único.
- **AuditLogs**: Tabla de auditoría inmutable que registra cambios de estado y eventos críticos.
- **Solid Queue / Cache / Cable**: Tablas internas de Rails 8 para manejo de colas, caché y websockets, eliminando la necesidad de Redis.

---

## Decisiones Técnicas

### Backend: Ruby on Rails 8 (API-Only)
- **Patrón Strategy**: Se implementó para desacoplar las reglas de negocio de cada país. Agregar un nuevo país solo requiere crear una nueva clase Strategy sin tocar el controlador principal.
- **Solid Stack (Queue, Cache, Cable)**: Se eligió la nueva pila por defecto de Rails 8 para simplificar la infraestructura. Al usar PostgreSQL para todo, reducimos la complejidad operativa y los costos de mantenimiento (no se necesita Redis).
- **Service Objects**: La lógica compleja (integración bancaria, evaluación de riesgo) se encapsula en servicios para mantener los controladores "delgados".
- **Estrategia de Webhooks**: Se implementó un endpoint de entrada (`/api/v1/webhooks/bank_update`) que permite integraciones asíncronas con entidades financieras. El sistema valida el `application_id` y actualiza el estado de la solicitud en tiempo real, disparando notificaciones automáticas vía WebSockets a los clientes conectados.

### Frontend: Angular 21 — SPA
- **Signals**: Se utiliza el nuevo sistema de reactividad de Angular para un manejo de estado más eficiente y predecible que `RxJS` en casos simples.
- **Componentes Standalone**: Arquitectura moderna sin `NgModules` para reducir el código repetitivo.
- **Nginx**: Servidor web ligero optimizado para servir la SPA y manejar el enrutamiento del lado del cliente.

---

## Consideraciones de Seguridad

1. **Autenticación Stateless (JWT)**: Uso de JSON Web Tokens para autenticación, permitiendo escalabilidad horizontal sin sesiones en servidor.
2. **Secret Management**: Las credenciales sensibles (DB password, Secret Key Base) se inyectan como Variables de Envorno en Kubernetes, no hardcodeadas.
3. **Validación de Datos**: Strong Parameters en Rails y validaciones de formulario en Angular para prevenir inyección de datos maliciosos.
4. **CORS Configurado**: Política estricta para permitir peticiones solo desde el origen del frontend confiable.
5. **Auditoría**: Registro inmutable de todas las decisiones de crédito para trazabilidad y cumplimiento normativo.

---

## Análisis de Escalabilidad y Volumetría

El sistema está diseñado para escalar ante altos volúmenes de solicitudes:

### 1. Procesamiento Asíncrono (Solid Queue)
Las evaluaciones de crédito pesadas se envían a un worker en segundo plano. Esto libera el hilo principal de la API para seguir recibiendo solicitudes (alta concurrencia) sin bloquearse mientras se procesan reglas complejas.

### 2. Escalado Horizontal (Kubernetes)
- **API Stateless**: Al no depender de sesiones en memoria, se pueden levantar múltiples réplicas (pods) de la API (`replicas: 2` en `api.yaml`) tras un Load Balancer.
- **Workers Independientes**: El procesamiento de trabajos (`worker.yaml`) escala independientemente de la API web. Si la cola crece, se aumentan solo los workers.

### 3. Base de Datos (PostgreSQL)
- **Particionamiento (Futuro)**: El diseño permite migrar fácilmente a particionamiento por país o fecha si el volumen de datos alcanza millones de registros.

### Pruebas de Estrés y Concurrencia
Para validar la capacidad del sistema de procesar múltiples solicitudes en paralelo, se ha incluido un script de simulación que genera tráfico de forma masiva:

```bash
# Ejecutar simulación de 10 solicitudes aleatorias desde el cluster
kubectl exec -it $(kubectl get pods -l app=api -o jsonpath='{.items[0].metadata.name}') -- bin/rails runner bin/stress_test.rb 10
```
*Este comando dispara 50 solicitudes con datos válidos (DNI, NIF, CPF, etc.) y lógica de aprobación/rechazo aleatoria para todos los países.*

---

## Despliegue en Kubernetes (Requisito 4.8)

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

---

## Reglas de Negocio por País

| País | Identificador | Regla Principal |
|---|---|---|
| España | DNI | Revisión manual si monto > 50,000€ |
| Portugal | NIF | Rechazo si monto supera el 10% de ingresos |
| Italia | Codice Fiscale | Reglas de estabilidad financiera |
| México | CURP | Evaluación de ratio deuda/ingreso |
| Colombia | CC | Verificación de capacidad de endeudamiento |
| Brasil | CPF | Score financiero con integración mock |
