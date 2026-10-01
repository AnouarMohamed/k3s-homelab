# k3s-homelab

Production-grade, GitOps-managed Kubernetes homelab as a public portfolio repository.

## Planned Architecture

```mermaid
graph TD
    subgraph Internet
        CF[Cloudflare Tunnel]
    end
    subgraph LAN
        subgraph Control Plane
            CP1[pc-1: k3s server]
            CP2[pc-2: k3s server]
            CP3[pc-3: k3s server]
            VIP[kube-vip VIP]
        end
        subgroup Worker Nodes
            WN1[pc-1: k3s agent]
            WN2[pc-2: k3s agent]
            WN3[pc-3: k3s agent]
        end
        subgroup Network
            Cilium[cni: Cilium]
            KVIP[kube-vip: LB/VP]
        end
        subgroup Storage
            Longhorn[longhorn-system]
        end
        subgroup GitOps
            ArgoCD[argo-cd: Application controller]
            AppOfApps[ApplicationSet: app-of-apps]
        end
        subgroup Platform
            CertManager[cert-manager]
            OpenBao[openbao]
            ExternalSecrets[external-secrets]
        end
        subgroup Observability
            Monitoring[prometheus-stack]
            Logging[loki]
            Tracing[tempo]
        end
        subgroup Policies
            Kyverno[kyverno-policies]
        end
        subgroup Apps
            DemoApp[apps/demo]
            SelfHosted[apps/self-hosted]
        end
    end

    CF -->|HTTPS/TLS| VIP
    VIP --> CP1 & CP2 & CP3
    CP1 & CP2 & CP3 --> Cilium
    Cilium --> WN1 & WN2 & WN3
    WN1 & WN2 & WN3 --> Longhorn
    WN1 & WN2 & WN3 --> Platform
    WN1 & WN2 & WN3 --> Observability
    WN1 & WN2 & WN3 --> Policies
    WN1 & WN2 & WN3 --> Apps
    ArgoCD --> AppOfApps
    AppOfApps --> Platform
    AppOfApps --> Observability
    AppOfApps --> Policies
    AppOfApps --> Apps
```

## Phases Status

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Repository skeleton and tooling | ✅ done |
| 1 | Bootstrap clusters with k3s | ⬜ not started |
| 2 | Install platform components (Cilium, cert-manager, etc.) | 🟡 preparation completed |
| 3 | Deploy Argo CD and app-of-apps | ⬜ not started |
| 4 | Add observability stack | ⬜ not started |
| 5 | Add policy engine | ⬜ not started |
| 6 | Deploy demo and self-hosted apps | ⬜ not started |