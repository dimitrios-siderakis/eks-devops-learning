# Lab 06: Init Containers & Sidecar Patterns

**Week:** 2 | **Difficulty:** Intermediate | **Est. time:** 2 hours  
**Depends on:** Lab 01 cluster  
**Source material:** `repo_k8sbook/pods/initpod.yml` · `repo_k8sbook/pods/sidecarpod.yml`

## What Poulton's Example Shows vs. What This Lab Adds

| Poulton | This Lab |
|---------|----------|
| Init: DNS gate on `k8sbook` service | → real dependency gate: wait for a named Service to exist |
| Sidecar: git-sync + nginx + emptyDir | → Fluent Bit sidecar shipping logs to CloudWatch |
| No resource limits on init | + resource limits on init containers |
| Single init container | + chained init sequence (2 steps) |

## Objective

Master two core pod patterns:
1. **Init container** — block main container startup until a dependency is healthy
2. **Sidecar** — Fluent Bit reads app logs from a shared volume and ships to CloudWatch

## Architecture

```
Part A — Chained Init Containers
  initpod:
    init-1: wait until postgres Service DNS resolves
    init-2: run DB migration script (or wait for migration job)
    main:   app starts only after both pass

Part B — Fluent Bit Sidecar
  sidecar-pod:
    ctr-app:  writes JSON logs to /var/log/app/app.log (shared emptyDir)
    ctr-fluent-bit: reads /var/log/app/app.log → ships to CloudWatch Logs
  Shared volume: emptyDir (log staging)
```

---

## Lab Steps

### Part A: Init Containers

```bash
kubectl apply -f k8s/init-demo-ns.yaml
kubectl apply -f k8s/init-pod.yaml

# Watch the init container wait
kubectl get pods -n init-lab -w
# initpod stuck in Init:0/2 — postgres service doesn't exist yet

kubectl describe pod initpod -n init-lab | grep -A5 "Init Containers:"
# Shows init-1 running, waiting for DNS to resolve

# Unblock: create the postgres service
kubectl apply -f k8s/postgres-stub-svc.yaml

# Watch init-1 complete, init-2 start, then main container start
kubectl get pods -n init-lab -w

kubectl logs initpod -n init-lab -c init-wait-db
kubectl logs initpod -n init-lab -c init-migrate
kubectl logs initpod -n init-lab -c app
```

### Part B: Fluent Bit Sidecar

```bash
kubectl apply -f k8s/sidecar-fluent-bit.yaml

# Let app write some logs
kubectl exec -n init-lab sidecar-pod -c ctr-app -- \
  sh -c 'for i in $(seq 1 10); do echo "{\"level\":\"info\",\"msg\":\"request-$i\"}"; sleep 1; done >> /var/log/app/app.log'

# Check Fluent Bit is shipping logs
kubectl logs -n init-lab sidecar-pod -c ctr-fluent-bit --tail=20

# Verify in CloudWatch (requires IRSA)
aws logs describe-log-groups --log-group-name-prefix /eks/init-lab
aws logs get-log-events \
  --log-group-name /eks/init-lab/app \
  --log-stream-name $(aws logs describe-log-streams \
    --log-group-name /eks/init-lab/app \
    --query 'logStreams[0].logStreamName' --output text)
```

---

## Failure Scenarios

### Failure 1: Init container never exits — main container never starts
Set the init container to `until nslookup nonexistent-service` with no matching service.
- **Symptom:** Pod stuck `Init:0/1` indefinitely; `kubectl describe pod` shows init still running
- **Fix:** Create the service OR use `kubectl delete pod` + fix the init condition

### Failure 2: Init container resource limits cause OOMKill
Give the init container a 1Mi memory limit during a busy DB probe loop.
- **Symptom:** Pod shows `Init:OOMKilled`; restart loop begins
- **Fix:** Raise memory limit; init containers run once so OOMKill means they never hand off

### Failure 3: Sidecar log volume full (emptyDir has no size limit by default)
Set `emptyDir: {}` (no `sizeLimit`). A verbose app fills the node's disk.
- **Symptom:** Node disk pressure → pod evicted (`The node had condition: DiskPressure`)
- **Fix:** Set `emptyDir.sizeLimit: 100Mi`; ensure Fluent Bit ships faster than app writes

### Failure 4: Sidecar container crashes — main container keeps running
Kill the Fluent Bit container process inside the pod.
- **Symptom:** `kubectl get pods` shows pod `Running` but `READY 1/2`; logs not shipping
- **Diagnostic:** `kubectl describe pod sidecar-pod -n init-lab` shows ctr-fluent-bit `CrashLoopBackOff`
- **Production implication:** Main app is up but logging is broken — silent failure

---

## Validation Checklist

- [ ] `initpod` stuck in `Init:0/2` before postgres service exists
- [ ] After `postgres-stub-svc.yaml` applied, init containers complete in order
- [ ] `kubectl logs initpod -c init-migrate` shows migration completed message
- [ ] Main app container starts only after both init containers exit 0
- [ ] Fluent Bit sidecar shows log entries being shipped in its stdout
- [ ] CloudWatch log group `/eks/init-lab/app` contains JSON log entries

---

## Debugging Reference

```bash
# Which init container is currently running?
kubectl get pod initpod -n init-lab -o jsonpath='{.status.initContainerStatuses}'

# Logs from a specific init container
kubectl logs initpod -n init-lab -c init-wait-db

# Exec into sidecar container (not the main one)
kubectl exec -n init-lab sidecar-pod -c ctr-fluent-bit -- sh

# Check shared volume contents
kubectl exec -n init-lab sidecar-pod -c ctr-app -- ls -la /var/log/app/
```

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- Pod lifecycle & scheduling: 2 → 3
- Container Insights / Fluent Bit: 0 → 1

---

## Production Upgrade — `k8s/production-deployment.yaml`

The basic lab files (`init-pod.yaml`, `sidecar-fluent-bit.yaml`) use raw Pods to teach
patterns clearly. Once you understand them, the production version combines both into a
`Deployment` with proper lifecycle, IRSA, and PDB.

**What changed and why:**

| Basic | Production | Reason |
|-------|-----------|--------|
| `kind: Pod` | `kind: Deployment` (3 replicas) | Self-healing, rolling updates, PDB support |
| IRSA annotation = code comment | Real SA annotation from Terraform | Fluent Bit can actually reach CloudWatch |
| `restartPolicy: OnFailure` | RollingUpdate strategy | App is a service, not a one-shot job |
| No probes | startupProbe + readinessProbe + livenessProbe | Gate traffic, detect hangs, handle slow start |
| No topology spread | topologySpreadConstraints (3 AZ) | Node failure in one AZ doesn't kill all pods |
| No PDB | `minAvailable: 2` | Node drain can't take all 3 pods at once |
| `fluent/fluent-bit:3.0` | `public.ecr.aws/aws-observability/aws-for-fluent-bit:stable` | AWS-supported image, ECR pull (no Docker Hub rate limit) |
| CloudWatch group auto-created | Pre-created by Terraform with 7-day retention | Retention is critical — Fluent Bit can't set retention |

**Apply order for production version:**

```bash
# 1. Provision IRSA role and CloudWatch log group
cd labs/lab-06-init-sidecar/terraform
terraform init
terraform apply -var="oidc_provider_arn=$(cd ../../lab-01-eks-cluster-foundation/terraform && terraform output -raw oidc_provider_arn)" \
                -var="oidc_provider_url=$(cd ../../lab-01-eks-cluster-foundation/terraform && terraform output -raw oidc_provider_url)"

# 2. Annotate the ServiceAccount with the actual role ARN
$(terraform output -raw annotate_command)
# or manually:
kubectl annotate sa fluent-bit-sa -n init-lab \
  eks.amazonaws.com/role-arn=$(terraform output -raw fluent_bit_role_arn) --overwrite

# 3. Apply the namespace (PSA labels added)
kubectl apply -f k8s/init-demo-ns.yaml

# 4. Apply the production deployment
kubectl apply -f k8s/production-deployment.yaml

# 5. Watch pods stuck in Init — all 3 replicas waiting for postgres
kubectl get pods -n init-lab -w

# 6. Unblock init containers
kubectl apply -f k8s/postgres-stub-svc.yaml

# 7. Watch rollout complete
kubectl rollout status deployment/init-sidecar-app -n init-lab
kubectl get pods -n init-lab -o wide  # should show AZ spread

# 8. Verify PDB
kubectl get pdb -n init-lab

# 9. Verify Fluent Bit shipping logs
kubectl logs -n init-lab -l app=init-sidecar-app -c fluent-bit --tail=20
aws logs get-log-events \
  --log-group-name /eks/init-lab/app \
  --log-stream-name $(aws logs describe-log-streams \
    --log-group-name /eks/init-lab/app \
    --order-by LastEventTime --descending \
    --query 'logStreams[0].logStreamName' --output text)
```

**Additional failure scenario (production deployment only):**

### Failure 5: Fluent Bit IRSA not wired — CloudWatch permission denied

The ServiceAccount annotation is set but the token file isn't mounted, or the role trust
policy has a typo in the sub condition.
- **Symptom:** Fluent Bit logs show `AccessDeniedException` or `No credential providers found`
- **Diagnosis:**
  ```bash
  kubectl exec -n init-lab <pod> -c fluent-bit -- env | grep AWS
  # Should show: AWS_WEB_IDENTITY_TOKEN_FILE, AWS_ROLE_ARN
  # If missing: SA annotation wrong, or pod predates annotation
  kubectl delete pod -l app=init-sidecar-app -n init-lab   # force pod restart
  ```
- **Fix:** Confirm SA annotation matches exact role ARN; ensure token volume is projected
  (check `kubectl describe pod` for `projected: kube-api-access` volume)
