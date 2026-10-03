# ============================================================
# Головний файл: terraform-блок і провайдери
# Лаба CMD521: 2 EC2 (Ubuntu + Amazon Linux) під Ansible-інвентар
# ============================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Провайдер за замовчуванням — один регіон (Європа, Stockholm)
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
