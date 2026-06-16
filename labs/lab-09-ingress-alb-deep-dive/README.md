# Lab 09: Ingress Deep Dive — From Nigel's nginx-ingress to AWS ALB

**Week:** 2, Day 6 | **Difficulty:** Intermediate–Advanced | **Est. time:** 3 hours  
**Depends on:** Lab 01 (cluster) + Lab 02 (AWS LBC installed)  
**Source material:** `repo_k8sbook/ingress/` — all 4 files (ig-mcu-host, ig-mcu-path, ig-all, app.yml)

## What Nigel's Example Shows vs. What This Lab Does

| Nigel Poulton (nginx-ingress) | This Lab (AWS ALB on EKS) |
|-------------------------------|--------------------------|
| `ingressClassName: nginx` | `kubernetes.io/ingress.class: alb` |
| nginx controller annotation `rewrite-target` | ALB routing rules — no rewrite needed |
| Self-signed or cert-manager TLS | ACM certificate on ALB (no cert in cluster) |
| Host-based routing | Same — but ALB creates one listener rule per host |
| Path-based routing | Same — but ALB target groups per path |
| Service type ClusterIP | `alb.ingress.kubernetes.io/target-type: ip` |
| One nginx pod → all traffic | AWS-managed ALB → direct to pod IPs |

**Core insight:** With nginx-ingress, one pod proxies all traffic. With ALB on EKS, AWS manages the load balancer entirely — pods are registered directly as ALB targets. This is more reliable, scales automatically, and supports native AWS features (WAF, Shield, ACM).

## Architecture

```
Internet
    │ HTTPS:443  (ACM cert auto-renewed)
    ▼
ALB (provisioned by AWS LBC when Ingress is created)
    │
    ├── Rule 1: shield.lab.yourdomain.com → target group → shield pods
    └── Rule 2: hydra.lab.yourdomain.com  → target group → hydra pods
         + /shield path → shield pods
         + /hydra path  → hydra pods

ExternalDNS: creates Route53 A records for both hosts automatically
```

---

## Prerequisites

- AWS LBC installed (Lab 02 Terraform)
- ExternalDNS installed (Lab 02 Helm)
- ACM certificate for `*.lab.yourdomain.com` — issued and validated
- Route53 hosted zone ID

---

## Lab Steps

### Step 1: Understand the Nigel source first

```bash
# Read these — understand the concepts before translating to ALB
cat sources/nigel_poulton/repo_k8sbook/ingress/ig-mcu-host.yml
cat sources/nigel_poulton/repo_k8sbook/ingress/ig-mcu-path.yml
cat sources/nigel_poulton/repo_k8sbook/ingress/ig-all.yml
cat sources/nigel_poulton/repo_k8sbook/ingress/app.yml

# The shield/hydra apps from Nigel — we deploy these directly
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backends.yaml     # shield + hydra deployments + ClusterIP services
kubectl get pods -n ingress-lab
kubectl get svc -n ingress-lab
```

### Step 2: Deploy host-based Ingress (Nigel's ig-mcu-host → ALB translation)

```bash
# Edit k8s/ingress-host.yaml — replace <YOUR_CERT_ARN> and <YOUR_DOMAIN>
kubectl apply -f k8s/ingress-host.yaml
kubectl get ingress -n ingress-lab -w
# Wait for ADDRESS column to populate (~90 seconds for ALB provisioning)

# Verify ALB created in AWS console
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `ingress-lab`)].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}'
```

Test host-based routing:
```bash
# Should return shield app
curl -H "Host: shield.lab.yourdomain.com" https://$(kubectl get ingress mcu-host -n ingress-lab -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Should return hydra app
curl -H "Host: hydra.lab.yourdomain.com" https://$(kubectl get ingress mcu-host -n ingress-lab -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

### Step 3: Deploy path-based Ingress

```bash
kubectl apply -f k8s/ingress-path.yaml
kubectl get ingress -n ingress-lab

# Test path routing
curl https://app.lab.yourdomain.com/shield
curl https://app.lab.yourdomain.com/hydra
```

### Step 4: Inspect ALB rules in AWS

```bash
# Get the ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName,`k8s-ingress`)].LoadBalancerArn' \
  --output text | head -1)

# List listener rules — should map exactly to Ingress spec rules
aws elbv2 describe-rules \
  --listener-arn $(aws elbv2 describe-listeners \
    --load-balancer-arn $ALB_ARN \
    --query 'Listeners[?Port==`443`].ListenerArn' \
    --output text) \
  --query 'Rules[].{Priority:Priority,Conditions:Conditions,Actions:Actions[0].Type}'
```

### Step 5: Verify ExternalDNS created Route53 records

```bash
# Within ~2 minutes of Ingress creation
aws route53 list-resource-record-sets \
  --hosted-zone-id <YOUR_ZONE_ID> \
  --query "ResourceRecordSets[?contains(Name,'lab.yourdomain.com')]"
# Expected: A records (ALIAS to ALB) for shield, hydra, app subdomains
```

---

## Failure Scenarios

### Failure 1: ALB never provisions — subnet tags missing

Remove `kubernetes.io/role/elb: 1` tag from public subnets.
- **Symptom:** `kubectl describe ingress mcu-host -n ingress-lab` → `Failed build model due to unable to discover at least one subnet`
- **Diagnosis:** `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller | grep subnet`
- **Fix:** Re-tag public subnets; LBC reconciles within ~30 seconds

### Failure 2: Target group shows unhealthy targets

ALB creates target group but health checks fail — `healthy: 0 / unhealthy: 2`.
- **Symptom:** ALB returns 502 or 503; pods are Running
- **Common causes:**
  1. Health check path returns non-200: `alb.ingress.kubernetes.io/healthcheck-path` wrong
  2. Security group on nodes blocks ALB health check range
  3. Pod readinessProbe failing (same symptom from lab-03)
- **Diagnosis:**
  ```bash
  aws elbv2 describe-target-health --target-group-arn <TG_ARN>
  kubectl describe pod <pod> -n ingress-lab | grep -A5 Conditions
  ```
- **Fix:** Correct health check path; verify node security group allows `0.0.0.0/0` from ALB SG

### Failure 3: HTTPS redirects but cert is invalid

ACM cert exists but not attached to Ingress annotation.
- **Symptom:** Browser shows "Your connection is not private" — cert is ALB default self-signed
- **Fix:** Add `alb.ingress.kubernetes.io/certificate-arn: <ACM_ARN>` to Ingress annotations

### Failure 4: Multiple Ingress objects create multiple ALBs (unexpected cost)

By default, AWS LBC creates one ALB per Ingress resource.
- **Symptom:** Two Ingress objects → two ALBs in AWS console → cost doubles
- **Fix:** Use `alb.ingress.kubernetes.io/group.name: my-group` annotation to share one ALB across multiple Ingress objects

---

## Key ALB Annotation Reference

```yaml
annotations:
  kubernetes.io/ingress.class: alb
  alb.ingress.kubernetes.io/scheme: internet-facing          # or internal
  alb.ingress.kubernetes.io/target-type: ip                  # register pod IPs directly
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
  alb.ingress.kubernetes.io/certificate-arn: <ACM_ARN>
  alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS13-1-2-2021-06
  alb.ingress.kubernetes.io/ssl-redirect: "443"              # HTTP → HTTPS redirect
  alb.ingress.kubernetes.io/healthcheck-path: /healthz
  alb.ingress.kubernetes.io/group.name: production           # share ALB across Ingresses
  alb.ingress.kubernetes.io/wafv2-acl-arn: <WAF_ARN>        # optional WAF
  external-dns.alpha.kubernetes.io/hostname: app.yourdomain.com
```

---

## Validation Checklist

- [ ] `kubectl get ingress -n ingress-lab` → ADDRESS column has ALB DNS name
- [ ] `curl https://shield.lab.yourdomain.com` → shield app response
- [ ] `curl https://hydra.lab.yourdomain.com` → hydra app response
- [ ] `curl https://app.lab.yourdomain.com/shield` → shield via path routing
- [ ] `curl https://app.lab.yourdomain.com/hydra` → hydra via path routing
- [ ] ALB listener rules in AWS console match Ingress spec exactly
- [ ] Route53 A records created automatically by ExternalDNS
- [ ] TLS cert shows valid ACM certificate (not self-signed)
- [ ] HTTP requests redirect to HTTPS

---

## Nigel → ALB Translation Cheatsheet

| Nigel concept | ALB equivalent |
|---------------|---------------|
| `ingressClassName: nginx` | `kubernetes.io/ingress.class: alb` |
| `nginx.ingress.kubernetes.io/rewrite-target: /` | Not needed — ALB routes natively |
| Cert-manager ClusterIssuer | ACM certificate ARN |
| NodePort service for nginx | ClusterIP service (target-type: ip bypasses NodePort) |
| Multiple hosts in one Ingress | Same — supported natively by ALB listener rules |
| Multiple paths in one Ingress | Same — supported natively by ALB path rules |

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- Ingress (ALB) with TLS termination: 0 → 3
- AWS Load Balancer Controller: 0 → 3
- ExternalDNS integration: 0 → 2
