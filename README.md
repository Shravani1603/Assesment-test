# Directus CI/CD on AWS

This repository contains a fully automated CI/CD pipeline for deploying Directus CMS and PostgreSQL on AWS EC2 using Terraform and GitHub Actions.

## Quick Start (Manual Setup Required)

To get this pipeline running, you **must** configure the following in GitHub:

### 1. Repository Secrets
Go to **Settings → Secrets and variables → Actions** and add:

| Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key |
| `AWS_DEFAULT_REGION` | Usually `us-east-1` |
| `ADMIN_EMAIL` | Directus log-in email |
| `ADMIN_PASSWORD` | Directus log-in password |
| `DB_PASSWORD` | PostgreSQL database password |
| `DIRECTUS_SECRET` | A random 32-character string |

### 2. Environments
Go to **Settings → Environments** and create:
1. `production`: Protects the deployment job.
2. `cleanup`: Protects the destruction job.

## Troubleshooting

### "hostname contains invalid characters"
This error is now fixed in the pipeline. It was caused by hidden whitespace in the server IP. The pipeline now uses regex to clean the IP automatically.

### "No valid credential sources found"
This means your **AWS Secrets** are missing. The pipeline now includes a specific "Check Secrets" stage that will tell you exactly what is missing.

## Architecture
- **Infrastructure**: AWS VPC, Subnet, Internet Gateway, Security Group, EC2.
- **App**: Directus CMS + PostgreSQL (Docker Compose).
- **Automation**: GitHub Actions (6 Stages: Validate, Plan, Provision, Deploy, Test, Cleanup).
