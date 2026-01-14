# EC2 Instance with Terraform

This Terraform configuration creates an EC2 instance with 16GB RAM running Ubuntu, with all required software installed.

## Prerequisites

1. AWS CLI configured with credentials
2. SSH key pair created in AWS
3. Private key file available locally

## What Gets Installed

- Java (OpenJDK 11)
- Python 3
- Maven
- Terraform
- Git
- Apache Tomcat 10

## Usage

1. Copy the example variables file:
   ```bash
   copy terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   - `key_name`: Your AWS key pair name
   - `private_key_path`: Path to your private key file
   - `git_repo_url`: Your Git repository URL

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

6. Access your instance:
   ```bash
   ssh -i /path/to/your-key.pem ubuntu@<public-ip>
   ```

## Instance Details

- **Instance Type**: t3.xlarge (16GB RAM, 4 vCPUs)
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 30GB encrypted GP3
- **IAM Role**: Attached with permissions for RDS, S3, CloudWatch, SSM, and Secrets Manager
- **Security**: Controlled access via security groups

## Security Warning

⚠️ This configuration opens the instance to ALL networks. This is NOT recommended for production use. Consider restricting access to specific IP ranges.

## Outputs

After applying, you'll get:
- Instance ID
- Public IP address
- Public DNS name
- Security group ID
- Tomcat URL

## Cleanup

To destroy all resources:
```bash
terraform destroy
```
