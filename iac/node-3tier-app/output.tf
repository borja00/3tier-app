output "domain" {
  value = aws_lb.alb.0.dns_name
}

output "cdn_domain" {
  value = aws_cloudfront_distribution.content.0.domain_name
}

output "grafana_admin_password" {
  value     = random_password.grafana_admin_password.result
  sensitive = true
}
