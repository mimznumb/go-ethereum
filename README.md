TEST DEPLOY PIPE

🚀 Custom go-ethereum (Geth) CI/CD & Infrastructure Setup

This repository extends the official go-ethereum (Geth) project with a complete CI/CD and infrastructure pipeline that builds, tests, and deploys Ethereum development networks automatically.

📘 Overview

The setup adds:

Automated Docker image builds for Geth and devnet variants:

CI:Base → Builds and pushes the base runtime image (Alpine + dependencies)

CI:Build → Builds and pushes the main go-ethereum image to ECR

CI:Deploy → Builds and pushes a pre-deployed devnet with Hardhat contracts (in progress)

Terraform Infrastructure for creating and managing the ECR registry and repositories.

GitHub Actions Workflows for:

Terraform plan & apply on PRs and merges

Manual Terraform destroy (with confirmation)

Docker image build/push triggered by PR labels

Docker Compose definition for running a local devnet environment

🧩 Directory Structure
.
├── .github/workflows/
│   ├── ci-build-base.yml         # Builds the base Docker image (CI:Base)
│   ├── ci-build.yml              # Builds main go-ethereum image (CI:Build)
│   ├── ci-deploy.yml             # Deploys contracts & builds pre-deployed devnet (WIP)
│   ├── terraform-plan.yml        # Runs terraform plan on PRs
│   ├── terraform-apply.yml       # Applies terraform on merge to master
│   ├── terraform-destroy.yml     # Manual destroy pipeline
│
├── docker/
│   ├── base/
│   │   └── Dockerfile            # Minimal Alpine base image
│   └── devnet/
│       └── Dockerfile            # Multi-stage Geth devnet build
│
├── terraform/
│   ├── backend.tfvars            # Remote backend config (S3 backend)
│   ├── main.tf                   # Root Terraform config (calls ECR module)
│   ├── locals.tf
│   ├── variables.tf
│   ├── versions.tf
│   └── modules/
│       └── ecr/
│           ├── main.tf
│           ├── locals.tf
│           ├── outputs.tf
│           ├── variables.tf
│           └── versions.tf
│
├── hardhat/                      # Hardhat project (contracts, scripts)
│   ├── contracts/Lock.sol
│   ├── scripts/deploy.ts
│   ├── hardhat.config.ts
│   └── package.json
│
├── docker-compose.yml            # Local devnet runner
└── README.md                     # This file

⚙️ Workflows Summary
Workflow	Trigger	Purpose
Build Base (CI:Base)	PR merge with label CI:Base	Builds and pushes base runtime image to ECR
Build (CI:Build)	PR merge with label CI:Build	Builds geth image and pushes to ECR
Deploy (CI:Deploy)	PR merge with label CI:Deploy	Runs devnet + deploys Hardhat sample contracts (in progress)
Terraform Plan	PR touching terraform/**	Runs terraform plan and comments output on PR
Terraform Apply	Merge to master	Runs terraform apply automatically
Terraform Destroy	Manual via Actions	Destroys Terraform-managed infra (with confirmation)
🧰 Local Development Setup
1. Prerequisites

Install the following locally:

Docker

Terraform ≥ 1.5

AWS CLI v2

GitHub CLI (optional)

Authenticate to AWS:

aws configure

2. Build and Test Docker Images Locally
🧱 Build Base Image
cd docker/base
docker build -t base_image:go-eth .

⚙️ Build Devnet Image
cd ../devnet
docker build \
  --build-arg BASE_IMAGE=base_image:go-eth \
  -t devnet:latest \
  -f Dockerfile .

🧪 Run a Local Devnet
docker-compose up


RPC is exposed at:

http://localhost:8545

3. Terraform Setup
📁 Initialize Backend

Use S3 native backend lock (no DynamoDB):

bucket  = "mariya-demo-test"
key     = "terraform/state/ecr.tfstate"
region  = "eu-central-1"
encrypt = true


Initialize:

cd terraform
terraform init -backend-config=backend.tfvars
terraform validate

4. Deploy AWS ECR Registry
Run Plan
terraform plan -out=tfplan.binary

Apply
terraform apply tfplan.binary


This creates:

ECR registry

Repositories:

geth-base

geth-devnet

🪣 ECR Module Details
Inputs
Name	Type	Default	Description
enable_registry_scanning	bool	true	Enables enhanced scanning
registry_scan_frequency	string	"SCAN_ON_PUSH"	Frequency of image scans
repositories	map(object)	—	Repos with lifecycle & encryption configs
tags	map(string)	{}	Global tags for resources
Outputs
Name	Description
repository_urls	Map of repo name → URL
repository_arns	Map of repo name → ARN
☁️ GitHub Setup
🔐 Secrets

Set in Repo → Settings → Secrets → Actions:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

⚙️ Variables

Set in Repo → Settings → Variables → Actions:

AWS_REGION

AWS_ACCOUNT_ID

ECR_REPO (e.g. geth-devnet)

⚡ Manually Triggering Workflows
🔹 Build Base (CI:Base)

Go to:
Actions → Build Base (CI:Base → ECR) → Click Run workflow

🔹 Build Main (CI:Build)

Triggered on PR merge with CI:Build label.

🔹 Terraform Plan

Auto-triggers on PRs that modify terraform/**.

🔹 Terraform Apply

Auto-triggers after merge to master.

🔹 Terraform Destroy

Manual only:
Actions → Terraform Destroy → Type DESTROY → Confirm.

🧱 Example Local Workflow Test

Test your workflow locally without ECR push:

on:
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test local build
        run: docker build -f docker/base/Dockerfile -t base_image:test .

💎 Hardhat Project (WIP)

A Hardhat project has been initialized under hardhat/ for deploying smart contracts to the local devnet.

Current setup:

Installed using:

npx hardhat init


TypeScript environment with Mocha + Ethers.js

Sample contract: Lock.sol

Deployment script: scripts/deploy.ts

Network config:

localdevnet: {
  type: "http",
  chainType: "l1",
  url: "http://127.0.0.1:8545",
  accounts: [
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
  ],
}


Next:

Running contract deployment to the local Geth devnet

Automating this in CI:Deploy pipeline

🧩 Next Steps

 Finalize Hardhat deployment to devnet

 Build Docker image with pre-deployed contracts

 Add Docker Compose for Geth + Hardhat integration

 Extend Terraform to deploy CI environment on EKS (optional)

 Add contract verification & smoke tests in CI