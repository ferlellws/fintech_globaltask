# Stage 1: Build
FROM node:20-alpine AS build

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto del código
COPY . .

# Construir la aplicación para producción
RUN npm run build -- --configuration production

# Stage 2: Serve
FROM nginx:alpine

# Copiar los archivos construidos desde el stage anterior
# Nota: Ajusta 'dist/frontend/browser' si el nombre del proyecto en angular.json es diferente
COPY --from=build /app/dist/frontend/browser /usr/share/nginx/html

# Copiar configuración personalizada de nginx para soportar SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
