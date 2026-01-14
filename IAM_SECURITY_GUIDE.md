# IAM Security Configuration Guide

This guide explains the IAM roles and policies configured for EC2 and RDS resources.

## Overview

IAM roles provide secure, temporary credentials to AWS resources without embedding long-term access keys. This configuration follows AWS security best practices.

## EC2 IAM Configuration

### IAM Role: `ec2-app-server-role`

The EC2 instance is assigned an IAM role with the following capabilities:

#### 1. RDS Access Policy
**Purpose:** Allows EC2 to connect to RDS using IAM database authentication

**Permissions:**
- `rds-db:connect` - Connect to RDS databases using IAM authentication

**Benefits:**
- No need to store database passwords in application code
- Automatic credential rotation
- Centralized access control

#### 2. CloudWatch Logs Policy
**Purpose:** Enables application logging to CloudWatch

**Permissions:**
- `logs:CreateLogGroup` - Create log groups
- `logs:CreateLogStream` - Create log streams
- `logs:PutLogEvents` - Write log events
- `logs:DescribeLogStreams` - Describe log streams

**Use Cases:**
- Application logs
- Error tracking
- Performance monitoring

#### 3. S3 Access Policy
**Purpose:** Access S3 buckets for application artifacts and backups

**Permissions:**
- `s3:GetObject` - Download files
- `s3:PutObject` - Upload files
- `s3:ListBucket` - List bucket contents

**Scope:** Limited to buckets matching `${instance_name}-*`

#### 4. Systems Manager (SSM) Policy
**Purpose:** Secure remote access without SSH keys

**Permissions:**
- Session Manager access
- Patch management
- Run commands remotely

**Benefits:**
- No need to open SSH port 22
- Audit trail of all sessions
- No SSH key management

#### 5. Secrets Manager Policy
**Purpose:** Retrieve database credentials securely

**Permissions:**
- `secretsmanager:GetSecretValue` - Retrieve secrets
- `secretsmanager:DescribeSecret` - Get secret metadata

**Scope:** Limited to secrets under `${instance_name}/*`

#### 6. AWS Managed Policies
- `AmazonSSMManagedInstanceCore` - Full SSM functionality
- `CloudWatchAgentServerPolicy` - CloudWatch agent operations

## RDS IAM Configuration

### IAM Role: `rds-enhanced-monitoring-role`

**Purpose:** Enables RDS Enhanced Monitoring for detailed performance metrics

**Permissions:**
- AWS managed policy: `AmazonRDSEnhancedMonitoringRole`

**Monitoring Interval:** 60 seconds

**Metrics Provided:**
- CPU utilization
- Memory usage
- Disk I/O
- Network traffic
- Process list

### IAM Role: `rds-s3-backup-role`

**Purpose:** Allows RDS to backup data to S3

**Permissions:**
- `s3:PutObject` - Upload backups
- `s3:GetObject` - Retrieve backups
- `s3:ListBucket` - List backup files
- `s3:DeleteObject` - Remove old backups

**Scope:** Limited to `${db_identifier}-backups` bucket

### IAM Database Authentication

**Status:** Enabled

**Benefits:**
- No password management
- Automatic credential rotation every 15 minutes
- Centralized access control via IAM
- Audit trail in CloudTrail

## Security Best Practices Implemented

✅ **Least Privilege Principle**
- Each policy grants only necessary permissions
- Resource-level restrictions where possible
- No wildcard (*) resources except where required

✅ **No Hardcoded Credentials**
- Database passwords retrieved from Secrets Manager
- IAM authentication for database access
- Instance profile provides temporary credentials

✅ **Audit and Monitoring**
- CloudWatch Logs for application and database
- Enhanced Monitoring for RDS performance
- CloudTrail logs all IAM actions

✅ **Secure Remote Access**
- Systems Manager Session Manager instead of SSH
- No need to expose port 22
- All sessions logged and auditable

✅ **Encryption**
- RDS storage encrypted at rest
- Secrets Manager encrypts credentials
- TLS for data in transit

## Using IAM Database Authentication

### From EC2 Instance

1. **Install AWS CLI and MySQL client:**
   ```bash
   sudo apt-get install -y awscli mysql-client
   ```

2. **Generate authentication token:**
   ```bash
   TOKEN=$(aws rds generate-db-auth-token \
     --hostname your-rds-endpoint.rds.amazonaws.com \
     --port 3306 \
     --username admin \
     --region us-east-1)
   ```

3. **Connect using the token:**
   ```bash
   mysql -h your-rds-endpoint.rds.amazonaws.com \
     -P 3306 \
     -u admin \
     --password="$TOKEN" \
     --ssl-ca=/path/to/rds-ca-bundle.pem
   ```

### In Application Code (Python Example)

```python
import boto3
import pymysql

def get_db_connection():
    client = boto3.client('rds', region_name='us-east-1')
    
    token = client.generate_db_auth_token(
        DBHostname='your-rds-endpoint.rds.amazonaws.com',
        Port=3306,
        DBUsername='admin'
    )
    
    connection = pymysql.connect(
        host='your-rds-endpoint.rds.amazonaws.com',
        user='admin',
        password=token,
        database='mydb',
        ssl={'ssl': True}
    )
    
    return connection
```

### In Application Code (Java Example)

```java
import com.amazonaws.auth.DefaultAWSCredentialsProviderChain;
import com.amazonaws.services.rds.auth.GetIamAuthTokenRequest;
import com.amazonaws.services.rds.auth.RdsIamAuthTokenGenerator;

public class RDSConnection {
    public static String generateAuthToken() {
        RdsIamAuthTokenGenerator generator = RdsIamAuthTokenGenerator.builder()
            .credentials(new DefaultAWSCredentialsProviderChain())
            .region("us-east-1")
            .build();
        
        return generator.getAuthToken(
            GetIamAuthTokenRequest.builder()
                .hostname("your-rds-endpoint.rds.amazonaws.com")
                .port(3306)
                .userName("admin")
                .build()
        );
    }
}
```

## Accessing Secrets Manager

### From EC2 Instance

```bash
# Retrieve database credentials
aws secretsmanager get-secret-value \
  --secret-id dev-server/db-credentials \
  --region us-east-1 \
  --query SecretString \
  --output text
```

### In Application Code

```python
import boto3
import json

def get_db_credentials():
    client = boto3.client('secretsmanager', region_name='us-east-1')
    
    response = client.get_secret_value(SecretId='dev-server/db-credentials')
    secret = json.loads(response['SecretString'])
    
    return {
        'host': secret['host'],
        'username': secret['username'],
        'password': secret['password'],
        'database': secret['database']
    }
```

## Using Systems Manager Session Manager

### Connect to EC2 without SSH

```bash
# Install Session Manager plugin first
# Then connect:
aws ssm start-session --target i-1234567890abcdef0
```

**Benefits:**
- No SSH keys needed
- No port 22 exposure
- All sessions logged
- Can be restricted by IAM policies

## Monitoring and Auditing

### View IAM Activity

```bash
# View CloudTrail logs for IAM actions
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::IAM::Role \
  --max-results 50
```

### View RDS Enhanced Monitoring

1. Go to RDS Console
2. Select your database instance
3. Click "Monitoring" tab
4. View detailed metrics

### View CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix /aws/

# View recent logs
aws logs tail /aws/ec2/application --follow
```

## Cost Considerations

- **Enhanced Monitoring:** ~$0.01 per instance per hour
- **Performance Insights:** Free for 7 days retention
- **CloudWatch Logs:** First 5GB free, then $0.50/GB
- **Secrets Manager:** $0.40 per secret per month + $0.05 per 10,000 API calls

## Troubleshooting

### EC2 Cannot Access RDS

1. Verify IAM role is attached:
   ```bash
   aws ec2 describe-instances --instance-ids i-xxx --query 'Reservations[0].Instances[0].IamInstanceProfile'
   ```

2. Check IAM policy permissions:
   ```bash
   aws iam get-role-policy --role-name ec2-app-server-role --policy-name rds-access
   ```

3. Verify RDS has IAM authentication enabled:
   ```bash
   aws rds describe-db-instances --db-instance-identifier mysql-db --query 'DBInstances[0].IAMDatabaseAuthenticationEnabled'
   ```

### Cannot Retrieve Secrets

1. Check IAM permissions for Secrets Manager
2. Verify secret exists and is in the correct region
3. Check secret name matches the pattern in IAM policy

### Session Manager Not Working

1. Verify SSM agent is running on EC2:
   ```bash
   sudo systemctl status amazon-ssm-agent
   ```

2. Check IAM role has SSM policies attached
3. Ensure EC2 has internet access or VPC endpoints for SSM

## Additional Security Recommendations

1. **Enable MFA for IAM users** accessing AWS Console
2. **Use AWS Organizations** for multi-account management
3. **Enable AWS Config** for compliance monitoring
4. **Set up AWS GuardDuty** for threat detection
5. **Use AWS Security Hub** for centralized security findings
6. **Implement VPC Flow Logs** for network monitoring
7. **Enable AWS CloudTrail** in all regions
8. **Regular IAM access reviews** using IAM Access Analyzer
9. **Implement AWS Backup** for automated backups
10. **Use AWS KMS** for encryption key management

## References

- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [RDS IAM Authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)
- [Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
