#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────
# Nexus Repository Manager Setup Script
# Default username : admin
# Default password : located inside the container at:
#                    /nexus-data/admin.password
# Access at: http://<EC2_PUBLIC_IP>:8081
# ─────────────────────────────────────────

echo "===== [1/3] Updating System ====="
sudo apt-get update -y && sudo apt-get upgrade -y

echo "===== [2/3] Installing Docker ====="
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

echo "===== [3/3] Starting Nexus Container ====="

docker run -d \
  --name nexus \
  --restart unless-stopped \
  -p 8081:8081 \
  sonatype/nexus3

echo "Waiting for Nexus to initialize (this takes ~90 seconds)..."
sleep 90
docker ps --filter name=nexus


echo "   Nexus Repository Manager setup complete!"

echo "🌐 Access Nexus at: http://$(hostname -I | awk '{print $1}'):8081"
echo ""
echo "🔑 Default credentials:"
echo "   Username : admin"
echo "   Password : run the command below to get it:"
echo ""
echo "   docker exec nexus cat /nexus-data/admin.password && echo"
