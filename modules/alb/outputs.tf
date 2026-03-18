output "alb_arn" {
  value       = aws_lb.this.arn
  description = "The ALB ARN"
}

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "The ALB DNS name"
}

output "target_group_arns" {
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
  description = "Map of name → target-group ARN"
}

output "listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "Listener ARN"
}

output "listener_rule_arns" {
  value       = { for k, lr in aws_lb_listener_rule.this : k => lr.arn }
  description = "Map of name → listener-rule ARN"
}

output "alb_zone_id" {
  description = "The hosted-zone ID for the ALB (needed for Route53 alias records)"
  value       = aws_lb.this.zone_id
}
