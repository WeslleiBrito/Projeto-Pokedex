terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- ECR repo
resource "aws_ecr_repository" "repo" {
  name = var.ecr_repo_name

  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- Suffix for unique names
resource "random_id" "suffix" {
  byte_length = 2
}

# --- IAM role for EC2
data "aws_iam_policy_document" "assume_for_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "ec2-ecr-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.assume_for_ec2.json
}

data "aws_iam_policy_document" "ec2_ecr_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  # logs
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  # SSM
  statement {
    actions   = ["ssm:DescribeInstanceInformation", "ssm:GetCommandInvocation", "ssm:SendCommand"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy" "ec2_ecr_policy_attach" {
  name   = "ec2-ecr-policy-${random_id.suffix.hex}"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.ec2_ecr_policy.json
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-${random_id.suffix.hex}"
  role = aws_iam_role.ec2_role.name
}

# Anexa a política gerenciada do SSM ao IAM Role da instância EC2
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- Security Group
resource "aws_security_group" "web_sg" {
  name        = "react-web-sg-${random_id.suffix.hex}"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Default VPC
data "aws_vpc" "default" {
  default = true
}

# --- EC2 instance
resource "aws_instance" "app" {
  ami                         = "ami-035efd31ab8835d8a"
  instance_type               = var.instance_type
  key_name                    = "inst-pokedex-key"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "react-app-server-${random_id.suffix.hex}"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip
              # Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io
              usermod -aG docker ubuntu
              # AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              systemctl enable docker
              systemctl start docker
              EOF
}