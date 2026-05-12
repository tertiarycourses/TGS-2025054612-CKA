# Free Tools Reference — CKA Curriculum v1.35 Labs

Every tool listed here is **100% free** (open-source, freeware, or free tier with no time limit).

Two categories:

1. **Inside Killercoda** — pre-installed or `apt`-installed in the Kubernetes / kubeadm playgrounds. Nothing touches your own machine.
2. **External / Standalone** — downloaded onto your own PC/laptop, or used in a browser. Useful when you're offline, on a school PC, or want a GUI.

Free Killercoda playgrounds (no signup):
- Pre-built cluster: https://killercoda.com/playgrounds/scenario/kubernetes
- Empty kubeadm nodes: https://killercoda.com/playgrounds/scenario/kubeadm

---

## Section A — Tools available inside the Killercoda VMs

### A1. Core Kubernetes binaries (pre-installed)
| Tool | Purpose | Used in Lab |
|------|---------|-------------|
| `kubectl` | Kubernetes CLI | all labs |
| `kubeadm` | Bootstrap & lifecycle | 1, 2, 4, 5, 26 |
| `kubelet` | Node agent | 1, 2, 26, 27 |
| `containerd` | Container runtime (CRI) | 1, 10, 26, 27 |
| `crictl` | CRI debug tool | 10, 26, 27 |
| `etcdctl` | etcd client | 26 |

### A2. Networking add-ons installed during labs
| Tool | Install | Purpose | Lab |
|------|---------|---------|-----|
| Calico | `kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml` | CNI + NetworkPolicy | 3, 21 |
| ingress-nginx | `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml` | Ingress controller | 19 |
| Gateway API CRDs | `kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml` | Gateway API | 20 |
| metrics-server | `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml` | Resource metrics | 14, 29 |

### A3. Package & manifest tooling
| Tool | Install | Purpose | Lab |
|------|---------|---------|-----|
| `helm` | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` | Kubernetes package manager | 6, 9 |
| `kustomize` | built into `kubectl -k` | Overlay-based manifest generation | 7 |

### A4. Storage add-ons
| Tool | Install | Purpose | Lab |
|------|---------|---------|-----|
| local-path-provisioner | `kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml` | Dynamic local-disk PVs | 24 |

### A5. Linux diagnostics (apt)
| Tool | Install | Purpose | Lab |
|------|---------|---------|-----|
| `journalctl` | pre-installed (systemd) | Service logs (kubelet, containerd) | 26, 27 |
| `systemctl` | pre-installed | Service control | 26, 27 |
| `dig` / `nslookup` | `apt install dnsutils` | DNS queries against CoreDNS | 22, 30 |
| `curl` | pre-installed | HTTP probe | 17, 18, 19, 30 |
| `nc` | `apt install netcat-openbsd` | TCP port test | 30 |
| `tcpdump` | `apt install tcpdump` | Packet capture | 30 |

### A6. Operators / sample CRDs
| Tool | Install | Purpose | Lab |
|------|---------|---------|-----|
| cert-manager | helm chart `jetstack/cert-manager` | Example operator with CRDs | 9 |

---

## Section B — External / Standalone Free Tools (download or browser)

### B1. Kubernetes GUIs and dashboards
| Tool | Type | Link |
|------|------|------|
| Kubernetes Dashboard | In-cluster web UI | https://github.com/kubernetes/dashboard |
| Lens Desktop | Free GUI (Win/Mac/Linux) | https://k8slens.dev |
| OpenLens | OSS build of Lens | https://github.com/MuhammedKalkan/OpenLens |
| Headlamp | GUI (CNCF) | https://headlamp.dev |
| k9s | Terminal UI | https://k9scli.io |
| Octant | Read-only dashboard | https://octant.dev |

### B2. kubectl helpers
| Tool | Type | Link |
|------|------|------|
| kubectx + kubens | Context/namespace switcher | https://github.com/ahmetb/kubectx |
| krew | kubectl plugin manager | https://krew.sigs.k8s.io |
| stern | Multi-pod log tailing | https://github.com/stern/stern |
| kubecolor | Colorized kubectl | https://github.com/kubecolor/kubecolor |
| fubectl | Bash aliases | https://github.com/kubermatic/fubectl |

### B3. Manifest & policy tooling
| Tool | Type | Link |
|------|------|------|
| Helm | Package manager | https://helm.sh |
| Kustomize | Overlay tool | https://kustomize.io |
| kubeval | Schema validation | https://github.com/instrumenta/kubeval |
| kube-linter | Best-practice linter | https://github.com/stackrox/kube-linter |
| Kyverno | Policy engine | https://kyverno.io |
| OPA Gatekeeper | Policy engine | https://open-policy-agent.github.io/gatekeeper |
| Polaris | Audit dashboard | https://polaris.docs.fairwinds.com |

### B4. Browser sandboxes (Killercoda alternatives)
| Service | What you get | Link |
|---------|-------------|------|
| Killercoda Kubernetes Playground | Pre-built 1cp+1w cluster | https://killercoda.com/playgrounds/scenario/kubernetes |
| Killercoda kubeadm Playground | Two empty Ubuntu nodes | https://killercoda.com/playgrounds/scenario/kubeadm |
| Play with Kubernetes | 4-hour live cluster | https://labs.play-with-k8s.com |
| Minikube | Local single-node | https://minikube.sigs.k8s.io |
| Kind | Local cluster in Docker | https://kind.sigs.k8s.io |
| k3d / k3s | Lightweight local | https://k3d.io |

### B5. Monitoring (Lab 29)
| Tool | Type | Link |
|------|------|------|
| metrics-server | Required for `kubectl top` & HPA | https://github.com/kubernetes-sigs/metrics-server |
| Prometheus + Grafana | OSS stack | https://prometheus.io / https://grafana.com |
| kube-prometheus-stack | Helm chart | https://github.com/prometheus-community/helm-charts |
| Kubernetes Event Exporter | Stream events | https://github.com/resmoio/kubernetes-event-exporter |
| KubeShark | Wireshark-like traffic viewer | https://kubeshark.co |

### B6. Networking / Ingress (Lab 19, 20, 21)
| Tool | Type | Link |
|------|------|------|
| ingress-nginx | Ingress controller | https://kubernetes.github.io/ingress-nginx |
| Traefik | Ingress + Gateway controller | https://traefik.io |
| Contour | Gateway / Envoy-based | https://projectcontour.io |
| Istio | Service mesh + Gateway | https://istio.io |
| Linkerd | Service mesh | https://linkerd.io |
| Cilium | CNI + NetworkPolicy + Gateway | https://cilium.io |
| Calico | CNI + NetworkPolicy | https://www.tigera.io/project-calico |

### B7. Storage (Lab 23, 24, 25)
| Tool | Type | Link |
|------|------|------|
| local-path-provisioner | Rancher dynamic local PV | https://github.com/rancher/local-path-provisioner |
| OpenEBS | OSS dynamic storage | https://openebs.io |
| Longhorn | Distributed block storage | https://longhorn.io |
| Rook + Ceph | Storage operator | https://rook.io |
| MinIO | S3-compatible object | https://min.io |

### B8. Security & RBAC (Lab 8, 31)
| Tool | Type | Link |
|------|------|------|
| rbac-tool | RBAC analyzer | https://github.com/alcideio/rbac-tool |
| kubectl-who-can | Who can do X | https://github.com/aquasecurity/kubectl-who-can |
| Trivy | Image / cluster scanner | https://aquasecurity.github.io/trivy |
| kube-bench | CIS Benchmark | https://github.com/aquasecurity/kube-bench |
| Falco | Runtime security | https://falco.org |

### B9. Operators & CRDs (Lab 9)
| Tool | Type | Link |
|------|------|------|
| OperatorHub.io | Catalog | https://operatorhub.io |
| cert-manager | Cert lifecycle | https://cert-manager.io |
| ArgoCD | GitOps | https://argo-cd.readthedocs.io |
| Flux | GitOps | https://fluxcd.io |
| External-DNS | DNS sync operator | https://github.com/kubernetes-sigs/external-dns |

### B10. Editors / IDE integration
| Tool | Type | Link |
|------|------|------|
| VS Code Kubernetes extension | Free | https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools |
| JetBrains Kubernetes plugin | Free (in IDEs) | https://plugins.jetbrains.com/plugin/10485-kubernetes |
| YAML Language Server | LSP | https://github.com/redhat-developer/yaml-language-server |

---

## Lab → Primary Tool Quick Map

| Lab | Headline tool(s) |
|-----|------------------|
| 1 | containerd, kubeadm, kubelet, kubectl |
| 2 | kubeadm init / join |
| 3 | Calico manifest |
| 4 | kubeadm upgrade |
| 5 | kubeadm + keepalived/haproxy |
| 6 | helm |
| 7 | kubectl -k (kustomize) |
| 8 | kubectl create role/rolebinding |
| 9 | kubectl apply CRD, helm cert-manager |
| 10 | crictl, kubectl get csidrivers |
| 11 | kubectl rollout |
| 12 | kubectl create configmap |
| 13 | kubectl create secret |
| 14 | metrics-server, kubectl autoscale |
| 15 | probes, ReplicaSet, DaemonSet, StatefulSet |
| 16 | resources, nodeAffinity, taints |
| 17 | kubectl exec, curl |
| 18 | kubectl expose |
| 19 | ingress-nginx |
| 20 | Gateway API CRDs |
| 21 | NetworkPolicy + Calico |
| 22 | CoreDNS ConfigMap, dig |
| 23 | PV, PVC |
| 24 | StorageClass, local-path-provisioner |
| 25 | emptyDir, hostPath, projected, downwardAPI |
| 26 | journalctl, crictl, kubectl -n kube-system |
| 27 | systemctl, kubelet status, taints |
| 28 | kubectl logs, stern |
| 29 | metrics-server, kubectl top |
| 30 | dig, curl, kubectl get endpoints |
| 31 | kubectl auth can-i, describe pod |

---

All tools above are free of charge. The Killercoda VMs are also free and disposable, so you can run every lab without spending or installing anything on your own machine.
