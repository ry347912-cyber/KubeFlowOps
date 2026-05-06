output "ec2_public_ip" {
  description = "EC2 Public IP — add this to GitHub Secrets as EC2_HOST"
  value       = aws_eip.app_eip.public_ip
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ecr_repository_name" {
  description = "ECR Repository Name — add to GitHub Secrets as ECR_REPOSITORY"
  value       = aws_ecr_repository.app_repo.name
}

output "ssh_command" {
  description = "SSH command to connect to your server"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_eip.app_eip.public_ip}"
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.app_eip.public_ip}:5000"
}
