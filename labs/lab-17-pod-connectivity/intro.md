# Lab 17 — Pod-to-Pod Connectivity

Every pod gets a routable IP and can reach every other pod without NAT. In this lab you prove the model end-to-end with `netshoot`, a tools-rich debug image.

**What you will do:**
- Launch a client pod (netshoot) and a server pod (nginx) on the flat pod network
- Verify pod-to-pod reachability by ping and curl using raw pod IPs
- Expose a pod as a Service and use DNS-based discovery
- Inspect the pod's network interface, routing table, and resolv.conf
- Trace the path between pods across nodes
