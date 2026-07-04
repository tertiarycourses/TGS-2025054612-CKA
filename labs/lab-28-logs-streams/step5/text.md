# Step 5 — Multi-pod tail with stern (optional)

```bash
GO111MODULE=on go install github.com/stern/stern@latest 2>/dev/null || \
  curl -L https://github.com/stern/stern/releases/download/v1.30.0/stern_1.30.0_linux_amd64.tar.gz \
    | sudo tar -xz -C /usr/local/bin stern
stern chatty --tail 5
```

Ctrl-C to stop. `stern` follows logs across pods, containers, and namespaces in one stream.
