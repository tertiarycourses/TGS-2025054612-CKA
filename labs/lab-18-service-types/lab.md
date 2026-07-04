# Lab 18 — Service Types: ClusterIP, NodePort, LoadBalancer

In this lab you expose the same Deployment with each of the three primary Service types and inspect the resulting Endpoints.

**Lab environment:** *(link to be added)*
---

## Step 1 — Deploy a workload

```bash
kubectl create deployment web --image=nginx --replicas=3
kubectl rollout status deploy/web
kubectl get pods -l app=web -o wide
```

---

## Step 2 — ClusterIP (default)

```bash
kubectl expose deploy web --port=80 --name=web-clusterip
kubectl get svc web-clusterip
kubectl get endpoints web-clusterip
CIP=$(kubectl get svc web-clusterip -o jsonpath='{.spec.clusterIP}')
kubectl run probe --image=busybox --rm -it --restart=Never -- wget -qO- $CIP | head -5
```

ClusterIP is in-cluster only. The Endpoints object lists the three pod IPs that kube-proxy load-balances over.

---

## Step 3 — NodePort

```bash
kubectl expose deploy web --port=80 --type=NodePort --name=web-nodeport
kubectl get svc web-nodeport
PORT=$(kubectl get svc web-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
curl -s http://localhost:$PORT | head -5
```

NodePort opens the same high-numbered port on every node and forwards to the ClusterIP.

---

## Step 4 — LoadBalancer

```bash
kubectl expose deploy web --port=80 --type=LoadBalancer --name=web-lb
kubectl get svc web-lb
```

On a cloud cluster, the cloud-controller-manager allocates an external IP. On Killercoda / bare metal the `EXTERNAL-IP` stays `<pending>` unless you install **MetalLB**:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
kubectl -n metallb-system rollout status deploy/controller --timeout=120s

cat <<'EOF' | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata: { name: pool, namespace: metallb-system }
spec: { addresses: ["172.18.255.200-172.18.255.210"] }
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata: { name: l2, namespace: metallb-system }
EOF
kubectl get svc web-lb
```

Adjust the pool range to fit the Killercoda node's subnet (`ip addr show`).

---

## Step 5 — Inspect Endpoints & EndpointSlices

```bash
kubectl get endpoints web-clusterip
kubectl get endpointslices -l kubernetes.io/service-name=web-clusterip
kubectl describe endpointslice -l kubernetes.io/service-name=web-clusterip
```

EndpointSlices are the modern, scalable replacement; the legacy `Endpoints` object still exists for compatibility.

---

## Step 6 — Cleanup

```bash
kubectl delete svc web-clusterip web-nodeport web-lb
kubectl delete deploy web
# Optional: kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
```

---

## What you learned
- ClusterIP (in-cluster), NodePort (cluster-wide host port), LoadBalancer (cloud LB or MetalLB).
- The Endpoints / EndpointSlice link between Service and Pods.
- Why bare-metal needs MetalLB to use `type=LoadBalancer`.
