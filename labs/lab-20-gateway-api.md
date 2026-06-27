# Lab 20 — Gateway API

The Gateway API is Kubernetes' next-generation traffic routing standard — role-oriented, CRD-driven, and capable of handling HTTP, HTTPS, TCP, TLS, and gRPC. It graduated to GA (v1) in Kubernetes v1.28 and is now tested in CKA 2026. You must know the three core objects: GatewayClass, Gateway, and HTTPRoute.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- Gateway API CRDs (installed in Step 1)
- NGINX Gateway Fabric controller (installed in Step 2)
- `hashicorp/http-echo` image (pulled automatically)

---

## Step 1 — Install the Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
kubectl get crds | grep gateway
```

You should see: `gatewayclasses`, `gateways`, `httproutes`, `grpcroutes`, `referencegrants`.

---

## Step 2 — Install NGINX Gateway Fabric controller

```bash
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/manifests/nginx-gateway.yaml
kubectl -n nginx-gateway wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=nginx-gateway-fabric --timeout=180s
kubectl get gatewayclass
```

---

## Step 3 — Deploy a backend

```bash
kubectl create deployment echo --image=hashicorp/http-echo --port=5678 \
  -- -text="gateway works"
kubectl expose deploy echo --port=80 --target-port=5678
```

---

## Step 4 — Create a Gateway (infrastructure-owned)

```bash
cat > gateway.yaml <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web
  namespace: default
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
kubectl apply -f gateway.yaml
kubectl get gateway web
kubectl describe gateway web | grep -A5 Status
```

The Gateway represents the load balancer infrastructure — owned by cluster admins.

---

## Step 5 — Create an HTTPRoute (developer-owned)

```bash
cat > httproute.yaml <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
spec:
  parentRefs:
  - name: web
  hostnames:
  - "echo.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: echo
      port: 80
EOF
kubectl apply -f httproute.yaml
kubectl get httproute echo-route
```

The HTTPRoute is developer-owned — separate RBAC from the Gateway. `parentRefs` binds this route to the `web` Gateway.

---

## Step 6 — Test the route

```bash
NODEPORT=$(kubectl -n nginx-gateway get svc \
  -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}')
curl -s -H "Host: echo.local" http://localhost:$NODEPORT
```

Expected: `gateway works`

---

## Step 7 — Gateway API vs Ingress comparison

| Concept | Ingress | Gateway API |
|---------|---------|-------------|
| Controller selector | `ingressClassName` | `GatewayClass` |
| Infrastructure object | `Ingress` (mixed) | `Gateway` (admin-owned) |
| Route object | (inside Ingress) | `HTTPRoute` (dev-owned) |
| Protocols | HTTP/HTTPS only | HTTP, HTTPS, TCP, TLS, gRPC, UDP |
| Cross-namespace routes | No | Yes (`allowedRoutes`) |
| Role separation | None | GatewayClass → Gateway → Route |

---

## Step 8 — Clean up

```bash
kubectl delete httproute echo-route
kubectl delete gateway web
kubectl delete svc echo
kubectl delete deploy echo
```

---

## Free online tools

- **Gateway API docs**: https://gateway-api.sigs.k8s.io/
- **Gateway API releases**: https://github.com/kubernetes-sigs/gateway-api/releases
- **NGINX Gateway Fabric**: https://docs.nginx.com/nginx-gateway-fabric/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- Three Gateway API objects: `GatewayClass` (infra type), `Gateway` (admin), `HTTPRoute` (developer).
- `parentRefs` in HTTPRoute binds the route to a specific Gateway.
- Gateway API supports more protocols than Ingress and enables true role separation.
- `allowedRoutes.namespaces` controls which namespaces can attach routes to a Gateway.
