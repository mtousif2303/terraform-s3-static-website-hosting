# 🚀 terraform-s3-static-hosting

> Deploy **any static website to AWS S3 in minutes** using Terraform — automated bucket setup, public access, ACL, website configuration & remote state. Zero manual clicks.

[![Terraform](https://img.shields.io/badge/Terraform-≥1.3.0-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-S3-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/s3/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Live-brightgreen)](http://mohamed-tousif-portfolio.s3-website-us-east-1.amazonaws.com)

---

## 📸 Live Demo

> **[🌐 View Live Portfolio →](http://mohamed-tousif-portfolio.s3-website-us-east-1.amazonaws.com)**

![Portfolio Preview](https://img.shields.io/badge/Hosted%20On-AWS%20S3-FF9900?style=for-the-badge&logo=amazonaws)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Terraform Steps Explained](#-terraform-steps-explained)
- [Outputs](#-outputs)
- [Remote State (Step 8)](#-remote-state-step-8)
- [Destroy Resources](#-destroy-resources)
- [Troubleshooting](#-troubleshooting)
- [Author](#-author)

---

## 🔍 Overview

This project automates the full lifecycle of hosting a static website on **AWS S3** using **Terraform** — from creating an empty bucket to making it publicly accessible and configuring it as a website. It covers all **8 configuration steps** taught in the DevOps for BigData with CI/CD course.

### ✅ What gets provisioned

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` | Creates the S3 bucket |
| `aws_s3_bucket_ownership_controls` | Sets ownership to BucketOwnerPreferred |
| `aws_s3_bucket_public_access_block` | Disables public access restrictions |
| `aws_s3_bucket_acl` | Applies `public-read` ACL |
| `aws_s3_object` (×2) | Uploads `index.html` & `error.html` |
| `aws_s3_bucket_website_configuration` | Configures static website hosting |
| `aws_s3_bucket_policy` | Grants public `GetObject` access |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                   Your Machine                  │
│                                                 │
│  terraform apply  ──►  AWS Provider             │
│                              │                  │
└──────────────────────────────│──────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │    AWS S3       │
                    │                 │
                    │  ┌───────────┐  │
                    │  │  Bucket   │  │
                    │  │  (public) │  │
                    │  │           │  │
                    │  │index.html │  │
                    │  │error.html │  │
                    │  └───────────┘  │
                    │                 │
                    │  Website URL ◄──┼──── Internet
                    └─────────────────┘
```

---

## 📁 Project Structure

```
terraform-s3-static-hosting/
│
├── main.tf              # All 8 AWS resource steps
├── variables.tf         # Input variable definitions
├── outputs.tf           # Website URL & bucket info
├── terraform.tfvars     # Your custom values (⚠️ not committed)
├── .gitignore           # Excludes state & secrets
├── README.md            # This file
│
└── website/
    ├── index.html       # Main homepage
    └── error.html       # 404 error page
```

---

## 🧰 Prerequisites

Before you begin, make sure you have:

| Tool | Version | Install |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | ≥ 1.3.0 | `brew install terraform` |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | v2+ | `brew install awscli` |
| AWS Account | - | [Sign up free](https://aws.amazon.com/free/) |

---

## ⚡ Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/mtousif2303/terraform-s3-static-hosting.git
cd terraform-s3-static-hosting
```

### 2. Configure AWS credentials

```bash
aws configure
```

```
AWS Access Key ID:     xxxxxxxxxx
AWS Secret Access Key: xxxxxxxxxx
Default region:        us-east-1
Default output format: json
```

### 3. Set your bucket name

Edit `terraform.tfvars`:

```hcl
aws_region  = "us-east-1"
bucket_name = "your-unique-bucket-name"   # ⚠️ Must be globally unique!
```

> **Note:** S3 bucket names must be globally unique across all AWS accounts. Use lowercase letters, numbers, and hyphens only — no underscores.

### 4. Add your website files

Replace the files inside `website/` with your own:

```
website/
├── index.html    ← Your homepage
└── error.html    ← Your 404 page
```

### 5. Deploy

```bash
# Initialise Terraform & download AWS provider
terraform init

# Preview what will be created
terraform plan

# Deploy to AWS
terraform apply
```

Type `yes` when prompted.

### 6. Visit your website 🎉

After `apply` completes, Terraform prints your live URL:

```
Outputs:

website_url  = "http://your-bucket-name.s3-website-us-east-1.amazonaws.com"
bucket_name  = "your-bucket-name"
bucket_arn   = "arn:aws:s3:::your-bucket-name"
```

---

## ⚙️ Configuration

All configurable values live in `terraform.tfvars`:

| Variable | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | AWS region to deploy into |
| `bucket_name` | `my-static-site` | S3 bucket name (globally unique) |
| `environment` | `dev` | Environment tag (`dev`, `staging`, `prod`) |

---

## 📖 Terraform Steps Explained

The `main.tf` implements all 8 steps from the DevOps workflow:

```
Step 1  →  Setup AWS Provider
Step 2  →  Create Empty Bucket
Step 3  →  Setup Ownership Controls to Bucket Owner
Step 4  →  Make the Bucket Public Access Block
Step 5  →  Assign ACL to Bucket
Step 6  →  Move Files Inside Bucket
Step 7  →  Setup Main and Error Pages
Step 8  →  Save the State (remote backend)
```

### Step 1 – AWS Provider

```hcl
provider "aws" {
  region = var.aws_region
}
```

### Step 2 – Create Bucket

```hcl
resource "aws_s3_bucket" "static_site" {
  bucket        = var.bucket_name
  force_destroy = true
}
```

### Steps 3–5 – Ownership, Public Access & ACL

These three must be applied **in order** (enforced by `depends_on`) to allow public access:

```
Ownership Controls → Public Access Block → ACL (public-read)
```

### Step 6 – Upload Files

```hcl
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
  acl          = "public-read"
}
```

### Step 7 – Website Configuration

```hcl
resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  index_document { suffix = "index.html" }
  error_document { key    = "error.html" }
}
```

### Step 8 – Remote State

Uncomment the `backend "s3"` block in `main.tf` to store state remotely (recommended for teams):

```hcl
backend "s3" {
  bucket = "your-terraform-state-bucket"
  key    = "static-site/terraform.tfstate"
  region = "us-east-1"
}
```

---

## 📤 Outputs

After a successful `terraform apply`:

| Output | Description |
|---|---|
| `website_url` | Full HTTP URL of your hosted site |
| `bucket_name` | Name of the created S3 bucket |
| `bucket_arn` | ARN of the S3 bucket |

---

## 🗑️ Destroy Resources

To tear down all resources and avoid AWS charges:

```bash
terraform destroy
```

Type `yes` when prompted. This will delete the bucket and all files inside it.

---

## 🔧 Troubleshooting

### ❌ `BucketAlreadyExists` error
The bucket name is already taken globally. Change `bucket_name` in `terraform.tfvars` to something unique.

### ❌ `InvalidBucketName` error
S3 bucket names **cannot contain underscores**. Use hyphens instead:
```
✅ my-portfolio-site
❌ my_portfolio_site
```

### ❌ `AccessDenied` during apply
Your AWS credentials don't have S3 permissions. Attach the `AmazonS3FullAccess` policy to your IAM user.

### ❌ Website shows `403 Forbidden`
The bucket policy or ACL was not applied. Run:
```bash
terraform apply -refresh=true
```

### ❌ `Error: Reference to undeclared resource`
All resources in `main.tf` must use the **same resource label**. Ensure every reference to the bucket uses `aws_s3_bucket.static_site`.

---

## 📚 What I Learned

This project was built as part of the **DevOps For BigData With CI/CD** course, covering:

- Infrastructure as Code with Terraform
- AWS S3 static website hosting
- IAM permissions and bucket policies
- Terraform state management
- CI/CD pipeline concepts

---

## 👤 Author

**Mohamed Tousif**
SAP Commerce Cloud Lead · Dubai, UAE

[![LinkedIn](https://img.shields.io/badge/LinkedIn-mohamedtousif-0077B5?logo=linkedin)](https://www.linkedin.com/in/mohamedtousif/)
[![GitHub](https://img.shields.io/badge/GitHub-mtousif2303-181717?logo=github)](https://github.com/mtousif2303)
[![Email](https://img.shields.io/badge/Email-tousif9743@gmail.com-D14836?logo=gmail)](mailto:tousif9743@gmail.com)

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<div align="center">

⭐ **If this project helped you, give it a star!** ⭐

</div>
