resource "aws_route53_zone" "this" {
  name = var.zone_name
  tags = var.tags
}

resource "aws_route53_record" "alias" {
  zone_id = aws_route53_zone.this.id
  name    = var.record_name # e.g. "app" → app.example.com
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
