SHELL := /usr/bin/env bash
REPOSITORY_ROOT := $(CURDIR)
TOOL_BIN := $(REPOSITORY_ROOT)/.tools/bin
export PATH := $(TOOL_BIN):$(PATH)

.DEFAULT_GOAL := help

.PHONY: help tools lint validate security bootstrap bootstrap-nodes upgrade-k3s reset \
	bootstrap-cni bootstrap-gitops bootstrap-platform test tofu-plan teardown

help: ## Show all supported targets
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\nTargets:\n"} \
		/^[a-zA-Z0-9_-]+:.*## / {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

tools: ## Install pinned local validation tools into .tools/bin
	@scripts/install-tools.sh

lint: ## Lint YAML, Markdown, shell, and Ansible sources
	@git ls-files -co --exclude-standard -z -- '*.yaml' '*.yml' | \
		while IFS= read -r -d '' file; do \
			[[ -f "$$file" ]] && printf '%s\0' "$$file"; \
		done | xargs -0 -r yamllint
	@markdownlint-cli2
	@shellcheck scripts/*.sh
	@ansible-lint infra/ansible

validate: ## Validate repository policy and Kubernetes manifests
	@scripts/check-forbidden-files.sh
	@scripts/check-private-values.sh
	@scripts/check-pins.sh
	@scripts/validate-manifests.sh

security: ## Scan the complete Git history for secrets
	@gitleaks git --redact --verbose --log-opts=--all

bootstrap: bootstrap-nodes bootstrap-cni bootstrap-gitops bootstrap-platform ## Run the documented bootstrap sequence

bootstrap-nodes: ## Provision and harden the three k3s servers
	@ansible-playbook -i infra/ansible/inventory/hosts.yaml infra/ansible/site.yaml

upgrade-k3s: ## Perform a guarded rolling k3s upgrade
	@ansible-playbook -i infra/ansible/inventory/hosts.yaml infra/ansible/upgrade.yaml

reset: ## Reset k3s only when CONFIRM_RESET=homelab is supplied
	@test "$(CONFIRM_RESET)" = homelab || \
		{ printf 'Refusing reset; use CONFIRM_RESET=homelab after reading the runbook.\n' >&2; exit 1; }
	@ansible-playbook -i infra/ansible/inventory/hosts.yaml infra/ansible/reset.yaml

bootstrap-cni: ## Install Gateway API CRDs and Cilium
	@scripts/bootstrap-cni.sh

bootstrap-gitops: ## Bootstrap Argo CD and its root application
	@scripts/bootstrap-gitops.sh

bootstrap-platform: ## Synchronize the platform through Argo CD
	@scripts/bootstrap-platform.sh

test: ## Run application unit and integration tests
	@$(MAKE) -C apps/sentinel test

tofu-plan: ## Produce non-destructive OpenTofu plans
	@tofu -chdir=infra/tofu init -backend=false
	@tofu -chdir=infra/tofu validate
	@tofu -chdir=infra/tofu plan -lock=false

teardown: ## Alias for the guarded reset target
	@$(MAKE) reset CONFIRM_RESET="$(CONFIRM_RESET)"
