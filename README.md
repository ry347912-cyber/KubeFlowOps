# 🚀 DevOps CI/CD Platform

```
 ██████╗██╗    ██████╗ ██████╗     ██████╗ ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
██╔════╝██║   ██╔════╝██╔══██╗    ██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║
██║     ██║   ██║     ██║  ██║    ██████╔╝██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║
██║     ██║   ██║     ██║  ██║    ██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║
╚██████╗██║   ╚██████╗██████╔╝    ██║     ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝    ╚═════╝╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
```

> **End-to-End DevOps CI/CD Pipeline — GitHub Actions · Docker · AWS ECR · EC2 · Terraform · Nginx**

![CI](https://github.com/YOUR_USERNAME/cicd-platform/actions/workflows/ci.yml/badge.svg)
![CD](https://github.com/YOUR_USERNAME/cicd-platform/actions/workflows/cd.yml/badge.svg)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker)
![AWS](https://img.shields.io/badge/AWS-EC2%20%2B%20ECR-FF9900?logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🎯 What is this?

A **production-grade CI/CD pipeline** that automatically tests, builds, scans, and deploys a Python Flask API to AWS EC2 — triggered on every `git push`.

```
Developer pushes code
        │
        ▼
GitHub Actions CI Triggered
        │
        ├─→ 🧪 Run Tests (pytest + coverage)
        ├─→ 🔒 Security Scan (Bandit)
        ├─→ 🐳 Build Docker Image
        ├─→ 🔍 Container Scan (Trivy)
        ├─→ 📤 Push to AWS ECR
        │
        ▼
GitHub Actions CD Triggered
        │
        ├─→ 🔑 SSH into EC2
        ├─→ 📥 Pull new image from ECR
        ├─→ ♻️  Replace running container
        ├─→ ✅ Health check (auto-rollback on fail)
        └─→ 📣 Slack notification
```

---

## ✨ Features

| Feature | Details |
|---|---|
| ⚡ Auto Deploy | Every push to `main` triggers full pipeline |
| 🧪 Test Gate | Deployment blocked if tests fail |
| 🔒 Security Scan | Bandit (SAST) + Trivy (container) |
| 🐳 Multi-stage Docker | Slim production image with non-root user |
| 📤 AWS ECR | Private container registry with lifecycle policy |
| ☁️ Terraform IaC | Entire AWS infra provisioned in one command |
| ♻️ Auto Rollback | Health check fails → automatic rollback |
| 📣 Slack Alerts | Success and failure notifications |
| 🔄 Zero-Downtime | Old container stops only after new one starts |
| 🌐 Nginx Proxy | Rate limiting + security headers |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  AWS (ap-south-1 Mumbai)                  │
│                                                           │
│   ┌─────────────┐    ┌──────────────────────────────┐   │
│   │  Amazon ECR │    │    EC2 t2.micro (Free Tier)   │   │
│   │             │    │                               │   │
│   │  Docker     │───▶│  ┌─────────┐  ┌───────────┐  │   │
│   │  Images     │    │  │  Nginx  │  │  Flask    │  │   │
│   │             │    │  │ :80     │─▶│  App :5000│  │   │
│   └─────────────┘    │  └─────────┘  └───────────┘  │   │
│                       └──────────────────────────────┘   │
│                                   ▲                       │
│   ┌────────────────────────────┐  │                       │
│   │       GitHub Actions       │──┘ SSH + Docker Deploy  │
│   │  CI: Test → Build → Scan  │                          │
│   │  CD: Pull → Run → Health  │                          │
│   └────────────────────────────┘                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
cicd-platform/
│
├── 📁 app/                    ← Flask Application
│   ├── app.py                 ← Main API (4 endpoints)
│   ├── requirements.txt       ← Python deps
│   └── tests/
│       └── test_app.py        ← 9 pytest tests
│
├── 📁 .github/workflows/      ← CI/CD Pipelines
│   ├── ci.yml                 ← Test → Build → Push to ECR
│   └── cd.yml                 ← Pull → Deploy → Health check
│
├── 📁 terraform/              ← AWS Infrastructure as Code
│   ├── main.tf                ← VPC, EC2, ECR, Security Group
│   ├── variables.tf           ← Input variables
│   ├── outputs.tf             ← EC2 IP, ECR URL, SSH command
│   └── user_data.sh           ← EC2 bootstrap (Docker, AWS CLI)
│
├── 📁 nginx/
│   └── nginx.conf             ← Reverse proxy + rate limiting
│
├── 📁 scripts/
│   ├── deploy.sh              ← Manual deploy (emergency)
│   └── rollback.sh            ← Rollback to previous image
│
├── Dockerfile                 ← Multi-stage production image
├── docker-compose.yml         ← Local dev environment
└── README.md                  ← You are here
```

---

## 🚀 Setup — Step by Step

### Step 1 — AWS Free Tier Setup

1. Create AWS account at [aws.amazon.com](https://aws.amazon.com)
2. Go to **IAM** → Create user → Attach policies:
   - `AmazonEC2FullAccess`
   - `AmazonECR_FullAccess`
   - `AmazonVPCFullAccess`
3. Create **Access Key** → save `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

### Step 2 — Provision AWS Infrastructure

```bash
# 1. Generate SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# 2. Clone repo
git clone https://github.com/YOUR_USERNAME/cicd-platform.git
cd cicd-platform/terraform

# 3. Configure AWS CLI
aws configure
# Enter: Access Key ID, Secret Key, region: ap-south-1, format: json

# 4. Deploy infrastructure
terraform init
terraform plan
terraform apply   # Type 'yes' when prompted

# 5. Note the outputs — you'll need these!
# ec2_public_ip  →  add to GitHub Secrets as EC2_HOST
# ecr_repository_name  →  add to GitHub Secrets as ECR_REPOSITORY
```

### Step 3 — GitHub Secrets Setup

Go to your repo → **Settings → Secrets and variables → Actions** → Add:

| Secret Name | Value | Where to get |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key | AWS IAM |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key | AWS IAM |
| `EC2_HOST` | EC2 Public IP | `terraform output ec2_public_ip` |
| `EC2_SSH_KEY` | Content of `~/.ssh/id_rsa` | `cat ~/.ssh/id_rsa` |
| `ECR_REPOSITORY` | ECR repo name | `terraform output ecr_repository_name` |
| `SLACK_WEBHOOK_URL` | Slack webhook URL | Slack API (optional) |

### Step 4 — Push and Watch Pipeline Run!

```bash
# In repo root
git add .
git commit -m "feat: initial CI/CD setup"
git push origin main

# Go to GitHub → Actions tab → watch it run!
```

---

## 🧪 Run Tests Locally

```bash
cd app
pip install -r requirements.txt
pytest tests/ -v --cov=. --cov-report=term-missing
```

Expected output:
```
tests/test_app.py::test_home_returns_200         PASSED
tests/test_app.py::test_home_has_status_field    PASSED
tests/test_app.py::test_health_returns_200       PASSED
tests/test_app.py::test_health_is_healthy        PASSED
tests/test_app.py::test_info_endpoint            PASSED
tests/test_app.py::test_echo_endpoint            PASSED
...
Coverage: 94%  ✅
```

---

## 🐳 Run Locally with Docker

```bash
# Build and run
docker compose up --build

# Test
curl http://localhost/health
curl http://localhost/api/info
```

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | App info + version + timestamp |
| GET | `/health` | Health check (used by CI/CD) |
| GET | `/api/info` | Build info — version, commit, deploy time |
| POST | `/api/echo` | Echo back any JSON payload |

---

## 🔄 Pipeline Flow Detail

```
Push to main
     │
     ▼
[CI — ci.yml]
  ├── Job 1: test
  │     ├── Checkout code
  │     ├── Setup Python 3.11
  │     ├── pip install
  │     ├── pytest (must pass ≥80% coverage)
  │     └── Upload coverage artifact
  │
  ├── Job 2: security (needs: test)
  │     ├── Bandit SAST scan
  │     └── Upload security report
  │
  └── Job 3: docker-build (needs: test, security)
        ├── Generate image tag (SHA + timestamp)
        ├── Configure AWS credentials
        ├── Login to ECR
        ├── Docker build (multi-stage)
        ├── Trivy container scan
        └── Push to ECR (:tag + :latest)

[CD — cd.yml] (triggers after CI success)
  └── Job: deploy
        ├── SSH into EC2
        ├── Pull new image from ECR
        ├── Stop old container
        ├── Start new container
        ├── Health check (5 retries)
        ├── Auto-rollback on failure
        └── Slack notification
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Application | Python 3.11 · Flask · Gunicorn |
| Containerization | Docker (multi-stage) · Docker Compose |
| CI/CD | GitHub Actions |
| Registry | AWS ECR |
| Compute | AWS EC2 t2.micro (Free Tier) |
| Infrastructure | Terraform v1.7+ |
| Reverse Proxy | Nginx (rate limit + headers) |
| Security Scanning | Bandit (SAST) · Trivy (container) |
| Testing | pytest · pytest-cov |
| Notifications | Slack Webhooks |

---

## 💼 What This Proves (Interview Points)

- ✅ Built end-to-end CI/CD from scratch — not just used existing tools
- ✅ Wrote Infrastructure as Code — zero manual AWS console clicks
- ✅ Implemented security scanning in pipeline (SAST + container)
- ✅ Auto-rollback on failed health check
- ✅ Multi-stage Docker — production-grade, non-root, minimal image
- ✅ Free Tier deployment — cost-conscious cloud thinking

---

## 📄 License

MIT License — Free for educational and portfolio use.

---

⭐ **Star this repo if it helped your DevOps journey!**
