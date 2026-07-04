# Lab 8 — RBAC: Roles, RoleBindings, ServiceAccounts

In this lab you create a ServiceAccount for a "read-only viewer" persona, define a namespaced `Role` that allows only `get/list/watch` on Pods, bind the role to the SA, and prove that the SA can read but cannot write.

Use the **Kubernetes playground**: https://killercoda.com/playgrounds/scenario/kubernetes

**What you will do:**
- Create a namespace and a ServiceAccount for the viewer persona
- Define a namespaced Role with `get`, `list`, `watch` verbs on Pods
- Bind the Role to the ServiceAccount with a RoleBinding
- Verify access with `kubectl auth can-i --as=`
- Run a pod under the ServiceAccount and test read vs write permissions live
- Create a ClusterRole and ClusterRoleBinding for cluster-scoped resources
- Inspect aggregated built-in ClusterRoles
