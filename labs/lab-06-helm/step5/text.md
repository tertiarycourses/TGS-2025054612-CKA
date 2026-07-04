# Step 5 — Roll back

```bash
helm -n web rollback web 1
helm -n web history web
```

Helm keeps the manifests of every revision in cluster secrets so rollback is instant.
