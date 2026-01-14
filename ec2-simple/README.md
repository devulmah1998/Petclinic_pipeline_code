# Two EC2 Instances - Test and Production

Simple Terraform configuration to create 2 EC2 instances (16GB RAM each) without database.

## What Gets Created

- **Test Server**: Ubuntu 22.04, 16GB RAM, with Java, Python, Maven, Terraform, Git, Tomcat
- **Production Server**: Ubuntu 22.04, 16GB RAM, with Java, Python, Maven, Terraform, Git, Tomcat
- **Shared Security Group**: Allows SSH (22), HTTP (80), HTTPS (443), Tomcat (8080)
- **IAM Role**: Basic permissions for SSM and CloudWatch

## No Database

This configuration does NOT include any database. It's just 2 standalone EC2 instances.

## Usage

1. Copy the example file:
   ```bash
   copy terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   - AWS key pair name
   - Path to your private key
   - Git repository URL

3. Deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Get server information:
   ```bash
   terraform output servers_info
   ```

## Accessing Servers

```bash
# Test server
ssh -i your-key.pem ubuntu@<test-ip>

# Production server
ssh -i your-key.pem ubuntu@<prod-ip>
```

## What's Installed

Both servers have:
- Java 11
- Python 3
- Maven
- Terraform
- Git
- Apache Tomcat 10

## Cleanup

```bash
terraform destroy
```

## Cost

- 2 x t3.xlarge instances (16GB RAM each)
- Approximately $0.1664/hour per instance
- Total: ~$0.33/hour or ~$240/month for both running 24/7

## Notes

- Both servers share the same security group
- Both servers have the same IAM role
- No database connection configured
- Servers are independent of each other
