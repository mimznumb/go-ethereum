# ============================================
# Devnet Image - Development Environment
# ============================================
# This image extends geth-base with development-specific configuration
# and optionally includes pre-deployed smart contracts

# Build argument for base image (can be overridden)
ARG BASE_IMAGE=geth-base:latest
ARG INCLUDE_CONTRACTS=false

# ============================================
# Stage 1: Contract Builder (Optional)
# ============================================
FROM node:22-alpine AS contract-builder

WORKDIR /contracts

# Copy Hardhat project
COPY hardhat/package*.json ./
RUN npm ci

COPY hardhat/ ./

# Compile contracts
RUN npx hardhat compile

# Generate deployment artifacts
RUN mkdir -p /contract-artifacts && \
    cp -r artifacts/contracts /contract-artifacts/ && \
    cp -r ignition /contract-artifacts/ || true

# ============================================
# Stage 2: Runtime - Devnet Configuration
# ============================================
FROM ${BASE_IMAGE}

LABEL description="Geth devnet with development configuration"
LABEL version="1.0"

# Switch to root for setup
USER root

# Copy contract artifacts if building with contracts
COPY --from=contract-builder /contract-artifacts /opt/contracts/

# Create deployment info file
RUN echo "Devnet image built at $(date)" > /opt/devnet-info.txt && \
    echo "Base image: ${BASE_IMAGE}" >> /opt/devnet-info.txt && \
    if [ -d /opt/contracts ]; then \
        echo "Contracts included: yes" >> /opt/devnet-info.txt; \
        ls -la /opt/contracts >> /opt/devnet-info.txt; \
    else \
        echo "Contracts included: no" >> /opt/devnet-info.txt; \
    fi

# Optional: Add contract deployment script
COPY docker/scripts/deploy-contracts.sh /usr/local/bin/deploy-contracts.sh 2>/dev/null || true
RUN if [ -f /usr/local/bin/deploy-contracts.sh ]; then \
        chmod +x /usr/local/bin/deploy-contracts.sh; \
    fi

# Set ownership
RUN chown -R geth:geth /opt/contracts /opt/devnet-info.txt 2>/dev/null || true

# Switch back to non-root user
USER geth

# Override environment for devnet
ENV GETH_NETWORK=dev \
    GETH_API=eth,net,web3,txpool,debug,trace \
    GETH_EXTRA_ARGS="--allow-insecure-unlock --nodiscover --maxpeers 0"

# Devnet uses the same entrypoint from base image
# ENTRYPOINT and CMD inherited from base image
