# 🎨 Visual Deployment Flow

## Quick Reference Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COMPLETE DEPLOYMENT FLOW                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│ Developer    │
│ Makes Change │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Create PR    │
└──────┬───────┘
       │
       ├─────────────────────────────────────────────────────────────┐
       │                                                              │
       ▼                                                              ▼
┌─────────────────────┐                                    ┌─────────────────────┐
│ Label: CI:Base      │                                    │ Label: CI:Deploy    │
│ (Infrastructure)    │                                    │ (Application)       │
└─────────┬───────────┘                                    └─────────┬───────────┘
          │                                                          │
          ▼                                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        BUILD BASE IMAGE                                      │
│  Workflow: ci-build-base.yml                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Checkout code                                                           │
│  2. Setup Docker Buildx (with cache)                                        │
│  3. Build docker/base/Dockerfile                                            │
│     ├─ Stage 1: Compile geth (golang:1.23-alpine)                          │
│     └─ Stage 2: Runtime base (alpine:3.20 + geth binary)                   │
│  4. Tag: geth-base:base-XXXXXX                                             │
│  5. Push to ECR                                                             │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      │ Base image ready in ECR
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      BUILD & TEST DEVNET IMAGE                               │
│  Workflow: ci-deploy-ecr.yml                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Checkout merged code                                                    │
│  2. Login to ECR (to pull base image)                                       │
│  3. Setup Docker Buildx (with cache)                                        │
│  4. Build docker/devnet/Dockerfile                                          │
│     ├─ FROM geth-base:base-XXXXXX (from ECR)                               │
│     ├─ Stage 1: Compile smart contracts (node:22-alpine)                   │
│     │   ├─ npm ci (install Hardhat)                                         │
│     │   ├─ npx hardhat compile                                              │
│     │   └─ Copy artifacts to /opt/contracts                                 │
│     └─ Stage 2: Runtime (extends base image)                                │
│         └─ Copy contract artifacts                                          │
│  5. Tag: local/devnet:XXXXXX (local only)                                  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────┐        │
│  │                    TESTING PHASE                                │        │
│  ├────────────────────────────────────────────────────────────────┤        │
│  │  6. Start devnet container (port 8545)                          │        │
│  │  7. Wait for RPC ready (web3_clientVersion)                     │        │
│  │  8. Fund Hardhat default account                                │        │
│  │     └─ Transfer 100 ETH from dev account                         │        │
│  │  9. Setup Node.js 22                                             │        │
│  │  10. Install Hardhat dependencies (npm ci)                       │        │
│  │  11. Run Hardhat tests                                           │        │
│  │      ├─ npx hardhat clean                                        │        │
│  │      ├─ npx hardhat compile                                      │        │
│  │      └─ npx hardhat test test/Counter.ts                         │        │
│  │          ├─ Deploy Counter.sol                                   │        │
│  │          ├─ Test inc() function                                  │        │
│  │          └─ Test incBy(5) function                               │        │
│  │  12. Stop devnet container                                       │        │
│  └────────────────────────────────────────────────────────────────┘        │
│                                                                              │
│  IF TESTS PASS ✅:                                                          │
│  13. Retag: geth-devnet-pre:pre-XXXXXX                                     │
│  14. Push to ECR                                                            │
│  15. Generate deployment summary                                            │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      │ Validated image in ECR
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    UPDATE HELM VALUES (Manual)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Update helm/geth-devnet/values.yaml                                     │
│     image:                                                                   │
│       tag: pre-XXXXXX                                                        │
│  2. Create new PR                                                            │
│  3. Add label: HelmDeploy                                                    │
│  4. Merge PR                                                                 │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      DEPLOY TO KUBERNETES                                    │
│  Workflow: helm-deploy.yml                                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Checkout code                                                            │
│  2. Authenticate to AWS (OIDC)                                               │
│  3. Update kubeconfig for EKS                                                │
│  4. Install kubectl & helm                                                   │
│  5. Create namespace (if missing)                                            │
│  6. Deploy Helm chart                                                        │
│     ├─ helm upgrade --install geth-devnet                                   │
│     ├─ Uses image: geth-devnet-pre:pre-XXXXXX                              │
│     └─ Creates:                                                              │
│         ├─ Deployment (geth pod)                                             │
│         ├─ Service (LoadBalancer on port 8545)                               │
│         └─ ServiceAccount (with IRSA)                                        │
│  7. Wait for rollout (kubectl rollout status)                               │
│  8. Show service info                                                        │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RUNNING IN EKS                                       │
│  ✅ Pod running with validated image                                        │
│  ✅ LoadBalancer exposing RPC endpoint                                      │
│  ✅ Smart contracts available (if included)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Image Dependency Tree

```
golang:1.23-alpine
       │
       ▼ (build geth)
┌──────────────────┐
│  geth binary     │
└────────┬─────────┘
         │
         ▼
alpine:3.20 + geth binary + scripts
         │
         ▼
┌──────────────────────────────────┐
│  geth-base:base-XXXXXX           │
│  (pushed to ECR)                 │
└────────┬─────────────────────────┘
         │
         ├──────────────────────────────────┐
         │                                  │
         ▼                                  ▼
┌─────────────────────┐          ┌─────────────────────┐
│  geth-devnet        │          │  geth-production    │
│  + contracts        │          │  + prod config      │
│  + dev config       │          │  (future)           │
└─────────────────────┘          └─────────────────────┘
         │
         ▼
geth-devnet-pre:pre-XXXXXX
(validated & pushed to ECR)
```

---

## Smart Contract Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  hardhat/contracts/Counter.sol                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ contract Counter {                                       │   │
│  │   uint public x;                                         │   │
│  │   function inc() public { x++; }                         │   │
│  │   function incBy(uint by) public { x += by; }            │   │
│  │ }                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼ (npx hardhat compile)
┌─────────────────────────────────────────────────────────────────┐
│  hardhat/artifacts/contracts/Counter.sol/Counter.json            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ {                                                        │   │
│  │   "abi": [...],                                          │   │
│  │   "bytecode": "0x608060405234801561001057600080fd5b50..." │   │
│  │ }                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ├──────────────────────────────────────┐
                         │                                      │
                         ▼                                      ▼
         ┌───────────────────────────┐        ┌────────────────────────────┐
         │  OPTION 1: CI Testing     │        │  OPTION 2: Baked in Image  │
         │  (Current)                │        │  (Recommended)             │
         ├───────────────────────────┤        ├────────────────────────────┤
         │  1. Start devnet          │        │  1. Copy to /opt/contracts │
         │  2. Deploy via Hardhat    │        │  2. Include in image       │
         │  3. Run tests             │        │  3. Deploy on startup      │
         │  4. Container stops       │        │  4. Save addresses         │
         │  5. ❌ Contracts lost     │        │  5. ✅ Persistent          │
         └───────────────────────────┘        └────────────────────────────┘
```

---

## Workflow Trigger Matrix

| Workflow              | Trigger                    | Label Required | Purpose                    |
|-----------------------|----------------------------|----------------|----------------------------|
| `ci-build-base.yml`   | PR merge to master         | `CI:Base`      | Build base image           |
| `ci-deploy-ecr.yml`   | PR merge to master         | `CI:Deploy`    | Build, test, push devnet   |
| `helm-deploy.yml`     | PR merge to master         | `HelmDeploy`   | Deploy to EKS              |
| `terraform-plan.yml`  | PR to master (terraform/*) | None           | Plan infrastructure        |
| `terraform-apply.yml` | Push to master (terraform/*) | None         | Apply infrastructure       |
| `go.yml`              | PR to master               | None           | Run Go tests               |
| `validate_pr.yml`     | PR opened/updated          | None           | Validate PR                |

---

## Environment Variables Reference

### CI/CD Workflows

| Variable              | Used In                  | Purpose                          |
|-----------------------|--------------------------|----------------------------------|
| `AWS_REGION`          | All workflows            | AWS region                       |
| `ECR_REGISTRY`        | ci-build-base            | ECR registry hostname            |
| `ECR_DEPLOY_REGISTRY` | ci-deploy-ecr            | ECR registry for deployment      |
| `IMAGE_URI`           | ci-build-base            | Full base image URI              |
| `IMAGE_DEPLOY_URI`    | ci-deploy-ecr            | Full devnet image URI            |
| `BASE_IMAGE_URI`      | ci-deploy-ecr            | Base image to use for devnet     |
| `EKS_CLUSTER_NAME`    | helm-deploy              | EKS cluster name                 |
| `EKS_OIDC_ROLE_ARN`   | helm-deploy              | OIDC role for EKS access         |

### Docker Images

| Variable           | Default                  | Purpose                          |
|--------------------|--------------------------|----------------------------------|
| `GETH_DATADIR`     | `/home/geth/.ethereum`   | Geth data directory              |
| `GETH_HTTP_PORT`   | `8545`                   | HTTP RPC port                    |
| `GETH_WS_PORT`     | `8546`                   | WebSocket port                   |
| `GETH_HTTP_ADDR`   | `0.0.0.0`                | HTTP bind address                |
| `GETH_WS_ADDR`     | `0.0.0.0`                | WebSocket bind address           |
| `GETH_NETWORK`     | `dev`                    | Network type (dev/mainnet/etc)   |
| `GETH_API`         | `eth,net,web3,...`       | Enabled RPC APIs                 |

---

## Common Issues & Solutions

### Issue 1: Base image not found

**Symptom**: `ci-deploy-ecr.yml` fails with "image not found"

**Solution**:
```bash
# Check if base image exists
aws ecr describe-images --repository-name geth-base --region eu-central-1

# If missing, trigger base build:
# 1. Create PR with any change
# 2. Add label "CI:Base"
# 3. Merge PR
```

### Issue 2: Hardhat tests timeout

**Symptom**: Tests fail with "RPC not responding"

**Solution**:
```yaml
# Increase wait time in ci-deploy-ecr.yml
for i in {1..60}; do  # was {1..30}
```

### Issue 3: Contract deployment not persistent

**Symptom**: Contracts disappear after container restart

**Solution**: Use the new `deploy-contracts.sh` script:
```bash
# In docker/devnet/Dockerfile, add:
CMD ["/usr/local/bin/deploy-contracts.sh && /usr/local/bin/start-devnet.sh"]
```

### Issue 4: Build cache not working

**Symptom**: Builds are slow, no cache hits

**Solution**:
```yaml
# Ensure BuildKit is enabled in workflow:
- uses: docker/setup-buildx-action@v3
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## Performance Metrics

### Before Optimization

| Metric                  | Time      |
|-------------------------|-----------|
| Base image build        | 5-7 min   |
| Devnet image build      | 4-5 min   |
| Total CI time           | 15-20 min |
| Cache hit rate          | ~20%      |

### After Optimization (Expected)

| Metric                  | Time      | Improvement |
|-------------------------|-----------|-------------|
| Base image build        | 2-3 min   | 60% faster  |
| Devnet image build      | 1-2 min   | 65% faster  |
| Total CI time           | 8-12 min  | 45% faster  |
| Cache hit rate          | ~80%      | 4x better   |

---

## Next Steps Checklist

- [ ] Review and approve new Dockerfiles
- [ ] Test local build with `make build-all`
- [ ] Update GitHub repository variables:
  - [ ] `BASE_IMAGE_URI`
  - [ ] `ECR_REGISTRY`
  - [ ] `IMAGE_URI`
- [ ] Trigger base image build (CI:Base label)
- [ ] Update devnet Dockerfile with new base image tag
- [ ] Trigger devnet build (CI:Deploy label)
- [ ] Verify tests pass
- [ ] Deploy to EKS (HelmDeploy label)
- [ ] Monitor deployment
- [ ] Update documentation

---

## Related Files

- [Deployment Flow Documentation](./DEPLOYMENT_FLOW.md)
- [Infrastructure Review](../infrastructure_review.md)
- [Makefile](../Makefile)
- [Base Dockerfile](../docker/base/Dockerfile)
- [Devnet Dockerfile](../docker/devnet/Dockerfile)
