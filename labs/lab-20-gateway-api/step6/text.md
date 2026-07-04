# Step 6 — Test

```bash
GW_SVC=$(kubectl -n nginx-gateway get svc -o jsonpath='{.items[0].metadata.name}')
NODEPORT=$(kubectl -n nginx-gateway get svc $GW_SVC -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
curl -s -H "Host: echo.local" http://localhost:$NODEPORT
```
