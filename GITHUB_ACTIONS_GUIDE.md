# GitHub Actions Setup Guide

Complete guide to deploy AWS infrastructure using GitHub Actions.

## Overview

GitHub Actions will automatically deploy your infrastructure when you push code to GitHub.

## Workflows Created

1. **`terraform-combined-plan.yml`** - Runs on Pull Requests
   - Shows what will be created
   - Validates Terraform code
   - Comments plan on PR

2. **`terraform-combined-apply.yml`** - Deploys on push to main
   - Creates EC2 + RDS infrastructure
   - Can also destroy resources
   - Shows deployment summary

3. **`terraform-simple-apply.yml`** - Deploys 2 EC2 instances only
   - No database
   - Simpler setup

## Step 1: Add Secrets to GitHub

Go to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS region | `us-east-1` |
| `TF_VAR_KEY_NAME` | AWS key pair name | `my-key-pair` |
| `TF_VAR_GIT_REPO_URL` | Git repo URL | `https://github.com/user/repo.git` |
| `TF_VAR_DB_PASSWORD` | Database password | `SecurePassword123!` |

### How to Add a Secret:

1. Click **New repository secret**
2. Name: `AWS_ACCESS_KEY_ID`
3. Secret: Paste your AWS access key
4. Click **Add secret**
5. Repeat for all secrets above

## Step 2: Set Up Production Environment

1. Go to **Settings → Environments**
2. Click **New environment**
3. Name: `production`
4. Click **Configure environment**
5. Enable **Required reviewers** (optional)
6. Add yourself as a reviewer
7. Click **Save protection rules**

This adds a manual approval step before deployment.

## Step 3: Push Code to GitHub

```bash
# In your project directory
git add .
git commit -m "Add GitHub Actions workflows"
git push origin main
```

## Step 4: Watch the Deployment

1. Go to your GitHub repository
2. Click **Actions** tab
3. You'll see the workflow running
4. Click on it to see progress

## Workflow Triggers

### Automatic Deployment (Push to Main)

```bash
# Make changes
git add infrastructure-combined/
git commit -m "Update infrastructure"
git push origin main

# GitHub Actions automatically runs terraform apply
```

### Manual Deployment

1. Go to **Actions** tab
2. Select **Terraform Apply - Combined Infrastructure**
3. Click **Run workflow**
4. Select:
   - Branch: `main`
   - Action: `apply` or `destroy`
5. Click **Run workflow**
6. If production environment is configured, approve the deployment

### Pull Request Workflow

```bash
# Create a branch
git checkout -b feature/update-infra

# Make changes
git add infrastructure-combined/
git commit -m "Update EC2 instance size"
git push origin feature/update-infra

# Create Pull Request on GitHub
# GitHub Actions will run terraform plan and comment on the PR
```

## Workflow Behavior

### On Pull Request:
- ✅ Runs `terraform plan`
- ✅ Validates code
- ✅ Comments plan on PR
- ❌ Does NOT deploy

### On Push to Main:
- ✅ Runs `terraform init`
- ✅ Runs `terraform plan`
- ✅ Runs `terraform apply`
- ✅ Creates resources
- ✅ Shows outputs

### Manual Trigger:
- ✅ Can choose `apply` or `destroy`
- ✅ Requires approval (if environment configured)
- ✅ Full control

## Viewing Deployment Results

### Method 1: GitHub Actions Summary

1. Go to **Actions** tab
2. Click on the workflow run
3. Scroll to bottom
4. See deployment summary with IPs and connection info

### Method 2: Download Outputs

1. Go to workflow run
2. Scroll to **Artifacts**
3. Download `terraform-outputs`
4. Open `outputs.json` to see all details

### Method 3: Check AWS Console

1. Go to AWS Console
2. Navigate to **EC2** → **Instances**
3. See your instances running
4. Navigate to **RDS** → **Databases**
5. See your database

## Example Workflow Run

```
┌─────────────────────────────────────────┐
│  1. Checkout code from Git              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  2. Configure AWS credentials           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  3. Setup Terraform                     │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  4. Terraform Init                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  5. Terraform Plan                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  6. ⏸️  Wait for Approval (if enabled)  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  7. Terraform Apply                     │
│     - Creates EC2 instance              │
│     - Creates RDS database              │
│     - Configures security groups        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  8. Show Outputs                        │
│     - EC2 IP: 54.123.45.67              │
│     - RDS Endpoint: mysql-db.xxx...     │
└─────────────────────────────────────────┘
```

## Troubleshooting

### Issue: Workflow fails with "AWS credentials not found"

**Solution:**
1. Check secrets are added correctly
2. Secret names must match exactly (case-sensitive)
3. Re-add the secrets if needed

### Issue: Terraform plan shows errors

**Solution:**
1. Check the error message in workflow logs
2. Fix the Terraform code
3. Push the fix
4. Workflow will run again

### Issue: Approval step not showing

**Solution:**
1. Go to Settings → Environments
2. Make sure `production` environment exists
3. Enable "Required reviewers"
4. Add yourself as a reviewer

### Issue: Resources not created

**Solution:**
1. Check AWS credentials have proper permissions
2. Check IAM user has EC2, RDS, VPC permissions
3. Check AWS region is correct

## Best Practices

✅ **Use Pull Requests**
- Always create a branch
- Create PR to see plan
- Review before merging

✅ **Enable Branch Protection**
- Settings → Branches → Add rule
- Branch name: `main`
- Require PR reviews
- Require status checks

✅ **Use Environments**
- Separate dev, test, prod
- Require approvals for prod
- Different secrets per environment

✅ **Monitor Costs**
- Check AWS billing regularly
- Set up billing alerts
- Destroy resources when not needed

✅ **Secure Secrets**
- Never commit secrets to Git
- Rotate AWS keys regularly
- Use least privilege IAM policies

## Advanced: Multiple Environments

### Create Dev Environment

1. Copy `infrastructure-combined/` to `infrastructure-dev/`
2. Update variables for dev
3. Create workflow: `.github/workflows/terraform-dev.yml`
4. Add dev secrets: `AWS_ACCESS_KEY_ID_DEV`, etc.

### Create Prod Environment

1. Copy `infrastructure-combined/` to `infrastructure-prod/`
2. Update variables for prod
3. Create workflow: `.github/workflows/terraform-prod.yml`
4. Add prod secrets with different AWS account

## Cost Optimization

### Auto-Destroy on Schedule

Add to workflow:

```yaml
on:
  schedule:
    - cron: '0 18 * * 5'  # Every Friday at 6 PM
```

Then run `terraform destroy` to save costs on weekends.

## Monitoring

### Enable Notifications

1. Go to repository **Settings**
2. Click **Notifications**
3. Enable email notifications for workflow failures

### Slack Integration

Add to workflow:

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Next Steps

1. ✅ Add secrets to GitHub
2. ✅ Set up production environment
3. ✅ Push code to GitHub
4. ✅ Watch first deployment
5. ⬜ Set up branch protection
6. ⬜ Configure notifications
7. ⬜ Set up multiple environments
8. ⬜ Implement cost controls

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS Credentials Action](https://github.com/aws-actions/configure-aws-credentials)

## Support

For issues:
1. Check workflow logs in Actions tab
2. Review this guide
3. Check Terraform documentation
4. Open an issue in the repository
