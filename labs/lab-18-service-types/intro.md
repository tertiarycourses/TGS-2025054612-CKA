# Lab 18 — Service Types: ClusterIP, NodePort, LoadBalancer

In this lab you expose the same Deployment with each of the three primary Service types and inspect the resulting Endpoints.

**What you will do:**
- Deploy a three-replica nginx Deployment
- Create a ClusterIP Service and test in-cluster access
- Create a NodePort Service and reach it from the host via a high-numbered port
- Create a LoadBalancer Service and (on bare-metal) install MetalLB to assign an external IP
- Inspect Endpoints and EndpointSlices to understand how kube-proxy load-balances
