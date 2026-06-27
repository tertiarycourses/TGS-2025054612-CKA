# Lab 8 — RBAC: Role, RoleBinding, ClusterRole, auth can-i --as, Test from Inside Pod

Role-Based Access Control (RBAC) is a critical CKA exam domain that controls who can do what in your cluster. This lab creates namespace-scoped Roles and ClusterRoles, binds them to users and service accounts with RoleBindings and ClusterRoleBindings, validates permissions with `kubectl auth can-i --as`, and tests authorization from inside a running pod using the mounted service account token. RBAC misconfiguration is the most common real-world security incident in Kubernetes clusters.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)
- curl (pre-installed in pod)

---

## Step 1 — Understand RBAC Objects

```bash
# RBAC has four core object types:
# Role          — namespace-scoped permissions (can only access resources in one namespace)
# ClusterRole   — cluster-scoped permissions (can access resources in any namespace or cluster-wide)
# RoleBinding   — binds a Role OR ClusterRole to subjects within a specific namespace
# ClusterRoleBinding — binds a ClusterRole to subjects cluster-wide

# View existing ClusterRoles
kubectl get clusterroles | head -20
kubectl describe clusterrole view
kubectl describe clusterrole edit
kubectl describe clusterrole cluster-admin

# View existing ClusterRoleBindings
kubectl get clusterrolebindings | head -10
```

Kubernetes ships with built-in ClusterRoles: `cluster-admin` (full access), `admin` (namespace admin), `edit` (read-write in namespace), `view` (read-only in namespace). Always prefer these over creating custom roles when they fit.

---

## Step 2 — Create a Namespace-Scoped Role

```bash
# Create a namespace for this lab
kubectl create namespace rbac-lab

# Create a Role that allows reading pods and services
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: rbac-lab
rules:
- apiGroups: [""]        # "" means the core API group (pods, services, configmaps, etc.)
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
EOF

# View the created role
kubectl describe role pod-reader -n rbac-lab
```

`apiGroups: [""]` refers to the core API group (v1 resources: pods, services, configmaps, secrets, etc.). Resources in other groups like `apps/v1` require `apiGroups: ["apps"]`, and `networking.k8s.io/v1` requires `apiGroups: ["networking.k8s.io"]`.

---

## Step 3 — Create a ClusterRole

```bash
# ClusterRole for managing deployments cluster-wide
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployment-manager
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments/scale"]
  verbs: ["get", "update", "patch"]
EOF

# ClusterRole for read-only access to cluster-level resources
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-viewer
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "list"]
EOF

kubectl describe clusterrole deployment-manager
```

ClusterRoles can grant access to cluster-scoped resources (nodes, PVs, namespaces, CRDs) which Roles cannot. A ClusterRole can also be bound to a specific namespace using a RoleBinding.

---

## Step 4 — Create a RoleBinding

```bash
# Create a user (simulated — in practice created via certificates or OIDC)
# Bind the pod-reader Role to user 'alice' in namespace rbac-lab

cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: alice-pod-reader
  namespace: rbac-lab
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

# You can also bind a ClusterRole in a namespace via RoleBinding
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bob-deployment-manager
  namespace: rbac-lab
subjects:
- kind: User
  name: bob
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole         # ClusterRole bound with RoleBinding = scoped to this namespace
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl get rolebindings -n rbac-lab
```

A RoleBinding can reference either a Role or a ClusterRole. When referencing a ClusterRole, the permissions are limited to the namespace of the RoleBinding — this is a common pattern for reusable permission sets.

---

## Step 5 — Create a ClusterRoleBinding

```bash
# Bind deployment-manager ClusterRole cluster-wide to user 'charlie'
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: charlie-cluster-deployment-manager
subjects:
- kind: User
  name: charlie
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
EOF

# Bind node-viewer to a Group (applies to all users in that group)
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devteam-node-viewer
subjects:
- kind: Group
  name: devteam
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-viewer
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl get clusterrolebindings | grep -E 'charlie|devteam'
```

ClusterRoleBindings grant access across all namespaces. Use them sparingly — prefer namespace-scoped RoleBindings for workload access and reserve ClusterRoleBindings for cluster administrators.

---

## Step 6 — Test Permissions with kubectl auth can-i

```bash
# Check what alice can do
kubectl auth can-i get pods -n rbac-lab --as=alice
# yes

kubectl auth can-i list services -n rbac-lab --as=alice
# yes

kubectl auth can-i create pods -n rbac-lab --as=alice
# no

kubectl auth can-i get pods -n default --as=alice
# no (alice's binding is only in rbac-lab namespace)

# Check bob's permissions
kubectl auth can-i create deployments -n rbac-lab --as=bob
# yes

kubectl auth can-i delete deployments -n default --as=bob
# no (bob's ClusterRole is bound only in rbac-lab via RoleBinding)

# Check charlie's cluster-wide permissions
kubectl auth can-i create deployments -n production --as=charlie
# yes

kubectl auth can-i create deployments -n any-namespace --as=charlie
# yes

# List all permissions for a user in a namespace
kubectl auth can-i --list -n rbac-lab --as=alice
```

`kubectl auth can-i` is the fastest way to verify RBAC permissions on the CKA exam. Always test with `--as=<username>` to impersonate the user rather than relying on mental calculations.

---

## Step 7 — Create a Service Account

```bash
# Service Accounts are for pods (not human users)
kubectl create serviceaccount pod-reader-sa -n rbac-lab

# Bind the pod-reader role to the service account
kubectl create rolebinding pod-reader-sa-binding \
  --role=pod-reader \
  --serviceaccount=rbac-lab:pod-reader-sa \
  --namespace=rbac-lab

# Verify the service account and its binding
kubectl get serviceaccount pod-reader-sa -n rbac-lab
kubectl describe rolebinding pod-reader-sa-binding -n rbac-lab

# Check what the service account can do
kubectl auth can-i get pods -n rbac-lab \
  --as=system:serviceaccount:rbac-lab:pod-reader-sa
# yes

kubectl auth can-i create pods -n rbac-lab \
  --as=system:serviceaccount:rbac-lab:pod-reader-sa
# no
```

The format for impersonating a service account is `system:serviceaccount:<namespace>:<name>`. This is critical to know for CKA exam questions that involve testing pod-level API access.

---

## Step 8 — Deploy a Pod with the Service Account

```bash
# Create a test pod using the pod-reader-sa service account
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: sa-test-pod
  namespace: rbac-lab
spec:
  serviceAccountName: pod-reader-sa
  containers:
  - name: test
    image: curlimages/curl:latest
    command: ["sleep", "infinity"]
EOF

kubectl wait --for=condition=Ready pod/sa-test-pod -n rbac-lab --timeout=60s

# The service account token is automatically mounted
kubectl exec sa-test-pod -n rbac-lab -- \
  ls /var/run/secrets/kubernetes.io/serviceaccount/
# token  ca.crt  namespace
```

Kubernetes automatically mounts the service account token into every pod at `/var/run/secrets/kubernetes.io/serviceaccount/token`. This token is used by the pod to authenticate to the API server.

---

## Step 9 — Test RBAC from Inside the Pod

```bash
# Get the token from inside the pod
TOKEN=$(kubectl exec sa-test-pod -n rbac-lab -- \
  cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Get the API server address
APISERVER="https://kubernetes.default.svc.cluster.local"

# Test GET pods (should succeed — pod-reader-sa has get pods)
kubectl exec sa-test-pod -n rbac-lab -- \
  curl -s -k \
  -H "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/rbac-lab/pods | \
  python3 -m json.tool | grep '"name"' | head -5

# Test CREATE pod (should fail — pod-reader-sa cannot create)
kubectl exec sa-test-pod -n rbac-lab -- \
  curl -s -k \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -X POST \
  $APISERVER/api/v1/namespaces/rbac-lab/pods \
  -d '{"apiVersion":"v1","kind":"Pod","metadata":{"name":"test"}}' | \
  python3 -m json.tool | grep -E 'reason|message'
# Expected: "Forbidden" or 403
```

Testing from inside the pod confirms that the service account token is correctly bound and that RBAC rules are enforced at the API level, not just by kubectl.

---

## Step 10 — RBAC Troubleshooting Tips

```bash
# When you get "Forbidden" errors, check what role bindings exist
kubectl get rolebindings,clusterrolebindings -A | grep <subject-name>

# Describe the binding to see the roleRef and subjects
kubectl describe rolebinding <name> -n <namespace>

# Check if the resource name, verb, or apiGroup is wrong
kubectl api-resources | grep <resource>
# Shows the API group and short name

# Common mistakes:
# 1. Using apiGroups: ["apps"] for core resources (should be [""])
# 2. Missing the subresource: pods/log, pods/exec, pods/portforward
# 3. Binding to wrong namespace
# 4. Binding ClusterRoleBinding when only namespace access is needed

# List all resources and their API groups
kubectl api-resources -o wide | head -30

# Find the correct apiGroup for a resource
kubectl explain deployment | grep -i 'group\|version'
```

The most common RBAC mistake on the CKA exam is getting the `apiGroups` wrong. Use `kubectl api-resources -o wide` to find the correct group for any resource.

---

## Free online tools
- **Kubernetes Docs — RBAC**: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- Roles are namespace-scoped; ClusterRoles are cluster-scoped or can be reused in namespaces via RoleBinding
- RoleBindings can reference ClusterRoles — the permissions are then scoped to the binding's namespace
- Subjects in bindings can be: `User`, `Group`, or `ServiceAccount`
- `kubectl auth can-i <verb> <resource> -n <ns> --as=<user>` is the fastest permission test
- Service account format for `--as`: `system:serviceaccount:<namespace>:<name>`
- Service account tokens are auto-mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token`
- `apiGroups: [""]` covers core v1 resources; `["apps"]` covers Deployments/ReplicaSets
- Subresources (`pods/log`, `pods/exec`) require explicit permission separate from the base resource
- `kubectl api-resources -o wide` shows API group and verbs for any resource
- Use `kubectl auth can-i --list --as=<user>` to enumerate all permissions for a user
