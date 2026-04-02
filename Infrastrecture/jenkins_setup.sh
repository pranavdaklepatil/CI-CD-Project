#!/bin/bash
set -euo pipefail

echo "===== [0/4] Cleaning any previous Jenkins repo artifacts ====="
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc
sudo rm -f /usr/share/keyrings/jenkins-keyring.gpg
sudo rm -f /etc/apt/keyrings/jenkins-keyring.asc
sudo rm -f /etc/apt/sources.list.d/jenkins.list


echo "===== [1/4] Updating System ====="
sudo apt-get update -y && sudo apt-get upgrade -y

# ─────────────────────────────────────────
#    Install Java 17 + fontconfig
#    fontconfig is required by Jenkins UI
#    and several plugins — missing it causes
#    silent font rendering failures
# ─────────────────────────────────────────
echo "===== [2/4] Installing Java 17 ====="
sudo apt-get install -y fontconfig openjdk-17-jre-headless
java -version

# ─────────────────────────────────────────
#    Install Jenkins
# ─────────────────────────────────────────
echo "===== [3/4] Installing Jenkins ====="

# Source: https://pkg.jenkins.io/debian-stable/ (official Jenkins repo)
#         https://www.jenkins.io/doc/book/installing/linux/
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins --no-pager

# ─────────────────────────────────────────
#    Install Docker
# ─────────────────────────────────────────
echo "===== [4/4] Installing Docker ====="

sudo apt-get install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart jenkins

sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker --no-pager


set -e
sudo apt-get update
sudo apt-get install -y wget apt-transport-https gnupg lsb-release

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update
sudo apt-get install -y trivy

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client



echo ""
echo "✅ =============================================="
echo "   Jenkins + Docker + Trivy setup complete!"
echo "================================================"
echo ""
echo "🌐 Access Jenkins at: http://$(curl -s ifconfig.me):8080"
echo ""
echo "🔑 Initial admin password:"
echo "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
