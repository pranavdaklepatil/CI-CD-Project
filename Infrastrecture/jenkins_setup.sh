#!/bin/bash
set -euo pipefail

echo "===== [1/4] Updating System ====="
sudo apt update -y && sudo apt upgrade -y

echo "===== [2/4] Installing Java 17 ====="
sudo apt install -y openjdk-17-jre-headless
java -version


echo "===== [3/4] Installing Jenkins ====="

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins --no-pager


echo "===== [4/4] Installing Docker ====="

sudo apt-get update
sudo apt-get install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin


sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker --no-pager

echo ""
echo "✅ =============================================="
echo "   Jenkins + Docker setup complete!"
echo "================================================"
echo ""
echo "📌 Jenkins is running at: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "🔑 Unlock Jenkins with the initial admin password:"
echo "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "📌 Open port 8080 in your EC2 Security Group to access Jenkins UI."