# AWS Academy Learner Lab Deployment Guide

This guide provides end-to-end instructions for deploying the **PulseCare Healthcare System** on an **AWS Academy Learner Lab** EC2 instance.

---

## 📌 AWS Learner Lab Environment Constraints

| Parameter | Recommended Value / Setting | Why? |
| :--- | :--- | :--- |
| **Instance Type** | `t3.medium` (or `t2.large`) | 2 vCPU, 4GB RAM: Sufficient to run Jenkins, Docker, and K3s simultaneously. |
| **Operating System** | Ubuntu Server 22.04 LTS (64-bit x86) | Standard Linux distribution supported by Docker and Jenkins. |
| **Storage (EBS)** | 25 GB gp3 | Accommodates Docker base images, Jenkins workspaces, and K3s images. |
| **Kubernetes Distro** | **K3s** (Lightweight Kubernetes) | Minikube or EKS consume >6GB RAM or exceed Learner Lab budget. K3s uses <500MB! |

---

## 🚀 Step 1: Launch EC2 Instance in AWS Learner Lab

1. Log into your **AWS Academy** account and open **Learner Lab**.
2. Click **Start Lab** and wait until the status indicator turns green (`AWS status: ready`).
3. Click on the **AWS** link next to the status dot to open the AWS Management Console.
4. Go to **EC2** &rarr; **Instances** &rarr; **Launch an instance**.
5. Configure the instance:
   - **Name**: `Healthcare-DevSecOps-Server`
   - **Application and OS Images**: `Ubuntu Server 22.04 LTS (HVM), SSD Volume Type`
   - **Instance type**: `t3.medium`
   - **Key pair**: Select an existing key pair or click *Create new key pair* (e.g., `devops-key.pem`).
   - **Network settings (Security Group)**:
     Click **Edit** and add the following Inbound Rules:

| Type | Port Range | Source | Description |
| :--- | :--- | :--- | :--- |
| **SSH** | `22` | `0.0.0.0/0` | Secure Shell access |
| **Custom TCP** | `8080` | `0.0.0.0/0` | **Jenkins Web Dashboard** |
| **Custom TCP** | `30080` | `0.0.0.0/0` | **Production App (NodePort)** |
| **Custom TCP** | `30081` | `0.0.0.0/0` | **Preview App (NodePort)** |
| **Custom TCP** | `3000` | `0.0.0.0/0` | Direct Container Port |
| **HTTP** | `80` | `0.0.0.0/0` | Web Traffic |

6. **Configure Storage**: Change the root volume size to **25 GiB** (gp3).
7. Click **Launch instance**.

---

## 💻 Step 2: Connect to your EC2 Instance

You can connect in either of two ways:

### Option A: Using AWS EC2 Instance Connect (No SSH client needed!)
- In the EC2 console, select your instance and click **Connect**.
- Choose **EC2 Instance Connect** and click **Connect**. A terminal will open directly in your web browser!

### Option B: Using SSH from your local computer
```bash
chmod 400 devops-key.pem
ssh -i devops-key.pem ubuntu@<YOUR-EC2-PUBLIC-IP>
```

---

## ⚡ Step 3: Run Automated Setup Script

Once inside the EC2 terminal, clone your GitHub repository:

```bash
# Clone the repository
git clone https://github.com/<YOUR-GITHUB-USERNAME>/<YOUR-REPO-NAME>.git
cd <YOUR-REPO-NAME>

# Make setup script executable and run it
chmod +x scripts/setup-aws-learner-lab.sh
./scripts/setup-aws-learner-lab.sh
```

### What the script automatically installs and configures:
- ✅ Docker Engine (and adds `ubuntu` & `jenkins` users to the `docker` group)
- ✅ OpenJDK 17 + Jenkins LTS (configured on port `8080`)
- ✅ K3s Lightweight Kubernetes cluster
- ✅ Kubeconfig permissions for Jenkins CI/CD automation
- ✅ Aqua Trivy vulnerability scanner
- ✅ Node.js 20 & npm

At the end of the script, it will print:
- The **Jenkins Web URL**: `http://<EC2-PUBLIC-IP>:8080`
- The **Jenkins Initial Admin Password**

---

## 🛠️ Step 4: Configure Jenkins Web Dashboard

1. Open your browser and navigate to:
   ```
   http://<YOUR-EC2-PUBLIC-IP>:8080
   ```
2. Retrieve the initial password if needed:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Paste the password and click **Continue**.
4. Click **Install suggested plugins** and wait 2-3 minutes.
5. Create your admin user account (or click *Continue as admin*).
6. Click **Save and Finish** &rarr; **Start using Jenkins**.

---

## 🔄 Step 5: Create and Run the CI/CD Pipeline

1. On the Jenkins home screen, click **New Item**.
2. Enter item name: `Healthcare-PBL-Pipeline`.
3. Select **Pipeline** and click **OK**.
4. Scroll down to the **Pipeline** section:
   - **Definition**: Select `Pipeline script from SCM`
   - **SCM**: Select `Git`
   - **Repository URL**: `https://github.com/<YOUR-USERNAME>/<YOUR-REPO>.git`
   - **Branch Specifier**: `*/main`
   - **Script Path**:
     - For All-in-One Pipeline: `Jenkinsfile`
     - For Blue-Green Specific (PBL-8): `Jenkinsfile.bluegreen`
     - For DevSecOps Specific (PBL-9): `Jenkinsfile.devsecops`
5. Click **Save**.
6. Click **Build Now**.

---

## 🌐 Step 6: Access the Deployed Application

Once the pipeline completes with green checkmarks, open your web browser:

- **Production Healthcare App**:
  ```
  http://<YOUR-EC2-PUBLIC-IP>:30080
  ```
- **Preview / Staging Candidate App**:
  ```
  http://<YOUR-EC2-PUBLIC-IP>:30081
  ```
- **Kubernetes Health Check Endpoint**:
  ```
  http://<YOUR-EC2-PUBLIC-IP>:30080/healthz
  ```

---

## ⏰ Managing AWS Learner Lab Session Limits

> [!NOTE]
> AWS Learner Lab sessions run for **4 hours** before pausing. Your EC2 instance and all data **are not lost**!

When your session expires:
1. Log back into AWS Academy and click **Start Lab**.
2. Open the AWS EC2 console.
3. If your instance is stopped, select it &rarr; **Instance state** &rarr; **Start instance**.
4. Note your new **Public IPv4 address** (AWS assigns a new IP upon restart).
5. SSH back in and verify services:
   ```bash
   sudo systemctl status jenkins
   kubectl get pods -n healthcare
   ```
