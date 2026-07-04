# Lab 12 — ConfigMaps

ConfigMaps hold non-secret key/value configuration. In this lab you create a ConfigMap three ways (literal, file, manifest) and consume it in a pod as environment variables and as a mounted file.

**What you will do:**
- Create a ConfigMap from literal key/value pairs
- Create a ConfigMap from a properties file
- Consume a ConfigMap as environment variables in a pod
- Consume a ConfigMap as a mounted volume file
- Observe live update propagation for mounted ConfigMaps
- Clean up all resources
