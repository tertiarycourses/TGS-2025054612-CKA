# Lab 14 — Horizontal Pod Autoscaling

The Horizontal Pod Autoscaler (HPA) scales a Deployment up and down based on observed CPU/memory or custom metrics. In this lab you install `metrics-server`, deploy a CPU-burning app, attach an HPA, then stress it.

**What you will do:**
- Install and configure metrics-server for the lab environment
- Deploy a CPU-bound workload with resource requests
- Create an HPA targeting 50% CPU utilisation
- Generate load and watch the HPA scale out
- Stop the load and observe the scale-down stabilisation window
- Review the HPA v2 API with multiple metric types
- Clean up all resources
