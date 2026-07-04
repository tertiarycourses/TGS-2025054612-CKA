# Lab 9 — CRDs and Operators

A CustomResourceDefinition (CRD) extends the Kubernetes API with new object kinds. An Operator is a controller that watches a CRD and reconciles real-world state. In this lab you define a tiny CRD by hand, then install **cert-manager** as a real-world operator to see the pattern in production.

**Lab environment:** [Play with Kubernetes](https://killercoda.com/playgrounds/course/kubernetes-playgrounds/two-node)
---

## Step 1 — Define a CRD

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.training.example.com
spec:
  group: training.example.com
  scope: Namespaced
  names:
    plural: widgets
    singular: widget
    kind: Widget
    shortNames: [wg]
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              color:   { type: string }
              size:    { type: integer, minimum: 1, maximum: 100 }
EOF
```

---

## Step 2 — Use the new resource

```bash
kubectl api-resources | grep widgets
cat <<'EOF' | kubectl apply -f -
apiVersion: training.example.com/v1
kind: Widget
metadata:
  name: blue-widget
spec:
  color: blue
  size: 7
EOF
kubectl get widgets
kubectl describe widget blue-widget
```

The CRD gives you storage and validation, but **no controller is reconciling it** — `kubectl get widgets` reads from etcd, nothing else happens. That's the missing operator piece.

---

## Step 3 — Install a real operator (cert-manager)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
kubectl -n cert-manager get pods
```

This installs the cert-manager Deployments **and** several CRDs:

```bash
kubectl get crds | grep cert-manager
```

You should see `certificates`, `issuers`, `clusterissuers`, `certificaterequests`, `orders`, `challenges`.

---

## Step 4 — Create a self-signed Issuer + Certificate

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata: { name: selfsigned, namespace: default }
spec: { selfSigned: {} }
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: { name: test-cert, namespace: default }
spec:
  secretName: test-cert-tls
  duration: 24h
  commonName: example.local
  issuerRef:
    name: selfsigned
    kind: Issuer
EOF
```

```bash
kubectl get certificate
kubectl get secret test-cert-tls
```

Cert-manager's controller saw the `Certificate` object, ran the issuance flow, and created the `test-cert-tls` Secret containing `tls.crt` + `tls.key`. **That** is the operator pattern.

---

## Step 5 — Clean up

```bash
kubectl delete certificate test-cert
kubectl delete issuer selfsigned
kubectl delete widget blue-widget
kubectl delete crd widgets.training.example.com
helm -n cert-manager uninstall cert-manager
```

---

## What you learned
- A CRD adds a typed, validated object kind to the API.
- Without a controller, a CRD is just storage.
- An operator = CRD(s) + controller loop, demonstrated by cert-manager.
