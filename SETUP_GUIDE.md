# Setup Guide: Provision Resources Using Git

This guide shows you how to set up and use Git to manage and provision your AWS infrastructure.

## Step 1: Initialize Git Repository

```bash
# Navigate to your project directory
cd /path/to/petclinic_Terraform

# Initialize git
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: AWS infrastructure with Terraform"
```

## Step 2: Create GitHub Repository

### Option A: Using GitHub Website

1. Go to https://github.com
2. Click "New repository"
3. Name it (e.g., `aws-infrastructure`)
4. Don't initialize with README (we already have files)
5. Click "Create repository"

### Option B: Using GitHub CLI

```bash
# Install GitHub CLI first: https://cli.github.com/

# Login
gh auth login

# Create repository
gh repo create aws-infrastructure --private --source=. --remote=origin

# Push code
git push -u origin main
```

## Step 3: Add Remote and Push

```bash
# Add GitHub as remote (replace with your URL)
git remote add origin https://github.com/YOUR_USERNAME/aws-infrastructure.git

# Push to GitHub
git push -u origin main
```

## Step 4: Configure GitHub Secrets

Go to your repository on GitHub:
1. Click **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these secrets:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS region | `us-east-1` |
| `TF_VAR_key_name` | Your AWS key pair name | `my-key-pair` |
| `TF_VAR_git_repo_url` | Git repo to clone on EC2 | `https://github.com/user/repo.git` |

## Step 5: Enable GitHub Actions

1. Go to **Actions** tab in your repository
2. You'll see workflows: `Terraform Plan` and `Terraform Apply`
3. They're automatically enabled

## Step 6: Create Protection Rules (Optional but Recommended)

1. Go to **Settings** → **Branches**
2. Click **Add branch protection rule**
3. Branch name pattern: `main`
4. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging

## Workflow: Making Changes

### Method 1: Pull Request Workflow (Recommended)

```bash
# 1. Create a new branch
git checkout -b feature/add-monitoring

# 2. Make changes to Terraform files
nano ec2-simple/main.tf

# 3. Test locally
cd ec2-simple
terraform plan

# 4. Commit changes
git add .
git commit -m "Add CloudWatch monitoring to EC2 instances"

# 5. Push to GitHub
git push origin feature/add-monitoring

# 6. Create Pull Request on GitHub
# - Go to your repository
# - Click "Compare & pull request"
# - Add description
# - Click "Create pull request"

# 7. GitHub Actions will automatically:
# - Run terraform fmt check
# - Run terraform validate
# - Run terraform plan
# - Comment the plan on your PR

# 8. Review the plan, then merge PR

# 9. After merge, GitHub Actions will:
# - Run terraform apply (with manual approval)
```

### Method 2: Direct Push (Not Recommended for Production)

```bash
# Make changes
nano ec2-simple/main.tf

# Commit and push directly to main
git add .
git commit -m "Update infrastructure"
git push origin main

# GitHub Actions will run terraform apply
```

## Workflow: Manual Deployment

### Deploy from Local Machine

```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/aws-infrastructure.git
cd aws-infrastructure

# 2. Navigate to desired directory
cd ec2-simple

# 3. Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# 4. Add your values:
aws_region       = "us-east-1"
key_name         = "your-key-pair-name"
private_key_path = "~/.ssh/your-key.pem"
git_repo_url     = "https://github.com/your-username/your-repo.git"

# 5. Initialize Terraform
terraform init

# 6. Plan
terraform plan

# 7. Apply
terraform apply

# 8. Get outputs
terraform output servers_info
```

## Workflow: Deploy via GitHub Actions

### Automatic Deployment (on merge to main)

1. Make changes in a branch
2. Create Pull Request
3. Review terraform plan in PR comments
4. Merge PR
5. GitHub Actions runs terraform apply
6. Approve deployment in GitHub Actions UI

### Manual Deployment (workflow_dispatch)

1. Go to **Actions** tab
2. Select **Terraform Apply** workflow
3. Click **Run workflow**
4. Select directory (ec2-simple, ec2-terraform, or rds-mysql)
5. Click **Run workflow**
6. Approve deployment when prompted

## Monitoring Deployments

### View Workflow Runs

1. Go to **Actions** tab
2. Click on a workflow run
3. View logs for each step
4. Check terraform plan/apply output

### View Terraform State

State is stored locally or in S3 (if configured).

To view current state:
```bash
terraform show
terraform state list
```

## Rollback Changes

### Rollback via Git

```bash
# 1. Find the commit to rollback to
git log --oneline

# 2. Revert to previous commit
git revert <commit-hash>

# 3. Push
git push origin main

# 4. GitHub Actions will apply the reverted state
```

### Manual Rollback

```bash
# 1. Checkout previous version
git checkout <commit-hash> ec2-simple/

# 2. Apply
cd ec2-simple
terraform apply

# 3. Commit the rollback
git add .
git commit -m "Rollback: revert to previous infrastructure"
git push origin main
```

## Best Practices

### 1. Always Use Branches

```bash
# Create feature branch
git checkout -b feature/description

# Make changes, commit, push
git push origin feature/description

# Create PR, review, merge
```

### 2. Write Good Commit Messages

```bash
# Good
git commit -m "Add: CloudWatch alarms for EC2 instances"
git commit -m "Fix: Security group ingress rules"
git commit -m "Update: Increase EC2 instance size to t3.2xlarge"

# Bad
git commit -m "changes"
git commit -m "fix"
git commit -m "update"
```

### 3. Test Locally First

```bash
# Always test before pushing
terraform fmt
terraform validate
terraform plan
```

### 4. Use Terraform Workspaces

```bash
# Create workspaces for environments
terraform workspace new dev
terraform workspace new test
terraform workspace new prod

# Switch between workspaces
terraform workspace select test
terraform apply
```

### 5. Tag Releases

```bash
# Tag stable versions
git tag -a v1.0.0 -m "Production release v1.0.0"
git push origin v1.0.0
```

## Troubleshooting

### Issue: GitHub Actions failing

**Check:**
1. Secrets are configured correctly
2. AWS credentials have proper permissions
3. Terraform syntax is valid

**Fix:**
```bash
# Test locally first
terraform validate
terraform plan
```

### Issue: State conflicts

**Cause:** Multiple people applying changes simultaneously

**Fix:** Use remote state with locking (S3 + DynamoDB)

### Issue: Can't push to main

**Cause:** Branch protection rules

**Fix:** Create a Pull Request instead

## Security Checklist

✅ Never commit `.tfvars` files (in `.gitignore`)
✅ Never commit SSH keys (in `.gitignore`)
✅ Use GitHub Secrets for sensitive data
✅ Enable branch protection on main
✅ Require PR reviews before merge
✅ Use separate AWS accounts for dev/prod
✅ Rotate AWS credentials regularly
✅ Enable MFA on AWS account
✅ Use least privilege IAM policies

## Next Steps

1. ✅ Initialize Git repository
2. ✅ Push to GitHub
3. ✅ Configure GitHub Secrets
4. ✅ Enable GitHub Actions
5. ✅ Set up branch protection
6. ✅ Make first deployment
7. ⬜ Set up remote state (S3)
8. ⬜ Configure Terraform workspaces
9. ⬜ Set up monitoring and alerts
10. ⬜ Document runbooks

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
