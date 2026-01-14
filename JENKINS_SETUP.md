# Jenkins Setup Guide for Terraform

Complete guide to set up Jenkins and deploy AWS infrastructure using Terraform.

## Prerequisites

- Jenkins server installed and running
- Git installed on Jenkins server
- AWS account with access keys
- GitHub/GitLab repository with your Terraform code

## Part 1: Install Jenkins

### On Ubuntu/Linux

```bash
# Update system
sudo apt update

# Install Java
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### On Windows

1. Download Jenkins from: https://www.jenkins.io/download/
2. Run the installer
3. Follow the setup wizard
4. Access Jenkins at: http://localhost:8080

### Access Jenkins

1. Open browser: `http://your-server-ip:8080`
2. Enter the initial admin password
3. Install suggested plugins
4. Create admin user

## Part 2: Install Required Plugins

1. Go to **Manage Jenkins** → **Manage Plugins**
2. Click **Available** tab
3. Search and install:
   - ✅ **Git Plugin** (for Git integration)
   - ✅ **Pipeline Plugin** (for Jenkinsfile)
   - ✅ **Credentials Plugin** (for storing secrets)
   - ✅ **AWS Credentials Plugin** (for AWS access)
   - ✅ **Terraform Plugin** (optional, for better Terraform support)

4. Click **Install without restart**
5. Check **Restart Jenkins when installation is complete**

## Part 3: Configure AWS Credentials in Jenkins

### Step 1: Add AWS Credentials

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **(global)** domain
3. Click **Add Credentials**

**Add AWS Access Keys:**
- Kind: **Secret text** or **AWS Credentials**
- Scope: **Global**
- ID: `aws-credentials`
- Secret: Your AWS Access Key ID and Secret Access Key
- Description: `AWS Credentials for Terraform`

### Step 2: Add Terraform Variables

Add these credentials (Kind: **Secret text**):

| ID | Secret Value | Description |
|----|--------------|-------------|
| `tf-key-name` | your-key-pair-name | AWS key pair name |
| `tf-git-repo-url` | https://github.com/user/repo.git | Git repo URL |

### Alternative: Use AWS Credentials Plugin

1. Add Credentials → **AWS Credentials**
2. ID: `aws-credentials`
3. Access Key ID: `your-access-key`
4. Secret Access Key: `your-secret-key`
5. Click **OK**

## Part 4: Install Terraform on Jenkins Server

### On Linux (Jenkins Server)

```bash
# SSH to Jenkins server
ssh user@jenkins-server

# Download Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip

# Unzip
unzip terraform_1.6.0_linux_amd64.zip

# Move to PATH
sudo mv terraform /usr/local/bin/

# Verify
terraform version

# Make accessible to Jenkins user
sudo chmod +x /usr/local/bin/terraform
```

### On Windows (Jenkins Server)

1. Download Terraform from: https://www.terraform.io/downloads
2. Extract to `C:\terraform`
3. Add to PATH:
   - Right-click **This PC** → **Properties**
   - Click **Advanced system settings**
   - Click **Environment Variables**
   - Edit **Path** → Add `C:\terraform`
4. Restart Jenkins service

## Part 5: Create Jenkins Pipeline Job

### Step 1: Create New Job

1. Click **New Item**
2. Enter name: `Terraform-AWS-Infrastructure`
3. Select **Pipeline**
4. Click **OK**

### Step 2: Configure Pipeline

**General Section:**
- ✅ Check **This project is parameterized**
- Add parameters (optional, already in Jenkinsfile):
  - Choice Parameter: `ACTION` (plan, apply, destroy)
  - Choice Parameter: `DIRECTORY` (ec2-simple, ec2-terraform, rds-mysql)

**Pipeline Section:**
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
- Credentials: Add your GitHub credentials
- Branch: `*/main`
- Script Path: `Jenkinsfile`

Click **Save**

## Part 6: Push Code to Git

```bash
# In your project directory
cd C:\Users\mdevulapelly\petclinic_Terraform

# Initialize git (if not done)
git init

# Add all files
git add .

# Commit
git commit -m "Add Jenkins pipeline for Terraform"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push
git push -u origin main
```

## Part 7: Run the Pipeline

### Method 1: Build with Parameters

1. Go to your Jenkins job
2. Click **Build with Parameters**
3. Select:
   - **ACTION**: `apply`
   - **DIRECTORY**: `ec2-simple`
   - **AUTO_APPROVE**: `false` (for manual approval)
4. Click **Build**

### Method 2: Automatic Trigger (on Git Push)

Configure webhook in GitHub:
1. Go to GitHub repo → **Settings** → **Webhooks**
2. Add webhook:
   - URL: `http://your-jenkins-server:8080/github-webhook/`
   - Content type: `application/json`
   - Events: **Just the push event**
3. Click **Add webhook**

Now every push to main will trigger Jenkins!

## Part 8: Monitor the Build

1. Click on the build number (e.g., #1)
2. Click **Console Output** to see logs
3. Watch Terraform init, plan, and apply
4. Approve when prompted (if AUTO_APPROVE is false)
5. View outputs at the end

## Part 9: View Terraform Outputs

After successful build:
1. Go to build page
2. Scroll to bottom of **Console Output**
3. You'll see:
   ```json
   {
     "test_public_ip": "54.123.45.67",
     "prod_public_ip": "54.123.45.68"
   }
   ```

## Jenkins Pipeline Workflow

```
┌─────────────────────────────────────────────┐
│  1. Developer pushes code to Git            │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  2. Jenkins detects push (webhook)          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  3. Jenkins checks out code                 │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  4. Terraform init                          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  5. Terraform validate                      │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  6. Terraform plan                          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  7. Wait for manual approval                │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  8. Terraform apply                         │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  9. Show outputs (IPs, URLs)                │
└─────────────────────────────────────────────┘
```

## Troubleshooting

### Issue: Terraform not found

**Solution:**
```bash
# On Jenkins server
sudo ln -s /usr/local/bin/terraform /usr/bin/terraform
```

### Issue: AWS credentials not working

**Solution:**
1. Verify credentials in Jenkins
2. Test on Jenkins server:
   ```bash
   export AWS_ACCESS_KEY_ID="your-key"
   export AWS_SECRET_ACCESS_KEY="your-secret"
   aws sts get-caller-identity
   ```

### Issue: Permission denied

**Solution:**
```bash
# Give Jenkins user permissions
sudo usermod -aG sudo jenkins
sudo systemctl restart jenkins
```

### Issue: Git authentication failed

**Solution:**
1. Add GitHub credentials in Jenkins
2. Or use SSH key:
   ```bash
   sudo su - jenkins
   ssh-keygen
   cat ~/.ssh/id_rsa.pub
   # Add to GitHub → Settings → SSH Keys
   ```

## Best Practices

✅ **Use separate Jenkins jobs** for dev, test, prod
✅ **Enable manual approval** for production
✅ **Store state in S3** (remote backend)
✅ **Use Jenkins credentials** for all secrets
✅ **Enable build notifications** (email, Slack)
✅ **Archive terraform plans** as artifacts
✅ **Use Jenkins shared libraries** for reusable code
✅ **Implement proper RBAC** in Jenkins
✅ **Regular Jenkins backups**
✅ **Monitor Jenkins with CloudWatch**

## Advanced: Multi-Environment Setup

Create separate jobs:
- `Terraform-Dev` → deploys to dev
- `Terraform-Test` → deploys to test
- `Terraform-Prod` → deploys to prod (requires approval)

Use different branches:
- `dev` branch → auto-deploy to dev
- `test` branch → auto-deploy to test
- `main` branch → manual deploy to prod

## Next Steps

1. ✅ Install Jenkins
2. ✅ Install plugins
3. ✅ Configure AWS credentials
4. ✅ Install Terraform
5. ✅ Create pipeline job
6. ✅ Push code to Git
7. ✅ Run first deployment
8. ⬜ Set up webhooks
9. ⬜ Configure notifications
10. ⬜ Set up remote state (S3)

## Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Terraform Jenkins Integration](https://www.terraform.io/docs/cloud/run/install-software.html)
