# Lab 27 — Troubleshoot Nodes

Nodes go `NotReady` when the kubelet can't report healthy. In this lab you simulate three common node-level failures and recover from each.

**What you will do:**
- Establish a baseline by checking node conditions and taints
- Stop the kubelet on a worker node and observe the `NotReady` transition
- Break the kubelet config with a wrong cgroup driver setting and recover
- Cordon, drain, and uncordon a node for planned maintenance
- Simulate disk pressure and observe eviction events
- Stop the container runtime and observe the effect on node readiness
- Apply a structured triage checklist for `NotReady` nodes
