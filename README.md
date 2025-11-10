TESTING BASE BUILD AND PUSH

Custom go-ethereum (Geth) CI/CD & Infrastructure Setup

This repository extends the official go-ethereum
 project with a complete CI/CD and infrastructure pipeline that builds, tests, and deploys Ethereum development networks automatically.

📘 Overview

The setup adds:

Automated Docker image builds for Geth and devnet variants:

CI:Base → Builds and pushes the base runtime image (Alpine + dependencies).

CI:Build → Builds and pushes the main go-ethereum image to ECR.

CI:Deploy → Builds and pushes a pre-deployed devnet with Hardhat contracts.

Terraform Infrastructure for creating and managing the ECR registry and repositories.

GitHub Actions Workflows for:

Terraform plan & apply on PRs and merges.

Manual Terraform destroy (with confirmation).

Docker image build/push triggered by PR labels.

Docker Compose definition for running a local devnet environment.

🧩 Directory Structure
.
├── .github/workflows/
│   ├── ci-build-base.yml         # Builds the base Docker image (CI:Base)
│   ├── ci-build.yml              # Builds main go-ethereum image (CI:Build)
│   ├── ci-deploy.yml             # Builds pre-deployed devnet image (CI:Deploy)
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
│   ├── backend.hcl               # Remote backend configuration
│   ├── main.tf                   # Root Terraform config (calls module)
│   ├── variables.tf
│   └── modules/
│       └── ecr/
│           ├── main.tf
│           ├── locals.tf
│           ├── outputs.tf
│           ├── variables.tf
│           └── versions.tf
│
├── docker-compose.yml            # Local devnet runner
└── README.md                     # This file

⚙️ Workflows Summary
Workflow	Trigger	Purpose
Build Base (CI:Base)	PR merge with label CI:Base	Builds and pushes base runtime image to ECR
Build (CI:Build)	PR merge with label CI:Build	Builds geth image and pushes to ECR
Deploy (CI:Deploy)	PR merge with label CI:Deploy	Runs devnet + deploys Hardhat sample contracts
Terraform Plan	PR touching terraform/**	Runs terraform plan and comments output on PR
Terraform Apply	Merge to master	Runs terraform apply automatically
Terraform Destroy	Manual via Actions	Destroys Terraform-managed infra (with typed confirmation)
🧰 Local Development Setup
1. Prerequisites

Install the following locally:

Docker

Terraform ≥ 1.5

AWS CLI v2

GitHub CLI
 (optional)

Ensure you are authenticated to AWS:

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


Your local devnet will start with Geth RPC enabled at:

http://localhost:8545

3. Terraform Setup
📁 Initialize Backend

Ensure terraform/backend.hcl contains your backend configuration:

bucket         = "my-terraform-state"
key            = "ecr/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "terraform-locks"
encrypt        = true


Initialize and validate locally:

cd terraform
terraform init -backend-config=backend.hcl
terraform validate

4. Deploy AWS ECR Registry
Run Plan
terraform plan -out=tfplan.binary

Apply
terraform apply tfplan.binary


This creates:

The ECR registry configuration

Repositories:

geth-base

geth-devnet

geth-devnet-pre

🪣 ECR Module Details
Inputs
Name	Type	Default	Description
enable_registry_scanning	bool	true	Enables enhanced scanning
registry_scan_frequency	string	"SCAN_ON_PUSH"	Frequency of scans
repositories	map(object)	—	Map of repos with lifecycle & encryption configs
replication_rules	list(object)	[]	Optional replication setup
tags	map(string)	{}	Global tags for resources
Outputs
Name	Description
repository_urls	Map of repo name → URL
repository_arns	Map of repo name → ARN
☁️ GitHub Setup
Secrets

Set in Repo → Settings → Secrets and variables → Actions → Secrets:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

Variables

Set in Repo → Settings → Secrets and variables → Actions → Variables:

AWS_REGION

ECR_REPO (e.g. geth-devnet)

AWS_ACCOUNT_ID

🧨 Manual Terraform Destroy

To clean up all resources:

Go to Actions → Terraform Destroy (manual)

Click Run workflow

Type DESTROY to confirm

(Optional) Set auto_approve = true

Example manual run:

terraform destroy -auto-approve

🧩 Running the Full CI/CD Flow

Fork the go-ethereum repo.

Create branches for pipelines:

git checkout -b ci/build-pipeline
git checkout -b ci/deploy-pipeline
git checkout -b infra/terraform
git checkout -b infra/compose


Commit and push your changes.

Create a PR to master with one of the labels:

CI:Base

CI:Build

CI:Deploy

Merge the PR → the corresponding workflow runs automatically.

🧱 Example Local Workflow Test

If you just want to test your workflow logic without pushing to ECR:

on:
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test local build
        run: docker build -f docker/base/Dockerfile -t base_image:test .

🧩 Next Steps

Coming up next in the workflow:

docker-compose integration for Hardhat + devnet.

Hardhat sample project deployment on CI:Deploy.

Terraform EKS deployment module (optional).