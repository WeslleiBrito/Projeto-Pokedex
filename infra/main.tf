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
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
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
  name               = "ec2-ecr-role-react-app"
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
  name   = "ec2-ecr-policy-react-app"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.ec2_ecr_policy.json
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-react-app"
  role = aws_iam_role.ec2_role.name
}

# Anexa a política gerenciada do SSM ao IAM Role da instância EC2
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- Security Group
resource "aws_security_group" "web_sg" {
  name        = "react-web-sg"
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
    Name = "react-app-server"
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

            # Instalar SSM Agent no Ubuntu
            snap install amazon-ssm-agent --classic
            systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
            systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

            systemctl enable docker
            systemctl start docker
            EOF

}


resource "null_resource" "build_lambda" {
  provisioner "local-exec" {
    command = "${path.module}/build_lambda.sh"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Lambda para enviar alertas ao Discord
resource "aws_lambda_function" "discord_alert" {
  function_name = "discord-alerts"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.lambda_handler"

  filename         = "${path.module}/discord_alert.zip"
  source_code_hash = filebase64sha256("${path.module}/discord_alert.zip")

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-discord"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# EventBridge para disparar alerta em eventos de deploy
resource "aws_cloudwatch_event_rule" "deploy_events" {
  name        = "react-app-deploy-events"
  description = "Dispara evento no deploy do React App"
  event_pattern = jsonencode({
    source = ["aws.ec2", "aws.ecr"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.deploy_events.name
  target_id = "send-to-discord"
  arn       = aws_lambda_function.discord_alert.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.deploy_events.arn
}


  