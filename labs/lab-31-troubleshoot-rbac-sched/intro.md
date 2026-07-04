# Lab 31 — Troubleshoot RBAC and Scheduling Failures

Two more high-frequency exam scenarios: a ServiceAccount that can't do what it needs, and a Pod that stays `Pending` because the scheduler refuses to place it.

**What you will do:**
- Create a ServiceAccount with no permissions and observe Forbidden errors
- Use `kubectl auth can-i --as=` to diagnose RBAC gaps without running the workload
- Grant minimal namespaced access with Role and RoleBinding
- Extend permissions to cluster-scoped resources using ClusterRole and ClusterRoleBinding
- Trigger `Pending` due to excessive resource requests and interpret the event
- Apply a taint and observe untolerated-taint scheduling failure
- Use `nodeSelector` to cause a no-matching-node failure
- Clean up the namespace, ClusterRole, and ClusterRoleBinding
