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

# ── Security Group ─────────────────────────────────────────────────────────────
resource "aws_security_group" "scheduler_sg" {
  name        = "scheduler-ec2-sg"
  description = "Allow SSH, HTTP, HTTPS and Jenkins traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP - App via minikube tunnel"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "SonarQube Web UI"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "scheduler-ec2-sg"
    Project = "time-scheduler"
  }
}

# ── Key Pair ───────────────────────────────────────────────────────────────────
resource "aws_key_pair" "scheduler_key" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

# ── EC2 Instance ───────────────────────────────────────────────────────────────
resource "aws_instance" "scheduler_ec2" {
  ami                    = var.ami_id          # Amazon Linux 2023 (us-east-1)
  instance_type          = var.instance_type   # t3.medium minimum for Minikube
  key_name               = aws_key_pair.scheduler_key.key_name
  vpc_security_group_ids = [aws_security_group.scheduler_sg.id]

  # 30 GB is a safe baseline for Docker images + Minikube
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name    = "time-scheduler-ec2"
    Project = "time-scheduler"
  }
}

# ── Elastic IP (stable public IP across reboots) ───────────────────────────────
resource "aws_eip" "scheduler_eip" {
  instance = aws_instance.scheduler_ec2.id
  domain   = "vpc"

  tags = {
    Name    = "scheduler-eip"
    Project = "time-scheduler"
  }
}

# ── Ansible Inventory (auto-generated after EC2 is created) ───────────────────
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    ec2_public_ip = aws_eip.scheduler_eip.public_ip
    ssh_user      = var.ssh_user
    key_path      = var.private_key_path
  })
  filename = "${path.module}/../ansible/inventory.ini"
}
