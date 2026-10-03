# ============================================================
# EC2: Ubuntu + Amazon Linux, one region (eu-north-1)
# Both hosts belong to the Ansible group "aws_hosts"
# ============================================================

# ---------- AMI: Ubuntu 24.04 LTS (Canonical) ----------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ---------- AMI: Amazon Linux 2023 (Amazon) ----------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ---------- Default VPC ----------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------- SSH key pair (generated here, private key stays local) ----------
resource "tls_private_key" "lab" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab" {
  key_name   = var.key_name
  public_key = tls_private_key.lab.public_key_openssh

  tags = {
    Name = var.key_name
  }
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.lab.private_key_openssh
  filename        = "${path.module}/keys/${var.key_name}.pem"
  file_permission = "0600"
}

# ---------- Security Group: SSH + HTTP ----------
resource "aws_security_group" "lab" {
  name        = "cmd521-ansible-sg"
  description = "SSH and HTTP for CMD521 Ansible lab hosts"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from admin CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cmd521-ansible-sg"
  }
}

# ---------- Ubuntu 24.04 (ansible_user = ubuntu) ----------
resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.lab.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.lab.id]

  tags = {
    Name   = "cmd521-ubuntu"
    OS     = "ubuntu"
    Group  = "aws_hosts"
    Campus = "CMD521"
  }
}

# ---------- Amazon Linux 2023 (ansible_user = ec2-user) ----------
resource "aws_instance" "amazon_linux" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.lab.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.lab.id]

  tags = {
    Name   = "cmd521-amazon-linux"
    OS     = "amazon-linux"
    Group  = "aws_hosts"
    Campus = "CMD521"
  }
}
