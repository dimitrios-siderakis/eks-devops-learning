# Kubernetes — Theory Study Guide

> A plain-English reference covering core Kubernetes concepts.
> Built from hands-on lab experience + official docs: https://kubernetes.io/docs/home/
> Designed to be read top to bottom or used as a quick reference when studying.

---

## 1. What is Kubernetes?

Kubernetes (also called K8s) is a system that runs and manages containerised applications across a group of machines.

Think of it like an **operating system for a cluster of servers**. Just like your laptop's OS decides which apps run, on which CPU cores, and restarts them if they crash — Kubernetes does the same thing, but for containers spread across many machines.

**The problem it solves:**
Before Kubernetes, running apps at scale meant:
- Manually deciding which server to deploy to
- Writing scripts to restart crashed processes
- Manually scaling up when load increased
- Risking downtime during deployments
- No standard way to inject config or secrets

Kubernetes automates all of that.

**The declarative model — the most important concept:**
With Kubernetes you do NOT say *"go start container X on server 3"* (imperative).
You say *"I want 3 copies of container X running at all times"* (declarative) and write that in a YAML file.
Kubernetes continuously compares desired state (your YAML) vs actual state (reality) and fixes any difference. This is called the **reconciliation loop** and it runs forever.

```
Your YAML (desired):  3 replicas running
Reality:              2 replicas running (one crashed)
Action:               Kubernetes starts a new one automatically
```

**What it does for you:**
- Schedules containers onto available machines with enough CPU/memory
- Restarts containers that crash
- Scales pods up or down based on CPU/memory load
- Routes traffic to healthy containers only (removes unhealthy ones from load balancing)
- Rolls out new versions without downtime using rolling updates
- Rolls back to a previous version if the new one is broken
- Stores and injects configuration and secrets into containers
- Provisions and attaches persistent storage
- Enforces network firewall rules between pods

**On EKS:** Amazon Elastic Kubernetes Service (EKS) is AWS's managed Kubernetes. AWS runs and maintains the Control Plane (the brain) for you. You focus on deploying your applications.

**Official docs:** https://kubernetes.io/docs/concepts/overview/

---

## 2. The Cluster: Nodes and the Control Plane

A Kubernetes **cluster** has two types of machines:

```
┌───────────────────────────────────────────────────────────────┐
│                         CLUSTER                               │
│                                                               │
│   ┌──────────────────────────┐    ┌────────┐  ┌────────┐     │
│   │      Control Plane       │    │ Node 1 │  │ Node 2 │     │
│   │  (managed by AWS on EKS) │    │        │  │        │     │
│   │  - API Server            │    │ Pods   │  │ Pods   │     │
│   │  - Scheduler             │    │kubelet │  │kubelet │     │
│   │  - Controller Manager    │    │kube-   │  │kube-   │     │
│   │  - etcd                  │    │proxy   │  │proxy   │     │
│   └──────────────────────────┘    └────────┘  └────────┘     │
└───────────────────────────────────────────────────────────────┘
```

### Control Plane Components

**API Server** — the front door. Every interaction (your `kubectl` commands, other controllers, nodes) goes through the API server. It validates requests and writes state to etcd.

**Scheduler** — decides which node a new pod should run on. It looks at each node's available CPU/memory, pod affinity rules, taints/tolerations, and picks the best fit.

**Controller Manager** — a collection of controllers running in a loop. The Deployment controller watches for desired vs actual replica count and creates/deletes pods. The Node controller watches for node failures. There are dozens of built-in controllers.

**etcd** — the cluster's database. A distributed key-value store that holds ALL cluster state. If etcd is lost, the cluster state is lost. On EKS, AWS backs this up for you.

### Node Components

**kubelet** — the Kubernetes agent running on every node. It watches the API server for pods assigned to its node, starts/stops containers, and reports pod status back.

**kube-proxy** — manages the network rules (iptables/IPVS) on each node that allow Services to route traffic to pods. When you create a Service, kube-proxy programs the rules.

**Container Runtime** — the software that actually runs containers (e.g. containerd, CRI-O). kubelet talks to it via the CRI (Container Runtime Interface).

**On EKS:** AWS manages and patches the Control Plane. You manage the Nodes (via Managed Node Groups or self-managed). Node components (kubelet, kube-proxy, containerd) run on your EC2 instances.

**Official docs:** https://kubernetes.io/docs/concepts/overview/components/

---

## 3. The Pod — The Smallest Unit

A **Pod** is the smallest thing Kubernetes can schedule and run. It wraps one or more containers that always run together on the same node.

Think of a Pod as a **lightweight VM** — all containers inside it share:
- The same IP address (they reach each other via `localhost`)
- The same network namespace
- The same hostname
- Optionally the same storage volumes

```
┌──────────────────────── Pod ─────────────────────────┐
│  Container A (your app)    Container B (sidecar)      │
│  port 8080                 port 9090                  │
│       │                         │                     │
│       │ localhost:9090          │                     │
│       └─────────────────────────┘                     │
│                    │                                  │
│              shared emptyDir volume                   │
│              shared pod IP: 10.42.0.55                │
└──────────────────────────────────────────────────────┘
```

### Pod Lifecycle Phases

| Phase | Meaning |
|---|---|
| `Pending` | Pod accepted but not yet running. Could be: pulling image, waiting for node, waiting for PVC. |
| `Running` | At least one container is running |
| `Succeeded` | All containers exited with code 0 (for Jobs/batch work) |
| `Failed` | All containers have stopped, at least one exited non-zero |
| `Unknown` | Node is unreachable, pod state can't be determined |

### READY column explained
`2/2` means 2 of 2 containers have passed their readiness probe. A pod can be `Running` but `0/1 READY` if the readiness probe is failing.

### Key rules
- Pods are **ephemeral** — they can die and be replaced at any time. Never rely on a pod's IP or hostname surviving.
- When a Pod dies, its local filesystem is gone (unless you use a PersistentVolume)
- You almost never create Pods directly — you use a controller (Deployment, StatefulSet) that manages pods for you and recreates them if they die
- Multiple containers in a pod are used for the **sidecar pattern** (logging, proxies, helpers) — not for running two unrelated apps together

### emptyDir — temporary shared storage
The simplest volume: a directory created when the pod starts and deleted when the pod stops. Used to share files between containers in the same pod (e.g. app writes logs, sidecar reads them).

```yaml
volumes:
  - name: shared-logs
    emptyDir: {}      # deleted when pod is deleted
    # emptyDir:
    #   sizeLimit: 100Mi  # set a cap to avoid disk pressure
```

**Official docs:** https://kubernetes.io/docs/concepts/workloads/pods/

---

## 4. Namespaces — Logical Separation

A **Namespace** divides one cluster into multiple virtual clusters. Think of it as a folder or a project boundary.

```
cluster
├── namespace: default          ← where resources land if you don't specify
├── namespace: kube-system      ← system components (CoreDNS, kube-proxy, metrics-server)
├── namespace: kube-public      ← publicly readable cluster info
├── namespace: production
│   └── pod: api-server
└── namespace: staging
    └── pod: api-server   ← same name, different namespace — no conflict
```

### What namespaces give you
- **Name scoping:** two teams can have a pod named `api-server` — no conflicts
- **RBAC boundary:** you can give a team access to only their namespace
- **Resource quotas:** limit how much CPU/memory a namespace can consume in total
- **Easy cleanup:** `kubectl delete ns staging` removes everything in that namespace at once

### What namespaces do NOT give you
**Namespaces are not a network security boundary.** A pod in `production` can talk to a pod in `staging` using its full DNS name by default. You need NetworkPolicies to enforce actual network isolation.

### Resource Quota — limiting namespace consumption
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    pods: "20"              # max 20 pods in this namespace
    requests.cpu: "4"       # total requested CPU across all pods
    requests.memory: 8Gi    # total requested memory
    limits.cpu: "8"
    limits.memory: 16Gi
```

### Built-in namespaces you should know
| Namespace | Purpose |
|---|---|
| `default` | Where resources land if no namespace specified |
| `kube-system` | Kubernetes system components — don't deploy your apps here |
| `kube-public` | Readable by everyone — used for cluster info |

**Official docs:** https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

---

## 5. Deployments — Running Stateless Apps

A **Deployment** is the standard way to run a stateless application. You describe the desired state and the Deployment controller continuously ensures reality matches it.

The Deployment creates a **ReplicaSet**, which in turn creates and manages the **Pods**. You rarely interact with ReplicaSets directly.

```
Deployment (desired: 3 replicas of v2)
  ├── ReplicaSet v2 (current) — 3 pods
  │     ├── Pod-1 (v2)
  │     ├── Pod-2 (v2)
  │     └── Pod-3 (v2)
  └── ReplicaSet v1 (previous) — 0 pods (kept for rollback history)
```

### Rolling Updates — zero-downtime deployments
When you update a Deployment (e.g. new image tag), Kubernetes does NOT kill all pods at once. It performs a rolling update:

```
Before:  [v1] [v1] [v1]   (3 running)
Step 1:  [v1] [v1] [v1] [v2]  (surge: starts new v2 pod)
Step 2:  [v1] [v1] [v2]   (kills one v1 after v2 is Ready)
Step 3:  [v1] [v2] [v2]   (repeats)
Step 4:  [v2] [v2] [v2]   (done)
```

The key setting: **the new pod must pass its readiness probe before an old pod is removed**. This ensures zero dropped requests during the rollout.

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # allow 1 extra pod above desired count during rollout
    maxUnavailable: 0  # never reduce below desired count during rollout
```

### Rollback
Every update is recorded. If the new version is broken:
```bash
kubectl rollout undo deployment/my-app             # back to previous version
kubectl rollout undo deployment/my-app --to-revision=3  # back to specific version
kubectl rollout history deployment/my-app          # see all recorded revisions
```

### Watching a rollout
```bash
kubectl rollout status deployment/my-app    # live status
kubectl get pods -w                         # watch pods change
```

### Deployment vs ReplicaSet — when to use which
Always use a Deployment, never create a ReplicaSet directly. Deployments add rollout/rollback management on top of ReplicaSets. A ReplicaSet on its own has no rollout history.

**Common gotcha:** If you `kubectl apply` a Deployment with no changes, nothing happens — Kubernetes is idempotent. Only changed fields trigger a new rollout.

**Official docs:** https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

---

## 6. StatefulSets — Running Stateful Apps

A **StatefulSet** is like a Deployment but for applications that need a stable, persistent identity. Databases, message queues, and distributed caches all need to know which peer is which — a Deployment can't provide that.

| Feature | Deployment | StatefulSet |
|---|---|---|
| Pod names | Random (`pod-abc123`) | Stable (`pod-0`, `pod-1`, `pod-2`) |
| Creation order | All at once (parallel) | Sequential: 0 → 1 → 2 |
| Deletion order | Any order | Reverse: 2 → 1 → 0 |
| Storage per pod | Shared or none | Dedicated PVC per pod (never shared) |
| DNS per pod | No | Yes (via headless Service) |
| Use case | Stateless web apps | Databases, queues, caches |

### Why ordered startup matters
In a 3-node database cluster: pod-0 is the primary, pods 1 and 2 are replicas.
- If all three start at once, replicas try to sync from a primary that doesn't exist yet — chaos.
- With a StatefulSet: pod-0 starts and becomes Ready → pod-1 starts and syncs from pod-0 → pod-2 starts and syncs. Clean.

### Why reverse deletion matters
When scaling down from 3 to 1, the highest-indexed replicas (least important) are removed first. Pod-0 (the primary/leader) is last and is never removed unless you scale to 0.

### volumeClaimTemplates — per-pod storage
Instead of one shared PVC for all pods, the StatefulSet auto-creates one PVC per pod:

```yaml
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3-encrypted
      resources:
        requests:
          storage: 10Gi
```

This creates: `data-myapp-0`, `data-myapp-1`, `data-myapp-2` — named predictably. When pod-1 is deleted and recreated, it **reattaches** `data-myapp-1` with all previous data intact.

**Critical:** PVCs are NOT deleted when pods are deleted. They outlive the pod. Only deleting the StatefulSet with `--cascade=orphan` or deleting PVCs manually removes the data.

### Headless Service requirement
Every StatefulSet must reference a headless Service (covered in Section 7). The `serviceName` field in the StatefulSet spec must match the headless Service name. Without it, per-pod DNS names don't work.

```yaml
spec:
  serviceName: "mydb"   # must match the headless Service
  replicas: 3
```

### Pod status progression
```
Init:0/1 → PodInitializing → Running 0/1 → Running 1/1 → [next pod starts]
```
Each pod must reach `1/1 Running` (pass readiness probe) before the next pod is created.

**Official docs:** https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

---

## 7. Services — Stable Network Endpoints

Pods come and go. Their IP addresses change every time they restart. A **Service** gives you a stable address that always routes to the correct pods, regardless of which pods are running at any moment.

A Service uses a **label selector** to find its pods. Any pod with matching labels is automatically included. When a pod is added or removed, the Service updates its routing table instantly.

```yaml
selector:
  app: my-api   # route to any pod with label app=my-api
```

### Service Types

#### ClusterIP (default) — internal only
Creates a stable virtual IP inside the cluster. Only reachable from within the cluster.
```
Client pod → Service VIP (10.43.x.x:8080) → kube-proxy → Pod-1, Pod-2, or Pod-3
```
Use for: internal service-to-service communication.

#### NodePort — exposes on every node
Opens the same port on every node in the cluster. Traffic to `<any-node-IP>:<nodePort>` is forwarded to the pods.
- Ports are in range 30000–32767
- Useful for testing; avoid in production (exposes node IPs, limited port range)

#### LoadBalancer — cloud load balancer
On EKS, creates an AWS Load Balancer (ALB or NLB) automatically. Gives you a public DNS name. Uses the AWS Load Balancer Controller add-on.

#### Headless Service (`clusterIP: None`) — for StatefulSets
No virtual IP. DNS returns the actual pod IPs directly. Each StatefulSet pod gets a stable DNS name:
```
tkb-sts-0.dullahan.namespace.svc.cluster.local → 10.42.0.65 (pod-0's actual IP)
tkb-sts-1.dullahan.namespace.svc.cluster.local → 10.42.0.69 (pod-1's actual IP)
```
Querying the headless service itself returns ALL pod IPs (useful for peer discovery).

### How Services route traffic
Services don't actually proxy traffic themselves. **kube-proxy** on each node programs `iptables` (or IPVS) rules that DNAT packets destined for the Service VIP to a real pod IP. This happens at the kernel level with no userspace overhead.

### Traffic only goes to Ready pods
The Service maintains an **Endpoints** object that lists pod IPs. When a pod fails its readiness probe, its IP is removed from Endpoints immediately. Traffic stops going to it. When it recovers, it's added back. This is how zero-downtime rolling updates work.

```bash
kubectl get endpoints my-service -n my-ns  # see which pod IPs are active
```

**Common gotcha:** If all pods fail readiness, the Endpoints list is empty and all requests to the Service get no response. Watch readiness probes carefully.

**Official docs:** https://kubernetes.io/docs/concepts/services-networking/service/

---

## 8. DNS — How Pods Find Each Other

Every Service gets a DNS name automatically when it's created:
```
<service-name>.<namespace>.svc.cluster.local
```

**CoreDNS** is the DNS server running inside every cluster (in `kube-system`). When a pod does `nslookup my-service`, it queries CoreDNS at the cluster DNS IP (usually `10.43.0.10` or similar).

### Short names vs FQDNs
When a pod looks up `ent`, CoreDNS tries a list of search domains in order:
```
ent                                   ← bare name (usually fails)
ent.dev.svc.cluster.local             ← appends current namespace → FOUND, stops here
ent.svc.cluster.local                 ← not tried (already resolved)
ent.cluster.local                     ← not tried
```

The short name `ent` from a pod in namespace `dev` **always** resolves to `ent.dev` — never to `ent.prod`. This is a deliberate security feature.

**The golden rule:** Always use FQDNs when referencing services across namespaces:
```
http://ent.prod.svc.cluster.local:8080   ✔ explicit, always correct
http://ent:8080                           ✘ resolves to current namespace silently
```

### What nslookup output means
```
Server:     10.43.0.10         ← CoreDNS IP
Address:    10.43.0.10:53

** server can't find ent.cluster.local: NXDOMAIN  ← normal, ignore

Name:    ent.dev.svc.cluster.local    ← the answer you care about
Address: 10.43.34.27                  ← Service ClusterIP
```
The NXDOMAIN errors for shorter suffixes are normal — they're failed search domain attempts before the correct one resolved.

### Pod DNS names
Pods also get DNS names, but they use hyphens instead of dots in the IP:
```
10-42-0-55.default.pod.cluster.local   ← pod with IP 10.42.0.55
```
This is rarely used directly. Per-pod addressing is done via StatefulSet headless Service names instead.

### DNS and NetworkPolicies — important interaction
If you apply a `default-deny-all` NetworkPolicy, **DNS breaks**. CoreDNS is in `kube-system` and the egress to it is blocked. You must explicitly allow UDP/TCP port 53 egress to `kube-system` in every NetworkPolicy that uses default-deny.

**Official docs:** https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

---

## 9. NetworkPolicies — Actual Network Isolation

**The most important thing to know:** By default, every pod in a Kubernetes cluster can talk to every other pod — across namespaces — with no restrictions. Namespaces do not provide network isolation.

A **NetworkPolicy** is a firewall rule at the pod level. It restricts which pods can send traffic to which other pods, and on which ports.

### The default-deny + explicit allow pattern
This is the only safe way to use NetworkPolicies:

```yaml
# Step 1: Block everything
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: dev
spec:
  podSelector: {}   # empty = selects ALL pods in this namespace
  policyTypes:
    - Ingress
    - Egress
  # No rules = deny everything
```

```yaml
# Step 2: Add back only what you need
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-intra-dev
  namespace: dev
spec:
  podSelector: {}        # applies to all pods in dev
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              env: dev   # only allow traffic from dev namespace
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              env: shared
      ports:
        - port: 80       # allow reaching shared services
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - port: 53
          protocol: UDP  # CRITICAL: allow DNS or nothing resolves
        - port: 53
          protocol: TCP
```

### Selectors in NetworkPolicy
- `podSelector` — select by pod labels
- `namespaceSelector` — select by namespace labels
- Both combined — pods with label X in namespace with label Y
- `{}` (empty) — matches ALL pods / ALL namespaces

### CNI enforcement — not all CNIs behave the same
NetworkPolicies are defined in Kubernetes but **enforced by the CNI plugin** installed on the cluster. Different CNIs handle edge cases differently:

| CNI | Policy evaluation vs DNAT | Blocked connection shows as |
|---|---|---|
| Calico | Before DNAT (use Service port in egress rules) | Timeout (silent drop) |
| Cilium | Before DNAT | Timeout |
| Flannel (k3s) | After DNAT (use container port in egress rules) | `Connection refused` (TCP RST) |

On **EKS**, the VPC CNI plugin + a NetworkPolicy add-on (Calico or built-in EKS NetworkPolicy) is used. You'll see timeouts, not `connection refused`, when traffic is blocked.

### Common mistakes
1. **Forgetting DNS egress** — DNS breaks silently after default-deny
2. **Wrong port** — using Service port instead of container port (or vice versa) depending on CNI
3. **Selector typo** — policy applies to no pods, traffic flows freely with no warning
4. **Only one direction** — you need egress rules on the sender AND ingress rules on the receiver

**Official docs:** https://kubernetes.io/docs/concepts/services-networking/network-policies/

---

## 10. Health Checks — Probes

Kubernetes uses three types of probes to check if a container is healthy. Getting these right is critical — wrong probe settings are one of the most common causes of production incidents.

### readinessProbe — "Is this container ready to receive traffic?"
- A **failing** readiness probe removes the pod's IP from the Service Endpoints
- The container is **not restarted** — it stays running but receives no traffic
- Use for: app still warming up, DB connection not established yet, circuit breaker open
- Once the probe passes again, traffic resumes automatically

### livenessProbe — "Is this container still alive and functioning?"
- A **failing** liveness probe kills the container and triggers a restart
- Use for: detecting deadlocks, zombie processes, infinite loops that don't crash
- **Warning:** if `initialDelaySeconds` is too short, liveness will kill your app before it finishes starting

### startupProbe — "Has this container finished its initial startup?"
- **Disables** liveness and readiness checks until it passes
- Use for: slow-starting apps (JVM warmup, legacy systems, database migration on startup)
- Once it passes, normal liveness/readiness take over
- Prevents liveness from killing a slow-starting container before it's had a chance to initialise

### Probe types
```yaml
# HTTP GET — most common. Success = 2xx or 3xx response.
readinessProbe:
  httpGet:
    path: /healthz
    port: 8080

# TCP Socket — success if port accepts a connection
readinessProbe:
  tcpSocket:
    port: 5432

# Exec — success if command exits 0
livenessProbe:
  exec:
    command: ["pg_isready", "-U", "postgres"]
```

### Timing parameters
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10   # wait 10s before first check
  periodSeconds: 5          # check every 5s
  timeoutSeconds: 3         # fail if no response in 3s
  failureThreshold: 3       # 3 consecutive failures = unhealthy
  successThreshold: 1       # 1 success after failure = healthy again
```

### Volume mount trap — common crash loop cause
If you mount a volume at a path where the container image has default content, the volume overlays it with an empty directory. Any probe checking for a file or HTTP path that relied on that default content will fail → liveness kills → restart loop.

**Fix:** use an init container to seed the required file before the main container starts.

### Reading probe failures
```bash
kubectl describe pod <pod> -n <ns> | grep -A10 "Events:"
# Look for:
# Liveness probe failed: HTTP probe failed with statuscode: 403
# Readiness probe failed: connection refused
```

**Official docs:** https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

---

## 11. ConfigMaps and Secrets — Injecting Configuration

Hardcoding configuration in container images is bad practice — it means rebuilding the image for every environment change. ConfigMaps and Secrets decouple config from code.

### ConfigMap — non-sensitive configuration
Stores key-value pairs or whole file contents. Typical use: environment names, feature flags, config files, URLs.

**Creating a ConfigMap:**
```bash
# From literals
kubectl create configmap app-config \
  --from-literal=ENV=production \
  --from-literal=LOG_LEVEL=info

# From a file (the filename becomes the key)
kubectl create configmap nginx-conf --from-file=nginx.conf
```

**Injection method 1: Environment variables**
```yaml
env:
  - name: LOG_LEVEL
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: LOG_LEVEL
```
- Simple and fast
- **Downside:** changes require pod restart to take effect

**Injection method 2: Volume mount (files)**
```yaml
volumeMounts:
  - name: config-vol
    mountPath: /etc/config
volumes:
  - name: config-vol
    configMap:
      name: app-config
```
- Each key becomes a file in `/etc/config/`
- **Advantage:** kubelet syncs changes automatically — no pod restart needed
- Use for config files (nginx.conf, application.yaml, etc.)

**Immutable ConfigMaps:**
```yaml
immutable: true
```
Prevents accidental modification. Kubernetes rejects any edit attempt. Good for production where you want config to be predictable and version-controlled.

### Secret — sensitive data
Same API as ConfigMap but values are base64-encoded. Kubernetes treats them slightly differently (less likely to be printed in logs, can be restricted via RBAC).

**Critical security fact:** Native Kubernetes Secrets are base64-encoded, not encrypted. Anyone with `kubectl get secret` permission can decode them:
```bash
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
```

For real security, etcd must be encrypted with KMS — this is NOT enabled by default.

**Secret types:**
| Type | Use |
|---|---|
| `Opaque` | Generic key-value pairs (most common) |
| `kubernetes.io/tls` | TLS certificate + key |
| `kubernetes.io/dockerconfigjson` | Docker registry pull credentials |
| `kubernetes.io/service-account-token` | Auto-generated SA tokens |

### Production pattern on EKS: Secrets Manager + CSI Driver
Instead of storing secrets in etcd, store them in AWS Secrets Manager (encrypted, audited, rotatable) and mount them as files using the Secrets Store CSI Driver + IRSA:

```
Pod → CSI Driver → AWS Secrets Manager → mounts secret as file in /mnt/secrets/
```

The pod never sees the secret as a Kubernetes object. Rotation happens automatically without restarting the pod.

**Official docs:**
- ConfigMaps: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/

---

## 12. Persistent Storage — PVCs and StorageClasses

Pods are ephemeral. Anything written to a container's filesystem is lost when the pod dies. For data that must survive, you need persistent storage.

### The storage abstraction stack
```
Your Pod
  └── PersistentVolumeClaim (PVC)   ← your request: "I need 10Gi, RWO"
        └── PersistentVolume (PV)       ← the actual disk (auto-created by StorageClass)
              └── Cloud Volume               ← AWS EBS, GCP PD, Azure Disk, NFS...
```

You work with PVCs. Kubernetes (via the StorageClass provisioner) handles creating the actual volume.

### PersistentVolumeClaim (PVC)
A request for storage. You specify how much and what access mode:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3-encrypted
  resources:
    requests:
      storage: 10Gi
```

### StorageClass
Defines how volumes are provisioned. The provisioner field tells Kubernetes which driver to use:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-encrypted
provisioner: ebs.csi.aws.com          # AWS EBS CSI driver (on EKS)
volumeBindingMode: WaitForFirstConsumer  # provision in same AZ as pod
reclaimPolicy: Delete                    # delete EBS volume when PVC is deleted
allowVolumeExpansion: true               # allow resizing without recreation
parameters:
  type: gp3
  encrypted: "true"
```

**`WaitForFirstConsumer` is critical on EKS.** EBS volumes are locked to a single Availability Zone. If the volume is provisioned immediately (before the pod is scheduled), it might be created in AZ-1 while the pod schedules in AZ-2 — pod stuck `Pending` forever with error `volume node affinity conflict`.

With `WaitForFirstConsumer`, Kubernetes waits until the pod is scheduled, learns which AZ it's on, and then provisions the EBS volume in that same AZ.

### Access Modes
| Mode | Abbreviation | Meaning | Typical use |
|---|---|---|---|
| ReadWriteOnce | RWO | One pod, read + write | Databases (EBS) |
| ReadOnlyMany | ROX | Many pods, read only | Shared static content |
| ReadWriteMany | RWX | Many pods, read + write | Shared file storage (EFS) |

**EBS is RWO only.** It can only be attached to one node at a time. For shared storage across pods, use EFS (NFS-based, RWX).

### Reclaim Policy
| Policy | What happens when PVC is deleted |
|---|---|
| `Delete` | PV and cloud volume are deleted. Data gone. |
| `Retain` | PV and cloud volume survive. Data preserved. Requires manual cleanup. |

Use `Retain` in production for critical data. Use `Delete` in dev/test to avoid orphaned EBS volumes accumulating charges.

### emptyDir vs PVC
| | emptyDir | PVC |
|---|---|---|
| Lifetime | Pod lifetime | Outlives pods |
| Survives pod restart | No | Yes |
| Size limit | Optional | Specified |
| Use case | Temp files, sidecar sharing | Database data, uploads |

**Official docs:** https://kubernetes.io/docs/concepts/storage/persistent-volumes/

---

## 13. Init Containers — Dependency Gates

Init containers run **before** the main container starts. They are designed for setup tasks that must complete successfully before the app can start safely.

### How they work
```
Pod scheduled
    │
    ▼
init-1 runs → must exit 0 → init-2 runs → must exit 0 → main container starts
    │                              │
   if fails: restart init-1      if fails: restart init-2
   (never reaches init-2)        (never reaches main)
```

### Pod status during init
```
Init:0/2 → Init:1/2 → PodInitializing → Running 0/1 → Running 1/1
```

### Why init containers instead of app-side retry logic?
**Without init containers:** app starts, tries to connect to DB, fails, crashes, restarts, fails again — enters `CrashLoopBackOff`. Each restart adds a longer backoff delay (1s, 2s, 4s, 8s...). The app is unavailable and generating noise in logs and alerts.

**With init containers:** the pod sits quietly in `Init:0/2` polling the dependency. No crashes. No backoff. No noise. When the dependency is ready, the main app starts once, cleanly.

### Common use cases
| Init container task | What it does |
|---|---|
| DNS probe | `until nslookup postgres; do sleep 2; done` — wait for DB to be reachable |
| DB migration | Run schema migrations before app starts |
| Config render | Fetch secrets and write config files to a shared volume |
| Permission fix | `chown` a mounted volume to the correct UID before the main app uses it |
| Wait for service | `until curl -sf http://auth-service/health; do sleep 2; done` |

### Init containers and volumes
Init containers can use the same volumes as the main container. A common pattern: init container writes files to a volume, main container reads them.

```yaml
initContainers:
  - name: init-config
    image: busybox:1.36
    command: ['sh', '-c', 'echo "app-started" > /shared/status.txt']
    volumeMounts:
      - name: shared-data
        mountPath: /shared
containers:
  - name: app
    volumeMounts:
      - name: shared-data
        mountPath: /shared   # sees the file written by init container
```

### Key differences from regular containers
- Run once and exit — they're not long-running processes
- Restart policy for init containers is always `Always` (until they succeed)
- Do not support readiness probes (they're not serving traffic)
- Listed under `initContainers:`, not `containers:` in the pod spec

**Official docs:** https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

---

## 14. Sidecar Containers — Augmenting Your App

A **sidecar** is a container that runs alongside the main container in the same pod for the entire lifetime of the pod. Both start at the same time. Both share the pod's network and volumes.

### The log-shipping pattern (most common)
```
Pod READY: 2/2
├── ctr-app         ← writes JSON logs to /var/log/app/app.log
└── ctr-fluent-bit  ← reads /var/log/app/app.log, ships to CloudWatch
         │
     shared emptyDir volume (/var/log/app/)
```

The app doesn't know or care how logs are shipped. Fluent Bit doesn't know or care what the app does. They share only the volume path.

### Why sidecars instead of building logging into the app?
- **Separation of concerns:** the app team writes business logic; the platform team manages log shipping
- **Portability:** swap the logging sidecar (Fluent Bit → Logstash → Vector) without touching app code
- **Language agnostic:** works with any app regardless of language or framework
- **Consistent observability:** every app across the platform uses the same sidecar — uniform log format

### Other common sidecar patterns
| Sidecar | What it does |
|---|---|
| Fluent Bit / Fluentd | Collect and ship logs |
| Envoy / Istio proxy | Service mesh: traffic control, mTLS, observability |
| Vault agent | Fetch and renew secrets, write to shared volume |
| git-sync | Clone a git repo to a shared volume on a timer |
| Prometheus exporter | Expose app metrics in Prometheus format |

### Silent failure — the key risk
If a sidecar crashes, the main container keeps running. The pod shows `1/2 Running`. The app continues serving traffic. **But the sidecar's function (logging, security proxy, secret rotation) is broken silently.**

Kubernetes does NOT automatically alert you that one of the two containers in a pod has died. You must:
- Monitor container-level readiness, not just pod-level
- Set up alerts on `READY` ratio (e.g. alert when `kube_pod_container_status_ready` is 0 for a non-init container)

```bash
# Detect a crashed sidecar:
kubectl get pods -n <ns>              # READY shows 1/2
kubectl describe pod <pod> -n <ns>   # shows CrashLoopBackOff on sidecar
kubectl logs <pod> -n <ns> -c ctr-fluent-bit  # see why it crashed
```

### Debugging distroless sidecar containers
Hardened/production sidecar images (like the AWS Fluent Bit image) are often distroless — no shell, no tools. `kubectl exec -- sh` fails with `executable not found`.

Solution: `kubectl debug` with an ephemeral container:
```bash
kubectl debug -n <ns> <pod> \
  --image=busybox:1.36 \
  --target=ctr-fluent-bit \
  -it -- sh
# Now inside: can see fluent-bit's processes, send signals, inspect filesystem
```

**Official docs:** https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

---

## 15. HPA — Horizontal Pod Autoscaler

The **HPA** automatically adjusts the number of replicas in a Deployment (or StatefulSet) based on observed metrics. It ensures your app can handle load spikes without manual intervention.

### How it works
```
HPA polls metrics every 15s
  │
  ├── avg CPU > target threshold → scale UP (add replicas)
  └── avg CPU < target threshold → scale DOWN (remove replicas, with cooldown)
```

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60   # scale when avg CPU > 60% of requested
```

### The hard requirement: resource requests
HPA calculates utilisation as:
```
utilisation % = actual CPU used / CPU requested
```

If a pod has no `resources.requests.cpu`, there is no baseline. The HPA will refuse to scale and show:
```
Warning  FailedGetResourceMetric  unable to get metrics for resource cpu
```

**Always set resource requests on pods that will be autoscaled.**

### Scale-up vs scale-down behaviour
- **Scale up** is fast — happens within seconds when threshold is crossed
- **Scale down** is slow by design — Kubernetes waits several minutes (default 5 min) before scaling down to avoid flapping. High load might be brief; you don't want to scale down and immediately have to scale back up.

### Metric types
| Type | Example use |
|---|---|
| CPU utilisation | General-purpose workloads |
| Memory utilisation | Memory-intensive apps |
| Custom metrics | Queue depth, request latency, active connections |
| External metrics | SQS queue size, Datadog metric |

### HPA + PDB interaction
If you have `minAvailable: 2` in a PDB and the HPA tries to scale down to 1 replica, it will be blocked. HPA and PDB work together: HPA controls the desired count, PDB controls the minimum safe count during disruptions.

**Official docs:** https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

---

## 16. PodDisruptionBudget — Protecting Availability

A **PDB** tells Kubernetes: "when you need to evict pods voluntarily, never take the service below this availability level."

### What counts as a voluntary disruption?
- Node drain (`kubectl drain`) during maintenance or upgrades
- Cluster autoscaler removing an underutilised node
- Rolling update of the underlying node group
- Manual `kubectl delete pod`

### What does NOT count (involuntary)
- Node hardware failure
- Kernel panic
- Cloud provider instance termination

A PDB only protects against the voluntary cases.

### Two ways to set the threshold
```yaml
spec:
  minAvailable: 2    # at least 2 pods must be running at all times
  # OR
  maxUnavailable: 1  # at most 1 pod may be unavailable at a time
```

**With 3 replicas and `minAvailable: 2`:**
When draining a node, Kubernetes can evict 1 pod (leaving 2 running). It waits for a replacement to be scheduled and healthy before evicting another. If the replacement fails to start, the drain stalls — this is the intended safety behaviour.

**With `maxUnavailable: 1`:** same effect as above, expressed differently.

### PDB + StatefulSet
For StatefulSets (databases), set `maxUnavailable: 1` to ensure only one replica is down at a time during node maintenance. If you need to drain a node that has a StatefulSet pod, the PDB prevents all replicas from going down simultaneously.

### Checking PDB status
```bash
kubectl get pdb -n <ns>
# Shows: NAME   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
# ALLOWED DISRUPTIONS = how many pods CAN be evicted right now
# If ALLOWED DISRUPTIONS = 0, the drain will block
```

### Common mistake: PDB blocks a node drain permanently
If you have `minAvailable: 3` and 3 replicas, `ALLOWED DISRUPTIONS = 0` always. No pod can ever be evicted. Node drains will hang indefinitely.

For emergency maintenance, temporarily patch the PDB:
```bash
kubectl patch pdb my-pdb -n <ns> -p '{"spec":{"maxUnavailable":2}}'
```

**Official docs:** https://kubernetes.io/docs/concepts/workloads/pods/disruptions/

---

## 17. Resource Requests and Limits

Every container should declare the CPU and memory it needs. Without this, Kubernetes can't schedule pods efficiently or protect nodes from being overwhelmed.

```yaml
resources:
  requests:
    cpu: 100m       # 100 millicores = 0.1 of one CPU core
    memory: 128Mi   # 128 mebibytes
  limits:
    cpu: 500m       # hard cap
    memory: 256Mi   # hard cap
```

### Requests — for scheduling
The scheduler uses **requests** to decide which node a pod can fit on. A node with 2 CPU cores can fit 20 pods that each request 100m. The actual CPU usage might be higher or lower — requests are just the reservation.

### Limits — for runtime enforcement
Limits are enforced by the container runtime (cgroups):
- **CPU limit exceeded:** container is **throttled** (slowed down). It does not crash. You may see slow response times.
- **Memory limit exceeded:** container is **OOMKilled** (kernel kills it, pod restarts). This is the most common cause of unexpected pod restarts.

### CPU units: millicores
| Value | Means |
|---|---|
| `1000m` | 1 full CPU core |
| `500m` | Half a CPU core |
| `100m` | 10% of one CPU core |
| `1` | Same as `1000m` |

### Memory units
| Value | Means |
|---|---|
| `128Mi` | 128 mebibytes (1 Mi = 1024 × 1024 bytes) |
| `1Gi` | 1 gibibyte |
| `128M` | 128 megabytes (slightly different from Mi) |

### QoS Classes — eviction priority
Kubernetes automatically assigns a QoS (Quality of Service) class based on your resource declarations:

| Class | Condition | Evicted when... |
|---|---|---|
| `Guaranteed` | requests == limits for all containers | Last to be evicted (only under extreme pressure) |
| `Burstable` | requests < limits (or only requests set) | Evicted when node is under memory pressure |
| `BestEffort` | No requests or limits set at all | First to be evicted |

**Production rule:** Set both requests and limits on all containers. Aim for `Guaranteed` on critical workloads.

### Namespace ResourceQuota
Cap total resource usage across all pods in a namespace:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "8"       # team-a can't request more than 8 CPU total
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    pods: "50"
```

**Official docs:** https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

---

## 18. RBAC — Who Can Do What

**Role-Based Access Control** determines which users, groups, or service accounts can perform which actions on which Kubernetes resources. It is enabled by default on all modern clusters.

### The four RBAC objects

| Object | Scope | What it does |
|---|---|---|
| `Role` | Namespace only | Defines allowed verbs on resources within one namespace |
| `ClusterRole` | Cluster-wide | Defines allowed verbs on resources across all namespaces |
| `RoleBinding` | Namespace | Grants a Role (or ClusterRole) to a subject within one namespace |
| `ClusterRoleBinding` | Cluster-wide | Grants a ClusterRole to a subject across all namespaces |

### Verbs and resources
```yaml
rules:
  - apiGroups: [""]        # "" = core API group (pods, services, configmaps...)
    resources: ["pods"]    # what object type
    verbs: ["get", "list", "watch"]  # what actions are allowed
```

Common verbs: `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`

### Example: read-only access to pods in one namespace
```yaml
# Step 1: Define what is allowed
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
---
# Step 2: Grant it to a ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: dev
subjects:
  - kind: ServiceAccount
    name: my-app-sa
    namespace: dev
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### ServiceAccounts — identity for pods
Every pod runs as a ServiceAccount. By default it runs as the `default` SA in its namespace, which has no permissions. To give a pod access to the Kubernetes API, create a dedicated SA, bind it to a Role, and reference it in the pod spec.

```yaml
spec:
  serviceAccountName: my-app-sa   # pod assumes this identity
```

### Testing permissions
```bash
# Can this service account delete pods in namespace dev?
kubectl auth can-i delete pods \
  --namespace=dev \
  --as=system:serviceaccount:dev:my-app-sa
# Returns: yes or no
```

### IRSA on EKS (IAM + RBAC combined)
On EKS, you can bind an **AWS IAM role** to a Kubernetes ServiceAccount using IRSA (IAM Roles for Service Accounts). This gives pods AWS permissions (S3, DynamoDB, SecretsManager, etc.) without storing AWS credentials anywhere:

```yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-app-role
```

This is the production pattern for any pod that needs AWS access.

**Official docs:** https://kubernetes.io/docs/reference/access-authn-authz/rbac/

---

## 19. Quick Reference: kubectl Commands

```bash
# ── CLUSTER ───────────────────────────────────────────────────
kubectl get nodes                          # list nodes
kubectl config current-context            # which cluster am I on?
kubectl config get-contexts               # all available clusters

# ── RESOURCES ─────────────────────────────────────────────────
kubectl get pods -n <ns>                  # list pods in namespace
kubectl get all -n <ns>                   # list all resources
kubectl describe pod <name> -n <ns>       # full details + events
kubectl logs <pod> -n <ns>               # container logs
kubectl logs <pod> -n <ns> -c <container> # specific container
kubectl exec -n <ns> <pod> -- <command>  # run command in pod

# ── DEPLOYMENTS ───────────────────────────────────────────────
kubectl apply -f file.yaml               # create or update
kubectl rollout status deployment/<name> # watch rollout
kubectl rollout undo deployment/<name>   # rollback
kubectl scale deployment/<name> --replicas=3

# ── DEBUGGING ─────────────────────────────────────────────────
kubectl describe pod <pod> -n <ns> | grep -A10 "Events:"
kubectl get events -n <ns> --sort-by='.lastTimestamp'
kubectl top pods -n <ns>                 # CPU/memory usage

# ── DISTROLESS CONTAINERS (no shell) ──────────────────────────
kubectl debug -n <ns> <pod> \
  --image=busybox:1.36 \
  --target=<container> \
  -it -- sh

# ── CLEANUP ───────────────────────────────────────────────────
kubectl delete ns <name>                 # delete namespace + all contents
```

**kubectl cheat sheet:** https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## 20. The Mental Model — Everything in One Picture

### The reconciliation loop (the core idea)
```
You write YAML (desired state)
           ↓
    kubectl apply -f
           ↓
    Kubernetes API Server stores in etcd
           ↓
    Controllers detect gap between desired and actual
           ↓
    Scheduler assigns pod to a node
           ↓
    kubelet on that node starts the container
           ↓
    Readiness probe passes → Service adds pod to Endpoints
           ↓
    Traffic flows to the pod
           ↓
    Pod crashes → controller detects it → creates a new pod
           ↓
    Loop runs forever — Kubernetes never stops watching
```

### How the objects fit together
```
Namespace
  └── Deployment
        └── ReplicaSet
              ├── Pod (init containers → main container + sidecars)
              │     ├── Volume (emptyDir, PVC)
              │     └── ServiceAccount → RBAC Role → IRSA → AWS IAM
              ├── Pod
              └── Pod
                    ↑
              ConfigMap / Secret → injected as env vars or volume files
                    ↑
              HPA watches CPU → adjusts ReplicaSet replica count
                    ↑
              PDB limits evictions → protects during node drains

  └── Service (ClusterIP)
        └── Endpoints ← updated when pod readiness changes
              └── kube-proxy programs iptables rules on every node

  └── StatefulSet
        ├── Pod-0 → PVC webroot-0 → PV → EBS volume
        ├── Pod-1 → PVC webroot-1 → PV → EBS volume
        └── Pod-2 → PVC webroot-2 → PV → EBS volume
              ↑
        Headless Service → DNS: pod-0.svc.ns.svc.cluster.local

  └── NetworkPolicy (default-deny + explicit allow)
        └── enforced by CNI plugin (Flannel / Calico / VPC CNI)
```

### The most important things to remember

1. **Kubernetes is always watching.** If reality drifts from desired state, it corrects automatically. This is the reconciliation loop.

2. **Pods are disposable.** Never depend on a pod's identity, IP, or local storage. Build apps to be stateless, or use StatefulSets + PVCs for state.

3. **Namespaces are not security boundaries.** Without NetworkPolicies, every pod can reach every other pod. Add default-deny policies to namespaces that need isolation.

4. **Readiness gates traffic. Liveness restarts containers.** These are different. A failing readiness probe removes the pod from load balancing. A failing liveness probe kills and restarts it.

5. **Always set resource requests.** The scheduler needs them to place pods correctly. The HPA needs them to calculate utilisation. Without them, scheduling becomes unpredictable.

6. **ConfigMaps and native Secrets are not encrypted.** For production secrets, use AWS Secrets Manager + Secrets Store CSI Driver on EKS.

7. **Init containers prevent CrashLoopBackOff.** Use them to gate the main container behind dependency checks and setup tasks.

8. **DNS short names resolve to the current namespace.** Use FQDNs for cross-namespace service references.

9. **PVCs outlive pods.** Deleting a pod does not delete its PVC. The data is preserved and reattached when the pod is recreated.

10. **`kubectl describe` + Events is your first debugging tool.** Almost every Kubernetes problem leaves a clue in the Events section.
