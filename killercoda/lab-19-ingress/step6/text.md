# Step 6 — Path-based routing (reference)

```yaml
rules:
- http:
    paths:
    - { path: /a, pathType: Prefix, backend: { service: { name: app1, port: { number: 80 } } } }
    - { path: /b, pathType: Prefix, backend: { service: { name: app2, port: { number: 80 } } } }
```
