# Project Implementation Guide
> CI/CD Pipeline Automation on AWS with Kubernetes, Jenkins, SonarQube & Nexus

---

## Table of Contents

1. [Analysis & Planning](#1-analysis--planning)
2. [AWS Setup](#21-aws-setup)
3. [EC2 Infrastructure Setup](#22-ec2-infrastructure-setup)
   - [Security Group Configuration](#221-security-group-configuration)
   - [Kubernetes Cluster Setup](#222-kubernetes-cluster-setup)
   - [SonarQube & Nexus Setup](#223-sonarqube--nexus-setup)
   - [Jenkins Server Setup](#224-jenkins-server-setup)
4. [Summary](#3-summary)

---

## 1. Analysis & Planning

Before provisioning any infrastructure, invest time in thorough analysis and design to ensure a stable, maintainable pipeline.

1. **Analyze the application** — Identify all processes that need to be automated (build, test, quality scan, artifact storage, deployment).
2. **Create a detailed architectural design:**
   - Define system components and their interactions.
   - Choose appropriate technologies and tools for each stage of the pipeline.
3. **Review and validate the design** with relevant stakeholders before proceeding.
4. **Prepare the environment:**
   - Install required CLI tools locally (AWS CLI, `kubectl`, SSH client).
   - Verify AWS account permissions for EC2, VPC, and Security Groups.

---

## 2. Implementation Steps

### 2.1 AWS Setup

- Log in to the **AWS Management Console**.
- All resources in this guide use the **default private VPC**.
- Confirm that your IAM user/role has permissions to create EC2 instances, Security Groups, and Key Pairs.

---

### 2.2 EC2 Infrastructure Setup

#### 2.2.1 Security Group Configuration

Create **one common Security Group** to be attached to all EC2 instances ( **Not Recomended** ).

##### Inbound Rules

| Service / Rule        | Protocol | Port(s)       | Source               |
|:---------------------:|:--------:|:-------------:|:--------------------:|
| SSH                   | TCP      | 22            | Your trusted IP only |
| HTTP                  | TCP      | 80            | 0.0.0.0/0            |
| HTTPS                 | TCP      | 443           | 0.0.0.0/0            |
| Custom TCP            | TCP      | 3000 – 10000  | 0.0.0.0/0            |
| SMTPS                 | TCP      | 465           | 0.0.0.0/0            |
| SMTP                  | TCP      | 25            | 0.0.0.0/0            |
| Kubernetes Node Ports | TCP      | 30000 – 32767 | 0.0.0.0/0            |
| Kubernetes API Server | TCP      | 6443          | 0.0.0.0/0            |

##### Outbound Rules

| Rule        | Protocol | Port(s) | Destination |
|:-----------:|:--------:|:-------:|:-----------:|
| All Traffic | All      | All     | 0.0.0.0/0   |

---

#### 2.2.2 Kubernetes Cluster Setup

Provision **3 EC2 instances** — one master node and two worker nodes.

| Parameter      | Value                                          |
|:--------------:|:----------------------------------------------:|
| Instance Names | `master`, `slave1`, `slave2`                   |
| AMI            | Ubuntu Server 20.04 LTS (HVM), SSD Volume Type |
| Instance Type  | `t2.medium` — 2 vCPUs, 4 GB RAM               |
| Key Pair       | Create a new key pair for SSH access           |
| Security Group | Attach the common security group               |

**Installation steps:**

1. Run `k8s_installation.sh` on **all three nodes**.
2. On the **master node** only, execute `master.sh`.
3. Copy the join command output from the master node.
4. On **each worker node** (`slave1`, `slave2`), run the copied join command to register with the cluster.
5. Verify the cluster is healthy:
   ```bash
   kubectl get nodes
   ```
   All nodes should display `Ready` status.

---

#### 2.2.3 SonarQube & Nexus Setup

Provision **2 EC2 instances** — one for SonarQube and one for Nexus.

| Parameter      | Value                                          |
|:--------------:|:----------------------------------------------:|
| Instance Names | `sonarqube`, `nexus`                           |
| AMI            | Ubuntu Server 20.04 LTS (HVM), SSD Volume Type |
| Instance Type  | `t2.medium` — 2 vCPUs, 4 GB RAM               |
| Key Pair       | Use existing key pair                          |
| Security Group | Attach the common security group               |

**Installation steps:**

1. Install Docker on **both** instances.
2. Deploy the **SonarQube** container:
   ```bash
   bash sonarqube_setup.sh
   ```
3. Deploy the **Nexus** container:
   ```bash
   bash nexus_setup.sh
   ```

> **Default Credentials**
> - SonarQube: `admin` / `admin` (change on first login)
> - Nexus: retrieve the initial password from `/nexus-data/admin.password`

---

#### 2.2.4 Jenkins Server Setup

Provision **1 EC2 instance** dedicated to Jenkins.

| Parameter      | Value                                          |
|:--------------:|:----------------------------------------------:|
| Instance Name  | `jenkins`                                      |
| AMI            | Ubuntu Server 20.04 LTS (HVM), SSD Volume Type |
| Instance Type  | `t2.large` — 2 vCPUs, 8 GB RAM, 30 GB Storage |
| Key Pair       | Use existing key pair                          |
| Security Group | Attach the common security group               |

**Step 1 — Install Jenkins & Docker**

```bash
bash jenkins_setup.sh
```

---

**Step 2 — Install Required Plugins**

Navigate to **Manage Jenkins → Plugins → Available Plugins** and install:

| Category   | Plugin(s)                                        |
|:----------:|:------------------------------------------------:|
| Java       | Eclipse Temurin Installer (Java 17)              |
| Maven      | Config File Provider, Pipeline Maven Integration |
| SonarQube  | SonarQube Scanner for Jenkins                    |
| Docker     | Docker Pipeline                                  |
| Kubernetes | Kubernetes CLI, Kubernetes Plugin                |

---

**Step 3 — Configure Tools**

Navigate to **Manage Jenkins → Tools** and configure the following:

| Tool              | Name      | Value / Version                         |
|:-----------------:|:---------:|:---------------------------------------:|
| JDK               | `jdk17`   | `/usr/lib/jvm/java-17-openjdk-amd64`    |
| SonarQube Scanner | `sonar`   | Latest                                  |
| Maven             | `maven3`  | `3.6.1`                                 |
| Docker            | `docker`  | Latest (auto-install from `docker.com`) |

---

**Step 4 — Create the Pipeline Job**

1. In Jenkins, click **New Item**.
2. Enter a name and select **Pipeline**.
3. Under **Pipeline Definition**, choose **Pipeline script from SCM**.
4. Configure the repository URL and credentials.
5. Set the **Script Path** to the `Jenkinsfile` in the repository.
6. Save and run the pipeline.

---

## 3. Summary

This guide provisions a complete, production-ready CI/CD infrastructure on AWS:

| Component          | Details                              |
|:------------------:|:------------------------------------:|
| Kubernetes Cluster | 1 Master Node + 2 Worker Nodes       |
| Jenkins            | CI/CD orchestration server           |
| SonarQube          | Static code analysis & quality gates |
| Nexus              | Artifact repository manager          |
| Docker             | Container runtime on all nodes       |
| AWS Infrastructure | EC2 instances within a private VPC   |

> **Next Steps:** Configure webhook integration between your Git repository and Jenkins to trigger pipeline runs automatically on every push or pull request.