# Lab 09 Local: ingress-nginx Deep Dive

**Target:** Rancher Desktop | **Depends on:** Lab 02 Local | **Time:** 2–3 hours

This lab translates Nigel Poulton's nginx Ingress examples into a hardened local
exercise. Lab 02 Local must already have installed ingress-nginx and cert-manager.

## 1. Read the source and deploy the backends

```bash
cat sources/nigel_poulton/repo_k8sbook/ingress/ig-mcu-host.yml
cat sources/nigel_poulton/repo_k8sbook/ingress/ig-mcu-path.yml
cat sources/nigel_poulton/repo_k8sbook/ingress/ig-all.yml
cat sources/nigel_poulton/repo_k8sbook/ingress/app.yml

kubectl apply -f labs/lab-09-local-ingress-deep-dive/k8s/namespace.yaml
kubectl apply -f labs/lab-09-local-ingress-deep-dive/k8s/backends.yaml
kubectl rollout status deployment/shield -n ingress-lab-local
kubectl rollout status deployment/hydra -n ingress-lab-local
kubectl get endpoints -n ingress-lab-local
```

## 2. Create TLS and host-based routing

This reuses the `local-selfsigned` ClusterIssuer created in Lab 02 Local.

```bash
kubectl apply -f labs/lab-09-local-ingress-deep-dive/k8s/tls.yaml
kubectl wait --for=condition=Ready certificate/ingress-deep-dive-tls \
  -n ingress-lab-local --timeout=120s
kubectl apply -f labs/lab-09-local-ingress-deep-dive/k8s/ingress-host.yaml
kubectl describe ingress mcu-host-local -n ingress-lab-local
```

Keep the ingress controller forwarded in another terminal:

```bash
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller \
  8080:80 8443:443
```

Validate both hosts:

```bash
curl -kfsS --resolve shield.127.0.0.1.sslip.io:8443:127.0.0.1 \
  https://shield.127.0.0.1.sslip.io:8443/
curl -kfsS --resolve hydra.127.0.0.1.sslip.io:8443:127.0.0.1 \
  https://hydra.127.0.0.1.sslip.io:8443/
```

## 3. Add path-based routing and rewrite

The regex captures everything after `/shield` or `/hydra`; ingress-nginx
rewrites it to `/$2` before sending it to the selected backend.

```bash
kubectl apply -f labs/lab-09-local-ingress-deep-dive/k8s/ingress-path.yaml
kubectl describe ingress mcu-paths-local -n ingress-lab-local

curl -kfsS --resolve mcu.127.0.0.1.sslip.io:8443:127.0.0.1 \
  https://mcu.127.0.0.1.sslip.io:8443/shield/
curl -kfsS --resolve mcu.127.0.0.1.sslip.io:8443:127.0.0.1 \
  https://mcu.127.0.0.1.sslip.io:8443/hydra/
```

Compare the two Ingress objects and the controller's generated configuration:

```bash
kubectl get ingress -n ingress-lab-local -o wide
kubectl exec -n ingress-nginx deploy/ingress-nginx-controller -- \
  nginx -T 2>/dev/null | grep -E 'shield|hydra|mcu'
```

## Failure scenarios

Diagnose each before fixing it.

1. **Unknown class:** change `ingressClassName` to `does-not-exist` and observe
   that no controller reconciles the object.
2. **Wrong Service port:** change a backend port from `8080` to `80`; correlate
   the 503 with Ingress events, Service ports, and endpoints.
3. **No ready endpoints:** patch one readiness probe to `/missing`; explain why
   Running pods can still yield a 503.
4. **Bad rewrite:** remove `$2` from `rewrite-target`; compare the upstream URI
   using controller logs.
5. **TLS secret missing:** change `secretName`; inspect the certificate served
   by nginx and explain fallback-certificate behavior.
6. **Host mismatch:** send the request to localhost without a Host header and
   explain why nginx selects its default backend.

Useful commands:

```bash
kubectl describe ingress -n ingress-lab-local
kubectl get svc,endpoints,endpointslices -n ingress-lab-local
kubectl logs -n ingress-nginx \
  -l app.kubernetes.io/component=controller --tail=100
openssl s_client -connect 127.0.0.1:8443 \
  -servername shield.127.0.0.1.sslip.io </dev/null
```

## Completion checklist

- [ ] Shield and Hydra each have two Ready endpoints
- [ ] host routing returns the correct backend
- [ ] path routing returns the correct backend
- [ ] regex rewrite behavior is explained and verified
- [ ] HTTP-to-HTTPS redirect verified
- [ ] certificate contains all three DNS SANs
- [ ] controller-generated configuration inspected
- [ ] all six failure scenarios diagnosed without fix-first

After Lab 02 Local and this lab pass, Task 3 can be marked complete for
**Kubernetes networking**. Keep AWS LBC, ALB, ACM, Route53/ExternalDNS, and EKS
VPC CNI explicitly deferred.

