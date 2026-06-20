# Progress Log

> Format per session: date · lab(s) worked · skills updated · blockers · next action
> Presentation rule: keep one consolidated entry per date and append same-day updates in execution order.
>
> **Current status (2026-06-20): PHASE 1 IN PROGRESS — Day 2 complete for local scope; Lab-04 Part C deferred due to sandbox IAM policy.**  
> Lab-03 is closed. Lab-04 Part A and B are validated on local cluster. Part C is deferred until an AWS account/sandbox with `iam:PassRole` is available.

---

## 2026-06-16 — System Initialization (SCAFFOLDING ONLY — no training done)

**This is NOT a training session. No kubectl, no Terraform, no cluster.**

**Setup actions (Copilot-assisted):**
- Initialized workspace structure (goals/, roadmap/, labs/, progress/, notes/, sources/, mappings/)
- Created `skills_matrix.md` with starting baseline
- Cloned Nigel Poulton repos into `sources/nigel_poulton/`
- Analyzed repos → generated `mappings/k8s_learning_map.md`
- Scaffolded labs 01–10 (Terraform + Kubernetes manifests, failure scenarios, validation checklists)
- Created Phase 1 roadmap (`roadmap/eks-2-week-focused.md`) and Phase 2 roadmap (`roadmap/eks-4-week-roadmap.md`)
- Initialized `sources/kodekloud/` structure (courses.md, progress.md, notes stubs)
- Reviewed and improved all labs; upgraded lab-06 to production-grade

**Starting baseline (unchanged from initial state):**
- AWS: 3 | Terraform: 3 | CI/CD: 3
- Kubernetes/EKS: 0 — not started

**Next action:** Start Phase 1, Day 1 — provision lab-01 EKS cluster, then run lab-03 Deployments

---

## 2026-06-17 — Phase 1 Day 1: Cluster setup + Lab 03 partial (PAUSED — theory gap)

**Lab:** lab-03-production-deployments (partial)  
**Time spent:** ~1h  
**Cluster:** Rancher Desktop (local, k3s, single node, v1.32.4)

**What was done:**
- Set up Rancher Desktop as local training cluster
- Secured kubeconfig: added aliases to ~/.zshrc to prevent accidentally hitting work/prod clusters (`kuse-train`, `kuse-prod`, `k-train`, `kctx`)
- Documented alias reference in workflow.md
- Applied lab-03 manifests: namespace, deployment-v1, service, pdb, hpa
- Hit and diagnosed first real failure: pods stuck `Pending` due to `topologySpreadConstraints` requiring `topology.kubernetes.io/zone` label — missing on local node
- Fix applied: `kubectl label node lima-rancher-desktop topology.kubernetes.io/zone=local-az-1`
- All 3 pods reached `Running`, HPA reading CPU (2%/60%), PDB showing `ALLOWED DISRUPTIONS: 1`
- Observed Pod Security Admission warning on deploy (baseline enforced, restricted warned — not blocked)
- Paused before triggering Failure Scenario 2 (readinessProbe 404)

**Blocker / decision:**
- Theory gap identified. Do not understand readiness vs liveness probes, rolling update mechanics, or requests/limits well enough to diagnose failure scenarios meaningfully
- Decision: study KodeKloud "Kubernetes for the Absolute Beginners" before continuing

**Skills updated:** none (no skill raised until theory + failure scenarios fully completed)

**Next action:**
- KodeKloud → "Kubernetes Concepts — Pods, Re..." module — resume at lesson 6 (ReplicaSets), 29% done
- Complete remaining lessons: ReplicaSets → Deployments → Resource Limits → Self-Healing → Rolling Updates
- Then: Services module
- Then: Return to Lab 03, trigger Failure Scenario 2 (readinessProbe patch already prepared)
- Then complete all validation checklist items and remaining failure scenarios

---

## 2026-06-19 — KodeKloud catch-up: 63% complete (36/57)

**Lab:** none  
**Time spent:** not logged  
**Cluster:** none used for repo labs today

**What was done:**
- Continued KodeKloud "Kubernetes for the Absolute Beginners - Hands-on Tutorial"
- Confirmed completed modules: Introduction, Kubernetes Overview, Kubernetes Concepts, YAML Introduction, Kubernetes Concepts - Pods/ReplicaSets/Deployments, Networking in Kubernetes
- Started Services module (1 of 6 lessons complete)
- Course progress now at 36/57 lessons (63%)
- Updated KodeKloud tracking files in repo to match current course UI state

**Blocker / decision:**
- Stopping for the day after progress update; resume with Services next session

**Skills updated:** none (theory progressing, but no repo lab closed yet)

**Next action:**
- Finish Services module (remaining 5 lessons)
- Continue with Microservices Architecture and Kubernetes on the Cloud
- Then return to `labs/lab-03-production-deployments` and finish the remaining failure scenarios and validation checklist

---

## 2026-06-20 — Consolidated Daily Progress (theory + labs + session restarts)

**Labs / tracks worked:**
- KodeKloud Beginners (course completion)
- lab-03-production-deployments (completed)
- lab-04-configmaps-secrets-manager (Part A/B completed, Part C deferred)
- KCNA theory (started; Fundamentals in progress)

**Time spent:** not logged  
**Clusters used:** Rancher Desktop (local, k3s) + KodeKloud AWS sandbox (Terraform preflight)

**Execution timeline (in order):**
1. Completed the full KodeKloud Beginners course (57/57 lessons).
2. Executed lab-03 end-to-end:
   - rollout/rollback verified
   - bad-image failure diagnosed and recovered
   - readiness/liveness failure scenarios completed and recovered
   - PDB behavior verified under drain
3. Executed lab-04 Part A/B:
   - ConfigMap env and file injection validated
   - immutable ConfigMap rejection validated
   - native Secret decode/injection validated
4. Attempted AWS-backed prerequisites for lab-04 Part C:
   - blocked by sandbox Organizations policy (`iam:PassRole`)
   - Terraform resources cleaned up and Part C deferred
5. Started KCNA:
   - Introduction completed (3/3)
   - Kubernetes Fundamentals progressed to 6/9 lessons (67%)
   - notes/progress trackers updated

**Blockers / decisions:**
- AWS sandbox restrictions prevent EKS provisioning and lab-04 Part C execution (`iam:PassRole` denied).
- Decision: treat Day 2 as complete for local scope, defer AWS-only Part C, continue theory/local progression.

**Skills updated:**
- Deployments / ReplicaSets: 0 -> 2
- Resource requests/limits & QoS: 0 -> 2
- Horizontal Pod Autoscaler: 0 -> 2
- Pod Disruption Budgets: 0 -> 2
- ConfigMaps & Secrets management: 0 -> 2

**Next action:**
- Continue KCNA Kubernetes Fundamentals with this exact first action:
  - Open KCNA module and complete `Quiz - Kubernetes Fundamentals`

---

<!-- TEMPLATE — copy this block for each session
## YYYY-MM-DD — [Lab title]

If an entry for this date already exists, append updates to that same date block instead of creating a second block.

**Lab completed:** lab-0X
**Time spent:** Xh
**Skills updated in skills_matrix.md:**
  - Skill name: 0 → 2
**Failure scenarios hit:**
  - Failure N: [what happened, how fixed]
**Blockers:**
  - [anything that blocked progress]
**Next action:**
  - [next lab or topic]
-->
