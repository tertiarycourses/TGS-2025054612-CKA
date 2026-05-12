# CKA Curriculum v1.35 — Lab Index

Most labs run on the free Killercoda Kubernetes Playground (single-node cluster, pre-built):
**https://killercoda.com/playgrounds/scenario/kubernetes**

Install / upgrade / HA labs run on the Killercoda kubeadm Playground (two empty Ubuntu nodes):
**https://killercoda.com/playgrounds/scenario/kubeadm**

No installs required on your own machine — every package is pulled with `apt` inside the throw-away VMs.

---

## Domain 1 — Cluster Architecture, Installation and Configuration (25%)

| # | Lab | Playground | Free software needed |
|---|-----|------------|----------------------|
| 1 | [kubeadm Prerequisites and Container Runtime](lab-01-kubeadm-prereqs.md) | kubeadm | `containerd`, `kubeadm`, `kubelet`, `kubectl` (apt) |
| 2 | [Bootstrap a Cluster with kubeadm](lab-02-kubeadm-bootstrap.md) | kubeadm | `kubeadm` |
| 3 | [Install a CNI Plugin (Calico)](lab-03-cni-calico.md) | kubeadm | Calico manifest |
| 4 | [Cluster Upgrade with kubeadm](lab-04-cluster-upgrade.md) | kubeadm | `kubeadm`, `apt` |
| 5 | [Highly-Available Control Plane](lab-05-ha-control-plane.md) | kubeadm (concept) | `kubeadm`, `keepalived`/`haproxy` (reference) |
| 6 | [Install Components with Helm](lab-06-helm.md) | kubernetes | `helm` |
| 7 | [Customize Manifests with Kustomize](lab-07-kustomize.md) | kubernetes | `kubectl` (built-in kustomize) |
| 8 | [RBAC: Roles, RoleBindings, ServiceAccounts](lab-08-rbac.md) | kubernetes | `kubectl` |
| 9 | [CRDs and Operators](lab-09-crds-operators.md) | kubernetes | `kubectl`, `helm` |
| 10 | [Extension Interfaces (CNI, CSI, CRI)](lab-10-extension-interfaces.md) | kubernetes | `crictl`, `kubectl` |

## Domain 2 — Workloads and Scheduling (15%)

| # | Lab | Playground | Free software needed |
|---|-----|------------|----------------------|
| 11 | [Deployments: Rolling Update and Rollback](lab-11-deployments-rollout.md) | kubernetes | `kubectl` |
| 12 | [ConfigMaps](lab-12-configmaps.md) | kubernetes | `kubectl` |
| 13 | [Secrets](lab-13-secrets.md) | kubernetes | `kubectl`, `base64` |
| 14 | [Horizontal Pod Autoscaling](lab-14-hpa.md) | kubernetes | `metrics-server`, `kubectl` |
| 15 | [Self-Healing Primitives (Probes, RS, DS, StatefulSet)](lab-15-self-healing.md) | kubernetes | `kubectl` |
| 16 | [Pod Scheduling (Limits, Affinity, Taints)](lab-16-scheduling.md) | kubernetes | `kubectl` |

## Domain 3 — Services and Networking (20%)

| # | Lab | Playground | Free software needed |
|---|-----|------------|----------------------|
| 17 | [Pod-to-Pod Connectivity](lab-17-pod-connectivity.md) | kubernetes | `kubectl`, `curl` |
| 18 | [Service Types: ClusterIP, NodePort, LoadBalancer](lab-18-service-types.md) | kubernetes | `kubectl`, `curl` |
| 19 | [Ingress Controller and Resources](lab-19-ingress.md) | kubernetes | ingress-nginx |
| 20 | [Gateway API](lab-20-gateway-api.md) | kubernetes | Gateway API CRDs |
| 21 | [Network Policies](lab-21-network-policies.md) | kubernetes | Calico/Cilium CNI |
| 22 | [CoreDNS](lab-22-coredns.md) | kubernetes | `kubectl`, `dig` |

## Domain 4 — Storage (10%)

| # | Lab | Playground | Free software needed |
|---|-----|------------|----------------------|
| 23 | [PersistentVolume and PersistentVolumeClaim](lab-23-pv-pvc.md) | kubernetes | `kubectl` |
| 24 | [StorageClass and Dynamic Provisioning](lab-24-storageclass.md) | kubernetes | local-path-provisioner |
| 25 | [Volume Types in Pods](lab-25-volume-types.md) | kubernetes | `kubectl` |

## Domain 5 — Troubleshooting (30%)

| # | Lab | Playground | Free software needed |
|---|-----|------------|----------------------|
| 26 | [Troubleshoot Cluster Components](lab-26-troubleshoot-components.md) | kubeadm | `kubectl`, `journalctl`, `crictl` |
| 27 | [Troubleshoot Nodes](lab-27-troubleshoot-nodes.md) | kubeadm | `kubectl`, `systemctl` |
| 28 | [Application Logs and Container Streams](lab-28-logs-streams.md) | kubernetes | `kubectl`, `stern` (optional) |
| 29 | [Monitor Cluster and Application Usage](lab-29-monitoring.md) | kubernetes | metrics-server, Prometheus (optional) |
| 30 | [Troubleshoot Services and Networking](lab-30-troubleshoot-net.md) | kubernetes | `kubectl`, `dig`, `curl` |
| 31 | [Troubleshoot RBAC and Scheduling Failures](lab-31-troubleshoot-rbac-sched.md) | kubernetes | `kubectl auth can-i` |

---

## Suggested order

Work through Domain 1 → 2 → 3 → 4 → 5 in numeric order. Labs 1–5 must be done on the **kubeadm** playground because they require an un-initialized cluster. Reset the Kubernetes playground between Labs 21 (NetworkPolicy), 8 (RBAC), and 9 (CRDs) to avoid carry-over.
