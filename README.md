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

Hemos incluido un `Makefile` en la raíz para simplificar las operaciones:

```bash
# Instalar todo (Backend y Frontend)
make setup

# Iniciar el ecosistema completo (API + Worker + Angular)
make start

# Ver ayuda de comandos disponibles
make help
```

## ☸️ Despliegue en Kubernetes

Los manifiestos se encuentran en la carpeta `/k8s/`. Incluyen la configuración para:
- Base de Datos (PostgreSQL)
- API (Rails)
- Worker (Solid Queue)
- Frontend (Angular/Nginx)

Para desplegar localmente:
```bash
make k8s-deploy
```

## 📝 Reglas de Negocio Implementadas
- **España (ES)**: Validación de DNI. Revisión manual si el monto > 50,000€.
- **Portugal (PT)**: Validación de NIF. Rechazo automático si el monto solicitado excede el 10% de los ingresos.
- **Italia (IT)**: Validación de Codice Fiscale. Reglas de estabilidad financiera.
- **México (MX)**: Validación de CURP. Evaluación de ratio deuda/ingreso.
- **Colombia (CO)**: Validación de CC. Verificación de capacidad de endeudamiento.
- **Brasil (BR)**: Validación de CPF. Integración con mock de score financiero.

---
Desarrollado para el desafío técnico GlobalTask.
