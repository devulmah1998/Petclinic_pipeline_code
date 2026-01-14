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

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for EC2 Application Server
resource "aws_security_group" "app_sg" {
  name        = "app-server-sg"
  description = "Security group for application server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tomcat access"
  }

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
  description = "Security group for RDS database"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
    description     = "MySQL access from application server"
  }

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

# IAM Role for EC2
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
    Name        = "ec2-app-server-role"
    Environment = var.environment
  }
}

# IAM Policy for RDS Access
resource "aws_iam_policy" "rds_access" {
  name        = "ec2-rds-access-policy"
  description = "Policy for EC2 to access RDS using IAM authentication"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${var.aws_region}:*:dbuser:*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.rds_access.arn
}

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
    Name        = "ec2-app-server-profile"
    Environment = var.environment
  }
}

# EC2 Instance
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = var.instance_name

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.xlarge"
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
    Name        = var.instance_name
    Environment = var.environment
    Terraform   = "true"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "mysql" {
  name       = "mysql-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name        = "MySQL DB subnet group"
    Environment = var.environment
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "rds-enhanced-monitoring-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS MySQL Instance
module "rds_mysql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.db_identifier

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = var.db_instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = false

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  iam_database_authentication_enabled = true
  
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled   = true
  performance_insights_retention_period = 7

  tags = {
    Name        = var.db_identifier
    Environment = var.environment
    Terraform   = "true"
  }
}

# Provisioning for EC2
resource "null_resource" "provision_instance" {
  depends_on = [module.ec2_instance, module.rds_mysql]

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
      "sudo apt-get install -y openjdk-11-jdk",
      "sudo apt-get install -y python3 python3-pip",
      "sudo apt-get install -y maven",
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y terraform",
      "sudo apt-get install -y git mysql-client",
      "cd /home/ubuntu",
      "git clone ${var.git_repo_url}",
      "cd /opt",
      "sudo wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz",
      "sudo tar -xvzf apache-tomcat-10.1.34.tar.gz",
      "sudo mv apache-tomcat-10.1.34 tomcat",
      "sudo chmod +x /opt/tomcat/bin/*.sh",
      "echo 'RDS_ENDPOINT=${module.rds_mysql.db_instance_address}' | sudo tee -a /etc/environment",
      "echo 'DB_NAME=${var.db_name}' | sudo tee -a /etc/environment",
      "echo 'DB_USERNAME=${var.db_username}' | sudo tee -a /etc/environment"
    ]
  }
}
