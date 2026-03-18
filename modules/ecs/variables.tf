variable "cluster_name" {
  type        = string
  description = "Name for the ECS cluster"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "The VPC where ECS tasks will live"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnets for ECS tasks"
}

variable "log_retention_in_days" {
  type        = number
  description = "CloudWatch Logs retention for all containers"
  default     = 7
}

variable "task_cpu" {
  type        = number
  description = "CPU units for each task"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Memory (MiB) for each task"
  default     = 512
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
  description = "List of containers to deploy: name, image, port and desired count"
}

variable "sg_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "List of ingress rules for the ECS tasks security group"
  default     = []
}

variable "target_group_arns" {
  type        = map(string)
  description = "Map of container name → ALB target group ARN"
}


variable "tags" {
  type        = map(string)
  description = "Tags to apply to all ECS resources"
  default     = {}
}

