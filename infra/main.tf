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
    null = {
      source = "hashicorp/null"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- ECR repo
resource "aws_ecr_repository" "repo" {
  name         = var.ecr_repo_name
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

  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

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

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- Security Group
data "aws_vpc" "default" {
  default = true
}

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

              # Instalar SSM Agent
              snap install amazon-ssm-agent --classic
              systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
              systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

              systemctl enable docker
              systemctl start docker
              EOF
}

# --- CloudWatch Logs
resource "aws_cloudwatch_log_group" "react_app_logs" {
  name              = "react-app-logs"
  retention_in_days = 7
}

# --- Lambda (já existente no seu código)
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "null_resource" "build_lambda" {
  provisioner "local-exec" {
    command     = "bash build_lambda.sh"
    interpreter = ["bash", "-c"]
  }

  triggers = {
    always_run = timestamp()
  }
}

resource "aws_lambda_function" "discord_alert" {
  function_name = "discord-alert"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.9"
  handler       = "index.lambda_handler"
  filename      = "${path.module}/lambda.zip"

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

# --- EventBridge (EC2 events → Lambda)
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "ec2-state-change"
  description = "Notifica mudanças de estado da EC2"
  event_pattern = <<EOF
{
  "source": ["aws.ec2"],
  "detail-type": ["EC2 Instance State-change Notification"]
}
EOF
}

resource "aws_cloudwatch_event_target" "ec2_to_lambda" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "EC2LambdaTarget"
  arn       = aws_lambda_function.discord_alert.arn
}

resource "aws_lambda_permission" "allow_ec2_event" {
  statement_id  = "AllowExecutionFromEventBridgeEC2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_state_change.arn
}

# --- EventBridge (ECR push → Lambda)
resource "aws_cloudwatch_event_rule" "ecr_image_push" {
  name        = "ecr-image-push"
  description = "Notifica quando uma nova imagem é enviada ao ECR"
  event_pattern = <<EOF
{
  "source": ["aws.ecr"],
  "detail-type": ["ECR Image Action"],
  "detail": { "action-type": ["PUSH"] }
}
EOF
}

resource "aws_cloudwatch_event_target" "ecr_to_lambda" {
  rule      = aws_cloudwatch_event_rule.ecr_image_push.name
  target_id = "ECRLambdaTarget"
  arn       = aws_lambda_function.discord_alert.arn
}

resource "aws_lambda_permission" "allow_ecr_event" {
  statement_id  = "AllowExecutionFromEventBridgeECR"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_image_push.arn
}

# --- EventBridge (Deploy custom events → Lambda)
resource "aws_cloudwatch_event_rule" "deploy_status" {
  name        = "deploy-status"
  description = "Recebe eventos customizados do pipeline"
  event_pattern = <<EOF
{
  "source": ["custom.cicd"],
  "detail-type": ["Deploy Status"]
}
EOF
}

resource "aws_cloudwatch_event_target" "deploy_to_lambda" {
  rule      = aws_cloudwatch_event_rule.deploy_status.name
  target_id = "DeployLambdaTarget"
  arn       = aws_lambda_function.discord_alert.arn
}

resource "aws_lambda_permission" "allow_deploy_event" {
  statement_id  = "AllowExecutionFromEventBridgeDeploy"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.deploy_status.arn
}
