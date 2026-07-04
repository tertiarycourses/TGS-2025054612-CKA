# Lab 30 — Troubleshoot Services and Networking

Service connectivity bugs are the single biggest category of CKA exam questions. In this lab you walk the chain Pod → Service → DNS → Endpoint and fix three intentional faults.

**Lab environment:** *(link to be added)*
---

## Step 1 — Build a normal service

```bash
kubectl create deployment web --image=nginx --replicas=2
kubectl expose deploy web --port=80
kubectl run probe --image=nicolaka/netshoot --command -- sleep 3600
kubectl wait --for=condition=Ready pod/probe --timeout=60s
kubectl exec probe -- curl -s -o /dev/null -w "%{http_code}\n" http://web
```

Baseline: should print `200`.

---

## Step 2 — Fault 1: selector mismatch

```bash
kubectl patch svc web --type=merge -p '{"spec":{"selector":{"app":"wrong"}}}'
kubectl exec probe -- curl -s --max-time 3 http://web || echo TIMEOUT
kubectl get endpoints web
```

`ENDPOINTS` is empty. The selector no longer matches any pod.

Fix:

```bash
kubectl patch svc web --type=merge -p '{"spec":{"selector":{"app":"web"}}}'
kubectl get endpoints web
```

---

## Step 3 — Fault 2: targetPort mismatch

```bash
kubectl patch svc web --type=merge -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'
kubectl exec probe -- curl -s --max-time 3 http://web || echo FAIL
```

Endpoints are populated, but the wrong port — connection refused.

```bash
kubectl describe svc web | grep -E "Port:|TargetPort"
kubectl exec probe -- curl -s -o /dev/null -w "%{http_code}\n" http://$(kubectl get pod -l app=web -o jsonpath='{.items[0].status.podIP}'):80
```

Fix:

```bash
kubectl patch svc web --type=merge -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'
```

---

## Step 4 — Fault 3: CoreDNS or resolv.conf

Simulate a busted DNS by scaling CoreDNS to zero:

```bash
kubectl -n kube-system scale deploy coredns --replicas=0
kubectl exec probe -- nslookup web 2>&1 | head -5
kubectl exec probe -- curl -s --max-time 3 http://web || echo DNS_DEAD
# pod IP still works
kubectl exec probe -- curl -s -o /dev/null -w "%{http_code}\n" \
  http://$(kubectl get pod -l app=web -o jsonpath='{.items[0].status.podIP}')
```

Restore:

```bash
kubectl -n kube-system scale deploy coredns --replicas=2
kubectl -n kube-system rollout status deploy coredns
```

---

## Step 5 — The triage chain

When `curl <svc>` fails inside a pod:

```bash
# 1) Does DNS resolve?
kubectl exec probe -- nslookup web

# 2) Does the Service have endpoints?
kubectl get endpoints web

# 3) Does the pod match the selector?
kubectl get pods --show-labels -l app=web

# 4) Does the targetPort match the container?
kubectl describe svc web | grep -E "Port|TargetPort"
kubectl get pod -l app=web -o jsonpath='{.items[0].spec.containers[0].ports[*].containerPort}{"\n"}'

# 5) Pod IP reachable from probe?
kubectl exec probe -- curl --max-time 3 http://$(kubectl get pod -l app=web -o jsonpath='{.items[0].status.podIP}'):80

# 6) NetworkPolicy blocking?
kubectl get networkpolicy -A

# 7) kube-proxy alive?
kubectl -n kube-system get pods -l k8s-app=kube-proxy
```

---

## Step 6 — Cleanup

```bash
kubectl delete deploy web
kubectl delete svc web
kubectl delete pod probe
```

---

## What you learned
- The seven-step triage chain from DNS to kube-proxy.
- `kubectl get endpoints` is the single most useful Service-debug command.
- CoreDNS failure looks like everything else broken — verify DNS first.
