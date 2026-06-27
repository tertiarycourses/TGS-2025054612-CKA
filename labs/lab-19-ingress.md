# Lab 19 — Ingress Controller and Resources

An Ingress controller is a reverse proxy running inside the cluster that routes external HTTP/HTTPS traffic based on host and path rules defined in Ingress objects. CKA 2026 tests installing ingress-nginx, host-based routing, TLS termination, and debugging misconfigured Ingress resources.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `openssl` (pre-installed on Killercoda)
- ingress-nginx controller (installed in Step 1)
- `hashicorp/http-echo` image (pulled automatically)

---

## Step 1 — Install ingress-nginx

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
kubectl -n ingress-nginx wait --for=condition=Ready pod \
  -l app.kubernetes.io/component=controller --timeout=180s
kubectl -n ingress-nginx get svc ingress-nginx-controller
```

Note the NodePort values — you need them to test:

```bash
HTTP_PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
HTTPS_PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
echo "HTTP=$HTTP_PORT  HTTPS=$HTTPS_PORT"
```

---

## Step 2 — Deploy two backends

```bash
kubectl create deployment app1 --image=hashicorp/http-echo --port=5678 \
  -- -text="hello from app1"
kubectl create deployment app2 --image=hashicorp/http-echo --port=5678 \
  -- -text="hello from app2"
kubectl expose deploy app1 --port=80 --target-port=5678
kubectl expose deploy app2 --port=80 --target-port=5678
```

---

## Step 3 — Create an Ingress with host-based routing

```bash
cat > ing.yaml <<'EOF'
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
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1
            port:
              number: 80
  - host: app2.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2
            port:
              number: 80
EOF
kubectl apply -f ing.yaml
kubectl get ingress demo
```

`ingressClassName: nginx` selects which controller handles this Ingress. The Ingress `apiVersion` is `networking.k8s.io/v1` — not the deprecated `extensions/v1beta1`.

---

## Step 4 — Test with Host header

```bash
curl -s -H "Host: app1.local" http://localhost:$HTTP_PORT
curl -s -H "Host: app2.local" http://localhost:$HTTP_PORT
```

Expected: `hello from app1` and `hello from app2`.

---

## Step 5 — Add TLS termination

```bash
openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
  -keyout tls.key -out tls.crt -subj "/CN=app1.local"
kubectl create secret tls app1-tls --cert=tls.crt --key=tls.key

kubectl patch ingress demo --type=merge -p '
spec:
  tls:
  - hosts: [app1.local]
    secretName: app1-tls'

curl -sk -H "Host: app1.local" https://localhost:$HTTPS_PORT
```

The `tls.secretName` must reference a `kubernetes.io/tls` type Secret containing `tls.crt` and `tls.key`.

---

## Step 6 — Path-based routing

```bash
kubectl patch ingress demo --type=json -p='[
  {"op":"add","path":"/spec/rules/0/http/paths/-",
   "value":{"path":"/v2","pathType":"Prefix",
   "backend":{"service":{"name":"app2","port":{"number":80}}}}}]'

curl -s -H "Host: app1.local" http://localhost:$HTTP_PORT/v2
```

---

## Step 7 — Debug a broken Ingress

```bash
kubectl patch ingress demo --type=merge \
  -p '{"spec":{"rules":[{"host":"app1.local","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"wrong-name","port":{"number":80}}}}]}}]}}'
curl -s -H "Host: app1.local" http://localhost:$HTTP_PORT
kubectl describe ingress demo | grep -A5 Rules
```

A 503 means the Ingress rule points to a Service that does not exist. Fix: correct the service name.

```bash
kubectl delete ingress demo
kubectl apply -f ing.yaml
```

---

## Step 8 — Clean up

```bash
kubectl delete ingress demo
kubectl delete secret app1-tls
kubectl delete svc app1 app2
kubectl delete deploy app1 app2
rm -f tls.key tls.crt
```

---

## Free online tools

- **ingress-nginx docs**: https://kubernetes.github.io/ingress-nginx/
- **Ingress API reference**: https://kubernetes.io/docs/concepts/services-networking/ingress/
- **Ingress controllers list**: https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- Ingress `apiVersion` is `networking.k8s.io/v1` — `extensions/v1beta1` was removed in v1.22.
- `ingressClassName` selects the controller; without it the Ingress is ignored.
- TLS termination requires a `kubernetes.io/tls` Secret referenced by `spec.tls.secretName`.
- A 503 from the controller means the backend Service or its Endpoints are missing.
