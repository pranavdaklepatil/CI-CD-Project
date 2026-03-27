#!/bin/bash
set -euo pipefail

echo "===== [1/9] System Update ====="
sudo apt update -y && sudo apt upgrade -y

echo "===== [2/9] Disabling Swap ====="
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "===== [3/9] Loading Kernel Modules ====="
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "===== [4/9] Applying Sysctl Params ====="
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "===== [5/9] Installing containerd ====="
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# CRITICAL: systemd cgroup driver must match kubelet
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd

echo "===== [6/9] Installing Dependencies ====="
sudo apt install -y apt-transport-https ca-certificates curl gpg

echo "===== [7/9] Adding Kubernetes Repo ====="
sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "===== [8/9] Installing kubeadm, kubelet, kubectl ====="
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

echo "===== [9/9] Initializing Kubernetes Cluster ====="

# Auto-detect private IP — critical on EC2 where multiple NICs may exist
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# pod-network-cidr=192.168.0.0/16 matches Calico's default
# --ignore-preflight-errors=NumCPU allows init on t2.micro (1 vCPU) instances
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address="$PRIVATE_IP" \
  --ignore-preflight-errors=NumCPU

echo "===== Setting up kubeconfig (Master) ====="
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo "===== Installing Calico CNI ====="
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml

# FIX: Sleep before wait — Calico pods need time to be scheduled by the DaemonSet
# Without this, kubectl wait fires before any pods exist and returns "no matching resources found"
echo "===== Waiting 20s for Calico pods to be scheduled... ====="
sleep 20

echo "===== Waiting for Calico pods to be ready (up to 3 min) ====="
kubectl wait --namespace kube-system \
  --for=condition=ready pod \
  --selector=k8s-app=calico-node \
  --timeout=180s

echo "===== Installing NGINX Ingress Controller ====="
# Pinned to stable release — 'main' branch can be unstable/breaking
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml

# ─────────────────────────────────────────────────────────────────────────────
# FIX: Distribute kubeconfig to worker nodes
# Workers need admin.conf to run kubectl — without it they get:
#   "connection refused to localhost:8080"
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "===== Saving kubeconfig for worker distribution ====="
# Copy admin.conf to a readable location so you can scp it to workers
sudo cp /etc/kubernetes/admin.conf /home/ubuntu/admin.conf
sudo chown ubuntu:ubuntu /home/ubuntu/admin.conf
echo "✅ Kubeconfig saved to /home/ubuntu/admin.conf"
echo ""
echo "   To enable kubectl on each WORKER node, run FROM THIS MASTER:"
echo ""
echo "   scp /home/ubuntu/admin.conf ubuntu@<WORKER_IP>:~/.kube/config"
echo ""
echo "   Then on the WORKER node:"
echo "   mkdir -p \$HOME/.kube && sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
echo ""

echo "✅ =============================================="
echo "   Master node initialized successfully!"
echo "================================================"
echo ""
echo "👇 Run the following command on each WORKER node to join the cluster:"
echo ""
kubeadm token create --print-join-command
echo ""
echo "📌 Verify cluster health from this master:"
echo "   kubectl get nodes"
echo "   kubectl get pods -A"