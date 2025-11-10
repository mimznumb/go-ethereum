# declare ARG in the global scope so it can be used in FROM
ARG BASE_IMAGE=722377226063.dkr.ecr.eu-central-1.amazonaws.com/geth-base:base-dd778d

# ---------- Builder: compile geth ----------
FROM golang:1.23-alpine AS builder

WORKDIR /src
ENV GOTOOLCHAIN=auto
RUN apk add --no-cache build-base linux-headers git bash

# cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# copy the rest of the repo
COPY . .

# build geth (try multiple build entrypoints)
RUN go run ./ci.go install ./cmd/geth || \
    go run build/ci.go install ./cmd/geth || \
    go build -o build/bin/geth ./cmd/geth

# ---------- Runtime: use the ECR base image ----------
FROM ${BASE_IMAGE} AS runtime

# fallback entrypoint if BASE_IMAGE is plain alpine
RUN test -x /usr/local/bin/start-devnet.sh || ( \
      apk add --no-cache ca-certificates bash curl jq tini && \
      printf '#!/usr/bin/env bash\nexec geth --dev --http --http.addr 0.0.0.0 --http.api eth,net,web3,txpool,debug --ws --ws.addr 0.0.0.0 --http.corsdomain=\"*\" --http.vhosts=\"*\" --allow-insecure-unlock --nodiscover --maxpeers 0\n' \
      > /usr/local/bin/start-devnet.sh && chmod +x /usr/local/bin/start-devnet.sh )

# copy geth binary from builder stage
COPY --from=builder /src/build/bin/geth /usr/local/bin/geth
