# Lab 18 — Service Types: ClusterIP, NodePort, LoadBalancer (MetalLB), EndpointSlices, Selector Debug

Kubernetes Services provide stable network endpoints for a dynamic set of pods. This lab creates and tests all three primary service types — ClusterIP for internal access, NodePort for node-level external access, and LoadBalancer with MetalLB for external VIP assignment — inspects the EndpointSlice objects that back services, and debugs selector mismatches that cause services to have no endpoints. Service types are heavily tested in the Services & Networking domain (20% of CKA).

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)
- MetalLB (installed in this lab for LoadBalancer type)

---

## Step 1 — Create a Deployment to Back the Services

```bash
# Deploy a web application with a distinctive version label
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      version: v1
  template:
    metadata:
      labels:
        app: webapp
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        - containerPort: 443
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
      version: v2
  template:
    metadata:
      labels:
        app: webapp
        version: v2
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        ports:
        - containerPort: 80
EOF

kubectl rollout status deployment webapp
kubectl get pods -l app=webapp --show-labels
```

Labels on pods are what Services use for discovery. The `version` label allows us to target v1, v2, or all pods depending on the Service's `selector`.

---

## Step 2 — ClusterIP Service: Internal-Only Access

```bash
# ClusterIP is the default service type — accessible only within the cluster
kubectl expose deployment webapp \
  --name=webapp-clusterip \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP

# View the service
kubectl get svc webapp-clusterip
kubectl describe svc webapp-clusterip
# Type: ClusterIP
# IP: 10.96.x.x (virtual IP, no external access)
# Selector: app=webapp, version=v1

# Test internal access
kubectl run test-client --image=curlimages/curl --restart=Never \
  -- curl -s http://webapp-clusterip/
kubectl logs test-client
# nginx welcome page

# Test DNS resolution
kubectl run test-dns --image=busybox:1.28 --restart=Never \
  -- nslookup webapp-clusterip.default.svc.cluster.local
kubectl logs test-dns

kubectl delete pod test-client test-dns
```

ClusterIP services get a virtual IP that exists only in the cluster's iptables/IPVS rules. The IP is not routable from outside the cluster. For external access, use NodePort or LoadBalancer.

---

## Step 3 — NodePort Service: External Access via Node IP

```bash
# NodePort opens a port on EVERY cluster node (range: 30000-32767)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: webapp-nodeport
spec:
  type: NodePort
  selector:
    app: webapp           # Selects both v1 and v2 pods
  ports:
  - name: http
    port: 80              # Port the service listens on (ClusterIP port)
    targetPort: 80        # Port the pods listen on
    nodePort: 30080       # Fixed external port (omit to let Kubernetes assign)
  - name: https
    port: 443
    targetPort: 443
    nodePort: 30443
EOF

kubectl get svc webapp-nodeport
# TYPE: NodePort
# PORT(S): 80:30080/TCP,443:30443/TCP

# Get a node IP for external testing
NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Node IP: $NODE_IP"

# Access via NodePort (from outside the cluster or curl from within)
curl -s http://$NODE_IP:30080/ | head -5

# NodePort is accessible on EVERY node's IP
NODE2_IP=$(kubectl get node -o jsonpath='{.items[1].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
[ -n "$NODE2_IP" ] && curl -s http://$NODE2_IP:30080/ | head -5
```

NodePort creates a high-numbered port (30000-32767) on every node. Traffic to `<any-node-IP>:<nodePort>` is forwarded to the service's pod backends. It's commonly used in labs; production typically uses LoadBalancer or Ingress.

---

## Step 4 — Install MetalLB for LoadBalancer Support

```bash
# MetalLB provides LoadBalancer support for bare-metal clusters
# (Cloud providers have their own implementations)

# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

# Wait for MetalLB pods to be ready
kubectl rollout status deployment controller -n metallb-system --timeout=120s
kubectl get pods -n metallb-system

# Configure MetalLB with an IP address pool
# Use IP range from your node subnet (adjust to match your lab environment)
NODE_IP=$(kubectl get node worker01 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || \
  kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
SUBNET=$(echo $NODE_IP | cut -d. -f1-3)
echo "Node IP: $NODE_IP, using subnet: $SUBNET"

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lab-pool
  namespace: metallb-system
spec:
  addresses:
  - ${SUBNET}.200-${SUBNET}.210   # IP range to assign to LoadBalancer services
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: lab-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - lab-pool
EOF
```

MetalLB implements the LoadBalancer service type using either L2 (ARP) or BGP. L2 mode is simpler — one node announces the IP via ARP and routes traffic. BGP mode distributes load across all nodes.

---

## Step 5 — LoadBalancer Service: External VIP Assignment

```bash
# Create a LoadBalancer service
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: webapp-lb
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 80
EOF

# Wait for MetalLB to assign an external IP
kubectl get svc webapp-lb -w
# EXTERNAL-IP transitions from <pending> to 192.168.x.200 (or similar)

LB_IP=$(kubectl get svc webapp-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "LoadBalancer IP: $LB_IP"

# Access via the LoadBalancer external IP
curl -s http://$LB_IP/

# Compare all three service types
kubectl get svc webapp-clusterip webapp-nodeport webapp-lb
# TYPE:         ClusterIP    NodePort    LoadBalancer
# EXTERNAL-IP:  <none>       <none>      192.168.x.200
```

LoadBalancer services get an externally-routable IP assigned by the cloud provider (or MetalLB). This is the production-grade way to expose services. Each LoadBalancer service creates a NodePort service internally.

---

## Step 6 — Inspect EndpointSlices

```bash
# EndpointSlices replaced Endpoints in Kubernetes v1.21+ for better scalability
kubectl get endpointslices

# View EndpointSlice for the webapp-lb service
kubectl describe endpointslice -l kubernetes.io/service-name=webapp-lb

# EndpointSlices show:
# Endpoints: IP addresses, ports, and readiness state of backing pods
# Each slice holds up to 100 endpoints (default)

# Also view the legacy Endpoints object (still exists alongside EndpointSlices)
kubectl get endpoints webapp-lb
kubectl describe endpoints webapp-lb

# Get pod IPs to compare with endpoints
kubectl get pods -l app=webapp -o wide
```

EndpointSlices are the scalable successor to Endpoints objects. They're automatically created and updated as pods become ready/not-ready. The `kube-proxy` agent watches EndpointSlices to update iptables rules.

---

## Step 7 — Debug Selector Mismatch (Empty Endpoints)

```bash
# Create a service with a WRONG selector (common exam mistake)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: broken-svc
spec:
  type: ClusterIP
  selector:
    app: webapp
    tier: frontend      # This label doesn't exist on pods!
  ports:
  - port: 80
    targetPort: 80
EOF

# The service will have no endpoints
kubectl get endpoints broken-svc
# NAME         ENDPOINTS   AGE
# broken-svc   <none>      5s

# Diagnose the selector mismatch
echo "=== Service selector ==="
kubectl get svc broken-svc -o jsonpath='{.spec.selector}'
# {"app":"webapp","tier":"frontend"}

echo "=== Pod labels (what actually exists) ==="
kubectl get pods -l app=webapp --show-labels | head -5
# Labels: app=webapp, version=v1 (no 'tier' label!)

# Fix: update the service selector to match actual pod labels
kubectl patch svc broken-svc \
  --type=merge \
  -p '{"spec":{"selector":{"app":"webapp"}}}'

# Verify endpoints are now populated
kubectl get endpoints broken-svc
# NAME         ENDPOINTS
# broken-svc   192.168.x.x:80,192.168.x.x:80,...
```

Empty endpoints (`<none>`) with a running deployment almost always means a selector mismatch. The debugging process: compare `kubectl get svc -o yaml` selector with `kubectl get pods --show-labels`. This pattern appears in CKA troubleshooting questions.

---

## Step 8 — Service Without Selector (Manual Endpoints)

```bash
# Services without selectors allow manual endpoint management
# Use case: external databases, services in other namespaces/clusters

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
  - port: 5432
    targetPort: 5432
  # No selector — endpoints managed manually
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db    # Must match Service name
subsets:
- addresses:
  - ip: 10.0.1.50      # External database IP
  - ip: 10.0.1.51      # Secondary database IP
  ports:
  - port: 5432
EOF

kubectl get svc external-db
kubectl get endpoints external-db
# Shows manually specified IPs
```

Selector-less services with manual Endpoints allow Kubernetes service discovery (DNS) to be used for external resources, enabling gradual migration of external services into Kubernetes.

---

## Step 9 — Headless Service (for StatefulSets and Direct Pod DNS)

```bash
# Headless service: no ClusterIP, DNS returns pod IPs directly
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: webapp-headless
spec:
  clusterIP: None       # This makes it headless
  selector:
    app: webapp
  ports:
  - port: 80
EOF

kubectl get svc webapp-headless
# CLUSTER-IP: None

# DNS returns multiple A records (one per pod)
kubectl run dns-test --image=busybox:1.28 --restart=Never \
  -- nslookup webapp-headless.default.svc.cluster.local
kubectl logs dns-test
# Multiple addresses returned (one per pod)
# Compare with regular service (returns single ClusterIP)

kubectl delete pod dns-test
```

Headless services are required for StatefulSet stable DNS (`<pod>.<service>.<ns>.svc.cluster.local`). They can also be used with custom service discovery where you need individual pod IPs rather than a load-balanced VIP.

---

## Step 10 — Clean Up

```bash
kubectl delete deployment webapp webapp-v2
kubectl delete svc webapp-clusterip webapp-nodeport webapp-lb broken-svc external-db webapp-headless
```

---

## Free online tools
- **Kubernetes Docs — Services**: https://kubernetes.io/docs/concepts/services-networking/service/
- **Kubernetes Docs — EndpointSlices**: https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/
- **MetalLB documentation**: https://metallb.universe.tf/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- `ClusterIP` (default): internal-only virtual IP; no external access; DNS-discoverable within the cluster
- `NodePort`: opens a port (30000-32767) on every cluster node for external access; backed by ClusterIP
- `LoadBalancer`: requests an external IP from the cloud provider or MetalLB; backed by NodePort + ClusterIP
- MetalLB provides LoadBalancer support for bare-metal clusters via ARP (L2) or BGP
- EndpointSlices track pod IPs and readiness; watched by kube-proxy for iptables updates
- Empty endpoints (`<none>`) almost always indicate a selector mismatch — compare service selector with pod labels
- Headless services (`clusterIP: None`) return pod IPs directly via DNS rather than a VIP
- Services without selectors support manual endpoint management for external databases
- The `port` field is the service port; `targetPort` is the container port; `nodePort` is the external node port
- `kubectl describe endpoints <svc>` is the first tool when diagnosing service connectivity issues
