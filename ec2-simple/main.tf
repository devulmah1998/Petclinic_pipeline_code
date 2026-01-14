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

# Security Group for EC2 Instances
resource "aws_security_group" "app_sg" {
  name        = "app-server-sg"
  description = "Security group for application servers"
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
    Name = "app-server-sg"
  }
}

# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name = "ec2-app-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ec2-app-server-role"
  }
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-app-server-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "ec2-app-server-profile"
  }
}

# Test Server
module "ec2_test" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "test-server"

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
    Name        = "test-server"
    Environment = "test"
    Terraform   = "true"
  }
}

# Production Server
module "ec2_prod" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "prod-server"

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
    Name        = "prod-server"
    Environment = "production"
    Terraform   = "true"
  }
}

# Provisioning for Test Server
resource "null_resource" "provision_test" {
  depends_on = [module.ec2_test]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = module.ec2_test.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y openjdk-11-jdk",
      "sudo apt-get install -y python3 python3-pip",
      "sudo apt-get install -y maven",
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y terraform",
      "sudo apt-get install -y git",
      "cd /home/ubuntu",
      "git clone ${var.git_repo_url}",
      "cd /opt",
      "sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz",
      "sudo tar -xvzf apache-tomcat-10.1.34.tar.gz",
      "sudo mv apache-tomcat-10.1.34 tomcat",
      "sudo chmod +x /opt/tomcat/bin/*.sh"
    ]
  }
}

# Provisioning for Production Server
resource "null_resource" "provision_prod" {
  depends_on = [module.ec2_prod]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = module.ec2_prod.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y openjdk-11-jdk",
      "sudo apt-get install -y python3 python3-pip",
      "sudo apt-get install -y maven",
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y terraform",
      "sudo apt-get install -y git",
      "cd /home/ubuntu",
      "git clone ${var.git_repo_url}",
      "cd /opt",
      "sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz",
      "sudo tar -xvzf apache-tomcat-10.1.34.tar.gz",
      "sudo mv apache-tomcat-10.1.34 tomcat",
      "sudo chmod +x /opt/tomcat/bin/*.sh"
    ]
  }
}
