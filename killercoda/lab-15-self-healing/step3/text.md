# Step 3 — ReplicaSet self-heal

```bash
kubectl create deployment rs-demo --image=nginx --replicas=3
kubectl get pods -l app=rs-demo
POD=$(kubectl get pods -l app=rs-demo -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD
kubectl get pods -l app=rs-demo -w
```

A new pod is spawned within seconds. The ReplicaSet controller continuously reconciles `desired` vs `actual`.
