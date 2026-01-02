# Multi-Region Jenkins Infrastructure with Terraform

## Overview

This Terraform project deploys a multi-region Jenkins infrastructure on AWS with VPC peering between **us-east-1** (master region) and **us-west-2** (worker region). The architecture supports a distributed Jenkins setup with high availability and cross-region connectivity.

## Architecture

### Infrastructure Components

**Master Region (us-east-1):**
- VPC with CIDR `10.0.0.0/16`
- 2 Subnets across different Availability Zones (`10.0.1.0/24`, `10.0.2.0/24`)
- Internet Gateway for public internet access
- Application Load Balancer with security group (ports 80, 443)
- Jenkins Master instance with security group (port 8080, SSH)
- Route tables with internet and VPC peering routes

**Worker Region (us-west-2):**
- VPC with CIDR `192.168.0.0/16`
- 1 Subnet (`192.168.1.0/24`)
- Internet Gateway for public internet access
- Jenkins Worker instance with security group (SSH)
- Route tables with internet and VPC peering routes

**VPC Peering:**
- Established between us-east-1 and us-west-2
- Enables private communication between Jenkins master and workers
- Bidirectional routing configured

## Prerequisites

### Required Tools
- **Terraform** >= 0.12.0 (recommended: latest version)
- **AWS CLI** configured with appropriate credentials
- **Git** (for cloning the repository)

### AWS Requirements
1. **AWS Account** with appropriate permissions
2. **IAM User/Role** with the following permissions:
   - EC2 (VPC, Subnets, Security Groups, Instances)
   - S3 (for state file backend)
   - VPC Peering
3. **S3 Bucket** for Terraform state file storage (must be created beforehand)
4. **AWS CLI Profile** configured (default or custom)

### AWS IAM Permissions Summary
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
```

## Configuration

### Step 1: Configure Backend

Edit `backend.tf` and update the S3 bucket name:

```hcl
backend "s3" {
  region  = "us-east-1"
  profile = "default"
  key     = "terraformstatefile"
  bucket  = "your-terraform-state-bucket-name"  # Update this
}
```

**Important:** The S3 bucket must exist before running Terraform and have versioning enabled for state locking.

### Step 2: Configure Variables

Edit `variables.tf` or create a `terraform.tfvars` file:

```hcl
profile        = "default"           # Your AWS CLI profile
region-master  = "us-east-1"        # Master region
region-worker  = "us-west-2"        # Worker region
```

### Step 3: Set Your External IP

You'll need to add your external IP address for SSH access. Add this to `variables.tf`:

```hcl
variable "external_ip" {
  type        = string
  description = "Your public IP address for SSH access"
  default     = "YOUR.PUBLIC.IP.ADDRESS/32"
}
```

To find your public IP:
```bash
curl ifconfig.me
```

## Installation & Deployment

### Step 1: Initialize Terraform

Initialize the Terraform working directory and download required providers:

```bash
terraform init
```

**Expected Output:**
```
Initializing the backend...
Successfully configured the backend "s3"!
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 2: Validate Configuration

Validate the Terraform configuration files:

```bash
terraform validate
```

### Step 3: Plan the Deployment

Review the execution plan to see what resources will be created:

```bash
terraform plan
```

**Optional:** Save the plan to a file:
```bash
terraform plan -out=tfplan
```

### Step 4: Apply the Configuration

Deploy the infrastructure:

```bash
terraform apply
```

Review the plan and type `yes` when prompted.

**With saved plan:**
```bash
terraform apply tfplan
```

**Auto-approve (use with caution):**
```bash
terraform apply -auto-approve
```

### Step 5: Verify Deployment

Check the created resources:

```bash
# List all resources in state
terraform state list

# Show specific resource details
terraform show
```

## Usage

### Accessing Resources

**Jenkins Master (us-east-1):**
- Access via Load Balancer DNS (output after apply)
- Direct SSH access from your IP

**Jenkins Worker (us-west-2):**
- SSH access from your IP
- Private communication with master via VPC peering

### Viewing Outputs

Define outputs in a new `outputs.tf` file:

```hcl
output "vpc_master_id" {
  value = aws_vpc.vpc_master.id
}

output "vpc_worker_id" {
  value = aws_vpc.vpc_master_oregon.id
}

output "peering_connection_id" {
  value = aws_vpc_peering_connection.useast1-uswest2.id
}
```

Then run:
```bash
terraform output
```

## State Management

### View State
```bash
terraform show
terraform state list
```

### Remote State
The state file is stored remotely in S3 for:
- **Collaboration:** Multiple team members can work on the same infrastructure
- **Security:** State files contain sensitive data
- **Locking:** Prevents concurrent modifications
- **Versioning:** Track changes over time

### State Operations
```bash
# Refresh state
terraform refresh

# Import existing resource
terraform import aws_vpc.vpc_master vpc-xxxxxxxxx

# Remove resource from state (doesn't destroy)
terraform state rm aws_vpc.vpc_master
```

## Maintenance

### Updating Infrastructure

1. Modify the `.tf` files as needed
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes

### Resource Targeting

Apply changes to specific resources:
```bash
terraform apply -target=aws_vpc.vpc_master
```

### Workspace Management

Use workspaces for multiple environments:
```bash
# Create new workspace
terraform workspace new dev

# List workspaces
terraform workspace list

# Switch workspace
terraform workspace select prod
```

## Destroying Infrastructure

### Destroy All Resources
```bash
terraform destroy
```

### Destroy Specific Resources
```bash
terraform destroy -target=aws_vpc.vpc_master
```

### Before Destroying
- Backup important data
- Review the destruction plan
- Ensure you have the correct workspace selected

## Troubleshooting

### Common Issues

**1. Backend Initialization Failed**
```
Error: Failed to get existing workspaces: S3 bucket does not exist
```
**Solution:** Create the S3 bucket specified in `backend.tf`

**2. Invalid Credentials**
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```
**Solution:** Configure AWS CLI with `aws configure`

**3. Resource Already Exists**
```
Error: VPC already exists
```
**Solution:** Import the existing resource or use a different CIDR block

**4. VPC Peering Failed**
```
Error: Error accepting VPC Peering Connection
```
**Solution:** Ensure both VPCs exist and IAM permissions are correct

**5. State Lock Issues**
```
Error: Error acquiring the state lock
```
**Solution:** Check for hung processes or manually remove lock from DynamoDB (if configured)

### Debug Mode

Enable detailed logging:
```bash
export TF_LOG=DEBUG
terraform apply
```

Log levels: TRACE, DEBUG, INFO, WARN, ERROR

### Verify AWS Configuration
```bash
aws sts get-caller-identity
aws s3 ls s3://your-bucket-name
```

## Security Best Practices

1. **State File Security:**
   - Enable S3 bucket encryption
   - Enable S3 bucket versioning
   - Restrict bucket access with IAM policies
   - Use DynamoDB for state locking

2. **Credential Management:**
   - Never commit AWS credentials to version control
   - Use IAM roles for EC2 instances
   - Rotate access keys regularly
   - Use AWS Secrets Manager for sensitive data

3. **Network Security:**
   - Restrict SSH access to your IP only
   - Use security groups for least-privilege access
   - Enable VPC Flow Logs
   - Use private subnets for internal resources

4. **Code Security:**
   - Add `.terraform/` to `.gitignore`
   - Add `*.tfstate*` to `.gitignore`
   - Add `*.tfvars` with sensitive data to `.gitignore`
   - Use `terraform.tfvars.example` for templates

## File Structure

```
terraform_project/
├── README.md                  # This file
├── backend.tf                 # Backend configuration for state
├── providers.tf               # AWS provider configuration
├── variables.tf               # Variable definitions
├── terraform.tfvars          # Variable values (create this, add to .gitignore)
├── networks.tf               # VPC, subnets, peering configuration
├── security_group.tf         # Security group rules
├── .gitignore                # Git ignore file
└── .terraform/               # Terraform working directory (ignored)
```

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [AWS VPC Peering Guide](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html)

## Support and Contribution

For issues or questions:
1. Check the troubleshooting section
2. Review Terraform and AWS documentation
3. Check AWS service quotas and limits
4. Verify IAM permissions

## License

[Specify your license here]

## Author

Ola - Customer Success Engineer at Hedgeserv
