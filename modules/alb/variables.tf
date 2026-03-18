variable "name" {
  type        = string
  description = "Prefix for all ALB resources (e.g. \"my-alb\")"
}

variable "vpc_id" {
  type        = string
  description = "VPC in which to create the ALB"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB"
}

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "Security‐group ingress rules for the ALB"
  default     = []
}

variable "target_groups" {
  type = list(object({
    name              = string # used as key and in resource names
    port              = number # container port to forward to
    path_pattern      = string # e.g. \"/api/*\" or \"/\"
    health_check_path = string # e.g. \"/api/health\"
    priority          = number # integer > 1; controls rule evaluation order
  }))
  description = "Definitions of each path‐based target group"
}

variable "default_target_name" {
  type        = string
  description = "Which target_group.name to use for the listener’s default_action"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS listener"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all ALB resources"
}
