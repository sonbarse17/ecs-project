variable "zone_name" {
  type        = string
  description = "The base DNS name (e.g. example.com) for the hosted zone"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the Route53 hosted zone"
}

variable "record_name" {
  type        = string
  description = "The subdomain (e.g. \"app\") for the alias record"
}

variable "alb_dns_name" {
  type        = string
  description = "The DNS name of the ALB (for alias)"
}

variable "alb_zone_id" {
  type        = string
  description = "The hosted zone ID of the ALB (for alias)"
}
