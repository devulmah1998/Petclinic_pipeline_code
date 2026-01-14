# Security Group Setup Guide

This guide explains the security group configuration for EC2 and RDS communication.

## Architecture

```
Internet → EC2 (App Server) → RDS (Database)
```

## Security Groups

### 1. Application Server Security Group (`app-server-sg`)

**Inbound Rules:**
- Port 22 (SSH): 0.0.0.0/0 - For remote access
- Port 80 (HTTP): 0.0.0.0/0 - For web traffic
- Port 443 (HTTPS): 0.0.0.0/0 - For secure web traffic
- Port 8080 (Tomcat): 0.0.0.0/0 - For application access

**Outbound Rules:**
- All traffic: 0.0.0.0/0 - Allows EC2 to connect to RDS and internet

### 2. Database Security Group (`db-server-sg`)

**Inbound Rules:**
- Port 3306 (MySQL): Only from `app-server-sg` - Restricts database access to application server only

**Outbound Rules:**
- All traffic: 0.0.0.0/0 - For updates and patches

## Deployment Steps

### Option 1: Deploy Together (Recommended)

Create a combined configuration that deploys both EC2 and RDS with proper security groups.

### Option 2: Deploy Separately

1. **Deploy EC2 first:**
   ```bash
   cd ec2-terraform
   terraform init
   terraform apply
   ```

2. **Get the security group ID:**
   ```bash
   terraform output app_security_group_id
   ```

3. **Update RDS configuration:**
   Edit `rds-mysql/terraform.tfvars` and add the security group ID:
   ```hcl
   allowed_security_groups = ["sg-xxxxxxxxxxxxxxxxx"]
   publicly_accessible     = false
   ```

4. **Deploy RDS:**
   ```bash
   cd ../rds-mysql
   terraform init
   terraform apply
   ```

## Security Best Practices

✅ **Implemented:**
- Database only accepts connections from application server
- Database is not publicly accessible
- Specific ports opened instead of all traffic
- Security groups use least privilege principle

⚠️ **Consider for Production:**
- Restrict SSH access (port 22) to specific IP addresses
- Restrict HTTP/HTTPS/Tomcat to specific IP ranges if possible
- Enable Multi-AZ for RDS
- Enable deletion protection for RDS
- Use AWS Secrets Manager for database credentials
- Enable VPC Flow Logs for monitoring
- Use private subnets for RDS
- Implement bastion host for SSH access

## Testing Connectivity

From your EC2 instance, test database connection:

```bash
# Install MySQL client if not already installed
sudo apt-get install -y mysql-client

# Test connection (replace with your RDS endpoint)
mysql -h your-rds-endpoint.rds.amazonaws.com -P 3306 -u admin -p
```

## Troubleshooting

**Cannot connect to database from EC2:**
1. Verify security group IDs match
2. Check RDS security group inbound rules
3. Ensure EC2 and RDS are in the same VPC
4. Verify RDS endpoint is correct

**Cannot SSH to EC2:**
1. Check security group allows port 22
2. Verify key pair is correct
3. Check instance is running

## Network Diagram

```
┌─────────────────────────────────────────┐
│           Internet (0.0.0.0/0)          │
└────────────────┬────────────────────────┘
                 │
                 │ Ports: 22, 80, 443, 8080
                 ▼
┌─────────────────────────────────────────┐
│         EC2 Instance (App Server)       │
│      Security Group: app-server-sg      │
└────────────────┬────────────────────────┘
                 │
                 │ Port: 3306 (MySQL)
                 │ Source: app-server-sg only
                 ▼
┌─────────────────────────────────────────┐
│         RDS MySQL Instance              │
│      Security Group: db-server-sg       │
│      Publicly Accessible: false         │
└─────────────────────────────────────────┘
```
