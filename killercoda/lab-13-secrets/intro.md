# Lab 13 — Secrets

Kubernetes Secrets carry sensitive data — passwords, tokens, TLS keys — and are base64-encoded (not encrypted) by default. In this lab you create a generic Secret, a TLS Secret, and a docker-registry Secret, and use them from pods.

**What you will do:**
- Create a generic Secret from literals and decode the base64 values
- Consume Secret data as environment variables in a pod
- Consume Secret data as a tmpfs-mounted file
- Generate a self-signed certificate and create a TLS Secret
- Create a docker-registry Secret for private image pulls
- Clean up all resources
