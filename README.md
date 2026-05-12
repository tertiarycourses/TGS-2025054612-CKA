# TGS-2025054612 — Certified Kubernetes Administrator (CKA) Hands-On Labs

> **Course:** WSQ — Certified Kubernetes Administrator (CKA) Training
> **Course Code:** TGS-2025054612
> **Register here:** https://www.tertiarycourses.com.sg/wsq-certified-kubernetes-administrator-cka-training.html

These are the official hands-on lab exercises for the WSQ Certified Kubernetes Administrator Training course delivered by [**Tertiary Infotech Academy Pte Ltd**](https://www.tertiarycourses.com.sg/).

A complete set of **31 step-by-step labs** aligned to the CNCF **CKA Curriculum v1.35** exam objectives. Every lab runs on the free **Killercoda Kubernetes Playground** (https://killercoda.com/playgrounds/scenario/kubernetes) and **kubeadm Playground** (https://killercoda.com/playgrounds/scenario/kubeadm) — no local install required.

---

## How to use

1. Open the Killercoda Kubernetes playground in your browser: https://killercoda.com/playgrounds/scenario/kubernetes (pre-built 1 control plane + 1 worker cluster).
2. For install/upgrade/HA labs (Labs 1–5) use the kubeadm playground: https://killercoda.com/playgrounds/scenario/kubeadm (two empty Ubuntu nodes).
3. Pick a lab from the list below and follow the steps in order.
4. Reset the playground between labs that mutate cluster-wide resources (RBAC, network policies, CRDs).
5. See [labs/tools.md](labs/tools.md) for every free tool used (with install commands and download links).

---

## Lab catalogue

### Domain 1 — Cluster Architecture, Installation and Configuration (25%)
- [Lab 1 — kubeadm Prerequisites and Container Runtime](labs/lab-01-kubeadm-prereqs.md)
- [Lab 2 — Bootstrap a Cluster with kubeadm](labs/lab-02-kubeadm-bootstrap.md)
- [Lab 3 — Install a CNI Plugin (Calico)](labs/lab-03-cni-calico.md)
- [Lab 4 — Cluster Upgrade with kubeadm](labs/lab-04-cluster-upgrade.md)
- [Lab 5 — Highly-Available Control Plane](labs/lab-05-ha-control-plane.md)
- [Lab 6 — Install Components with Helm](labs/lab-06-helm.md)
- [Lab 7 — Customize Manifests with Kustomize](labs/lab-07-kustomize.md)
- [Lab 8 — RBAC: Roles, RoleBindings, ServiceAccounts](labs/lab-08-rbac.md)
- [Lab 9 — CRDs and Operators](labs/lab-09-crds-operators.md)
- [Lab 10 — Extension Interfaces (CNI, CSI, CRI)](labs/lab-10-extension-interfaces.md)

### Domain 2 — Workloads and Scheduling (15%)
- [Lab 11 — Deployments: Rolling Update and Rollback](labs/lab-11-deployments-rollout.md)
- [Lab 12 — ConfigMaps](labs/lab-12-configmaps.md)
- [Lab 13 — Secrets](labs/lab-13-secrets.md)
- [Lab 14 — Horizontal Pod Autoscaling](labs/lab-14-hpa.md)
- [Lab 15 — Self-Healing Primitives (Probes, RS, DS, StatefulSet)](labs/lab-15-self-healing.md)
- [Lab 16 — Pod Scheduling (Limits, Affinity, Taints)](labs/lab-16-scheduling.md)

### Domain 3 — Services and Networking (20%)
- [Lab 17 — Pod-to-Pod Connectivity](labs/lab-17-pod-connectivity.md)
- [Lab 18 — Service Types: ClusterIP, NodePort, LoadBalancer](labs/lab-18-service-types.md)
- [Lab 19 — Ingress Controller and Resources](labs/lab-19-ingress.md)
- [Lab 20 — Gateway API](labs/lab-20-gateway-api.md)
- [Lab 21 — Network Policies](labs/lab-21-network-policies.md)
- [Lab 22 — CoreDNS](labs/lab-22-coredns.md)

### Domain 4 — Storage (10%)
- [Lab 23 — PersistentVolume and PersistentVolumeClaim](labs/lab-23-pv-pvc.md)
- [Lab 24 — StorageClass and Dynamic Provisioning](labs/lab-24-storageclass.md)
- [Lab 25 — Volume Types in Pods](labs/lab-25-volume-types.md)

### Domain 5 — Troubleshooting (30%)
- [Lab 26 — Troubleshoot Cluster Components](labs/lab-26-troubleshoot-components.md)
- [Lab 27 — Troubleshoot Nodes](labs/lab-27-troubleshoot-nodes.md)
- [Lab 28 — Application Logs and Container Streams](labs/lab-28-logs-streams.md)
- [Lab 29 — Monitor Cluster and Application Usage](labs/lab-29-monitoring.md)
- [Lab 30 — Troubleshoot Services and Networking](labs/lab-30-troubleshoot-net.md)
- [Lab 31 — Troubleshoot RBAC and Scheduling Failures](labs/lab-31-troubleshoot-rbac-sched.md)

---

## Reference

- [labs/README.md](labs/README.md) — Lab index grouped by domain with software requirements
- [labs/tools.md](labs/tools.md) — Complete list of free tools (Killercoda + external)
- `CKA_Curriculum_v1.35.pdf` — Official CNCF exam blueprint
- [theplatformlab/CKA-Certified-Kubernetes-Administrator](https://github.com/theplatformlab/CKA-Certified-Kubernetes-Administrator) — Companion question bank for exam-style Q&A practice

---

## Free tools used

All tooling is **100% free**. The bulk runs inside the disposable Killercoda Kubernetes / kubeadm playground via `kubectl`, `kubeadm`, and `apt`. Optional GUI/web tools (k9s, Lens, kubectx) are listed for local convenience but are never required.

Full tool list: [labs/tools.md](labs/tools.md).
