# Secure RDS Deployment with Terraform

## Overview

This project deploys a secure Amazon RDS (PostgreSQL) instance using Terraform with a Bastion host for secure access, following AWS best practices. The infrastructure includes a VPC with public and private subnets, security groups, and proper network isolation.

## Architecture

![AWS Infrastructure Architecture](./images/architecture-diagram.png)

*Figure: AWS RDS Infrastructure with Bastion Host Architecture*

### Components

- **VPC**: Custom VPC with DNS support and hostnames
- **Public Subnet**: Hosts the Bastion instance with internet access
- **Private Subnets**: Host the RDS instance (multi-AZ for high availability)
- **Bastion Host**: EC2 instance for secure SSH access to private resources
- **RDS Instance**: PostgreSQL database in private subnet
- **Security Groups**: Restrictive access controls
- **NAT Gateway**: Provides internet access for private subnet resources

## Security Practices

### Network Security
- **Private RDS**: Database is not publicly accessible
- **Bastion Host**: Only entry point to private resources
- **Security Groups**: 
  - Bastion: SSH (port 22) access only from specified IP
  - RDS: PostgreSQL (port 5432) access only from Bastion security group
- **Network Isolation**: Clear separation between public and private subnets

### Access Control
- **IP Restriction**: SSH access limited to your specific IP address
- **Key-based Authentication**: EC2 instance uses SSH key pairs
- **Database Access**: Only accessible through Bastion host tunnel

### Data Protection
- **Encryption**: Terraform state stored encrypted in S3
- **No Hardcoded Secrets**: Sensitive values managed through variables
- **Skip Snapshot**: Configured for development (adjust for production)

### Traffic Flow

In this project, the VPC acts as a private network container that holds all resources, including subnets, gateways, security controls, and compute instances. The public subnet is designed to host the Bastion host, which is the only instance directly accessible from the internet. This subnet has a route table that sends any traffic destined for the internet through the Internet Gateway (IGW), allowing secure communication from external networks to the Bastion. Security groups and network ACLs provide multiple layers of protection; the Bastion’s security group permits SSH access only from your specific IP address while allowing all outbound traffic, and the public NACL allows SSH and ephemeral ports inbound, while permitting all outbound connections.

The private subnets, spread across two availability zones, host the RDS PostgreSQL database. These subnets do not have direct access to the internet. Instead, if any instance inside the private subnet needs to initiate outbound internet connections, the traffic is routed through a NAT Gateway located in the public subnet. The NAT Gateway forwards this traffic to the Internet Gateway while blocking inbound traffic from the internet, ensuring that the RDS database remains isolated from external access. The private route table contains a local route for internal VPC traffic and a default route pointing to the NAT Gateway, so the private instances can communicate internally and reach the internet safely for updates or patches. Security groups on the RDS database are configured to allow PostgreSQL traffic only from the Bastion host, while NACLs further restrict inbound traffic to only allow SSH and PostgreSQL from the public subnet and ephemeral ports for responses, ensuring strict control of network traffic.

All internal VPC traffic, such as Bastion connecting to RDS, uses the local route in the private subnet route table. This ensures that traffic never leaves the VPC for communication between these resources. Multi-AZ deployment of RDS allows the database to replicate across private subnets for high availability, and all replication traffic remains internal to the VPC, never touching the NAT Gateway or IGW. This setup guarantees that private resources are protected, while the Bastion host acts as a controlled access point, balancing both security and functionality.

The entire flow can be visualized as follows:

[Your Laptop/PC]
      |
      | SSH 22
      v
[Internet Gateway (IGW)]
      |
      v
[Public Subnet Route Table] → [Bastion Host (10.0.1.x)]
      |
      | TCP 5432 (PostgreSQL)
      v
[Private Subnet Route Table] → [RDS Database (10.0.2.x / 10.0.3.x)]
      |
      | (Optional outbound)
      v
[NAT Gateway in Public Subnet] → [Internet via IGW]


In summary, the project architecture ensures that the Bastion host serves as the only entry point from the internet, while the RDS database remains in isolated private subnets with controlled access. Route tables, security groups, NACLs, and gateways work together to direct traffic appropriately, enforce security, and maintain the ability for private instances to communicate both internally and with the internet when necessary, achieving a balance of accessibility, isolation, and high availability.


## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** installed (version >= 1.0)
3. **SSH Key Pair** created in AWS EC2 console
4. **S3 Bucket** for Terraform state storage with versioning enabled

## Deployment Instructions

### 1. Clone and Navigate
```bash
git clone <repository-url>
cd IaC-Project
```

### 2. Configure Variables
Edit `terraform.tfvars` with your specific values:
```hcl
aws_region            = "us-east-1"
project_name          = "your-project-name"
allowed_ssh_ip        = "YOUR.IP.ADDRESS.HERE/32"  # Your public IP
bastion_ami           = "ami-0e2c86481225d3c51"    # Amazon Linux 2
bastion_instance_type = "t3.micro"
key_name              = "your-key-pair-name"       # Your EC2 key pair
db_username           = "admin"
db_password           = "your-secure-password"
s3_bucket_name        = "your-terraform-state-bucket"
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Plan Deployment
```bash
terraform plan
```

### 5. Deploy Infrastructure
```bash
terraform apply
```
Type `yes` when prompted to confirm the deployment.

### 6. Get Outputs
```bash
terraform output
```

## Accessing the Database

### 1. Connect to Bastion Host
```bash
ssh -i /path/to/your-key.pem ec2-user@<bastion-public-ip>
```

### 2. Install PostgreSQL Client (on Bastion)
```bash
sudo dnf install -y postgresql15-server postgresql15
```

### 3. Connect to RDS
```bash
psql -h <rds-endpoint> -U <username> -d postgres
```

### Alternative: SSH Tunnel
Create an SSH tunnel from your local machine:
```bash
ssh -i /path/to/your-key.pem -L 5432:<rds-endpoint>:5432 ec2-user@<bastion-public-ip>
```

Then connect locally:
```bash
psql -h localhost -U <username> -d postgres
```

## File Structure

```
IaC-Project/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── terraform.tfvars        # Variable values (configure this)
├── outputs.tf              # Output definitions
├── modules/
│   ├── vpc/
│   │   ├── main.tf         # VPC, subnets, routing
│   │   ├── variables.tf    # VPC variables
│   │   └── outputs.tf      # VPC outputs
│   ├── bastion/
│   │   ├── main.tf         # Bastion host and security group
│   │   ├── variables.tf    # Bastion variables
│   │   └── outputs.tf      # Bastion outputs
│   └── rds/
│       ├── main.tf         # RDS instance and security group
│       ├── variables.tf    # RDS variables
│       └── outputs.tf      # RDS outputs
└── README.md               # This file
```

## Cost Optimization

- **Instance Types**: Using t3.micro for Bastion and db.t3.micro for RDS (free tier eligible)
- **Storage**: Minimal allocated storage (20GB)
- **No Multi-AZ**: Single AZ deployment for cost savings (adjust for production)

## Cleanup

To destroy all infrastructure:
```bash
terraform destroy
```

Type `yes` when prompted to confirm the destruction.

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify security group allows your IP
   - Check key pair name is correct
   - Ensure instance is in running state

2. **Database Connection Failed**
   - Verify RDS instance is available
   - Check security group allows connection from Bastion
   - Confirm endpoint address is correct

3. **Terraform State Issues**
   - Ensure S3 bucket exists and is accessible
   - Verify AWS credentials have S3 permissions

### Validation Commands

```bash
# Check infrastructure status
terraform show

# Validate configuration
terraform validate

# Check outputs
terraform output

# AWS CLI verification
aws ec2 describe-instances --filters "Name=tag:Name,Values=*bastion*"
aws rds describe-db-instances --db-instance-identifier <project-name>-rds
```

## Production Considerations

For production deployments, consider:

- Enable RDS Multi-AZ deployment
- Configure automated backups
- Use AWS Secrets Manager for database credentials
- Implement monitoring and alerting
- Add additional security layers (WAF, CloudTrail)
- Use private subnets for Bastion host with VPN/Direct Connect

## Support

For issues or questions, please refer to the AWS documentation or Terraform documentation.
