# Lab 22 — CoreDNS

CoreDNS is the default in-cluster DNS server. Every pod gets `/etc/resolv.conf` pointing to its ClusterIP. In this lab you inspect CoreDNS, query different record types, and customize the Corefile.

**What you will do:**
- Locate the CoreDNS Service, pods, and ConfigMap in kube-system
- Run a netshoot debug pod and inspect its DNS configuration
- Query A records for a Service using both short names and FQDNs
- Create a headless Service and observe that DNS returns pod IPs directly
- Query SRV records to see port discovery
- Customize the Corefile to add a stub zone that forwards to an external resolver
