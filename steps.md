# Project Implementation Guide

## 1. Analysis & Planning

1. Analyze the application and identify processes that need to be automated.
2. Create a detailed architectural design:
   - Define system components and their interactions.
   - Choose appropriate technologies and tools for automation.
3. Verify and validate the architectural design.
4. Begin implementing the automation process based on the finalized design:
   - Install required tools and set up the environment.

---

## 2. Implementation Steps

### 2.1 AWS Setup

- Log in to AWS and create the required resources.
- Use the **default private VPC** for this setup.

---

### 2.2 EC2 Infrastructure Setup

#### 2.2.1 Security Group Configuration

Create a **common security group** for all EC2 instances with the following rules:

**Inbound Rules:**
- SSH (Port 22) → Allowed from trusted IPs
- HTTP (Port 80) → Allowed from anywhere
- HTTPS (Port 443) → Allowed from anywhere
- Custom TCP (Ports 3000–10000) → Allowed from anywhere
- SMTPS (Port 465) → Allowed from anywhere
- SMTP (Port 25) → Allowed from anywhere
- Kubernetes Node Ports (30000–32767) → Allowed
- Kubernetes API Server (Port 6443) → Allowed

**Outbound Rules:**
- Allow all outbound traffic

---

#### 2.2.2 Kubernetes Cluster Setup

Create **three EC2 instances**:

- **Names:** `master`, `slave1`, `slave2`
- **AMI:** Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
- **Instance Type:** t2.medium (2 vCPUs, 4 GB RAM)
- **Key Pair:** Create a new key pair for SSH access
- **Security Group:** Attach the common security group

**Installation Steps:**
- Run `k8s_installation.sh` on all nodes.
- On the **master node**:
  - Execute `master.sh`
  - Copy the generated join command
- On **worker nodes (slave1, slave2)**:
  - Run the join command to connect to the cluster

---

### 2.2.3 SonarQube & Nexus Setup

Create **2 EC2 instances** for SonarQube and Nexus:

- **AMI:** Ubuntu Server 20.04 LTS
- **Instance Type:** t2.medium (2 vCPUs, 4 GB RAM)
- **Key Pair:** Use existing key pair
- **Security Group:** Common security group

**Setup Steps:**
- Install Docker on both instances
- Deploy:
  - SonarQube container
  - Nexus container
- Use the script: `nexus_setup.sh` and  `sonarqube_setup.sh`


  ---

### 2.2.4 Jenkins Server Setup

Create **1 EC2 instance** for Jenkins:

- **AMI:** Ubuntu Server 20.04 LTS
- **Instance Type:** t2.large (2 vCPUs, 8 GB RAM, 30 GB Storage)
- **Key Pair:** Use existing key pair
- **Security Group:** Common security group

**Setup Steps:**
- Install Jenkins and Docker using: `jenkins_setup.sh`


---

## 3. Summary

This setup includes:
- Kubernetes Cluster (1 Master + 2 Workers)
- CI/CD Tools:
- Jenkins
- SonarQube
- Nexus
- Docker-based deployment
- Secure and scalable AWS infrastructure