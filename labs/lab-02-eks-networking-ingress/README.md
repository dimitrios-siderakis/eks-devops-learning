# Lab 02: EKS Networking & Ingress

**Week:** 1 | **Difficulty:** Intermediate-Advanced | **Est. time:** 3–4 hours  
**Depends on:** Lab 01 cluster must be running

## Objective

Deploy the AWS Load Balancer Controller, expose a service over HTTPS via an ALB Ingress, configure ExternalDNS for automatic Route53 records, and enforce Network Policies between namespaces.

## What You'll Build

```
Internet
    │
    ▼
ALB (HTTPS, ACM cert)
    │
    ▼
AWS Load Balancer Controller (in-cluster)
    │
    ├── Ingress → app-frontend (Namespace: production)
    └── Ingress → app-api     (Namespace: production)

Network Policies:
  production  → can reach  database namespace
  staging     → CANNOT reach production or database
```

## Architecture Decisions

| Decision | Reason |
|----------|--------|
| AWS LBC instead of in-tree CLB | Supports ALB (layer 7), target group binding, weighted routing |
| ACM cert on ALB, not in-cluster | Offloads TLS; cert renewal is AWS-managed |
| ExternalDNS with Route53 | Automatic DNS — no manual A-record management |
| Network Policies (Calico/vpc-cni) | Namespace isolation; defense in depth |
| `WaitForFirstConsumer` on ingress | Prevents ALB provisioning before pods schedule |

---

## Prerequisites

- Lab 01 cluster running
- A Route53 hosted zone you control
- ACM certificate issued (wildcard `*.lab.yourdomain.com` recommended)
- Helm 3 installed

---

## Lab Steps

### Step 1: Deploy AWS Load Balancer Controller

```bash
cd labs/lab-02-eks-networking-ingress/terraform
terraform init
terraform apply
```

This provisions the IRSA role for the LBC. Then install via Helm:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=lab01-eks \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw lbc_role_arn) \
  --set region=us-east-1 \
  --set vpcId=$(terraform output -raw vpc_id)
```

Verify: `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`

### Step 2: Deploy ExternalDNS

```bash
helm install external-dns bitnami/external-dns \
  -n kube-system \
  --set provider=aws \
  --set aws.region=us-east-1 \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw externaldns_role_arn) \
  --set domainFilters[0]=lab.yourdomain.com \
  --set policy=sync
```

### Step 3: Deploy test application

```bash
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

**Update `k8s/ingress.yaml`:** Replace `<YOUR_CERT_ARN>` and `<YOUR_DOMAIN>` before applying.

### Step 4: Verify ALB provisioned

```bash
kubectl get ingress -n production -w
# ADDRESS column populates when ALB is ready (~2 min)
```

```bash
curl -I https://app.lab.yourdomain.com
# Expected: HTTP/2 200
```

### Step 5: Enforce Network Policies

```bash
kubectl apply -f k8s/network-policies.yaml
```

Test isolation:
```bash
# Should SUCCEED (production → database)
kubectl exec -n production deploy/app-frontend -- \
  curl -s --max-time 3 http://postgres.database.svc.cluster.local

# Should FAIL (staging → database)
kubectl exec -n staging deploy/staging-app -- \
  curl -s --max-time 3 http://postgres.database.svc.cluster.local
# Expected: connection timed out
```

---

## Intentional Failure Scenarios

### Failure 1: LBC missing subnet tags
Remove `kubernetes.io/role/elb` tag from public subnets. The LBC cannot discover subnets and the ALB never provisions.
- **Symptom:** `kubectl describe ingress` shows `Failed build model due to unable to discover at least one subnet`
- **Fix:** Re-add the tag to public subnets; LBC re-reconciles automatically

### Failure 2: IRSA permissions gap for ExternalDNS
Remove `route53:ChangeResourceRecordSets` from the ExternalDNS policy.
- **Symptom:** `kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns` shows `AccessDenied`
- **DNS:** A-records never created; `nslookup app.lab.yourdomain.com` fails
- **Fix:** Add missing Route53 action to the IAM policy

### Failure 3: Network policy "deny-all" without explicit allow
Apply `k8s/network-policies.yaml` and forget to apply the allow policy for production → kube-dns.
- **Symptom:** DNS resolution breaks inside `production` namespace; pods can't reach any service by name
- **Fix:** Add egress rule allowing port 53 to `kube-system` namespace

---

## Validation Checklist

- [ ] `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller` — Running
- [ ] `kubectl get ingress -n production` — ADDRESS column has ALB DNS name
- [ ] `curl -I https://app.lab.yourdomain.com` — HTTP/2 200 with valid cert
- [ ] Route53 console shows auto-created A-record for `app.lab.yourdomain.com`
- [ ] Production → database: succeeds
- [ ] Staging → database: times out (network policy enforced)

---

## Cleanup

```bash
kubectl delete -f k8s/
helm uninstall aws-load-balancer-controller -n kube-system
helm uninstall external-dns -n kube-system
terraform destroy
```

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- AWS Load Balancer Controller: 0 → 2
- VPC CNI plugin: 0 → 1
- Ingress (ALB) with TLS termination: 0 → 2
- ExternalDNS integration: 0 → 2
- Network Policies: 0 → 2
- IRSA: 2 → 3 (reinforced)
