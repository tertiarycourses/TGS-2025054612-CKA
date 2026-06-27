# Lab 17 — Pod Connectivity: Flat Pod Network, ping by Pod IP, curl, DNS Discovery, traceroute, netshoot

Kubernetes implements a flat pod network model where every pod can communicate with every other pod without NAT. This lab verifies pod-to-pod communication using ping and curl, tests DNS-based service discovery, traces network paths with traceroute, and uses the nicolaka/netshoot container as a network debugging toolkit. Understanding pod networking fundamentals is the foundation for the entire Services & Networking domain (20% of the CKA exam).

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)
- nicolaka/netshoot image (pulled in this lab)

---

## Step 1 — Deploy Test Pods Across Nodes

```bash
# Deploy pods on different nodes to test cross-node connectivity
# First, find the node names
kubectl get nodes -o wide
NODE1=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
NODE2=$(kubectl get nodes -o jsonpath='{.items[1].metadata.name}' 2>/dev/null || echo $NODE1)
echo "Node1: $NODE1, Node2: $NODE2"

# Deploy a server pod (nginx) on node1
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: server-pod
  labels:
    role: server
spec:
  nodeName: NODE1_PLACEHOLDER
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
EOF
# Replace the placeholder
kubectl patch pod server-pod -p "{\"spec\":{\"nodeName\":\"$NODE1\"}}" 2>/dev/null || \
  kubectl delete pod server-pod 2>/dev/null; \
  kubectl run server-pod --image=nginx:alpine --port=80 --overrides="{\"spec\":{\"nodeName\":\"$NODE1\"}}"

# Deploy a client pod (netshoot) on node2
kubectl run client-pod \
  --image=nicolaka/netshoot \
  --overrides="{\"spec\":{\"nodeName\":\"$NODE2\"}}" \
  -- sleep infinity

# Wait for both pods to be running
kubectl wait --for=condition=Ready pod/server-pod --timeout=60s
kubectl wait --for=condition=Ready pod/client-pod --timeout=60s

# Get pod IPs
SERVER_IP=$(kubectl get pod server-pod -o jsonpath='{.status.podIP}')
CLIENT_IP=$(kubectl get pod client-pod -o jsonpath='{.status.podIP}')
echo "Server pod IP: $SERVER_IP"
echo "Client pod IP: $CLIENT_IP"
```

Pod IPs come from the pod CIDR range (e.g., `192.168.x.x` with Calico). Every pod gets a unique IP within the cluster-wide pod network.

---

## Step 2 — Ping Pod-to-Pod by IP

```bash
# Ping the server pod from the client pod
kubectl exec client-pod -- ping -c 4 $SERVER_IP

# Expected output:
# PING 192.168.x.x: 56 data bytes
# 64 bytes from 192.168.x.x: seq=0 ttl=62 time=0.8 ms
# 64 bytes from 192.168.x.x: seq=1 ttl=62 time=0.5 ms
# --- 192.168.x.x ping statistics ---
# 4 packets transmitted, 4 packets received, 0% packet loss

# Ping in reverse direction
kubectl exec server-pod -- ping -c 4 $CLIENT_IP 2>/dev/null || \
  echo "nginx:alpine doesn't have ping — netshoot does"

# Ping from client to server
kubectl exec client-pod -- ping -c 2 $SERVER_IP
```

Successful ping confirms Layer 3 (IP) connectivity between pods. If ping fails, the CNI plugin is misconfigured, or a NetworkPolicy is blocking ICMP. The TTL of 62 (not 64) indicates traffic went through 2 hops (typically 2 routing hops in the overlay network).

---

## Step 3 — curl Pod-to-Pod by IP

```bash
# HTTP request to the server pod's nginx on port 80
kubectl exec client-pod -- curl -s http://$SERVER_IP/
# Expected: nginx welcome page HTML

# With response headers
kubectl exec client-pod -- curl -sI http://$SERVER_IP/
# HTTP/1.1 200 OK
# Server: nginx/...

# Check response code only
kubectl exec client-pod -- curl -o /dev/null -w "%{http_code}" http://$SERVER_IP/
# 200

# Test connectivity to a specific port
kubectl exec client-pod -- curl -s --connect-timeout 3 http://$SERVER_IP:80/
```

Successful curl on port 80 confirms that pod networking works at Layer 4 (TCP). This verifies both the IP routing and the pod's listening port.

---

## Step 4 — Create a Service and Test DNS Discovery

```bash
# Expose the server pod via a Service
kubectl expose pod server-pod \
  --name=server-svc \
  --port=80 \
  --target-port=80

# Get service details
kubectl get svc server-svc
SVC_IP=$(kubectl get svc server-svc -o jsonpath='{.spec.clusterIP}')
echo "Service ClusterIP: $SVC_IP"

# Access the service by ClusterIP
kubectl exec client-pod -- curl -s http://$SVC_IP/
# Works — iptables/IPVS routes the request to a pod

# Access by service DNS name (most important!)
kubectl exec client-pod -- curl -s http://server-svc.default.svc.cluster.local/

# Short DNS forms also work (within the same namespace)
kubectl exec client-pod -- curl -s http://server-svc/
kubectl exec client-pod -- curl -s http://server-svc.default/
```

DNS service discovery is the standard way pods find each other in Kubernetes. The full DNS name is `<service>.<namespace>.svc.<cluster-domain>`. Within the same namespace, the service name alone works.

---

## Step 5 — Inspect DNS Resolution

```bash
# Look up the service IP using DNS
kubectl exec client-pod -- nslookup server-svc

# Full DNS lookup
kubectl exec client-pod -- nslookup server-svc.default.svc.cluster.local

# View the DNS search domains configured in the pod
kubectl exec client-pod -- cat /etc/resolv.conf
# nameserver 10.96.0.10  (CoreDNS ClusterIP)
# search default.svc.cluster.local svc.cluster.local cluster.local

# The search domain list explains short DNS names:
# "server-svc" → tries "server-svc.default.svc.cluster.local" first

# DNS for pods (not commonly used but worth knowing)
POD_IP_DASHED=$(echo $SERVER_IP | tr '.' '-')
kubectl exec client-pod -- nslookup ${POD_IP_DASHED}.default.pod.cluster.local 2>/dev/null || true
```

The `/etc/resolv.conf` search domains are injected by kubelet based on the pod's namespace. This is why short names work — the DNS client appends the search domain until a match is found.

---

## Step 6 — Deploy a Multi-Replica Service for Load Balancing

```bash
# Create a deployment with multiple replicas
kubectl create deployment multi-nginx --image=nginx:alpine --replicas=3
kubectl expose deployment multi-nginx --port=80

# Get all pod IPs
kubectl get pods -l app=multi-nginx -o wide

# Send multiple requests and observe round-robin (or random) load balancing
for i in {1..6}; do
  kubectl exec client-pod -- curl -s http://multi-nginx/ | grep -o 'Welcome to nginx'
done

# Check the endpoints object (shows which pod IPs are behind the service)
kubectl get endpoints multi-nginx
kubectl describe endpoints multi-nginx
# Addresses shows the IPs of all ready pods
```

The `Endpoints` object is automatically created and updated by the Endpoints controller to track which pod IPs back a Service. When a pod becomes not-ready, its IP is removed from the Endpoints.

---

## Step 7 — traceroute Between Pods

```bash
# Trace the network path between pods (netshoot has traceroute)
kubectl exec client-pod -- traceroute $SERVER_IP

# Expected output with Calico IP-in-IP:
# traceroute to 192.168.x.x (192.168.x.x), 30 hops max
#  1  <host IP>   (192.168.0.1)   0.1 ms   (host gateway)
#  2  192.168.x.x (the destination pod)     0.5 ms

# The number of hops reveals the CNI tunneling mode:
# Direct routing (BGP): 2 hops (host → destination)
# IP-in-IP or VXLAN: 2-3 hops

# Trace path to a service IP
kubectl exec client-pod -- traceroute $SVC_IP
# Service IP disappears immediately (iptables DNAT happens before routing)
# Trace shows the destination pod IP, not the VIP
```

`traceroute` reveals the CNI implementation. With BGP direct routing, packets go node-to-node. With overlay networks (VXLAN, IP-in-IP), the outer IP is the node IP and the inner IP is the pod IP.

---

## Step 8 — Network Debugging with netshoot

```bash
# netshoot is a comprehensive network debugging container
# It includes: ping, traceroute, tcpdump, ss, iperf3, nslookup, dig, curl, netstat

# Check listening ports on the server
kubectl exec client-pod -- nc -zv $SERVER_IP 80
# Connection to 192.168.x.x 80 port [tcp/http] succeeded!

kubectl exec client-pod -- nc -zv $SERVER_IP 443
# nc: Connection refused (nginx not listening on 443)

# Check open ports on a service
kubectl exec client-pod -- nmap -p 80,443,8080 $SVC_IP 2>/dev/null || \
  kubectl exec client-pod -- nc -zv $SVC_IP 80

# Run dig for detailed DNS information
kubectl exec client-pod -- dig server-svc.default.svc.cluster.local
# Shows TTL, ANSWER SECTION with ClusterIP

# Check network interfaces inside a pod
kubectl exec client-pod -- ip addr
# eth0 — pod's primary interface (gets the pod IP)
# lo   — loopback

# Check routing table
kubectl exec client-pod -- ip route
# default via <gateway>  (host's veth gateway)
```

The `nicolaka/netshoot` image is specifically designed for Kubernetes network debugging. It contains every networking tool you need for CKA troubleshooting scenarios. Remember its name — it saves time.

---

## Step 9 — Test Cross-Namespace Connectivity

```bash
# Create a second namespace with a pod
kubectl create namespace test-ns
kubectl run cross-ns-pod \
  --image=nginx:alpine \
  -n test-ns

kubectl wait --for=condition=Ready pod/cross-ns-pod -n test-ns --timeout=60s

CROSS_NS_IP=$(kubectl get pod cross-ns-pod -n test-ns -o jsonpath='{.status.podIP}')
echo "Cross-namespace pod IP: $CROSS_NS_IP"

# Default Kubernetes policy: pods can communicate across namespaces
kubectl exec client-pod -- curl -s http://$CROSS_NS_IP/
# nginx welcome page — cross-namespace communication works by default!

# For namespace isolation, you need NetworkPolicies (Lab 21)
# Cross-namespace service DNS:
kubectl expose pod cross-ns-pod --name=cross-svc -n test-ns --port=80
kubectl exec client-pod -- curl -s http://cross-svc.test-ns.svc.cluster.local/
# Works — using fully-qualified namespace in DNS name
```

Without NetworkPolicies, pods in different namespaces CAN communicate freely. Namespaces provide organizational and access-control isolation, not network isolation. NetworkPolicies (Lab 21) add network isolation.

---

## Step 10 — Clean Up

```bash
kubectl delete pod server-pod client-pod
kubectl delete deployment multi-nginx
kubectl delete svc server-svc multi-nginx
kubectl delete namespace test-ns
```

---

## Free online tools
- **Kubernetes Docs — Cluster Networking**: https://kubernetes.io/docs/concepts/cluster-administration/networking/
- **netshoot repository**: https://github.com/nicolaka/netshoot
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- Kubernetes flat network: every pod can communicate with every other pod without NAT by default
- Pod IPs come from the pod CIDR and are unique across the entire cluster
- `kubectl exec <pod> -- ping` and `curl` are the primary tools for testing pod connectivity
- Cross-namespace pod communication works by default — namespaces do NOT provide network isolation
- Service DNS format: `<service>.<namespace>.svc.cluster.local` — the full form always works
- Short DNS names work within the same namespace due to search domains in `/etc/resolv.conf`
- The `Endpoints` object maps service selectors to pod IPs — inspect it when service routing fails
- `traceroute` reveals how many hops packets take, exposing the CNI's routing mechanism
- `nicolaka/netshoot` is the Swiss Army knife of pod network debugging (ping, curl, dig, traceroute, nc, nmap)
- Service ClusterIP is a virtual IP implemented via iptables DNAT — traceroute to a VIP shows destination pod IP
