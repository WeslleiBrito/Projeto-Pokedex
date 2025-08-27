variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "sa-east-1"
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "react-app"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into EC2 (ex: YOUR_IP/32). Required."
  type        = string
}

variable "public_key" {
  description = "Optional SSH public key (openssh format). If empty, Terraform will generate a keypair and output the private key."
  type        = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBwTGvSRagdYJBXw3Y/ApYV5wgLy2YzXm2eIn0131mB/FPiONMsWLZrUe38hvIwdxwxPzGwMQYJ09TJAsGQldyIVa08tKRNedZ3Uji7CoaxKU2ByDSYNt+EVneur3TvqbAKEWCWF24kYhvd14XWRKw24ZdiOOKLOgBqm//J9Vvxbb6X5wqov7xIJEfprYqo8ntmGtM3Z7YkrC4ka94HIUfq4oaH3wg5agfOPneP22Gx75OiPuhB5oKf1gsd7E3ibFerWZX+jmrMIcZIl2CKPK7tiFDuLhgHE6B7hWFLwls1qj9SgvWDTl5VbwEP4hyH4Xi1BD/kUkk7IaisA/DQ+gn"
}
