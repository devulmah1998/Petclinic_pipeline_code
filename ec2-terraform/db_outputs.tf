# Outputs for database security group to be used by RDS module
output "db_security_group_for_rds" {
  description = "Database security group ID to use in RDS configuration"
  value       = aws_security_group.db_sg.id
}

output "vpc_id" {
  description = "VPC ID where resources are created"
  value       = data.aws_vpc.default.id
}
