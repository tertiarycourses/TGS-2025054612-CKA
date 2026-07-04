# Lab 19 — Ingress Controller and Resources

An Ingress controller is a reverse proxy (typically nginx, Traefik, or Envoy) running inside the cluster that routes external HTTP/HTTPS based on `Ingress` objects. In this lab you install ingress-nginx and route two hostnames to two Services.

**Lab environment:** [Play with Kubernetes](https://labs.play-with-k8s.com)
---

## Step 1 — Install ingress-nginx

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
kubectl -n ingress-nginx wait --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=180s
kubectl -n ingress-nginx get svc
```

The bare-metal manifest creates a NodePort Service for the controller — note the assigned port.

---

## Step 2 — Deploy two backends

```bash
kubectl create deployment app1 --image=hashicorp/http-echo --port=5678 -- \
  -text="hello from app1"
kubectl create deployment app2 --image=hashicorp/http-echo --port=5678 -- \
  -text="hello from app2"
kubectl expose deploy app1 --port=80 --target-port=5678
kubectl expose deploy app2 --port=80 --target-port=5678
```

---

## Step 3 — Create the Ingress

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app1.local
    http:
      paths:
      - { path: /, pathType: Prefix, backend: { service: { name: app1, port: { number: 80 } } } }
  - host: app2.local
    http:
      paths:
      - { path: /, pathType: Prefix, backend: { service: { name: app2, port: { number: 80 } } } }
EOF
kubectl get ingress
```

---

## Step 4 — Test with Host header

```bash
NODEPORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
curl -s -H "Host: app1.local" http://localhost:$NODEPORT
curl -s -H "Host: app2.local" http://localhost:$NODEPORT
```

You should see "hello from app1" and "hello from app2".

---

## Step 5 — Add TLS

```bash
openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
  -keyout tls.key -out tls.crt -subj "/CN=app1.local"
kubectl create secret tls app1-tls --cert=tls.crt --key=tls.key

kubectl patch ingress demo --type=merge -p '
spec:
  tls:
  - hosts: [app1.local]
    secretName: app1-tls'

HTTPS=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
curl -sk -H "Host: app1.local" https://localhost:$HTTPS
```

---

## Step 6 — Path-based routing (reference)

```yaml
rules:
- http:
    paths:
    - { path: /a, pathType: Prefix, backend: { service: { name: app1, port: { number: 80 } } } }
    - { path: /b, pathType: Prefix, backend: { service: { name: app2, port: { number: 80 } } } }
```

---

## Step 7 — Cleanup

```bash
kubectl delete ingress demo
kubectl delete secret app1-tls
kubectl delete svc app1 app2
kubectl delete deploy app1 app2
rm tls.key tls.crt
```

---

## What you learned
- Controller (the proxy pod) vs Ingress resource (the routing rule).
- Host-based and path-based routing.
- TLS termination via a `tls` Secret.
