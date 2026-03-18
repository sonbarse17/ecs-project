output "zone_id" {
  value       = aws_route53_zone.this.id
  description = "The Route53 Hosted Zone ID"
}

output "name_servers" {
  value       = aws_route53_zone.this.name_servers
  description = "The NS records assigned by AWS"
}
