output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = module.bastion.instance_public_ip
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_master_user_secret_arn" {
  description = "ARN of the RDS master user secret in AWS Secrets Manager"
  value       = module.rds.rds_master_user_secret_arn
}

output "rds_master_user_secret_status" {
  description = "Status of the RDS master user secret"
  value       = module.rds.rds_master_user_secret_status
}