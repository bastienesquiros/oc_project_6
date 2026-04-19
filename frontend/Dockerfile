# Stage 1: Build
FROM node:22.22.2-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --cache .npm --prefer-offline

COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:1.27.5-alpine

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /app/dist/olympic-games-starter/browser /app

EXPOSE 80
