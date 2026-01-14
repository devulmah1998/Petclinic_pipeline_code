# RDS MySQL Instance with Terraform

This Terraform configuration creates an RDS MySQL instance using the official AWS RDS module.

## Prerequisites

- AWS CLI configured with credentials
- Terraform installed

## What Gets Created

- RDS MySQL 8.0 instance
- DB subnet group using default VPC subnets
- Security group allowing MySQL access (port 3306)
- CloudWatch logs for error, general, and slow query logs
- Encrypted storage
- Automated backups

## Usage

1. Copy the example variables file:
   ```bash
   copy terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   - `db_password`: Set a strong password (required)
   - `db_name`: Your database name
   - `db_username`: Master username
   - Other settings as needed

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

6. Connect to your database:
   ```bash
   mysql -h <endpoint> -P 3306 -u admin -p
   ```

## Instance Details

- **Engine**: MySQL 8.0
- **Instance Class**: db.t3.micro (default, can be changed)
- **Storage**: 20GB (auto-scales up to 100GB)
- **Encryption**: Enabled
- **Backups**: 7 days retention
- **Multi-AZ**: Disabled by default (can be enabled)
- **IAM Authentication**: Enabled for secure, password-less access
- **Enhanced Monitoring**: Enabled (60-second intervals)
- **Performance Insights**: Enabled (7-day retention)

## Security Warning

⚠️ This configuration makes the database publicly accessible and open to all networks (0.0.0.0/0). This is NOT recommended for production. Consider:
- Setting `publicly_accessible = false`
- Restricting security group to specific IP ranges
- Using VPC peering or VPN for secure access

## Outputs

After applying, you'll get:
- Database endpoint
- Database address
- Database port
- Connection string
- Instance ID and ARN

## Cost Considerations

- db.t3.micro is eligible for AWS Free Tier (750 hours/month)
- Storage costs apply beyond free tier limits
- Multi-AZ deployment doubles the cost

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

Note: If `deletion_protection = true`, you'll need to set it to `false` before destroying.
