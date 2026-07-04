# Lab 29 — Monitor Cluster and Application Usage

In this lab you install metrics-server, use `kubectl top`, then install the kube-prometheus-stack via Helm for the full Prometheus + Grafana experience.

**What you will do:**
- Install metrics-server and patch it for an insecure-TLS environment
- Use `kubectl top nodes` and `kubectl top pods` to view live resource usage
- Inspect cluster events sorted by timestamp to find warnings
- Query the raw cAdvisor stats endpoint on a node
- Deploy the kube-prometheus-stack with Helm and expose Grafana via port-forward
- Run sample PromQL queries in Grafana Explore
- Clean up the monitoring namespace
