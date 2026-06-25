# Lab-05 Objects - Brief Theory

Lab-05 focuses on StatefulSets for running stateful applications with stable identity, ordered lifecycle, and persistent per-pod storage.

## Objects Touched

- `StatefulSet`
  - Manages pods with stable, predictable names: `<name>-0`, `<name>-1`, `<name>-2`
  - Creates pods in strict ascending order (0 → 1 → 2); each must be Running and Ready before the next starts
  - Deletes pods in strict descending order (2 → 1 → 0) during scaledown
  - Each pod gets its own PVC from `volumeClaimTemplates` — never shared
  - Requires a headless Service (`clusterIP: None`) for stable DNS

- `headless Service` (`clusterIP: None`)
  - No virtual ClusterIP — DNS returns actual pod IPs directly
  - Enables per-pod stable DNS: `<pod>.<service>.<namespace>.svc.cluster.local`
  - Used by cluster members to discover and address each other by stable name

- `volumeClaimTemplates`
  - Defined inside the StatefulSet spec — one PVC is auto-created per pod
  - Named predictably: `<template-name>-<statefulset-name>-<index>`
  - PVCs are **not deleted** when pods are deleted or scaled down — they outlive the pod
  - When a pod is recreated, it reattaches its existing PVC automatically

- `StorageClass`
  - Defines how volumes are provisioned (provisioner, type, encryption, binding mode)
  - `volumeBindingMode: WaitForFirstConsumer` — volume provisioned in the same AZ as the scheduled pod (critical for EBS on EKS)
  - `reclaimPolicy: Delete` — volume deleted when PVC is deleted (use `Retain` in production for critical data)

- `PersistentVolumeClaim` (PVC)
  - Kubernetes object representing a storage request
  - Once `Bound`, it has a backing PersistentVolume (PV) created by the StorageClass provisioner
  - `STATUS: Bound` = volume provisioned and ready
  - `ACCESS MODES: RWO` = ReadWriteOnce — only one pod can mount at a time

- `PodDisruptionBudget` (PDB)
  - Same as in lab-03 — prevents all pods from being evicted simultaneously
  - `minAvailable: 2` = at least 2 pods must remain during voluntary disruptions

## StatefulSet vs Deployment

| Feature | Deployment | StatefulSet |
|---|---|---|
| Pod names | Random (`pod-abc123`) | Stable (`pod-0`, `pod-1`) |
| Pod creation order | All at once | Sequential (0 → N) |
| Pod deletion order | Any order | Reverse (N → 0) |
| Storage per pod | Shared or none | Dedicated PVC per pod |
| DNS per pod | No | Yes (via headless Service) |
| Use case | Stateless apps | Databases, queues, clusters |

## Stable DNS via Headless Service

```
Normal ClusterIP Service:
  myapp.namespace.svc.cluster.local → 10.43.x.x (virtual IP, load-balanced)

Headless Service (clusterIP: None):
  myapp.namespace.svc.cluster.local → 10.42.0.65, 10.42.0.69, 10.42.0.67 (all pod IPs)
  tkb-sts-0.dullahan.namespace.svc.cluster.local → 10.42.0.65 (pod-0 IP only)
  tkb-sts-1.dullahan.namespace.svc.cluster.local → 10.42.0.69 (pod-1 IP only)
```

The per-pod DNS name is stable even when the pod is deleted and recreated — the name resolves to the new pod's IP automatically.

## Volume Mount Trap — Init Container Fix

When a PVC is mounted at a path that contains default content in the container image, the mount **overlays and hides** that content. The directory appears empty at runtime.

**Example:** nginx image bakes `/usr/share/nginx/html/index.html`. Mounting a PVC at `/usr/share/nginx/html` replaces the directory with an empty volume. nginx returns `403 Forbidden` on `GET /` → readiness probe fails → liveness probe kills container → restart loop.

**Fix:** init container that seeds the file before the main container starts:
```yaml
initContainers:
  - name: init-html
    image: busybox:1.36
    command:
      - sh
      - -c
      - |
        if [ ! -f /usr/share/nginx/html/index.html ]; then
          echo "Initialised: $HOSTNAME" > /usr/share/nginx/html/index.html
        fi
    volumeMounts:
      - name: webroot
        mountPath: /usr/share/nginx/html
```

The `if [ ! -f ]` guard prevents overwriting real data on pod restart — init container only seeds if the file is missing.

## StorageClass: Local vs EKS

| Setting | Local (k3s) | EKS (production) |
|---|---|---|
| Provisioner | `rancher.io/local-path` | `ebs.csi.aws.com` |
| Volume type | Directory on node | EBS gp3 volume |
| Encryption | None | `encrypted: "true"` |
| AZ binding | N/A (single node) | `WaitForFirstConsumer` (critical) |
| Resize | Not supported | `allowVolumeExpansion: true` |

On EKS, `WaitForFirstConsumer` ensures the EBS volume is created in the same AZ as the pod. Without it, the volume may provision in a different AZ → pod stuck `Pending` with `volume node affinity conflict`.

## Quick Reference Commands

```bash
# Watch ordered StatefulSet startup
kubectl get pods -n stateful-lab -w

# Check all PVCs and their binding status
kubectl get pvc -n stateful-lab

# Check per-pod stable DNS
kubectl exec -n stateful-lab jump-pod -- \
  nslookup tkb-sts-0.dullahan.stateful-lab.svc.cluster.local

# Check headless service returns all pod IPs
kubectl exec -n stateful-lab jump-pod -- \
  nslookup dullahan.stateful-lab.svc.cluster.local

# Write data to each pod's volume
for i in 0 1 2; do
  kubectl exec -n stateful-lab tkb-sts-$i -- \
    sh -c "echo 'pod-$i' > /usr/share/nginx/html/index.html"
done

# Scale down — observe reverse termination order
kubectl scale statefulset tkb-sts -n stateful-lab --replicas=1

# Diagnose Pending pod (AZ mismatch or PVC issue)
kubectl describe pod tkb-sts-1 -n stateful-lab | grep -A5 "Events:"
kubectl describe pvc webroot-tkb-sts-1 -n stateful-lab

# Teardown
kubectl delete ns stateful-lab
```
