provider "aws" {
  region = var.aws_region
}

locals {
  rds_subnet_ids = length(module.vpc.data_subnet_ids) > 0 ? module.vpc.data_subnet_ids : module.vpc.app_subnet_ids

  backend_rds_environment = [
    { name = "DB_HOST", value = module.rds.address },
    { name = "DB_PORT", value = tostring(module.rds.port) },
    { name = "DB_NAME", value = var.rds_db_name },
    { name = "DB_USER", value = var.rds_username },
    { name = "DB_PASSWORD", value = var.rds_password },
    { name = "DB_SSL", value = "true" },
    { name = "AWS_REGION", value = var.aws_region }
  ]

  containers_with_rds_env = [
    for c in var.containers : c.name == var.backend_container_name
    ? merge(c, { environment = concat(c.environment, local.backend_rds_environment) })
    : c
  ]
}

module "vpc" {
  source     = "./modules/vpc"
  name       = var.name
  cidr_block = var.vpc_cidr
  azs        = var.azs

  enable_public_subnet = var.enable_public_subnet
  public_subnet_cidrs  = var.public_subnet_cidrs

  enable_app_subnet = var.enable_app_subnet
  app_subnet_cidrs  = var.app_subnet_cidrs

  enable_data_subnet = var.enable_data_subnet
  data_subnet_cidrs  = var.data_subnet_cidrs

  tags = var.tags
}

module "rds" {
  source = "./modules/rds"

  identifier              = var.rds_identifier
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = local.rds_subnet_ids
  allowed_cidr_blocks     = var.app_subnet_cidrs
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = var.rds_max_allocated_storage
  storage_type            = var.rds_storage_type
  port                    = var.rds_port
  db_name                 = var.rds_db_name
  username                = var.rds_username
  password                = var.rds_password
  publicly_accessible     = var.rds_publicly_accessible
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.rds_skip_final_snapshot
  tags                    = var.tags
}

module "ecs" {
  source                = "./modules/ecs"
  cluster_name          = var.cluster_name
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.app_subnet_ids
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  log_retention_in_days = var.log_retention_in_days
  tags                  = var.tags
  target_group_arns     = module.alb.target_group_arns

  containers       = local.containers_with_rds_env
  sg_ingress_rules = var.sg_ingress_rules
}

# Route53
module "route53" {
  source    = "./modules/route53"
  zone_name = var.zone_name
  tags      = var.tags

  # new inputs for the alias record
  record_name  = var.app_subdomain # e.g. "app"
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

#ACM
module "acm" {
  source                    = "./modules/acm"
  domain_name               = "${var.app_subdomain}.${var.zone_name}"
  subject_alternative_names = [] # add SANs here if needed
  validation_method         = "DNS"
  zone_id                   = module.route53.zone_id
  tags                      = var.tags
}

# ALB
module "alb" {
  source              = "./modules/alb"
  name                = var.alb_name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  ingress_rules       = var.alb_ingress_rules
  target_groups       = var.target_groups
  default_target_name = var.default_target_name
  certificate_arn     = module.acm.certificate_arn
  tags                = var.tags
}
