# ECS Portfolio Infrastructure

This repository contains a full-stack, production-ready AWS architecture built using Terraform. It provisions an end-to-end environment to host a containerized portfolio application (frontend and backend).

The application consists of two containers:
- `frontend`: A static UI.
- `backend`: A Node.js API with Express.

The backend connects to an Amazon RDS PostgreSQL instance, and all incoming traffic is handled by an Application Load Balancer (ALB) which routes:
- `/` -> `frontend` target group
- `/api/*` -> `backend` target group

## Repository Structure
- `main.tf`, `variables.tf`, `outputs.tf`: Root Terraform configuration for provisioning resources.
- `modules/`: Custom reusable Terraform modules (`vpc`, `alb`, `ecs`, `route53`, `acm`, `rds`).
- `sample-app/frontend/`: Frontend source code and Dockerfile.
- `sample-app/backend/`: Backend source code, Express API, and Dockerfile.

---

## 🚀 Detailed Deployment Guide

Follow these step-by-step instructions to deploy the infrastructure and application to your AWS account.

### Step 1: Prerequisites
Before you begin, ensure you have the following installed and configured:
1. **Terraform**: version `>= 1.5` installed ([Download Terraform](https://developer.hashicorp.com/terraform/downloads)).
2. **AWS CLI**: Installed and configured. Run `aws configure` to set up your AWS Access Key, Secret Key, and Default Region. Ensure your IAM user has sufficient permissions (Admin access is recommended for initial setup).
3. **Docker**: Installed and running locally. You must be logged into a container registry (e.g., Docker Hub) via `docker login`.
4. **A Registered Domain Name**: You need access to the DNS settings of a domain you own (e.g., via GoDaddy, Namecheap, Hostinger) to route traffic to the AWS infrastructure.

### Step 2: Configure Environment Variables
1. Clone this repository and navigate to the project root.
2. Create your own variable file by copying the example template:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Open `terraform.tfvars` in your editor and update the following key variables:
   - **Networking**: `vpc_cidr`, `azs` (Availability Zones for your chosen region).
   - **Database**: Set a secure `rds_password`, and update `rds_username` or `rds_db_name` if needed.
   - **Domain**: 
     - `zone_name` (e.g., `example.com`)
     - `app_subdomain` (e.g., `portfolio` to deploy at `portfolio.example.com`)
   - **Docker Images**: Keep track of the `containers[].image` names. You will build and push to these exact repository endpoints in the next step.

> **Note:** `terraform.tfvars` is automatically ignored in `.gitignore` to prevent secret leakage.

### Step 3: Build and Push Docker Images
You need to package your app into Docker containers and push them to your registry (e.g., Docker Hub) so ECS can pull them during deployment.

1. **Build and push the frontend:**
   ```bash
   docker build -t <your-dockerhub-username>/personal-portfolio-frontend:latest sample-app/frontend
   docker push <your-dockerhub-username>/personal-portfolio-frontend:latest
   ```
   
2. **Build and push the backend:**
   ```bash
   docker build -t <your-dockerhub-username>/personal-portfolio-backend:latest sample-app/backend
   docker push <your-dockerhub-username>/personal-portfolio-backend:latest
   ```

*Make sure these image tags precisely match the `image` variable blocks configured in your `terraform.tfvars` file.*

### Step 4: Initialize Terraform
Initialize your Terraform working directory to download the necessary providers and modules.

```bash
terraform init
terraform validate
```
*`terraform validate` ensures your configuration format is syntactically valid.*

### Step 5: Provision Route53 Hosted Zone (Targeted Apply)
Our architecture provisions an SSL/TLS certificate via ACM (AWS Certificate Manager). ACM requires DNS validation to prove you own the domain. Before deploying the full stack, you must deploy the Route53 zone so you can point your domain registrar to AWS.

Run a targeted apply to strictly build the Route53 Hosted Zone:
```bash
terraform apply -target=module.route53.aws_route53_zone.this -auto-approve
```

### Step 6: Update Domain Nameservers
Once Terraform creates the Route53 zone, AWS assigns 4 unique nameservers (NS). You must update your domain registrar (Namecheap, GoDaddy, Hostinger, etc.) to use these nameservers.

1. Retrieve the nameservers from AWS CLI:
   ```bash
   aws route53 get-hosted-zone --id <your-hosted-zone-id> --query 'DelegationSet.NameServers' --output text
   ```
2. Log into your domain registrar's dashboard.
3. Locate the "Custom DNS" or "Nameservers" section.
4. Replace the default nameservers with the 4 AWS nameservers provided by the command above.

### Step 7: Verify DNS Propagation
Nameserver changes can take anywhere from a few minutes to up to 48 hours to propagate globally. Verify that the DNS has updated before moving forward:

```bash
dig NS <your_zone_name> +short
```
*Wait until the output matches the AWS Nameservers.*

### Step 8: Deploy the Full Infrastructure Stack
Once DNS propagation is confirmed, deploy the remaining infrastructure (VPC, ALB, RDS, ECS Cluster, Services, and ACM Certificate):

```bash
terraform apply -auto-approve
```

> **Important**: During this step, Terraform will automatically create DNS records for ACM validation. If you correctly followed Step 6, the certificate will issue seamlessly. The deployment will pause while waiting for database creation and certificate validation (this usually takes 5-10 minutes).

### Step 9: Verify the Deployment
Once `terraform apply` completes successfully, verify your application is running.

1. **Access the Frontend App:** Open your browser and navigate to `https://<app_subdomain>.<zone_name>`
2. **Check Backend API Health:** Navigate to `https://<app_subdomain>.<zone_name>/api/health`
3. **Check Database Connectivity:** Navigate to `https://<app_subdomain>.<zone_name>/api/visits` to confirm the backend is reading/writing to RDS.

---

## Troubleshooting Common Issues

- **ACM Validation Timeout/Stuck:** Ensure you have correctly updated your domain's nameservers at the registrar (Step 6). It will stay 'pending validation' indefinitely if the domain does not point to Route53.
- **Backend Task Crashes (`no pg_hba.conf entry`):** This usually means SSL isn't forced correctly on the connection URI. Ensure `DB_SSL=true` is injected via the environment variables in `main.tf`.
- **Frontend shows `Unexpected token '<'` when hitting API:** This indicates the ALB is returning a default HTML response because the backend target group is unhealthy. Ensure the RDS database is fully initialized and the backend is connecting to it on startup.

## Teardown Infrastructure
To avoid incurring unnecessary AWS costs, destroy all provisioned infrastructure when you are done:

```bash
terraform destroy -auto-approve
```
*Note: This action is irreversible and will delete your ECS cluster, network, and RDS data.*
