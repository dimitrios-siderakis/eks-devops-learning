# Kubernetes Learning Map — Nigel Poulton Source Analysis

> Generated: 2026-06-16  
> **Status: Reference document only. No material has been studied yet.**  
> This is an analysis of what exists in the source repos and how it maps to concepts.  
> For the active day-by-day study plan, use:  
> - Phase 1: [`roadmap/eks-2-week-focused.md`](../roadmap/eks-2-week-focused.md)  
> - Phase 2: [`roadmap/eks-4-week-roadmap.md`](../roadmap/eks-4-week-roadmap.md)  
>
> Sources: `repo_k8sbook` (TheK8sBook) · `repo_getting_started` (getting-started-k8s)  
> Purpose: Map every example to a concept, tier it, flag lab candidates, identify EKS gaps.

---

## Source File Inventory

### repo_getting_started

| File | Kind(s) | Concept |
|------|---------|---------|
| `Pods/pod.yml` | Pod | Minimal single-container pod |
| `Pods/multi-pod.yml` | Pod | Multi-container (adapter pattern: nginx + prometheus exporter) |
| `Deployments/deploy.yml` | Deployment | Basic Deployment, replicas, labels |
| `Deployments/deploy-complete.yml` | Deployment | RollingUpdate strategy, `maxSurge`, `minReadySeconds` |
| `Services/svc-lb.yml` | Service/LB | Cloud LoadBalancer service (port mapping) |
| `Services/svc-nodeport.yml` | Service/NodePort | NodePort, fixed port assignment |

### repo_k8sbook

| File | Kind(s) | Concept |
|------|---------|---------|
| `pods/pod.yml` | Pod | Pod with resource limits (`cpu`, `memory`) |
| `pods/initpod.yml` | Pod | Init container (DNS gate before main container) |
| `pods/sidecarpod.yml` | Pod | Sidecar pattern: git-sync + nginx, shared `emptyDir` volume |
| `pods/sidecar-cloud.yml` | Pod | Same as above, cloud variant |
| `deployments/deploy.yml` | Deployment | RollingUpdate, `progressDeadlineSeconds`, `revisionHistoryLimit` |
| `deployments/svc.yml` | Service/NodePort | NodePort service wired to Deployment |
| `deployments/lb.yml` | Service/LB | Cloud LoadBalancer wired to Deployment |
| `configmaps/singlemap.yml` | ConfigMap | File-based config injection |
| `configmaps/multimap.yml` | ConfigMap | Key-value config injection |
| `configmaps/cmpod.yml` | Pod | ConfigMap mounted as volume file |
| `configmaps/envpod.yml` | Pod | ConfigMap projected as env vars (`valueFrom`) |
| `configmaps/startuppod.yml` | Pod | ConfigMap env vars used in container command args |
| `configmaps/tkb-secret.yml` | Secret | Opaque Secret (base64 encoded credentials) |
| `configmaps/secretpod.yml` | Pod | Secret mounted as read-only volume |
| `namespaces/shield-ns.yml` | Namespace | Namespace creation with labels |
| `namespaces/shield-app.yml` | Pod/Service/SA | App in a named namespace, ServiceAccount |
| `namespaces/shield-pod.yml` | Pod | Pod scoped to namespace |
| `networking/svc.yml` | Service/ClusterIP | Internal ClusterIP service |
| `networking/nodeport.yml` | Service/NodePort | NodePort service |
| `networking/cloud-lb.yml` | Service/LB | Cloud LoadBalancer |
| `networking/ping.yml` | Pod | Network debug pod (DNS/connectivity testing) |
| `service-discovery/sd-example.yml` | Deployment/Service | Same service name in dev/prod namespaces; DNS-based discovery |
| `ingress/ig-mcu-host.yml` | Ingress | Host-based routing (two virtual hosts) |
| `ingress/ig-mcu-path.yml` | Ingress | Path-based routing |
| `ingress/ig-all.yml` | Ingress | Combined host + path rules, rewrite annotation |
| `ingress/app.yml` | Pod/Service | Backend services for Ingress demo |
| `ingress/ig-class.yml` | Ingress | `ingressClassName` field |
| `statefulsets/sts.yml` | StatefulSet | Ordered pods, `volumeClaimTemplates`, stable DNS |
| `statefulsets/headless-svc.yml` | Service | Headless service for StatefulSet pod DNS |
| `statefulsets/app.yml` | StatefulSet/Service | Full StatefulSet with headless + storage |
| `statefulsets/jump-pod.yml` | Pod | Debug pod for StatefulSet DNS resolution |
| `storage/gke-pvc.yml` | PVC | PersistentVolumeClaim (GKE SC — not EKS) |
| `storage/gke-pv.yml` | PV | Static PersistentVolume (GKE — not EKS) |
| `storage/google-pod.yml` | Pod | Pod consuming PVC |
| `psa/psa-pod.yml` | Pod | Pod violating Pod Security Admission (privileged=true) |
| `api/crd.yml` | CRD | CustomResourceDefinition with schema validation |
| `api/tkb.yml` + `api/kcna.yml` | CR | Custom Resources consuming the CRD |
| `api/ns.yml` / `ns.json` | Namespace | Namespace in both YAML and JSON |
| `api/deprecate.yml` | — | API version deprecation example |

---

## Concept Map — Beginner → Advanced

### BEGINNER (run this week, first contact with each concept)

| Concept | Source File(s) | Key Learning |
|---------|---------------|--------------|
| Pod lifecycle | `gs/Pods/pod.yml` · `k8s/pods/pod.yml` | Minimal pod, labels, container ports |
| Resource limits | `k8s/pods/pod.yml` | `requests` vs `limits`; OOM risk |
| Multi-container pod | `gs/Pods/multi-pod.yml` | Adapter pattern; shared localhost |
| Basic Deployment | `gs/Deployments/deploy.yml` | Replicas, selector, pod template |
| RollingUpdate strategy | `gs/Deployments/deploy-complete.yml` · `k8s/deployments/deploy.yml` | `maxSurge`, `maxUnavailable`, `minReadySeconds`, `progressDeadlineSeconds` |
| ClusterIP Service | `k8s/networking/svc.yml` | Internal service; label selector |
| NodePort Service | `gs/Services/svc-nodeport.yml` | External port; dev/test use only |
| LoadBalancer Service | `gs/Services/svc-lb.yml` · `k8s/networking/cloud-lb.yml` | Cloud LB provisioning |
| Namespaces | `k8s/namespaces/shield-ns.yml` | Isolation boundary; label usage |

### INTERMEDIATE (week 1–2 material)

| Concept | Source File(s) | Key Learning |
|---------|---------------|--------------|
| Init containers | `k8s/pods/initpod.yml` | Dependency sequencing; DNS gate pattern |
| Sidecar pattern | `k8s/pods/sidecarpod.yml` | `emptyDir` shared volume; git-sync |
| ConfigMap (file) | `k8s/configmaps/singlemap.yml` · `cmpod.yml` | Volume-mounted config file |
| ConfigMap (env vars) | `k8s/configmaps/multimap.yml` · `envpod.yml` | `valueFrom.configMapKeyRef` |
| ConfigMap (cmd args) | `k8s/configmaps/startuppod.yml` | Env vars in container command |
| Secrets (native) | `k8s/configmaps/tkb-secret.yml` · `secretpod.yml` | Base64 opaque secrets; volume mount |
| Service Discovery / DNS | `k8s/service-discovery/sd-example.yml` | FQDN: `<svc>.<ns>.svc.cluster.local` |
| Namespace scoping | `k8s/namespaces/shield-app.yml` | SA scoping; same app name in different NSes |
| Ingress (host-based) | `k8s/ingress/ig-mcu-host.yml` · `app.yml` | Virtual hosting via Ingress |
| Ingress (path-based) | `k8s/ingress/ig-mcu-path.yml` | URL path routing |
| Ingress (combined) | `k8s/ingress/ig-all.yml` | Rewrite annotation; `ingressClassName` |
| PVC basics | `k8s/storage/gke-pvc.yml` · `google-pod.yml` | Dynamic provisioning flow (GKE here → adapt to EBS) |

### ADVANCED (week 2–4 material)

| Concept | Source File(s) | Key Learning |
|---------|---------------|--------------|
| StatefulSet | `k8s/statefulsets/sts.yml` + `headless-svc.yml` | Ordered pod names, stable DNS, `volumeClaimTemplates` |
| StatefulSet DNS | `k8s/statefulsets/jump-pod.yml` | `<pod>.<svc>.<ns>.svc.cluster.local` resolution |
| Pod Security Admission | `k8s/psa/psa-pod.yml` | `privileged:true` blocked by `restricted` PSS |
| CRD + Custom Resources | `k8s/api/crd.yml` · `tkb.yml` · `kcna.yml` | Schema-validated CRD; operator extension point |
| API versioning | `k8s/api/deprecate.yml` | Deprecation strategy; `apiVersion` migration |

---

## Lab Candidates

Labs marked **✓ STRONG** have enough self-contained material to run directly.  
Labs marked **⚡ EXTEND** need EKS-specific additions to become production-grade.

| Priority | Lab Title | Source Files | What to Add for EKS |
|----------|-----------|-------------|---------------------|
| ✓ STRONG | **Rolling Deploy & Rollback** | `gs/Deployments/deploy-complete.yml` + `k8s/deployments/deploy.yml` | Add readiness/liveness probes, PDB |
| ✓ STRONG | **ConfigMap & Secret Injection** | `k8s/configmaps/*` | Replace `tkb-secret.yml` with Secrets Store CSI → Secrets Manager |
| ✓ STRONG | **Ingress Routing (host + path)** | `k8s/ingress/*` + `app.yml` | Swap nginx-ingress for AWS LBC + ALB annotations |
| ✓ STRONG | **Init Container Dependency Gate** | `k8s/pods/initpod.yml` | Add IRSA to init container for AWS API wait |
| ✓ STRONG | **StatefulSet + Headless Service** | `k8s/statefulsets/*` | Swap `flash` StorageClass for `gp3` (EBS CSI) |
| ✓ STRONG | **Service Discovery Deep Dive** | `k8s/service-discovery/sd-example.yml` | Add cross-namespace NetworkPolicy around the same example |
| ⚡ EXTEND | **Pod Security Admission** | `k8s/psa/psa-pod.yml` | Add Kyverno policy alongside PSS; test both enforcement paths |
| ⚡ EXTEND | **CRD + Controller Pattern** | `k8s/api/crd.yml` + CRs | Evolve into understanding how EKS add-ons (e.g. Karpenter) register CRDs |
| ⚡ EXTEND | **Sidecar for Observability** | `k8s/pods/sidecarpod.yml` | Replace git-sync with Fluent Bit sidecar → CloudWatch |

---

## EKS-Specific Gaps (not covered by either repo)

These are production-critical EKS topics absent from both Poulton repos. Each is a future lab.

### IAM & Identity
| Gap | Why It Matters on EKS |
|-----|----------------------|
| IRSA (IAM Roles for Service Accounts) | Pod-level AWS auth; zero pods should use node role |
| `aws-auth` ConfigMap / Access Entries | Cluster access control; IAM user/role → K8s RBAC mapping |
| EKS Pod Identity (newer mechanism) | Replaces IRSA annotation pattern from K8s 1.30+ |

### Networking
| Gap | Why It Matters on EKS |
|-----|----------------------|
| AWS Load Balancer Controller annotations | ALB ingress is fundamentally different from nginx-ingress |
| VPC CNI prefix delegation | Required to avoid IP exhaustion on large clusters |
| NetworkPolicy enforcement on EKS | Requires Calico or VPC CNI network policy mode — not default |
| ExternalDNS → Route53 | DNS automation; Poulton shows no external DNS integration |
| PrivateLink / internal ALB | Air-gapped or private-cluster ingress pattern |

### Storage
| Gap | Why It Matters on EKS |
|-----|----------------------|
| EBS CSI StorageClass (`gp3`) | Poulton uses GKE `standard`/`flash` SCs; must adapt |
| EFS CSI (ReadWriteMany) | Multi-AZ shared storage; StatefulSet cross-AZ pattern |
| Volume snapshots (EBS) | Backup/restore validation for stateful workloads |

### Autoscaling
| Gap | Why It Matters on EKS |
|-----|----------------------|
| Horizontal Pod Autoscaler (HPA) | Zero examples in either repo |
| Karpenter NodePool/EC2NodeClass | Not covered; replaces Cluster Autoscaler for EKS |
| KEDA (event-driven scaling) | SQS/Kafka-triggered scaling; common in platform teams |

### Security
| Gap | Why It Matters on EKS |
|-----|----------------------|
| Kyverno / OPA Gatekeeper policies | Poulton only shows PSA violation; no admission controller |
| Secrets Store CSI Driver | Native Secrets are base64, not encrypted at rest by default |
| ECR image pull with IRSA | Pulling from private ECR; `imagePullSecrets` vs IRSA pull |
| GuardDuty EKS Runtime | Threat detection; not a K8s concept but critical operational layer |

### Observability
| Gap | Why It Matters on EKS |
|-----|----------------------|
| Resource requests/limits tuning | Poulton sets static limits; no profiling workflow |
| Liveness / Readiness / Startup probes | Missing from most Poulton examples; prod-critical |
| Prometheus scrape annotations | No observability wiring in any example |
| Container Insights / Fluent Bit | EKS-native logging pipeline; zero coverage |

### Reliability
| Gap | Why It Matters on EKS |
|-----|----------------------|
| Pod Disruption Budgets | Missing from all examples; required for safe node drain |
| Topology spread constraints | Multi-AZ pod distribution; EKS 3-AZ requirement |
| Affinity / anti-affinity rules | Dedicated node pools (spot, GPU, etc.) |
| `terminationGracePeriodSeconds` tuning | Only `1s` in demo apps; need real drain window |

---

## Recommended Study Sequence

> **This is a reference mapping, not the active schedule.**  
> The active day-by-day plan is in the roadmap files. This section shows which Poulton source files correspond to which phase — use it when you want to understand what a lab is based on.

```
Phase 1 (2-week fundamentals → roadmap/eks-2-week-focused.md)
  Week 1
  Day 1   │ BEGINNER: Pod, Deployment, Services
           │ Files: gs/Pods, gs/Deployments, gs/Services, k8s/networking
           │
  Day 2   │ INTERMEDIATE: ConfigMaps, Secrets
           │ Files: k8s/configmaps (all 6)
           │
  Day 3   │ INTERMEDIATE: Namespaces, Service Discovery, DNS
           │ Files: k8s/namespaces, k8s/service-discovery/sd-example.yml
           │
  Day 4   │ INTERMEDIATE: Init containers, Sidecar pattern
           │ Files: k8s/pods/initpod.yml, sidecarpod.yml
           │
  Day 5   │ ADVANCED: StatefulSet + PVC
           │ Files: k8s/statefulsets/* (swap GKE SC → gp3 EBS)
  Week 2
  Day 6   │ ADVANCED: Ingress (host + path → ALB translation)
           │ Files: k8s/ingress/* → all 4 files
           │
  Day 7   │ EKS GAP: RBAC (not in Poulton repos)
           │
  Day 8   │ ADVANCED: PSA + Kyverno
           │ Files: k8s/psa/psa-pod.yml
           │
  Day 9   │ EKS GAP: Karpenter + Spot (not in Poulton repos)
           │
  Day 10  │ Review + skills_matrix.md update

Phase 2 (4-week advanced → roadmap/eks-4-week-roadmap.md)
  Weeks 3–6
  Week 3  │ Workload Reliability + Autoscaling
  Week 4  │ Security Hardening
  Week 5  │ Observability (Prometheus + Grafana + Fluent Bit)
  Week 6  │ GitOps (ArgoCD)
```

---

## File-to-Roadmap Cross-Reference

| Phase | Poulton Files Used | EKS Gap Coverage Added |
|-------|--------------------|----------------------|
| Phase 1 Week 1 (Cluster Foundation) | `pods/pod.yml`, `deployments/deploy.yml` | IRSA, EBS CSI, control plane logging |
| Phase 1 Week 1 (Networking/Ingress) | `ingress/ig-all.yml`, `networking/*` | AWS LBC, ExternalDNS, NetworkPolicies |
| Phase 1 Week 2 (Reliability) | `statefulsets/*`, `configmaps/*` | HPA, Karpenter, PDB, topology spread |
| Phase 1 Week 2 (Storage) | `storage/gke-pvc.yml` → adapt | EBS CSI gp3, EFS CSI, snapshots |
| Phase 2 Week 1 (Security) | `psa/psa-pod.yml`, `configmaps/tkb-secret.yml` | Kyverno, Secrets Store CSI, ECR scanning |
| Phase 2 Week 2 (Observability/GitOps) | `pods/sidecarpod.yml` | Fluent Bit, kube-prometheus-stack, ArgoCD |
