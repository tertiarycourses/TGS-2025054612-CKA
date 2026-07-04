# Lab 24 — StorageClass and Dynamic Provisioning

Static PVs don't scale. With dynamic provisioning, a StorageClass + CSI driver creates a PV on demand when a PVC is submitted. In this lab you install the local-path-provisioner, create a default StorageClass, and watch a PVC trigger PV creation.

**What you will do:**
- Check existing StorageClasses and install the local-path-provisioner
- Mark the StorageClass as the cluster default
- Create a PVC without specifying a class and watch the PV appear automatically
- Deploy a StatefulSet with volumeClaimTemplates — each replica gets its own PV
- Verify data persists across pod restarts
- Clean up all PVCs and StatefulSet resources
