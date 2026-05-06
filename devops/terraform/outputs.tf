output "ec2_public_ip" {
  description = "Public IP of the EC2 instance (Elastic IP)"
  value       = aws_eip.scheduler_eip.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.scheduler_ec2.id
}

output "ssh_command" {
  description = "SSH command to access the EC2 instance"
  value       = "ssh -i ${var.private_key_path} ${var.ssh_user}@${aws_eip.scheduler_eip.public_ip}"
}

output "jenkins_url" {
  description = "Jenkins URL (once Ansible installs and starts it)"
  value       = "http://${aws_eip.scheduler_eip.public_ip}:8080"
}

output "sonarqube_url" {
  description = "SonarQube URL (once Ansible installs and starts it)"
  value       = "http://${aws_eip.scheduler_eip.public_ip}:9000"
}

output "app_url" {
  description = "App URL (once minikube tunnel is running)"
  value       = "http://${aws_eip.scheduler_eip.public_ip}"
}
