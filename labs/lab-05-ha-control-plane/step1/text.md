# Step 1 — HA topology overview

The standard HA layout is "stacked etcd":

```
            VIP / LB :6443
                 │
   ┌─────────────┼─────────────┐
   ▼             ▼             ▼
cp-1          cp-2          cp-3        ← each runs apiserver + etcd member
   │             │             │
   └─────────────┼─────────────┘
                 ▼
              workers
```

The clients (kubectl, kubelets) talk to a **load-balanced virtual IP** that fronts the three apiservers. etcd runs as a 3-node Raft quorum on the same hosts.
