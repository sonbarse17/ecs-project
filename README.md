# ECS Portfolio Infrastructure

This repo deploys a simple portfolio-style app on AWS using Terraform.

The app has two containers:
- `frontend`: static UI
- `backend`: Node.js API

The backend connects to PostgreSQL on RDS, and traffic is routed through an ALB:
- `/` -> frontend
- `/api/*` -> backend

## What's in this repo
- `main.tf`, `variables.tf`, `outputs.tf`: root Terraform wiring
- `modules/`: reusable modules (`vpc`, `alb`, `ecs`, `route53`, `acm`, `rds`)
- `sample-app/frontend`: frontend source and Dockerfile
- `sample-app/backend`: backend source and Dockerfile

## Before you start
- Terraform `>= 1.5`
- AWS CLI configured with working credentials
- Docker installed and logged into Docker Hub

## Configure values
Create your working tfvars file from the template:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` before deployment:
- networking (`vpc_cidr`, subnet CIDRs, AZs)
- domain (`zone_name`, `app_subdomain`)
- database (`rds_*` values)
- container images (`containers[].image`)

Note: `terraform.tfvars` is ignored in `.gitignore`, so secrets are not committed.

## Build and push Docker images
```bash
docker build -t <dockerhub-user>/personal-portfolio-frontend:latest sample-app/frontend
docker push <dockerhub-user>/personal-portfolio-frontend:latest

docker build -t <dockerhub-user>/personal-portfolio-backend:latest sample-app/backend
docker push <dockerhub-user>/personal-portfolio-backend:latest
```

Then set those image names in `terraform.tfvars`.

## Deployment steps
1. Initialize Terraform:

```bash
terraform init
terraform validate
```

2. Create only the Route53 hosted zone first:

```bash
terraform apply -target=module.route53.aws_route53_zone.this -auto-approve
```

3. Copy the Route53 nameservers and update them in your domain provider.

```bash
terraform output -json
# or
aws route53 get-hosted-zone --id <hosted-zone-id> --query 'DelegationSet.NameServers' --output text
```

4. Wait for nameserver propagation and confirm:

```bash
dig NS <zone_name> +short
```

5. After NS points to AWS, deploy the full stack:

```bash
terraform apply -auto-approve
```

## Common deployment issues and fixes
- ACM validation stayed pending because the domain was still delegated to old nameservers.
  Fix: update Hostinger nameservers to Route53 and wait for propagation.

- Backend tasks crashed with `no pg_hba.conf entry ... no encryption`.
  Fix: enable SSL for DB connection (`DB_SSL=true` in Terraform-injected backend env).

- Frontend showed `Unexpected token '<'` while calling `/api/*`.
  Fix: this happened because backend was unhealthy and ALB returned HTML. Once backend + DB were healthy, `/api` returned valid JSON.

## Verify
- App: `https://<app_subdomain>.<zone_name>`
- Backend health: `https://<app_subdomain>.<zone_name>/api/health`
- Backend DB check: `https://<app_subdomain>.<zone_name>/api/visits`

## Destroy everything
```bash
terraform destroy -auto-approve
```
