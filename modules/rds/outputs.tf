output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.rds.endpoint
}

output "rds_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.rds.id
}

output "rds_master_user_secret_arn" {
  description = "ARN of the master user secret in AWS Secrets Manager"
  value       = aws_db_instance.rds.master_user_secret[0].secret_arn
}

output "rds_master_user_secret_status" {
  description = "Status of the master user secret"
  value       = aws_db_instance.rds.master_user_secret[0].secret_status
}
