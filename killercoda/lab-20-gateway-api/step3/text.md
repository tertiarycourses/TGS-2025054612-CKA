# Step 3 — Deploy a backend

```bash
kubectl create deployment echo --image=hashicorp/http-echo --port=5678 -- -text="gateway works"
kubectl expose deploy echo --port=80 --target-port=5678
```
