# Sample Frontend + Backend App

This folder contains a minimal two-container app:
- `frontend`: static UI served by nginx, calls backend at `/api/*`
- `backend`: Node.js API, reads/writes from PostgreSQL on RDS

## Backend APIs
- `GET /api/health`
- `GET /api/visits`
- `GET /api/config`

## Build and push images (example)

```bash
AWS_ACCOUNT_ID=<your-account-id>
AWS_REGION=ap-south-1

aws ecr create-repository --repository-name personal-portfolio-frontend || true
aws ecr create-repository --repository-name personal-portfolio-backend || true

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

docker build -t personal-portfolio-frontend:latest sample-app/frontend
docker tag personal-portfolio-frontend:latest "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/personal-portfolio-frontend:latest"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/personal-portfolio-frontend:latest"

docker build -t personal-portfolio-backend:latest sample-app/backend
docker tag personal-portfolio-backend:latest "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/personal-portfolio-backend:latest"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/personal-portfolio-backend:latest"
```

After push, set the two image URIs in `terraform.tfvars` and run `terraform apply`.
