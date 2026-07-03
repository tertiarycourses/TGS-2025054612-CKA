# Lab 11 — Deployments: Rolling Update and Rollback

In this lab you create a Deployment, perform a rolling update by changing the image, watch the rollout, then roll back to the previous revision.

**Lab environment:** [KillerCoda](https://killercoda.com/tertiary-labs-cka/course/killercoda/lab-11-deployments-rollout)
---

## Step 1 — Create the Deployment

```bash
kubectl create deployment web --image=nginx:1.25 --replicas=4
kubectl rollout status deploy/web
kubectl get pods -l app=web -o wide
```

---

## Step 2 — Inspect the strategy

```bash
kubectl get deploy web -o yaml | grep -A5 strategy
```

Default is `RollingUpdate` with `maxSurge: 25%` and `maxUnavailable: 25%`.

---

## Step 3 — Perform a rolling update

```bash
kubectl set image deploy/web nginx=nginx:1.26 --record
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```

Watch in another shell:

```bash
kubectl get pods -l app=web -w
```

You'll see new pods come up while old ones are still serving — that's the surge.

---

## Step 4 — Cause a bad rollout

```bash
kubectl set image deploy/web nginx=nginx:doesnotexist
kubectl rollout status deploy/web --timeout=30s
kubectl get pods -l app=web
```

New replicas stay `ImagePullBackOff`; old replicas keep serving.

---

## Step 5 — Roll back

```bash
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```

Go back to a specific revision:

```bash
kubectl rollout undo deploy/web --to-revision=1
```

---

## Step 6 — Pause and resume

```bash
kubectl rollout pause deploy/web
kubectl set image deploy/web nginx=nginx:1.27
kubectl set resources deploy/web --limits=cpu=200m,memory=256Mi
kubectl rollout resume deploy/web
kubectl rollout status deploy/web
```

Pause batches multiple changes into one rollout.

---

## Step 7 — Cleanup

```bash
kubectl delete deploy web
```

---

## What you learned
- `RollingUpdate` strategy, `maxSurge` and `maxUnavailable`.
- `rollout status`, `history`, `undo`, `pause`, `resume`.
- How a Deployment tracks each revision as a ReplicaSet.
