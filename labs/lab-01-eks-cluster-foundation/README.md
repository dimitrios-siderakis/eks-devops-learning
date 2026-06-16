# Lab 01: EKS Cluster Foundation

**Week:** 1 | **Difficulty:** Intermediate | **Est. time:** 3–4 hours

## Objective

Provision a production-grade EKS cluster using Terraform. No console clicks. The result should be a cluster you'd hand to a team to run workloads on.

## What You'll Build

```
VPC (3 AZs)
├── Public subnets  → NAT Gateways, ALB
├── Private subnets → Worker nodes, pods
└── EKS Control Plane (private endpoint + public for kubectl)
    ├── Managed Node Group (Bottlerocket, On-Demand)
    ├── Add-ons: vpc-cni, coredns, kube-proxy, ebs-csi-driver
    └── IRSA enabled (OIDC provider)
```

## Prerequisites

- AWS CLI configured (`aws sts get-caller-identity` works)
- Terraform >= 1.7
- kubectl + helm installed
- An AWS account with permissions to create EKS, VPC, IAM

## Architecture Decisions (production rationale)

| Decision | Reason |
|----------|--------|
| Bottlerocket OS | Minimal attack surface, auto-update capable |
| Private node subnets | Nodes not directly internet-reachable |
| EKS managed add-ons | AWS handles version compatibility |
| IRSA over node IAM roles | Pod-level IAM, least privilege |
| Prefix delegation on vpc-cni | Avoids IP exhaustion on large clusters |

---

## Lab Steps

### Step 1: Deploy infrastructure

```bash
cd labs/lab-01-eks-cluster-foundation/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 2: Configure kubectl

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name lab01-eks \
  --alias lab01
```

### Step 3: Verify cluster health

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl get daemonsets -n kube-system
```

**Expected:** All nodes `Ready`, coredns/vpc-cni/kube-proxy pods `Running`.

### Step 4: Validate IRSA

```bash
kubectl apply -f k8s/irsa-test-pod.yaml
kubectl logs irsa-test -n default
```

**Expected:** The pod should print its assumed IAM role ARN via `aws sts get-caller-identity`.

### Step 5: Validate EBS CSI

```bash
kubectl apply -f k8s/ebs-test-pvc.yaml
kubectl get pvc -w
```

**Expected:** PVC transitions to `Bound` within ~30 seconds.

---

## Intentional Failure Scenarios

### Failure 1: IP exhaustion (simulate)
Change `vpc-cni` annotation to disable prefix delegation, then scale node group to 10 nodes. Watch pods get stuck `Pending` with `0/X nodes available: Insufficient pods`.
- **Fix:** Re-enable prefix delegation: `ENABLE_PREFIX_DELEGATION=true` on vpc-cni DaemonSet

### Failure 2: IRSA misconfiguration
Remove the `serviceAccountName` from `irsa-test-pod.yaml`. The pod will use the node IAM role, not the pod-specific role.
- **Diagnostic:** `kubectl exec irsa-test -- aws sts get-caller-identity` shows node role ARN, not pod role ARN
- **Fix:** Restore serviceAccount reference and confirm SA has `eks.amazonaws.com/role-arn` annotation

### Failure 3: Node group in wrong subnet
Intentionally set `subnet_ids` in the node group to public subnets. Nodes will come up but pods won't have private routing.
- **Diagnostic:** `kubectl describe node` shows public IP; security group rules may block pod-to-pod traffic
- **Fix:** Restrict node group to private subnets only

---

## Validation Checklist

- [ ] `kubectl get nodes` — all nodes `Ready`
- [ ] All kube-system pods `Running` (no `Pending` or `CrashLoopBackOff`)
- [ ] IRSA test pod logs show correct role ARN (not node role)
- [ ] EBS PVC reaches `Bound` state
- [ ] `aws eks describe-cluster --name lab01-eks` shows `ACTIVE`
- [ ] Control plane logs appear in CloudWatch under `/aws/eks/lab01-eks/cluster`

---

## Cleanup

```bash
kubectl delete -f k8s/
terraform destroy
```

> **Warning:** `terraform destroy` will delete the VPC and all subnets. Ensure no other resources depend on it.

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- EKS cluster architecture: 0 → 2
- Managed Node Groups: 0 → 2
- IRSA: 0 → 2
- EKS add-ons: 0 → 2
- EKS control plane logging: 0 → 1
