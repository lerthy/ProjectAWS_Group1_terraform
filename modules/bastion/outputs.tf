output "security_group_id" {
  description = "Bastion security group id"
  value       = aws_security_group.bastion_sg.id
}

output "instance_id" {
  description = "Bastion instance id"
  value       = aws_instance.bastion.id
}

output "instance_public_ip" {
  description = "Bastion public IP"
  value       = aws_instance.bastion.public_ip
}
