variable "project_name" {
  type        = string
  description = "The project name used for resource naming"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where RDS will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the RDS subnet group"
}

variable "bastion_sg_id" {
  type        = string
  description = "Security group ID of the bastion host allowed to access RDS"
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS PostgreSQL instance"
}

variable "db_password" {
  type        = string
  description = "Master password for the RDS PostgreSQL instance"
  sensitive   = true
}
