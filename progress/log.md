# Progress Log

> Format per session: date · lab(s) worked · skills updated · blockers · next action
> Presentation rule: keep one consolidated entry per date and append same-day updates in execution order.
>
> **Current status (2026-07-06): PHASE 1 IN PROGRESS — Helm course complete; lab-03 Helm chart follow-up validated locally.**
> Lab-03 closed. Lab-04 Part A/B closed (Part C deferred). Lab-07 closed. Lab-06 closed (CloudWatch deferred — no IRSA). Lab-05 closed (EBS-specific features noted; local-path used). Day 6 next (Ingress deep dive — requires EKS).

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

## 2026-06-25 — Phase 1 Day 3 + Day 4: Service Discovery + NetworkPolicies + Init Containers + Sidecar

**Lab:** lab-07-service-discovery-netpol (completed)  
**Time spent:** ~1h  
**Cluster:** Rancher Desktop (local, k3s)

**What was done:**
- Applied namespaces (dev, prod, shared), sd-deployments, jump pods
- Phase 2: proved cross-namespace reachability before any NetworkPolicy (`dev/jump → ent.prod` returned `text-prod`)
- Proved DNS namespace scoping: short name `ent` from dev resolves to `ent.dev.svc.cluster.local`, not prod
- Applied all 6 NetworkPolicies (default-deny-all + explicit allow in each namespace)
- Verified `dev → prod` blocked (connection refused — Flannel sends TCP RST instead of silent drop)
- Verified `prod → dev` blocked
- Verified `dev → shared-api` allowed after policy fix

**Bug found and fixed in lab manifest:**
- `network-policies.yaml` egress rule to `shared` namespace used `port: 8080` (Service port)
- Flannel evaluates NetworkPolicy egress **after** kube-proxy DNAT, so the packet's destination port is already `80` (container port) by evaluation time
- Fix: changed egress port to `80` in both `allow-intra-dev` and `allow-intra-prod`
- Lesson: Calico/Cilium evaluate before DNAT (use Service port); Flannel/kube-proxy iptables evaluate after DNAT (use container port)

**Validation checklist:** all 6 items passed

**Skills updated:**
- Services (ClusterIP, NodePort, LB): 1 → 2
- Network Policies: 0 → 2

**Next action:** Phase 1 Day 4 — Init Containers + Sidecar (lab-06)

---

### Lab-06 — Init Containers + Sidecar (appended same session)

**Lab:** lab-06-init-sidecar (Part A complete; Part B local-only — CloudWatch deferred)  
**Cluster:** Rancher Desktop (local, k3s)

**What was done:**
- Part A: Applied init-demo-ns + init-pod without postgres Service — pod stuck `Init:0/2`
- Read live logs from `init-wait-db`: confirmed DNS loop (`NXDOMAIN` every 2s)
- Applied `postgres-stub-svc.yaml` — init-1 unblocked, progressed through `Init:1/2` → `PodInitializing` → `Running`
- Read logs from all three containers in sequence: init-wait-db → init-migrate → app
- Part B: Applied `sidecar-fluent-bit.yaml` — `sidecar-pod` reached `2/2 Running`
- Generated 5 JSON log entries via `kubectl exec` into `ctr-app` shared emptyDir volume
- Verified app container wrote to `/var/log/app/app.log`
- Fluent Bit logs showed heartbeat entries (app auto-writing) + AWS credential failures at output stage only — input/parse stages confirmed working
- Attempted Failure Scenario 4 (kill Fluent Bit) — discovered image is fully distroless (no shell, no kill)
- Learned `kubectl debug --target` with ephemeral containers as the correct tool for distroless debugging

**Deferred:** CloudWatch log delivery (Part B output stage) — requires IRSA on EKS

**Skills updated:**
- Pod lifecycle & scheduling: 1 → 2
- Fluent Bit log shipping to CloudWatch: 0 → 1

**New tool learned:** `kubectl debug -it --image=busybox --target=<container>` — ephemeral container for distroless pod debugging

**Next action:** Phase 1 Day 5 — StatefulSets + EBS (lab-05)

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

---

## 2026-07-02 — KCNA continuation: Kubernetes Fundamentals ✅ complete + Kubernetes Resources (9/15)

**Lab:** none (theory session)
**Cluster:** none
**Course:** Kubernetes and Cloud-Native Associate (KCNA) — progressed from 8% (9/115) to 19% (22/115)

**Completed:**
- ✅ **Kubernetes Fundamentals** (9/9 lessons) — Quiz, Notes, Module Completion
- **Kubernetes Resources** (9/15 lessons — 60% complete)
  - ✅ Pods, Demo - Pods, Pods with YAML, Demo - Pods with YAML
  - ✅ ReplicaSets, Demo - ReplicaSets
  - ✅ Deployments, Demo - Deployments
  - ✅ Deployments - Rolling Updates and Rollbacks

**Key concepts reinforced:** Containers, orchestration, Kubernetes architecture, CRI, Docker vs containerd; Pods → ReplicaSets → Deployments; Rolling updates (maxSurge, maxUnavailable)

**Next action:** Resume Kubernetes Resources (Demo - Deployments - Rolling Updates) → finish all 15 lessons

---

## 2026-07-03 — Pivot planned: Helm for Beginners aligned to Task 4

**Lab:** none (course planning)
**Cluster:** none
**Course:** Helm for Beginners (KodeKloud) — 0/33 lessons

**What changed:**
- Decided to start KodeKloud **Helm for Beginners** now, aligned with goals Task 4: Configuration Management.
- Added course tracking under `sources/kodekloud/progress.md`.
- Added notes file at `sources/kodekloud/notes/helm-for-beginners.md`.
- Updated Task 4 in `goals/kubernetes-deployment-mastery.md` from NOT STARTED to IN PROGRESS.

**Why:**
- Helm is already a planned objective and is safer to progress while the active Kubernetes context is pointed at a production cluster.
- It builds directly toward chart templating, package management, and later lab-09/lab-10 work.

**Next action:** Start Helm for Beginners → Introduction module, lesson 1.

---

## 2026-07-05 — Helm for Beginners: Introduction + Intro to Helm complete

**Lab:** KodeKloud Helm course labs only
**Cluster:** KodeKloud course environment
**Course:** Helm for Beginners (KodeKloud) — 48% complete (16/33 lessons)

**What was done:**
- Completed **Introduction** module (2/2 lessons).
- Completed **Introduction to Helm** module (13/13 lessons), including:
  - Helm installation/configuration
  - Lab: Installing Helm
  - Helm components and charts
  - Working with Helm basics
  - Customizing chart parameters
  - Lab: using Helm to deploy a chart
  - Lifecycle management with Helm
  - Lab: upgrading a Helm chart
  - Course resources and notes
- Started **Helm Charts Anatomy** module.
- Completed first lesson in Helm Charts Anatomy: **Understanding Helm charts**.

**Blockers / decisions:**
- No blocker logged.
- Do not count Helm as production-capable yet; chart authoring is only at early course/anatomy stage.

**Skills updated:**
- Helm chart authoring: 0 -> 1

**Next action:**
- Resume Helm Charts Anatomy at **Writing a Helm chart**.
- After the module is complete, create a production-style Helm follow-up lab for one existing workload with values, templates, install, upgrade, rollback, and failure validation.

---

## 2026-07-06 — Helm for Beginners completed

**Lab:** KodeKloud Helm course labs only
**Cluster:** KodeKloud course environment
**Course:** Helm for Beginners (KodeKloud) — 100% complete (33/33 lessons)

**What was done:**
- Completed **Helm Charts Anatomy** module (17/17 lessons), including:
  - Understanding Helm charts
  - Writing a Helm chart
  - Making sure a chart is working as intended
  - Functions and pipelines
  - Conditionals, `with` blocks, and ranges
  - Named templates
  - Chart hooks
  - Packaging and signing charts
  - Uploading charts
- Completed all Helm Charts Anatomy labs:
  - Writing a Helm chart
  - Using functions and pipelines
  - Conditionals, with blocks, and ranges
  - Chart hooks
  - Uploading charts
- Completed **Conclusion** module (1/1 lesson).

**Blockers / decisions:**
- No blocker logged.
- Helm course theory/labs are complete, but Task 4 should remain **IN PROGRESS** until a repo workload is converted into a production-style chart and validated locally or on EKS.

**Skills updated:**
- Helm chart authoring: 1 -> 2

**Next action:**
- Create a production-style Helm follow-up lab using one existing workload, preferably `lab-03-production-deployments` first because it has Deployment, Service, probes, HPA, and PDB behavior already validated.
- Minimum validation: `helm lint`, `helm template`, `helm install`, values-driven image tag or replica change, `helm upgrade`, `helm rollback`, and notes on what belongs in templates vs values.
- After that, apply Helm to an ingress-facing workload before returning to Day 6 / lab-09 on EKS.

### Helm follow-up lab — lab-03 chart authoring and release lifecycle (appended same day)

**Lab:** `labs/lab-03-production-deployments/chart`  
**Cluster:** Rancher Desktop (local, k3s, context verified: `rancher-desktop`)  
**Release:** `lab03`

**What was done:**
- Created a Helm chart for the existing lab-03 workload:
  - `Chart.yaml`
  - `values.yaml`
  - `templates/_helpers.tpl`
  - `templates/namespace.yaml`
  - `templates/deployment.yaml`
  - `templates/service.yaml`
  - `templates/hpa.yaml`
  - `templates/pdb.yaml`
- Converted lab-03 manifests into reusable templates while preserving:
  - Deployment name `web-app`
  - namespace `web`
  - Service `web-app-svc`
  - HPA `web-app-hpa`
  - PDB `web-app-pdb`
  - probes, resources, rolling update strategy, topology spread, and preStop lifecycle hook
- Added Helm workflow documentation to `labs/lab-03-production-deployments/README.md`.
- Reviewed the chart command-by-command:
  - `Chart.yaml`
  - `values.yaml`
  - helpers
  - Namespace, Service, Deployment, HPA, and PDB templates

**Validation completed:**
- `helm lint ./chart` passed (`0 chart(s) failed`).
- `helm template lab03 ./chart` rendered expected resources.
- `helm install lab03 ./chart --dry-run` passed.
- `helm install lab03 ./chart` completed as revision 1.
- Verified Kubernetes resources:
  - 3 pods `Running`
  - Deployment `3/3`
  - HPA reading CPU (`2%/60%`)
  - PDB allowed disruptions = `1`
  - Service endpoints had all 3 ready pod IPs
- `helm upgrade lab03 ./chart --set image.tag=2.0 --set changeCause="v2 - updated application image via Helm" --dry-run` passed.
- `helm upgrade lab03 ./chart --set image.tag=2.0 --set changeCause="v2 - updated application image via Helm"` completed as revision 2.
- Verified image changed to `nigelpoulton/getting-started-k8s:2.0`.
- `helm rollback lab03 1 --dry-run` passed (with Helm warning to prefer `--dry-run=client`).
- `helm rollback lab03 1` completed as revision 3.
- Verified image returned to `nigelpoulton/getting-started-k8s:1.0`.
- `helm history lab03` showed:
  - revision 1 superseded — install
  - revision 2 superseded — upgrade
  - revision 3 deployed — rollback to 1
- `helm get values lab03 --all` confirmed active values were restored to image tag `1.0`.
- `helm uninstall lab03` completed.
- Verified cleanup:
  - no Helm release remains
  - no resources remain in `web`
  - namespace `web` deleted

**Observed warning / follow-up improvement:**
- Pod Security Admission warned that the workload would violate `restricted:latest`.
- Current namespace enforces `baseline` and warns on `restricted`, so the release succeeded.
- Follow-up chart hardening should add:
  - `securityContext.allowPrivilegeEscalation: false`
  - `securityContext.capabilities.drop: ["ALL"]`
  - `securityContext.runAsNonRoot: true` where image compatibility allows
  - `seccompProfile.type: RuntimeDefault`

**Skills updated:**
- Helm chart authoring: 2 -> 3

**Next action:**
- Add restricted-compatible pod/container security context support to the chart values/templates and re-run lint/template/install/upgrade/rollback.
- Then apply the same Helm pattern to an ingress-facing workload before returning to Day 6 / lab-09 on EKS.

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
