# Combined Infrastructure - EC2 + RDS

Deploy EC2 instance and RDS MySQL database together in a single Terraform apply.

## What Gets Created

✅ **EC2 Instance** (t3.xlarge, 16GB RAM)
- Ubuntu 22.04
- Java, Python, Maven, Terraform, Git
- Apache Tomcat 10
- IAM role with RDS access

✅ **RDS MySQL Database** (db.t3.micro)
- MySQL 8.0
- Encrypted storage
- Automated backups
- IAM authentication enabled
- Enhanced monitoring

✅ **Security Groups**
- App server security group (SSH, HTTP, HTTPS, Tomcat)
- Database security group (MySQL from app server only)

✅ **IAM Roles**
- EC2 role with RDS, SSM, CloudWatch access
- RDS monitoring role

## Advantages

- ✅ Deploy everything at once
- ✅ Security groups automatically configured
- ✅ EC2 can immediately connect to RDS
- ✅ Single terraform apply/destroy
- ✅ Consistent state management

## Usage

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Get Connection Info

```bash
terraform output summary
```

## Connecting to Database from EC2

```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@<ec2-ip>

# Connect to RDS
mysql -h <rds-endpoint> -P 3306 -u admin -p
```

## Using IAM Authentication

```bash
# On EC2 instance
TOKEN=$(aws rds generate-db-auth-token \
  --hostname <rds-endpoint> \
  --port 3306 \
  --username admin \
  --region us-east-1)

mysql -h <rds-endpoint> -P 3306 -u admin --password="$TOKEN" --ssl-mode=REQUIRED
```

## Cleanup

```bash
terraform destroy
```

## Cost Estimate

- EC2 t3.xlarge: ~$120/month
- RDS db.t3.micro: ~$12/month
- Storage: ~$5/month
- **Total: ~$137/month**

## Notes

- RDS is NOT publicly accessible (secure)
- Only EC2 can connect to RDS
- All credentials managed via IAM
- Automatic backups enabled
- CloudWatch monitoring enabled
