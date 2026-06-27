# Lab 13 — Secrets: generic/tls/docker-registry, Env Inject, tmpfs Mount defaultMode 0400, base64 Decode

Kubernetes Secrets store sensitive data (passwords, TLS keys, API tokens) separately from application code. This lab creates secrets of three types — generic, TLS, and docker-registry — injects them into pods via environment variables, mounts them as tmpfs-backed files with restrictive permissions (mode 0400), and demonstrates base64 decoding. Understanding Secret security properties and access patterns is tested in both the Workloads and Troubleshooting domains.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)
- openssl (pre-installed)

---

## Step 1 — Understand Secret Security Properties

```bash
# IMPORTANT: Secrets in Kubernetes are NOT encrypted by default
# They are base64-encoded and stored in etcd as plaintext unless:
# 1. etcd encryption at rest is enabled (EncryptionConfiguration)
# 2. External secret manager is used (Vault, AWS Secrets Manager)

# Secrets are protected by:
# - RBAC (who can GET/LIST secrets)
# - Namespace isolation
# - Node-level access control (kubelet only gets secrets for pods on that node)

# View secrets in the default namespace
kubectl get secrets

# Every namespace has a default service account token secret
kubectl get secret -n kube-system | head -10

# Base64 encoding (NOT encryption):
echo -n "mypassword" | base64
# bXlwYXNzd29yZA==
echo "bXlwYXNzd29yZA==" | base64 -d
# mypassword
```

Base64 is encoding, not encryption. Anyone with kubectl `get secret` permission can read all secret values. Enable RBAC to restrict who can access secrets, and enable etcd encryption at rest for defense in depth.

---

## Step 2 — Create a Generic Secret (from Literals)

```bash
# Create a generic secret from literal key-value pairs
kubectl create secret generic db-credentials \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=SuperSecret123! \
  --from-literal=DB_HOST=postgres.default.svc.cluster.local

# View the secret (values are base64-encoded)
kubectl get secret db-credentials -o yaml

# Decode all values
kubectl get secret db-credentials -o jsonpath='{.data}' | \
  python3 -c "
import json, sys, base64
d = json.load(sys.stdin)
for k, v in d.items():
    print(f'{k}: {base64.b64decode(v).decode()}')
"

# Shortcut to decode a single key
kubectl get secret db-credentials \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# SuperSecret123!
```

The `kubectl get secret -o yaml` command shows base64-encoded values. Always decode with `base64 -d` to verify the actual content. This is important for troubleshooting when an application reports "invalid credentials."

---

## Step 3 — Create a Generic Secret from Files

```bash
# Create files containing sensitive data
echo -n "prod-api-key-abc123xyz" > /tmp/api-key.txt
echo -n "prod-db-password-xyz789" > /tmp/db-pass.txt

# Create secret from files
kubectl create secret generic api-credentials \
  --from-file=api-key=/tmp/api-key.txt \
  --from-file=db-password=/tmp/db-pass.txt

# View
kubectl get secret api-credentials -o jsonpath='{.data.api-key}' | base64 -d
# prod-api-key-abc123xyz

# Create from YAML (base64 encode manually)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: manual-secret
type: Opaque
data:
  username: $(echo -n 'admin' | base64)
  password: $(echo -n 'P@ssw0rd!' | base64)
EOF
```

Note the `echo -n` flag — without `-n`, echo adds a trailing newline that gets encoded into the base64 value, causing authentication failures.

---

## Step 4 — Create a TLS Secret

```bash
# Generate a self-signed TLS certificate and key
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /tmp/tls.key \
  -out /tmp/tls.crt \
  -days 365 \
  -subj "/CN=webapp.example.com/O=ExampleCorp"

# Create TLS secret from the cert and key files
kubectl create secret tls webapp-tls \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key

# View the TLS secret
kubectl get secret webapp-tls -o yaml
# Type: kubernetes.io/tls
# Keys: tls.crt, tls.key

# Decode and inspect the certificate
kubectl get secret webapp-tls \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | \
  openssl x509 -noout -text | grep -E 'Subject:|Not After'
```

TLS secrets have type `kubernetes.io/tls` and always use the keys `tls.crt` and `tls.key`. Ingress controllers and TLS-terminating services expect this exact secret type and key names.

---

## Step 5 — Create a Docker Registry Secret

```bash
# Create a secret for pulling images from a private registry
kubectl create secret docker-registry my-registry-secret \
  --docker-server=registry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myuser@example.com

# View the secret
kubectl get secret my-registry-secret -o yaml
# Type: kubernetes.io/dockerconfigjson

# Decode the docker config JSON
kubectl get secret my-registry-secret \
  -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | python3 -m json.tool

# Use the registry secret in a pod
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
spec:
  imagePullSecrets:
  - name: my-registry-secret     # Reference the registry secret
  containers:
  - name: app
    image: registry.example.com/myapp:latest
    command: ["echo", "hello"]
EOF
```

`imagePullSecrets` in the pod spec (or service account) configures the registry credentials kubelet uses when pulling private images. Without this, private image pulls fail with `ErrImagePull`.

---

## Step 6 — Inject Secret as Environment Variables

```bash
# Create a test pod that injects the db-credentials secret
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: env-secret-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | grep DB && sleep infinity"]
    env:
    - name: DB_USER              # Env var name in the container
      valueFrom:
        secretKeyRef:
          name: db-credentials   # Secret name
          key: DB_USER           # Key in the secret
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: DB_PASSWORD
    - name: DB_HOST
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: DB_HOST
          optional: false        # Pod fails if this key doesn't exist
EOF

kubectl wait --for=condition=Ready pod/env-secret-pod --timeout=60s
kubectl exec env-secret-pod -- env | grep DB
# DB_USER=admin
# DB_PASSWORD=SuperSecret123!
# DB_HOST=postgres.default.svc.cluster.local

# Inject all keys at once with envFrom
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: envfrom-secret-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "infinity"]
    envFrom:
    - secretRef:
        name: db-credentials
EOF
```

Secrets injected as environment variables appear in plaintext in the container's environment. Anyone who can `kubectl exec` into the pod can read them. For higher security, use volume mounts with restrictive permissions.

---

## Step 7 — Mount Secret as tmpfs Volume with defaultMode 0400

```bash
# Mount secret as files — backed by tmpfs (in-memory, not written to disk)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "ls -la /secrets && cat /secrets/DB_PASSWORD && sleep infinity"]
    volumeMounts:
    - name: secret-vol
      mountPath: /secrets
      readOnly: true             # Mount as read-only
  volumes:
  - name: secret-vol
    secret:
      secretName: db-credentials
      defaultMode: 0400          # -r-------- (owner read only)
      # Optional: mount only specific keys
      # items:
      # - key: DB_PASSWORD
      #   path: password
      #   mode: 0400
EOF

kubectl wait --for=condition=Ready pod/secret-volume-pod --timeout=60s

# Check file permissions and content
kubectl exec secret-volume-pod -- ls -la /secrets
# -r-------- 1 root root ... DB_HOST
# -r-------- 1 root root ... DB_PASSWORD
# -r-------- 1 root root ... DB_USER

kubectl exec secret-volume-pod -- cat /secrets/DB_PASSWORD
# SuperSecret123!

# Verify it's tmpfs (in-memory, not on disk)
kubectl exec secret-volume-pod -- df -h /secrets
# tmpfs  ... (tmpfs filesystem)
```

`defaultMode: 0400` makes files readable only by the owner (root). tmpfs means the secrets are never written to the node's disk — they exist only in memory, reducing the risk of data leakage from node disk forensics.

---

## Step 8 — Verify tmpfs is Not on Disk

```bash
# From the node, verify secrets are NOT on the disk filesystem
# Secret volume mounts use tmpfs backed by the kubelet's memory

# On the node, check mount types for a running pod
# (requires node access — for understanding only)
# cat /proc/mounts | grep secret

# From inside the pod, confirm tmpfs
kubectl exec secret-volume-pod -- mount | grep /secrets
# tmpfs on /secrets type tmpfs (ro,relatime)

# The secret data never touches the node's disk
# This is one security advantage of volume mounts over environment variables
# Env vars may be exposed via /proc/<pid>/environ on the node
```

tmpfs mounts are stored in the node's RAM. If the node is compromised, secret data may be read from memory, but it cannot be recovered from disk forensics after the pod terminates.

---

## Step 9 — Use Secrets in a Real Application (nginx with TLS)

```bash
# Create a pod that serves TLS using the webapp-tls secret
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: tls-nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 443
    volumeMounts:
    - name: tls-certs
      mountPath: /etc/nginx/ssl
      readOnly: true
    - name: nginx-config
      mountPath: /etc/nginx/conf.d
  volumes:
  - name: tls-certs
    secret:
      secretName: webapp-tls
      defaultMode: 0400
  - name: nginx-config
    configMap:
      name: nginx-tls-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-tls-config
data:
  default.conf: |
    server {
        listen 443 ssl;
        ssl_certificate /etc/nginx/ssl/tls.crt;
        ssl_certificate_key /etc/nginx/ssl/tls.key;
        location / {
            return 200 "Hello TLS!\n";
        }
    }
EOF

kubectl wait --for=condition=Ready pod/tls-nginx-pod --timeout=60s

# Test TLS (use -k to skip cert verification for self-signed)
POD_IP=$(kubectl get pod tls-nginx-pod -o jsonpath='{.status.podIP}')
kubectl run tls-test --image=curlimages/curl --restart=Never \
  -- curl -k https://$POD_IP/
```

This demonstrates combining a TLS Secret (for the certificate) with a ConfigMap (for nginx config) to create a complete HTTPS server without embedding any sensitive data in the container image.

---

## Step 10 — Secret Best Practices

```bash
# 1. Restrict who can read secrets (RBAC)
kubectl create role secret-reader \
  --verb=get,list \
  --resource=secrets \
  -n default

# 2. Use separate secrets per application (not one giant secret)
# Bad:  kubectl create secret generic all-secrets --from-literal=key1=... --from-literal=key2=...
# Good: One secret per application component

# 3. Enable etcd encryption at rest
# Add EncryptionConfiguration to /etc/kubernetes/manifests/kube-apiserver.yaml
# --encryption-provider-config=/etc/kubernetes/enc/enc.yaml

# 4. Use Immutable secrets for production
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: immutable-prod-secret
type: Opaque
immutable: true
data:
  API_KEY: $(echo -n 'prod-key-xyz' | base64)
EOF

# 5. Rotate secrets by creating a new secret and updating pod references
# Then delete the old secret

# Clean up
kubectl delete pod env-secret-pod envfrom-secret-pod secret-volume-pod tls-nginx-pod tls-test private-image-pod 2>/dev/null
kubectl delete secret db-credentials api-credentials manual-secret webapp-tls my-registry-secret immutable-prod-secret 2>/dev/null
kubectl delete configmap nginx-tls-config 2>/dev/null
```

---

## Free online tools
- **Kubernetes Docs — Secrets**: https://kubernetes.io/docs/concepts/configuration/secret/
- **Kubernetes Docs — Distribute Credentials**: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- Secrets are base64-encoded (NOT encrypted) by default; enable etcd encryption at rest for actual security
- Three secret types: `Opaque` (generic), `kubernetes.io/tls` (TLS), `kubernetes.io/dockerconfigjson` (registry)
- `echo -n` is critical when piping to `base64` — without `-n`, trailing newlines corrupt the encoded value
- `kubectl get secret -o jsonpath='{.data.key}' | base64 -d` decodes a specific secret key
- `secretKeyRef` injects individual keys; `secretRef` in `envFrom` injects all keys as env vars
- Secret volume mounts use tmpfs — stored in RAM, never written to node disk
- `defaultMode: 0400` sets `-r--------` permissions on secret files
- Env-var-injected secrets appear in `/proc/<pid>/environ` on the node; volume mounts are safer
- `imagePullSecrets` in pod spec configures credentials for pulling private container images
- Use separate secrets per application; use `immutable: true` for production secrets to prevent drift
