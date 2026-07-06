# Helm for Beginners — Notes

> Course: Helm for Beginners (KodeKloud)
> Status: COMPLETED — 100% (33/33 lessons) as of 2026-07-06
> Goal alignment: Task 4 — Configuration Management: Helm, Templating, Package Management

---

## Course Structure

1. Introduction (2 lessons)
2. Introduction to Helm (13 lessons)
3. Helm Charts Anatomy (17 lessons)
4. Conclusion (1 lesson)

---

## Introduction

- Completed 2026-07-05.
- Course introduction and KodeKloud support/notes orientation.

## Introduction to Helm

- Completed 2026-07-05.
- Covered what Helm is, installation/configuration, Helm 2 vs Helm 3 context, Helm components, chart basics, working with Helm, customizing chart parameters, lifecycle management, and course resources.
- Hands-on labs completed:
  - Installing Helm
  - Using Helm to deploy a chart
  - Upgrading a Helm chart

## Helm Charts Anatomy

- Completed 2026-07-06.
- Covered:
  - Chart file structure and the role of `Chart.yaml`, `values.yaml`, and `templates/`
  - Writing a chart and checking rendered output before install
  - Template functions and pipelines
  - Conditional rendering
  - `with` blocks for scoped values
  - `range` loops for repeated manifests or repeated sections
  - Named templates / helpers for reusable labels and naming conventions
  - Chart hooks for lifecycle actions
  - Packaging, signing, and uploading charts
- Hands-on labs completed:
  - Writing a Helm chart
  - Using functions and pipelines
  - Conditionals, with blocks, and ranges
  - Chart hooks
  - Uploading charts

## Conclusion

- Completed 2026-07-06.
- Helm for Beginners course is complete: 33/33 lessons.

---

## Hands-on Follow-up

Completed 2026-07-06 using `labs/lab-03-production-deployments/chart`.

Charted the existing lab-03 workload with:

- `Chart.yaml`
- `values.yaml`
- `templates/_helpers.tpl`
- `templates/namespace.yaml`
- `templates/deployment.yaml`
- `templates/service.yaml`
- `templates/hpa.yaml`
- `templates/pdb.yaml`

Validated locally on Rancher Desktop:

- `helm lint ./chart`
- `helm template lab03 ./chart`
- `helm install lab03 ./chart --dry-run`
- `helm install lab03 ./chart`
- Kubernetes rollout, pods, Service endpoints, HPA, and PDB checks
- `helm upgrade lab03 ./chart --set image.tag=2.0 --set changeCause="v2 - updated application image via Helm" --dry-run`
- `helm upgrade lab03 ./chart --set image.tag=2.0 --set changeCause="v2 - updated application image via Helm"`
- `helm rollback lab03 1 --dry-run`
- `helm rollback lab03 1`
- `helm history lab03`
- `helm get values lab03 --all`
- `helm status lab03`
- `helm uninstall lab03`
- namespace/resource cleanup verification

Key lesson:

- `templates/` holds reusable Kubernetes structure.
- `values.yaml` holds release-specific knobs such as image tag, replica count, service port, resources, probes, HPA, and PDB settings.
- Helm rollback creates a new revision; it does not make the old revision active in-place.
- PodSecurity warnings showed the chart still needs restricted-compatible security context hardening.

Next:

1. Add optional pod/container security context values and template support.
2. Re-run lint/template/install/upgrade/rollback after hardening.
3. Repeat the pattern for an ingress-facing workload before Day 6 / lab-09 on EKS.
