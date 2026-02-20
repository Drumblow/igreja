# ── Stage 1: Build Flutter Web ──────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.32.2 AS builder

WORKDIR /app

# Copy pubspec files first for dependency caching
COPY pubspec.yaml pubspec.lock* ./

RUN flutter pub get

# Copy the rest of the source
COPY . .

# Build for web with production API URL
ARG API_URL=http://147.15.109.89:8080/api
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# ── Stage 2: Serve with Nginx ──────────────────────────────────────
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built Flutter web app
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
