output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.rds_mysql.db_instance_identifier
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds_mysql.db_instance_endpoint
}

output "db_instance_address" {
  description = "RDS instance address"
  value       = module.rds_mysql.db_instance_address
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = module.rds_mysql.db_instance_port
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds_mysql.db_instance_arn
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_username" {
  description = "Database master username"
  value       = var.db_username
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.rds_sg.id
}

output "connection_string" {
  description = "MySQL connection string"
  value       = "mysql -h ${module.rds_mysql.db_instance_address} -P ${module.rds_mysql.db_instance_port} -u ${var.db_username} -p"
}
