# CKA 2026 Labs

Hands-on labs for the **Certified Kubernetes Administrator (CKA)** exam — updated for the 2026 curriculum (Kubernetes v1.35). All labs run in free browser-based environments with no local installation required.

## Exam overview

- **Duration**: 2 hours
- **Format**: Performance-based (hands-on tasks in a live cluster)
- **Pass score**: 66%
- **Allowed references**: kubernetes.io/docs, etcd.io/docs, helm.sh/docs
- **Primary environment**: Killercoda (https://killercoda.com/playgrounds/scenario/kubernetes)

---

## Domain weights and lab mapping

| Domain | Weight | Labs |
|--------|--------|------|
| **Cluster Architecture, Installation & Configuration** | 25% | 01–10 |
| **Workloads & Scheduling** | 15% | 11–16 |
| **Services & Networking** | 20% | 17–22 |
| **Storage** | 10% | 23–25 |
| **Troubleshooting** | 30% | 26–31 |

---

## Lab index

### Domain 1 — Cluster Architecture, Installation & Configuration (25%)

| Lab | Title | Killercoda Environment |
|-----|-------|----------------------|
| [Lab 01](lab-01-kubeadm-prereqs.md) | kubeadm Prerequisites and System Setup | kubeadm playground |
| [Lab 02](lab-02-kubeadm-bootstrap.md) | Bootstrap a Kubernetes Cluster with kubeadm | kubeadm playground |
| [Lab 03](lab-03-cni-calico.md) | Install and Verify a CNI Plugin (Calico) | kubeadm playground |
| [Lab 04](lab-04-cluster-upgrade.md) | Cluster Upgrade with kubeadm | kubeadm playground |
| [Lab 05](lab-05-ha-control-plane.md) | High-Availability Control Plane | kubeadm playground |
| [Lab 06](lab-06-helm.md) | Helm Chart Management | kubernetes playground |
| [Lab 07](lab-07-kustomize.md) | Kustomize for Environment-Specific Configs | kubernetes playground |
| [Lab 08](lab-08-rbac.md) | RBAC — Users, ServiceAccounts, and Roles | kubernetes playground |
| [Lab 09](lab-09-crds-operators.md) | Custom Resource Definitions and Operators | kubernetes playground |
| [Lab 10](lab-10-extension-interfaces.md) | CNI, CSI, and CRI Extension Interfaces | kubeadm playground |

### Domain 2 — Workloads & Scheduling (15%)

| Lab | Title | Killercoda Environment |
|-----|-------|----------------------|
| [Lab 11](lab-11-deployments-rollout.md) | Deployments and Rolling Updates | kubernetes playground |
| [Lab 12](lab-12-configmaps.md) | ConfigMaps — Env Variables and Volume Mounts | kubernetes playground |
| [Lab 13](lab-13-secrets.md) | Secrets — Types, Encryption, and Rotation | kubernetes playground |
| [Lab 14](lab-14-hpa.md) | Horizontal Pod Autoscaler (autoscaling/v2) | kubernetes playground |
| [Lab 15](lab-15-self-healing.md) | Self-Healing — DaemonSets and StatefulSets | kubernetes playground |
| [Lab 16](lab-16-scheduling.md) | Scheduling — Affinity, Taints, PriorityClasses | kubernetes playground |

### Domain 3 — Services & Networking (20%)

| Lab | Title | Killercoda Environment |
|-----|-------|----------------------|
| [Lab 17](lab-17-pod-connectivity.md) | Pod-to-Pod Connectivity and DNS | kubernetes playground |
| [Lab 18](lab-18-service-types.md) | Service Types — ClusterIP, NodePort, LoadBalancer | kubernetes playground |
| [Lab 19](lab-19-ingress.md) | Ingress Controller and Resources | kubernetes playground |
| [Lab 20](lab-20-gateway-api.md) | Gateway API (GatewayClass, Gateway, HTTPRoute) | kubernetes playground |
| [Lab 21](lab-21-network-policies.md) | NetworkPolicy — Ingress and Egress Rules | kubernetes playground |
| [Lab 22](lab-22-coredns.md) | CoreDNS — Configuration and Customisation | kubernetes playground |

### Domain 4 — Storage (10%)

| Lab | Title | Killercoda Environment |
|-----|-------|----------------------|
| [Lab 23](lab-23-pv-pvc.md) | PersistentVolume and PersistentVolumeClaim | kubernetes playground |
| [Lab 24](lab-24-storageclass.md) | StorageClass and Dynamic Provisioning | kubernetes playground |
| [Lab 25](lab-25-volume-types.md) | Volume Types — emptyDir, hostPath, projected, downwardAPI | kubernetes playground |

### Domain 5 — Troubleshooting (30%)

| Lab | Title | Killercoda Environment |
|-----|-------|----------------------|
| [Lab 26](lab-26-troubleshoot-components.md) | Troubleshoot Cluster Components (API server, etcd) | kubeadm playground |
| [Lab 27](lab-27-troubleshoot-nodes.md) | Troubleshoot Nodes — kubelet and containerd | kubeadm playground |
| [Lab 28](lab-28-logs-streams.md) | Application Logs and Container Streams | kubernetes playground |
| [Lab 29](lab-29-monitoring.md) | Monitor Cluster and Application Usage | kubernetes playground |
| [Lab 30](lab-30-troubleshoot-net.md) | Troubleshoot Networking (7-step triage) | kubernetes playground |
| [Lab 31](lab-31-troubleshoot-rbac-sched.md) | Troubleshoot RBAC and Scheduling Failures | kubernetes playground |

---

## Quick start

1. Open the Killercoda playground for the lab you're starting (link in each lab header).
2. Set up exam aliases immediately:
   ```bash
   source <(kubectl completion bash)
   alias k=kubectl
   complete -o default -F __start_kubectl k
   export do="--dry-run=client -o yaml"
   export now="--force --grace-period=0"
   ```
3. Follow the lab steps. Every step has expected output noted.
4. Run the clean-up section before moving to the next lab.

---

## API versions reference (Kubernetes v1.35)

| Resource | apiVersion |
|----------|-----------|
| Pod, Service, PV, PVC, ConfigMap, Secret | `v1` |
| Deployment, DaemonSet, StatefulSet, ReplicaSet | `apps/v1` |
| CronJob, Job | `batch/v1` |
| Ingress, NetworkPolicy | `networking.k8s.io/v1` |
| Gateway, HTTPRoute | `gateway.networking.k8s.io/v1` |
| HPA | `autoscaling/v2` |
| PodDisruptionBudget | `policy/v1` |
| ClusterRole, Role, *Binding | `rbac.authorization.k8s.io/v1` |
| StorageClass | `storage.k8s.io/v1` |
| CRD | `apiextensions.k8s.io/v1` |

---

## Must-know exam commands

```bash
# RBAC: check permissions
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>

# etcd backup (memorise the cert flags)
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/backup.db

# Fix a NotReady node
sudo systemctl status kubelet
sudo journalctl -u kubelet -n 50

# Drain before maintenance
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Debug networking
kubectl exec <pod> -- nslookup <svc>
kubectl get endpoints <svc>
```

See [tools.md](tools.md) for the full tool reference and exam-day setup.
