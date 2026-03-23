# 🎲 Board Game Database — CI/CD Pipeline

> **A production-grade CI/CD pipeline** designed and implemented for the Board Game Database Full-Stack Web Application — a platform for browsing board games and reviews with role-based access control. This README documents the complete DevOps pipeline built to automate the build, test, security scan, containerization, and deployment lifecycle.

---

## 📌 Table of Contents

- [Pipeline Architecture](#-pipeline-architecture)
- [Tools & Technologies](#-tools--technologies)
- [Pipeline Stages](#-pipeline-stages)
- [Notifications](#-notifications)
- [Prerequisites](#-prerequisites)

---

## 🏗️ Pipeline Architecture

<p align="center">
  <img src="./CICD-Architecture.png" alt="CI/CD Pipeline Architecture" width="900"/>
</p>

<p align="center">
  <em>End-to-end CI/CD pipeline — GitHub → Jenkins → Maven → SonarQube → Trivy → Nexus → Docker → Kubernetes → Email Notification</em>
</p>

---

## 🛠️ Tools & Technologies

<div align="center">

| Tool | Category | Purpose |
|------|----------|---------|
| **GitHub** | Source Control | Hosts application source code; triggers Jenkins via webhook on every push |
| **Jenkins** | CI/CD Orchestration | Automates and manages the entire pipeline end-to-end |
| **Maven** | Build Tool | Compiles source code, runs unit tests, and packages the application artifact |
| **SonarQube** | Code Quality | Performs static analysis — detects bugs, vulnerabilities, and code smells |
| **Trivy** | Security Scanning | Scans both the filesystem and Docker image for known CVEs |
| **Nexus Repository** | Artifact Registry | Stores and versions the built `.jar` artifact |
| **Docker** | Containerization | Packages the application into a portable, runnable container image |
| **Kubernetes** | Orchestration | Deploys, scales, and manages containers in production |
| **Gmail (SMTP)** | Notifications | Sends pipeline success/failure alerts to the developer |

</div>

---

## 📋 Pipeline Stages

As the DevOps engineer on this project, I designed the pipeline with **security and quality gates at every stage**, ensuring only clean, tested, and vulnerability-free code reaches production.

### Stage 1 — 🔀 Source Code Trigger (GitHub → Jenkins)

- A webhook is configured on the GitHub repository to notify Jenkins on every `push` or `pull request merge`
- Jenkins picks up the event and kicks off the pipeline automatically — **zero manual intervention required**

---

### Stage 2 — ⚙️ Compile & Unit Test (Maven)

```bash
mvn clean compile
mvn test
```

- Maven compiles the Java source code and resolves all dependencies
- Unit tests are executed; the pipeline **halts immediately on test failure**, preventing bad code from proceeding further

---

### Stage 3 — 🔍 Code Quality Gate (SonarQube)

```bash
mvn sonar:sonar \
  -Dsonar.projectKey=board-game-db \
  -Dsonar.host.url=http://<sonarqube-host>:9000 \
  -Dsonar.login=<token>
```

- SonarQube performs deep static analysis on the codebase
- Checks for **bugs, security hotspots, code smells, duplications, and test coverage**
- A **Quality Gate** is enforced — pipeline fails if the gate is not passed
- Results are published to the SonarQube dashboard for developer review

---

### Stage 4 — 🛡️ Filesystem Vulnerability Scan (Trivy)

```bash
trivy fs --exit-code 1 --severity HIGH,CRITICAL .
```

- Trivy scans the project's source files, `pom.xml` dependencies, and the filesystem for known CVEs **before packaging**
- Pipeline is configured to **fail on HIGH and CRITICAL vulnerabilities**
- This is the first of two Trivy scans — catches issues early before an image is even built

---

### Stage 5 — 📦 Build & Publish Artifact (Maven → Nexus)

```bash
mvn clean package -DskipTests
mvn deploy
```

- Maven packages the application into a deployable `.jar` artifact
- The artifact is **uploaded and versioned in Nexus Repository Manager**, making it available for Docker image construction
- Nexus serves as the single source of truth for all build artifacts

---

### Stage 6 — 🐳 Docker Image Build

```bash
docker build -t board-game-db:${BUILD_NUMBER} .
docker tag board-game-db:${BUILD_NUMBER} <registry>/board-game-db:latest
```

- Docker builds a container image using the `Dockerfile` in the repository
- The image is tagged with the **Jenkins build number** for full traceability

---

### Stage 7 — 🔒 Docker Image Vulnerability Scan (Trivy)

```bash
trivy image --exit-code 1 --severity HIGH,CRITICAL <registry>/board-game-db:latest
```

- Trivy performs a second scan — this time on the **built Docker image**
- Scans OS packages, base image layers, and installed libraries for vulnerabilities
- This two-phase Trivy approach (filesystem + image) provides **defense-in-depth** security coverage

---

### Stage 8 — 📤 Docker Image Push

```bash
docker push <registry>/board-game-db:latest
docker push <registry>/board-game-db:${BUILD_NUMBER}
```

- The clean, scanned image is pushed to the container registry
- Only images that have **passed all prior quality and security gates** reach this stage

---

### Stage 9 — ☸️ Kubernetes Deployment

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/board-game-db
```

- Kubernetes pulls the latest image and performs a **rolling deployment** — zero downtime
- Deployment health is verified using `kubectl rollout status` before the stage is marked successful

---

### Stage 10 — 📧 Developer Notification (Gmail)

- Jenkins sends an automated email at the **end of every pipeline run**, regardless of outcome
- Notification includes: pipeline status, build number, stage that failed (if any), and a direct link to console logs

---

## 🔒 Security Scanning Strategy

<div align="center">

| Scan | Tool | Placed After | Scope |
|------|------|-------------|-------|
| **Filesystem Scan** | Trivy | SonarQube Stage | Source code, dependencies, `pom.xml` |
| **Docker Image Scan** | Trivy | Docker Build Stage | OS packages, base image, libraries |
| **Static Code Analysis** | SonarQube | Unit Test Stage | Bugs, hotspots, code smells, coverage |

</div>

> 💡 **Design Decision:** Two Trivy scans are intentionally placed at different stages — one before packaging (catches dependency issues early) and one after the Docker image is built (catches OS-level vulnerabilities from the base image). This **defense-in-depth** approach ensures no vulnerability slips through to production.


---

## 📧 Notifications

<div align="center">

| Event | Notification Trigger |
|-------|---------------------|
| ✅ Pipeline Success | Email with build number & deployment confirmation |
| ❌ Pipeline Failure | Email with failed stage name & console log link |
| ⚠️ Quality Gate Fail | Email indicating SonarQube gate breach |
| 🔒 Vulnerability Found | Email indicating Trivy scan failure with severity level |

</div>

---

## ✅ Prerequisites

<div align="center">

| Requirement | Details |
|-------------|---------|
| **Jenkins** | v2.400+ with Maven, Docker, SonarQube, Kubernetes, Email Extension plugins |
| **SonarQube** | v9+ server running; token configured in Jenkins credentials |
| **Trivy** | Installed on Jenkins agent (`trivy` binary in `PATH`) |
| **Nexus Repository** | Running instance with Maven hosted repo configured |
| **Docker** | Installed on Jenkins agent; Docker Hub credentials stored in Jenkins |
| **Kubernetes** | Cluster accessible from Jenkins; `kubectl` configured with kubeconfig |
| **Java** | JDK 17+ |
| **Maven** | 3.8+ |
| **SMTP** | Gmail SMTP configured in Jenkins for email notifications |

</div>

---

<div align="center">
  <em>Designed & implemented by PranavDaklePatil · Automated from commit to production</em>
</div>