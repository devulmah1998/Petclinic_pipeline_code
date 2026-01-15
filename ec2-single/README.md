# Single EC2 Instance - 8GB RAM

Simple Terraform configuration to create one EC2 instance with 8GB RAM in us-east-1.

## Specifications

- **Instance Type**: t3.large
- **RAM**: 8GB
- **vCPUs**: 2
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 20GB encrypted GP3
- **Region**: us-east-1
- **Security**: SSH (22), HTTP (80), HTTPS (443)

## Usage

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

Required variables:
- `key_name` - Your AWS key pair name

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Get Connection Info

```bash
terraform output instance_public_ip
terraform output ssh_command
```

### 4. Connect to Instance

```bash
ssh -i your-key.pem ubuntu@<public-ip>
```

## Outputs

After deployment, you'll get:
- Instance ID
- Public IP address
- Public DNS name
- Security group ID
- SSH command

## Cost

- **t3.large**: ~$0.0832/hour (~$60/month)
- **Storage**: ~$2/month
- **Total**: ~$62/month

## Cleanup

```bash
terraform destroy
```

## Module Used

This configuration uses the official AWS EC2 Terraform module:
- Source: `terraform-aws-modules/ec2-instance/aws`
- Version: `~> 5.0`
- Documentation: https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws

## Security

- Security group allows SSH, HTTP, HTTPS
- Root volume is encrypted
- Uses latest Ubuntu 22.04 AMI from Canonical

## Customization

### Change Instance Size

Edit `main.tf`:
```hcl
instance_type = "t3.medium"  # 4GB RAM
instance_type = "t3.large"   # 8GB RAM (current)
instance_type = "t3.xlarge"  # 16GB RAM
```

### Change Region

Edit `terraform.tfvars`:
```hcl
aws_region = "us-west-2"
```

### Add More Ports

Edit `main.tf` security group:
```hcl
ingress {
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Custom port"
}
```
