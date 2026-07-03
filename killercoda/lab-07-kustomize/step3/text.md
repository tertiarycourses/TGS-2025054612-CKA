# Step 3 — Create the prod overlay

```bash
mkdir -p kustom/overlays/prod
cat > kustom/overlays/prod/kustomization.yaml <<'EOF'
namespace: web-prod
resources:
  - ../../base
patches:
  - target: { kind: Deployment, name: web }
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 4
images:
  - name: nginx
    newTag: "1.27"
EOF
```
