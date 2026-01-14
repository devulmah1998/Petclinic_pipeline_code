terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Security Group for EC2 Application Server
resource "aws_security_group" "app_sg" {
  name        = "app-server-sg"
  description = "Security group for application server"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Tomcat access
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tomcat access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "app-server-sg"
    Environment = var.environment
  }
}

# Security Group for RDS Database
resource "aws_security_group" "db_sg" {
  name        = "db-server-sg"
  description = "Security group for RDS database - allows access from app server"
  vpc_id      = data.aws_vpc.default.id

  # MySQL access from application server only
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
    description     = "MySQL access from application server"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "db-server-sg"
    Environment = var.environment
  }
}

# EC2 Instance Module
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = var.instance_name

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.xlarge" # 16GB RAM
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
      encrypted   = true
    }
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Null resource for provisioning
resource "null_resource" "provision_instance" {
  depends_on = [module.ec2_instance]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = module.ec2_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      
      # Install Java
      "sudo apt-get install -y openjdk-11-jdk",
      
      # Install Python
      "sudo apt-get install -y python3 python3-pip",
      
      # Install Maven
      "sudo apt-get install -y maven",
      
      # Install Terraform
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y terraform",
      
      # Install Git
      "sudo apt-get install -y git",
      
      # Clone git repository (replace with your repo URL)
      "cd /home/ubuntu",
      "git clone ${var.git_repo_url}",
      
      # Download and install Apache Tomcat
      "cd /opt",
      "sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz",
      "sudo tar -xvzf apache-tomcat-10.1.34.tar.gz",
      "sudo mv apache-tomcat-10.1.34 tomcat",
      "sudo chmod +x /opt/tomcat/bin/*.sh",
      
      # Verify installations
      "java -version",
      "python3 --version",
      "mvn -version",
      "terraform -version",
      "git --version"
    ]
  }
}
