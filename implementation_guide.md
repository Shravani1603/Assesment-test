# Directus CI/CD Implementation Guide

This document outlines the end-to-end implementation of the Directus CMS deployment using Infrastructure as Code (IaC) and an automated CI/CD pipeline.

## 1. Project Overview
The goal was to automate the provisioning and deployment of a Directus site on AWS. The architecture follows modern DevOps practices using Terraform, Docker, and GitLab CI/CD.

## 2. Infrastructure Architecture (Terraform)
The infrastructure is defined in the `/terraform` directory and includes:

*   **VPC & Networking**: A custom VPC with a public subnet, internet gateway, and route tables.
*   **Security Groups**: 
    *   Port 22 (SSH) for deployment.
    *   Port 8055 (Directus) for web access.
*   **EC2 Instance**: A `t2.micro` instance running Ubuntu 22.04 LTS.
*   **TLS Key Pair**: Automatically generated using the `tls_private_key` resource to allow secure SSH access without pre-existing keys.
*   **Provisioning**: A `user_data` script installs Docker and Docker Compose automatically upon instance boot.

## 3. Container Orchestration (Docker)
Directus is deployed using `docker-compose.yml`, which orchestrates two services:
1.  **Directus CMS**: The main application service.
2.  **PostgreSQL**: The relational database for content storage.

**Note:** The `.env` file is generated dynamically by the CI/CD pipeline to ensure secrets are never committed to version control.

## 4. CI/CD Pipeline (GitLab)
The `.gitlab-ci.yml` file defines a multi-stage pipeline:

1.  **Validate**: Checks Terraform formatting and linting.
2.  **Plan**: Generates the Terraform execution plan.
3.  **Provision**: Executes `terraform apply` to create the AWS resources.
4.  **Deploy**: 
    *   Copies `docker-compose.yml` to the server via SCP.
    *   Generates the `.env` file on the fly.
    *   Starts services using `docker compose up -d`.
5.  **Test**: Runs health checks against the `/server/ping` endpoint to verify the CMS is online.
6.  **Cleanup**: A manual stage to `terraform destroy` the infrastructure when finished.

## 5. Security & Best Practices
*   **Encrypted Storage**: EC2 root volume is encrypted.
*   **Least Privilege**: Security groups only allow necessary inbound traffic.
*   **Secrets Management**: GitLab CI/CD variables are used for sensitive data (DB passwords, Admin credentials).
*   **Dynamic Cleanup**: Infrastructure is treated as ephemeral and can be destroyed instantly.

---
**Deployment Finalized**: Accessible at `http://98.80.137.188:8055`
