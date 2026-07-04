# Lab 8 — RBAC: Roles, RoleBindings, ServiceAccounts

In this lab you create a ServiceAccount for a "read-only viewer" persona, define a namespaced `Role` that allows only `get/list/watch` on Pods, bind the role to the SA, and prove that the SA can read but cannot write.

**Lab environment:** [Play with Kubernetes](https://killercoda.com/playgrounds/course/kubernetes-playgrounds)
---

## Step 1 — Create a namespace and ServiceAccount

```bash
kubectl create ns rbac-demo
kubectl -n rbac-demo create serviceaccount viewer
```

---

## Step 2 — Create a Role

```bash
kubectl -n rbac-demo create role pod-viewer \
  --verb=get,list,watch \
  --resource=pods
```

Inspect:

```bash
kubectl -n rbac-demo get role pod-viewer -o yaml
```

---

## Step 3 — Bind the Role to the ServiceAccount

```bash
kubectl -n rbac-demo create rolebinding viewer-binding \
  --role=pod-viewer \
  --serviceaccount=rbac-demo:viewer
```

---

## Step 4 — Test with `kubectl auth can-i`

```bash
kubectl -n rbac-demo auth can-i list pods       --as=system:serviceaccount:rbac-demo:viewer
kubectl -n rbac-demo auth can-i create pods     --as=system:serviceaccount:rbac-demo:viewer
kubectl -n rbac-demo auth can-i list deployments --as=system:serviceaccount:rbac-demo:viewer
```

You should see `yes`, `no`, `no`.

---

## Step 5 — Test from inside a pod

```bash
kubectl -n rbac-demo run viewer-pod \
  --image=bitnami/kubectl:latest \
  --serviceaccount=viewer \
  --command -- sleep 3600
kubectl -n rbac-demo wait --for=condition=Ready pod/viewer-pod --timeout=60s

kubectl -n rbac-demo exec viewer-pod -- kubectl get pods
kubectl -n rbac-demo exec viewer-pod -- kubectl create deploy nginx --image=nginx
```

The second command must fail with a Forbidden error — proof that RBAC is enforced.

---

## Step 6 — ClusterRole and ClusterRoleBinding

Some permissions are cluster-scoped (nodes, persistentvolumes). Create a read-only cluster role for nodes:

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding viewer-nodes \
  --clusterrole=node-reader \
  --serviceaccount=rbac-demo:viewer
kubectl -n rbac-demo exec viewer-pod -- kubectl get nodes
```

---

## Step 7 — Aggregated ClusterRoles (reference)

Built-in roles like `view`, `edit`, `admin` are aggregated. Inspect:

```bash
kubectl describe clusterrole view | head -20
```

---

## What you learned
- The Role / RoleBinding / ClusterRole / ClusterRoleBinding split.
- The `system:serviceaccount:<ns>:<name>` identity format.
- How to verify access with `kubectl auth can-i --as=...`.
