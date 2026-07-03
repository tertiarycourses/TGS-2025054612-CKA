# Step 4 — LoadBalancer

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
