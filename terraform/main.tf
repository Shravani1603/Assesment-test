provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────────
# TLS Private Key (RSA 4096-bit)
# ──────────────────────────────────────────────
resource "tls_private_key" "directus_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ──────────────────────────────────────────────
# AWS Key Pair (register public key)
# ──────────────────────────────────────────────
resource "aws_key_pair" "directus_keypair" {
  key_name   = "${var.project_name}-keypair"
  public_key = tls_private_key.directus_key.public_key_openssh

  tags = {
    Name        = "${var.project_name}-keypair"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────
resource "aws_vpc" "directus_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────────
# Internet Gateway
# ──────────────────────────────────────────────
resource "aws_internet_gateway" "directus_igw" {
  vpc_id = aws_vpc.directus_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────────
# Public Subnet
# ──────────────────────────────────────────────
resource "aws_subnet" "directus_public_subnet" {
  vpc_id                  = aws_vpc.directus_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────────
# Route Table (public — routes to IGW)
# ──────────────────────────────────────────────
resource "aws_route_table" "directus_public_rt" {
  vpc_id = aws_vpc.directus_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.directus_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────────
# Route Table Association
# ──────────────────────────────────────────────
resource "aws_route_table_association" "directus_public_rta" {
  subnet_id      = aws_subnet.directus_public_subnet.id
  route_table_id = aws_route_table.directus_public_rt.id
}

# ──────────────────────────────────────────────
# Security Group
# ──────────────────────────────────────────────
resource "aws_security_group" "directus_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Directus server"
  vpc_id      = aws_vpc.directus_vpc.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Directus access
  ingress {
    description = "Directus"
    from_port   = 8055
    to_port     = 8055
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────────
# EC2 Instance (using custom AMI)
# ──────────────────────────────────────────────
resource "aws_instance" "directus" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.directus_keypair.key_name
  vpc_security_group_ids      = [aws_security_group.directus_sg.id]
  subnet_id                   = aws_subnet.directus_public_subnet.id
  associate_public_ip_address = true

  # Install Docker and Docker Compose at boot
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system packages
    apt-get update -y

    # Install prerequisites
    apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      apt-transport-https \
      software-properties-common

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Add ubuntu user to docker group
    usermod -aG docker ubuntu

    # Install Docker Compose standalone (v2)
    curl -SL "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Create working directory for Directus
    mkdir -p /home/ubuntu/directus
    chown ubuntu:ubuntu /home/ubuntu/directus

    echo "Docker setup complete at $(date)" > /tmp/docker-setup-complete.txt
  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────────
# Elastic IP Association (Conditional)
# ──────────────────────────────────────────────
resource "aws_eip_association" "directus_eip_assoc" {
  count       = var.elastic_ip != "" ? 1 : 0
  instance_id = aws_instance.directus.id
  public_ip   = var.elastic_ip
}
