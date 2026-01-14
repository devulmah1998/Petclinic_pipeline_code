# Test Server Outputs
output "test_instance_id" {
  description = "ID of the test EC2 instance"
  value       = module.ec2_test.id
}

output "test_public_ip" {
  description = "Public IP of test server"
  value       = module.ec2_test.public_ip
}

output "test_public_dns" {
  description = "Public DNS of test server"
  value       = module.ec2_test.public_dns
}

# Production Server Outputs
output "prod_instance_id" {
  description = "ID of the production EC2 instance"
  value       = module.ec2_prod.id
}

output "prod_public_ip" {
  description = "Public IP of production server"
  value       = module.ec2_prod.public_ip
}

output "prod_public_dns" {
  description = "Public DNS of production server"
  value       = module.ec2_prod.public_dns
}

# Security Group
output "security_group_id" {
  description = "ID of the shared security group"
  value       = aws_security_group.app_sg.id
}

# Summary
output "servers_info" {
  description = "Summary of both servers"
  value = {
    test = {
      ip          = module.ec2_test.public_ip
      ssh_command = "ssh -i ${var.private_key_path} ubuntu@${module.ec2_test.public_ip}"
      tomcat_url  = "http://${module.ec2_test.public_ip}:8080"
    }
    prod = {
      ip          = module.ec2_prod.public_ip
      ssh_command = "ssh -i ${var.private_key_path} ubuntu@${module.ec2_prod.public_ip}"
      tomcat_url  = "http://${module.ec2_prod.public_ip}:8080"
    }
  }
}
