# IAM Role and Profile Outputs
output "ec2_iam_role_name" {
  description = "Name of the IAM role attached to EC2"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_iam_role_arn" {
  description = "ARN of the IAM role attached to EC2"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}
