# Lab 23 — PersistentVolume and PersistentVolumeClaim

A PersistentVolume (PV) is a piece of storage in the cluster. A PersistentVolumeClaim (PVC) is a pod's request for storage. In this lab you statically provision a `hostPath` PV, claim it, mount it, and explore access modes and reclaim policies.

**What you will do:**
- Prepare a host directory with a seed file
- Statically provision a hostPath PersistentVolume with Retain reclaim policy
- Create a PersistentVolumeClaim and observe PV binding
- Mount the PVC into an nginx pod and verify the host file is served
- Write data from the pod, delete the pod, recreate it, and confirm data survives
- Delete the PVC and inspect the PV's Released state under Retain policy
