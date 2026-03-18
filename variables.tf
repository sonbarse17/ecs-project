variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "my-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "enable_public_subnet" {
  type    = bool
  default = true
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "enable_app_subnet" {
  type    = bool
  default = true
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "enable_data_subnet" {
  type    = bool
  default = false
}

variable "data_subnet_cidrs" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = { Environment = "dev" }
}

variable "cluster_name" {
  type = string
}

variable "task_cpu" {
  type = number
}
variable "task_memory" {
  type = number
}

variable "log_retention_in_days" {
  type = number
}

variable "containers" {
  type = list(object({
    name          = string
    image         = string
    port          = number
    desired_count = number
    environment = list(object({
      name  = string
      value = string
    }))
  }))
}

variable "sg_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "List of ingress rules (ports and CIDRs) for the ECS security group"
  default     = []
}

variable "alb_name" {
  type        = string
  description = "Prefix for the ALB"
}

variable "alb_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "Security‐group rules for the ALB"
  default     = []
}

variable "target_groups" {
  type = list(object({
    name              = string
    port              = number
    path_pattern      = string
    health_check_path = string
    priority          = number
  }))
  description = "Path-based routing definitions for ALB"
}

variable "default_target_name" {
  type        = string
  description = "Which target_group.name to use as the default listener action"
}

variable "backend_container_name" {
  type        = string
  description = "Name of backend container to receive DB environment variables"
  default     = "backend"
}

variable "rds_identifier" {
  type        = string
  description = "RDS instance identifier"
}

variable "rds_engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "16.13"
}

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  type        = number
  description = "Initial RDS storage in GiB"
  default     = 20
}

variable "rds_max_allocated_storage" {
  type        = number
  description = "Maximum autoscaled storage in GiB"
  default     = 100
}

variable "rds_storage_type" {
  type        = string
  description = "RDS storage type"
  default     = "gp3"
}

variable "rds_port" {
  type        = number
  description = "RDS PostgreSQL port"
  default     = 5432
}

variable "rds_db_name" {
  type        = string
  description = "Default PostgreSQL database name"
}

variable "rds_username" {
  type        = string
  description = "Master username for RDS"
}

variable "rds_password" {
  type        = string
  description = "Master password for RDS"
  sensitive   = true
}

variable "rds_publicly_accessible" {
  type        = bool
  description = "Whether RDS is publicly accessible"
  default     = false
}

variable "rds_multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment"
  default     = false
}

variable "rds_backup_retention_period" {
  type        = number
  description = "Number of days to keep automated backups"
  default     = 7
}

variable "rds_deletion_protection" {
  type        = bool
  description = "Protect RDS from accidental deletion"
  default     = false
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on destroy"
  default     = true
}

variable "app_subdomain" {
  type        = string
  description = "Subdomain for the ALB record"
  default     = "app"
}

variable "zone_name" {
  type        = string
  description = "The base domain name (e.g. \"example.com\")"
}
