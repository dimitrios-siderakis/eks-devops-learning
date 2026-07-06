# Lab 03: Production Deployments — Rolling Updates, Probes & Rollback

**Week:** 1–2 | **Difficulty:** Intermediate | **Est. time:** 2–3 hours  
**Depends on:** Lab 01 cluster running  
**Source material:** `repo_getting_started/Deployments/deploy-complete.yml` · `repo_k8sbook/deployments/deploy.yml`

## What Poulton's Example Shows vs. What This Lab Adds

| Poulton | This Lab |
|---------|----------|
| `maxSurge`, `minReadySeconds` | + readiness/liveness/startup probes |
| Static resource `limits` only | + `requests` (required for scheduler) |
| No health gating | + PodDisruptionBudget |
| Basic rollback mention | + scripted failure injection + rollback verification |
| `terminationGracePeriodSeconds: 1` | + realistic 30s drain window |

## Objective

Deploy a production-grade workload to EKS. Inject a bad image to trigger a stalled rollout. Verify PDB blocks unsafe node drain. Roll back cleanly.

## Architecture

```
Deployment: web-app (3 replicas, RollingUpdate)
├── readinessProbe  → gates traffic routing (Service endpoint)
├── livenessProbe   → restarts hung container
├── startupProbe    → gives slow-start apps time to init
└── PodDisruptionBudget → minAvailable: 2

HPA: 2–10 replicas, CPU 60% target
Service: ClusterIP (fronted by ALB Ingress from Lab 02)
```

---

## Lab Steps

### Step 1: Deploy v1

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment-v1.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/pdb.yaml
kubectl apply -f k8s/hpa.yaml
```

Watch rollout:
```bash
kubectl rollout status deployment/web-app -n web
```

Verify endpoints are registered (readiness gates traffic):
```bash
kubectl get endpoints web-app-svc -n web
# All 3 pod IPs should appear — if readinessProbe fails, endpoints are empty
```

### Step 2: Deploy v2 (clean rolling update)

```bash
kubectl apply -f k8s/deployment-v2.yaml
kubectl rollout status deployment/web-app -n web --timeout=120s
```

Watch pods turn over one at a time:
```bash
kubectl get pods -n web -w
```

### Step 3: Inject bad image (stalled rollout)

```bash
kubectl set image deployment/web-app \
  web-ctr=nigelpoulton/k8sbook:does-not-exist \
  -n web
```

Observe:
```bash
kubectl rollout status deployment/web-app -n web
# Hangs — progressDeadlineSeconds will fire after 120s

kubectl get pods -n web
# New pod: ImagePullBackOff or ErrImagePull; old pods untouched (maxUnavailable: 0)

kubectl describe pod -n web -l app=web-app | grep -A5 Events
```

### Step 4: Roll back

```bash
kubectl rollout undo deployment/web-app -n web
kubectl rollout status deployment/web-app -n web
```

Verify history:
```bash
kubectl rollout history deployment/web-app -n web
```

### Step 5: Test PDB blocks unsafe drain

```bash
# Identify which node hosts 2+ web-app pods
kubectl get pods -n web -o wide

# Try to drain it — PDB should block if it would violate minAvailable: 2
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Expected: "Cannot evict pod as it would violate the pod's disruption budget"
# Fix: kubectl uncordon <node-name>
```

---

## Helm Follow-up: Chart This Workload

The `chart/` directory converts the same lab resources into a Helm release:

- `templates/namespace.yaml`
- `templates/deployment.yaml`
- `templates/service.yaml`
- `templates/hpa.yaml`
- `templates/pdb.yaml`
- `values.yaml`

The main lesson: keep reusable Kubernetes structure in `templates/`, and put release-specific knobs in `values.yaml`.

### Pre-flight

Use the local training cluster:

```bash
kubectl config use-context rancher-desktop
kubectl config current-context
kubectl get nodes
```

This lab uses `topologySpreadConstraints` with `topology.kubernetes.io/zone`. If Rancher Desktop has only one node and it is missing the zone label, add it:

```bash
kubectl label node lima-rancher-desktop topology.kubernetes.io/zone=local-az-1 --overwrite
```

### Render and Validate

```bash
helm lint ./chart
helm template lab03 ./chart
```

### Install

```bash
helm install lab03 ./chart
kubectl rollout status deployment/web-app -n web --timeout=120s
kubectl get all -n web
```

### Upgrade

This simulates moving from the original `deployment-v1.yaml` image to `deployment-v2.yaml`:

```bash
helm upgrade lab03 ./chart \
  --set image.tag=2.0 \
  --set changeCause="v2 - updated application image via Helm"

kubectl rollout status deployment/web-app -n web --timeout=120s
helm history lab03
```

### Roll Back

```bash
helm rollback lab03 1
kubectl rollout status deployment/web-app -n web --timeout=120s
helm history lab03
```

### Clean Up

```bash
helm uninstall lab03
kubectl delete namespace web
```

### What Belongs in `values.yaml`

- Image repository/tag
- Replica count
- Service port
- Resource requests/limits
- Probe paths and timings
- HPA min/max/target
- PDB availability rule

Keep API versions, resource kinds, selectors, and rollout structure in templates unless they truly differ by environment.

---

## Failure Scenarios

### Failure 1: Missing resource `requests` → scheduler ignores limits
Remove `requests` from the deployment, leave only `limits`. HPA cannot scale (it uses `requests` for % calculation). Pods may be placed on overcommitted nodes.
- **Symptom:** `kubectl get hpa -n web` shows `<unknown>/60%` for TARGETS
- **Fix:** Always set both `requests` and `limits`

### Failure 2: readinessProbe path returns 404
Change `readinessProbe.httpGet.path` to `/nonexistent`. Pods start but are never added to Endpoints.
- **Symptom:** `kubectl get endpoints web-app-svc -n web` → no addresses
- **Diagnostic:** `kubectl describe pod <pod> -n web` → `Readiness probe failed: HTTP 404`
- **Fix:** Correct the path; wait for probe to pass

### Failure 3: livenessProbe too aggressive
Set `livenessProbe.failureThreshold: 1` and `periodSeconds: 3`. Under load, healthy pods restart constantly.
- **Symptom:** Pod `RESTARTS` counter climbs; traffic drops mid-request
- **Fix:** Tune: `failureThreshold: 3`, `periodSeconds: 10`, add `startupProbe` for slow starts

### Failure 4: PDB + rollout deadlock
Set `pdb.minAvailable: 3` (same as replicas). Rolling update can never proceed — can't evict any pod without violating PDB.
- **Symptom:** `kubectl rollout status` hangs indefinitely
- **Fix:** `minAvailable` should be `replicas - maxUnavailable` at most

---

## Validation Checklist

- [ ] `kubectl rollout status deployment/web-app -n web` → `successfully rolled out`
- [ ] `kubectl get endpoints web-app-svc -n web` → 3 pod IPs listed
- [ ] `kubectl get hpa -n web` → TARGETS shows actual CPU%, not `<unknown>`
- [ ] Bad image deploy: old pods remain running, new pod shows `ErrImagePull`
- [ ] `kubectl rollout undo` restores v1; all endpoints healthy
- [ ] Node drain blocked by PDB when only 2 replicas would remain
- [ ] `kubectl rollout history deployment/web-app -n web` → 2 revisions visible

---

## Debugging Reference

```bash
# Why is the pod not ready?
kubectl describe pod <pod> -n web | grep -A 20 "Conditions:"

# Is the probe path correct?
kubectl exec -n web deploy/web-app -- wget -qO- http://localhost:8080/healthz

# HPA not scaling?
kubectl describe hpa web-app-hpa -n web

# Events on the deployment
kubectl describe deployment web-app -n web | tail -20

# Full rollout history with change cause
kubectl annotate deployment web-app -n web kubernetes.io/change-cause="v1 initial"
kubectl rollout history deployment/web-app -n web
```

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- Deployments / ReplicaSets: 0 → 3
- Resource requests/limits & QoS: 0 → 2
- Horizontal Pod Autoscaler: 0 → 2
- Pod Disruption Budgets: 0 → 2
