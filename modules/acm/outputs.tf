output "certificate_arn" {
  description = "The ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "certificate_id" {
  description = "The ID of the ACM certificate"
  value       = aws_acm_certificate.this.id
}
