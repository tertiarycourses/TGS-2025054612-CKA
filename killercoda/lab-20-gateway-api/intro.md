# Lab 20 — Gateway API

The Gateway API is Kubernetes' next-generation ingress: role-oriented (GatewayClass / Gateway / HTTPRoute) and CRD-driven. In this lab you install the API plus a controller (nginx-gateway-fabric) and route HTTP traffic with an HTTPRoute.

**What you will do:**
- Install the Gateway API standard CRDs
- Install NGINX Gateway Fabric as the Gateway controller
- Deploy an echo backend and expose it as a Service
- Create a Gateway object that declares a listener on port 80
- Create an HTTPRoute that attaches to the Gateway and routes by hostname
- Test the route with curl using the Host header
- Compare the Gateway API role model with the legacy Ingress API
