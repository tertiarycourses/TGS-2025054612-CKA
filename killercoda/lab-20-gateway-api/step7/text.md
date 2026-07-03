# Step 7 — Compare with Ingress

| Concept             | Ingress              | Gateway API             |
|---------------------|----------------------|-------------------------|
| Controller selector | `ingressClassName`   | `GatewayClass`          |
| Cluster object      | `Ingress` (mixed)    | `Gateway` (infra-owned) |
| Route object        | (inside `Ingress`)   | `HTTPRoute` (dev-owned) |
| Protocols           | HTTP/S only          | HTTP, HTTPS, TCP, TLS, gRPC, UDP |
| Cross-namespace     | No                   | Yes (`allowedRoutes`)   |
