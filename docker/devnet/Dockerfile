# declare ARG in global scope so it can be used in FROM
ARG BASE_IMAGE=alpine:3.20

# ---------- Builder: compile geth ----------
    FROM golang:1.23-alpine AS builder
    WORKDIR /src
    ENV GOTOOLCHAIN=auto   
    #allows Go to fetch a newer patch toolchain if needed
    RUN apk add --no-cache build-base linux-headers git bash
    
    # cache deps first
    COPY go.mod go.sum ./
    RUN go mod download
    
    # now bring the rest
    COPY . .
    # build geth (try ci.go at root, then build/, fallback to plain go build)
    RUN go run ./ci.go install ./cmd/geth || \
        go run build/ci.go install ./cmd/geth || \
        go build -o build/bin/geth ./cmd/geth
    

# ---------- Runtime: use the base image ----------
FROM ${BASE_IMAGE} AS runtime

# fallback entrypoint if BASE_IMAGE is plain alpine
RUN test -x /usr/local/bin/start-devnet.sh || ( \
      apk add --no-cache ca-certificates bash curl jq tini && \
      printf '#!/usr/bin/env bash\nexec geth --dev --http --http.addr 0.0.0.0 --http.api eth,net,web3,txpool,debug --ws --ws.addr 0.0.0.0 --http.corsdomain=\"*\" --http.vhosts=\"*\" --allow-insecure-unlock --nodiscover --maxpeers 0\n' \
      > /usr/local/bin/start-devnet.sh && chmod +x /usr/local/bin/start-devnet.sh )

COPY --from=builder /src/build/bin/geth /usr/local/bin/geth
