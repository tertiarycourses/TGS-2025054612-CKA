# Lab 9 — CRDs and Operators: Define CRD with Schema Validation, Install cert-manager, Certificate Lifecycle

Custom Resource Definitions (CRDs) extend the Kubernetes API with your own resource types, and Operators use these CRDs to automate complex application lifecycle management. This lab defines a CRD with OpenAPI schema validation, creates custom resources, installs the cert-manager operator from its Helm chart, and walks through the complete TLS certificate lifecycle from Certificate request to Secret. The CKA exam tests your ability to work with CRDs and operator-managed resources.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)
- helm v3 (install: `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`)
- cert-manager (installed in this lab)

---

## Step 1 — Understand the CRD Extension Pattern

```bash
# View existing CRDs in the cluster
kubectl get crds
# In a fresh cluster: no output (or just calico CRDs)

# After cert-manager install: many Certificate*, Issuer*, ClusterIssuer* CRDs

# CRDs appear in API discovery
kubectl api-resources | grep -E 'APIVERSION|certificates'

# A CRD defines:
# - Group:     company.io or cert-manager.io
# - Version:   v1, v1beta1, v1alpha1
# - Kind:      Certificate, AppDatabase, etc.
# - Plural:    certificates, appdatabases
# - Scope:     Namespaced or Cluster

echo "CRDs let you treat custom objects exactly like built-in Kubernetes objects"
echo "kubectl get certificates  ←  just like kubectl get pods"
```

CRDs are the mechanism that makes Kubernetes an extensible platform. Once a CRD is installed, you can create, list, get, describe, and delete custom resources using standard kubectl commands.

---

## Step 2 — Define a CRD with Schema Validation

```bash
# Create a CRD for a hypothetical AppDatabase resource
cat <<'EOF' | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: appdatabases.storage.example.com
spec:
  group: storage.example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: ["engine", "storage"]   # These fields are mandatory
            properties:
              engine:
                type: string
                enum: ["postgresql", "mysql", "redis"]  # Only these values allowed
                description: "Database engine type"
              storage:
                type: string
                pattern: '^[0-9]+[GgMm][Ii]?$'   # Must match e.g. 10Gi, 500Mi
                description: "Storage size (e.g. 10Gi)"
              replicas:
                type: integer
                minimum: 1
                maximum: 10
                default: 1
              version:
                type: string
                description: "Database version"
          status:
            type: object
            properties:
              phase:
                type: string
              ready:
                type: boolean
  scope: Namespaced
  names:
    plural: appdatabases
    singular: appdatabase
    kind: AppDatabase
    shortNames:
    - adb
EOF

# Verify the CRD was created
kubectl get crd appdatabases.storage.example.com
kubectl describe crd appdatabases.storage.example.com | head -40
```

OpenAPI v3 schema validation is enforced by the API server — invalid CRs are rejected before they reach etcd. The `required` field, `enum` constraints, `pattern` regex, and `minimum/maximum` for integers are all validation mechanisms.

---

## Step 3 — Create Custom Resources

```bash
# Create a valid AppDatabase resource
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.example.com/v1
kind: AppDatabase
metadata:
  name: my-postgres
  namespace: default
spec:
  engine: postgresql
  storage: 20Gi
  replicas: 2
  version: "15.4"
EOF

# Create another instance
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.example.com/v1
kind: AppDatabase
metadata:
  name: my-redis
  namespace: default
spec:
  engine: redis
  storage: 5Gi
  replicas: 1
EOF

# Use kubectl to work with custom resources just like built-in resources
kubectl get appdatabases
kubectl get adb               # shortName works
kubectl describe adb my-postgres
kubectl get adb -o yaml
```

Custom resources behave identically to built-in resources from a kubectl perspective. Labels, annotations, `kubectl describe`, `kubectl edit`, and `kubectl delete` all work normally.

---

## Step 4 — Test Schema Validation

```bash
# Try to create an invalid resource (bad engine value)
cat <<'EOF' | kubectl apply -f - 2>&1
apiVersion: storage.example.com/v1
kind: AppDatabase
metadata:
  name: bad-db
spec:
  engine: oracle      # Not in enum: postgresql, mysql, redis
  storage: 10Gi
EOF
# Expected error: "Unsupported value: oracle: supported values: postgresql, mysql, redis"

# Try with invalid storage format
cat <<'EOF' | kubectl apply -f - 2>&1
apiVersion: storage.example.com/v1
kind: AppDatabase
metadata:
  name: bad-storage
spec:
  engine: mysql
  storage: ten-gigs   # Doesn't match pattern
EOF
# Expected error: storage must match pattern

# Try with missing required field
cat <<'EOF' | kubectl apply -f - 2>&1
apiVersion: storage.example.com/v1
kind: AppDatabase
metadata:
  name: missing-fields
spec:
  engine: postgresql
  # storage is required but missing
EOF
# Expected error: "spec.storage: Required value"
```

Schema validation ensures that the API server rejects malformed resources before they are stored in etcd, preventing operators from receiving garbage input.

---

## Step 5 — Install cert-manager via Helm

```bash
# Add the Jetstack Helm repository (cert-manager maintainers)
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager with CRD installation enabled
# --set installCRDs=true is the recommended approach for Helm v3
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.0 \
  --set installCRDs=true

# Wait for cert-manager components to be ready
kubectl rollout status deployment cert-manager -n cert-manager --timeout=120s
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=120s
kubectl rollout status deployment cert-manager-cainjector -n cert-manager --timeout=120s

# Verify all pods are running
kubectl get pods -n cert-manager
```

cert-manager is a CNCF project that automates TLS certificate management using CRDs. It supports Let's Encrypt (ACME), self-signed, Vault, and many other certificate authorities. It is commonly used in CKA lab environments.

---

## Step 6 — View cert-manager CRDs

```bash
# cert-manager installs many CRDs
kubectl get crds | grep cert-manager.io

# Key CRDs:
# certificaterequests.cert-manager.io
# certificates.cert-manager.io
# clusterissuers.cert-manager.io
# issuers.cert-manager.io
# orders.acme.cert-manager.io
# challenges.acme.cert-manager.io

# View the Certificate CRD schema
kubectl explain certificate
kubectl explain certificate.spec
kubectl explain certificate.spec.issuerRef
```

cert-manager introduces six CRDs. `Issuer` and `ClusterIssuer` define certificate authorities. `Certificate` requests a TLS certificate. `CertificateRequest` is the underlying request created by the Certificate controller.

---

## Step 7 — Create a Self-Signed ClusterIssuer

```bash
# A ClusterIssuer is cluster-scoped (can issue certs in any namespace)
# A self-signed issuer creates its own CA
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF

# Verify the issuer is ready
kubectl get clusterissuer selfsigned-issuer
kubectl describe clusterissuer selfsigned-issuer
# Status: Ready=True

# Create a CA ClusterIssuer using the self-signed cert
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-ca-cert
  namespace: cert-manager
spec:
  isCA: true
  commonName: my-lab-ca
  secretName: my-ca-secret
  duration: 87600h    # 10 years
  renewBefore: 720h   # 30 days before expiry
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
EOF

kubectl wait --for=condition=Ready certificate/my-ca-cert -n cert-manager --timeout=60s
```

`ClusterIssuer` is cluster-scoped; `Issuer` is namespace-scoped. The self-signed issuer is perfect for development and lab environments. In production, you would configure ACME (Let's Encrypt) or a corporate CA.

---

## Step 8 — Create a CA-Backed Issuer

```bash
# Create an Issuer backed by the CA certificate we just created
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: my-ca-secret  # References the Secret created in Step 7
EOF

kubectl get clusterissuer ca-issuer
kubectl describe clusterissuer ca-issuer
# Status.Conditions: type=Ready, status=True
```

The CA-backed ClusterIssuer signs new Certificate requests using the CA certificate stored in the `my-ca-secret` Secret. All resulting certificates will be signed by this CA.

---

## Step 9 — Request a TLS Certificate

```bash
# Create a namespace for the test application
kubectl create namespace webapp

# Request a TLS certificate for webapp
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: webapp-tls
  namespace: webapp
spec:
  secretName: webapp-tls-secret    # cert-manager creates this Secret
  duration: 2160h                  # 90 days
  renewBefore: 360h                # Renew 15 days before expiry
  dnsNames:
  - webapp.example.com
  - www.webapp.example.com
  subject:
    organizations:
    - ExampleCorp
  issuerRef:
    name: ca-issuer
    kind: ClusterIssuer
    group: cert-manager.io
EOF

# Wait for the certificate to be issued
kubectl wait --for=condition=Ready certificate/webapp-tls -n webapp --timeout=60s

# View the certificate status
kubectl get certificate webapp-tls -n webapp
kubectl describe certificate webapp-tls -n webapp
```

cert-manager watches for `Certificate` resources, creates a `CertificateRequest`, sends it to the configured issuer, and stores the resulting TLS key and certificate in the named Secret. No manual openssl commands needed.

---

## Step 10 — Inspect the Certificate Secret

```bash
# View the created Secret (TLS type with tls.crt and tls.key)
kubectl get secret webapp-tls-secret -n webapp
kubectl describe secret webapp-tls-secret -n webapp

# Decode and inspect the certificate
kubectl get secret webapp-tls-secret -n webapp \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | \
  openssl x509 -noout -text | grep -E 'Subject:|DNS:|Not Before:|Not After'

# View the certificate's expiry
kubectl get certificate webapp-tls -n webapp \
  -o jsonpath='{.status.notAfter}'

# View all cert-manager resources
kubectl get certificate,certificaterequest,order,challenge -n webapp
```

cert-manager stores the certificate in a Kubernetes Secret of type `kubernetes.io/tls` with keys `tls.crt` and `tls.key`. Pods can mount this secret as a volume to serve HTTPS traffic.

---

## Step 11 — Clean Up

```bash
# Delete CRD and custom resources
kubectl delete appdatabases my-postgres my-redis -n default
kubectl delete crd appdatabases.storage.example.com

# Uninstall cert-manager
helm uninstall cert-manager -n cert-manager
kubectl delete namespace cert-manager webapp

# Verify CRDs are removed
kubectl get crds | grep cert-manager
```

---

## Free online tools
- **Kubernetes Docs — CRDs**: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
- **cert-manager documentation**: https://cert-manager.io/docs/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- CRDs extend the Kubernetes API with custom resource types, fully integrated with kubectl
- OpenAPI v3 schema validation enforces required fields, enum values, patterns, and numeric ranges at the API server level
- Custom resources support all standard kubectl operations: get, describe, edit, delete, -o yaml
- cert-manager uses the Operator pattern: CRDs (Certificate, Issuer) + controllers = automated TLS management
- `ClusterIssuer` is cluster-scoped; `Issuer` is namespace-scoped
- A self-signed ClusterIssuer is the starting point for lab environments
- cert-manager stores issued certificates in `kubernetes.io/tls` Secrets with `tls.crt` and `tls.key`
- The `Certificate` CRD specifies `dnsNames`, `duration`, `renewBefore`, and `secretName`
- cert-manager automatically renews certificates before they expire based on `renewBefore`
- Operators automate Day 2 operations (backup, upgrade, failover) that would otherwise require manual intervention
