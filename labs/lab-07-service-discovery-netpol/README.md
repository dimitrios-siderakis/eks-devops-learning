# Lab 07: Service Discovery & Cross-Namespace Network Policies

**Week:** 2 | **Difficulty:** Intermediate | **Est. time:** 2–3 hours  
**Depends on:** Lab 01 cluster  
**Source material:** `repo_k8sbook/service-discovery/sd-example.yml` · `repo_k8sbook/namespaces/`

## What Poulton's Example Shows vs. What This Lab Adds

| Poulton | This Lab |
|---------|----------|
| Same service name in dev/prod namespaces | + NetworkPolicies enforcing the isolation |
| DNS FQDN resolution from jump pod | + prove isolation is actually enforced (not just logical) |
| ClusterIP services | + headless service DNS comparison |
| No security posture | + default-deny + explicit allow NetworkPolicies |

## Objective

Understand how Kubernetes DNS service discovery works across namespaces, then lock it down with NetworkPolicies so cross-namespace traffic is explicitly controlled — not just assumed isolated.

## Architecture

```
Namespace: dev     → deployment: enterprise (image: text-dev)
Namespace: prod    → deployment: enterprise (image: text-prod)
Namespace: shared  → deployment: shared-api (reachable from both)

Service name 'ent' exists in BOTH dev and prod.
DNS:  ent.dev.svc.cluster.local  ≠  ent.prod.svc.cluster.local
      ent (short name from dev pod) → resolves to dev, NOT prod

NetworkPolicy rules:
  dev   → can reach shared-api
  prod  → can reach shared-api
  dev   → CANNOT reach prod (and vice versa)
  prod  → CANNOT reach dev
```

---

## Lab Steps

### Step 1: Deploy the namespaces and services

```bash
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/sd-deployments.yaml
kubectl apply -f k8s/jump-pod.yaml
```

### Step 2: Explore DNS resolution (no policies yet)

```bash
# From the dev jump pod — short name resolves to dev namespace
kubectl exec -n dev jump -- wget -qO- http://ent:8080
# Expected: "text-dev" response (from dev deployment)

# FQDN — explicitly target prod from dev
kubectl exec -n dev jump -- wget -qO- http://ent.prod.svc.cluster.local:8080
# Expected: "text-prod" response. Cross-namespace IS reachable before NetworkPolicy.

# Prove short name stays local
kubectl exec -n dev jump -- nslookup ent
# Shows: ent.dev.svc.cluster.local — NOT prod
```

### Step 3: Apply NetworkPolicies

```bash
kubectl apply -f k8s/network-policies.yaml
```

### Step 4: Verify enforcement

```bash
# dev → prod: should FAIL
kubectl exec -n dev jump -- wget -qO- --timeout=5 \
  http://ent.prod.svc.cluster.local:8080
# Expected: connection timeout

# dev → shared-api: should SUCCEED
kubectl exec -n dev jump -- wget -qO- --timeout=5 \
  http://shared-api.shared.svc.cluster.local:8080
# Expected: response from shared-api

# prod → dev: should FAIL
kubectl exec -n prod jump -- wget -qO- --timeout=5 \
  http://ent.dev.svc.cluster.local:8080
# Expected: connection timeout

# prod → shared-api: should SUCCEED
kubectl exec -n prod jump -- wget -qO- --timeout=5 \
  http://shared-api.shared.svc.cluster.local:8080
```

---

## Failure Scenarios

### Failure 1: DNS breaks after applying default-deny
Apply default-deny NetworkPolicy without adding egress to kube-system port 53.
- **Symptom:** `kubectl exec -n dev jump -- nslookup ent` → `can't resolve 'ent'`
- **Root cause:** CoreDNS is in `kube-system`; UDP 53 must be explicitly allowed
- **Fix:** Add egress rule: `to namespaceSelector: kubernetes.io/metadata.name=kube-system` port 53

### Failure 2: NetworkPolicy selector typo — policy has no effect
Set `podSelector.matchLabels.app: enterprise` but pods are labelled `app: ent`.
- **Symptom:** Dev can still reach prod after policy applied
- **Diagnostic:** `kubectl describe networkpolicy -n prod` → inspect the selector; `kubectl get pods -n prod --show-labels` → verify labels
- **Fix:** Align policy selector with pod labels

### Failure 3: FQDN vs. short name confusion in app config
App hardcodes `http://ent:8080` in config. From `prod` pod, this resolves to `ent.prod` — but the intent was `ent.shared`.
- **Symptom:** App connects to wrong service silently; data from wrong environment
- **Fix:** Always use FQDN in cross-namespace references: `http://ent.dev.svc.cluster.local:8080`

---

## Validation Checklist

- [ ] Before NetworkPolicy: `dev/jump → ent.prod` succeeds (cross-namespace reachable)
- [ ] After NetworkPolicy: `dev/jump → ent.prod` times out
- [ ] After NetworkPolicy: `dev/jump → shared-api.shared` succeeds
- [ ] After NetworkPolicy: `prod/jump → ent.dev` times out
- [ ] Short name `ent` from `dev` pod resolves to `ent.dev`, not `ent.prod`
- [ ] DNS still works after default-deny (port 53 egress allowed)
- [ ] `kubectl get networkpolicy -A` — shows policies in all three namespaces

---

## Debugging Reference

```bash
# List all NetworkPolicies and their selectors
kubectl get networkpolicy -A -o wide

# Which pods does this policy apply to?
kubectl describe networkpolicy default-deny -n dev

# Test DNS from inside a pod
kubectl exec -n dev jump -- nslookup ent.prod.svc.cluster.local

# Check if a connection is being dropped (vs. refused)
# Timeout = NetworkPolicy drop | Connection refused = pod/port issue
kubectl exec -n dev jump -- wget -qO- --timeout=3 http://ent.prod.svc.cluster.local:8080
echo "exit: $?"   # 1 = timeout/refused

# Verify CoreDNS is reachable from namespace
kubectl exec -n dev jump -- nslookup kubernetes.default
```

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- Pod lifecycle & scheduling: 3 → 3
- Services (ClusterIP, NodePort, LB): 0 → 2
- Network Policies: 2 → 3
