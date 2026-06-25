# EKS Production Readiness — Skills Workspace

A hands-on, production-focused learning workspace for Kubernetes and EKS.  
Built for a Senior DevOps Engineer targeting **platform engineering depth**: real infrastructure, real failure modes, real debugging.

---

## Philosophy

- **Hands-on over theory** — every concept is exercised in a lab
- **Production realism** — labs model real failure modes, not happy-path demos
- **EKS-first** — all workloads run on AWS EKS with Terraform-provisioned infrastructure
- **Depth over speed** — complete each lab without hints before moving on

---

## Roadmap

| Phase | File | Scope | Status |
|-------|------|-------|--------|
| Phase 1 | [`roadmap/eks-2-week-focused.md`](roadmap/eks-2-week-focused.md) | K8s fundamentals → EKS production capable | Not started |
| Phase 2 | [`roadmap/eks-4-week-roadmap.md`](roadmap/eks-4-week-roadmap.md) | Advanced platform: observability, security, autoscaling | Locked until Phase 1 complete |

Start at Phase 1. Do not advance until every lab validation checklist passes without referencing documentation.

---

## Lab Index

| Lab | Topic | Key Concepts |
|-----|-------|--------------|
| [lab-01](labs/lab-01-eks-cluster-foundation/) | EKS Cluster Foundation | VPC, managed node groups, IRSA, EKS add-ons, Bottlerocket |
| [lab-02](labs/lab-02-eks-networking-ingress/) | Networking & Ingress | ALB Ingress, ExternalDNS, Network Policies |
| [lab-03](labs/lab-03-production-deployments/) | Production Deployments | Probes, HPA, PDB, rolling updates, topology spread |
| [lab-04](labs/lab-04-configmaps-secrets-manager/) | ConfigMaps & Secrets | ConfigMaps, native Secrets, Secrets Store CSI, AWS Secrets Manager |
| [lab-05](labs/lab-05-statefulset-ebs/) | StatefulSets & EBS | StorageClass, PVC, StatefulSet, PDB, EBS CSI |
| [lab-06](labs/lab-06-init-sidecar/) | Init & Sidecar Containers | Init containers, Fluent Bit sidecar, IRSA for CloudWatch |
| [lab-07](labs/lab-07-service-discovery-netpol/) | Service Discovery & NetPol | CoreDNS, ClusterIP, cross-namespace policies |
| [lab-08](labs/lab-08-pod-security-kyverno/) | Pod Security & Kyverno | Pod Security Standards, Kyverno ClusterPolicies |
| [lab-09](labs/lab-09-ingress-alb-deep-dive/) | ALB Ingress Deep Dive | Host/path routing, TLS termination, ACM, IngressGroup |
| [lab-10](labs/lab-10-karpenter-spot/) | Karpenter & Spot | NodePool, EC2NodeClass, Spot interruption handling |

Each lab contains:
- `README.md` — context, steps, validation checklist, failure scenarios
- `k8s/` — Kubernetes manifests
- `terraform/` — infrastructure (where applicable)

---

## Repository Structure

```
roadmap/          # Phased learning plans
labs/             # Hands-on labs (k8s/ + terraform/ per lab)
sources/          # Reference material (Nigel Poulton, KodeKloud)
skills_matrix.md  # Skill level tracking (0–4 scale)
progress/log.md   # Daily session log
mappings/         # Concept-to-lab cross-reference
notes/            # Freeform notes
AGENT.md          # Copilot agent persona and instructions
workflow.md       # Daily session workflow guide
```

---

## Daily Workflow

1. Read `progress/log.md` — what was the last action?
2. Open the active roadmap — which day/lab are you on?
3. Run the lab, hit the intentional failure scenarios, diagnose them
4. Update `skills_matrix.md` and `progress/log.md`

See [`workflow.md`](workflow.md) for the full session protocol.

---

## Skills Tracking

[`skills_matrix.md`](skills_matrix.md) tracks proficiency across Kubernetes Core, EKS-Specific, Networking, Observability, and Security.

Scale: `0` Not started · `1` Aware · `2` Hands-on basic · `3` Production capable · `4` Expert / can teach

Update after every lab execution.

---

## Learning Sources

| Source | Role |
|--------|------|
| [Nigel Poulton](sources/nigel_poulton/) | Concept foundation and base examples — always extend to EKS |
| [KodeKloud](sources/kodekloud/) | Structured guided exercises — use to identify weak areas |
| Stackademic all-in-one Linux/DevOps blogs: https://blog.stackademic.com/all-in-one-linux-devops-automation-blogs-46621975f0f8 | Supplemental quick theory reference for specific concept explanation/check only (not primary learning path) |

---

## Prerequisites

- AWS account with permissions to create EKS, VPC, IAM, and related resources
- Terraform ≥ 1.5, kubectl, AWS CLI v2, Helm 3
- Lab 01 cluster must be provisioned before running labs 02–10
