# Lab 17 — Pod-to-Pod Connectivity

Every pod gets a routable IP and can reach every other pod without NAT. In this lab you prove the model end-to-end with `netshoot`, a tools-rich debug image.

Use the **Kubernetes playground**: https://killercoda.com/playgrounds/scenario/kubernetes

---

## Step 1 — Launch two debug pods

```bash
kubectl run client --image=nicolaka/netshoot --command -- sleep 3600
kubectl run server --image=nginx
kubectl wait --for=condition=Ready pod/client pod/server --timeout=60s
kubectl get pods -o wide
```

Note each pod's IP and the node it landed on.

---

## Step 2 — Ping by pod IP

```bash
SERVER_IP=$(kubectl get pod server -o jsonpath='{.status.podIP}')
kubectl exec client -- ping -c 3 $SERVER_IP
```

No SNAT, no port mapping — the pod sees its own IP.

---

## Step 3 — Curl the nginx pod directly

```bash
kubectl exec client -- curl -s -o /dev/null -w "%{http_code}\n" http://$SERVER_IP
```

Should print `200`.

---

## Step 4 — DNS-based discovery

Expose `server` as a Service:

```bash
kubectl expose pod server --port=80
kubectl exec client -- nslookup server
kubectl exec client -- curl -s -o /dev/null -w "%{http_code}\n" http://server
```

The Service name `server` resolves to a virtual ClusterIP — covered in Lab 18.

---

## Step 5 — Inspect routing inside the pod

```bash
kubectl exec client -- ip addr
kubectl exec client -- ip route
kubectl exec client -- cat /etc/resolv.conf
```

The default route points to a per-node CNI gateway; `/etc/resolv.conf` points to the CoreDNS ClusterIP.

---

## Step 6 — Traceroute across nodes (if multi-node)

```bash
kubectl exec client -- traceroute -n $SERVER_IP
```

You'll see one or two hops depending on whether the pods landed on the same node.

---

## Step 7 — Cleanup

```bash
kubectl delete pod client server
kubectl delete svc server
```

---

## What you learned
- Flat pod network with no NAT between pods.
- Pod IPs are ephemeral — use Service DNS for stability.
- How to use `netshoot` to debug from inside the cluster.
