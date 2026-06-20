## 2026-06-17

A PodDisruptionBudget (PDB) in Kubernetes is a safety mechanism for availability during voluntary disruptions. It defines how many pods of an application must remain running when disruptions are triggered intentionally.

## What a PodDisruptionBudget is
A PDB lets you specify availability constraints for a group of pods (usually behind a Deployment, StatefulSet, etc.):
You define either:

minAvailable: minimum number (or %) of pods that must stay up
or
maxUnavailable: how many pods can be taken down at once

Example : 
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app

## What PDB actually protects against
PDBs protect against voluntary disruptions initiated by Kubernetes or operators.
1. Node draining (e.g., maintenance, upgrades)

kubectl drain
Cluster autoscaler scaling down nodes
Managed Kubernetes node upgrades

👉 The eviction API will respect the PDB and block eviction if it violates availability rules.

2. Controlled evictions via the Kubernetes API
Any component that uses the Eviction API must respect PDBs:

Cluster autoscaler
Kubernetes descheduler
Some operators/controllers


3. Rolling updates (sometimes indirectly)

If a Deployment rollout tries to terminate too many pods at once, the PDB can slow or block it
Forces safer rollout pacing


4. Human-initiated disruptions

kubectl drain
Manual eviction (kubectl delete pod via eviction flow)


✅ Bottom line:
PDB ensures that availability SLOs are preserved during planned or controlled operations.

 

---

## 2026-06-20

kubectl uncordon lima-rancher-desktop does one thing:

It marks the node as schedulable again.

What happened before:

kubectl drain ... first cordoned the node (SchedulingDisabled) so no new pods can land there.
Then it tried to evict pods.
Your PDB blocked some web pods (which is correct).
Why uncordon is needed:

While node is cordoned, replacement pods stay Pending.
uncordon flips that flag off.
Scheduler can place pending pods again, and cluster returns to normal.
In short:

drain = prepare node for maintenance by evicting pods + disable scheduling
uncordon = maintenance done, allow scheduling again

## Lab-03 quick object reference

Command:

```bash
kubectl get deploy,po,svc,hpa,pdb -n web
```

What each object is:

- `deploy` (Deployment): desired state for your app rollout (replicas, strategy, image updates, rollback history).
- `po` (Pods): the running app instances created by the Deployment/ReplicaSet.
- `svc` (Service): stable in-cluster endpoint that routes traffic to ready pods.
- `hpa` (HorizontalPodAutoscaler): automatically scales pod count based on metrics (CPU target in this lab).
- `pdb` (PodDisruptionBudget): protects minimum availability during voluntary disruptions (like `kubectl drain`).
- `-n web`: query resources only in namespace `web`.

Quick follow-up checks:

```bash
kubectl describe deployment web-app -n web
kubectl rollout status deployment/web-app -n web
kubectl get endpoints web-app-svc -n web
```

Quick failure triage:

```bash
kubectl get pods -n web
kubectl describe pod -n web -l app=web-app | grep -A5 Events
kubectl get hpa -n web
```

### 2026-06-20 execution summary

- Core lab flow completed: v2 rollout, bad-image rollback, PDB drain protection, recovery via uncordon.
- Failure scenario 2 completed: readiness path changed to `/nonexistent`, pod stayed `Running` but not `Ready`, service endpoints excluded the failing pod, then restored.
- Failure scenario 3 completed: aggressive liveness plus broken liveness path produced restart churn, then restored conservative settings.
- Failure scenario 4 attempted: with current controller behavior and rollout path, deadlock was not reproducible in this single-node setup.
- Final state restored to lab defaults for key controls:
  - Deployment rolling update: `maxSurge=1`, `maxUnavailable=0`
  - Probes: readiness `/`, liveness `/` with conservative timing
  - PDB: `minAvailable=2`