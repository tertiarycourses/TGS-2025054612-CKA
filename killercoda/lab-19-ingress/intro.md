# Lab 19 — Ingress Controller and Resources

An Ingress controller is a reverse proxy (typically nginx, Traefik, or Envoy) running inside the cluster that routes external HTTP/HTTPS based on `Ingress` objects. In this lab you install ingress-nginx and route two hostnames to two Services.

**What you will do:**
- Install the ingress-nginx controller via bare-metal manifest
- Deploy two echo-server backends and expose them as Services
- Create an Ingress resource with host-based routing rules
- Test routing with curl using the `Host` header
- Add TLS termination using a self-signed certificate in a Secret
- Review path-based routing as a reference pattern
