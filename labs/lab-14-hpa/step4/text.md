# Step 4 — Generate load

In a new terminal:

```bash
kubectl run -i --tty load --image=busybox --restart=Never -- /bin/sh -c \
  "while true; do wget -q -O- http://php-apache; done"
```

Watch:

```bash
kubectl get hpa -w
kubectl get pods -l app=php-apache -w
```

CPU should climb above 50%, the HPA replica count should rise toward 5.
