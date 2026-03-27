#!/bin/bash
set -euo pipefail

echo "===== [1/8] System Update ====="
sudo apt update -y && sudo apt upgrade -y

echo "===== [2/8] Disabling Swap (Required for Kubernetes) ====="
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "===== [3/8] Loading Required Kernel Modules ====="
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "===== [4/8] Applying Sysctl Parameters ====="
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "===== [5/8] Installing containerd (CRI for Kubernetes v1.24+) ====="
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null


sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd

echo "===== [6/8] Installing Dependencies ====="
sudo apt install -y apt-transport-https ca-certificates curl gpg

echo "===== [7/8] Adding Kubernetes APT Repository ====="
sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "===== [8/8] Installing Kubernetes Components ====="
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

echo ""
echo "✅ Installation complete! Verify with:"
echo "   kubeadm version"
echo "   kubectl version --client"
echo "   sudo systemctl status containerd"