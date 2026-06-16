# Lab 04: ConfigMaps, Native Secrets & AWS Secrets Manager (Secrets Store CSI)

**Week:** 2 | **Difficulty:** Intermediate | **Est. time:** 3–4 hours  
**Depends on:** Lab 01 cluster (IRSA + OIDC provider)  
**Source material:** `repo_k8sbook/configmaps/*` (singlemap, multimap, envpod, secretpod, tkb-secret)

## What Poulton's Example Shows vs. What This Lab Adds

| Poulton | This Lab |
|---------|----------|
| ConfigMap as volume file | + immutable ConfigMaps |
| ConfigMap as env vars | + projected volumes (CM + Secret combined) |
| Native K8s Secret (base64) | → replaced with Secrets Store CSI → AWS Secrets Manager |
| Secret mounted as volume | + Secret rotation without pod restart |
| No IRSA | + IRSA role for CSI driver |

## Objective

Understand all three config injection patterns, then graduate native Secrets to AWS Secrets Manager via the Secrets Store CSI Driver — the production standard for EKS.

## Architecture

```
Part A — ConfigMaps
  multimap (k/v) → env vars in pod
  singlemap (file) → volume mount in pod

Part B — Native Secrets (understand, then replace)
  tkb-secret (Opaque) → volume mount
  ⚠️  Problem: base64 is NOT encryption; etcd at rest requires KMS (Lab 01 enabled this)

Part C — Secrets Manager + CSI Driver (production pattern)
  AWS Secrets Manager secret
      ↓ (IRSA — pod-level IAM)
  Secrets Store CSI Driver
      ↓ (SecretProviderClass)
  Pod reads secret as file /mnt/secrets/db-password
      ↓ (optional sync)
  Kubernetes Secret object (for env var projection)
```

---

## Prerequisites

- Lab 01 cluster with IRSA/OIDC
- Secrets Store CSI Driver installed:
  ```bash
  helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
  helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
    -n kube-system \
    --set syncSecret.enabled=true \
    --set enableSecretRotation=true
  ```
- AWS Provider for CSI Driver:
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
  ```
- Terraform in `terraform/` to provision the Secrets Manager secret + IRSA role:
  ```bash
  cd terraform && terraform init && terraform apply
  ```

---

## Lab Steps

### Part A: ConfigMap Patterns

```bash
kubectl apply -f k8s/configmaps.yaml
kubectl apply -f k8s/configmap-pods.yaml

# Verify env var injection
kubectl exec -n config-lab cm-envpod -- env | grep -E "FIRSTNAME|LASTNAME"
# Expected: FIRSTNAME=Nigel  LASTNAME=Poulton

# Verify file mount
kubectl exec -n config-lab cm-filepod -- cat /etc/config/app.conf
# Expected: file contents from singlemap

# Test immutable ConfigMap — should be rejected
kubectl patch configmap immutable-config -n config-lab \
  --patch '{"data": {"key": "newvalue"}}'
# Expected: "configmap is immutable"
```

### Part B: Native Secret (understand the weakness)

```bash
kubectl apply -f k8s/native-secret.yaml

# Decode the "secret" — it's just base64, not encrypted at rest without KMS
kubectl get secret tkb-secret -n config-lab -o jsonpath='{.data.password}' | base64 -d
# Expected: plaintext password. This is why KMS envelope encryption in Lab 01 matters.

# Verify volume mount
kubectl exec -n config-lab secret-pod -- cat /etc/tkb/password
```

### Part C: Secrets Manager via CSI Driver

```bash
# Get IRSA role ARN from Terraform
CSI_ROLE_ARN=$(cd terraform && terraform output -raw csi_irsa_role_arn)

# Annotate the ServiceAccount
kubectl annotate sa csi-app-sa -n config-lab \
  eks.amazonaws.com/role-arn=$CSI_ROLE_ARN

kubectl apply -f k8s/secret-provider-class.yaml
kubectl apply -f k8s/csi-app.yaml

# Verify secret is mounted from Secrets Manager (not a K8s Secret)
kubectl exec -n config-lab csi-app -- cat /mnt/secrets/db-password
# Expected: actual password from AWS Secrets Manager

# Verify synced K8s Secret (for env var use)
kubectl get secret synced-db-secret -n config-lab
kubectl get secret synced-db-secret -n config-lab \
  -o jsonpath='{.data.db-password}' | base64 -d
```

### Step: Test Secret Rotation

```bash
# Update the secret in AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id lab04/db-password \
  --secret-string '{"db-password":"NewSecurePassword456!"}'

# CSI driver rotates within the configured interval (default 2 min)
# Watch for the update without pod restart:
kubectl exec -n config-lab csi-app -- watch cat /mnt/secrets/db-password
```

---

## Failure Scenarios

### Failure 1: IRSA role missing Secrets Manager permission
Remove `secretsmanager:GetSecretValue` from the IRSA policy.
- **Symptom:** Pod stuck in `ContainerCreating`; `kubectl describe pod csi-app -n config-lab` → `failed to fetch secret from secrets manager: AccessDeniedException`
- **Fix:** Add `secretsmanager:GetSecretValue` for the specific secret ARN

### Failure 2: SecretProviderClass wrong secret name
Set `objectName` in the SecretProviderClass to a non-existent Secrets Manager secret name.
- **Symptom:** Pod stuck `ContainerCreating` → `ResourceVersion... failed to get secret`
- **Fix:** `aws secretsmanager describe-secret --secret-id <name>` to verify ARN; update `objectName`

### Failure 3: ConfigMap env var typo in `valueFrom.key`
Change `configMapKeyRef.key` from `given` to `firstname` (wrong key).
- **Symptom:** Pod fails with `Error: couldn't find key firstname in ConfigMap`
- **Fix:** `kubectl describe configmap multimap -n config-lab` to list actual keys

### Failure 4: Secret rotation — old value cached in env var
A pod reads Secrets Manager via env var (not volume). Secret rotates but pod still uses old value.
- **Symptom:** App fails auth with rotated credential; CSI volume shows new value but env var is stale
- **Fix:** Use CSI volume mount (not env var) for rotatable secrets; restart pod or use `envsub` sidecar

---

## Validation Checklist

- [ ] `kubectl exec cm-envpod -- env | grep FIRSTNAME` → `Nigel`
- [ ] `kubectl exec cm-filepod -- cat /etc/config/app.conf` → file contents visible
- [ ] Immutable ConfigMap patch rejected
- [ ] Native secret decoded to plaintext (demonstrates base64 ≠ encryption)
- [ ] CSI pod reads `/mnt/secrets/db-password` from Secrets Manager
- [ ] `synced-db-secret` K8s Secret exists and contains the value
- [ ] After secret rotation, file content updates without pod restart

---

## Debugging Reference

```bash
# CSI driver logs
kubectl logs -n kube-system -l app=csi-secrets-store-provider-aws --tail=50

# Why is the pod stuck ContainerCreating?
kubectl describe pod csi-app -n config-lab | grep -A10 "Events:"

# List all SecretProviderClass objects
kubectl get secretproviderclass -n config-lab -o yaml

# Verify IRSA is working for the CSI SA
kubectl exec -n config-lab csi-app -- \
  env | grep AWS_  # should show AWS_ROLE_ARN, AWS_WEB_IDENTITY_TOKEN_FILE
```

---

## Skills Updated After Completion

Update `skills_matrix.md`:
- ConfigMaps & Secrets management: 0 → 3
- Secrets management (Secrets Store CSI / ESO): 0 → 2
- IRSA: 2 → 3
