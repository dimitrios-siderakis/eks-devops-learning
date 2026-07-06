# KodeKloud — Course Catalog

> Courses relevant to the EKS production readiness track.
> Notes go in `notes/<course-slug>.md`. Progress tracked in `progress.md`.

---

## Kubernetes Track

| Course | Slug | Aligns to Labs | Priority |
|--------|------|---------------|----------|
| Kubernetes Crash Course: For Absolute Beginners | k8s-crash-course | lab-03 | ✅ COMPLETED |
| Kubernetes for the Absolute Beginners - Hands-on Tutorial | k8s-beginners | lab-03, lab-04, lab-06 | ✅ COMPLETED 2026-06-20 |
| Kubernetes and Cloud-Native Associate (KCNA) | kcna | lab-03, lab-04, lab-05, lab-06, lab-07 | HIGH (do next) |
| Certified Kubernetes Administrator (CKA) | cka | all | HIGH |
| Kubernetes CKAD | ckad | lab-03, lab-04, lab-07 | MEDIUM |
| Kubernetes Security Specialist (CKS) | cks | lab-08 | MEDIUM |

## AWS / EKS Track

| Course | Slug | Aligns to Labs | Priority |
|--------|------|---------------|----------|
| Amazon EKS Basics | eks-basics | lab-01, lab-02 | HIGH |
| Helm for Beginners | helm-basics | lab-09, lab-10 | ✅ COMPLETED 2026-07-06 |
| ArgoCD | argocd | post-week-4 | LOW |

## Supplemental External Theory Source

| Source | Use Case | Rule |
|--------|----------|------|
| Stackademic all-in-one Linux/DevOps blogs: https://blog.stackademic.com/all-in-one-linux-devops-automation-blogs-46621975f0f8 | Quick inclusive refresher when a specific concept needs explanation/check | Use only for targeted theory lookup, not as primary course path |

## How to use this folder

```
sources/kodekloud/
  courses.md           ← this file
  progress.md          ← which sections completed
  notes/
    k8s-beginners.md   ← notes during course
    cka.md
    eks-basics.md
```

When a course section maps to a lab, add `→ lab-XX` inline in your notes.
