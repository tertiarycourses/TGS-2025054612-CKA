# Lab 14 — Horizontal Pod Autoscaling

The Horizontal Pod Autoscaler (HPA) scales a Deployment up and down based on observed CPU/memory or custom metrics. In this lab you install `metrics-server`, deploy a CPU-burning app, attach an HPA, then stress it.

**Lab environment:** [Play with Kubernetes](https://killercoda.com/playgrounds/course/kubernetes-playgrounds/two-node)
---

## Step 1 — Install metrics-server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deploy metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deploy/metrics-server --timeout=90s
kubectl top nodes
kubectl top pods -A
```

`--kubelet-insecure-tls` is needed in lab environments where the kubelet uses self-signed certs.

---

## Step 2 — Deploy a CPU-bound workload

```bash
kubectl create deployment php-apache --image=registry.k8s.io/hpa-example
kubectl set resources deploy/php-apache --requests=cpu=100m --limits=cpu=500m
kubectl expose deployment php-apache --port=80
kubectl rollout status deploy/php-apache
```

---

## Step 3 — Create the HPA

```bash
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=5
kubectl get hpa
```

---

## Step 4 — Generate load

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

---

## Step 5 — Stop the load and watch scale-down

Ctrl-C the load generator, then:

```bash
kubectl delete pod load
kubectl get hpa -w
```

After ~5 minutes (default stabilization window) the HPA scales back to 1.

---

## Step 6 — HPA v2 with multiple metrics (reference)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: php-apache }
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target: { type: Utilization, averageUtilization: 50 }
  - type: Resource
    resource:
      name: memory
      target: { type: AverageValue, averageValue: 200Mi }
```

---

## Step 7 — Cleanup

```bash
kubectl delete hpa php-apache
kubectl delete deploy php-apache
kubectl delete svc php-apache
```

---

## What you learned
- metrics-server is a prerequisite for `kubectl top` and HPA.
- HPA needs `resources.requests` on the target Deployment.
- Stabilization window prevents flapping.
