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
4. [Jenkins Integrations & Credentials](#3-jenkins-integrations--credentials)
   - [SonarQube Integration](#31-sonarqube-integration)
   - [Quality Gate Configuration](#32-quality-gate-configuration)
   - [Nexus Artifact Repository](#33-nexus-artifact-repository)
   - [Docker Hub Credentials](#34-docker-hub-credentials)
   - [Kubernetes Configuration](#35-kubernetes-configuration)
5. [Pipeline Job Setup](#4-pipeline-job-setup)
6. [Summary](#5-summary)

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

Create **one common Security Group** to be attached to all EC2 instances (**Not Recommended** for production — use separate, scoped security groups per service).

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

**Step 1 — Install Jenkins, Docker & Trivy**

```bash
bash jenkins_setup.sh
```

> **Note:** Install **Trivy** directly on the Jenkins server — no official Jenkins plugin is available for Trivy at this time.

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

## 3. Jenkins Integrations & Credentials

### 3.1 SonarQube Integration

#### Step 1 — Generate a SonarQube Token

1. Log in to SonarQube at `http://<sonarqube-instance-ip>:9000`.
2. Navigate to **My Account → Security → Generate Token**.
3. Give it a meaningful name (e.g., `jenkins-token`) and click **Generate**.
4. **Copy the token immediately** — it will not be shown again.

#### Step 2 — Add the Token to Jenkins

1. In Jenkins, navigate to **Manage Jenkins → Credentials → Global → Add Credentials**.
2. Fill in the details:

   | Field       | Value              |
   |:-----------:|:------------------:|
   | Kind        | Secret text        |
   | Secret      | `<your-token>`     |
   | ID          | `sonar-token`      |
   | Description | `SonarQube Token`  |

3. Click **Create** to save.

#### Step 3 — Configure the SonarQube Server in Jenkins

1. Navigate to **Manage Jenkins → System**.
2. Scroll down to the **SonarQube Servers** section and click **Add SonarQube**.
3. Enter the following details:

   | Field                    | Value                                   |
   |:------------------------:|:---------------------------------------:|
   | Name                     | `sonar`                                 |
   | Server URL               | `http://<sonarqube-instance-ip>:9000`   |
   | Server Authentication Token | `sonar-token` *(select from dropdown)* |

4. Click **Save**.

---

### 3.2 Quality Gate Configuration

Configure a webhook in SonarQube so Jenkins can receive Quality Gate results in real time.

1. In SonarQube, navigate to **Administration → Webhooks**.
2. Click **Create** and fill in:

   | Field | Value                                               |
   |:-----:|:---------------------------------------------------:|
   | Name  | `jenkins`                                           |
   | URL   | `http://<jenkins-instance-ip>:8080/sonarqube-webhook/` |

3. Click **Create** to save the webhook.

> **Tip:** Jenkins will now pause pipeline execution at the Quality Gate step and wait for SonarQube to post the result back via this webhook before proceeding.

---

### 3.3 Nexus Artifact Repository

#### Step 1 — Update `pom.xml` with Nexus Repository URLs

1. In the Nexus UI, navigate to **Browse → Repositories** and copy the URLs for:
   - `maven-releases`
   - `maven-snapshots`
2. Paste them into your project's `pom.xml` under the `<distributionManagement>` section:

   ```xml
   <distributionManagement>
     <repository>
       <id>maven-releases</id>
       <url>http://<nexus-instance-ip>:8081/repository/maven-releases/</url>
     </repository>
     <snapshotRepository>
       <id>maven-snapshots</id>
       <url>http://<nexus-instance-ip>:8081/repository/maven-snapshots/</url>
     </snapshotRepository>
   </distributionManagement>
   ```

#### Step 2 — Add Nexus Credentials in Jenkins (Global Maven Settings)

1. In Jenkins, navigate to **Manage Jenkins → Managed Files**.
2. Find and edit the **Global Maven Settings** file (ID: `global-settings`), then click **Next**.
3. Locate the `<servers>` tag and add the following entries:

   ```xml
   <servers>
     <server>
       <id>maven-releases</id>
       <username>admin</username>
       <password>nexus_password</password>
     </server>
     <server>
       <id>maven-snapshots</id>
       <username>admin</username>
       <password>nexus_password</password>
     </server>
   </servers>
   ```

4. Click **Submit** to save.

> **Important:** The `<id>` values in the Maven settings file must exactly match the `<id>` values in your `pom.xml` `<distributionManagement>` section.

---

### 3.4 Docker Hub Credentials

Add your Docker Hub credentials to Jenkins so the pipeline can push images to your registry.

1. Navigate to **Manage Jenkins → Credentials → Global → Add Credentials**.
2. Fill in the details:

   | Field       | Value                  |
   |:-----------:|:----------------------:|
   | Kind        | Username with password |
   | Username    | `pranavdaklepatil`     |
   | Password    | `<dockerhub_password>` |
   | ID          | `docker-cred`          |
   | Description | `Docker Hub Credentials` |

3. Click **Create** to save.

---

### 3.5 Kubernetes Configuration

#### Step 1 — Create Namespace

SSH into the master node and create a dedicated namespace for the application:

```bash
kubectl create ns webapps
```

#### Step 2 — Apply RBAC Resources

Apply [`k8s-confi.yaml`](./k8s-confi.yaml) to create the required **ServiceAccount**, **Role**, and **RoleBinding** for Jenkins in a single command:

```bash
kubectl apply -f k8s-confi.yaml
```

> The `k8s-confi.yaml` file contains all three RBAC resources — `ServiceAccount` (named `jenkins`), `Role`, and `RoleBinding` — all scoped to the `webapps` namespace.

#### Step 3 — Generate a Service Account Token

Create a long-lived token secret for the `jenkins` service account:

```bash
kubectl -n webapps describe secret mysecretname
```

Copy the `token` value from the output.

#### Step 4 — Add the Kubernetes Token to Jenkins

1. In Jenkins, navigate to **Manage Jenkins → Credentials → Global → Add Credentials**.
2. Fill in the details:

   | Field       | Value                    |
   |:-----------:|:------------------------:|
   | Kind        | Secret text              |
   | Secret      | `<token from above>`     |
   | ID          | `k8s-token`              |
   | Description | `Kubernetes Token`       |

3. Click **Create** to save.

---

## 4. Pipeline Job Setup

1. In Jenkins, click **New Item**.
2. Enter a name and select **Pipeline**.
3. Under **Pipeline Definition**, choose **Pipeline script from SCM**.
4. Configure the repository URL and credentials.
5. Set the **Script Path** to `Jenkinsfile` — it is located at the root of the repository.
6. Save and run the pipeline.

---

## 5. Summary

This guide provisions a complete, production-ready CI/CD infrastructure on AWS:

| Component          | Details                                  |
|:------------------:|:----------------------------------------:|
| Kubernetes Cluster | 1 Master Node + 2 Worker Nodes           |
| Jenkins            | CI/CD orchestration server               |
| SonarQube          | Static code analysis & quality gates     |
| Nexus              | Artifact repository manager              |
| Docker             | Container runtime on all nodes           |
| Trivy              | Container image vulnerability scanner    |
| AWS Infrastructure | EC2 instances within a private VPC       |

### Credentials Summary

| Credential ID   | Type                   | Purpose                        |
|:---------------:|:----------------------:|:------------------------------:|
| `sonar-token`   | Secret Text            | SonarQube API authentication   |
| `docker-cred`   | Username with Password | Docker Hub image push/pull     |
| `k8s-token`     | Secret Text            | Kubernetes cluster access      |
| `global-settings` | Maven Settings File  | Nexus repository authentication |

> **Next Steps:** Configure webhook integration between your Git repository and Jenkins to trigger pipeline runs automatically on every push or pull request.