SHELL := bash

# Flake and package settings
FLAKE ?= .
OUTPUT ?= manifests-basic
MODULE_OUTPUT ?= manifests-module-basic
DOC_OUTPUT ?= docs-org

# Common paths
RESULT := result
MANIFEST := manifests.yaml
MANIFEST_MODULE := manifests-module.yaml
DOC := nixerator-options.org

.PHONY: help all build print build-module print-module show fmt check dev \
        manifests manifests-module apply apply-result docs print-docs \
        test update-golden kubeconform clean

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Available targets\n-----------------\n"} /^[a-zA-Z0-9_.-]+:.*?##/ { printf "  %-24s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

all: manifests manifests-module docs ## Build both manifest flavors and docs.

build: ## Build manifests to ./result via Nix (OUTPUT=$(OUTPUT)).
	nix build $(FLAKE)#$(OUTPUT)

print: ## Print YAML from ./result (built via OUTPUT).
	@test -e $(RESULT) || { echo "Run 'make build' first"; exit 1; }
	@echo
	@cat $(RESULT)

build-module: ## Build module-evaluated manifests (MODULE_OUTPUT=$(MODULE_OUTPUT)).
	nix build $(FLAKE)#$(MODULE_OUTPUT)

print-module: ## Print YAML from ./result (built via MODULE_OUTPUT).
	@test -e $(RESULT) || { echo "Run 'make build-module' first"; exit 1; }
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

manifests-module: build-module ## Copy module-built YAML to ./manifests-module.yaml.
	cp -f $(RESULT) $(MANIFEST_MODULE)
	@echo "Wrote $(MANIFEST_MODULE)"

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
	rm -f $(RESULT) $(MANIFEST) $(MANIFEST_MODULE) $(DOC)

test: ## Run golden tests and kubeconform (requires nix and yq; kubeconform optional).
	bash tests/run.sh

update-golden: ## Rebuild and update goldens (OUTPUT/MODULE_OUTPUT configurable).
	UPDATE_GOLDEN=1 bash tests/run.sh

kubeconform: ## Validate manifests with kubeconform (reads ./result or builds first).
	@if [ ! -e $(RESULT) ]; then nix build $(FLAKE)#$(OUTPUT); fi
	@command -v kubeconform >/dev/null 2>&1 || { echo "kubeconform not found in PATH"; exit 1; }
	kubeconform -strict -ignore-missing-schemas -summary -output pretty -exit-on-error - < $(RESULT)
