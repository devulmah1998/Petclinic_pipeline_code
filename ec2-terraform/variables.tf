variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "dev-server"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "private_key_path" {
  description = "Path to private SSH key for provisioning"
  type        = string
}

variable "git_repo_url" {
  description = "Git repository URL to clone"
  type        = string
}
