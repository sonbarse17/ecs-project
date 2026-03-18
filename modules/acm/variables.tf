variable "domain_name" {
  type        = string
  description = "Primary domain (e.g. app.example.com) for the SSL certificate"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "Additional domain names (SANs)"
  default     = []
}

variable "validation_method" {
  type        = string
  description = "Method to validate the certificate (DNS only)"
  default     = "DNS"
}

variable "zone_id" {
  type        = string
  description = "Route53 Hosted Zone ID for DNS validation"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the ACM resources"
  default     = {}
}
