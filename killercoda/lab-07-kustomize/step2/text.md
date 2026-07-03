# Step 2 — Create the dev overlay

```bash
mkdir -p kustom/overlays/dev
cat > kustom/overlays/dev/kustomization.yaml <<'EOF'
namespace: web-dev
resources:
  - ../../base
patches:
  - target: { kind: Deployment, name: web }
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 1
images:
  - name: nginx
    newTag: "1.25"
EOF
```
