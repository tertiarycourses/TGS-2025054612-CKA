# Lab 9 — CRDs and Operators

A CustomResourceDefinition (CRD) extends the Kubernetes API with new object kinds. An Operator is a controller that watches a CRD and reconciles real-world state. In this lab you define a tiny CRD by hand, then install **cert-manager** as a real-world operator to see the pattern in production.

**What you will do:**
- Define a custom `Widget` CRD with OpenAPI schema validation
- Create and inspect a custom resource instance
- Install cert-manager as a production-grade operator
- Create a self-signed Issuer and Certificate to see the operator reconciliation loop in action
- Clean up all resources
