# ============================================
# Geth DevOps Makefile
# ============================================
# Simplified commands for building and managing Docker images

.PHONY: help build-base build-devnet build-all test-local deploy-local clean

# Default target
help:
	@echo "🚀 Geth DevOps Commands"
	@echo ""
	@echo "Docker Image Management:"
	@echo "  make build-base          Build base image with geth binary"
	@echo "  make build-devnet        Build devnet image (requires base)"
	@echo "  make build-all           Build both base and devnet images"
	@echo ""
	@echo "Testing:"
	@echo "  make test-local          Run Hardhat tests against local devnet"
	@echo "  make deploy-local        Start local devnet with docker-compose"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean               Remove local images and containers"
	@echo "  make logs                Show devnet logs"
	@echo "  make shell               Open shell in running devnet container"
	@echo ""
	@echo "ECR Operations:"
	@echo "  make ecr-login           Login to AWS ECR"
	@echo "  make ecr-push-base       Push base image to ECR"
	@echo "  make ecr-push-devnet     Push devnet image to ECR"
	@echo ""

# Variables
REGISTRY ?= 722377226063.dkr.ecr.eu-central-1.amazonaws.com
BASE_REPO ?= geth-base
DEVNET_REPO ?= geth-devnet-pre
AWS_REGION ?= eu-central-1

# Generate short SHA for tagging
SHORT_SHA := $(shell git rev-parse --short=6 HEAD)
BASE_TAG ?= base-$(SHORT_SHA)
DEVNET_TAG ?= pre-$(SHORT_SHA)

BASE_IMAGE_LOCAL := $(BASE_REPO):$(BASE_TAG)
BASE_IMAGE_ECR := $(REGISTRY)/$(BASE_REPO):$(BASE_TAG)
DEVNET_IMAGE_LOCAL := $(DEVNET_REPO):$(DEVNET_TAG)
DEVNET_IMAGE_ECR := $(REGISTRY)/$(DEVNET_REPO):$(DEVNET_TAG)

# ============================================
# Build Commands
# ============================================

build-base:
	@echo "🔨 Building base image: $(BASE_IMAGE_LOCAL)"
	docker buildx build \
		-f docker/base/Dockerfile \
		-t $(BASE_IMAGE_LOCAL) \
		--load \
		.
	@echo "✅ Base image built: $(BASE_IMAGE_LOCAL)"

build-devnet: build-base
	@echo "🔨 Building devnet image: $(DEVNET_IMAGE_LOCAL)"
	docker buildx build \
		-f docker/devnet/Dockerfile \
		-t $(DEVNET_IMAGE_LOCAL) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE_LOCAL) \
		--build-arg INCLUDE_CONTRACTS=true \
		--load \
		.
	@echo "✅ Devnet image built: $(DEVNET_IMAGE_LOCAL)"

build-all: build-base build-devnet
	@echo "✅ All images built successfully!"
	@docker images | grep -E "geth-base|geth-devnet"

# ============================================
# Testing Commands
# ============================================

test-local: build-devnet
	@echo "🧪 Starting devnet for testing..."
	docker run -d --name geth-test \
		-p 8545:8545 \
		$(DEVNET_IMAGE_LOCAL)
	@echo "⏳ Waiting for RPC..."
	@bash -c 'for i in {1..30}; do \
		if curl -sf -H "Content-Type: application/json" \
			-d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"web3_clientVersion\",\"params\":[]}" \
			http://localhost:8545 > /dev/null; then \
			echo "✅ RPC ready"; break; \
		fi; \
		sleep 1; \
	done'
	@echo "🧪 Running Hardhat tests..."
	cd hardhat && npm test
	@echo "🛑 Stopping test container..."
	docker rm -f geth-test
	@echo "✅ Tests completed!"

deploy-local:
	@echo "🚀 Starting local devnet with docker-compose..."
	cd docker-compose && docker-compose up -d
	@echo "✅ Devnet running at http://localhost:8545"
	@echo "   Blockscout UI: http://localhost:3000"
	@echo ""
	@echo "To stop: make stop-local"

stop-local:
	@echo "🛑 Stopping local devnet..."
	cd docker-compose && docker-compose down
	@echo "✅ Stopped"

logs:
	cd docker-compose && docker-compose logs -f geth

# ============================================
# ECR Operations
# ============================================

ecr-login:
	@echo "🔐 Logging in to ECR..."
	aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(REGISTRY)
	@echo "✅ Logged in to ECR"

ecr-push-base: ecr-login build-base
	@echo "📤 Pushing base image to ECR..."
	docker tag $(BASE_IMAGE_LOCAL) $(BASE_IMAGE_ECR)
	docker push $(BASE_IMAGE_ECR)
	@echo "✅ Pushed: $(BASE_IMAGE_ECR)"

ecr-push-devnet: ecr-login build-devnet
	@echo "📤 Pushing devnet image to ECR..."
	docker tag $(DEVNET_IMAGE_LOCAL) $(DEVNET_IMAGE_ECR)
	docker push $(DEVNET_IMAGE_ECR)
	@echo "✅ Pushed: $(DEVNET_IMAGE_ECR)"
	@echo ""
	@echo "📝 Update helm/geth-devnet/values.yaml:"
	@echo "   image:"
	@echo "     tag: $(DEVNET_TAG)"

ecr-push-all: ecr-push-base ecr-push-devnet
	@echo "✅ All images pushed to ECR!"

# ============================================
# Utilities
# ============================================

clean:
	@echo "🧹 Cleaning up..."
	docker rm -f geth-test 2>/dev/null || true
	docker rmi $(BASE_IMAGE_LOCAL) 2>/dev/null || true
	docker rmi $(DEVNET_IMAGE_LOCAL) 2>/dev/null || true
	@echo "✅ Cleaned"

shell:
	@echo "🐚 Opening shell in devnet container..."
	docker exec -it geth-devnet /bin/bash

# Show current configuration
info:
	@echo "📋 Current Configuration:"
	@echo "  Registry: $(REGISTRY)"
	@echo "  Base Image: $(BASE_IMAGE_ECR)"
	@echo "  Devnet Image: $(DEVNET_IMAGE_ECR)"
	@echo "  Git SHA: $(SHORT_SHA)"
