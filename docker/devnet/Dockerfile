# ============================================
# Devnet Image - Development Environment
# ============================================
# This image extends geth-base with development-specific configuration
# and includes pre-compiled smart contracts

# Build argument for base image (can be overridden)
ARG BASE_IMAGE=geth-base:latest

# ============================================
# Stage 1: Contract Builder
# ============================================
FROM node:22-alpine AS contract-builder

WORKDIR /contracts

# Copy Hardhat project
COPY hardhat/package*.json ./
RUN npm ci --quiet

COPY hardhat/ ./

# Compile contracts
RUN npx hardhat compile

# Create deployment artifacts directory
RUN mkdir -p /contract-artifacts && \
    cp -r artifacts/contracts /contract-artifacts/ && \
    cp -r ignition /contract-artifacts/ 2>/dev/null || true && \
    echo "Contract artifacts prepared at $(date)" > /contract-artifacts/build-info.txt

# ============================================
# Stage 2: Geth Builder
# ============================================
FROM golang:1.23-alpine AS geth-builder

WORKDIR /src
ENV GOTOOLCHAIN=auto
RUN apk add --no-cache build-base linux-headers git bash

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the repo
COPY . .

# Build geth (try multiple build entrypoints)
RUN go run ./ci.go install ./cmd/geth || \
    go run build/ci.go install ./cmd/geth || \
    go build -o build/bin/geth ./cmd/geth

# ============================================
# Stage 3: Runtime - Devnet Configuration
# ============================================
FROM ${BASE_IMAGE}

LABEL description="Geth devnet with development configuration and pre-compiled contracts"
LABEL version="1.0"

# Switch to root for setup
USER root

# Copy geth binary from geth-builder stage
COPY --from=geth-builder /src/build/bin/geth /usr/local/bin/geth

# Copy contract artifacts from contract-builder stage
COPY --from=contract-builder /contract-artifacts /opt/contracts

# Copy deployment script
COPY docker/scripts/deploy-contracts.sh /usr/local/bin/deploy-contracts.sh
RUN chmod +x /usr/local/bin/deploy-contracts.sh

# Create deployment info file
RUN echo "Devnet image built at $(date)" > /opt/devnet-info.txt && \
    echo "Base image: ${BASE_IMAGE}" >> /opt/devnet-info.txt && \
    echo "Contracts included: yes" >> /opt/devnet-info.txt && \
    echo "Geth binary: $(geth version | head -1)" >> /opt/devnet-info.txt && \
    ls -la /opt/contracts >> /opt/devnet-info.txt 2>&1 || echo "No contracts found" >> /opt/devnet-info.txt

# Set ownership to geth user
RUN chown -R geth:geth /opt/contracts /opt/devnet-info.txt /usr/local/bin/deploy-contracts.sh

# Switch back to non-root user
USER geth

# Environment for devnet
ENV GETH_NETWORK=dev \
    GETH_API=eth,net,web3,txpool,debug,trace \
    GETH_EXTRA_ARGS="--allow-insecure-unlock --nodiscover --maxpeers 0" \
    CONTRACTS_DIR=/opt/contracts

# The entrypoint from base image will be used
# Contracts are available in /opt/contracts
# Use deploy-contracts.sh to deploy them on startup if needed
