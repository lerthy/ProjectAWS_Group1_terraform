output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = module.bastion.instance_public_ip
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_endpoint
}
