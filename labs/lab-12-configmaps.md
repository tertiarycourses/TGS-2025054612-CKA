# Lab 12 — ConfigMaps

ConfigMaps hold non-secret key/value configuration. In this lab you create a ConfigMap three ways (literal, file, manifest) and consume it in a pod as environment variables and as a mounted file.

Use the **Kubernetes playground**: https://killercoda.com/playgrounds/scenario/kubernetes

---

## Step 1 — Create from literals

```bash
kubectl create configmap app-config \
  --from-literal=APP_ENV=prod \
  --from-literal=APP_TIER=backend
kubectl get configmap app-config -o yaml
```

---

## Step 2 — Create from a file

```bash
cat > app.properties <<'EOF'
log.level=INFO
cache.ttl=300
EOF
kubectl create configmap app-properties --from-file=app.properties
kubectl describe configmap app-properties
```

---

## Step 3 — Consume as environment variables

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: env-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","env | grep APP_; sleep 3600"]
    envFrom:
    - configMapRef: { name: app-config }
EOF
kubectl wait --for=condition=Ready pod/env-demo --timeout=60s
kubectl logs env-demo
```

You should see both `APP_ENV=prod` and `APP_TIER=backend`.

---

## Step 4 — Consume as a mounted file

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: file-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","cat /etc/cfg/app.properties; sleep 3600"]
    volumeMounts:
    - { name: cfg, mountPath: /etc/cfg }
  volumes:
  - name: cfg
    configMap: { name: app-properties }
EOF
kubectl wait --for=condition=Ready pod/file-demo --timeout=60s
kubectl logs file-demo
```

---

## Step 5 — Update propagation

```bash
kubectl edit configmap app-properties   # change cache.ttl=300 to 60
kubectl exec file-demo -- cat /etc/cfg/app.properties
```

Mounted ConfigMaps update **in place** after ~30–60 s — environment variables do **not**. To pick up env var changes you must restart the pod (`kubectl rollout restart deploy/...`).

---

## Step 6 — Cleanup

```bash
kubectl delete pod env-demo file-demo
kubectl delete configmap app-config app-properties
```

---

## What you learned
- Three ways to build ConfigMaps.
- Env vs volume-mount consumption and their update semantics.
- Why `rollout restart` is needed for env-based reloads.
