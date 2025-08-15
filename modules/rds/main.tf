resource "aws_security_group" "rds_sg" {
  vpc_id = var.vpc_id
  name   = "${var.project_name}-rds-sg"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  # RDS instances typically don't need outbound connections
  # Remove overly permissive egress rule - RDS should only respond to connections
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "rds" {
  identifier                     = "${var.project_name}-rds"
  allocated_storage              = 20
  engine                         = "postgres"
  engine_version                 = "16.9"
  instance_class                 = "db.t3.micro"
  username                       = var.db_username
  manage_master_user_password    = true
  master_user_secret_kms_key_id  = var.kms_key_id
  db_subnet_group_name           = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids         = [aws_security_group.rds_sg.id]
  skip_final_snapshot            = true
  publicly_accessible            = false
}