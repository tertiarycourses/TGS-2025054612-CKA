# Free Tools Reference — CKA v1.35 (2026) Labs

Every tool listed here is **100% free**. No credit card, no time limit.

Two categories:
1. **Inside Killercoda** — pre-installed in the disposable Kubernetes or kubeadm VM.
2. **External / Browser** — used outside the VM for reference, practice, or validation.

Primary lab environment (free, no signup required):
- **Standard cluster:** https://killercoda.com/playgrounds/scenario/kubernetes
- **kubeadm (two empty nodes):** https://killercoda.com/playgrounds/scenario/kubeadm

Alternative environments if Killercoda is unavailable:
- **Play with Kubernetes**: https://labs.play-with-k8s.com
- **GitHub Codespaces** (free quota): https://github.com/features/codespaces

---

## Section A — Tools Pre-Installed in Killercoda VMs

### A1. Core Kubernetes Tools
| Tool | Purpose | Labs |
|------|---------|------|
| `kubectl` | All Kubernetes operations | All labs |
| `kubeadm` | Cluster bootstrap, upgrade, join | 1–5 |
| `kubelet` | Node agent (inspect/restart via systemctl) | 1–5, 26–27 |
| `crictl` | CRI client — inspect containers when API server is down | 1, 10, 26 |
| `kubectl kustomize` | Kustomize rendering (built into kubectl) | 7 |
| `helm` | Install via one-line script (Lab 6 Step 1) | 6 |

### A2. etcd Tools
| Tool | Purpose | Labs |
|------|---------|------|
| `etcdctl` | `snapshot save` and `snapshot restore` for etcd backup | 5 |
| `ETCDCTL_API=3` | Must be set to use v3 API | 5 |

### A3. System and Network Tools
| Tool | Install | Purpose | Labs |
|------|---------|---------|------|
| `systemctl` | pre-installed | Start/stop/enable kubelet, containerd | 1–5, 26–27 |
| `journalctl` | pre-installed | Read kubelet and containerd logs | 26–27 |
| `curl` | pre-installed | Test HTTP Services and Ingress | 17–22, 29–30 |
| `nslookup` / `dig` | pre-installed | DNS resolution testing | 22, 30 |
| `openssl` | pre-installed | Inspect TLS certificates | 19 |
| `ip route` / `ip addr` | pre-installed | Inspect node networking | 3, 17 |
| `netshoot` | `kubectl run` (docker image) | Advanced network troubleshooting | 17, 30 |

### A4. Text Manipulation
| Tool | Purpose | Labs |
|------|---------|------|
| `sed` | In-place YAML edits and manifest fixes | 1–5 |
| `grep` | Filter `describe` and `get` output | All labs |
| `base64` | Encode/decode Secret values | 13 |
| `jq` | JSON parsing (`apt install jq`) | 10 |

---

## Section B — External / Browser Tools

### B1. Exam Practice
| Tool | URL | Purpose |
|------|-----|---------|
| **Tertiary Infotech CKA Practice Exam** | https://exams.tertiaryinfotech.com/practice-exams/linuxfoundation/linuxfoundation-cka | CKA practice exam — exam-style questions to test your readiness |
| **Killercoda CKA** | https://killercoda.com/cka | Community CKA practice scenarios |

### B2. Official Documentation (allowed in CKA exam)
| Resource | URL | Purpose |
|----------|-----|---------|
| Kubernetes docs | https://kubernetes.io/docs/ | Main reference for all lab tasks |
| kubectl Cheat Sheet | https://kubernetes.io/docs/reference/kubectl/cheatsheet/ | Command quick-reference |
| kubeadm reference | https://kubernetes.io/docs/reference/setup-tools/kubeadm/ | Bootstrap and upgrade docs |
| Helm docs | https://helm.sh/docs/ | Helm chart and CLI reference |
| Calico docs | https://docs.tigera.io/calico/latest/getting-started/ | CNI plugin reference |

### B3. Utility Tools
| Tool | URL | Purpose |
|------|-----|---------|
| **YAML Lint** | https://www.yamllint.com | Validate YAML manifests before applying |
| **Kubernetes YAML validator** | https://k8syaml.com | Check K8s manifest correctness |
| **Base64 decoder** | https://www.base64decode.org | Decode Secret values |
| **CronTab Guru** | https://crontab.guru | Verify CronJob schedule expressions |
| **RegexR** | https://regexr.com | Test selector and label expressions |

---

## CKA Exam Tips

- All five kubernetes.io sub-domains are allowed open-book during the exam.
- The exam environment pre-configures `alias k=kubectl` and bash completion.
- `export do="--dry-run=client -o yaml"` is the fastest way to generate manifest skeletons.
- Time budget: ~5–7 minutes per task. Skip and flag if stuck; return later.
- `kubectl explain <resource>.<field>` is faster than searching docs for field names.
