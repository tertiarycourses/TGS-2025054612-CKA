# Lab 30 — Troubleshoot Networking

Networking failures in Kubernetes have seven root causes. CKA 2026 tests a structured 7-step triage chain: DNS → Service → Endpoints → CNI → NetworkPolicy → kube-proxy → and node routing. This lab breaks each layer intentionally and shows how to find the fault.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `nicolaka/netshoot` debug image (pulled automatically)
- `nginx`, `busybox` images (pre-pulled on Killercoda)

---

## Step 1 — Deploy baseline workload

```bash
kubectl create deployment app --image=nginx --replicas=2
kubectl expose deploy app --port=80 --name=app-svc
kubectl wait --for=condition=Ready pod -l app=app --timeout=60s
kubectl get svc app-svc
kubectl get endpoints app-svc
```

Launch a debug Pod used throughout this lab:

```bash
kubectl run dbg --image=nicolaka/netshoot --command -- sleep 3600
kubectl wait --for=condition=Ready pod/dbg --timeout=60s
```

---

## Step 2 — Step 1 of 7: DNS resolution

```bash
kubectl exec dbg -- nslookup app-svc
kubectl exec dbg -- nslookup app-svc.default.svc.cluster.local
kubectl exec dbg -- nslookup kubernetes.default
```

If DNS fails → check CoreDNS Pods:

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system logs -l k8s-app=kube-dns | tail -10
```

---

## Step 3 — Step 2 of 7: Service exists and has correct port

```bash
kubectl get svc app-svc -o yaml | grep -A5 "ports:"
kubectl exec dbg -- curl -s -o /dev/null -w "%{http_code}" http://app-svc
```

Break it:

```bash
kubectl patch svc app-svc --type=json \
  -p='[{"op":"replace","path":"/spec/ports/0/port","value":9999}]'
kubectl exec dbg -- curl -s --max-time 3 http://app-svc || echo "BROKEN"
```

Fix:

```bash
kubectl patch svc app-svc --type=json \
  -p='[{"op":"replace","path":"/spec/ports/0/port","value":80}]'
```

---

## Step 4 — Step 3 of 7: Endpoints are populated

```bash
kubectl get endpoints app-svc
```

Break it by changing the selector to a label that doesn't exist:

```bash
kubectl patch svc app-svc --type=merge \
  -p='{"spec":{"selector":{"app":"wrong-label"}}}'
kubectl get endpoints app-svc
```

Empty Endpoints → selector mismatch. Fix:

```bash
kubectl patch svc app-svc --type=merge \
  -p='{"spec":{"selector":{"app":"app"}}}'
kubectl get endpoints app-svc
```

---

## Step 5 — Step 4 of 7: Pod is Ready and port is open

```bash
kubectl get pods -l app=app -o wide
APP_POD=$(kubectl get pod -l app=app -o jsonpath='{.items[0].metadata.name}')
APP_IP=$(kubectl get pod $APP_POD -o jsonpath='{.status.podIP}')
kubectl exec dbg -- curl -s -o /dev/null -w "%{http_code}" http://$APP_IP
```

If the Pod IP is reachable but the Service isn't, jump to kube-proxy (Step 7).

---

## Step 6 — Step 5 of 7: NetworkPolicy is not blocking

```bash
kubectl get networkpolicy -A
```

If a policy exists that targets these Pods, test by temporarily adding the `dbg` pod's label to the allow list (see Lab 21 for details).

---

## Step 7 — Step 6 of 7: kube-proxy and iptables rules

```bash
kubectl -n kube-system get pods -l k8s-app=kube-proxy
SVCIP=$(kubectl get svc app-svc -o jsonpath='{.spec.clusterIP}')
sudo iptables -t nat -L KUBE-SERVICES -n | grep $SVCIP
```

If no rule exists for the ClusterIP → kube-proxy is not running or has an error.

---

## Step 8 — Step 7 of 7: CNI plugin health

```bash
kubectl -n kube-system get pods | grep -E "calico|flannel|weave|cilium"
kubectl -n kube-system describe pod -l k8s-app=calico-node | grep -A5 Conditions
```

A Pending or CrashLoopBackOff CNI pod means Pod networking is broken cluster-wide.

---

## Step 9 — 7-step triage cheatsheet

| Step | Check | Command |
|------|-------|---------|
| 1 | DNS | `nslookup <svc>` |
| 2 | Service port | `kubectl get svc -o yaml` |
| 3 | Endpoints | `kubectl get endpoints <svc>` |
| 4 | Pod Ready + port | `curl http://<pod-ip>` |
| 5 | NetworkPolicy | `kubectl get netpol -A` |
| 6 | kube-proxy | `iptables -t nat -L KUBE-SERVICES` |
| 7 | CNI | `kubectl -n kube-system get pods` |

---

## Step 10 — Clean up

```bash
kubectl delete deploy app
kubectl delete svc app-svc
kubectl delete pod dbg --force --grace-period=0
```

---

## Free online tools

- **Debug services**: https://kubernetes.io/docs/tasks/debug/debug-service/
- **DNS debugging**: https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
- **netshoot**: https://github.com/nicolaka/netshoot
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- Empty Endpoints means selector mismatch — compare `svc.spec.selector` with Pod labels.
- DNS failure means CoreDNS is down — `kubectl -n kube-system logs -l k8s-app=kube-dns`.
- kube-proxy writes iptables/IPVS rules; if missing, ClusterIPs don't route.
- Use the 7-step chain top-down: DNS → Service → Endpoints → Pod → Policy → kube-proxy → CNI.
