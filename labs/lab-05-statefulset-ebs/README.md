# Lab 05: StatefulSet + EBS gp3 Storage on EKS

**Week:** 2 | **Difficulty:** Intermediate–Advanced | **Est. time:** 3–4 hours  
**Depends on:** Lab 01 cluster (EBS CSI add-on installed)  
**Source material:** `repo_k8sbook/statefulsets/` (sts.yml, headless-svc.yml, app.yml, jump-pod.yml)

## What Poulton's Example Shows vs. What This Lab Adds

| Poulton | This Lab |
|---------|----------|
| StatefulSet with `flash` StorageClass (GKE) | → `gp3` EBS CSI StorageClass (EKS) |
| `volumeClaimTemplates` | + encrypted EBS volumes |
| Headless service for stable DNS | + cross-AZ ordering and AZ-affinity trap |
| Basic pod ordering | + PDB, graceful scaledown, topology constraints |
| No persistence validation | + data survives pod delete + reschedule |

## Objective

Run a 3-replica StatefulSet on EKS with encrypted gp3 EBS volumes. Validate ordered pod startup, stable DNS, and data persistence. Hit the AZ-affinity trap (EBS is AZ-scoped) and fix it.

## Architecture

```
StatefulSet: tkb-sts (3 replicas)
├── Pod: tkb-sts-0  ← first, always
├── Pod: tkb-sts-1  ← waits for 0 Ready
└── Pod: tkb-sts-2  ← waits for 1 Ready

Headless Service: dullahan
└── DNS: tkb-sts-0.dullahan.stateful-lab.svc.cluster.local

PVC per pod (volumeClaimTemplates):
└── webroot-tkb-sts-{0,1,2}: 1Gi gp3 EBS (encrypted, WaitForFirstConsumer)

PodDisruptionBudget: minAvailable: 2
```

---

## Lab Steps

### Step 1: Deploy StorageClass + StatefulSet

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/storageclass.yaml
kubectl apply -f k8s/headless-svc.yaml
kubectl apply -f k8s/statefulset.yaml
kubectl apply -f k8s/pdb.yaml
```

Watch ordered startup:
```bash
kubectl get pods -n stateful-lab -w
# Expected order: tkb-sts-0 Running → tkb-sts-1 Running → tkb-sts-2 Running
```

Verify PVCs:
```bash
kubectl get pvc -n stateful-lab
# All 3 should be Bound. WaitForFirstConsumer means they bind when pod schedules.
```

### Step 2: Validate stable DNS

```bash
kubectl apply -f k8s/jump-pod.yaml
kubectl exec -n stateful-lab jump-pod -- \
  nslookup tkb-sts-0.dullahan.stateful-lab.svc.cluster.local
# Expected: returns pod IP of tkb-sts-0

# Also test headless service returns all pod IPs
kubectl exec -n stateful-lab jump-pod -- \
  nslookup dullahan.stateful-lab.svc.cluster.local
# Expected: all 3 pod IPs (round-robin or all listed)
```

### Step 3: Write data and validate persistence

```bash
# Write unique data to each pod's volume
for i in 0 1 2; do
  kubectl exec -n stateful-lab tkb-sts-$i -- \
    sh -c "echo 'pod-$i data at $(date)' > /usr/share/nginx/html/index.html"
done

# Verify each pod serves its own data
for i in 0 1 2; do
  echo "=== tkb-sts-$i ==="
  kubectl exec -n stateful-lab tkb-sts-$i -- cat /usr/share/nginx/html/index.html
done

# Delete pod-1 and wait for reschedule
kubectl delete pod tkb-sts-1 -n stateful-lab
kubectl get pods -n stateful-lab -w  # should recreate tkb-sts-1

# Data must survive
kubectl exec -n stateful-lab tkb-sts-1 -- cat /usr/share/nginx/html/index.html
# Expected: "pod-1 data at <timestamp>" — same data, volume reattached
```

### Step 4: Ordered scaledown

```bash
kubectl scale statefulset tkb-sts -n stateful-lab --replicas=1
kubectl get pods -n stateful-lab -w
# Expected: tkb-sts-2 terminates first, then tkb-sts-1. tkb-sts-0 remains.

# PVCs are retained (not deleted with pods)
kubectl get pvc -n stateful-lab
# Expected: all 3 PVCs still Bound
```

---

## Failure Scenarios

### Failure 1: AZ mismatch — EBS volume locked to one AZ, pod rescheduled to another

Delete `tkb-sts-1`. If the new pod schedules in a different AZ from its PVC, it gets stuck.
- **Symptom:** Pod stuck `Pending`: `1 node(s) had volume node affinity conflict`
- **Root cause:** EBS volumes are AZ-scoped. Pod must schedule in the same AZ as its PVC.
- **Diagnosis:**
  ```bash
  kubectl describe pvc webroot-tkb-sts-1 -n stateful-lab | grep "topology.kubernetes.io/zone"
  kubectl describe pod tkb-sts-1 -n stateful-lab | grep "volume node affinity"
  ```
- **Fix options:**
  1. Use `WaitForFirstConsumer` (already set) — EBS is provisioned in the pod's AZ
  2. Pin StatefulSet replicas to specific AZs with `nodeAffinity`
  3. Switch to EFS CSI (ReadWriteMany, multi-AZ) for stateless-ish workloads

### Failure 2: StorageClass `Retain` policy orphans volumes on PVC delete

Change `reclaimPolicy: Delete` to `Retain` then delete the StatefulSet entirely.
- **Symptom:** `kubectl get pv` shows volumes in `Released` state, not `Deleted`. AWS charges continue.
- **Fix:** Manually delete the PVs + the underlying EBS volumes, or use `Delete` in non-production

### Failure 3: PDB blocks forced scaledown to zero

Try `kubectl scale statefulset tkb-sts --replicas=0` with `minAvailable: 2` and 3 replicas.
- **Symptom:** The first two pods terminate but the third hangs
- **Fix:** For maintenance, temporarily patch the PDB: `kubectl patch pdb tkb-sts-pdb -n stateful-lab -p '{"spec":{"minAvailable":0}}'`

### Failure 4: StatefulSet rollingUpdate blocked by non-ready pod

Intentionally corrupt `tkb-sts-0`'s readinessProbe target. Rolling update will stall because StatefulSet updates in reverse order (2→1→0) and won't proceed past a non-ready pod.
- **Symptom:** `kubectl rollout status statefulset/tkb-sts` hangs after updating pod-2 and pod-1
- **Fix:** Fix pod-0 health, or use `updateStrategy.rollingUpdate.partition` to skip it temporarily

---

## Validation Checklist

- [ ] Pods created in order: 0 → 1 → 2
- [ ] All 3 PVCs `Bound` to gp3 EBS volumes
- [ ] DNS resolves `tkb-sts-0.dullahan.stateful-lab.svc.cluster.local`
- [ ] After pod-1 deletion, data written to pod-1's volume survives
- [ ] Scaledown terminates in reverse order: 2 → 1
- [ ] `aws ec2 describe-volumes --filters Name=tag:kubernetes.io/created-for/pvc/name,Values=webroot-tkb-sts-0` — volume exists and is `in-use`, encrypted

---

## Debugging Reference

```bash
# Why is pod Pending?
kubectl describe pod tkb-sts-1 -n stateful-lab | grep -A5 "Events:"

# PVC not binding?
kubectl describe pvc webroot-tkb-sts-1 -n stateful-lab
# Look for: ProvisioningFailed, no matching StorageClass, volume node affinity

# Check EBS CSI driver logs
kubectl logs -n kube-system -l app=ebs-csi-controller --tail=30

# Verify EBS volume encryption
aws ec2 describe-volumes \
  --filters "Name=tag:kubernetes.io/created-for/pvc/namespace,Values=stateful-lab" \
  --query 'Volumes[].{ID:VolumeId,AZ:AvailabilityZone,Encrypted:Encrypted,State:State}'
```

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- Pod lifecycle & scheduling: 0 → 2
- PersistentVolumes / StorageClasses: 0 → 3
- EKS add-ons (ebs-csi): 2 → 3
- Taints, tolerations, affinity (AZ affinity): 0 → 1
