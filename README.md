# ECS Portfolio Infrastructure

A production-ready AWS infrastructure built with Terraform that hosts a containerized full-stack application. It provisions a complete environment including networking, compute, database, load balancing, DNS, and TLS — all wired together automatically.

## Architecture Overview

```
Internet
   │
   ▼
Route53 (DNS: portfolio.example.com)
   │
   ▼
ACM (TLS Certificate — DNS validated)
   │
   ▼
Application Load Balancer (public subnets, ports 80 + 443)
   │
   ├── / ──────────────────► ECS Fargate: frontend (nginx, port 80)
   │
   └── /api/* ─────────────► ECS Fargate: backend (Node.js/Express, port 80)
                                              │
                                              ▼
                                    RDS PostgreSQL (data subnets, port 5432)
```

### Infrastructure Components

| Module | Resources Provisioned |
|---|---|
| `vpc` | VPC, public/app/data subnets, IGW, NAT Gateway, route tables, NACLs |
| `alb` | Application Load Balancer, security group, HTTP/HTTPS listeners, path-based routing rules, target groups |
| `ecs` | ECS Cluster (Fargate), task definitions, services, IAM execution role, CloudWatch log groups |
| `rds` | RDS PostgreSQL instance, subnet group, security group |
| `acm` | ACM certificate, Route53 DNS validation records |
| `route53` | Hosted zone, A alias record pointing to ALB |

### Network Topology (3-tier)

```
Public Subnets   (10.20.0.0/24, 10.20.1.0/24, 10.20.2.0/24)  ← ALB, NAT Gateway
App Subnets      (10.20.10.0/24, 10.20.11.0/24, 10.20.12.0/24) ← ECS Fargate tasks
Data Subnets     (10.20.20.0/24, 10.20.21.0/24, 10.20.22.0/24) ← RDS PostgreSQL
```

### Application Components

- **Frontend**: Static HTML served by nginx. Calls backend APIs via relative paths (`/api/*`), which the ALB routes to the backend target group.
- **Backend**: Node.js + Express API. Exposes `/api/health`, `/api/visits`, and `/api/config`. Connects to RDS PostgreSQL using environment variables injected by Terraform at deploy time.
- **Database**: PostgreSQL 16 on RDS. The backend auto-creates the `visits` table on startup via `initSchema()`.

---

## Repository Structure

```
.
├── main.tf                    # Root module — wires all child modules together
├── variables.tf               # All input variable declarations
├── outputs.tf                 # Outputs: VPC ID, subnet IDs, RDS endpoint
├── terraform.tfvars.example   # Template — copy to terraform.tfvars and fill in
├── modules/
│   ├── vpc/                   # VPC, subnets, routing, NACLs
│   ├── alb/                   # Load balancer, listeners, target groups
│   ├── ecs/                   # Fargate cluster, task definitions, services
│   ├── rds/                   # PostgreSQL RDS instance
│   ├── acm/                   # TLS certificate + DNS validation
│   └── route53/               # Hosted zone + ALB alias record
└── sample-app/
    ├── frontend/              # index.html + nginx Dockerfile
    └── backend/               # Express API + pg Dockerfile
```

---

## Prerequisites

Before starting, ensure the following are installed and configured on your machine.

### Required Tools

| Tool | Minimum Version | Install |
|---|---|---|
| Terraform | >= 1.5 | [developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads) |
| AWS CLI | >= 2.x | [docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| Docker | >= 24.x | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |

### AWS IAM Permissions

Your AWS credentials need the following permissions. For initial setup, `AdministratorAccess` is the simplest option. For a least-privilege setup, ensure your IAM user/role has permissions for: EC2, ECS, RDS, Route53, ACM, IAM (role creation), CloudWatch Logs, and Elastic Load Balancing.

```bash
# Verify your credentials are working
aws sts get-caller-identity
```

### Domain Name

You need a registered domain name (e.g., `example.com`) where you can update the nameservers. This is required for Route53 DNS delegation and ACM certificate validation.

---

## Step-by-Step Deployment Guide

### Step 1 — Clone and Configure Variables

```bash
git clone <your-repo-url>
cd <repo-directory>
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and update every value. Key fields to change:

```hcl
# Your target AWS region
aws_region = "ap-south-1"

# Your domain name (must be a domain you own)
zone_name     = "yourdomain.com"
app_subdomain = "portfolio"   # deploys at portfolio.yourdomain.com

# Docker Hub images — must match what you push in Step 2
containers = [
  {
    name          = "frontend"
    image         = "your-dockerhub-username/personal-portfolio-frontend:latest"
    port          = 80
    desired_count = 2
    environment   = []
  },
  {
    name          = "backend"
    image         = "your-dockerhub-username/personal-portfolio-backend:latest"
    port          = 80
    desired_count = 1
    environment   = []
  }
]

# Use a strong, unique password — never commit this to git
rds_password = "YourStrongPassword123!"
```

> `terraform.tfvars` is listed in `.gitignore` and will not be committed.

---

### Step 2 — Build and Push Docker Images

ECS pulls images from a container registry at deploy time. Build and push both images before running Terraform.

```bash
# Log in to Docker Hub
docker login

# Build and push the frontend
docker build -t your-dockerhub-username/personal-portfolio-frontend:latest ./sample-app/frontend
docker push your-dockerhub-username/personal-portfolio-frontend:latest

# Build and push the backend
docker build -t your-dockerhub-username/personal-portfolio-backend:latest ./sample-app/backend
docker push your-dockerhub-username/personal-portfolio-backend:latest
```

Verify the image names in `terraform.tfvars` exactly match what you pushed.

---

### Step 3 — Initialize Terraform

Download the AWS provider and all module dependencies.

```bash
terraform init
```

Validate the configuration syntax:

```bash
terraform validate
```

Preview what Terraform will create (optional but recommended):

```bash
terraform plan
```

---

### Step 4 — Create the Route53 Hosted Zone First

This step must be done in isolation before the full deployment. The reason: ACM certificate validation requires DNS records in Route53, and Route53 must be delegated from your registrar before ACM can validate. Deploying the hosted zone first lets you complete the nameserver update (Step 5) before ACM tries to validate.

```bash
terraform apply -target=module.route53.aws_route53_zone.this -auto-approve
```

Once complete, retrieve the 4 nameservers AWS assigned to your zone:

```bash
# Get your hosted zone ID
aws route53 list-hosted-zones --query "HostedZones[?Name=='yourdomain.com.'].Id" --output text

# Get the nameservers for that zone
aws route53 get-hosted-zone --id <hosted-zone-id> --query 'DelegationSet.NameServers' --output text
```

You will see 4 nameservers like:
```
ns-123.awsdns-45.com
ns-678.awsdns-90.net
ns-111.awsdns-22.org
ns-999.awsdns-01.co.uk
```

---

### Step 5 — Update Nameservers at Your Domain Registrar

Log into your domain registrar (GoDaddy, Namecheap, Hostinger, etc.) and replace the default nameservers with the 4 AWS nameservers from Step 4.

The exact steps vary by registrar, but the general flow is:
1. Go to your domain's DNS settings
2. Find the "Nameservers" or "Custom DNS" section
3. Delete the existing nameservers
4. Add all 4 AWS nameservers
5. Save

---

### Step 6 — Wait for DNS Propagation

Nameserver changes can take anywhere from a few minutes to 48 hours to propagate globally. Check propagation status before proceeding:

```bash
# Check if your domain resolves to AWS nameservers
dig NS yourdomain.com +short
```

The output should match the 4 AWS nameservers. Do not proceed to Step 7 until this resolves correctly — ACM validation will hang indefinitely if DNS is not delegated.

You can also use [whatsmydns.net](https://www.whatsmydns.net/) to check propagation from multiple global locations.

---

### Step 7 — Deploy the Full Infrastructure

Once DNS propagation is confirmed, deploy everything:

```bash
terraform apply -auto-approve
```

This single command provisions in dependency order:
1. VPC, subnets, IGW, NAT Gateway, route tables, NACLs
2. RDS PostgreSQL instance and subnet group
3. ALB, target groups, HTTP/HTTPS listeners
4. Route53 A alias record pointing to the ALB
5. ACM certificate with automatic DNS validation records
6. ECS cluster, IAM roles, task definitions, Fargate services

> The deployment typically takes 10–15 minutes. RDS creation and ACM certificate validation are the longest steps.

---

### Step 8 — Verify the Deployment

Once `terraform apply` completes, verify everything is working.

**Check the frontend:**
```
https://portfolio.yourdomain.com
```

**Check backend health (confirms DB connectivity):**
```
https://portfolio.yourdomain.com/api/health
```
Expected response:
```json
{ "status": "ok", "database": "connected" }
```

**Test RDS read/write:**
```
https://portfolio.yourdomain.com/api/visits
```
Expected response:
```json
{
  "message": "Backend connected to RDS successfully",
  "visits": 1,
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

**Check ECS service status via CLI:**
```bash
aws ecs list-services --cluster personal-portfolio-prod-aps1-ecs --region ap-south-1
aws ecs describe-services \
  --cluster personal-portfolio-prod-aps1-ecs \
  --services personal-portfolio-prod-aps1-ecs-frontend personal-portfolio-prod-aps1-ecs-backend \
  --region ap-south-1 \
  --query 'services[*].{name:serviceName,running:runningCount,desired:desiredCount,status:status}'
```

**View container logs:**
```bash
aws logs tail /ecs/personal-portfolio-prod-aps1-ecs-backend --follow --region ap-south-1
```

---

## Production Hardening Checklist

The default `terraform.tfvars.example` is configured for a basic deployment. For production, review and update these settings:

### RDS

```hcl
rds_multi_az                = true   # Enable standby replica for HA
rds_deletion_protection     = true   # Prevent accidental deletion
rds_skip_final_snapshot     = false  # Take a snapshot before destroy
rds_backup_retention_period = 7      # Keep 7 days of automated backups
rds_instance_class          = "db.t3.small"  # Upgrade from micro for production load
```

### ECS

```hcl
task_cpu              = 512   # Increase CPU allocation
task_memory           = 1024  # Increase memory allocation
log_retention_in_days = 30    # Retain logs longer for auditing

# Increase desired count for redundancy
containers = [
  { name = "frontend", desired_count = 2, ... },
  { name = "backend",  desired_count = 2, ... }
]
```

### Secrets Management

The current setup passes `rds_password` as a plain Terraform variable. For production, use AWS Secrets Manager or SSM Parameter Store:

1. Store the password in Secrets Manager:
```bash
aws secretsmanager create-secret \
  --name "portfolio/rds-password" \
  --secret-string "YourStrongPassword123!" \
  --region ap-south-1
```

2. Reference it in Terraform using a `data` source instead of a variable.

### Tags

Update the `tags` block to include meaningful metadata for cost allocation and resource management:

```hcl
tags = {
  Project     = "personal-portfolio"
  Environment = "production"
  Owner       = "your-team"
  CostCenter  = "engineering"
}
```

---

## Updating the Application

To deploy a new version of the frontend or backend:

1. Build and push a new Docker image (use a versioned tag for traceability):
```bash
docker build -t your-dockerhub-username/personal-portfolio-backend:v1.1.0 ./sample-app/backend
docker push your-dockerhub-username/personal-portfolio-backend:v1.1.0
```

2. Update the image tag in `terraform.tfvars`:
```hcl
image = "your-dockerhub-username/personal-portfolio-backend:v1.1.0"
```

3. Apply the change — Terraform will register a new task definition revision and trigger a rolling ECS deployment:
```bash
terraform apply -auto-approve
```

---

## Troubleshooting

### ACM certificate stuck in "Pending validation"

The certificate will wait indefinitely if Route53 is not the authoritative DNS for your domain. Verify:
```bash
dig NS yourdomain.com +short
```
The output must show AWS nameservers. If it still shows your registrar's nameservers, the delegation has not propagated yet. Wait and retry.

### ECS tasks failing to start / crashing immediately

Check the container logs:
```bash
aws logs tail /ecs/<cluster-name>-backend --follow --region <region>
```

Common causes:
- **`no pg_hba.conf entry`** — SSL connection issue. Ensure `DB_SSL=true` is set. This is injected automatically by `main.tf` via `backend_rds_environment`.
- **`ECONNREFUSED` or connection timeout** — The RDS security group only allows traffic from `app_subnet_cidrs`. Verify ECS tasks are running in the app subnets and the CIDR ranges match.
- **Image pull failure** — The image name in `terraform.tfvars` does not match what was pushed to Docker Hub, or the image is private without pull credentials configured.

### Frontend shows `Unexpected token '<'` when calling `/api/*`

The ALB is returning an HTML error page instead of JSON. This means the backend target group is unhealthy. Check:
1. Backend ECS service has running tasks (`runningCount > 0`)
2. Backend logs show the server started successfully
3. RDS is fully available and the backend connected on startup
4. ALB target group health check at `/api/health` is passing

```bash
aws elbv2 describe-target-health \
  --target-group-arn <backend-target-group-arn> \
  --region <region>
```

### `terraform apply` fails with dependency errors

If you run `terraform apply` without completing the Route53 nameserver delegation first, ACM validation will time out after 60 minutes. Cancel the apply, complete Steps 5–6, then re-run.

---

## Teardown

To destroy all provisioned AWS resources and stop incurring costs:

```bash
terraform destroy -auto-approve
```

> This is irreversible. All data in RDS will be lost unless `rds_skip_final_snapshot = false` was set before destroying.

If `rds_deletion_protection = true` is set, you must disable it first:
```bash
terraform apply -target=module.rds.aws_db_instance.this -var="rds_deletion_protection=false" -auto-approve
terraform destroy -auto-approve
```
