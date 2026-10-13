# Run bounded chaos experiments

Only run this from the private administration path during a maintenance window. The
experiments target the sacrificial `chaos-testing` namespace, never production.

## Preflight

```bash
kubectl get namespaces -o json | \
  yq -r '.items[] | select(.metadata.annotations."chaos-mesh.org/inject" == "enabled") | .metadata.name'
kubectl -n chaos-testing get deploy,pods,pdb,networkpolicy
kubectl -n chaos-mesh get deploy,daemonset,pods
```

The first command must print only `chaos-testing`. All three target replicas and every
Chaos Mesh controller must be Ready. Start the baseline k6 scenario from a controlled
runner and record its start time.

Run `make test-chaos CONFIRM_CHAOS=homelab`. The script repeats the namespace boundary
check, performs a server-side dry run, and then submits the four experiment files. It
does not run when any other namespace opts in.

## Observe and abort

```bash
kubectl -n chaos-testing get podchaos,networkchaos,stresschaos,iochaos -w
kubectl -n chaos-testing get events --sort-by=.lastTimestamp
kubectl -n chaos-testing delete -k platform/chaos-mesh/experiments
```

Abort immediately if an object selects another namespace, the Kubernetes API or etcd
degrades, or non-test workloads show injected faults. The delete command removes only
the experiment CRs; verify target pods recover before ending the window. Record actual
results in the drill journal. Execution remains `not run yet`.
