#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────
# SonarQube Setup Script
# Default credentials → username: admin | password: admin
# Access at: http://<EC2_PUBLIC_IP>:9000
# ─────────────────────────────────────────

echo "===== [1/4] Updating System ====="
sudo apt-get update -y && sudo apt-get upgrade -y

echo "===== [2/4] Installing Docker ====="
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

sudo apt-get update -y
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

sudo usermod -aG docker "$USER"

sudo systemctl enable docker
sudo systemctl start docker

echo "===== [3/4] Setting Kernel Parameter for SonarQube ====="

sudo sysctl -w vm.max_map_count=262144

# Persist across reboots
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

echo "===== [4/4] Starting SonarQube Container ====="

docker run -d \
  --name sonar \
  --restart unless-stopped \
  -p 9000:9000 \
  sonarqube:lts-community

echo "Waiting for SonarQube to initialize (this takes ~60 seconds)..."
sleep 60
docker ps --filter name=sonar

echo ""
echo "✅ =============================================="
echo "   SonarQube setup complete!"
echo "================================================"
echo ""
echo "🌐 Access SonarQube at: http://$(hostname -I | awk '{print $1}'):9000"
echo ""
echo "🔑 Default credentials:"
echo "   Username : admin"
echo "   Password : admin"
echo "   (You will be prompted to change password on first login)"
echo ""
echo "⚠️  Open port 9000 in your EC2 Security Group."
echo "⚠️  Log out and back in for docker group changes to take effect,"
echo "   or run: newgrp docker"