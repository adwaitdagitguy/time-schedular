variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID (region-specific)"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2023 - us-east-1
}

variable "instance_type" {
  description = "EC2 instance type. t3.large (2 vCPU, 8GB) required for Minikube + Jenkins + SonarQube."
  type        = string
  default     = "t3.large"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to create"
  type        = string
  default     = "scheduler-key"
}

variable "public_key_path" {
  description = "Path to your LOCAL SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to your LOCAL SSH private key file (used for Ansible inventory)"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_user" {
  description = "SSH user for the EC2 instance"
  type        = string
  default     = "ec2-user"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance. Default: 0.0.0.0/0 (open). Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}
