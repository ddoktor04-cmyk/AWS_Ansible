# ============================================================
# Outputs
# ============================================================

output "ubuntu_ip" {
  description = "Public IP of the Ubuntu 24.04 instance"
  value       = aws_instance.ubuntu.public_ip
}

output "amazon_linux_ip" {
  description = "Public IP of the Amazon Linux 2023 instance"
  value       = aws_instance.amazon_linux.public_ip
}

output "ssh_ubuntu" {
  description = "SSH into the Ubuntu host"
  value       = "ssh -i keys/${var.key_name}.pem ubuntu@${aws_instance.ubuntu.public_ip}"
}

output "ssh_amazon_linux" {
  description = "SSH into the Amazon Linux host"
  value       = "ssh -i keys/${var.key_name}.pem ec2-user@${aws_instance.amazon_linux.public_ip}"
}

output "private_key_path" {
  description = "Local path of the generated private key (copy it to the Ansible controller)"
  value       = local_sensitive_file.private_key.filename
}

output "inventory_snippet" {
  description = "INI snippet to paste into inventory/production/hosts (or into the API web UI)"
  value       = <<-EOT
    ubuntu        ansible_host=${aws_instance.ubuntu.public_ip} ansible_user=ubuntu
    amazon-linux  ansible_host=${aws_instance.amazon_linux.public_ip} ansible_user=ec2-user
  EOT
}
