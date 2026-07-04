# Lab 21 — Network Policies

NetworkPolicy is the Kubernetes firewall for pod-to-pod traffic. It requires a CNI that enforces policy (Calico, Cilium, Weave). In this lab you write deny-by-default, then progressively allow traffic.

**What you will do:**
- Create a namespace with a server pod and two client pods (one trusted, one not)
- Verify baseline open connectivity
- Apply a default-deny ingress NetworkPolicy and observe that all clients are blocked
- Add an allow rule scoped to the trusted client by pod label
- Extend the allow rule to accept traffic from a trusted namespace
- Write an egress policy that restricts a pod to DNS-only outbound traffic
