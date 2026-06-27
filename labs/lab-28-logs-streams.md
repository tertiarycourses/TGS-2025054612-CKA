# Lab 28 — Application Logs and Container Streams

Containers emit logs to stdout/stderr. The kubelet writes them to `/var/log/pods/` and `kubectl logs` reads them back. CKA 2026 tests reading logs from crashed containers, multi-container Pods, raw log files on disk, and using `stern` for multi-Pod tailing.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `busybox` image (pre-pulled on Killercoda)
- `stern` (installed in Step 5 — one command)

---

## Step 1 — Set exam aliases

```bash
alias k=kubectl
```

---

## Step 2 — Single-container logs

```bash
k run noisy --image=busybox --restart=Never -- sh -c \
  'i=0; while true; do echo "line $i at $(date)"; i=$((i+1)); sleep 1; done'
sleep 5
k logs noisy --tail=5
k logs noisy --tail=10 --timestamps=true
```

`--timestamps=true` adds RFC3339 timestamps to every line — useful for correlating events.

---

## Step 3 — Follow logs in real time

```bash
k logs -f noisy &
sleep 5
kill %1
```

`-f` streams new log lines live — equivalent to `tail -f`.

---

## Step 4 — Retrieve logs from a crashed container

```bash
k run crasher --image=busybox --restart=Always -- sh -c \
  'echo "starting up"; sleep 2; echo "about to crash"; exit 1'
sleep 30
k get pod crasher
k logs crasher --previous | head -5
k describe pod crasher | grep -A4 "Last State"
```

`--previous` (or `-p`) retrieves logs from the last terminated container instance. Essential for diagnosing CrashLoopBackOff.

---

## Step 5 — Multi-container Pod logs

```bash
cat > multi.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: multi
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh", "-c", "while true; do echo WRITER $(date); sleep 1; done"]
  - name: reader
    image: busybox
    command: ["sh", "-c", "while true; do echo READER $(date); sleep 2; done"]
EOF
k apply -f multi.yaml
sleep 5
k logs multi -c writer | head -3
k logs multi -c reader | head -3
k logs multi --all-containers=true --prefix=true | head -8
```

`--prefix=true` adds `[pod/container]` labels to each line when reading multiple containers.

---

## Step 6 — Raw log files on disk (node-level access)

```bash
POD_UID=$(k get pod noisy -o jsonpath='{.metadata.uid}')
sudo ls /var/log/pods/default_noisy_${POD_UID}/noisy/
sudo tail -3 /var/log/pods/default_noisy_${POD_UID}/noisy/0.log
```

Raw logs are JSON-formatted with `time`, `stream`, and `log` fields. This is how monitoring agents (Fluent Bit, Filebeat) consume logs directly from the node.

---

## Step 7 — Install stern for multi-Pod log tailing

```bash
curl -sL https://github.com/stern/stern/releases/latest/download/stern_linux_amd64.tar.gz \
  | tar xz stern && sudo mv stern /usr/local/bin/
stern --version
```

```bash
k create deployment fleet --image=busybox --replicas=3 \
  -- sh -c 'while true; do echo $(hostname); sleep 1; done'
sleep 5
stern fleet --tail=3 --color=never
```

`stern` tails all Pods matching a name prefix — one command instead of three `kubectl logs` calls.

---

## Step 8 — Clean up

```bash
k delete pod noisy crasher multi --force --grace-period=0
k delete deployment fleet
```

---

## Free online tools

- **kubectl logs reference**: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_logs/
- **Logging architecture**: https://kubernetes.io/docs/concepts/cluster-administration/logging/
- **stern**: https://github.com/stern/stern
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- `kubectl logs --tail=N --timestamps=true` for recent, timestamped logs.
- `--previous` retrieves logs from the last crashed container — primary CrashLoopBackOff tool.
- `-c <container>` and `--all-containers=true --prefix=true` for multi-container Pods.
- Raw logs live at `/var/log/pods/<namespace>_<pod>_<uid>/<container>/0.log` in JSON format.
- `stern` tails multiple Pods simultaneously by name prefix.
