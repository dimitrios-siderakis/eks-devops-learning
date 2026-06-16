# Lab 08: Pod Security Admission + Kyverno Policy Enforcement

**Week:** 3 | **Difficulty:** Advanced | **Est. time:** 3–4 hours  
**Depends on:** Lab 01 cluster  
**Source material:** `repo_k8sbook/psa/psa-pod.yml` (privileged pod example)

## What Poulton's Example Shows vs. What This Lab Adds

| Poulton | This Lab |
|---------|----------|
| Privileged pod that violates PSS | + PSA namespace label enforcement |
| Shows what's blocked | + Kyverno ClusterPolicies to add custom rules |
| No admission webhook | + require labels, enforce registry, block latest tag |
| Single failing pod | + test matrix: audit/warn/enforce modes |

## Objective

Layer two enforcement mechanisms on EKS:
1. **Pod Security Admission (PSS)** — built-in Kubernetes; enforces `restricted` profile
2. **Kyverno** — policy-as-code; custom rules that PSA can't express

## Architecture

```
Namespace: psa-test
  PSA labels: enforce=restricted, audit=restricted, warn=restricted
  Result: privileged pods BLOCKED at API server

Kyverno ClusterPolicies (cluster-wide):
  policy-1: require label "owner" on all pods
  policy-2: block images from non-approved registries
  policy-3: block "latest" image tag
  policy-4: require resource requests on all containers
```

---

## Prerequisites

Install Kyverno:
```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --set admissionController.replicas=3 \
  --set backgroundController.replicas=2
```

Wait for webhook readiness:
```bash
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=admission-controller \
  -n kyverno --timeout=120s
```

---

## Lab Steps

### Part A: Pod Security Admission

```bash
kubectl apply -f k8s/psa-namespace.yaml
```

Test privileged pod (from Poulton `psa/psa-pod.yml`):
```bash
kubectl apply -f k8s/psa-privileged-pod.yaml
# Expected: Error: pods "psa-pod" is forbidden: violates PodSecurity "restricted:latest":
#   privileged (container "psa-ctr" must not set securityContext.privileged=true)
```

Test a compliant pod:
```bash
kubectl apply -f k8s/psa-compliant-pod.yaml
# Expected: pod/psa-compliant created — should succeed
```

Test `warn` mode (audit namespace):
```bash
kubectl apply -f k8s/psa-audit-namespace.yaml
kubectl apply -f k8s/psa-privileged-pod.yaml -n psa-audit
# Expected: WARNING displayed but pod IS created; shows up in audit log
kubectl get events -n psa-audit | grep Warning
```

### Part B: Kyverno Policies

```bash
kubectl apply -f k8s/kyverno-policies.yaml
```

**Test: missing owner label**
```bash
kubectl run no-label --image=nginx:1.25 -n default
# Expected: admission webhook denied: label 'owner' is required
```

**Test: unapproved registry**
```bash
kubectl run bad-registry --image=docker.io/nginx:1.25 -n default \
  --labels owner=test
# Expected: admission webhook denied: image must be from approved registry
```

**Test: latest tag**
```bash
kubectl run latest-tag --image=<YOUR_ECR_ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/nginx:latest \
  -n default --labels owner=test
# Expected: admission webhook denied: image tag 'latest' is not allowed
```

**Test: compliant pod passes all policies**
```bash
kubectl apply -f k8s/kyverno-compliant-pod.yaml
# Expected: pod created successfully
```

**Kyverno policy report:**
```bash
kubectl get policyreport -A
kubectl describe policyreport -n default
```

---

## Failure Scenarios

### Failure 1: Kyverno webhook times out → cluster unavailable
Kyverno is down (scaled to 0) and a policy has `failurePolicy: Fail`.
- **Symptom:** All pod creation blocked: `context deadline exceeded` in API server events
- **Fix:** Set `failurePolicy: Ignore` for non-critical policies; keep Kyverno in HA (3 replicas)
- **Emergency recovery:** `kubectl delete validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg`

### Failure 2: PSA `enforce` breaks existing workloads
Apply `enforce=restricted` to a namespace with running pods that use `allowPrivilegeEscalation: true`.
- **Symptom:** Existing pods unaffected (PSA is admission-time only), but any new pods/restarts fail
- **Diagnosis:** `kubectl label namespace myapp pod-security.kubernetes.io/warn=restricted` first (warn mode)
- **Fix:** Audit → warn → enforce progression; fix pods before switching to enforce

### Failure 3: Kyverno policy blocks system namespaces
Apply a ClusterPolicy without excluding `kube-system` and `kyverno` namespaces.
- **Symptom:** kube-system pods (like coredns) can't be restarted; cluster degraded
- **Fix:** Always add `exclude.resources.namespaces` in Kyverno policies

### Failure 4: Policy report shows violations but nothing is blocked
Policy is set to `validationFailureAction: Audit` instead of `Enforce`.
- **Symptom:** `kubectl get policyreport -A` shows FAIL entries; but pods run fine
- **Intended use:** Audit mode is for gradual rollout; switch to `Enforce` when baseline is clean

---

## Validation Checklist

- [ ] Privileged pod blocked in `psa-test` namespace (PSA enforce=restricted)
- [ ] Warning shown but pod created in `psa-audit` namespace (PSA audit mode)
- [ ] Kyverno blocks pod without `owner` label
- [ ] Kyverno blocks pod from `docker.io` registry
- [ ] Kyverno blocks `latest` image tag
- [ ] Kyverno blocks pod without resource `requests`
- [ ] Compliant pod passes all checks and is created
- [ ] `kubectl get policyreport -A` shows report entries for violations

---

## Debugging Reference

```bash
# Why was my pod rejected?
kubectl describe pod <name> -n <ns>   # look at Events
# Or the API server will return the reason in the kubectl error output

# List all Kyverno policies and their status
kubectl get clusterpolicy -o wide

# See what Kyverno would block (dry run)
kubectl apply --dry-run=server -f my-pod.yaml

# Check Kyverno controller logs
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller --tail=50

# Policy report — detailed view
kubectl get policyreport -n default -o yaml

# List all PSA-labelled namespaces
kubectl get ns --show-labels | grep pod-security
```

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- Pod Security Standards (restricted profile): 0 → 3
- OPA / Kyverno policy enforcement: 0 → 2
- Admission Controllers / Webhooks: 0 → 2
