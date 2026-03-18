variable "identifier" {
  type        = string
  description = "RDS instance identifier"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where RDS will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for DB subnet group"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to connect to RDS"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "16.13"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Initial storage in GiB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum autoscaled storage in GiB"
  default     = 100
}

variable "storage_type" {
  type        = string
  description = "Storage type"
  default     = "gp3"
}

variable "port" {
  type        = number
  description = "Database port"
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Default database name"
}

variable "username" {
  type        = string
  description = "Master username"
}

variable "password" {
  type        = string
  description = "Master password"
  sensitive   = true
}

variable "publicly_accessible" {
  type        = bool
  description = "Whether DB is publicly reachable"
  default     = false
}

variable "multi_az" {
  type        = bool
  description = "Enable multi-AZ"
  default     = false
}

variable "backup_retention_period" {
  type        = number
  description = "Automated backup retention in days"
  default     = 7
}

variable "deletion_protection" {
  type        = bool
  description = "Prevent accidental DB deletion"
  default     = false
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when destroying DB"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
