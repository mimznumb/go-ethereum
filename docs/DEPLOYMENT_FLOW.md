# 🚀 Deployment Flow Documentation

## Обща Архитектура

Този проект използва **multi-stage deployment pipeline** с автоматизирани тестове и валидация на всяка стъпка.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DEPLOYMENT PIPELINE                          │
└─────────────────────────────────────────────────────────────────────┘

1️⃣  BUILD BASE IMAGE          2️⃣  BUILD DEVNET IMAGE         3️⃣  DEPLOY TO EKS
   (CI:Base label)               (CI:Deploy label)              (HelmDeploy label)
         │                              │                              │
         ▼                              ▼                              ▼
   ┌──────────┐                  ┌──────────┐                  ┌──────────┐
   │ Build    │                  │ Build    │                  │ Update   │
   │ geth-    │─────────────────▶│ geth-    │─────────────────▶│ Helm     │
   │ base     │   (uses base)    │ devnet   │   (validated)    │ Release  │
   └──────────┘                  └──────────┘                  └──────────┘
        │                              │                              │
        │                              │                              │
   Push to ECR              Test + Push to ECR              Deploy to K8s
   geth-base:base-XXXXXX    geth-devnet-pre:pre-XXXXXX     Running Pod
```

---

## 📦 Docker Image Strategy

### Текуща Структура (Проблеми)

**Проблем 1**: Множество имиджи без ясна йерархия
- `Dockerfile` (root) - standalone geth build
- `Dockerfile.alltools` - всички geth tools
- `docker/base/Dockerfile` - runtime base без geth
- `docker/devnet/Dockerfile` - devnet с hardcoded base image

**Проблем 2**: Hardcoded dependencies
```dockerfile
# docker/devnet/Dockerfile:2
ARG BASE_IMAGE=722377226063.dkr.ecr.eu-central-1.amazonaws.com/geth-base:base-dd778d
```

**Проблем 3**: Повтарящ се build на geth във всеки workflow

---

## 🎯 Оптимизирана Структура

### Нова Image Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    IMAGE HIERARCHY                           │
└─────────────────────────────────────────────────────────────┘

1. geth-builder (build-time only)
   ├─ golang:1.23-alpine
   ├─ Build dependencies (gcc, musl-dev, git)
   └─ Compiled geth binary
        │
        ├──▶ 2. geth-base (runtime base)
        │    ├─ alpine:3.20
        │    ├─ Runtime utils (bash, curl, jq, tini)
        │    ├─ Helper scripts
        │    └─ geth binary from builder
        │         │
        │         ├──▶ 3. geth-devnet (development)
        │         │    ├─ FROM geth-base
        │         │    ├─ Dev configuration
        │         │    └─ Smart contracts (optional)
        │         │
        │         └──▶ 4. geth-production (future)
        │              ├─ FROM geth-base
        │              └─ Production config
```

### Build Strategy

**Еднократен Build на geth** → Споделен base image → Специализирани runtime images

---

## 🔄 CI/CD Workflow Details

### Workflow 1: `ci-build-base.yml` (Build Base Image)

**Trigger**: PR merge с label `CI:Base`

**Цел**: Build и push на base image с geth binary

```yaml
Steps:
1. Checkout code
2. Login to ECR
3. Build geth-base image (включва geth binary)
4. Tag: geth-base:base-{SHORT_SHA}
5. Push to ECR
```

**Output**: 
- Image: `722377226063.dkr.ecr.eu-central-1.amazonaws.com/geth-base:base-XXXXXX`
- Този image се използва като base за devnet

---

### Workflow 2: `ci-deploy-ecr.yml` (Build, Test & Deploy Devnet)

**Trigger**: PR merge с label `CI:Deploy`

**Цел**: Build devnet image, run tests, push validated image

```yaml
Steps:
1. Checkout merged code
2. Login to ECR (за pull на base image)
3. Build devnet image
   └─ FROM geth-base:base-XXXXXX (от ECR)
   └─ ADD geth binary (вече е в base)
4. Start devnet container locally
5. Wait for RPC ready
6. Fund Hardhat default account
7. Run Hardhat tests (Counter.sol)
   └─ Compile contracts
   └─ Deploy Counter contract
   └─ Test increment functions
8. IF TESTS PASS:
   └─ Retag image → geth-devnet-pre:pre-XXXXXX
   └─ Push to ECR
```

**Smart Contracts Flow**:
```
hardhat/contracts/Counter.sol
         │
         ▼ (compile)
hardhat/artifacts/Counter.json
         │
         ▼ (deploy via test)
Running devnet container @ localhost:8545
         │
         ▼ (test execution)
npx hardhat test test/Counter.ts --network localdevnet
         │
         ▼ (validation)
✅ Tests pass → Image validated → Push to ECR
```

**Output**:
- Image: `722377226063.dkr.ecr.eu-central-1.amazonaws.com/geth-devnet-pre:pre-XXXXXX`
- Този image е **тестван и валидиран**

---

### Workflow 3: `helm-deploy.yml` (Deploy to EKS)

**Trigger**: PR merge с label `HelmDeploy`

**Цел**: Deploy validated image to Kubernetes

```yaml
Steps:
1. Checkout code
2. Authenticate to AWS (OIDC)
3. Update kubeconfig for EKS cluster
4. Install kubectl & helm
5. Create namespace (if missing)
6. Deploy Helm chart
   └─ Uses image from helm/geth-devnet/values.yaml
   └─ Image: geth-devnet-pre:pre-XXXXXX (validated)
7. Wait for rollout
8. Show service info
```

**Helm Chart Structure**:
```
helm/geth-devnet/
├── Chart.yaml
├── values.yaml (image tag here!)
└── templates/
    ├── deployment.yaml (geth pod)
    ├── service.yaml (LoadBalancer)
    └── serviceaccount.yaml (IRSA)
```

**Output**:
- Running pod in EKS cluster
- LoadBalancer service exposing port 8545 (RPC)

---

### Workflow 4: `terraform-plan.yml` & `terraform-apply.yml`

**Trigger**: 
- Plan: PR to master (terraform/** changes)
- Apply: Push to master (terraform/** changes)

**Цел**: Manage infrastructure (VPC, EKS, ECR)

```yaml
Plan Steps:
1. Checkout
2. Setup Terraform
3. terraform fmt -check
4. terraform init
5. terraform validate
6. terraform plan

Apply Steps:
1. Checkout
2. Setup Terraform
3. terraform init
4. terraform plan
5. terraform apply -auto-approve
```

---

## 🔍 Smart Contracts Deployment Tracking

### Къде се деплойват контрактите?

**Отговор**: Контрактите се деплойват **временно** в CI pipeline за тестване, **НЕ** се комитват в имиджа.

### Текущ Flow:

```
1. CI Pipeline стартира devnet container
   └─ geth --dev (ephemeral chain, no persistence)

2. Hardhat компилира Counter.sol
   └─ Artifacts: hardhat/artifacts/contracts/Counter.sol/Counter.json

3. Hardhat deploy script (test/Counter.ts)
   └─ Deploy Counter contract to localhost:8545
   └─ Run tests (inc, incBy functions)
   └─ Contract address: 0x... (ephemeral, lost after test)

4. Container stops
   └─ Chain data discarded
   └─ Contract addresses lost
```

### Проблем:

❌ Няма persistence на deployed contracts
❌ Всеки път се deploy-ва наново
❌ Няма tracking на contract addresses

### Решение (Опция 1): Contract Artifacts в Image

```dockerfile
# docker/devnet/Dockerfile (enhanced)
FROM ${BASE_IMAGE} AS runtime

# Copy geth binary
COPY --from=builder /src/build/bin/geth /usr/local/bin/geth

# NEW: Copy compiled contracts
COPY hardhat/artifacts/contracts /opt/contracts/artifacts
COPY hardhat/deployments /opt/contracts/deployments

# NEW: Add deployment script
COPY docker/scripts/deploy-contracts.sh /usr/local/bin/
```

### Решение (Опция 2): Genesis Block с Pre-deployed Contracts

```json
// genesis.json
{
  "alloc": {
    "0x1234...": {
      "code": "0x608060...",  // Counter contract bytecode
      "balance": "0x0"
    }
  }
}
```

---

## 🐛 Failing Workflows - Диагностика

### Как да проверим кои workflows fail-ват:

```bash
# Check recent workflow runs
gh run list --limit 20

# View specific workflow
gh run view <run-id>

# Check workflow logs
gh run view <run-id> --log
```

### Често срещани проблеми:

1. **Missing ECR base image**
   - Причина: `geth-base:base-XXXXXX` не съществува
   - Решение: Run `ci-build-base.yml` първо

2. **Hardhat tests timeout**
   - Причина: RPC не стартира навреме
   - Решение: Увеличи wait time или подобри healthcheck

3. **Terraform state lock**
   - Причина: Concurrent applies
   - Решение: Add DynamoDB state locking

4. **OIDC authentication failure**
   - Причина: Missing/wrong role ARN
   - Решение: Verify `vars.EKS_OIDC_ROLE_ARN`

---

## 📋 Deployment Checklist

### Initial Setup (еднократно):

- [ ] 1. Setup AWS infrastructure
  ```bash
  cd terraform
  terraform init
  terraform plan
  terraform apply
  ```

- [ ] 2. Build base image
  - Create PR with changes
  - Add label `CI:Base`
  - Merge PR
  - Wait for `ci-build-base.yml` to complete
  - Note the image tag: `base-XXXXXX`

- [ ] 3. Update devnet Dockerfile
  ```dockerfile
  # docker/devnet/Dockerfile
  ARG BASE_IMAGE=722377226063.dkr.ecr.eu-central-1.amazonaws.com/geth-base:base-XXXXXX
  ```

### Regular Deployment:

- [ ] 1. Make code changes
- [ ] 2. Create PR
- [ ] 3. Add label `CI:Deploy`
- [ ] 4. Merge PR → Triggers build + test
- [ ] 5. Verify tests pass
- [ ] 6. Note validated image tag: `pre-XXXXXX`
- [ ] 7. Update Helm values
  ```yaml
  # helm/geth-devnet/values.yaml
  image:
    tag: pre-XXXXXX
  ```
- [ ] 8. Create new PR with Helm update
- [ ] 9. Add label `HelmDeploy`
- [ ] 10. Merge PR → Deploys to EKS

---

## 🔧 Troubleshooting

### Image not found in ECR

```bash
# List available images
aws ecr describe-images --repository-name geth-base --region eu-central-1
aws ecr describe-images --repository-name geth-devnet-pre --region eu-central-1
```

### Pod not starting in EKS

```bash
# Get pod status
kubectl get pods -n devnet

# Check pod logs
kubectl logs -n devnet <pod-name>

# Describe pod (events)
kubectl describe pod -n devnet <pod-name>
```

### Hardhat tests failing

```bash
# Run locally
cd hardhat
npm install
npx hardhat compile
npx hardhat test

# Test against local devnet
docker run -d -p 8545:8545 geth-devnet:latest
npx hardhat test --network localdevnet
```

---

## 📊 Metrics & Monitoring

### Build Times (current):

- Base image build: ~3-5 min
- Devnet image build: ~2-3 min
- Hardhat tests: ~30-60 sec
- Helm deployment: ~1-2 min

**Total deployment time**: ~10-15 min

### Optimization Opportunities:

1. ✅ Docker build cache → Save 40-60% build time
2. ✅ Reuse base image → No rebuild on every PR
3. ✅ Parallel test execution → Faster validation
4. ⏳ Pre-built contract artifacts → Skip compilation

---

## 🎯 Next Steps

1. **Implement optimized Docker structure** (see below)
2. **Add contract deployment persistence**
3. **Fix failing workflows**
4. **Add monitoring & alerting**
5. **Document rollback procedures**

---

## 📚 Related Documentation

- [Infrastructure Review](../infrastructure_review.md)
- [Helm Chart README](../helm/geth-devnet/README.md)
- [Hardhat README](../hardhat/README.md)
- [Terraform Modules](../terraform/README.md)
