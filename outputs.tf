output "alb_dns_endpoint" {
  description = "Access the application via this URL"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "db_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.mysql.endpoint
}