# ── Stage 1: Build ──────────────────────────────────────────────────
FROM rust:1.88-bookworm AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

# Copy manifests first for dependency caching
COPY Cargo.toml Cargo.lock* ./

# Create a dummy main.rs to build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release 2>/dev/null || true
RUN rm -rf src

# Copy full source
COPY src/ src/
COPY migrations/ migrations/

# Build the actual application
RUN touch src/main.rs && cargo build --release

# ── Stage 2: Runtime ───────────────────────────────────────────────
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled binary
COPY --from=builder /app/target/release/igreja-manager-api .

# Copy migrations (needed at runtime for sqlx::migrate!)
COPY migrations/ migrations/

# Create uploads directory
RUN mkdir -p uploads

EXPOSE 8080

ENV RUST_LOG=info
ENV HOST=0.0.0.0
ENV PORT=8080

CMD ["./igreja-manager-api"]
