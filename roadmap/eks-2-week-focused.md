# Phase 1: EKS/Kubernetes Fundamentals (2 Weeks)

> Created: 2026-06-16  
> Status: **IN PROGRESS** — Day 1 completed; Day 2 complete for local scope; Day 3 next  
> Scope: Kubernetes fundamentals → EKS production capable  
> Assumes: Lab 01 cluster is provisioned (or use a local kind cluster for Week 1)  
> Cadence: ~2–3 hours per day
>
> **Resources:**
> - Theory: [Kubernetes Official Docs](https://kubernetes.io/docs/home/) — use for concept pages, API reference, and task guides
> - Hands-on course: KodeKloud (see `sources/kodekloud/`)
> - Book + repos: Nigel Poulton (see `sources/nigel_poulton/`)
>
> **Sequence:** This is Phase 1. When all 10 days are complete and every
> validation checklist passes, continue to
> [Phase 2: `roadmap/eks-4-week-roadmap.md`](eks-4-week-roadmap.md).

This file drives daily execution. The Phase 2 roadmap is the extended syllabus.
Do not skip ahead to Phase 2 until you can complete each lab here without hints.

---

## Week 1 — Kubernetes Fundamentals on EKS

Goal: Be able to deploy, inspect, debug, and update any workload without referencing documentation.

### Day 1 — Pods, Deployments, Services

**Current:** ✅ Completed on 2026-06-20 (core flow + failure scenarios 1, 2, 3)

**Theory (30 min):** KodeKloud CKA sections: Core Concepts + Services  
**Hands-on:**

```bash
# Start from Nigel Poulton source — understand what you're running
cat sources/nigel_poulton/repo_k8sbook/pods/pod.yml
cat sources/nigel_poulton/repo_getting_started/Deployments/deploy-complete.yml

# Run Lab 03 (production deployment with probes + PDB + HPA)
kubectl apply -f labs/lab-03-production-deployments/k8s/namespace.yaml
kubectl apply -f labs/lab-03-production-deployments/k8s/deployment-v1.yaml
kubectl apply -f labs/lab-03-production-deployments/k8s/service.yaml
kubectl apply -f labs/lab-03-production-deployments/k8s/pdb.yaml
kubectl apply -f labs/lab-03-production-deployments/k8s/hpa.yaml
```

**Validate:** All checks in `labs/lab-03-production-deployments/README.md`  
**Hit deliberately:** Failure Scenarios 1, 2, 3 — diagnose before reading fix  
**Update:** `skills_matrix.md` — Deployments: 0 → 2, HPA: 0 → 2, PDB: 0 → 2

---

### Day 2 — ConfigMaps, Secrets, Secrets Manager

**Current:** ✅ Complete for local scope on 2026-06-20 (Part A + B validated; Part C deferred until AWS sandbox/account allows `iam:PassRole`)

**Theory (30 min):** KodeKloud CKA: ConfigMaps + Secrets  
**Reference:** `sources/nigel_poulton/repo_k8sbook/configmaps/` — read all 6 files  
**Hands-on:**

```bash
# Part A: understand the Nigel examples first
kubectl apply -f labs/lab-04-configmaps-secrets-manager/k8s/configmaps.yaml
kubectl apply -f labs/lab-04-configmaps-secrets-manager/k8s/configmap-pods.yaml
kubectl exec -n config-lab cm-envpod -- env | grep -E "FIRST|LAST"

# Part B: native secret weakness
kubectl apply -f labs/lab-04-configmaps-secrets-manager/k8s/native-secret.yaml
kubectl get secret tkb-secret -n config-lab -o jsonpath='{.data.password}' | base64 -d

# Part C (requires Terraform): Secrets Manager CSI
cd labs/lab-04-configmaps-secrets-manager/terraform && AWS_PROFILE=kodekloud-sandbox terraform init && AWS_PROFILE=kodekloud-sandbox terraform apply
```

**Hit deliberately:** Failure Scenario 1 (missing Secrets Manager IAM permission)  
**Update:** ConfigMaps & Secrets: 0 → 2, Secrets Store CSI: 0 → 1

---

### Day 3 — Namespaces, Service Discovery, DNS

**Reference:** `sources/nigel_poulton/repo_k8sbook/service-discovery/sd-example.yml`  
**Hands-on:**

```bash
kubectl apply -f labs/lab-07-service-discovery-netpol/k8s/
kubectl exec -n dev jump -- nslookup ent
kubectl exec -n dev jump -- wget -qO- http://ent.prod.svc.cluster.local:8080
# ↑ works BEFORE NetworkPolicy. Proves namespaces are NOT a security boundary.

kubectl apply -f labs/lab-07-service-discovery-netpol/k8s/network-policies.yaml
kubectl exec -n dev jump -- wget -qO- --timeout=5 http://ent.prod.svc.cluster.local:8080
# ↑ times out AFTER NetworkPolicy
```

**Hit deliberately:** Failure Scenario 1 (DNS breaks after default-deny)  
**Update:** Services: 0 → 2, Network Policies: 0 → 2

---

### Day 4 — Init Containers, Sidecar, Multi-container Pods

**Current:** ✅ Complete on 2026-06-25 (Part A: init sequencing fully validated; Part B: sidecar pattern + shared emptyDir validated locally; CloudWatch output deferred — no IRSA on local cluster; distroless debug via `kubectl debug` learned)

**Reference:** `sources/nigel_poulton/repo_k8sbook/pods/initpod.yml`, `sidecarpod.yml`  
**Hands-on:**

```bash
kubectl apply -f labs/lab-06-init-sidecar/k8s/init-demo-ns.yaml
kubectl apply -f labs/lab-06-init-sidecar/k8s/init-pod.yaml
# Watch it hang in Init:0/2
kubectl get pods -n init-lab -w
# Now unblock it
kubectl apply -f labs/lab-06-init-sidecar/k8s/postgres-stub-svc.yaml
# Watch it proceed: init-1 → init-2 → main container
kubectl apply -f labs/lab-06-init-sidecar/k8s/sidecar-fluent-bit.yaml
kubectl logs -n init-lab sidecar-pod -c ctr-fluent-bit --tail=20
```

**Hit deliberately:** Failure Scenario 3 (emptyDir fills node disk — read scenario, understand fix)  
**Update:** Pod lifecycle: 0 → 2, Fluent Bit: 0 → 1

---

### Day 5 — StatefulSets + EBS Storage

**Current:** ✅ Complete on 2026-06-25 (local-path StorageClass substituted for EBS; all StatefulSet concepts validated: ordered startup, stable DNS, persistence, reverse scaledown; liveness probe crash loop diagnosed and fixed with init container)

**Reference:** `sources/nigel_poulton/repo_k8sbook/statefulsets/` — all 5 files  
**Hands-on:**

```bash
kubectl apply -f labs/lab-05-statefulset-ebs/k8s/
kubectl get pods -n stateful-lab -w   # watch ordered creation: 0 → 1 → 2
kubectl get pvc -n stateful-lab        # verify Bound + gp3-encrypted SC

# Write data and prove persistence
for i in 0 1 2; do
  kubectl exec -n stateful-lab tkb-sts-$i -- \
    sh -c "echo 'pod-$i' > /usr/share/nginx/html/index.html"
done
kubectl delete pod tkb-sts-1 -n stateful-lab
kubectl exec -n stateful-lab tkb-sts-1 -- cat /usr/share/nginx/html/index.html
# Must show 'pod-1' — data survived pod deletion
```

**Hit deliberately:** Failure Scenario 1 (AZ mismatch — read + diagnose, don't need to fix)  
**Update:** PersistentVolumes: 0 → 3, StatefulSets: 0 → 2

---

## Week 2 — EKS Production Patterns

Goal: Ingress with real ALB, autoscaling with Karpenter, and pod security enforcement.

### Day 6 — Ingress Deep Dive (Nigel → EKS)

**Reference:** `sources/nigel_poulton/repo_k8sbook/ingress/` — all 4 files  
Read `mappings/k8s_learning_map.md` section on Ingress gaps before starting.

**Hands-on:** Run Lab 09 — see full instructions in `labs/lab-09-ingress-alb-deep-dive/README.md`

Key concepts to nail:
- Nigel uses nginx-ingress; on EKS you use AWS LBC → fundamentally different annotation model
- ALB is provisioned PER Ingress object (not per cluster)
- `target-type: ip` vs `instance` — understand the difference

**Update:** Ingress (ALB): 0 → 3, AWS Load Balancer Controller: 0 → 2

---

### Day 7 — RBAC + EKS Access Entries

**Theory (45 min):** KodeKloud CKA: Security → RBAC section  
**Hands-on:**

```bash
# Create a read-only role for a dev team member
kubectl create namespace dev-team
kubectl create serviceaccount dev-reader -n dev-team
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n dev-team
kubectl create rolebinding dev-reader-binding \
  --role=pod-reader \
  --serviceaccount=dev-team:dev-reader \
  -n dev-team

# Verify: can list pods, cannot delete
kubectl auth can-i list pods \
  --namespace=dev-team \
  --as=system:serviceaccount:dev-team:dev-reader
kubectl auth can-i delete pods \
  --namespace=dev-team \
  --as=system:serviceaccount:dev-team:dev-reader
```

**Update:** RBAC: 0 → 2

---

### Day 8 — Pod Security + Kyverno

**Hands-on:** Run Lab 08 — see `labs/lab-08-pod-security-kyverno/README.md`

Priority order:
1. Apply PSA labels to `psa-test` namespace
2. Try the privileged pod (Nigel's example) — confirm it's blocked
3. Install Kyverno, apply 4 ClusterPolicies
4. Run the test matrix (missing label, bad registry, latest tag, no requests)
5. Apply compliant pod — confirm it passes all policies

**Hit deliberately:** Failure Scenario 1 (Kyverno webhook timeout → cluster unavailable)  
**Update:** Pod Security Standards: 0 → 3, Kyverno: 0 → 2, Admission Controllers: 0 → 2

---

### Day 9 — Karpenter + Spot Node Provisioning

**Hands-on:** Run Lab 10 — see `labs/lab-10-karpenter-spot/README.md`

Key production concepts:
- Karpenter replaces Cluster Autoscaler on EKS
- NodePool/EC2NodeClass are CRDs — understand their schema
- Spot interruption handling via NTH (Node Termination Handler)
- Mixed instance types: Karpenter picks cheapest available

**Update:** Cluster Autoscaler/Karpenter: 0 → 2

---

### Day 10 — Review + Skills Matrix Update

**No new labs.** Review and consolidate.

```bash
# Review everything deployed
kubectl get all -A | grep -v kube-system

# Clean up labs you won't need running
kubectl delete namespace web config-lab stateful-lab init-lab dev prod shared psa-test

# Update skills_matrix.md — honest self-assessment after 2 weeks
```

Go through each row in `skills_matrix.md`. For every skill where you:
- Completed the lab → level should be at least 2
- Hit failure scenarios without hints → level 3
- Still feel shaky → write in Notes column, schedule a re-run

---

## Phase 1 Completion Gate

Before moving to Phase 2, all of the following must be true:

- [ ] All 10 lab validation checklists pass (no skipped items)
- [ ] At least 6 failure scenarios diagnosed independently (without reading the fix first)
- [ ] `skills_matrix.md` updated — every skill with a lab is at level ≥ 2
- [ ] At least one entry in `progress/log.md` per lab
- [ ] You can answer without notes: *What is IRSA, why does it exist, and how does the trust policy work?*
- [ ] You can answer without notes: *What happens to traffic when a readinessProbe fails?*
- [ ] You can answer without notes: *Why does Karpenter provision a new node instead of scheduling to an existing one?*

When all boxes are checked: → **[Begin Phase 2: `roadmap/eks-4-week-roadmap.md`](eks-4-week-roadmap.md)**
