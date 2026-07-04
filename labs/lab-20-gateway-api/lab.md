# Lab 20 — Gateway API

The Gateway API is Kubernetes' next-generation ingress: role-oriented (GatewayClass / Gateway / HTTPRoute) and CRD-driven. In this lab you install the API plus a controller (nginx-gateway-fabric) and route HTTP traffic with an HTTPRoute.

**Lab environment:** *(link to be added)*
---

## Step 1 — Install the Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
kubectl get crds | grep gateway
```

You'll see `gatewayclasses.gateway.networking.k8s.io`, `gateways...`, `httproutes...`, etc.

---

## Step 2 — Install a Gateway controller (NGINX Gateway Fabric)

```bash
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/manifests/nginx-gateway.yaml
kubectl -n nginx-gateway wait --for=condition=Ready pod -l app.kubernetes.io/name=nginx-gateway-fabric --timeout=180s
kubectl get gatewayclass
```

---

## Step 3 — Deploy a backend

```bash
kubectl create deployment echo --image=hashicorp/http-echo --port=5678 -- -text="gateway works"
kubectl expose deploy echo --port=80 --target-port=5678
```

---

## Step 4 — Create a Gateway

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: { name: web, namespace: default }
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces: { from: All }
EOF
kubectl get gateway
```

---

## Step 5 — Create an HTTPRoute

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: { name: echo-route }
spec:
  parentRefs:
  - name: web
  hostnames: ["echo.local"]
  rules:
  - matches:
    - path: { type: PathPrefix, value: / }
    backendRefs:
    - { name: echo, port: 80 }
EOF
kubectl get httproute echo-route -o yaml | grep -A3 status
```

---

## Step 6 — Test

```bash
GW_SVC=$(kubectl -n nginx-gateway get svc -o jsonpath='{.items[0].metadata.name}')
NODEPORT=$(kubectl -n nginx-gateway get svc $GW_SVC -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
curl -s -H "Host: echo.local" http://localhost:$NODEPORT
```

---

## Step 7 — Compare with Ingress

| Concept             | Ingress              | Gateway API             |
|---------------------|----------------------|-------------------------|
| Controller selector | `ingressClassName`   | `GatewayClass`          |
| Cluster object      | `Ingress` (mixed)    | `Gateway` (infra-owned) |
| Route object        | (inside `Ingress`)   | `HTTPRoute` (dev-owned) |
| Protocols           | HTTP/S only          | HTTP, HTTPS, TCP, TLS, gRPC, UDP |
| Cross-namespace     | No                   | Yes (`allowedRoutes`)   |

---

## Step 8 — Cleanup

```bash
kubectl delete httproute echo-route
kubectl delete gateway web
kubectl delete svc echo && kubectl delete deploy echo
```

---

## What you learned
- The three Gateway API objects: GatewayClass, Gateway, HTTPRoute.
- Role separation: infra installs Gateway, dev creates HTTPRoute.
- How Gateway API generalizes beyond HTTP.
