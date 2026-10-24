# System & DevOps Architecture Documentation

## 1. High-Level System Architecture

```mermaid
flowchart TD
    User["Patient / Doctor Browser"] -->|HTTP / NodePort 30080| K8sSvc["Kubernetes Service (healthcare-service)"]
    K8sSvc --> Pod1["Pod 1: PulseCare Container"]
    K8sSvc --> Pod2["Pod 2: PulseCare Container"]
    
    subgraph K8s["Kubernetes Cluster (Namespace: healthcare)"]
        K8sSvc
        Pod1
        Pod2
        ConfigMap["ConfigMap: healthcare-config"] -.-> Pod1
        ConfigMap -.-> Pod2
        Secrets["Secret: healthcare-secrets"] -.-> Pod1
        Secrets -.-> Pod2
        NetPol["NetworkPolicy: hipaa-restricted"] --- Pod1
        NetPol --- Pod2
    end
```

---

## 2. PBL-7: Docker & Kubernetes CI/CD Pipeline (Jenkins)

```mermaid
flowchart LR
    Dev["Developer Git Push"] --> GitRepo["GitHub Repository"]
    GitRepo --> Jenkins["Jenkins CI/CD Server"]
    
    subgraph JenkinsPipeline["Jenkins Declarative Pipeline"]
        Checkout["1. SCM Checkout"] --> Test["2. Unit Tests & Lint"]
        Test --> BuildDocker["3. Docker Multi-stage Build"]
        BuildDocker --> TrivyScan["4. Aqua Trivy Image Scan"]
        TrivyScan --> DeployK8s["5. Deploy to Kubernetes (kubectl apply)"]
        DeployK8s --> Verify["6. Health Check Probe (/healthz)"]
    end
    
    Jenkins --> JenkinsPipeline
    DeployK8s --> K8sCluster["Kubernetes Cluster (NodePort 30080)"]
```

---

## 3. PBL-8: Automated Blue-Green Zero-Downtime Deployment Strategy

```mermaid
flowchart TD
    Traffic["Inbound Hospital Web Traffic (Port 30080)"] --> ActiveSvc["healthcare-service (Production Service)"]
    
    subgraph BlueEnvironment["BLUE Environment (Version 1.0.0)"]
        BluePods["healthcare-blue Pods (Active)"]
    end

    subgraph GreenEnvironment["GREEN Environment (Version 1.1.0)"]
        GreenPods["healthcare-green Pods (Candidate)"]
    end

    ActiveSvc -->|selector: version=blue| BluePods
    
    PreviewSvc["healthcare-preview-service (Port 30081)"] -->|selector: version=green| GreenPods
    JenkinsBG["Jenkins Automated Switcher"] -->|1. Deploy & Test| GreenPods
    JenkinsBG -->|2. Automated Smoke Test /healthz| PreviewSvc
    JenkinsBG -->|3. Zero-Downtime Patch Selector to green| ActiveSvc
```

---

## 4. PBL-9: Healthcare DevSecOps Security Matrix (HIPAA Aligned)

```mermaid
flowchart TD
    subgraph CodeStage["Phase 1: Code Security"]
        Gitleaks["Secret Detection (Gitleaks)"]
        SAST["SAST (Helmet CSP, Non-root check)"]
    end

    subgraph BuildStage["Phase 2: Build Security"]
        SCA["Dependency Vulnerability Scan (npm audit)"]
        Trivy["Container CVE Scanner (Aqua Trivy)"]
    end

    subgraph DeployStage["Phase 3: Runtime & Cluster Security"]
        NonRoot["Non-Root Container User (UID 1000)"]
        NetPolicy["Kubernetes NetworkPolicy (Default Deny / Egress lock)"]
        RBAC["Least-Privilege RBAC ServiceAccount"]
    end

    CodeStage --> BuildStage
    BuildStage --> DeployStage
```
