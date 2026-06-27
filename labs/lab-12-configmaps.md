# Lab 12 — ConfigMaps: Create 3 Ways, envFrom, Volume Mount, Live Update Semantics

ConfigMaps decouple configuration from container images, allowing the same image to run in dev, staging, and production with different settings. This lab creates ConfigMaps using three methods (literal, file, and YAML manifest), injects them into pods via environment variables with `envFrom`, mounts them as files in a volume, and demonstrates the live-update behavior of volume-mounted ConfigMaps versus the static nature of env-var injection.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)

---

## Step 1 — Method 1: Create ConfigMap from Literals

```bash
# Create a ConfigMap with key-value literals
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info \
  --from-literal=MAX_CONNECTIONS=100 \
  --from-literal=DB_HOST=postgres.default.svc.cluster.local

# View the ConfigMap
kubectl get configmap app-config
kubectl describe configmap app-config

# Get raw YAML
kubectl get configmap app-config -o yaml
```

`--from-literal` is the fastest way to create a ConfigMap in an exam setting. Each `key=value` pair becomes a key in the ConfigMap's `data` field.

---

## Step 2 — Method 2: Create ConfigMap from Files

```bash
# Create config files first
cat <<'EOF' > /tmp/app.properties
database.host=postgres.default.svc.cluster.local
database.port=5432
database.name=myapp
cache.ttl=3600
feature.darkmode=true
EOF

cat <<'EOF' > /tmp/nginx.conf
server {
    listen 80;
    server_name example.com;
    location / {
        proxy_pass http://backend:8080;
    }
}
EOF

# Create ConfigMap from files
kubectl create configmap file-config \
  --from-file=/tmp/app.properties \
  --from-file=/tmp/nginx.conf

# The filename becomes the key
kubectl get configmap file-config -o yaml
# Keys: app.properties, nginx.conf

# Create with a custom key name (overrides the filename as key)
kubectl create configmap custom-key-config \
  --from-file=config=/tmp/app.properties
# Key: config (not app.properties)
```

`--from-file` uses the filename as the ConfigMap key and the file content as the value. This is ideal for configuration files that applications read at a specific path.

---

## Step 3 — Method 3: Create ConfigMap from YAML Manifest

```bash
# Create ConfigMap using declarative YAML
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: manifest-config
  namespace: default
  labels:
    app: webapp
data:
  # Simple key-value pairs
  FEATURE_FLAGS: "dark_mode,beta_checkout"
  REGION: "us-east-1"
  REPLICAS: "3"

  # Multi-line value (pipe |)
  app.yaml: |
    server:
      port: 8080
      timeout: 30s
    logging:
      level: info
      format: json

  # Multi-line value (folded >)
  description: >
    This is a folded scalar.
    All lines are joined with spaces
    into a single long line.
EOF

kubectl get configmap manifest-config -o yaml
```

YAML manifests support multi-line values using `|` (literal block — preserves newlines) and `>` (folded block — joins lines with spaces). The `|` format is what you want for config files and scripts.

---

## Step 4 — Inject ConfigMap as Environment Variables (envFrom)

```bash
# Inject entire ConfigMap as env vars using envFrom
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: envfrom-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | sort && sleep infinity"]
    envFrom:
    - configMapRef:
        name: app-config
      prefix: "CONFIG_"    # Optional: prefix all keys with CONFIG_
EOF

kubectl wait --for=condition=Ready pod/envfrom-pod --timeout=60s

# All ConfigMap keys are available as environment variables
kubectl exec envfrom-pod -- env | grep CONFIG_
# CONFIG_APP_ENV=production
# CONFIG_LOG_LEVEL=info
# CONFIG_MAX_CONNECTIONS=100
# CONFIG_DB_HOST=postgres.default.svc.cluster.local
```

`envFrom` injects ALL keys from a ConfigMap as environment variables. The `prefix` field adds a namespace to prevent collisions. Env var names must be valid — keys with dots (`.`) are NOT valid env var names and will be silently skipped.

---

## Step 5 — Inject Specific ConfigMap Keys as Env Vars

```bash
# Inject only specific keys, with custom variable names
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: selective-env-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | grep -E 'LOGLEVEL|MAXCONN|APPENV' && sleep infinity"]
    env:
    - name: APPENV           # Custom env var name
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV       # Specific key from ConfigMap
    - name: LOGLEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: LOG_LEVEL
    - name: MAXCONN
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: MAX_CONNECTIONS
          optional: true     # Don't fail if key doesn't exist
EOF

kubectl wait --for=condition=Ready pod/selective-env-pod --timeout=60s
kubectl exec selective-env-pod -- env | grep -E 'LOGLEVEL|MAXCONN|APPENV'
```

`valueFrom.configMapKeyRef` lets you inject individual keys and rename them as environment variables. This is more explicit than `envFrom` and is preferred when you only need a subset of the ConfigMap.

---

## Step 6 — Mount ConfigMap as a Volume

```bash
# Mount entire ConfigMap as files in a directory
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: volume-mount-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "ls /config && cat /config/APP_ENV && sleep infinity"]
    volumeMounts:
    - name: config-vol
      mountPath: /config
  volumes:
  - name: config-vol
    configMap:
      name: app-config
EOF

kubectl wait --for=condition=Ready pod/volume-mount-pod --timeout=60s

# Each key becomes a file; the value is the file content
kubectl exec volume-mount-pod -- ls /config
# APP_ENV  DB_HOST  LOG_LEVEL  MAX_CONNECTIONS

kubectl exec volume-mount-pod -- cat /config/LOG_LEVEL
# info
```

When a ConfigMap is mounted as a volume, each key becomes a file with the key name as the filename and the value as the file content. This is ideal for applications that read configuration from files.

---

## Step 7 — Mount Specific ConfigMap Keys as Files

```bash
# Mount only specific keys, with custom filenames and permissions
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: selective-vol-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/conf.d/
      readOnly: true
  volumes:
  - name: nginx-config
    configMap:
      name: file-config
      items:
      - key: nginx.conf      # The ConfigMap key
        path: default.conf   # The filename in the mounted directory
        mode: 0644           # File permissions
EOF

kubectl wait --for=condition=Ready pod/selective-vol-pod --timeout=60s
kubectl exec selective-vol-pod -- cat /etc/nginx/conf.d/default.conf
```

The `items` list in a volume ConfigMap mount lets you select specific keys and customize their filenames and permissions. This is how you inject a custom nginx.conf or application.properties into a container.

---

## Step 8 — Mount at a Specific File Path (subPath)

```bash
# Mount a single ConfigMap key as a specific file (not a directory)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: subpath-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/conf.d/custom.conf  # Full file path
      subPath: nginx.conf                         # The key in the ConfigMap
  volumes:
  - name: nginx-config
    configMap:
      name: file-config
EOF

kubectl wait --for=condition=Ready pod/subpath-pod --timeout=60s
kubectl exec subpath-pod -- ls /etc/nginx/conf.d/
# custom.conf  default.conf  (custom.conf is our ConfigMap-backed file)
```

`subPath` mounts a single key as a specific file rather than replacing the entire directory. This allows injecting one config file into a directory that already contains other files.

---

## Step 9 — Live Update Semantics (Key CKA Concept)

```bash
# IMPORTANT: Understanding live update behavior is tested on CKA

# SCENARIO 1: Volume-mounted ConfigMap — LIVE UPDATE (eventually consistent)
# Update the ConfigMap
kubectl patch configmap app-config \
  --type=merge \
  -p '{"data":{"LOG_LEVEL":"debug"}}'

# Wait for kubelet to sync (default sync period: 1-2 minutes)
echo "Waiting for kubelet to sync ConfigMap changes..."
sleep 90

# Check if the file updated in the volume-mounted pod
kubectl exec volume-mount-pod -- cat /config/LOG_LEVEL
# debug (updated without pod restart!)

# SCENARIO 2: Environment variable — DOES NOT live update
kubectl exec selective-env-pod -- env | grep LOGLEVEL
# LOGLEVEL=info  (still the old value)
# Pod MUST be restarted to pick up env var changes

# EXCEPTION: subPath mounts do NOT update live (treated like env vars)
kubectl exec subpath-pod -- cat /etc/nginx/conf.d/custom.conf
# Still shows old content — subPath mounts are NOT live
```

Live update behavior is a critical exam topic: volume-mounted ConfigMaps (without subPath) update automatically; environment variables and subPath mounts require a pod restart. The update propagation takes up to `syncPeriod` (default: 1 minute) + TTL time.

---

## Step 10 — Immutable ConfigMaps

```bash
# Immutable ConfigMaps improve performance and safety
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
data:
  DB_URL: "postgres://prod-db:5432/myapp"
  API_KEY: "prod-key-12345"
immutable: true
EOF

# Try to update an immutable ConfigMap (will fail)
kubectl patch configmap immutable-config \
  --type=merge \
  -p '{"data":{"DB_URL":"new-url"}}' 2>&1
# Error: cannot update immutable configmap

# Immutable ConfigMaps cannot be updated — you must delete and recreate
# This prevents accidental configuration drift in production

# Verify
kubectl get configmap immutable-config -o yaml | grep immutable
```

Immutable ConfigMaps prevent accidental changes and reduce API server load by not watching for updates. Once set to `immutable: true`, the data field cannot be changed — only the ConfigMap can be deleted and recreated.

---

## Step 11 — Clean Up

```bash
kubectl delete pod envfrom-pod selective-env-pod volume-mount-pod selective-vol-pod subpath-pod
kubectl delete configmap app-config file-config manifest-config custom-key-config immutable-config
```

---

## Free online tools
- **Kubernetes Docs — ConfigMaps**: https://kubernetes.io/docs/concepts/configuration/configmap/
- **Kubernetes Docs — Configure Pods with ConfigMaps**: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- ConfigMaps can be created three ways: `--from-literal`, `--from-file`, or declarative YAML manifest
- `envFrom.configMapRef` injects all ConfigMap keys as environment variables; `prefix` namespaces them
- `env.valueFrom.configMapKeyRef` injects a specific key with a custom environment variable name
- Keys with dots (e.g., `app.properties`) are invalid as env var names and are silently skipped
- Volume-mounted ConfigMaps: each key becomes a file; the entire ConfigMap directory is mounted
- `items` in a volume mount allows selecting specific keys and customizing filenames and permissions
- `subPath` mounts a single key as a specific file path without replacing the parent directory
- Live updates: volume mounts update automatically (1-2 min delay); env vars and subPath mounts DO NOT
- `immutable: true` prevents modifications and reduces API server watch load
- To update immutable ConfigMaps or env-var-injected configs, delete the pod and recreate it
