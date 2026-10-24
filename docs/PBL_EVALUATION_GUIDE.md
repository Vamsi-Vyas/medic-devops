# Evaluation Guide & Viva Presentation (Full 15 Marks Breakdown)

This guide provides the exact demonstration steps, commands, and talking points needed to secure **15 / 15 Marks** across PBL-7, PBL-8, and PBL-9.

---

## 📋 Evaluation Summary Table

| PBL Item | Topic | Deliverables | Allocated Marks |
| :--- | :--- | :--- | :--- |
| **PBL-7** | CI/CD Pipeline to Deploy Dockerized App on Kubernetes using Jenkins | Multi-stage Dockerfile, Jenkinsfile, Kubernetes manifests (`deployment.yaml`, `service.yaml`, `hpa.yaml`) | **5 Marks** |
| **PBL-8** | Automated Blue-Green Deployment Strategy using Jenkins, Kubernetes, Docker | Blue/Green Deployments, Production & Preview Services, Zero-Downtime switcher script & pipeline | **5 Marks** |
| **PBL-9** | Secure DevOps (DevSecOps) Implementation in a Healthcare System | Secret detection (Gitleaks), SCA (npm audit), Container CVE scan (Trivy), K8s NetworkPolicy & RBAC | **5 Marks** |
| **TOTAL** | **Healthcare Cloud-Native DevOps Architecture** | | **15 Marks** |

---

## 🩺 Part 1: PBL-7 — CI/CD Pipeline on Kubernetes (5 Marks)

### Objective
Demonstrate an automated Jenkins pipeline that takes code from Git, runs tests, packages it into a Docker image, and deploys it to a Kubernetes cluster.

### Demonstration Steps:
1. **Show Source Code & Tests**:
   - Show `src/server.js` and `test/app.test.js`.
   - Run tests locally or show them passing in Jenkins:
     ```bash
     npm test
     ```
2. **Show Hardened Dockerfile**:
   - Point out multi-stage build, unprivileged user `USER node` (UID: 1000), and `HEALTHCHECK`.
3. **Show Jenkins Pipeline**:
   - Open Jenkins Dashboard -> Click on the `Healthcare-CI-CD` job -> Show **Stage View**:
     - *Checkout* &rarr; *Lint & Test* &rarr; *Docker Build* &rarr; *Kubernetes Deploy* &rarr; *Verify*
4. **Inspect Kubernetes Resources via CLI**:
   ```bash
   kubectl get namespaces
   kubectl get pods,svc,hpa -n healthcare -o wide
   ```
5. **Open Healthcare Application in Browser**:
   - Navigate to `http://<EC2-PUBLIC-IP>:30080`.
   - Demonstrate the 3 interactive pages:
     - **Home Page** (`/`): Emergency SOS trigger, hospital stats.
     - **Appointments Page** (`/appointments`): Fill patient name, pick slot, book doctor, verify real-time list update.
     - **Patient EHR Portal** (`/records`): View encrypted vitals, active prescriptions, lab panels.

---

## 🔄 Part 2: PBL-8 — Automated Blue-Green Deployment Strategy (5 Marks)

### Objective
Demonstrate zero-downtime automated deployment where production traffic seamlessly switches from Blue to Green without dropping a single user request.

### Architecture Highlights to Explain:
- `healthcare-blue` (Deployment version 1.0.0, labeled `version: blue`).
- `healthcare-green` (Deployment version 1.1.0, labeled `version: green`).
- `healthcare-service` (Production service on port 30080, targeting the active color).
- `healthcare-preview-service` (Preview service on port 30081, targeting the idle candidate).

### Live Demonstration:
1. **Show Current Production Selector**:
   ```bash
   kubectl get svc healthcare-service -n healthcare -o jsonpath='{.spec.selector.version}'
   # Output: blue
   ```
2. **Show Browser**:
   - On `http://<EC2-PUBLIC-IP>:30080`, show the top indicator badge: **"Pod Active: BLUE (v1.0.0)"**.
3. **Execute Automated Blue-Green Switch**:
   Run via Jenkins (`Jenkinsfile.bluegreen`) OR run the automated script directly:
   ```bash
   ./scripts/deploy-bluegreen.sh
   ```
   **What happens automatically**:
   - Deploys Green pods.
   - Waits for rollout to be ready (`kubectl rollout status`).
   - Runs automated smoke test against candidate pods (`/healthz`).
   - Switches production service selector from `blue` to `green`.
4. **Show Switched Production Selector**:
   ```bash
   kubectl get svc healthcare-service -n healthcare -o jsonpath='{.spec.selector.version}'
   # Output: green
   ```
5. **Refresh Browser**:
   - The top indicator badge dynamically updates to: **"Pod Active: GREEN (v1.1.0)"**!
   - Zero downtime: No errors, no connection resets.
6. **Show Instant Rollback (Bonus Marks)**:
   ```bash
   ./scripts/rollback-bluegreen.sh
   # Instantly flips traffic back to BLUE within 100 milliseconds!
   ```

---

## 🛡️ Part 3: PBL-9 — DevSecOps in Healthcare System (5 Marks)

### Objective
Demonstrate security gates across all phases of the DevOps lifecycle to comply with healthcare regulatory standards (HIPAA / HITECH / GDPR).

### Security Gates Demonstration:

#### 1. Secret Detection (Gitleaks)
- Prevents patient data leakage, credentials, or AWS keys in version control:
  ```bash
  gitleaks detect --source . --verbose
  # Output: No leaks found.
  ```

#### 2. Static Application Security Testing (SAST) & CSP
- Demonstrate `helmet` configuration in `src/server.js`:
  - Enforces strict `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, and disables cross-site script injection.
- Demonstrate non-root container isolation in `Dockerfile` (`USER node`).

#### 3. Software Composition Analysis (SCA)
- Scan dependencies for known CVEs:
  ```bash
  npm audit --audit-level=high
  ```

#### 4. Container Vulnerability Scanning (Aqua Trivy)
- Demonstrate image scanning for OS/package CVEs:
  ```bash
  trivy image --severity HIGH,CRITICAL healthcare-app:latest
  ```

#### 5. Kubernetes Cluster Hardening (HIPAA Compliance)
- **Network Isolation (`k8s/devsecops/network-policy.yaml`)**:
  - Restricts ingress to port 3000 only and restricts egress to prevent data exfiltration.
  - Show policy:
    ```bash
    kubectl describe networkpolicy healthcare-network-policy -n healthcare
    ```
- **Principle of Least Privilege (`k8s/devsecops/rbac.yaml`)**:
  - Show non-root ServiceAccount and namespace-scoped Role:
    ```bash
    kubectl get serviceaccount,role,rolebinding -n healthcare
    ```

---

## 🎓 Expected Viva Questions & Model Answers

1. **Q: Why is Blue-Green deployment crucial for healthcare systems?**
   - *A: Healthcare applications handle critical patient vitals, telemetry, and emergency dispatch. Unplanned downtime or deployment errors can endanger patient care. Blue-Green guarantees zero downtime and provides instantaneous rollback if a bug is identified in production.*

2. **Q: How does K3s differ from standard Kubernetes or EKS in our AWS setup?**
   - *A: K3s is a certified, fully compliant lightweight Kubernetes distribution packaged as a single binary that requires less than 512MB RAM. In an AWS Learner Lab sandbox with t3.medium (4GB RAM), standard Kubernetes or EKS would exhaust memory and fail; K3s runs smoothly alongside Jenkins and Docker.*

3. **Q: What is the purpose of Liveness and Readiness probes?**
   - *A: The Readiness probe (`/readyz`) verifies the container has booted and is ready to accept HTTP traffic before routing traffic to it. The Liveness probe (`/healthz`) detects if the process has deadlocked; if it fails, Kubernetes automatically restarts the pod.*
