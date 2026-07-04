# Lab 25 — Volume Types in Pods

Beyond PVCs, pods can mount many in-tree volume types: `emptyDir`, `hostPath`, `configMap`, `secret`, `projected`, `downwardAPI`. In this lab you exercise each of them.

**Lab environment:** [Play with Kubernetes](https://killercoda.com/playgrounds/course/kubernetes-playgrounds/two-node)
---

## Step 1 — emptyDir (scratch space, pod lifetime)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: scratch }
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh","-c","echo hello > /data/file; sleep 3600"]
    volumeMounts: [{ name: tmp, mountPath: /data }]
  - name: reader
    image: busybox
    command: ["sh","-c","cat /data/file; sleep 3600"]
    volumeMounts: [{ name: tmp, mountPath: /data }]
  volumes:
  - name: tmp
    emptyDir: {}
EOF
kubectl wait --for=condition=Ready pod/scratch --timeout=60s
kubectl logs scratch -c reader
```

Two containers share `/data`. Deleting the pod deletes the volume.

---

## Step 2 — hostPath (node directory)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: hostpath-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","ls /host/etc/hostname; cat /host/etc/hostname; sleep 3600"]
    volumeMounts: [{ name: etc, mountPath: /host/etc, readOnly: true }]
  volumes:
  - name: etc
    hostPath: { path: /etc, type: Directory }
EOF
kubectl wait --for=condition=Ready pod/hostpath-demo --timeout=60s
kubectl logs hostpath-demo
```

⚠️ `hostPath` couples the pod to a specific node and is a security risk — admission controllers usually restrict it.

---

## Step 3 — configMap and secret as files

Done in Lab 12 and Lab 13 — re-check:

```bash
kubectl create configmap demo-cfg --from-literal=greeting=hi
kubectl create secret generic demo-sec --from-literal=token=s3cret

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: mount-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","cat /cfg/greeting /sec/token; sleep 3600"]
    volumeMounts:
    - { name: cfg, mountPath: /cfg }
    - { name: sec, mountPath: /sec }
  volumes:
  - { name: cfg, configMap: { name: demo-cfg } }
  - { name: sec, secret:    { secretName: demo-sec } }
EOF
kubectl wait --for=condition=Ready pod/mount-demo --timeout=60s
kubectl logs mount-demo
```

---

## Step 4 — projected (combine many sources)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: projected-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","ls -la /proj; cat /proj/greeting /proj/token; sleep 3600"]
    volumeMounts: [{ name: all, mountPath: /proj }]
  volumes:
  - name: all
    projected:
      sources:
      - configMap: { name: demo-cfg }
      - secret:    { name: demo-sec }
EOF
kubectl wait --for=condition=Ready pod/projected-demo --timeout=60s
kubectl logs projected-demo
```

A single mount point exposes keys from multiple ConfigMaps/Secrets/serviceAccountTokens.

---

## Step 5 — downwardAPI (pod metadata as files)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: downward-demo
  labels: { tier: web, env: prod }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","cat /info/labels /info/name; sleep 3600"]
    volumeMounts: [{ name: info, mountPath: /info }]
  volumes:
  - name: info
    downwardAPI:
      items:
      - path: labels
        fieldRef: { fieldPath: metadata.labels }
      - path: name
        fieldRef: { fieldPath: metadata.name }
EOF
kubectl wait --for=condition=Ready pod/downward-demo --timeout=60s
kubectl logs downward-demo
```

---

## Step 6 — Cleanup

```bash
kubectl delete pod scratch hostpath-demo mount-demo projected-demo downward-demo
kubectl delete configmap demo-cfg
kubectl delete secret demo-sec
```

---

## What you learned
- emptyDir for scratch, hostPath for node files (risky).
- configMap/secret/projected mounts are tmpfs and auto-updating.
- downwardAPI exposes pod metadata to the app.
