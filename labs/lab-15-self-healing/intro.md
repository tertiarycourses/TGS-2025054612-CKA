# Lab 15 — Self-Healing Primitives

Kubernetes self-healing relies on four pillars: liveness/readiness/startup probes, ReplicaSets, DaemonSets, and StatefulSets. In this lab you exercise each one.

**What you will do:**
- Configure a liveness probe and watch the kubelet restart a failing container
- Configure a readiness probe and observe traffic gating behaviour
- Delete a pod from a ReplicaSet and watch it be recreated immediately
- Deploy a DaemonSet that schedules one pod per node
- Deploy a StatefulSet with stable pod identities via a headless Service
- Clean up all resources
