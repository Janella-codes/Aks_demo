# Build stage
FROM node:22 AS build
WORKDIR /app

COPY frontend/aks-demo-frontend/package*.json ./
RUN npm install

COPY frontend/aks-demo-frontend/. .
RUN npm run build

# Runtime stage
FROM nginx:alpine
COPY --from=build /app/dist/aks-demo-frontend/browser /usr/share/nginx/html

EXPOSE 80
