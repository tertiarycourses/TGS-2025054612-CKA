# Well done!

You have completed Lab 8 — RBAC: Roles, RoleBindings, ServiceAccounts:

✅ Created the `rbac-demo` namespace and a `viewer` ServiceAccount
✅ Defined a namespaced `pod-viewer` Role with `get/list/watch` on Pods
✅ Bound the Role to the ServiceAccount via a RoleBinding
✅ Verified access with `kubectl auth can-i --as=system:serviceaccount:rbac-demo:viewer`
✅ Confirmed read allowed / write forbidden from inside a running pod
✅ Created a ClusterRole and ClusterRoleBinding for cluster-scoped node access
✅ Inspected the aggregated `view` built-in ClusterRole

**Next:** Lab 9 — etcd Backup and Restore
