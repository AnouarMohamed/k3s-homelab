# Variables for bootstrap-cni
GATEWAY_API_VERSION := v1.2.0
CILIUM_CHART_VERSION := 1.15.0
CILIUM_NAMESPACE := kube-system

.PHONY: help lint validate bootstrap-nodes upgrade-k3s reset bootstrap-cni

help:
	@echo "Available targets:"
	@echo "  help        Show this help message"
	@echo "  lint        Run linters"
	@echo "  validate    Run validation scripts"
	@echo "  bootstrap-nodes   Bootstrap the cluster (harden nodes and deploy k3s HA)"
	@echo "  upgrade-k3s       Upgrade k3s cluster (rolling update)"
	@echo "  reset             Teardown the cluster (remove k3s and kube-vip)"
	@echo "  bootstrap-cni     Install Gateway API CRDs and Cilium (kube-proxy replacement)"

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

bootstrap-cni:
	@echo "Installing Gateway API CRDs version $(GATEWAY_API_VERSION)..."
	@curl -L https://github.com/kubernetes-sigs/gateway-api/releases/download/$(GATEWAY_API_VERSION)/standard-install.yaml | kubectl apply -f -
	@echo "Adding Helm repo for Cilium..."
	@helm repo add cilium https://helm.cilium.io/ 2>/dev/null || echo "Repo already exists"
	@helm repo update
	@echo "Installing Cilium chart version $(CILIUM_CHART_VERSION) in namespace $(CILIUM_NAMESPACE)..."
	@helm install cilium cilium/cilium \
	  --namespace $(CILIUM_NAMESPACE) \
	  --version $(CILIUM_CHART_VERSION) \
	  -f platform/cilium/values.yml \
	  --wait
	@echo "Applying CiliumLoadBalancerIPPool..."
	@kubectl apply -f platform/cilium/cilium-lb-ippool.yaml
	@echo "Applying CiliumL2AnnouncementPolicy..."
	@kubectl apply -f platform/cilium/cilium-l2-policy.yaml
	@echo "Waiting for Cilium agent rollout..."
	@kubectl rollout status daemonset/cilium -n $(CILIUM_NAMESPACE) --timeout=5m
	@echo "Waiting for Cilium operator rollout..."
	@kubectl rollout status deployment/cilium-operator -n $(CILIUM_NAMESPACE) --timeout=5m
	@echo "Cilium installation complete. Run 'cilium status --wait' to verify."