.PHONY: help lint validate bootstrap-nodes upgrade-k3s reset

help:
	@echo "Available targets:"
	@echo "  help        Show this help message"
	@echo "  lint        Run linters"
	@echo "  validate    Run validation scripts"
	@echo "  bootstrap-nodes   Bootstrap the cluster (harden nodes and deploy k3s HA)"
	@echo "  upgrade-k3s       Upgrade k3s cluster (rolling update)"
	@echo "  reset             Teardown the cluster (remove k3s and kube-vip)"

lint:
	@echo "Running linters..."
	# This will be implemented with pre-commit and other linters in later phases
	@echo "Linting not fully implemented yet; run 'pre-commit run --all-files' for pre-commit hooks."

validate:
	@echo "Running validation..."
	# This will be implemented with kubeconform, kube-linter, etc. in later phases
	@echo "Validation not fully implemented yet."

bootstrap-nodes:
	@echo "Bootstrapping nodes (hardening and k3s HA cluster)..."
	ansible-playbook -i infra/ansible/inventory/hosts.yml infra/ansible/site.yml

upgrade-k3s:
	@echo "Upgrading k3s cluster (rolling update)..."
	ansible-playbook -i infra/ansible/inventory/hosts.yml infra/ansible/upgrade.yml

reset:
	@echo "Tearing down the cluster..."
	ansible-playbook -i infra/ansible/inventory/hosts.yml infra/ansible/reset.yml