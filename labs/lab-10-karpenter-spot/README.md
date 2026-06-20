# Lab 10: Karpenter + Spot — Production Node Autoscaling

**Week:** 2, Day 9 | **Difficulty:** Advanced | **Est. time:** 4 hours  
**Depends on:** Lab 01 cluster (Terraform VPC + EKS)  
**Type:** Production-grade scenario (no Nigel Poulton source equivalent — fills the autoscaling gap)

## Why This Lab Exists

Neither Nigel Poulton repo covers autoscaling. Karpenter is the production-standard node provisioner for EKS — it replaces Cluster Autoscaler and is faster, more flexible, and Spot-native. This is a critical platform engineering skill.

## What You'll Build

```
Karpenter NodePool (2 configs):
  ├── on-demand:  m6i.xlarge / m6a.xlarge  → for critical stateful workloads
  └── spot:       m6i.large / m6a.large / c6i.large (mixed) → for stateless burst

EC2NodeClass:
  └── Bottlerocket, private subnets, cluster security group, kubelet config

Node Termination Handler (NTH):
  └── DaemonSet that watches EC2 Spot interruption notices
      → drains pods 2 minutes before the instance is reclaimed

Scenario:
  Deploy 30 replicas → Karpenter provisions nodes in <60s
  Simulate Spot interruption → NTH drains, pods reschedule
  Scale to 0 → Karpenter removes idle nodes after 30s
```

---

## Prerequisites

- Lab 01 cluster running
- `helm` installed
- Terraform in `terraform/` to provision the Karpenter IAM role + SQS queue
- Sandbox profile configured and working: `aws sts get-caller-identity --profile kodekloud-sandbox`

---

## Step 1: Deploy Infrastructure (Terraform)

```bash
cd labs/lab-10-karpenter-spot/terraform
AWS_PROFILE=kodekloud-sandbox terraform init
AWS_PROFILE=kodekloud-sandbox terraform apply
```

This provisions:
- Karpenter IAM role (IRSA, node provisioning permissions)
- SQS queue for Spot interruption events
- EventBridge rules → SQS (Spot interruption, instance rebalance, state change)

### Step 2: Install Karpenter

```bash
export CLUSTER_NAME=lab01-eks
export KARPENTER_VERSION=1.0.0
export KARPENTER_ROLE_ARN=$(cd terraform && AWS_PROFILE=kodekloud-sandbox terraform output -raw karpenter_irsa_role_arn)

helm registry logout public.ecr.aws || true
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "${KARPENTER_VERSION}" \
  --namespace kube-system \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=$(cd terraform && AWS_PROFILE=kodekloud-sandbox terraform output -raw sqs_queue_name)" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${KARPENTER_ROLE_ARN}" \
  --wait

kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter
```

### Step 3: Deploy NodePool and EC2NodeClass

```bash
kubectl apply -f k8s/ec2nodeclass.yaml
kubectl apply -f k8s/nodepool-spot.yaml
kubectl apply -f k8s/nodepool-ondemand.yaml
```

### Step 4: Trigger scale-out

```bash
kubectl apply -f k8s/burst-deployment.yaml
# Deploys 30 replicas — far more than existing nodes can handle
kubectl get pods -w   # watch Pending → Running as Karpenter provisions nodes

# How long did it take?
kubectl get nodes -w   # new nodes appear in ~30-60 seconds
```

### Step 5: Verify Spot selection

```bash
kubectl get nodes -L karpenter.sh/capacity-type,node.kubernetes.io/instance-type
# Expected: mix of spot and on-demand nodes per NodePool config
```

### Step 6: Simulate Spot interruption

```bash
# Install Node Termination Handler (watches SQS for real interruption events)
helm install aws-node-termination-handler eks/aws-node-termination-handler \
  --namespace kube-system \
  --set enableSpotInterruptionDraining=true \
  --set enableRebalanceMonitoring=true \
  --set queueURL=$(cd terraform && AWS_PROFILE=kodekloud-sandbox terraform output -raw sqs_queue_url)

# Simulate interruption manually by draining a Spot node
SPOT_NODE=$(kubectl get nodes -l karpenter.sh/capacity-type=spot \
  -o jsonpath='{.items[0].metadata.name}')
kubectl drain $SPOT_NODE --ignore-daemonsets --delete-emptydir-data

# Watch pods reschedule to remaining nodes (or trigger new node)
kubectl get pods -o wide -w
```

### Step 7: Scale to zero → Karpenter removes idle nodes

```bash
kubectl scale deployment burst-app --replicas=3
# Wait 30 seconds (consolidation policy)
kubectl get nodes -w
# Idle nodes removed — only 3-node cluster remains
```

---

## Failure Scenarios

### Failure 1: Karpenter can't provision — instance type not available in AZ
NodePool includes `c6g.large` (ARM) but Bottlerocket x86 is configured in EC2NodeClass.
- **Symptom:** Pods stuck `Pending`; Karpenter logs: `no offering available` or `architecture mismatch`
- **Diagnosis:** `kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter | grep -i "failed\|error\|no offering"`
- **Fix:** Remove ARM instance types from NodePool or add `amiFamily: Bottlerocket` with ARM-compatible AMI

### Failure 2: Spot nodes provisioned but pods won't schedule (taint mismatch)
NodePool adds taint `spot:NoSchedule` but `burst-deployment.yaml` has no toleration.
- **Symptom:** Nodes appear `Ready` but pods stay `Pending`; `kubectl describe pod` shows taint rejection
- **Fix:** Add toleration to deployment or remove taint from NodePool (production: always use tolerations)

### Failure 3: NodePool consolidation removes node with PVC attached
Scale-down consolidation tries to move a pod with EBS PVC to another node in a different AZ.
- **Symptom:** Pod stuck `Pending` after consolidation: `1 node(s) had volume node affinity conflict`
- **Fix:** Add `karpenter.sh/do-not-disrupt: "true"` annotation to pods with AZ-locked PVCs

### Failure 4: Old Managed Node Group still exists — Karpenter competes
Lab 01 MNG and Karpenter both provision nodes. Karpenter provisions efficiently but scheduler places pods on MNG nodes (no Karpenter label preference).
- **Symptom:** Karpenter idle; all pods on original MNG nodes
- **Fix:** Taint the MNG nodes or use node affinity to prefer Karpenter-managed nodes

---

## Validation Checklist

- [ ] `kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter` — Running
- [ ] 30 replicas deployed: nodes scale from 3 → 6+ within 60 seconds
- [ ] New nodes show `karpenter.sh/capacity-type=spot` label
- [ ] `kubectl get nodes -L karpenter.sh/capacity-type` — mix of spot + on-demand
- [ ] After drain: pods reschedule within 2 minutes
- [ ] Scale down to 3 replicas: idle nodes removed by consolidation
- [ ] `kubectl describe nodeclaim` — shows Karpenter-managed node lifecycle

---

## Debugging Reference

```bash
# Karpenter controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -c controller --tail=50

# Why are pods still Pending?
kubectl describe pod <pending-pod>
kubectl get nodeclaim -A   # shows what Karpenter is trying to provision

# What instance types is Karpenter considering?
kubectl describe nodeclaim <name>

# Karpenter events
kubectl get events -n kube-system --field-selector reason=ProvisioningFailed

# List all nodes with Karpenter labels
kubectl get nodes -L karpenter.sh/capacity-type,karpenter.sh/nodepool,node.kubernetes.io/instance-type

# NodePool status
kubectl get nodepool -o wide
```

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- Cluster Autoscaler / Karpenter: 0 → 3
- Taints, Tolerations, Affinity rules: 1 → 2
- EKS add-ons: 2 → 3
