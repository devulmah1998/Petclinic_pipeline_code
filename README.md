# AWS Infrastructure with Terraform

This repository contains Terraform configurations to provision AWS infrastructure.

## Repository Structure

```
.
├── ec2-simple/         # 2 EC2 instances (Test + Production)
├── ec2-terraform/      # Single EC2 with full IAM setup
├── rds-mysql/          # RDS MySQL database
├── .github/workflows/  # GitHub Actions CI/CD
└── docs/               # Documentation
```

## Quick Start

### Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI configured locally
3. Terraform installed (v1.0+)
4. SSH key pair created in AWS

### Local Deployment

#### Option 1: Two Simple EC2 Instances (No Database)

```bash
cd ec2-simple
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

#### Option 2: EC2 + RDS Database

```bash
# Deploy EC2 first
cd ec2-terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform apply

# Get security group ID
terraform output app_security_group_id

# Deploy RDS
cd ../rds-mysql
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and add the security group ID
terraform init
terraform apply
```

## Git Workflow

### Initial Setup

```bash
# Initialize git repository
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: Terraform infrastructure"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/your-username/your-repo.git

# Push to GitHub
git push -u origin main
```

### Making Changes

```bash
# Create a new branch
git checkout -b feature/update-infrastructure

# Make your changes to .tf files

# Test locally
cd ec2-simple
terraform plan

# Commit changes
git add .
git commit -m "Update: description of changes"

# Push to GitHub
git push origin feature/update-infrastructure

# Create Pull Request on GitHub
# After review, merge to main
```

## CI/CD with GitHub Actions

This repository includes GitHub Actions workflows for:

1. **Terraform Validation** - Runs on every PR
2. **Terraform Plan** - Shows what will change
3. **Terraform Apply** - Deploys on merge to main (manual approval)

### Setup GitHub Actions

1. **Add AWS credentials to GitHub Secrets:**
   - Go to: Repository → Settings → Secrets and variables → Actions
   - Add secrets:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `AWS_REGION` (e.g., us-east-1)
     - `TF_VAR_key_name` (your AWS key pair name)
     - `TF_VAR_git_repo_url` (your git repo URL)

2. **Push code to GitHub:**
   ```bash
   git push origin main
   ```

3. **Workflows will run automatically:**
   - On Pull Request: Validation + Plan
   - On merge to main: Apply (with approval)

## Manual Provisioning via Git

### Step 1: Clone Repository

```bash
git clone https://github.com/your-username/your-repo.git
cd your-repo
```

### Step 2: Configure Variables

```bash
cd ec2-simple
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values
```

### Step 3: Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Get Outputs

```bash
terraform output servers_info
```

## Terraform State Management

### Local State (Current Setup)

State files are stored locally and ignored by git (`.gitignore`).

**Pros:**
- Simple setup
- No additional configuration

**Cons:**
- Not suitable for team collaboration
- No state locking
- Risk of state file loss

### Remote State (Recommended for Production)

Use S3 backend for state storage:

```hcl
# Add to main.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "ec2-simple/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Security Best Practices

✅ **Never commit sensitive data:**
- `.tfvars` files are in `.gitignore`
- SSH keys are in `.gitignore`
- Use GitHub Secrets for CI/CD

✅ **Use separate AWS accounts:**
- Development
- Test/Staging
- Production

✅ **Enable branch protection:**
- Require PR reviews
- Require status checks to pass
- Restrict who can push to main

✅ **Use Terraform workspaces:**
```bash
terraform workspace new test
terraform workspace new prod
terraform workspace select test
```

## Common Commands

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Show current state
terraform show

# List resources
terraform state list

# Get outputs
terraform output
```

## Troubleshooting

### Issue: Terraform state locked

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: AWS credentials not found

```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```

### Issue: SSH connection failed

```bash
# Check security group allows SSH
# Check key permissions
chmod 400 your-key.pem

# Test connection
ssh -i your-key.pem ubuntu@<instance-ip>
```

## Cost Estimation

### EC2 Simple (2 instances)
- 2 x t3.xlarge: ~$0.33/hour (~$240/month)

### EC2 + RDS
- 1 x t3.xlarge EC2: ~$0.17/hour (~$120/month)
- 1 x db.t3.micro RDS: ~$0.017/hour (~$12/month)
- Storage: ~$2-5/month

## Support

For issues or questions:
1. Check the documentation in `/docs`
2. Review GitHub Issues
3. Contact the infrastructure team

## License

[Your License Here]

## Contributors

[Your Team/Contributors]
