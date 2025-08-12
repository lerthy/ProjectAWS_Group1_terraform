variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "allowed_ssh_ip" {
  type = string
}

variable "bastion_ami" {
  type = string
}

variable "bastion_instance_type" {
  type = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "s3_bucket_name" {
  type = string
}



