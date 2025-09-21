#!/bin/bash
set -e

AWS_REGION="sa-east-1"

echo "🔍 Verificando recursos antes do terraform import..."

# 1. ECR Repository
if aws ecr describe-repositories --repository-names react-app --region $AWS_REGION >/dev/null 2>&1; then
  echo "✅ ECR repository 'react-app' existe → importando..."
  terraform import aws_ecr_repository.repo react-app || true
else
  echo "🆕 ECR repository 'react-app' não existe → Terraform vai criar."
fi

# 2. IAM Role (EC2 ECR Role)
if aws iam get-role --role-name ec2-ecr-role-react-app >/dev/null 2>&1; then
  echo "✅ IAM Role 'ec2-ecr-role-react-app' existe → importando..."
  terraform import aws_iam_role.ec2_role ec2-ecr-role-react-app || true
else
  echo "🆕 IAM Role 'ec2-ecr-role-react-app' não existe → Terraform vai criar."
fi

# 3. Security Group
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=react-web-sg --region $AWS_REGION \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [[ "$SG_ID" != "None" ]]; then
  echo "✅ Security Group 'react-web-sg' existe ($SG_ID) → importando..."
  terraform import aws_security_group.web_sg $SG_ID || true
else
  echo "🆕 Security Group 'react-web-sg' não existe → Terraform vai criar."
fi

# 4. CloudWatch Log Group
if aws logs describe-log-groups --log-group-name-prefix react-app-logs --region $AWS_REGION \
   --query "logGroups[?logGroupName=='react-app-logs']" --output text | grep -q "react-app-logs"; then
  echo "✅ CloudWatch Log Group 'react-app-logs' existe → importando..."
  terraform import aws_cloudwatch_log_group.react_app_logs react-app-logs || true
else
  echo "🆕 CloudWatch Log Group 'react-app-logs' não existe → Terraform vai criar."
fi

# 5. IAM Role (Lambda Exec)
if aws iam get-role --role-name lambda-exec-role >/dev/null 2>&1; then
  echo "✅ IAM Role 'lambda-exec-role' existe → importando..."
  terraform import aws_iam_role.lambda_exec lambda-exec-role || true
else
  echo "🆕 IAM Role 'lambda-exec-role' não existe → Terraform vai criar."
fi

echo "✔️ Finalizado! Agora rode: terraform plan"
