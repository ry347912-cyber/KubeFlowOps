variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "ap-south-1"   # Mumbai — lowest latency from India
}

variable "project_name" {
  description = "Project name — used for all resource names"
  type        = string
  default     = "cicd-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "public_key_path" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
