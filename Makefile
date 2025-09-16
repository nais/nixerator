SHELL := bash

# Flake and package settings
FLAKE ?= .
OUTPUT ?= manifests-basic

# Common paths
RESULT := result
MANIFEST := manifests.yaml

.PHONY: help build print show fmt check dev manifests apply apply-result clean

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Available targets\n-----------------\n"} /^[a-zA-Z0-9_.-]+:.*?##/ { printf "  %-16s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build manifests to ./result via Nix.
	nix build $(FLAKE)#$(OUTPUT)

print: ## Print the built YAML from ./result.
	@test -e $(RESULT) || { echo "Run 'make build' first"; exit 1; }
	@echo
	@cat $(RESULT)

show: ## Show flake outputs.
	nix flake show $(FLAKE)

fmt: ## Format Nix files using flake formatter.
	nix fmt

check: ## Run flake checks.
	nix flake check $(FLAKE)

dev: ## Enter the dev shell.
	nix develop $(FLAKE)

manifests: build ## Copy built YAML to ./manifests.yaml.
	cp -f $(RESULT) $(MANIFEST)
	@echo "Wrote $(MANIFEST)"

apply: manifests ## Apply manifests.yaml with kubectl.
	kubectl apply -f $(MANIFEST)

apply-result: build ## Apply ./result directly with kubectl.
	kubectl apply -f $(RESULT)

clean: ## Remove build artifacts (result symlink and manifests.yaml).
	rm -f $(RESULT) $(MANIFEST)

