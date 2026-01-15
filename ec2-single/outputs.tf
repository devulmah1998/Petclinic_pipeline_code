output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = module.ec2_instance.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name"
  value       = module.ec2_instance.public_dns
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ec2_sg.id
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i your-key.pem ubuntu@${module.ec2_instance.public_ip}"
}

output "instance_details" {
  description = "Complete instance details"
  value = {
    id          = module.ec2_instance.id
    public_ip   = module.ec2_instance.public_ip
    public_dns  = module.ec2_instance.public_dns
    instance_type = "t3.large"
    ram         = "8GB"
    vcpus       = "2"
    region      = var.aws_region
  }
}
