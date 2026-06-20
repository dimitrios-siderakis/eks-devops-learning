# Lab-03 Objects - Brief Theory

Lab-03 focuses on core workload and availability objects in Kubernetes.

## Objects Touched

- `Namespace`
  - Logical isolation boundary for resources.
  - Helps separate environments or applications (`web` in this lab).

- `Deployment` (`deploy`)
  - Declares desired app state: image, replica count, rollout strategy, probes, resources.
  - Manages rolling updates and rollback history.

- `ReplicaSet`
  - Ensures the requested number of pod replicas exist.
  - Usually managed by the Deployment rather than directly.

- `Pod` (`po`)
  - Smallest deployable unit that runs one or more containers.
  - Pod readiness/liveness determines traffic and restart behavior.

- `Service` (`svc`)
  - Stable virtual endpoint for a dynamic set of pods.
  - Routes traffic only to Ready pod endpoints.

- `HorizontalPodAutoscaler` (`hpa`)
  - Adjusts Deployment replicas based on metrics (for example CPU utilization).
  - Requires metrics pipeline and proper resource requests on pods.

- `PodDisruptionBudget` (`pdb`)
  - Protects minimum application availability during voluntary disruptions.
  - Constrains eviction operations such as node drain.

## Health and Availability Controls Used

- `readinessProbe`
  - Controls whether a pod is eligible to receive traffic.
  - Failing readiness removes pod from Service endpoints.

- `livenessProbe`
  - Detects unhealthy containers and triggers restart.
  - Too aggressive settings can cause unnecessary restarts.

- `startupProbe`
  - Gives slow-starting containers time before liveness checks begin.
  - Prevents premature restarts during initialization.

## Quick Reference Command

```bash
kubectl get deploy,po,svc,hpa,pdb -n web
```

- `deploy` = Deployment
- `po` = Pods
- `svc` = Service
- `hpa` = HorizontalPodAutoscaler
- `pdb` = PodDisruptionBudget
