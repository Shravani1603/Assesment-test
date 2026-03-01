# Directus CI/CD Demo Instructions

Use this file to quickly demonstrate or rerun the Directus CI/CD deployment.

## 1. Prerequisites
Ensure the following variables are set in your GitLab CI/CD Settings (`Settings > CI/CD > Variables`):

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Key |
| `AWS_DEFAULT_REGION` | e.g. `us-east-1` |
| `ADMIN_EMAIL` | Directus Login Email |
| `ADMIN_PASSWORD` | Directus Login Password |
| `DB_PASSWORD` | PostgreSQL Password |
| `DIRECTUS_SECRET` | A random 32+ character string |

## 2. Running the Pipeline
The pipeline is designed to be semi-automated. Follow these steps in GitLab:

1.  **Navigate** to `Build > Pipelines`.
2.  **Run Pipeline** on the `main` branch.
3.  The **Validate**, **Plan**, and **Provision** stages will run.
4.  **Manual Step**: You may need to manually trigger the `terraform_apply` job if configured as `manual` for safety.
5.  Once `terraform_apply` finishes, the **Deploy** and **Test** stages will execute automatically.

## 3. Local Development / Manual Inspection
If you have the files locally, you can inspect or manage the infra with these commands:

```bash
# Initialize Terraform
cd terraform
terraform init

# View the plan
terraform plan

# Deploy infrastructure manually (requires AWS CLI login)
terraform apply -auto-approve

# Check site health (Replace <IP> with server_ip.txt content)
curl -I http://<IP>:8055/server/ping
```

## 4. Verification URL
After a successful run, the site will be live at:
**`http://98.80.137.188:8055`**

## 5. Cleanup
To avoid costs, always run the cleanup job:
1.  Go to the latest pipeline.
2.  Trigger the **`terraform_destroy`** job manually.
