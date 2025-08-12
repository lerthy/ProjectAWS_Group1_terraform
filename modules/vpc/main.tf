resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.project_name}-private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "${var.project_name}-private-subnet-b"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "${var.project_name}-nat"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_assoc_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Network ACLs for additional security
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main.id

  # Allow inbound SSH from allowed IP
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow inbound HTTP/HTTPS for updates
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow ephemeral ports for responses
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = {
    Name = "${var.project_name}-public-nacl"
  }
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main.id

  # Allow inbound SSH from public subnet
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "10.0.1.0/24"
    action     = "allow"
  }

  # Allow inbound PostgreSQL from public subnet
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 5432
    to_port    = 5432
    cidr_block = "10.0.1.0/24"
    action     = "allow"
  }

  # Allow ephemeral ports for responses
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow all outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  tags = {
    Name = "${var.project_name}-private-nacl"
  }
}

# Associate NACLs with subnets
resource "aws_network_acl_association" "public_nacl_assoc" {
  network_acl_id = aws_network_acl.public_nacl.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_network_acl_association" "private_nacl_assoc" {
  network_acl_id = aws_network_acl.private_nacl.id
  subnet_id      = aws_subnet.private.id
}

resource "aws_network_acl_association" "private_nacl_assoc_b" {
  network_acl_id = aws_network_acl.private_nacl.id
  subnet_id      = aws_subnet.private_b.id
}