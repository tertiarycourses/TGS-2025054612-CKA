# Lab 11 — Deployments: Rolling Update and Rollback

In this lab you create a Deployment, perform a rolling update by changing the image, watch the rollout, then roll back to the previous revision.

**What you will do:**
- Create a Deployment with 4 replicas
- Inspect the default RollingUpdate strategy
- Perform a rolling update and watch the rollout
- Trigger a bad rollout with a non-existent image
- Roll back to a previous revision
- Pause, apply multiple changes, then resume as a single rollout
- Clean up
