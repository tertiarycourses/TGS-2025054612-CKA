# Lab 3 — Install a CNI Plugin (Calico)

A fresh kubeadm cluster has no pod network. In this lab you install Calico, watch the nodes flip from `NotReady` to `Ready`, and verify pod-to-pod connectivity across nodes.

Continue on the **kubeadm playground** from Lab 2.

**Lab environment:** [Play with Kubernetes](https://labs.play-with-k8s.com)

---

## Step 1 — Apply the Calico manifest

On the **controlplane**:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

This creates:
- `calico-system` and `calico-apiserver` (Tigera operator may vary by version) — for the manifest above, resources land in `kube-system`.
- A DaemonSet `calico-node` (one pod per node, wires the CNI binary into `/opt/cni/bin`).
- A Deployment `calico-kube-controllers`.

---

## Step 2 — Watch pods come up

```bash
kubectl get pods -n kube-system -w
```

Once `calico-node-*` reports `Running` on both nodes, press Ctrl-C and check:

```bash
kubectl get nodes
```

Both nodes should now be `Ready`.

---

## Step 3 — Verify pod networking across nodes

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

---

## Step 4 — Inspect the CNI configuration

On a worker:

```bash
ls /etc/cni/net.d/
cat /etc/cni/net.d/10-calico.conflist
ls /opt/cni/bin/ | grep calico
```

`/etc/cni/net.d/` is what kubelet reads to decide which plugin to invoke for every new pod.

---

## Step 5 — Clean up the test pods

```bash
kubectl delete pod pod-a pod-b
```

---

## What you learned
- How a CNI plugin turns `NotReady` nodes into `Ready` ones.
- Where CNI config and binaries live on each node.
- A practical cross-node connectivity test.
