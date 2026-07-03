# Step 2 — Create from a file

```bash
cat > app.properties <<'EOF'
log.level=INFO
cache.ttl=300
EOF
kubectl create configmap app-properties --from-file=app.properties
kubectl describe configmap app-properties
```
