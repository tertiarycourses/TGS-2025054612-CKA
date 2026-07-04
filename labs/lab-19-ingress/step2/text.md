# Step 2 — Deploy two backends

```bash
kubectl create deployment app1 --image=hashicorp/http-echo --port=5678 -- \
  -text="hello from app1"
kubectl create deployment app2 --image=hashicorp/http-echo --port=5678 -- \
  -text="hello from app2"
kubectl expose deploy app1 --port=80 --target-port=5678
kubectl expose deploy app2 --port=80 --target-port=5678
```
