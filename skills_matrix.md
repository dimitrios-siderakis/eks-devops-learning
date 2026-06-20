# Skills Matrix

> Updated: 2026-06-20 | Focus: Kubernetes / EKS Production Readiness  
> Labs scaffolded: 01–10 | Labs completed: 1 (lab-03) + 1 partial (lab-04 A/B)

Legend: `0` Not started · `1` Aware · `2` Hands-on basic · `3` Production capable · `4` Expert / can teach  
`(s)` = skill covered in a scaffolded lab, ready to execute

---

## Kubernetes Core

| Skill | Level | Last Lab | Notes |
|-------|-------|----------|-------|
| Pod lifecycle & scheduling | 1 | lab-03 | Topology spread + scheduler behavior observed during failures |
| Deployments / ReplicaSets / DaemonSets | 2 | lab-03 | Rolling updates, rollback, and rollout diagnostics completed |
| Services (ClusterIP, NodePort, LB) | 1 | lab-03 | Service endpoint behavior validated via readiness failures |
| ConfigMaps & Secrets management | 2 | lab-04 | ConfigMap env/file injection + native Secret decode/injection validated |
| Resource requests/limits & QoS classes | 2 | lab-03 | HPA dependency on requests validated |
| RBAC (Roles, ClusterRoles, Bindings) | 0 | — | Gap — no lab yet |
| Network Policies | 0 | — | Covered: lab-02(s), lab-07(s) |
| PersistentVolumes / StorageClasses | 0 | — | Covered: lab-05(s) |
| Horizontal / Vertical Pod Autoscaler | 2 | lab-03 | HPA behavior observed during rollout and recovery |
| Pod Disruption Budgets | 2 | lab-03 | Drain protection tested and verified |
| Taints, Tolerations, Affinity rules | 1 | lab-03 | Topology spread constraints actively exercised |
| Admission Controllers / Webhooks | 0 | — | Covered: lab-08(s) Kyverno |

---

## EKS-Specific

| Skill | Level | Last Lab | Notes |
|-------|-------|----------|-------|
| EKS cluster architecture (control plane) | 0 | — | Covered: lab-01(s) |
| Managed Node Groups vs. self-managed vs. Fargate | 0 | — | Covered: lab-01(s) |
| IRSA (IAM Roles for Service Accounts) | 0 | — | Covered: lab-01(s), lab-04(s), lab-06(s) |
| EKS add-ons (vpc-cni, coredns, kube-proxy, ebs-csi) | 0 | — | Covered: lab-01(s) |
| AWS Load Balancer Controller | 0 | — | Covered: lab-02(s) |
| Cluster Autoscaler / Karpenter | 0 | — | Covered: lab-10(s) NodePool, Spot, SQS interruption |
| EKS access entries / aws-auth ConfigMap | 0 | — | Gap — no lab yet |
| Bottlerocket OS node hardening | 0 | — | Covered: lab-01(s) node group config |
| EKS control plane logging | 0 | — | Covered: lab-01(s) |
| EKS private endpoint + VPC peering | 0 | — | Gap — no lab yet |

---

## Networking

| Skill | Level | Last Lab | Notes |
|-------|-------|----------|-------|
| VPC CNI plugin & IP assignment | 0 | — | |
| Ingress (ALB) with TLS termination | 0 | — | Covered: lab-09(s) host+path routing, ACM, group.name |
| ExternalDNS integration | 0 | — | Covered: lab-02(s), lab-09(s) |
| Service mesh basics (App Mesh / Istio) | 0 | — | Gap — no lab yet |
| PrivateLink / VPC Endpoints for EKS | 0 | — | Gap — no lab yet |

---

## Observability

| Skill | Level | Last Lab | Notes |
|-------|-------|----------|-------|
| Container Insights (CloudWatch) | 0 | — | Covered: lab-06(s) Fluent Bit sidecar |
| Prometheus + Grafana on EKS | 0 | — | Gap — Phase 2, Week 2 |
| Fluentbit log shipping to CloudWatch / S3 | 0 | — | Covered: lab-06(s) |
| Distributed tracing (X-Ray / OTEL) | 0 | — | Gap — no lab yet |
| kube-state-metrics + custom alerts | 0 | — | Gap — no lab yet |

---

## Security

| Skill | Level | Last Lab | Notes |
|-------|-------|----------|-------|
| Pod Security Standards (restricted profile) | 0 | — | Covered: lab-08(s) |
| OPA / Kyverno policy enforcement | 0 | — | Covered: lab-08(s) 4 ClusterPolicies |
| Secrets management (Secrets Store CSI / ESO) | 0 | — | Covered: lab-04(s) |
| Image scanning (ECR + Trivy) | 0 | — | Gap — no lab yet |
| Audit logging + GuardDuty EKS protection | 0 | — | Gap — no lab yet |
| Least-privilege node IAM roles | 0 | — | Covered: lab-01(s) node IAM |

---

## CI/CD & GitOps

| Skill | Level | Last Lab | Notes |
|-------|-------|----------|-------|
| Helm chart authoring | 0 | — | |
| ArgoCD app-of-apps pattern | 0 | — | |
| GitHub Actions → ECR → EKS deploy pipeline | 0 | — | |
| Kustomize overlays (dev/staging/prod) | 0 | — | |
| Progressive delivery (Argo Rollouts / Flagger) | 0 | — | |

---

## Platform Engineering

| Skill | Level | Last Lab | Notes |
|-------|-------|----------|-------|
| Internal Developer Platform concepts | 0 | — | |
| Backstage service catalog | 0 | — | |
| Crossplane for infra provisioning | 0 | — | |
| Multi-cluster management (Fleet / ACM) | 0 | — | |
| Cost optimization (Spot, right-sizing, Kubecost) | 0 | — | |

---

## Existing Strengths (Pre-loaded)

| Skill | Level | Notes |
|-------|-------|-------|
| AWS (core services) | 3 | Strong foundation |
| Terraform | 3 | Production experience |
| CI/CD pipeline design | 3 | Strong |
| SQL Server / relational DB ops | 3 | Deep background |
| Team leadership | 3 | Managing engineers |

---

## Lab Coverage Summary

| Lab | Status | Skills Targeted |
|-----|--------|----------------|
| lab-01 EKS Cluster Foundation | Scaffolded | EKS arch, node groups, IRSA, add-ons, control plane logging |
| lab-02 Networking & Ingress | Scaffolded | AWS LBC, ALB, ExternalDNS, NetworkPolicies |
| lab-03 Production Deployments | Completed | Deployments, probes, PDB, HPA, topology spread |
| lab-04 ConfigMaps & Secrets Manager | Partial (A/B complete, C blocked by AWS IAM) | ConfigMaps, Secrets, CSI driver, IRSA |
| lab-05 StatefulSet + EBS | Scaffolded | StatefulSets, gp3 StorageClass, PVCs, AZ affinity |
| lab-06 Init Containers & Sidecar | Scaffolded | Init containers, sidecar pattern, Fluent Bit |
| lab-07 Service Discovery + NetPol | Scaffolded | DNS, namespace isolation, NetworkPolicies |
| lab-08 Pod Security + Kyverno | Scaffolded | PSA, Kyverno ClusterPolicies |
| lab-09 Ingress Deep Dive (ALB) | Scaffolded | AWS LBC annotations, host/path routing, ACM, ExternalDNS |
| lab-10 Karpenter + Spot | Scaffolded | Karpenter v1 NodePool/EC2NodeClass, Spot SQS interruption, Terraform |

**How to update levels after completing a lab:**
- Read README → Level stays 0 → add `(r)` in notes
- Apply manifests, hit first failure → 0 → 1
- Complete all validation checks → 1 → 2
- Debug failure scenarios without hints → 2 → 3

---

## Lab Quality Audit (2026-06-16)

| Lab | Terraform | Probes | PDB | IRSA | PSA Labels | Verdict |
|-----|-----------|--------|-----|------|------------|---------|
| lab-01 | ✅ Full | N/A | N/A | ✅ | N/A | Production |
| lab-02 | ⚠️ IRSA only | ✅ | — | ✅ | ✅ | Near-prod |
| lab-03 | ❌ empty dir | ✅ | ✅ | ❌ default SA | ✅ baseline | Near-prod |
| lab-04 | ✅ Secrets | ✅ | — | ✅ | — | Production |
| lab-05 | ❌ empty dir | ✅ | ✅ | — | — | Near-prod |
| lab-06 | ✅ terraform/main.tf | ✅ | ✅ PDB | ✅ IRSA role | ✅ baseline | Near-prod |
| lab-07 | ❌ empty dir | ❌ none | ❌ | — | — | Weak |
| lab-08 | ❌ empty dir | — | — | — | ✅ | Near-prod |
| lab-09 | ❌ empty dir | ✅ | — | ✅ (Lab 02) | ✅ | Near-prod |
| lab-10 | ✅ Full | ✅ | ❌ | ✅ | — | Production |

**Known curriculum gaps (no lab):**
- RBAC (Roles, ClusterRoles, aggregation rules, EKS access entries)
- Prometheus + Grafana on EKS (kube-prometheus-stack)
- ArgoCD GitOps (app-of-apps)
- ECR + Trivy image scanning in CI pipeline
- Helm chart authoring
- EKS private endpoint + aws-auth migration
