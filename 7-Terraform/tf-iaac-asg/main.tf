# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "example-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}

# Create a Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "example-public-route-table"
  }
}

# Create Public Subnets
resource "aws_subnet" "example_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = var.subnet_cidrs[0]
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "example-subnet-1"
  }
}

resource "aws_subnet" "example_2" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = var.subnet_cidrs[1]
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "example-subnet-2"
  }
}

# Associate Subnets with Public Route Table
resource "aws_route_table_association" "example_1" {
  subnet_id      = aws_subnet.example_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "example_2" {
  subnet_id      = aws_subnet.example_2.id
  route_table_id = aws_route_table.public.id
}

# Create Security Group
resource "aws_security_group" "example" {
  vpc_id = aws_vpc.example.id
  name   = "example-sg"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "example-sg"
  }
}

# Create a Launch Template
resource "aws_launch_template" "example" {
  name_prefix   = "example-lt"
  image_id      = data.aws_ami.latest_amazon_linux.id # Automatically fetches latest Amazon Linux 2 AMI
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.example.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Terraform-ASG-Instance"
    }
  }
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = [aws_subnet.example_1.id, aws_subnet.example_2.id]
  desired_capacity    = 2
  min_size            = 1
  max_size            = 3
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

# Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}
