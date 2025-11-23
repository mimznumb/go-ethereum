# Geth Devnet Docker Image

This Docker image contains a development Ethereum network (devnet) with **pre-compiled smart contracts** included.

## 🎯 Key Features

- ✅ **Pre-compiled contracts** - Hardhat contracts are compiled during image build
- ✅ **Contract artifacts included** - Available at `/opt/contracts` in the image
- ✅ **Deployment script** - Optional script to deploy contracts on startup
- ✅ **Multi-stage build** - Optimized for size and security
- ✅ **Based on geth-base** - Reuses base image with geth binary

## 📦 What's Included

### Contract Artifacts (in `/opt/contracts`)

The image includes pre-compiled smart contract artifacts from the Hardhat project:

```
/opt/contracts/
├── contracts/
│   ├── Counter.sol/
│   │   ├── Counter.json      # ABI + bytecode
│   │   └── Counter.dbg.json
│   └── Lock.sol/
│       ├── Lock.json
│       └── Lock.dbg.json
└── ignition/
    └── modules/
        └── Counter.ts          # Deployment module
```

### How Contracts Are Included

The Dockerfile uses a **multi-stage build**:

```dockerfile
# Stage 1: Contract Builder
FROM node:22-alpine AS contract-builder
COPY hardhat/ ./
RUN npx hardhat compile
RUN cp -r artifacts/contracts /contract-artifacts/

# Stage 2: Geth Builder
FROM golang:1.23-alpine AS builder
COPY . .
RUN go build -o build/bin/geth ./cmd/geth

# Stage 3: Runtime
FROM geth-base:latest
COPY --from=builder /src/build/bin/geth /usr/local/bin/geth
COPY --from=contract-builder /contract-artifacts /opt/contracts  # ← Contracts!
```

This ensures:
- ✅ Contracts are **compiled once** during image build
- ✅ Artifacts are **persistent** in the image
- ✅ No need to recompile on every container start
- ✅ Contracts can be deployed immediately

## 🚀 Usage

### Build Image

```bash
# Build with contracts
docker buildx build -f docker/devnet/Dockerfile \
  --build-arg BASE_IMAGE=geth-base:latest \
  -t geth-devnet:latest .
```

### Run Devnet

```bash
# Start devnet
docker run -d -p 8545:8545 -p 8546:8546 \
  --name geth-devnet \
  geth-devnet:latest

# Check if contracts are included
docker exec geth-devnet ls -la /opt/contracts
```

### Deploy Contracts (Optional)

Contracts are **included** in the image but **not deployed** by default. To deploy them:

```bash
# Option 1: Run deployment script manually
docker exec geth-devnet /usr/local/bin/deploy-contracts.sh

# Option 2: Deploy with Hardhat (from host)
cd hardhat
npx hardhat ignition deploy ignition/modules/Counter.ts --network localdevnet
```

### Verify Contracts Are in Image

```bash
# Check contract artifacts
docker exec geth-devnet cat /opt/contracts/contracts/Counter.sol/Counter.json | jq '.abi'

# Check devnet info
docker exec geth-devnet cat /opt/devnet-info.txt
```

## 🔍 How It Works

### Build Time

1. **Contract Builder Stage**
   - Installs Node.js and Hardhat
   - Compiles all Solidity contracts
   - Copies artifacts to `/contract-artifacts`

2. **Geth Builder Stage**
   - Compiles geth binary from source
   - Optimized Go build

3. **Runtime Stage**
   - Starts from `geth-base` image
   - Copies geth binary from builder
   - **Copies contract artifacts** from contract-builder
   - Sets up deployment script

### Run Time

When container starts:
- Geth devnet starts (instant-seal mode)
- Contracts are **available** at `/opt/contracts`
- Deployment script can be run to deploy them
- Deployment addresses saved to `/home/geth/.ethereum/deployments.json`

## 📊 Image Layers

```
geth-devnet:latest
├─ Layer 1: Base image (Alpine + geth binary)
├─ Layer 2: Geth binary (from builder)
├─ Layer 3: Contract artifacts (from contract-builder)  ← Persistent!
└─ Layer 4: Scripts and configuration
```

## 🎯 Why This Approach?

### ✅ Advantages

1. **Contracts are persistent** - No recompilation needed
2. **Faster startup** - Contracts already compiled
3. **Reproducible** - Same artifacts every time
4. **Smaller final image** - No Node.js in runtime
5. **Secure** - Multi-stage build, minimal runtime

### 📝 Alternative Approaches

| Approach | Pros | Cons |
|----------|------|------|
| **Genesis block** | Contracts deployed at block 0 | Complex setup, hard to update |
| **Compile on startup** | Always fresh | Slow startup, needs Node.js |
| **Pre-compiled (current)** | Fast, persistent, small | Requires rebuild to update |

## 🔧 Development

### Update Contracts

```bash
# 1. Edit contracts in hardhat/contracts/
vim hardhat/contracts/Counter.sol

# 2. Rebuild image (contracts will be recompiled)
docker buildx build -f docker/devnet/Dockerfile -t geth-devnet:latest .

# 3. New image has updated contracts
docker run -d -p 8545:8545 geth-devnet:latest
```

### Test Locally

```bash
# Build image
make build-devnet

# Start container
docker run -d -p 8545:8545 --name test-devnet geth-devnet:latest

# Deploy contracts
docker exec test-devnet /usr/local/bin/deploy-contracts.sh

# Run Hardhat tests
cd hardhat && npx hardhat test --network localdevnet

# Clean up
docker rm -f test-devnet
```

## 📚 Related Documentation

- [Deployment Flow](../../docs/DEPLOYMENT_FLOW.md)
- [Quick Start](../../docs/QUICKSTART.md)
- [Hardhat README](../../hardhat/README.md)

## 🎓 Summary

This image demonstrates **best practices** for including smart contracts in Docker images:

- ✅ **Multi-stage builds** for optimization
- ✅ **Pre-compiled artifacts** for speed
- ✅ **Persistent in image** for reliability
- ✅ **Deployment script** for flexibility
- ✅ **Well-documented** for maintainability

**Result**: Fast, secure, reproducible devnet with contracts ready to deploy!
