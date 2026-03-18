# ECS Portfolio Infrastructure

Terraform project to deploy a two-container application on AWS ECS Fargate with:
- VPC (public/app/data subnets)
- ALB (path-based routing)
- Route53 + ACM
- RDS PostgreSQL

The sample app is:
- `frontend` (static page)
- `backend` (Node.js API)
- backend connects to RDS PostgreSQL

## Architecture
- `/` -> frontend target group
- `/api/*` -> backend target group
- backend uses env vars injected by Terraform for DB connection

## Repository Structure
- `main.tf`, `variables.tf`, `outputs.tf`: root wiring
- `modules/`: reusable Terraform modules (`vpc`, `alb`, `ecs`, `route53`, `acm`, `rds`)
- `sample-app/frontend`: frontend source + Dockerfile
- `sample-app/backend`: backend source + Dockerfile

## Prerequisites
- Terraform `>= 1.5`
- AWS CLI configured with valid credentials
- Docker installed and logged into Docker Hub

## Configure
1. Edit `terraform.tfvars`:
- networking CIDRs/AZs
- `zone_name`, `app_subdomain`
- RDS values (`rds_*`)
- container image URIs (`sonbarse17/...` or your own)

2. Keep secrets out of Git:
- `terraform.tfvars` is ignored via `.gitignore`

## Build and Push Images
Use the sample app folders:

```bash
docker build -t <dockerhub-user>/personal-portfolio-frontend:latest sample-app/frontend
docker push <dockerhub-user>/personal-portfolio-frontend:latest

docker build -t <dockerhub-user>/personal-portfolio-backend:latest sample-app/backend
docker push <dockerhub-user>/personal-portfolio-backend:latest
```

Update `containers[].image` values in `terraform.tfvars` with your image names.

## Deploy
```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

## Verify
- App URL: `https://<app_subdomain>.<zone_name>`
- Backend health: `https://<app_subdomain>.<zone_name>/api/health`
- Backend DB check: `https://<app_subdomain>.<zone_name>/api/visits`

## Destroy
```bash
terraform destroy -auto-approve
```

## Notes
- DNS nameserver propagation can delay ACM validation.
- If backend fails to connect to RDS due to encryption policy, ensure DB SSL is enabled in backend env (`DB_SSL=true`).
