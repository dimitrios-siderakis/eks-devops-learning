# Lab-07 Objects - Brief Theory

Lab-07 focuses on Kubernetes DNS-based service discovery across namespaces and NetworkPolicies for enforcing real network isolation.

## Objects Touched

- `Namespace`
  - Logical boundary for resources — **not a network security boundary by default**.
  - Any pod can reach any other pod cluster-wide using the FQDN until a NetworkPolicy blocks it.
  - Pods use short service names (e.g. `ent`) that resolve only within their own namespace.

- `Service` (ClusterIP)
  - Stable virtual IP (ClusterIP) assigned per namespace.
  - The same service name can exist in multiple namespaces independently.
  - DNS name format: `<service>.<namespace>.svc.cluster.local`

- `NetworkPolicy`
  - Firewall rules at the pod level, enforced by the CNI plugin.
  - Default behaviour with no policy: **all traffic allowed** in both directions.
  - Once a NetworkPolicy selects a pod, only explicitly allowed traffic passes.
  - `podSelector: {}` (empty) selects **all pods** in the namespace.
  - Always pair a `default-deny-all` with explicit allow rules — never rely on deny-only.

## Kubernetes DNS Resolution

When a pod makes a request using a short name (e.g. `http://ent:8080`), CoreDNS appends search domain suffixes in order until one resolves:

```
ent → ent.<current-namespace>.svc.cluster.local  ← resolves here, stops
     ent.svc.cluster.local
     ent.cluster.local
```

**Short name always resolves to the local namespace.** To reach a service in another namespace you must use the FQDN:

```
http://ent.prod.svc.cluster.local:8080
```

## NetworkPolicy Structure

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-intra-dev
  namespace: dev
spec:
  podSelector: {}          # applies to all pods in namespace
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              env: dev     # only pods from namespaces with this label
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              env: shared
      ports:
        - port: 80         # see CNI port evaluation note below
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
```

**Critical:** Always add a DNS egress rule (UDP/TCP 53 to kube-system) when using default-deny. Without it, CoreDNS becomes unreachable and all service name resolution breaks — pods can still hit raw IPs but not hostnames.

## CNI Port Evaluation and DNAT

When an egress NetworkPolicy targets a Service, the port to specify depends on **when your CNI evaluates the policy relative to kube-proxy DNAT**:

| CNI | Evaluates policy | Use in egress rule |
|---|---|---|
| Calico, Cilium | **Before** DNAT | Service port (e.g. `8080`) |
| Flannel + kube-proxy iptables (k3s) | **After** DNAT | Container port (e.g. `80`) |

**Example:** `shared-api` Service exposes port `8080`, container listens on `80`.
- In Flannel: by the time the egress rule is evaluated, kube-proxy has already rewritten the destination to `pod:80`. The rule must say `port: 80`.
- In Calico: the rule sees the original `Service:8080` and must say `port: 8080`.

Getting this wrong produces a silent failure — the deny-all catches the packet, but there is no obvious error about a port mismatch. Connection is refused or times out depending on CNI behaviour.

## Flannel vs Calico/Cilium Behaviour

| Behaviour | Flannel (k3s) | Calico / Cilium |
|---|---|---|
| Blocked connection | TCP RST → `Connection refused` | Silent drop → `timeout` |
| Policy evaluation vs DNAT | After DNAT | Before DNAT |
| Typical use | Local / dev clusters | Production EKS |

On EKS you will see **timeouts**, not `connection refused`, when a NetworkPolicy blocks traffic.

## Quick Reference Commands

```bash
# List all NetworkPolicies across all namespaces
kubectl get networkpolicy -A

# Inspect what pods a policy selects and its rules
kubectl describe networkpolicy <name> -n <namespace>

# Verify pod labels match policy selectors
kubectl get pods -n <namespace> --show-labels

# Test DNS resolution from inside a pod
kubectl exec -n dev jump -- nslookup ent
kubectl exec -n dev jump -- nslookup ent.prod.svc.cluster.local

# Test connectivity with a timeout (use --timeout to avoid hanging)
kubectl exec -n dev jump -- wget -qO- --timeout=5 http://ent.prod.svc.cluster.local:8080

# Cleanup — delete all three lab namespaces
kubectl delete ns dev prod shared
```

## Policy Rule Matrix (this lab)

| Source | Destination | Port | Result |
|---|---|---|---|
| dev | ent.dev | 8080 | ✅ allowed (intra-namespace) |
| prod | ent.prod | 8080 | ✅ allowed (intra-namespace) |
| dev | shared-api.shared | 8080 (→pod:80) | ✅ allowed (explicit cross-ns) |
| prod | shared-api.shared | 8080 (→pod:80) | ✅ allowed (explicit cross-ns) |
| dev | ent.prod | 8080 | ❌ blocked (default-deny) |
| prod | ent.dev | 8080 | ❌ blocked (default-deny) |
| any | kube-system:53 | UDP/TCP | ✅ allowed (DNS egress) |
