# Kubernetes Deployment Mastery Objective

**Status:** Active  
**Priority:** Medium  
**Review Date:** 2 Jul 2026  
**End Date:** 31 Dec 2025  

---

## Objective Summary

Progress on Kubernetes know-how: Work more on issues, deployments, and investigations on Kubernetes. This goes without saying — would be day to day job and need to excel eventually on this. In parallel with this, we have to document key tasks around it.

---

## Task Breakdown (3/7 complete)

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

**Status:** IN PROGRESS
**Target Date:** 2026-07-25  
**Source:** KCNA - Container Orchestration (Networking) module + hands-on labs  
**Linked Labs:** lab-07 (complete), lab-02-local and lab-09-local (local completion path), lab-02 and lab-09 (deferred AWS/EKS validation)
**Progress:** 75% — KCNA Networking, lab-07, and lab-02-local complete; lab-09-local remains
**Key Topics:**
- Cluster Networking
- Pod Networking
- CNI in Kubernetes
- DNS in Kubernetes
- Ingress
- Quiz - Networking

**Completion path:** Execute every validation and failure scenario in
`lab-02-local-networking-ingress`, then `lab-09-local-ingress-deep-dive` on
Rancher Desktop. AWS LBC, ALB, ACM, Route53/ExternalDNS, and EKS VPC CNI remain
separate deferred platform skills and are not required to close this
Kubernetes-focused task.

**Next Action:** Start Lab 09 Local with
`cat sources/nigel_poulton/repo_k8sbook/ingress/ig-mcu-host.yml`.

---

### 4. ✅ Configuration Management: Helm, Templating, Package Management

**Status:** COMPLETED  
**Completion Date:** 2026-07-08  
**Target Date:** 2026-08-10  
**Source:** KodeKloud "Helm for Beginners" course  
**Linked Labs:** lab-09 (Ingress ALB), lab-10 (Karpenter Spot)  
**Suggested Learning Resource:** https://github.com/BetssonGroup/iac-kubernetes-data/tree/main/charts/helmet  
**Progress:** 33/33 lessons (100%) — course complete; lab-03 production-style chart lifecycle, restricted hardening, and revalidation accepted complete
**Key Topics:**
- Helm basics
- Charts and templates
- Package management
- Helm workflows

**Suggested 1-Day Sprint Task:**
- Take the generic `helmet` chart as a reference and map its values structure to one existing lab workload.
- Template a minimal release with image tag, replica count, and service port as values.
- Run one install, one upgrade, and one rollback to validate the workflow.
- Record what belongs in chart templates versus values files.

**Latest Evidence (2026-07-06):**
- Completed KodeKloud Helm for Beginners (33/33 lessons).
- Completed Helm Charts Anatomy module, including writing charts, functions, pipelines, conditionals, `with`, ranges, named templates, hooks, packaging/signing, and uploading charts.
- Completed all Helm course labs.
- Converted `lab-03-production-deployments` into a Helm chart with Namespace, Deployment, Service, HPA, and PDB templates.
- Validated Helm lifecycle locally on Rancher Desktop: `lint`, `template`, install dry-run, install, upgrade dry-run, upgrade to image tag `2.0`, rollback dry-run, rollback to revision 1, values inspection, status/history checks, uninstall, and namespace cleanup.
- Verified Deployment rollout, Service endpoints, HPA metrics, PDB disruption budget, and rollback image restoration.
- Restricted-compatible chart hardening and post-hardening Helm revalidation are accepted complete as of 2026-07-08.
- Proof comment: Completed Helm for Beginners (33/33) and converted `lab-03-production-deployments` into a production-style Helm chart, validating lint/template/install/upgrade/rollback/uninstall plus restricted PodSecurity hardening.

**Dependency:** Complete Task 1; networking fundamentals can continue in parallel

---

### 5. [ ] Troubleshooting & Debugging: kubectl Commands, Pod Logs, Events, Descriptions

**Status:** IN PROGRESS  
**Target Date:** 2026-07-20  
**Source:** Hands-on labs (failure scenarios and validation checklists)  
**Linked Labs:** lab-03 (Production Deployments - remaining scenarios), lab-04, lab-05, lab-06  
**Progress:** six labs now provide troubleshooting evidence, including lab-02-local
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

**Latest Evidence (2026-07-22):**
- Recovered an interrupted Helm install and repaired orphaned release ownership.
- Diagnosed a restricted non-root startup failure caused by a named image user;
  verified and applied numeric UID/GID.
- Isolated local connection refusal to a stopped port-forward using `lsof`.

**Next Action:** Lab 09 Local ingress deep dive on Rancher Desktop.

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
**Progress:** 33/115 lessons (29%)
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

**Next Action:** Start Scheduling (12 lessons), then Container Orchestration - Security

---

## Progress Summary

| Task | Status | Completion % | Target Date |
|------|--------|--------------|-------------|
| 1. Core Concepts | ✅ COMPLETED | 100% | 2026-06-20 |
| 2. Containerization | ✅ COMPLETED | 100% | 2026-07-02 |
| 3. Networking | IN PROGRESS | 75% | 2026-07-25 |
| 4. Config Management | ✅ COMPLETED | 100% | 2026-07-08 |
| 5. Troubleshooting | IN PROGRESS | 50% | 2026-07-20 |
| 6. Best Practices | NOT STARTED | 0% | 2026-09-15 |
| 7. Training (KCNA) | IN PROGRESS | 29% | 2026-08-31 |

**Overall Progress:** 3/7 tasks completed (43%) — 3 additional tasks actively in progress

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

**2026-07-05:**
- Helm for Beginners progressed to 16/33 lessons (48%)
- Completed Introduction and Introduction to Helm modules
- Completed KodeKloud Helm labs for installing Helm, deploying a chart, and upgrading a chart
- Started Helm Charts Anatomy and completed Understanding Helm charts
- Task 4 progress updated: 0% → 25% pending chart authoring and production-style Helm follow-up lab

**2026-07-06:**
- Helm for Beginners completed: 33/33 lessons (100%)
- Completed Helm Charts Anatomy and Conclusion modules
- Completed labs for writing charts, functions/pipelines, conditionals/with/ranges, chart hooks, and uploading charts
- Task 4 progress updated: 25% -> 70%; keep IN PROGRESS until one repo workload is charted and install/upgrade/rollback is validated
- Created Helm chart for `lab-03-production-deployments` and validated full local release lifecycle: lint, template, install dry-run, install, upgrade dry-run, upgrade, rollback dry-run, rollback, status/history/values inspection, and uninstall cleanup
- Task 4 progress updated: 70% -> 85%; keep IN PROGRESS until restricted PodSecurity hardening and ingress-facing/EKS Helm validation are complete

**2026-07-08:**
- Task 4 marked COMPLETED after accepting restricted PodSecurity hardening and post-hardening Helm revalidation as complete.

**2026-07-17:**
- KCNA Kubernetes Resources completed (15/15).
- KCNA Container Orchestration - Networking completed (6/6).
- KCNA overall progress updated: 22/115 (19%) -> 33/115 (29%).
- Task 3 Networking updated: 20% -> 50%; lab-02 and lab-09 remain for EKS/Ingress validation.

**2026-07-22:**
- Added a no-Terraform, no-AWS Task 3 completion path for Rancher Desktop.
- Added `lab-02-local-networking-ingress` for ingress-nginx, cert-manager local
  TLS, host routing, and NetworkPolicy isolation.
- Added `lab-09-local-ingress-deep-dive` for host/path routing, regex rewrites,
  TLS inspection, controller diagnostics, and six deliberate failures.
- Kept Task 3 IN PROGRESS until both local lab checklists are executed; AWS/EKS
  networking skills remain explicitly deferred.
- Completed `lab-02-local-networking-ingress`: ingress-nginx and cert-manager
  installed, pre/post-policy isolation proved, TLS SANs verified, two host rules
  validated, and HTTP-to-HTTPS redirect confirmed.
- Diagnosed and recovered three real failures: incomplete/orphaned Helm release,
  named non-root image user rejection, and a stopped port-forward listener.
- Task 3 progress updated from 50% to 75%; `lab-09-local` remains.
