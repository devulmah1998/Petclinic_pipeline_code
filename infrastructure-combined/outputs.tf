# EC2 Outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2_instance.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.ec2_instance.public_dns
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app_sg.id
}

output "tomcat_url" {
  description = "Tomcat access URL"
  value       = "http://${module.ec2_instance.public_ip}:8080"
}

# RDS Outputs
output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.rds_mysql.db_instance_identifier
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds_mysql.db_instance_endpoint
}

output "db_address" {
  description = "RDS instance address"
  value       = module.rds_mysql.db_instance_address
}

output "db_port" {
  description = "RDS instance port"
  value       = module.rds_mysql.db_instance_port
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

# Connection Info
output "connection_info" {
  description = "Complete connection information"
  value = {
    ec2_ip           = module.ec2_instance.public_ip
    ssh_command      = "ssh -i ${var.private_key_path} ubuntu@${module.ec2_instance.public_ip}"
    tomcat_url       = "http://${module.ec2_instance.public_ip}:8080"
    db_endpoint      = module.rds_mysql.db_instance_address
    db_name          = var.db_name
    db_username      = var.db_username
    mysql_command    = "mysql -h ${module.rds_mysql.db_instance_address} -P 3306 -u ${var.db_username} -p"
  }
  sensitive = false
}

output "summary" {
  description = "Deployment summary"
  value = <<-EOT
  
  ========================================
  Infrastructure Deployed Successfully!
  ========================================
  
  EC2 Instance:
    - IP: ${module.ec2_instance.public_ip}
    - SSH: ssh -i ${var.private_key_path} ubuntu@${module.ec2_instance.public_ip}
    - Tomcat: http://${module.ec2_instance.public_ip}:8080
  
  RDS Database:
    - Endpoint: ${module.rds_mysql.db_instance_address}
    - Database: ${var.db_name}
    - Username: ${var.db_username}
    - Connect: mysql -h ${module.rds_mysql.db_instance_address} -P 3306 -u ${var.db_username} -p
  
  Security:
    - EC2 and RDS are connected via security groups
    - RDS only accepts connections from EC2
    - IAM authentication enabled for RDS
  
  ========================================
  EOT
}
