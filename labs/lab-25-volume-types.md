# Lab 25 — Volume Types in Pods

Beyond PVCs, Pods can mount many in-tree volume types: `emptyDir`, `hostPath`, `configMap`, `secret`, `projected`, and `downwardAPI`. CKA 2026 tests all of these — especially `projected` (combining multiple sources) and `downwardAPI` (exposing Pod metadata to the application).

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `busybox` image (pre-pulled on Killercoda)

---

## Step 1 — emptyDir: shared scratch space within a Pod

```bash
cat > emptydir.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: scratch
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh", "-c", "echo hello-shared > /data/file; sleep 3600"]
    volumeMounts:
    - name: tmp
      mountPath: /data
  - name: reader
    image: busybox
    command: ["sh", "-c", "sleep 2; cat /data/file; sleep 3600"]
    volumeMounts:
    - name: tmp
      mountPath: /data
  volumes:
  - name: tmp
    emptyDir: {}
EOF
kubectl apply -f emptydir.yaml
sleep 5
kubectl logs scratch -c reader
```

Expected: `hello-shared`. The volume is created at Pod start and deleted when the Pod is removed.

---

## Step 2 — hostPath: mount a node directory

```bash
cat > hostpath.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "cat /host/etc/hostname; sleep 3600"]
    volumeMounts:
    - name: etc
      mountPath: /host/etc
      readOnly: true
  volumes:
  - name: etc
    hostPath:
      path: /etc
      type: Directory
EOF
kubectl apply -f hostpath.yaml
sleep 3
kubectl logs hostpath-demo
```

`hostPath` couples the Pod to a specific node — use only in DaemonSets or for node-level tools.

---

## Step 3 — configMap and secret as volume mounts

```bash
kubectl create configmap demo-cfg --from-literal=greeting=hello-cka
kubectl create secret generic demo-sec --from-literal=token=s3cret-token

cat > mount-demo.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: mount-demo
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "cat /cfg/greeting; echo; cat /sec/token; sleep 3600"]
    volumeMounts:
    - name: cfg
      mountPath: /cfg
    - name: sec
      mountPath: /sec
      readOnly: true
  volumes:
  - name: cfg
    configMap:
      name: demo-cfg
  - name: sec
    secret:
      secretName: demo-sec
      defaultMode: 0400
EOF
kubectl apply -f mount-demo.yaml
sleep 3
kubectl logs mount-demo
```

Secret files are mounted as tmpfs — never written to node disk.

---

## Step 4 — projected: combine multiple sources in one mount

```bash
cat > projected.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: projected-demo
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "ls /proj; cat /proj/greeting; echo; cat /proj/token; sleep 3600"]
    volumeMounts:
    - name: all
      mountPath: /proj
  volumes:
  - name: all
    projected:
      sources:
      - configMap:
          name: demo-cfg
      - secret:
          name: demo-sec
EOF
kubectl apply -f projected.yaml
sleep 3
kubectl logs projected-demo
```

A `projected` volume merges ConfigMaps, Secrets, and ServiceAccount tokens into a single mount point.

---

## Step 5 — downwardAPI: expose Pod metadata to the container

```bash
cat > downward.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: downward-demo
  labels:
    tier: web
    env: prod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "cat /info/labels; echo; cat /info/podname; sleep 3600"]
    volumeMounts:
    - name: info
      mountPath: /info
  volumes:
  - name: info
    downwardAPI:
      items:
      - path: labels
        fieldRef:
          fieldPath: metadata.labels
      - path: podname
        fieldRef:
          fieldPath: metadata.name
EOF
kubectl apply -f downward.yaml
sleep 3
kubectl logs downward-demo
```

`downwardAPI` exposes Pod metadata (labels, name, namespace, UID) and resource fields as files — useful for apps that need to know their own identity.

---

## Step 6 — Clean up

```bash
kubectl delete pod scratch hostpath-demo mount-demo projected-demo downward-demo \
  --force --grace-period=0
kubectl delete configmap demo-cfg
kubectl delete secret demo-sec
```

---

## Free online tools

- **Volumes docs**: https://kubernetes.io/docs/concepts/storage/volumes/
- **Projected volumes**: https://kubernetes.io/docs/concepts/storage/projected-volumes/
- **Downward API**: https://kubernetes.io/docs/concepts/workloads/pods/downward-api/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- `emptyDir` — ephemeral, Pod-scoped, shared between containers.
- `hostPath` — node directory mount; risky in production, useful in DaemonSets.
- `configMap`/`secret` mounts are tmpfs and update live (within ~60s).
- `projected` merges multiple ConfigMaps, Secrets, and token sources into one mount.
- `downwardAPI` exposes Pod metadata (labels, name, namespace) as files.
