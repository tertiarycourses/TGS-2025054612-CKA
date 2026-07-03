# Lab 30 — Troubleshoot Services and Networking

Service connectivity bugs are the single biggest category of CKA exam questions. In this lab you walk the chain Pod → Service → DNS → Endpoint and fix three intentional faults.

**What you will do:**
- Deploy a baseline nginx service and confirm it returns HTTP 200
- Break and fix a selector mismatch that empties the Endpoints list
- Break and fix a targetPort mismatch that causes connection refused
- Simulate a CoreDNS outage and observe DNS failure vs direct pod-IP access
- Walk the seven-step triage chain from DNS to kube-proxy
- Clean up all deployments, services, and probe pods
