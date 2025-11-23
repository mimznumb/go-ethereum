# ============================================
# Stage 1: Builder - Compile Geth
# ============================================
FROM golang:1.23-alpine AS builder

WORKDIR /src
ENV GOTOOLCHAIN=auto

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    linux-headers \
    git \
    bash

# Cache dependencies first (better layer caching)
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Copy source code
COPY . .

# Build geth with cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    go run build/ci.go install -static ./cmd/geth

# Verify binary exists
RUN test -f /src/build/bin/geth && \
    /src/build/bin/geth version

# ============================================
# Stage 2: Runtime Base - Minimal Runtime
# ============================================
FROM alpine:3.20 AS runtime

LABEL maintainer="DevOps Team"
LABEL description="Geth base image with runtime dependencies"

WORKDIR /root

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    jq \
    tini

# Copy geth binary from builder
COPY --from=builder /src/build/bin/geth /usr/local/bin/geth

# Copy helper scripts
COPY docker/scripts/start-devnet.sh /usr/local/bin/start-devnet.sh
COPY docker/scripts/wait-for-rpc.sh /usr/local/bin/wait-for-rpc.sh
RUN chmod +x /usr/local/bin/*.sh

# Create non-root user for security
RUN addgroup -g 1000 geth && \
    adduser -u 1000 -G geth -s /bin/sh -D geth && \
    mkdir -p /home/geth/.ethereum && \
    chown -R geth:geth /home/geth

# Environment variables
ENV GETH_DATADIR=/home/geth/.ethereum \
    GETH_HTTP_PORT=8545 \
    GETH_WS_PORT=8546 \
    GETH_HTTP_ADDR=0.0.0.0 \
    GETH_WS_ADDR=0.0.0.0

# Expose ports
EXPOSE 8545 8546 30303/tcp 30303/udp

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD curl -sf -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","id":1,"method":"web3_clientVersion","params":[]}' \
      http://127.0.0.1:${GETH_HTTP_PORT} > /dev/null || exit 1

# Switch to non-root user
USER geth

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start-devnet.sh"]
