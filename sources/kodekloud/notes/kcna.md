# Kubernetes and Cloud-Native Associate (KCNA) — Notes

> Course: Kubernetes and Cloud-Native Associate (KCNA) (KodeKloud)
> Status: 🔄 IN PROGRESS — 8% (9/115 lessons) as of 2026-06-20
> Previous: Kubernetes for the Absolute Beginners (completed 2026-06-20)
> Certification Level: Associate (intermediate)

---

## Course Structure Overview

The KCNA course covers 13 modules with 115 total lessons:

1. **Introduction** (3 lessons)
2. **Kubernetes Fundamentals** (9 lessons)
3. **Kubernetes Resources** (15 lessons)
4. **Scheduling** (12 lessons)
5. **Container Orchestration - Security** (13 lessons)
6. **Container Orchestration - Networking** (6 lessons)
7. **Container Orchestration - Storage** (10 lessons)
8. **Cloud Native Architecture** (9 lessons)
9. **Cloud Native Observability** (12 lessons)
10. **Cloud Native Application Delivery** (9 lessons)
11. **Mock Exams** (5 lessons)
12. **Conclusion** (2 lessons)

---

### Introduction (completed)

- Course Introduction
- Discount and Certification Details
- How to Reach Out to KodeKloud

### Kubernetes Fundamentals (✅ completed 2026-07-02)

- Completed lessons:
	- What are Containers?
	- Demo - Docker
	- Container Orchestration
	- Kubernetes Architecture
	- Runtime - CRI
	- Docker vs ContainerD
	- Quiz - Kubernetes Fundamentals ✅
	- Notes available at KodeKloud Notes ✅
	- A Note for this Course ✅

Key notes:
- Containers package app + dependencies with process isolation and share host kernel.
- Orchestration solves scaling, healing, rollout, and placement across many containers.
- Kubernetes architecture: control plane manages desired state; worker nodes run workloads.
- CRI is the contract between kubelet and container runtime.
- Docker is a full platform; containerd is runtime-focused and commonly used by Kubernetes.



### Kubernetes Resources (in progress: 9/15 as of 2026-07-02)

- Completed lessons:
	- Pods (09:04) — basic Pod spec, labels, selectors
	- Demo - Pods (04:22) — kubectl run, pod creation walkthrough
	- Pods with YAML (06:49) — manifest structure, apiVersion, kind, metadata, spec
	- Demo - Pods with YAML (06:09) — creating Pods from manifests, kubectl apply
	- ReplicaSets (15:43) — selector matching, desired state, self-healing
	- Demo - ReplicaSets (13:44) — creating RS, scaling with kubectl scale
	- Deployments (04:21) — abstraction over RS, rolling updates, history
	- Demo - Deployments (04:26) — kubectl create deployment, editing and observing rollouts
	- Deployments - Rolling Updates and Rollbacks (06:32) — maxSurge, maxUnavailable, revision history, kubectl rollout

- Pending in this module (6 remaining):
	- Demo - Deployments - Rolling Updates and Rollbacks (14:35)
	- Imperative vs Declarative (12:49)
	- Kubernetes Explain Command
	- Namespaces
	- Services
	- ConfigMaps
	- Secrets
	- PersistentVolumes
	- StatefulSets
	- DaemonSets

Key takeaways (60% complete):
- Pod is atomic unit; ReplicaSet ensures replicas; Deployment manages rollouts
- Labels/selectors are fundamental to Kubernetes coupling and grouping
- Rolling update strategy (maxSurge/maxUnavailable) controls blast radius and availability
- All concepts directly map to repo labs (lab-03, lab-04, lab-05)

ReplicaSet can handle pods not created by the replicaset while this is not the case for replication controler.
How does the replicaset know what pods to monitor ? --> Pod is created with a specific label and replicaset will have a selector on matchlabels.
A ReplicaSet in Kubernetes ensures that a specified number of identical Pod replicas are running at all times.
For example, if you define replicas: 3, Kubernetes will try to keep 3 Pods running. If one Pod fails or is deleted, the ReplicaSet creates a replacement.

Simple rule --   Deployment = ReplicaSet + rolling updates + rollback support

### Scheduling

### Container Orchestration - Security

### Container Orchestration - Networking

### Container Orchestration - Storage

### Cloud Native Architecture

### Cloud Native Observability

### Cloud Native Application Delivery

### Mock Exams

### Conclusion
