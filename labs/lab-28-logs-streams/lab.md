# Lab 28 — Application Logs and Container Streams

Containers emit logs to `stdout` and `stderr`. The kubelet redirects these to `/var/log/pods/...`, and `kubectl logs` reads them back. In this lab you inspect single-container, multi-container, and previous-instance logs, then look at the files on disk.

**Lab environment:** *(link to be added)*
---

## Step 1 — Single-container logs

```bash
kubectl create deployment chatty --image=busybox \
  -- /bin/sh -c "i=0; while true; do echo line-\$i; i=\$((i+1)); sleep 1; done"
kubectl wait --for=condition=Available deploy/chatty --timeout=60s
POD=$(kubectl get pod -l app=chatty -o name | head -1)
kubectl logs $POD --tail=10
kubectl logs $POD -f &
sleep 5
kill %1
```

---

## Step 2 — Previous instance after a crash

```bash
kubectl run crashy --image=busybox -- /bin/sh -c "echo running; sleep 5; exit 1"
sleep 30
kubectl get pod crashy
kubectl logs crashy --previous
```

`--previous` (or `-p`) reads the last terminated container's log — invaluable when a CrashLoop hides the actual cause.

---

## Step 3 — Multi-container pod

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: multi }
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh","-c","i=0;while true;do echo writer-$i;i=$((i+1));sleep 1;done"]
  - name: reader
    image: busybox
    command: ["sh","-c","i=0;while true;do echo reader-$i;i=$((i+1));sleep 2;done"]
EOF
kubectl wait --for=condition=Ready pod/multi --timeout=60s

kubectl logs multi              # error: needs -c
kubectl logs multi -c writer --tail=5
kubectl logs multi -c reader --tail=5
kubectl logs multi --all-containers --prefix --tail=10
```

---

## Step 4 — Logs from the host

```bash
ls /var/log/pods/
ls /var/log/pods/default_multi_*/writer/
sudo tail /var/log/pods/default_multi_*/writer/0.log
```

Each line is JSON: timestamp, stream (`stdout`/`stderr`), and the raw output.

---

## Step 5 — Multi-pod tail with stern (optional)

```bash
GO111MODULE=on go install github.com/stern/stern@latest 2>/dev/null || \
  curl -L https://github.com/stern/stern/releases/download/v1.30.0/stern_1.30.0_linux_amd64.tar.gz \
    | sudo tar -xz -C /usr/local/bin stern
stern chatty --tail 5
```

Ctrl-C to stop. `stern` follows logs across pods, containers, and namespaces in one stream.

---

## Step 6 — Cleanup

```bash
kubectl delete deploy chatty
kubectl delete pod crashy multi --ignore-not-found
```

---

## What you learned
- `kubectl logs`, `-f`, `-p`, `-c`, `--all-containers`.
- The kubelet log path `/var/log/pods/<ns>_<pod>_<uid>/<container>/0.log`.
- `stern` for multi-pod tails.
