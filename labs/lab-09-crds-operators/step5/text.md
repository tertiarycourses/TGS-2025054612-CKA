# Step 5 — Clean up

```bash
kubectl delete certificate test-cert
kubectl delete issuer selfsigned
kubectl delete widget blue-widget
kubectl delete crd widgets.training.example.com
helm -n cert-manager uninstall cert-manager
```
