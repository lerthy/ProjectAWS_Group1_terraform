terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

 backend "s3" {
      bucket         = "myterraformstate112"
      key            = "terraform/state.tfstate"
      region         = "us-east-1"
      encrypt        = true
      dynamodb_table = "terraform-state-locks"
   }
}

provider "aws" {
  region = "us-east-1"
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-state-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  aws_region   = "us-east-1"
}

module "bastion" {
  source           = "./modules/bastion"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  allowed_ssh_ip   = var.allowed_ssh_ip
  ami_id           = var.bastion_ami
  instance_type    = var.bastion_instance_type
  key_name         = var.key_name
}

module "rds" {
  source           = "./modules/rds"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  bastion_sg_id    = module.bastion.security_group_id
  db_username      = "dbadmin"
}
