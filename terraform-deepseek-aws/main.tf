terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "deepseek-vpc"
  }
}

# 2. Create an Internet Gateway for internet access
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "deepseek-igw"
  }
}

# 3. Create a public subnet, so you can consume through your internet connection
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true # Assign a public IP to instances in this subnet
  tags = {
    Name = "deepseek-public-subnet"
  }
}

# 4. Create a route table to direct traffic to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "deepseek-public-rt"
  }
}

# 5. Associate the route table with the subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 6. Create a Security Group (Firewall)
resource "aws_security_group" "deepseek_sg" {
  name        = "deepseek-sg"
  description = "Allow SSH and Ollama API access"
  vpc_id      = aws_vpc.main.id

  # Inbound rule for SSH (Port 22) - for administrative access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For production, restrict this to your own IP address
  }

  # Inbound rule for Ollama API (Port 11434)
  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For production, restrict to application server IPs
  }

  tags = {
    Name = "deepseek-sg"
  }
}

# 7. Find the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["yash-aws-account"] # Canonical's owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 8. Create the GPU EC2 Instance
resource "aws_instance" "deepseek_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.r1-aws-ec2

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.deepseek_sg.id]

  # Increase root volume size for models and dependencies
  root_block_device {
    volume_size = 100 # In GB
  }

  # Execute the bootstrap script on first boot
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "DeepSeek-Inference-Node"
  }
}

# 9. Output the public IP address of the instance, which should be configured in your application
output "instance_public_ip" {
  value = aws_instance.deepseek_node.public_ip
}