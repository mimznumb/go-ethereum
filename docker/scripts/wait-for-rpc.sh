#!/usr/bin/env bash
set -euo pipefail
RPC_URL="${1:-http://127.0.0.1:8545}"
TRIES="${2:-60}"
for i in $(seq 1 "$TRIES"); do
  if curl -sSf -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","id":1,"method":"web3_clientVersion","params":[]}' \
      "$RPC_URL" >/dev/null; then
    echo "RPC ready at $RPC_URL"; exit 0
  fi
  sleep 2
done
echo "RPC not ready: $RPC_URL"; exit 1
