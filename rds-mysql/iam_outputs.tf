# IAM Role Outputs
output "rds_monitoring_role_arn" {
  description = "ARN of the RDS enhanced monitoring role"
  value       = aws_iam_role.rds_monitoring.arn
}

output "rds_s3_backup_role_arn" {
  description = "ARN of the RDS S3 backup role"
  value       = aws_iam_role.rds_s3_backup.arn
}

output "rds_iam_auth_policy_arn" {
  description = "ARN of the RDS IAM authentication policy"
  value       = aws_iam_policy.rds_iam_auth.arn
}

output "iam_database_authentication_enabled" {
  description = "Whether IAM database authentication is enabled"
  value       = module.rds_mysql.db_instance_iam_database_authentication_enabled
}
