# Progress Log

> Format per session: date · lab(s) worked · skills updated · blockers · next action
>
> **Current status (2026-06-16): SYSTEM SCAFFOLDED — no labs executed yet.**  
> All 10 labs are designed and ready. No cluster has been provisioned. No kubectl commands have been run. All skill levels in `skills_matrix.md` are 0 and must stay 0 until actual hands-on work is done.

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

## 2026-06-19 — KodeKloud catch-up: ReplicaSets + Deployments partial

**Lab:** none  
**Time spent:** not logged  
**Cluster:** none used for repo labs today

**What was done:**
- Continued KodeKloud "Kubernetes for the Absolute Beginners - Hands-on Tutorial"
- Completed lessons: Replication Controllers and ReplicaSets, Demo - ReplicaSets, Labs: Replica Sets, Lab Solution, Deployments, Demo: Deployments
- Course progress now at 18/57 lessons overall; current module at 11/17 lessons
- Updated `sources/kodekloud/notes/k8s-beginners.md` with ReplicaSets and Deployments notes during study

**Blocker / decision:**
- Stopping for the day due to fatigue; do not continue into more hands-on work tonight

**Skills updated:** none (theory progressing, but no repo lab closed yet)

**Next action:**
- Resume KodeKloud at `Labs: Deployments`
- Then complete: Lab Solution → Deployments Update and Rollback → Demo → Practice Test
- Then continue Resource Limits, Self-Healing, Rolling Updates, and Services
- Then return to `labs/lab-03-production-deployments` and finish the remaining failure scenarios and validation checklist

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

<!-- TEMPLATE — copy this block for each session
## YYYY-MM-DD — [Lab title]

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
