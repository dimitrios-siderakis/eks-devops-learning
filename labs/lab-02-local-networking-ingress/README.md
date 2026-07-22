# Lab 02 Local: Networking and Ingress Foundation

**Target:** Rancher Desktop Kubernetes | **Terraform/AWS:** not required | **Time:** 2–3 hours

This is the local completion path for Kubernetes Deployment Mastery Task 3. It
validates the Kubernetes concepts from Lab 02 without claiming EKS, ALB,
ExternalDNS, Route53, ACM, or VPC CNI experience.

## Outcomes

- Install and inspect an ingress controller.
- Terminate locally issued TLS at ingress-nginx.
- Route two hostnames to two ClusterIP Services.
- Enforce default-deny and explicitly permit ingress-controller traffic.
- Prove that staging cannot reach production directly.

## Architecture

```text
curl --resolve / sslip.io
        |
        v
ingress-nginx (local TLS termination)
        |
        +--> app-local.127.0.0.1.sslip.io --> frontend:80
        +--> api-local.127.0.0.1.sslip.io --> api:8080
                    |
             production NetworkPolicy
```

## 1. Preflight

```bash
kubectl config current-context
kubectl cluster-info
```

Stop unless the context is `rancher-desktop`. Start Kubernetes from Rancher
Desktop first if the API is unavailable.

## 2. Install ingress-nginx and cert-manager

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --version 4.15.1 \
  --namespace ingress-nginx --create-namespace \
  -f labs/lab-02-local-networking-ingress/helm/ingress-nginx-values.yaml \
  --wait

helm upgrade --install cert-manager jetstack/cert-manager \
  --version v1.21.0 \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true --wait

kubectl get ingressclass
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager
```

The Helm repositories and images require internet access. No AWS credentials
are used.

## 3. Deploy and validate the workloads

```bash
kubectl apply -f labs/lab-02-local-networking-ingress/k8s/namespaces.yaml
kubectl apply -f labs/lab-02-local-networking-ingress/k8s/apps.yaml
kubectl rollout status deployment/app-frontend -n production
kubectl rollout status deployment/app-api -n production

# Prove staging can reach production before isolation.
kubectl exec -n staging deploy/staging-jump -- \
  curl -fsS --max-time 5 http://app-frontend.production.svc.cluster.local

kubectl apply -f labs/lab-02-local-networking-ingress/k8s/network-policies.yaml

# Expected to time out after default-deny is applied.
kubectl exec -n staging deploy/staging-jump -- \
  curl -fsS --max-time 5 http://app-frontend.production.svc.cluster.local
```

## 4. Issue local TLS and create the Ingress

```bash
kubectl apply -f labs/lab-02-local-networking-ingress/k8s/tls.yaml
kubectl wait --for=condition=Ready certificate/local-networking-tls \
  -n production --timeout=120s
kubectl apply -f labs/lab-02-local-networking-ingress/k8s/ingress.yaml
kubectl describe ingress production-local -n production
```

In a second terminal, keep the controller reachable on localhost:

```bash
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller \
  8080:80 8443:443
```

Then validate routing and TLS. `-k` is expected because the self-signed
certificate is not in the workstation trust store.

```bash
curl -kfsS --resolve app-local.127.0.0.1.sslip.io:8443:127.0.0.1 \
  https://app-local.127.0.0.1.sslip.io:8443/
curl -kfsS --resolve api-local.127.0.0.1.sslip.io:8443:127.0.0.1 \
  https://api-local.127.0.0.1.sslip.io:8443/
curl -sSI --resolve app-local.127.0.0.1.sslip.io:8080:127.0.0.1 \
  http://app-local.127.0.0.1.sslip.io:8080/
```

The HTTP response must redirect to HTTPS. Inspect the certificate separately:

```bash
openssl s_client -connect 127.0.0.1:8443 \
  -servername app-local.127.0.0.1.sslip.io </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -ext subjectAltName
```

## Failure scenarios

1. **Remove `ingressClassName`:** the controller may ignore the Ingress. Use
   `kubectl describe ingress` and controller logs to prove the cause.
2. **Set the API backend port to `80`:** nginx reports no usable upstream.
   Compare the Ingress backend with `kubectl get svc app-api -n production -o yaml`.
3. **Change the frontend readiness path to `/missing`:** pods remain Running but
   become unready and ingress returns 503. Diagnose endpoints before fixing.
4. **Delete `allow-from-ingress-nginx`:** ingress returns 502/504 while direct
   Service configuration remains correct. Use policy inspection and controller
   logs to isolate the network path.
5. **Reference a nonexistent TLS Secret:** inspect Ingress events and the
   controller's fallback certificate.

Controller diagnostics:

```bash
kubectl logs -n ingress-nginx \
  -l app.kubernetes.io/component=controller --tail=100
kubectl get endpoints,endpointslices -n production
kubectl get networkpolicy -n production -o yaml
```

## Completion checklist

- [x] `rancher-desktop` context verified
- [x] ingress-nginx and cert-manager pods Ready
- [x] pre-policy staging-to-production request succeeds
- [x] post-policy staging-to-production request fails
- [x] ingress remains able to reach both production backends
- [x] both TLS hostnames route to the correct Service
- [x] HTTP redirects to HTTPS
- [x] certificate SANs contain both local hostnames
- [x] at least three failure scenarios diagnosed before applying the fix

Completed on 2026-07-22. See `progress/log.md` for execution evidence and
failure recovery details. AWS/EKS-specific skills were not credited.

Do not award AWS/EKS skill levels from this lab.
