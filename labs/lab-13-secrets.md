# Lab 13 — Secrets

Kubernetes Secrets carry sensitive data — passwords, tokens, TLS keys — and are base64-encoded (not encrypted) by default. In this lab you create a generic Secret, a TLS Secret, and a docker-registry Secret, and use them from pods.

Use the **Kubernetes playground**: https://killercoda.com/playgrounds/scenario/kubernetes

---

## Step 1 — Create a generic Secret

```bash
kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password='S3cure!Pw'
kubectl get secret db-creds -o yaml
```

Notice the base64 values — decode one:

```bash
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 -d ; echo
```

---

## Step 2 — Consume as env vars

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: sec-env }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","echo user=$DB_USER pw=$DB_PASS; sleep 3600"]
    env:
    - name: DB_USER
      valueFrom: { secretKeyRef: { name: db-creds, key: username } }
    - name: DB_PASS
      valueFrom: { secretKeyRef: { name: db-creds, key: password } }
EOF
kubectl wait --for=condition=Ready pod/sec-env --timeout=60s
kubectl logs sec-env
```

---

## Step 3 — Consume as a mounted file

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: sec-file }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","ls /etc/db; cat /etc/db/username; echo; sleep 3600"]
    volumeMounts:
    - { name: creds, mountPath: /etc/db, readOnly: true }
  volumes:
  - name: creds
    secret: { secretName: db-creds, defaultMode: 0400 }
EOF
kubectl wait --for=condition=Ready pod/sec-file --timeout=60s
kubectl logs sec-file
```

Files mounted from a Secret are tmpfs — never written to disk on the node.

---

## Step 4 — TLS Secret

```bash
openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
  -keyout tls.key -out tls.crt -subj "/CN=demo.local"
kubectl create secret tls demo-tls --cert=tls.crt --key=tls.key
kubectl get secret demo-tls -o yaml | head
```

TLS Secrets are used by Ingress, Gateway API, and webhook servers (Lab 19, 20).

---

## Step 5 — Docker-registry Secret (private image pull)

```bash
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=demo \
  --docker-password=demo123 \
  --docker-email=demo@example.com
```

Reference from a pod:

```yaml
spec:
  imagePullSecrets:
  - name: regcred
```

---

## Step 6 — Cleanup

```bash
kubectl delete pod sec-env sec-file
kubectl delete secret db-creds demo-tls regcred
rm tls.key tls.crt
```

---

## What you learned
- Generic, TLS, and docker-registry Secret types.
- Env-var vs tmpfs-mount consumption.
- Secrets are base64-encoded, not encrypted — enable EncryptionConfiguration at the API server for at-rest encryption.
