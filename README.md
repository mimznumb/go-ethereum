TEST HELM DEPLOY
🚀 Custom go-ethereum (Geth) CI/CD & Infrastructure Setup

This repository extends the official go-ethereum (Geth) implementation with a complete CI/CD pipeline, Terraform-managed infrastructure, a local devnet environment, smart contract deployment workflow, and a Blockscout explorer.

It enables fully automated builds, tests, devnet deployments, and infrastructure provisioning.

📘 Overview

The system adds:

🔧 Automated Docker Image Build Pipeline
Label	Purpose
CI:Base	Builds and pushes the base runtime image (Alpine + deps)
CI:Build	Builds and pushes the main go-ethereum devnet image
CI:Deploy	Spins up devnet → deploys Hardhat contracts → runs tests → (later) builds pre-deployed image
🏗 Terraform Infrastructure

Provisioned using clean Terraform modules:

ECR module → creates repositories for base/devnet/prebuilt images

VPC module → minimal network (private + public subnets)

EKS module → small cluster, IRSA enabled, ECR pull permissions

⚙️ GitHub Workflows

Terraform plan on PR

Terraform apply on merge

Terraform destroy (manual)

Build base image (CI:Base)

Build Geth devnet image (CI:Build)

Hardhat CI tests against Geth image (CI:Deploy)

Helm chart deployment to EKS

🧪 Hardhat Smart Contract Testing

Built-in Counter.ts test suite

Tests run automatically in CI against running Geth devnet

Uses prefunded Hardhat signer

Verified locally and in GitHub Actions

🗂 Local Dev Environment

A Docker Compose setup with:

Geth devnet RPC

Blockscout API

Blockscout UI

PostgreSQL

Allows full debugging & viewing transactions in a UI.

🧩 Directory Structure
.
├── .github/workflows/
│   ├── ci-build-base.yml
│   ├── ci-build.yml
│   ├── ci-deploy.yml
│   ├── hardhat-test.yml
│   ├── helm-deploy.yml
│   ├── terraform-plan.yml
│   ├── terraform-apply.yml
│   └── terraform-destroy.yml
│
├── docker/
│   ├── base/Dockerfile
│   └── devnet/Dockerfile
│
├── docker-compose.yml
│
├── terraform/
│   ├── backend.tfvars
│   ├── main.tf
│   ├── variables.tf
│   ├── locals.tf
│   ├── versions.tf
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       └── ecr/
│
├── helm/
│   └── geth-devnet/                # Helm chart for deploying devnet to EKS
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
├── hardhat/
│   ├── contracts/
│   ├── scripts/deploy.ts
│   ├── hardhat.config.ts
│   ├── test/Counter.ts
│   └── package.json
└── README.md

⚙️ Workflows Summary
Workflow	Trigger	Purpose
Build Base (CI:Base)	PR merge + label	Builds & pushes base image
Build Geth (CI:Build)	PR merge + label	Builds main devnet runtime
CI:Deploy	PR merge + label	Spins up devnet → runs Hardhat tests
Hardhat Test	Part of CI:Deploy	Executes test/Counter.ts
Terraform Plan	PR touching terraform/**	Generates plan
Terraform Apply	Push to master	Applies infra
Terraform Destroy	Manual	Destroys infra
Helm Deploy	PR merge + label	Installs chart to EKS
🧰 Local Development Setup
1. Install Prerequisites

Docker

Terraform ≥ 1.5

AWS CLI v2

Node 22 (required for Hardhat 3)

jq (for JSON-RPC helpers)

Authenticate:

aws configure

2. Build Docker Images Locally
Base Image
cd docker/base
docker build -t base_image:go-eth .

Devnet Image
cd docker/devnet
docker build -t devnet:latest .

3. Run Local Devnet With Blockscout
export DEVNET_IMAGE=722377226063.dkr.ecr.eu-central-1.amazonaws.com/geth-devnet:devnet-816414
docker compose up


Services exposed:

Component	URL
Geth RPC	http://localhost:8545

Blockscout API	http://localhost:4000

Blockscout UI	http://localhost:3000
4. Hardhat Local Usage
cd hardhat
npm ci
npx hardhat test --network localdevnet


Default signer is prefunded in local Geth via CI script.

☁️ Terraform Setup

Initialize backend:

cd terraform
terraform init -backend-config=backend.tfvars
terraform validate


Plan:

terraform plan


Apply:

terraform apply


Creates:

VPC

Public & private subnets

NAT (optional)

EKS cluster + node group

ECR repositories

🎛 EKS & Helm Chart Deployment

Terraform outputs:

cluster_name

cluster_endpoint

kubeconfig_yaml

IRSA role

public/private subnets

Install helm chart manually
aws eks update-kubeconfig --name geth-devnet-cluster --region eu-central-1

helm upgrade --install geth-devnet ./helm/geth-devnet \
  --set image.repository=722377226063.dkr.ecr.eu-central-1.amazonaws.com/geth-devnet \
  --set image.tag=devnet-latest

GitHub Actions Pipeline (helm-deploy.yml)

Automatically:

fetches kubeconfig from Terraform output

logs into EKS

installs/updates chart

💎 Hardhat Project

The hardhat project includes:

TypeScript configuration

Sample contract Lock.sol

Counter test

Custom deployment script

Configured localdevnet network

Network Config:
localdevnet: {
  type: "http",
  url: "http://127.0.0.1:8545",
  accounts: [
    process.env.DEPLOYER_PK
  ],
}

🧪 CI: Hardhat Counter Test

Runs inside CI:Deploy:

Pulls latest devnet image from ECR

Starts Geth devnet container

Waits for RPC

Funds Hardhat signer

Runs:

npx hardhat test test/lock.pre.test.ts --network localdevnet


Tears down container

Successful output example:

Counter
  ✓ Should emit the Increment event...
  ✓ The sum of the Increment events...

🛠 Manual Utilities
Get first account from devnet
curl -s -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_accounts","params":[]}' \
  http://localhost:8545

Send ETH from devnet signer
curl -s -H 'content-type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$DEV\",\"to\":\"$TARGET\",\"value\":\"0x56BC75E2D63100000\"}]}" \
  http://localhost:8545