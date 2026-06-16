# KodeKloud — Course Catalog

> Courses relevant to the EKS production readiness track.
> Notes go in `notes/<course-slug>.md`. Progress tracked in `progress.md`.

---

## Kubernetes Track

| Course | Slug | Aligns to Labs | Priority |
|--------|------|---------------|----------|
| Kubernetes for the Absolute Beginners | k8s-beginners | lab-03, lab-04, lab-06 | HIGH (do first) |
| Certified Kubernetes Administrator (CKA) | cka | all | HIGH |
| Kubernetes CKAD | ckad | lab-03, lab-04, lab-07 | MEDIUM |
| Kubernetes Security Specialist (CKS) | cks | lab-08 | MEDIUM |

## AWS / EKS Track

| Course | Slug | Aligns to Labs | Priority |
|--------|------|---------------|----------|
| Amazon EKS Basics | eks-basics | lab-01, lab-02 | HIGH |
| Helm for Beginners | helm-basics | lab-09, lab-10 | MEDIUM |
| ArgoCD | argocd | post-week-4 | LOW |

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
