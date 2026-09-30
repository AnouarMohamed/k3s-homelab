.PHONY: help lint validate bootstrap teardown

help:
	@echo "Available targets:"
	@echo "  help        Show this help message"
	@echo "  lint        Run linters"
	@echo "  validate    Run validation scripts"
	@echo "  bootstrap   Bootstrap the cluster (not implemented until phase 1)"
	@echo "  teardown    Teardown the cluster (not implemented until phase 5)"

lint:
	@echo "Running linters..."
	# This will be implemented with pre-commit and other linters in later phases
	@echo "Linting not fully implemented yet; run 'pre-commit run --all-files' for pre-commit hooks."

validate:
	@echo "Running validation..."
	# This will be implemented with kubeconform, kube-linter, etc. in later phases
	@echo "Validation not fully implemented yet."

bootstrap:
	@echo "not implemented until phase 1"

teardown:
	@echo "not implemented until phase 5"