#!/bin/bash
# ==============================================================================
# One-Click Environment Setup for AWS Learner Lab EC2 Instance
# Installs: Docker, Jenkins, K3s (Lightweight Kubernetes), Kubectl, Trivy, Node.js
# Designed for Ubuntu 22.04 LTS on t3.medium or t2.large
# ==============================================================================

set -e

echo "=================================================================="
echo "☁️  SETTING UP HEALTHCARE DEVOPS STACK FOR AWS LEARNER LAB"
echo "=================================================================="

# 1. System Update
echo -e "\n[1/7] 🔄 Updating Ubuntu package cache..."
sudo apt-get update -y
sudo apt-get install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release

# 2. Install Docker
echo -e "\n[2/7] 🐳 Installing Docker Engine..."
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# 3. Install Java 17 (Required by Jenkins)
echo -e "\n[3/7] ☕ Installing OpenJDK 17..."
sudo apt-get install -y openjdk-17-jdk

# 4. Install Jenkins LTS
echo -e "\n[4/7] ⚙️ Installing Jenkins LTS..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins

# 5. Install K3s (Lightweight Kubernetes - Perfect for Learner Lab 4GB RAM)
echo -e "\n[5/7] ☸️ Installing K3s (Lightweight Kubernetes Cluster)..."
curl -sfL https://get.k3s.io | sh -

# Configure kubeconfig permissions for both ubuntu and jenkins users
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
mkdir -p /home/ubuntu/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Provide kubeconfig for jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

# 6. Install Trivy (Container Vulnerability Scanner for DevSecOps)
echo -e "\n[6/7] 🛡️ Installing Aqua Trivy Scanner..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install -y trivy

# 7. Install Node.js 20 & npm
echo -e "\n[7/7] 📦 Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Restart Jenkins to ensure group permissions take effect
sudo systemctl restart jenkins

# Retrieve Public IP
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || curl -s https://ifconfig.me || echo "YOUR-EC2-PUBLIC-IP")

echo -e "\n=================================================================="
echo "🎉 SETUP COMPLETED SUCCESSFULLY!"
echo "=================================================================="
echo "Jenkins URL       : http://${PUBLIC_IP}:8080"
echo "Healthcare App URL: http://${PUBLIC_IP}:30080 (once deployed)"
echo ""
echo "🔑 Jenkins Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "Verify Kubernetes Cluster:"
kubectl get nodes
echo "=================================================================="
