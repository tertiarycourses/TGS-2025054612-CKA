# Step 3 — Verify pod networking across nodes

Schedule two pods, one on each node:

```bash
kubectl run pod-a --image=nicolaka/netshoot --overrides='{"spec":{"nodeName":"controlplane"}}' --command -- sleep 3600
kubectl run pod-b --image=nicolaka/netshoot --overrides='{"spec":{"nodeName":"node01"}}'     --command -- sleep 3600
kubectl wait --for=condition=Ready pod/pod-a pod/pod-b --timeout=120s
kubectl get pods -o wide
```

Ping pod-b from pod-a:

```bash
POD_B_IP=$(kubectl get pod pod-b -o jsonpath='{.status.podIP}')
kubectl exec pod-a -- ping -c 3 $POD_B_IP
```

A successful reply proves the Calico overlay (IP-in-IP / VXLAN) is forwarding cross-node traffic.
