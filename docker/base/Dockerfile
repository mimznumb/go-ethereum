FROM alpine:3.20
WORKDIR /root

# Minimal runtime utils + init
RUN apk add --no-cache ca-certificates bash curl jq tini

# Helper scripts (no geth here)
COPY scripts/start-devnet.sh /usr/local/bin/start-devnet.sh
COPY scripts/wait-for-rpc.sh   /usr/local/bin/wait-for-rpc.sh
RUN chmod +x /usr/local/bin/start-devnet.sh /usr/local/bin/wait-for-rpc.sh

# Defaults / volumes / ports
ENV GETH_DATADIR=/root/.ethereum \
    GETH_HTTP_PORT=8545 \
    GETH_WS_PORT=8546
VOLUME ["/root/.ethereum"]
EXPOSE 8545 8546 30303/tcp 30303/udp

# Healthcheck expects JSON-RPC (the devnet image will provide it via geth)
HEALTHCHECK --interval=5s --timeout=3s --retries=20 CMD \
  curl -sSf -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"web3_clientVersion","params":[]}' \
  http://127.0.0.1:${GETH_HTTP_PORT} >/dev/null || exit 1

ENTRYPOINT ["/sbin/tini","--","/usr/local/bin/start-devnet.sh"]
