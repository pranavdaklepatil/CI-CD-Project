#!/bin/bash

# Update system
sudo apt update

# Install Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group (optional but better than chmod 666)
sudo chmod 666 /var/run/docker.sock

# Install dependencies
sudo apt install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes key
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repo
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update again
sudo apt update

# Install Kubernetes (IMPORTANT: no version suffix)
sudo apt install -y kubelet kubeadm kubectl

# Hold versions
sudo apt-mark hold kubelet kubeadm kubectl