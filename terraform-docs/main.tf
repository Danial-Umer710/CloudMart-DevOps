# 1. TERRAFORM SETTINGS & PROVIDER
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1" # Stockholm
}

# 2. DYNAMIC AMI SEARCH
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# 3. NETWORK (VPC)
resource "aws_vpc" "cloudmart_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "cloudmart-vpc" }
}

# 4. INTERNET GATEWAY
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.cloudmart_vpc.id
  tags   = { Name = "cloudmart-igw" }
}

# 5. SUBNETS
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.cloudmart_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"
  tags                    = { Name = "cloudmart-public-subnet" }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.cloudmart_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1a"
  tags                    = { Name = "cloudmart-private-subnet" }
}
# NEW: Third subnet in a different AZ for RDS requirements
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.cloudmart_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1b" # Note the 'b' here!
  tags              = { Name = "cloudmart-private-subnet-2" }
}
# 6. ROUTING
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloudmart_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = { Name = "cloudmart-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. SECURITY GROUP
resource "aws_security_group" "web_sg" {
  name   = "cloudmart-web-sg"
  vpc_id = aws_vpc.cloudmart_vpc.id

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
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
  from_port   = 3000
  to_port     = 3000
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

# 8. IAM ROLE FOR ECR ACCESS
resource "aws_iam_role" "ec2_ecr_role" {
  name = "cloudmart-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_ecr_profile" {
  name = "cloudmart-ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# 9. EC2 INSTANCE
resource "aws_instance" "cloudmart_web" {
  ami                    = data.aws_ami.ubuntu_latest.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name= "cloudmart-final-key"
  iam_instance_profile   = aws_iam_instance_profile.ec2_ecr_profile.name
  tags                   = { Name = "cloudmart-web-server" }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              EOF
}

# 10. ECR REPOSITORIES
resource "aws_ecr_repository" "order_service" {
  name                 = "cloudmart-order-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "product_service" {
  name                 = "cloudmart-product-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
resource "aws_ecr_repository" "cloudmart_frontend" {
  name                 = "cloudmart-frontend"
  image_tag_mutability = "MUTABLE"
}
