output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.rds.endpoint
}

output "rds_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.rds.id
}
