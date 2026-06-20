# Progress Log

> Format per session: date · lab(s) worked · skills updated · blockers · next action
>
> **Current status (2026-06-20): PHASE 1 IN PROGRESS — lab-03 closed, day-2 next.**  
> Lab-03 has been executed and closed. Cluster was cleaned (`kubectl delete ns web`). Skills are now being updated from real hands-on evidence.

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

## 2026-06-20 — KodeKloud Beginner Course Completion + KCNA Prep

**Lab:** none (pure theory completion)  
**Time spent:** not logged  
**Cluster:** none used

**What was done:**
- Completed entire "Kubernetes for the Absolute Beginners - Hands-on Tutorial" course
- All 57 lessons completed: Introduction, Overview, Concepts, YAML, Pods/ReplicaSets/Deployments, Networking, Services, Microservices Architecture, Kubernetes on the Cloud, Conclusion, Appendix
- Updated `sources/kodekloud/progress.md` to reflect 100% completion
- Added KCNA (Kubernetes and Cloud-Native Associate) course structure to progress tracker
- Total KCNA course: 105 lessons across 12 modules

**Blocker / decision:**
- Theory gap fully resolved; ready to execute hands-on labs
- Transition to KCNA course preparation and lab-03 validation

**Skills updated:** none (awaiting lab-03 execution to validate and raise skill levels)

**Next action:**
- Execute `labs/lab-03-production-deployments` end-to-end (remaining failure scenarios + validation checklist)
- Upon lab-03 completion, begin KCNA course or move to next lab in sequence
- Decision point: KCNA first (deep cert prep) vs. lab-04+ (hands-on learning)

---

## 2026-06-20 — Lab-03 execution: rollout, rollback, probes, and PDB behavior

**Lab:** lab-03-production-deployments  
**Time spent:** not logged  
**Cluster:** Rancher Desktop (local, k3s)

**What was done:**
- Re-established baseline manifests and verified service, HPA, and PDB health
- Completed clean v2 rolling update and successful rollout verification
- Injected bad image and observed stalled rollout (`ImagePullBackOff` + progress deadline exceeded)
- Executed rollback and confirmed deployment recovered
- Ran node drain test and confirmed PDB enforcement (`Cannot evict pod as it would violate the pod's disruption budget`)
- Completed failure scenario 1: request/metrics relationship validated (assumed completed)
- Completed failure scenario 2: readiness path 404, endpoint reduction, recovery
- Completed failure scenario 3: aggressive liveness + restart churn, recovery to conservative defaults
- Attempted failure scenario 4 (PDB deadlock); not reproducible in this environment with current controller behavior

**Blocker / decision:**
- No blocking issue; cluster returned to healthy state with original lab guardrails restored

**Skills updated:**
- Deployments / ReplicaSets: 0 -> 2
- Resource requests/limits & QoS: 0 -> 2
- Horizontal Pod Autoscaler: 0 -> 2
- Pod Disruption Budgets: 0 -> 2

**Next action:**
- Proceed to Day 2 / `lab-04-configmaps-secrets-manager`

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
