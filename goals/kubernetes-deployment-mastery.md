# Kubernetes Deployment Mastery Objective

**Status:** Active  
**Priority:** Medium  
**Review Date:** 2 Jul 2026  
**End Date:** 31 Dec 2025  

---

## Objective Summary

Progress on Kubernetes know-how: Work more on issues, deployments, and investigations on Kubernetes. This goes without saying — would be day to day job and need to excel eventually on this. In parallel with this, we have to document key tasks around it.

---

## Task Breakdown (2/7 complete)

### 1. ✅ Core Concepts: Pods, Services, Deployments, Namespaces, ConfigMaps, Replication

**Status:** COMPLETED  
**Completion Date:** 2026-06-20  
**Source:** Kubernetes for the Absolute Beginners - Hands-on Tutorial (KodeKloud)  
**Details:**
- Pods with YAML
- ReplicaSets and Replication Controllers
- Deployments with rolling updates and rollbacks
- Services (NodePort, ClusterIP, LoadBalancer)
- Namespaces
- ConfigMaps overview

**Evidence:** [sources/kodekloud/progress.md](sources/kodekloud/progress.md) — 57/57 lessons completed

---

### 2. ✅ Containerization: Docker, Container Images, Container Registries

**Status:** COMPLETED  
**Completion Date:** 2026-07-02  
**Source:** KCNA - Kubernetes Fundamentals module  
**Linked Labs:** N/A (theory-only)  
**Progress:** 9/9 lessons (100%)  
**Key Topics:**
- What are Containers?
- Demo - Docker
- Container Orchestration
- Kubernetes Architecture
- Runtime - CRI
- Docker vs ContainerD
- Quiz - Kubernetes Fundamentals ✅
- Notes available at KodeKloud Notes ✅
- A Note for this Course ✅

**Evidence:** [sources/kodekloud/notes/kcna.md](sources/kodekloud/notes/kcna.md) — Kubernetes Fundamentals module completed with full notes

---

### 3. [ ] Networking: Services, Service Discovery, Ingress Controllers, Network Policies

**Status:** NOT STARTED  
**Target Date:** 2026-07-25  
**Source:** KCNA - Container Orchestration (Networking) module + hands-on labs  
**Linked Labs:** lab-02 (EKS Networking & Ingress), lab-07 (Service Discovery & Network Policies), lab-09 (Ingress ALB Deep Dive)  
**Progress:** 0/6 lessons  
**Key Topics:**
- Cluster Networking
- Pod Networking
- CNI in Kubernetes
- DNS in Kubernetes
- Ingress
- Quiz - Networking

**Dependency:** Must complete Task 1 (✅ done) and begin lab-02

---

### 4. [ ] Configuration Management: Helm, Templating, Package Management

**Status:** NOT STARTED  
**Target Date:** 2026-08-10  
**Source:** KodeKloud "Helm for Beginners" course  
**Linked Labs:** lab-09 (Ingress ALB), lab-10 (Karpenter Spot)  
**Progress:** 0/course  
**Key Topics:**
- Helm basics
- Charts and templates
- Package management
- Helm workflows

**Dependency:** Complete Task 1 + networking fundamentals

---

### 5. [ ] Troubleshooting & Debugging: kubectl Commands, Pod Logs, Events, Descriptions

**Status:** IN PROGRESS  
**Target Date:** 2026-07-20  
**Source:** Hands-on labs (failure scenarios and validation checklists)  
**Linked Labs:** lab-03 (Production Deployments - remaining scenarios), lab-04, lab-05, lab-06  
**Progress:** 4/6 labs (lab-03, lab-04, lab-07, lab-06, lab-05 executed)  
**Key Topics:**
- kubectl explain command
- kubectl apply command
- Kubernetes Namespaces
- Pod logs (kubectl logs)
- Events and descriptions (kubectl describe)
- Failure scenario investigation
- Root cause analysis

**Latest Evidence (2026-06-25):**
- lab-03 core flow completed (rollout, bad-image rollback, PDB drain protection)
- Failure scenario 1 (requests/HPA relation) completed
- Failure scenario 2 (readiness 404) completed and recovered
- Failure scenario 3 (aggressive liveness) completed and recovered
- lab-04 Part A/B completed: immutable ConfigMap behavior validated, native Secret decode/injection validated
- AWS sandbox blocker diagnosed for Part C prerequisites (`iam:PassRole` denied by Organizations policy); Part C intentionally deferred
- lab-07 completed: DNS namespace scoping, cross-namespace reachability, NetworkPolicy enforcement; Flannel DNAT port bug found and fixed
- lab-06 completed: init container sequencing (chained dependency gate), sidecar pattern (shared emptyDir log volume), distroless debugging via `kubectl debug` ephemeral containers
- lab-05 completed: StatefulSet ordered startup/shutdown, stable DNS via headless Service, PVC persistence across pod deletion and scaledown; liveness probe crash loop diagnosed and fixed

**Next Action:** Day 6 — Ingress deep dive (lab-09, requires EKS cluster)

---

### 6. [ ] Best Practices: Resource Management, Pod Design Patterns, Security Best Practices

**Status:** NOT STARTED  
**Target Date:** 2026-09-15  
**Source:** KCNA (Cloud Native Architecture, Observability, Security) + hands-on labs  
**Linked Labs:** lab-04 (ConfigMaps & Secrets), lab-05 (StatefulSet & EBS), lab-06 (Init & Sidecar), lab-08 (Pod Security & Kyverno)  
**Progress:** 0/labs  
**Key Topics:**
- Resource limits and requests
- Pod disruption budgets (PDB)
- Health checks (liveness, readiness)
- Stateful applications
- Security best practices
- Pod security policies

**Dependency:** Complete Task 1 + Task 5

---

### 7. [ ] Training Completion: KCNA Certification Readiness

**Status:** IN PROGRESS  
**Target Date:** 2026-08-31  
**Source:** KCNA full course (115 lessons) + Mock exams  
**Progress:** 9/115 lessons  
**Key Modules:**
- Introduction (3)
- Kubernetes Fundamentals (9)
- Kubernetes Resources (15)
- Scheduling (12)
- Container Orchestration - Security (13)
- Container Orchestration - Networking (6)
- Container Orchestration - Storage (10)
- Cloud Native Architecture (9)
- Cloud Native Observability (12)
- Cloud Native Application Delivery (9)
- Mock Exams (5)
- Conclusion (2)

**Next Action:** Start KCNA course after lab-03 completion

---

## Progress Summary

| Task | Status | Completion % | Target Date |
|------|--------|--------------|-------------|
| 1. Core Concepts | ✅ COMPLETED | 100% | 2026-06-20 |
| 2. Containerization | IN PROGRESS | 67% | 2026-07-10 |
| 3. Networking | IN PROGRESS | 20% | 2026-07-25 |
| 4. Config Management | NOT STARTED | 0% | 2026-08-10 |
| 5. Troubleshooting | IN PROGRESS | 50% | 2026-07-20 |
| 6. Best Practices | NOT STARTED | 0% | 2026-09-15 |
| 7. Training (KCNA) | IN PROGRESS | 8% | 2026-08-31 |

**Overall Progress:** 1/7 tasks completed (14%) — 3 additional tasks actively in progress

---

## Success Criteria

Each task is considered complete when:
1. All theory lessons in the source course are finished (✅ marked)
2. Related hands-on labs have passing validation checklists
3. Failure scenarios have been investigated and documented
4. Notes have been taken and are available in the repo

---

## Update Log

**2026-06-20 (consolidated):**
- Created objective file
- Marked Task 1 (Core Concepts) as COMPLETED
- Linked all tasks to KodeKloud courses and hands-on labs
- Set target dates for remaining 6 tasks
- Scheduled lab-03 execution as next action
- Executed lab-03 end-to-end core flow and validated rollout/rollback/PDB behavior
- Completed failure scenarios 2 and 3 with full recovery
- Updated troubleshooting task progress to 1/6 labs

**2026-06-25:**
- Task 3 (Networking) opened: lab-07 executed, DNS scoping and NetworkPolicy enforcement validated
- Task 5 (Troubleshooting) updated: 1/6 → 3/6 labs (lab-07 + lab-06 added)
- Task 3 progress: 0% → 20% (lab-07 done; KCNA Networking module + lab-02 + lab-09 remaining)
- Task 5 progress: 17% → 50% (lab-03, lab-04, lab-07, lab-06 evidence on record)
- New tool documented: `kubectl debug` ephemeral containers for distroless pod debugging
- Started KCNA course
- Completed Introduction module (3/3)
- Progressed Kubernetes Fundamentals to 6/9 lessons (67%)
- Updated Task 2 to IN PROGRESS and Task 7 to IN PROGRESS
