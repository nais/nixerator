SHELL := bash

# Flake and package settings
FLAKE ?= .
OUTPUT ?= manifests
DOC_OUTPUT ?= docs

# Common paths
RESULT := result
MANIFEST := manifests.yaml
DOC := nixerator-options.org

.PHONY: help all build print \
        show fmt check dev manifests \
        apply apply-result docs print-docs print-json test update-golden clean

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Available targets\n-----------------\n"} /^[a-zA-Z0-9_.-]+:.*?##/ { printf "  %-24s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

all: manifests docs ## Build manifests and docs.

build: ## Build manifests to ./result via Nix (OUTPUT=$(OUTPUT)).
	nix build $(FLAKE)#$(OUTPUT)

print: ## Print YAML from ./result (built via OUTPUT).
	@test -e $(RESULT) || { echo "Run 'make build' first"; exit 1; }
	@echo
	@cat $(RESULT)

print-json: ## Print pretty JSON, '---' delimited, from ./result.
	@test -e $(RESULT) || { echo "Run 'make build' or 'make build-module' first"; exit 1; }
	@command -v yq >/dev/null 2>&1 || { echo "yq not found; enter dev shell (make dev)"; exit 1; }
	@i=0; first=1; \
	while true; do \
	  out=$$(yq -o=json -I 2 'select(documentIndex == $$i)' $(RESULT) 2>/dev/null); \
	  if [ -z "$$out" ]; then break; fi; \
	  if [ $$first -eq 0 ]; then printf "\n---\n"; fi; \
	  printf "%s\n" "$$out"; \
	  first=0; i=$$((i+1)); \
	done


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

docs: ## Build Org docs and write to ./$(DOC) (DOC_OUTPUT=$(DOC_OUTPUT)).
	nix build $(FLAKE)#$(DOC_OUTPUT)
	cp -f $(RESULT) $(DOC)
	@echo "Wrote $(DOC)"

print-docs: ## Print the generated Org docs.
	@test -e $(RESULT) || { echo "Run 'make docs' first"; exit 1; }
	@echo
	@sed -n '1,200p' $(RESULT)

clean: ## Remove build artifacts and generated files.
	rm -f $(RESULT) $(MANIFEST) $(DOC)

test: ## Run golden tests (kubeconform runs via flake checks).
	bash tests/run.sh

update-golden: ## Rebuild and update goldens (OUTPUT configurable).
	UPDATE_GOLDEN=1 bash tests/run.sh
