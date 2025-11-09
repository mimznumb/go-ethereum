#!/usr/bin/env bash
set -euo pipefail

GETH_HTTP_ADDR="${GETH_HTTP_ADDR:-0.0.0.0}"
GETH_HTTP_PORT="${GETH_HTTP_PORT:-8545}"
GETH_WS_ADDR="${GETH_WS_ADDR:-0.0.0.0}"
GETH_WS_PORT="${GETH_WS_PORT:-8546}"
GETH_API="${GETH_API:-eth,net,web3,txpool,debug}"
GETH_NETWORK="${GETH_NETWORK:-dev}"      # dev = ephemeral instant-seal chain
GETH_EXTRA_ARGS="${GETH_EXTRA_ARGS:-}"
DATADIR="${GETH_DATADIR:-/root/.ethereum}"
mkdir -p "$DATADIR"

echo "[start-devnet] geth --${GETH_NETWORK} on ${GETH_HTTP_ADDR}:${GETH_HTTP_PORT}"
exec geth \
  --${GETH_NETWORK} \
  --datadir "${DATADIR}" \
  --http --http.addr "${GETH_HTTP_ADDR}" --http.port "${GETH_HTTP_PORT}" --http.api "${GETH_API}" \
  --ws   --ws.addr   "${GETH_WS_ADDR}"   --ws.port   "${GETH_WS_PORT}" \
  --http.corsdomain="*" --http.vhosts="*" \
  --allow-insecure-unlock \
  --nodiscover --maxpeers 0 \
  ${GETH_EXTRA_ARGS}
