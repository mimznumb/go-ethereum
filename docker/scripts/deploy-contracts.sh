#!/usr/bin/env bash
# ============================================
# Contract Deployment Script
# ============================================
# This script deploys smart contracts to the running devnet
# and saves deployment addresses for later use
#
# IMPORTANT: Contract artifacts are PRE-COMPILED and included
# in the Docker image at /opt/contracts during build time.
# This ensures contracts are persistent in the image.
#
# The devnet Dockerfile includes a contract-builder stage that:
# 1. Compiles Hardhat contracts
# 2. Copies artifacts to /opt/contracts
# 3. Makes them available in the final image
#
# This script can be run on container startup to deploy
# those pre-compiled contracts to the running chain.
# ============================================

set -euo pipefail

CONTRACTS_DIR="${CONTRACTS_DIR:-/opt/contracts}"
DEPLOYMENTS_FILE="${DEPLOYMENTS_FILE:-/home/geth/.ethereum/deployments.json}"
RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
DEPLOYER_PK="${DEPLOYER_PK:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"

echo "🚀 Starting contract deployment..."
echo "   RPC: $RPC_URL"
echo "   Contracts: $CONTRACTS_DIR"

# Check if contracts exist
if [ ! -d "$CONTRACTS_DIR" ]; then
    echo "⚠️  No contracts found at $CONTRACTS_DIR"
    echo "   Skipping deployment"
    exit 0
fi

# Wait for RPC to be ready
echo "⏳ Waiting for RPC..."
for i in {1..30}; do
    if curl -sf -H 'Content-Type: application/json' \
         --data '{"jsonrpc":"2.0","id":1,"method":"web3_clientVersion","params":[]}' \
         "$RPC_URL" > /dev/null 2>&1; then
        echo "✅ RPC is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ RPC not responding after 30 seconds"
        exit 1
    fi
    sleep 1
done

# Get chain ID
CHAIN_ID=$(curl -sf -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' \
    "$RPC_URL" | jq -r '.result')

echo "📡 Connected to chain ID: $CHAIN_ID"

# Initialize deployments file
mkdir -p "$(dirname "$DEPLOYMENTS_FILE")"
echo "{" > "$DEPLOYMENTS_FILE"
echo "  \"chainId\": \"$CHAIN_ID\"," >> "$DEPLOYMENTS_FILE"
echo "  \"deployedAt\": \"$(date -Iseconds)\"," >> "$DEPLOYMENTS_FILE"
echo "  \"contracts\": {" >> "$DEPLOYMENTS_FILE"

# Example: Deploy Counter contract if artifacts exist
if [ -f "$CONTRACTS_DIR/contracts/Counter.sol/Counter.json" ]; then
    echo "📝 Deploying Counter contract..."
    
    # Extract bytecode
    BYTECODE=$(jq -r '.bytecode' "$CONTRACTS_DIR/contracts/Counter.sol/Counter.json")
    
    # Get dev account
    DEV_ACCOUNT=$(curl -sf -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_accounts","params":[]}' \
        "$RPC_URL" | jq -r '.result[0]')
    
    echo "   Deployer: $DEV_ACCOUNT"
    
    # Deploy contract
    TX_HASH=$(curl -sf -H 'Content-Type: application/json' \
        --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$DEV_ACCOUNT\",\"data\":\"$BYTECODE\"}]}" \
        "$RPC_URL" | jq -r '.result')
    
    echo "   TX: $TX_HASH"
    
    # Wait for receipt
    sleep 2
    
    CONTRACT_ADDRESS=$(curl -sf -H 'Content-Type: application/json' \
        --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$TX_HASH\"]}" \
        "$RPC_URL" | jq -r '.result.contractAddress')
    
    echo "   ✅ Counter deployed at: $CONTRACT_ADDRESS"
    
    # Save to deployments file
    echo "    \"Counter\": {" >> "$DEPLOYMENTS_FILE"
    echo "      \"address\": \"$CONTRACT_ADDRESS\"," >> "$DEPLOYMENTS_FILE"
    echo "      \"transactionHash\": \"$TX_HASH\"," >> "$DEPLOYMENTS_FILE"
    echo "      \"deployer\": \"$DEV_ACCOUNT\"" >> "$DEPLOYMENTS_FILE"
    echo "    }" >> "$DEPLOYMENTS_FILE"
fi

# Close JSON
echo "  }" >> "$DEPLOYMENTS_FILE"
echo "}" >> "$DEPLOYMENTS_FILE"

echo ""
echo "✅ Deployment complete!"
echo "   Deployments saved to: $DEPLOYMENTS_FILE"
echo ""
cat "$DEPLOYMENTS_FILE"
