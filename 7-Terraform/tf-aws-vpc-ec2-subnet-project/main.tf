provider "aws" {
  region = "us-east-2"
}

# Create a VPC
resource "aws_vpc" "secure_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "SecureVPC"
  }
}

# Create Public Subnets
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.secure_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.secure_vpc.cidr_block, 8, count.index + 1)
  availability_zone       = "us-east-2a" ### (data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet-${count.index + 1}"
  }
}

# Create Private Subnets
resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.secure_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.secure_vpc.cidr_block, 8, count.index + 3)
  availability_zone = "us-east-2b" ###(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "PrivateSubnet-${count.index + 1}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.secure_vpc.id
  tags = {
    Name = "SecureVPC-IGW"
  }
}

# Create Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.secure_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    Name = "SecureVPC-NAT"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Create Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.secure_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "PrivateRouteTable"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Create Security Groups
resource "aws_security_group" "public_sg" {
  name        = "PublicSecurityGroup"
  description = "Allow SSH, HTTP, and HTTPS"
  vpc_id      = aws_vpc.secure_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  name        = "PrivateSecurityGroup"
  description = "Allow SSH from Public Subnet"
  vpc_id      = aws_vpc.secure_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.public_subnet[0].cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch EC2 Instances
resource "aws_instance" "public_instance" {
  ami             = "ami-018875e7376831abe" # Replace with your desired AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet[0].id
  security_groups = [aws_security_group.public_sg.id]
  key_name        = aws_key_pair.ssh_key.key_name
  tags = {
    Name = "PublicInstance"
  }
}

resource "aws_instance" "private_instance" {
  ami             = "ami-018875e7376831abe" # Replace with your desired AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnet[0].id
  security_groups = [aws_security_group.private_sg.id]
  key_name        = aws_key_pair.ssh_key.key_name
  tags = {
    Name = "PrivateInstance"
  }
}

# Generate SSH Key Pair
resource "aws_key_pair" "ssh_key" {
  key_name   = "secure-key"
  public_key = file("~/.ssh/id_ed25519.pub") # Replace with your public key path
}

# Outputs
output "public_instance_ip" {
  value = aws_instance.public_instance.public_ip
}

output "private_instance_ip" {
  value = aws_instance.private_instance.private_ip
}