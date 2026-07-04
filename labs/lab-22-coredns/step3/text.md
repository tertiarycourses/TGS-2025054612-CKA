# Step 3 — Query Service records

```bash
kubectl create deployment web --image=nginx
kubectl expose deploy web --port=80
kubectl exec dnsdebug -- dig +short web.default.svc.cluster.local
kubectl exec dnsdebug -- dig +short web   # short name via search list
```
