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

# Attach AWS managed policy for RDS Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# IAM Policy for RDS CloudWatch Logs
resource "aws_iam_policy" "rds_cloudwatch" {
  name        = "rds-cloudwatch-logs-policy"
  description = "Policy for RDS to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/rds/*"
        ]
      }
    ]
  })
}

# IAM Role for RDS Backup to S3
resource "aws_iam_role" "rds_s3_backup" {
  name = "rds-s3-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "rds-s3-backup-role"
    Environment = var.environment
  }
}

# IAM Policy for RDS S3 Backup Access
resource "aws_iam_policy" "rds_s3_backup" {
  name        = "rds-s3-backup-policy"
  description = "Policy for RDS to backup to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.db_identifier}-backups",
          "arn:aws:s3:::${var.db_identifier}-backups/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_s3_backup" {
  role       = aws_iam_role.rds_s3_backup.name
  policy_arn = aws_iam_policy.rds_s3_backup.arn
}

# IAM Database Authentication User Policy (for EC2 to use)
resource "aws_iam_policy" "rds_iam_auth" {
  name        = "rds-iam-authentication-policy"
  description = "Policy for IAM database authentication"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${var.aws_region}:*:dbuser:*/${var.db_username}"
        ]
      }
    ]
  })

  tags = {
    Name        = "rds-iam-authentication-policy"
    Environment = var.environment
  }
}
