# Lab-06 Objects - Brief Theory

Lab-06 focuses on two multi-container pod patterns: init containers for dependency gating and sidecars for augmenting a running application with a co-located process.

## Objects Touched

- `Pod` (multi-container)
  - A pod can have `initContainers` (run before main) and `containers` (run in parallel).
  - All containers in a pod share the same network namespace (same IP, same ports) and can share volumes.

- `initContainers`
  - Run sequentially before any main container starts.
  - Each must exit with code 0 before the next one starts.
  - If an init container fails, the pod restarts it until it succeeds (subject to `restartPolicy`).
  - Main containers are not created until all init containers have completed successfully.

- `containers` (sidecar pattern)
  - Run in parallel alongside the main container for the lifetime of the pod.
  - Share volumes and network with the main container.
  - If a sidecar crashes, the main container keeps running — `READY` drops to `N-1/N` but the pod stays `Running`.

- `emptyDir` volume
  - Ephemeral volume created when the pod is scheduled, deleted when the pod is removed.
  - Shared between all containers in the pod that mount it.
  - Used in the sidecar pattern to pass log files from app container to Fluent Bit.
  - Default has no size limit — set `sizeLimit` in production to prevent disk pressure.

- `ConfigMap` (Fluent Bit config)
  - Fluent Bit configuration injected as a volume mount at `/fluent-bit/etc/`.
  - Defines INPUT (tail log file), PARSER (JSON), and OUTPUT (CloudWatch Logs).

- `ServiceAccount` (with IRSA)
  - Fluent Bit needs IAM permissions (`logs:CreateLogGroup`, `logs:PutLogEvents`) to ship to CloudWatch.
  - On EKS, annotate the ServiceAccount with `eks.amazonaws.com/role-arn` to bind an IAM role.
  - Without IRSA on a local cluster, Fluent Bit reads and parses logs correctly but fails at the output stage only.

## Init Container Lifecycle

```
Pod scheduled
    │
    ▼
init-1 runs  ──► exits 0? ──► init-2 runs  ──► exits 0? ──► main container starts
                    │                               │
                   no: restart init-1             no: restart init-2
```

Pod status progression:
```
Init:0/2  →  Init:1/2  →  PodInitializing  →  Running
```

- `Init:0/2` — 0 of 2 init containers complete
- `Init:1/2` — 1 of 2 init containers complete
- `PodInitializing` — all init done, main container being created
- `Running` — main container running

## Sidecar Pattern — Shared Volume Log Shipping

```
ctr-app                          ctr-fluent-bit
   │                                    │
   │ writes JSON logs                   │ tails same file
   ▼                                    ▼
/var/log/app/app.log  ◄── emptyDir ──► CloudWatch Logs (requires IRSA on EKS)
```

Key properties:
- Neither container knows about the other — they share only the volume path
- App writes; Fluent Bit reads — loose coupling
- If Fluent Bit crashes, `READY` shows `1/2` but the app keeps serving — **silent failure**
- Always monitor container-level readiness, not just pod-level status

## Failure Scenario: Silent Sidecar Crash

When a sidecar crashes the pod shows `Running` but `READY 1/2`. The main app is up and serving traffic, but logging is broken. No automatic alert. This is dangerous in production.

**How to detect:**
```bash
kubectl get pods -n <ns>                     # READY shows N-1/N
kubectl describe pod <pod> -n <ns>           # shows CrashLoopBackOff on sidecar container
kubectl logs <pod> -n <ns> -c ctr-fluent-bit # shows crash reason
```

## Debugging Distroless Containers

Hardened/distroless images (like the Fluent Bit official image) have no shell, no `kill`, no `ls`. `kubectl exec -- sh` fails with exit code 127.

**Solution: `kubectl debug` with an ephemeral container**

```bash
kubectl debug -n <namespace> <pod> \
  --image=busybox:1.36 \
  --target=<container-name> \
  -it -- sh
```

- `--target=<container>` shares the target container's PID namespace
- The debug container can see and signal the target's processes
- Ephemeral containers are not saved to the pod spec — they disappear when the pod restarts
- This is the standard way to debug distroless containers in production EKS

## Quick Reference Commands

```bash
# Watch init container progression
kubectl get pods -n init-lab -w

# Logs from a specific init container
kubectl logs <pod> -n <ns> -c init-wait-db

# Logs from a specific sidecar
kubectl logs <pod> -n <ns> -c ctr-fluent-bit --tail=30

# Exec into a specific container in a multi-container pod
kubectl exec -n <ns> <pod> -c ctr-app -- cat /var/log/app/app.log

# Check init container status in JSON
kubectl get pod <pod> -n <ns> -o jsonpath='{.status.initContainerStatuses}'

# Debug a distroless container
kubectl debug -n <ns> <pod> --image=busybox:1.36 --target=<container> -it -- sh

# Teardown
kubectl delete ns init-lab
```

## CloudWatch Output (requires EKS + IRSA)

The Fluent Bit config ships to:
- Log group: `/eks/init-lab/app`
- Log stream prefix: `sidecar-pod/`

On a local cluster (no IRSA, no AWS network path), Fluent Bit correctly reads and parses all log entries but fails only at the delivery step with:
```
Failed to retrieve credentials for AWS Profile default
Failed to create log stream
Failed to send events
```
This is expected and confirms the INPUT and PARSER stages are working. Only the OUTPUT stage requires AWS.
