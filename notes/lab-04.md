# Lab-04 Objects - Brief Theory

Lab-04 focuses on configuration and secrets injection patterns in Kubernetes, graduating from ConfigMaps to production-grade AWS Secrets Manager.

## Objects Touched

- `ConfigMap`
  - Stores non-sensitive configuration data (key-value pairs or whole files).
  - Can be injected as environment variables or mounted as files.
  - Can be marked `immutable: true` to prevent accidental modifications.

- `Secret` (native Kubernetes)
  - Stores sensitive data encoded in base64 (NOT encrypted at rest without KMS).
  - Mounted as volumes or injected as environment variables.
  - Only as secure as etcd encryption policy; not recommended for production secrets.

- `SecretProviderClass`
  - Defines how Secrets Store CSI Driver fetches secrets from external providers (AWS Secrets Manager, Azure Key Vault, etc.).
  - Sits between pod and external secret store.

- `Secrets Store CSI Driver`
  - Kubernetes plugin that mounts secrets from external stores as volumes.
  - Supports automatic secret rotation without pod restart.
  - Requires IRSA for IAM-based access to AWS Secrets Manager.

- `Service Account` (with IRSA annotation)
  - Pod-level IAM role binding via `eks.amazonaws.com/role-arn` annotation.
  - Enables fine-grained access control for applications.

## kubectl Commands Reference

### `kubectl patch` vs `kubectl edit`

**`kubectl patch configmap <name> --patch '{"data":{"key":"value"}}'`**
- Non-interactive, one-shot update from CLI
- Changes only specified fields (JSON merge patch)
- Good for automation and scripts
- Reproducible and auditable
- Example: `kubectl patch configmap immutable-config -n config-lab --patch '{"data":{"key":"newvalue"}}'`

**`kubectl edit configmap <name>`**
- Interactive editor (opens full object YAML in `$EDITOR`)
- Change multiple fields manually
- Good for exploration and debugging
- Less reproducible (harder to replay exactly)

**`kubectl apply -f <file>`**
- Declarative, source-controlled approach
- Creates or updates based on file content
- Tracks annotations for drift detection
- Best practice for production

### Pattern Recognition

- Use `patch` for targeted, reproducible changes in automation
- Use `edit` for quick troubleshooting
- Use `apply` for desired-state management from version control

## ConfigMap Injection Patterns

**Pattern 1: Environment Variables**
```yaml
env:
  - name: FIRSTNAME
    valueFrom:
      configMapKeyRef:
        name: multimap
        key: given
```
- ConfigMap data becomes pod environment variables
- Changes require pod restart to take effect

**Pattern 2: Volume Mount**
```yaml
volumeMounts:
  - name: config-vol
    mountPath: /etc/config
volumes:
  - name: config-vol
    configMap:
      name: singlemap
```
- ConfigMap data becomes files in a mounted directory
- Changes can be reflected without pod restart (kubelet syncs)

**Pattern 3: Projected Volume**
```yaml
volumes:
  - name: combined-config
    projected:
      sources:
        - configMap:
            name: singlemap
        - secret:
            name: tkb-secret
```
- Combines ConfigMap and Secret in a single mount path
- Useful when app reads all config from one directory

## Immutable ConfigMaps

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
data:
  key: value
immutable: true
```

- Prevents accidental modifications after creation
- Kubernetes rejects any patch/edit attempts
- Good for production stability; bad for rapid iteration

## Quick Reference

```bash
# Create ConfigMap from literals
kubectl create configmap my-config --from-literal=key1=value1

# Create ConfigMap from file
kubectl create configmap my-config --from-file=app.conf

# View ConfigMap
kubectl get configmap my-config -o yaml

# Decode a native Secret
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d

# Check IRSA annotation on ServiceAccount
kubectl get sa csi-app-sa -n config-lab -o yaml | grep role-arn
```
