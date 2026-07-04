# Lab 16 — Pod Scheduling (Limits, Affinity, Taints)

In this lab you control where pods land using resource requests, nodeSelector, node affinity, and taints/tolerations.

**What you will do:**
- Label nodes and use nodeSelector to pin a pod to a specific node
- Write node affinity rules (required and preferred) to express scheduling constraints
- Use pod anti-affinity to spread replicas across nodes
- Set resource requests and limits so the scheduler finds a node with enough capacity
- Apply taints to a node and add tolerations to allow pods through
