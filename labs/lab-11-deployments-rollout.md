# Lab 11 — Deployments and Rollouts: Rolling Update, Bad Image, rollout undo, pause/resume

Deployments are the primary workload object in Kubernetes and are tested extensively in the CKA exam's Workloads & Scheduling domain. This lab creates a Deployment, performs a rolling update with a new image, deliberately introduces a broken image to trigger a failed rollout, rolls back using `kubectl rollout undo`, and uses pause/resume to control the update process. Mastering the `kubectl rollout` subcommands is essential for the 15% Workloads domain.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)

---

## Step 1 — Create a Deployment

```bash
# Create a Deployment imperatively (faster for exam)
kubectl create deployment webapp \
  --image=nginx:1.25 \
  --replicas=4 \
  --port=80

# View the deployment
kubectl get deployment webapp
kubectl describe deployment webapp

# View the ReplicaSet created by the Deployment
kubectl get replicasets -l app=webapp

# View the pods
kubectl get pods -l app=webapp -o wide
```

Deployments manage ReplicaSets, which manage Pods. Each Deployment update creates a new ReplicaSet and gradually shifts pods from the old RS to the new one. This is the rolling update strategy.

---

## Step 2 — Expose the Deployment and Test It

```bash
# Expose as a ClusterIP service
kubectl expose deployment webapp --port=80 --target-port=80

# Verify the service
kubectl get svc webapp
CLUSTER_IP=$(kubectl get svc webapp -o jsonpath='{.spec.clusterIP}')

# Test the current version
kubectl run test-client --image=curlimages/curl --restart=Never \
  -- curl -s http://$CLUSTER_IP | grep nginx
# Expected: nginx version header

# Check rollout history (only 1 revision so far)
kubectl rollout history deployment webapp
# REVISION  CHANGE-CAUSE
# 1         <none>
```

The CHANGE-CAUSE column shows the annotation `kubernetes.io/change-cause`. Always use `--record` or manually set this annotation so rollout history is meaningful.

---

## Step 3 — Annotate the First Revision

```bash
# Add a change-cause annotation to make history useful
kubectl annotate deployment webapp \
  kubernetes.io/change-cause="initial deployment nginx:1.25"

# View updated history
kubectl rollout history deployment webapp
# REVISION  CHANGE-CAUSE
# 1         initial deployment nginx:1.25
```

The `kubernetes.io/change-cause` annotation is the convention for documenting what changed in each revision. Without it, `kubectl rollout history` shows `<none>` for every revision.

---

## Step 4 — Examine the Rolling Update Strategy

```bash
# View the update strategy in the Deployment
kubectl get deployment webapp -o yaml | grep -A 10 'strategy:'
# RollingUpdate is the default with:
#   maxUnavailable: 25% (at most 1 pod down for a 4-replica deployment)
#   maxSurge: 25% (at most 1 extra pod during update)

# Modify strategy for zero-downtime updates
kubectl patch deployment webapp --type=json \
  -p='[
    {"op":"replace","path":"/spec/strategy/rollingUpdate/maxUnavailable","value":"0"},
    {"op":"replace","path":"/spec/strategy/rollingUpdate/maxSurge","value":"1"}
  ]'

kubectl describe deployment webapp | grep -A 5 'RollingUpdateStrategy'
```

`maxUnavailable: 0` ensures zero downtime — the update only proceeds if new pods are healthy. `maxSurge: 1` allows one extra pod above the desired count during updates.

---

## Step 5 — Perform a Rolling Update

```bash
# Update the image to nginx:1.27
kubectl set image deployment/webapp webapp=nginx:1.27

# Annotate the change
kubectl annotate deployment webapp \
  kubernetes.io/change-cause="upgrade to nginx:1.27"

# Watch the rollout in real time
kubectl rollout status deployment webapp
# Waiting for deployment "webapp" rollout to finish:
# 1 out of 4 new replicas have been updated...
# 2 out of 4 new replicas have been updated...
# ...
# deployment "webapp" successfully rolled out

# View the new revision in history
kubectl rollout history deployment webapp
# REVISION  CHANGE-CAUSE
# 1         initial deployment nginx:1.25
# 2         upgrade to nginx:1.27

# Verify new image is running
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}'
# All pods should show nginx:1.27
```

During a rolling update, you can watch two ReplicaSets exist simultaneously — the old one scaling down and the new one scaling up. `kubectl rollout status` blocks until the rollout completes or fails.

---

## Step 6 — Introduce a Bad Image (Simulate a Failed Rollout)

```bash
# Deploy an image that doesn't exist — will cause ImagePullBackOff
kubectl set image deployment/webapp webapp=nginx:this-tag-does-not-exist-999

kubectl annotate deployment webapp \
  kubernetes.io/change-cause="bad upgrade to nginx:999 [BROKEN]"

# Watch the rollout fail
kubectl rollout status deployment webapp
# Waiting for deployment "webapp" rollout to finish:
# 1 out of 4 new replicas have been updated...
# (hangs because new pod can't start)

# In another terminal, observe the stuck pod
kubectl get pods -l app=webapp
# NAME                      READY   STATUS             RESTARTS
# webapp-xxxxx              1/1     Running            0       (old - still serving)
# webapp-xxxxx              1/1     Running            0       (old - still serving)
# webapp-xxxxx              1/1     Running            0       (old - still serving)
# webapp-new-xxxx           0/1     ImagePullBackOff   0       (new - broken)

# The service continues to work because old pods are still running!
kubectl run verify --image=curlimages/curl --restart=Never \
  -- curl -s http://$CLUSTER_IP | grep nginx
```

This demonstrates a key Kubernetes feature: rolling updates are safe by default. The broken pod cannot start (ImagePullBackOff), so the rolling update stalls rather than taking down all healthy pods. Traffic continues flowing to the old ReplicaSet.

---

## Step 7 — Roll Back to the Previous Version

```bash
# Ctrl+C the stuck rollout status command first

# Undo the last rollout (reverts to previous working version)
kubectl rollout undo deployment webapp

# Watch the rollback
kubectl rollout status deployment webapp
# Waiting for rollback to finish...
# deployment "webapp" successfully rolled out

# Verify the pods are back on nginx:1.27 (the last good version)
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}'
# nginx:1.27

# View updated history
kubectl rollout history deployment webapp
# REVISION  CHANGE-CAUSE
# 1         initial deployment nginx:1.25
# 3         upgrade to nginx:1.27
# 4         bad upgrade to nginx:999 [BROKEN]
# Note: revision 2 is gone, revision 4 is the rollback to rev 2
```

`kubectl rollout undo` reverts to the previous revision. Notice the revision numbers — rolling back creates a NEW revision (4 in this example) with the same configuration as the target. The original revision 2 is consumed.

---

## Step 8 — Roll Back to a Specific Revision

```bash
# View all available revisions with their details
kubectl rollout history deployment webapp --revision=1
kubectl rollout history deployment webapp --revision=3

# Roll back to revision 1 (the original nginx:1.25)
kubectl rollout undo deployment webapp --to-revision=1

kubectl rollout status deployment webapp

# Verify
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}'
# nginx:1.25 (original version)

# History now has a new revision 5
kubectl rollout history deployment webapp
```

`--to-revision=<n>` allows targeting any previous revision, not just the last one. This is useful when you need to skip over an intermediate "partially good" revision and go back further.

---

## Step 9 — Pause and Resume a Rollout

```bash
# Start an update but pause it immediately after
kubectl set image deployment/webapp webapp=nginx:1.27
kubectl rollout pause deployment webapp

# Check status — update is paused
kubectl rollout status deployment webapp
# Waiting for deployment "webapp" rollout to finish:
# 1 out of 4 new replicas have been updated...
# (paused - no more updates until resumed)

kubectl get pods -l app=webapp
# Mix of nginx:1.25 and nginx:1.27 pods

# Make additional changes while paused (batched update)
kubectl set resources deployment webapp \
  --containers=webapp \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=256Mi

# Resume the rollout — now applies image + resource changes together
kubectl rollout resume deployment webapp
kubectl rollout status deployment webapp
# deployment "webapp" successfully rolled out
```

Pause/resume lets you make multiple changes to a Deployment and apply them in a single rollout, rather than triggering a separate rollout for each change. This is especially useful when updating both the image and resource limits simultaneously.

---

## Step 10 — Deployment Scaling

```bash
# Scale up
kubectl scale deployment webapp --replicas=6
kubectl get pods -l app=webapp

# Scale down
kubectl scale deployment webapp --replicas=2
kubectl get pods -l app=webapp

# Set autoscaling (requires metrics-server — see Lab 14 for full HPA)
kubectl autoscale deployment webapp \
  --min=2 --max=10 --cpu-percent=80

kubectl get hpa

# Remove the HPA
kubectl delete hpa webapp

# Restart all pods (rolling restart — useful when config changed)
kubectl rollout restart deployment webapp
kubectl rollout status deployment webapp
```

`kubectl rollout restart` triggers a rolling restart without changing the image or config. This is the clean way to force pods to re-read mounted ConfigMaps or Secrets (when `subPath` is used — otherwise live updates work).

---

## Step 11 — Deployment YAML Reference

```bash
# Generate the YAML without creating (useful for exam)
kubectl create deployment webapp2 \
  --image=nginx:1.27 \
  --replicas=3 \
  --dry-run=client -o yaml

# Full deployment spec reference:
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-full
  labels:
    app: webapp-full
  annotations:
    kubernetes.io/change-cause: "full spec example"
spec:
  replicas: 3
  revisionHistoryLimit: 5        # Keep last 5 ReplicaSets for rollback
  selector:
    matchLabels:
      app: webapp-full
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: webapp-full
    spec:
      containers:
      - name: webapp
        image: nginx:1.27
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
EOF

kubectl rollout status deployment webapp-full
```

---

## Free online tools
- **Kubernetes Docs — Deployments**: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- Deployments manage rolling updates by creating new ReplicaSets and gradually shifting pod traffic
- `kubectl set image` updates the container image and triggers a new rollout
- `kubectl rollout status` blocks until the rollout completes or fails — use it to wait programmatically
- A bad image (ImagePullBackOff) stalls the rollout without taking down healthy pods (rolling update safety)
- `kubectl rollout undo` reverts to the previous revision; `--to-revision=N` targets any historical revision
- `kubectl rollout history` shows revision history; `kubernetes.io/change-cause` annotation documents each change
- `kubectl rollout pause` and `kubectl rollout resume` allow batching multiple changes into one rollout
- `revisionHistoryLimit` controls how many old ReplicaSets are retained for rollback
- `kubectl scale` changes replica count immediately; `kubectl rollout restart` triggers a rolling pod restart
- `maxUnavailable: 0` with `maxSurge: 1` achieves zero-downtime deployments
