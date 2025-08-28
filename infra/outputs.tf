output "ecr_repository_url" {
  description = "URL do repositório ECR para push das imagens"
  value       = aws_ecr_repository.repo.repository_url
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "DNS público da instância EC2"
  value       = aws_instance.app.public_dns
}

output "security_group_id" {
  description = "ID do Security Group da aplicação"
  value       = aws_security_group.web_sg.id
}

output "instance_id" {
  value = aws_instance.react-app.id
}