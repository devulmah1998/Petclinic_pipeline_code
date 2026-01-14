# AWS Infrastructure with Terraform

This repository contains Terraform configurations to provision AWS infrastructure using Jenkins CI/CD.

## Repository Structure

```
.
├── ec2-simple/         # 2 EC2 instances (Test + Production)
├── ec2-terraform/      # Single EC2 with full IAM setup
├── rds-mysql/          # RDS MySQL database
├── Jenkinsfile         # Jenkins pipeline configuration
└── docs/               # Documentation
```

## Quick Start

### Prerequisites

1. Jenkins server installed and running
2. AWS Account with appropriate permissions
3. AWS CLI configured on Jenkins server
4. Terraform installed on Jenkins server
5. Git repository (GitHub/GitLab)

### Setup Steps

1. **Install Jenkins** - See `JENKINS_SETUP.md`
2. **Configure AWS credentials** in Jenkins
3. **Create Jenkins pipeline job**
4. **Push code to Git**
5. **Run the pipeline**

## Jenkins Pipeline

This repository uses Jenkins for CI/CD with the following workflow:

1. **Checkout** - Pull code from Git
2. **Init** - Initialize Terraform
3. **Validate** - Validate Terraform syntax
4. **Plan** - Show what will be created
5. **Approval** - Manual approval step
6. **Apply** - Provision infrastructure
7. **Output** - Display server IPs and info

## Running Deployments

### Via Jenkins UI

1. Go to Jenkins job
2. Click **Build with Parameters**
3. Select:
   - ACTION: `apply`
   - DIRECTORY: `ec2-simple`
   - AUTO_APPROVE: `false`
4. Click **Build**
5. Approve when prompted

### Via Git Push

```bash
# Make changes
git add .
git commit -m "Update infrastructure"
git push origin main

# Jenkins automatically runs the pipeline
```

## Local Deployment (Without Jenkins)

```bash
cd ec2-simple
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Documentation

- **JENKINS_SETUP.md** - Complete Jenkins setup guide
- **SETUP_GUIDE.md** - General setup instructions
- **SECURITY_SETUP.md** - Security group configuration
- **IAM_SECURITY_GUIDE.md** - IAM roles and policies

## Infrastructure Components

### EC2 Simple (2 Instances)
- Test server (16GB RAM)
- Production server (16GB RAM)
- Shared security group
- IAM roles for SSM and CloudWatch

### EC2 Terraform (Single Instance)
- Development server (16GB RAM)
- Full IAM setup
- Database security group

### RDS MySQL
- MySQL 8.0 database
- Encrypted storage
- Automated backups
- IAM authentication enabled

## Cost Estimation

- 2 x t3.xlarge EC2: ~$240/month
- 1 x db.t3.micro RDS: ~$12/month
- Storage: ~$5/month

## Security

✅ Credentials stored in Jenkins
✅ No secrets in Git repository
✅ IAM roles for EC2 instances
✅ Encrypted RDS storage
✅ Security groups configured

## Support

For issues or questions, check the documentation in `/docs` or contact the infrastructure team.

