# Phase 2: EKS Production Readiness — 4-Week Advanced Roadmap

> Status: **NOT STARTED** — begin only after Phase 1 completion gate passes  
> Prerequisites: [`roadmap/eks-2-week-focused.md`](eks-2-week-focused.md) — all 10 labs executed, all checklist items green  
> Target: Production-grade EKS platform operator

**This is Phase 2.** It assumes you can already deploy, debug, and update workloads without
referencing documentation. Every lab here builds on the cluster provisioned in Phase 1, Lab 01.

Each week builds on the previous. Labs are the primary output — notes are secondary.

---

## Week 1 — Cluster Foundation & Networking

**Goal:** Provision a production-grade EKS cluster you'd be comfortable running workloads on.

**Skills targeted:**
- EKS cluster architecture
- VPC design for EKS (private subnets, NAT, pod CIDR)
- Managed Node Groups with Bottlerocket
- IRSA bootstrap
- EKS add-ons (vpc-cni, coredns, kube-proxy, ebs-csi-driver)
- Control plane logging
- aws-auth / access entries

**Labs:**
| # | Lab | Outcome |
|---|-----|---------|
| 01 | EKS Cluster Foundation | Running EKS cluster, IRSA working, nodes healthy |
| 02 | EKS Networking & Ingress | ALB Ingress with TLS, ExternalDNS, Network Policies |

**Validation checkpoints:**
- [ ] `kubectl get nodes` — all nodes Ready
- [ ] IRSA test pod assumes correct IAM role
- [ ] ALB provisioned, HTTPS resolves, cert auto-issued via ACM/cert-manager
- [ ] Network policy blocks cross-namespace traffic
- [ ] Control plane logs visible in CloudWatch

**Failure scenarios to intentionally hit:**
- Node group with insufficient subnet IP space → learn vpc-cni prefix delegation
- IRSA misconfiguration → 403 on AWS API call from pod
- Missing node IAM policy → CSI driver fails to mount EBS

---

## Week 2 — Workload Reliability & Autoscaling

**Goal:** Run stateful and stateless workloads with production SLO confidence.

**Skills targeted:**
- Resource requests/limits & QoS classes
- HPA + KEDA (event-driven scaling)
- Karpenter (node provisioner replacing Cluster Autoscaler)
- Pod Disruption Budgets
- Taints, tolerations, affinity (dedicated node pools)
- PersistentVolumes with EBS CSI + EFS CSI

**Labs:**
| # | Lab | Outcome |
|---|-----|---------|
| 03 | Karpenter Node Provisioning | Nodes scale in/out in <60s, Spot mixed with On-Demand |
| 04 | Stateful Workload: PostgreSQL on EKS | Postgres with EBS GP3, PDB, backup via Velero |

**Validation checkpoints:**
- [ ] Load test triggers HPA + Karpenter node launch
- [ ] Spot interruption simulation → workload reschedules cleanly
- [ ] PDB prevents full rollout during node drain
- [ ] EBS volume survives pod reschedule to same AZ

**Failure scenarios:**
- Karpenter provisioner AZ mismatch with EBS volume → pod stuck Pending
- QoS Burstable pod OOMKilled under load → promote to Guaranteed

---

## Week 3 — Security Hardening

**Goal:** Cluster passes CIS EKS benchmark. Zero implicit trust between workloads.

**Skills targeted:**
- Pod Security Standards (restricted profile enforcement)
- OPA Gatekeeper or Kyverno policies
- Secrets Store CSI Driver (pull from AWS Secrets Manager)
- ECR image scanning + admission block on HIGH/CRITICAL CVEs
- Least-privilege IRSA + node IAM roles
- GuardDuty EKS Runtime Monitoring
- Audit log analysis

**Labs:**
| # | Lab | Outcome |
|---|-----|---------|
| 05 | Policy Enforcement with Kyverno | Block privileged pods, enforce image registry, require labels |
| 06 | Secrets & Image Security | Secrets Manager via CSI, ECR scan gate in CI pipeline |

**Validation checkpoints:**
- [ ] `kubectl run priv --image=nginx --privileged` → blocked by policy
- [ ] Pod using default SA can't list other namespaces
- [ ] Image with known CVE fails admission
- [ ] App pod reads DB password from Secrets Manager (no env vars)
- [ ] GuardDuty fires on simulated cryptominer exec

**Failure scenarios:**
- CSI driver SecretProviderClass misconfiguration → pod CrashLoopBackOff
- Kyverno webhook timeout → cluster unavailable if `failurePolicy: Fail`

---

## Week 4 — Observability & GitOps

**Goal:** Full-stack visibility + GitOps-driven deployments. Platform team operating model.

**Skills targeted:**
- Prometheus + Grafana (kube-prometheus-stack)
- Fluentbit → CloudWatch Logs / S3 / OpenSearch
- Custom alerting (PagerDuty/Slack integration)
- ArgoCD app-of-apps pattern
- Argo Rollouts canary deployments
- Helm chart authoring (production-grade)
- Kustomize overlays (dev/staging/prod)

**Labs:**
| # | Lab | Outcome |
|---|-----|---------|
| 07 | Full Observability Stack | Prometheus scraping, Grafana dashboards, alert fires on pod crash |
| 08 | GitOps with ArgoCD + Argo Rollouts | Canary deployment, auto-rollback on error rate spike |

**Validation checkpoints:**
- [ ] Grafana shows node CPU/mem, pod restarts, request rate
- [ ] Fluentbit ships app logs; CloudWatch Insights query works
- [ ] Alert fires within 2 min of simulated outage
- [ ] ArgoCD syncs on git push; canary pauses at 20% traffic
- [ ] Rollback triggered automatically by Prometheus metric threshold

**Failure scenarios:**
- Prometheus cardinality explosion → OOM on Prometheus pod
- ArgoCD out-of-sync due to Helm value drift
- Canary rollout stuck at 20% → investigate Argo Rollouts analysis template

---

## Post-Roadmap: Platform Engineering Track

After completing the 4 weeks, the next phase covers:
- **Crossplane** — provision AWS infra via K8s manifests
- **Backstage** — internal developer portal + service catalog
- **Multi-cluster** — hub-spoke with ArgoCD or ACM
- **Cost engineering** — Kubecost, Spot strategy, right-sizing pipelines
- **EKS Anywhere / Hybrid** — on-prem extension
