# Terraform Interview Questions - Comprehensive Guide

## Table of Contents
1. [Terraform Fundamentals](#1-terraform-fundamentals)
2. [State Management](#2-state-management)
3. [Providers and Resources](#3-providers-and-resources)
4. [Variables and Outputs](#4-variables-and-outputs)
5. [Modules](#5-modules)
6. [Functions and Expressions](#6-functions-and-expressions)
7. [Backend Configuration](#7-backend-configuration)
8. [Workspaces](#8-workspaces)
9. [Import and Data Sources](#9-import-and-data-sources)
10. [Advanced Topics](#10-advanced-topics)
11. [Security and Best Practices](#11-security-and-best-practices)
12. [Troubleshooting and Debugging](#12-troubleshooting-and-debugging)
13. [Terraform Cloud and Enterprise](#13-terraform-cloud-and-enterprise)
14. [Real-World Scenarios](#14-real-world-scenarios)

---

## 1. Terraform Fundamentals

### Q1: What is Terraform and how does it differ from other IaC tools like CloudFormation or Ansible?
**Answer:**
Terraform is an Infrastructure as Code (IaC) tool that allows you to define and provision infrastructure using declarative configuration files. 

**Key Differences:**
- **Multi-Cloud:** Terraform is cloud-agnostic (AWS, Azure, GCP, etc.), while CloudFormation is AWS-only
- **Declarative vs. Procedural:** Terraform and CloudFormation are declarative (define desired state), while Ansible is procedural (define steps)
- **State Management:** Terraform maintains state files to track infrastructure, CloudFormation uses stack management, Ansible is stateless
- **Provider Ecosystem:** Terraform has 1000+ providers for various services
- **Immutable Infrastructure:** Terraform focuses on infrastructure provisioning, Ansible on configuration management

### Q2: Explain the Terraform workflow (Write, Plan, Apply).
**Answer:**
1. **Write:** Define infrastructure in `.tf` files using HCL (HashiCorp Configuration Language)
2. **Plan:** Run `terraform plan` to preview changes without modifying infrastructure
3. **Apply:** Run `terraform apply` to execute the plan and provision/modify infrastructure
4. **Destroy (optional):** Run `terraform destroy` to remove infrastructure

**Additional Steps:**
- `terraform init`: Initialize working directory and download providers
- `terraform validate`: Check configuration syntax
- `terraform fmt`: Format code to canonical style

### Q3: What is HCL (HashiCorp Configuration Language)?
**Answer:**
HCL is a structured configuration language designed for Terraform. It's human-readable and supports:
- **Blocks:** Define resources, providers, variables
- **Arguments:** Key-value pairs within blocks
- **Expressions:** References, functions, operators
- **Comments:** `#`, `//`, or `/* */`

**Example:**
```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer-${var.environment}"
  }
}
```

### Q4: What are the main Terraform commands and their purposes?
**Answer:**
- `terraform init`: Initialize directory, download providers
- `terraform plan`: Preview changes
- `terraform apply`: Apply changes
- `terraform destroy`: Destroy all resources
- `terraform validate`: Validate configuration syntax
- `terraform fmt`: Format code
- `terraform show`: Show current state or plan
- `terraform output`: Display output values
- `terraform state`: Advanced state management
- `terraform import`: Import existing infrastructure
- `terraform taint`: Mark resource for recreation
- `terraform refresh`: Update state with real infrastructure
- `terraform graph`: Generate dependency graph

### Q5: What is the difference between `terraform plan` and `terraform apply`?
**Answer:**
- **terraform plan:**
  - Dry-run that shows what will change
  - No modifications to infrastructure
  - Creates execution plan
  - Safe to run anytime
  - Can save plan to file: `terraform plan -out=tfplan`

- **terraform apply:**
  - Executes changes to infrastructure
  - Can use saved plan or create new one
  - Prompts for confirmation (unless `-auto-approve`)
  - Updates state file
  - Makes actual API calls to providers

---

## 2. State Management

### Q6: What is Terraform state and why is it important?
**Answer:**
Terraform state is a JSON file (`terraform.tfstate`) that maps real-world resources to your configuration and tracks metadata.

**Importance:**
- **Resource Tracking:** Knows what resources exist and their attributes
- **Performance:** Caches resource attributes to avoid API calls
- **Dependency Management:** Tracks resource dependencies
- **Metadata Storage:** Stores resource metadata and provider configuration
- **Concurrency Control:** Enables state locking to prevent conflicts

**State Contents:**
- Resource IDs and attributes
- Resource dependencies
- Provider configuration
- Outputs
- Terraform version

### Q7: What are the differences between local and remote state storage?
**Answer:**

**Local State:**
- Stored in local `terraform.tfstate` file
- Simple for individual use
- Risk of loss or corruption
- No collaboration support
- No state locking
- Contains sensitive data in plain text

**Remote State:**
- Stored in remote backend (S3, Azure Storage, Terraform Cloud)
- Enables team collaboration
- Supports state locking
- Encrypted at rest
- Versioning and backup
- Shared access with proper permissions

**Best Practice:** Always use remote state for production environments.

### Q8: How do you configure remote state in S3 with state locking?
**Answer:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Optional: Use assume_role for cross-account access
    role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
  }
}
```

**State Locking with DynamoDB:**
1. Create DynamoDB table with primary key `LockID` (String)
2. Table must have billing mode or provisioned capacity
3. Terraform automatically acquires/releases locks

**Setup:**
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Q9: What is state locking and why is it necessary?
**Answer:**
State locking prevents multiple users from simultaneously modifying infrastructure, which could cause:
- State file corruption
- Resource conflicts
- Incomplete operations
- Lost updates

**How It Works:**
1. Terraform acquires lock before operations
2. Other operations wait or fail if lock exists
3. Lock released after operation completes

**Supported Backends:**
- S3 with DynamoDB
- Terraform Cloud
- Azure Storage
- GCS
- Consul

**Override Lock (Emergency):**
```bash
terraform force-unlock LOCK_ID
```

### Q10: How do you handle sensitive data in Terraform state?
**Answer:**

**1. Remote State Encryption:**
```hcl
backend "s3" {
  encrypt = true
  kms_key_id = "arn:aws:kms:region:account:key/id"
}
```

**2. Mark Outputs as Sensitive:**
```hcl
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}
```

**3. Use Secret Management:**
```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

**4. Restrict State File Access:**
- S3 bucket policies
- IAM roles and permissions
- VPC endpoints for private access

**5. State File Security:**
- Never commit `.tfstate` to version control
- Enable versioning for state bucket
- Use audit logging (CloudTrail for S3)

### Q11: Explain terraform state commands and their use cases.
**Answer:**

```bash
# List all resources in state
terraform state list

# Show details of specific resource
terraform state show aws_instance.web

# Move resource to different address
terraform state mv aws_instance.web aws_instance.web_server

# Remove resource from state (doesn't destroy)
terraform state rm aws_instance.web

# Pull remote state to local
terraform state pull

# Push local state to remote
terraform state push

# Replace provider in state
terraform state replace-provider hashicorp/aws registry.acme.com/aws
```

**Use Cases:**
- **list/show:** Inspect state without modifying
- **mv:** Refactor resource names or move to modules
- **rm:** Remove resources without destroying (manual cleanup)
- **pull/push:** Debug or recover state
- **replace-provider:** Migrate to different provider source

---

## 3. Providers and Resources

### Q12: What is a Terraform provider and how do you configure multiple providers?
**Answer:**
A provider is a plugin that enables Terraform to interact with APIs of cloud platforms, SaaS services, and other platforms.

**Single Provider:**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

**Multiple Provider Instances (Aliases):**
```hcl
provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

provider "aws" {
  region = "us-west-2"
  alias  = "backup"
}

resource "aws_instance" "primary" {
  provider = aws.primary
  # configuration
}

resource "aws_instance" "backup" {
  provider = aws.backup
  # configuration
}
```

### Q13: What is the difference between a resource and a data source?
**Answer:**

**Resource:**
- Creates, updates, or deletes infrastructure
- Defined with `resource` block
- Managed by Terraform
- Has lifecycle management
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t2.micro"
}
```

**Data Source:**
- Reads existing infrastructure
- Defined with `data` block
- Read-only, not managed by Terraform
- Used to fetch information
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

### Q14: Explain resource lifecycle meta-arguments (create_before_destroy, prevent_destroy, ignore_changes).
**Answer:**

**1. create_before_destroy:**
Create replacement before destroying original (useful for zero-downtime)
```hcl
resource "aws_instance" "web" {
  # configuration
  
  lifecycle {
    create_before_destroy = true
  }
}
```

**2. prevent_destroy:**
Prevent accidental deletion of critical resources
```hcl
resource "aws_db_instance" "production" {
  # configuration
  
  lifecycle {
    prevent_destroy = true
  }
}
```

**3. ignore_changes:**
Ignore changes to specific attributes (useful for auto-scaling, tags)
```hcl
resource "aws_instance" "web" {
  ami = "ami-12345"
  
  lifecycle {
    ignore_changes = [
      tags,
      user_data,
    ]
  }
}
```

**4. replace_triggered_by:**
Replace resource when another resource changes
```hcl
resource "aws_instance" "web" {
  lifecycle {
    replace_triggered_by = [
      aws_security_group.web.id
    ]
  }
}
```

### Q15: What is the `depends_on` meta-argument and when should you use it?
**Answer:**
`depends_on` creates explicit dependencies between resources when implicit dependencies aren't sufficient.

**When to Use:**
- Resource depends on another but doesn't reference its attributes
- Ordering matters but no direct attribute reference
- Module dependencies
- Data sources that need resources to exist first

**Example:**
```hcl
resource "aws_iam_role" "example" {
  name = "example-role"
  # configuration
}

resource "aws_iam_role_policy" "example" {
  role = aws_iam_role.example.name
  # Implicit dependency via reference
}

resource "aws_instance" "example" {
  # This instance needs the IAM role to exist
  # but doesn't directly reference it
  
  depends_on = [aws_iam_role.example]
}
```

**Caveat:** Use sparingly as Terraform automatically handles most dependencies.

---

## 4. Variables and Outputs

### Q16: Explain the different types of Terraform variables and how to define them.
**Answer:**

**Variable Types:**
1. **String**
2. **Number**
3. **Bool**
4. **List**
5. **Map**
6. **Object**
7. **Set**
8. **Tuple**
9. **Any**

**Definitions:**
```hcl
# String
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

# Number
variable "instance_count" {
  type    = number
  default = 3
}

# Bool
variable "enable_monitoring" {
  type    = bool
  default = true
}

# List
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# Map
variable "instance_types" {
  type = map(string)
  default = {
    dev  = "t2.micro"
    prod = "t2.large"
  }
}

# Object
variable "server_config" {
  type = object({
    instance_type = string
    volume_size   = number
    monitoring    = bool
  })
  default = {
    instance_type = "t2.micro"
    volume_size   = 20
    monitoring    = true
  }
}

# Set (unique values only)
variable "security_group_ids" {
  type    = set(string)
  default = ["sg-123", "sg-456"]
}

# Tuple (ordered, mixed types)
variable "mixed_list" {
  type    = tuple([string, number, bool])
  default = ["example", 42, true]
}
```

### Q17: What are the different ways to pass variables to Terraform?
**Answer:**

**Priority Order (highest to lowest):**
1. `-var` command line flag
2. `-var-file` command line flag
3. `*.auto.tfvars` files (alphabetically)
4. `terraform.tfvars` file
5. Environment variables `TF_VAR_name`
6. Default value in variable definition

**Examples:**

**1. Command Line:**
```bash
terraform apply -var="region=us-west-2" -var="instance_count=5"
```

**2. Variable File:**
```bash
terraform apply -var-file="production.tfvars"
```

**3. terraform.tfvars:**
```hcl
region         = "us-east-1"
instance_count = 3
```

**4. Environment Variables:**
```bash
export TF_VAR_region="us-east-1"
export TF_VAR_instance_count=3
terraform apply
```

**5. Interactive Prompt:**
If no value provided, Terraform prompts during apply.

### Q18: What are output values and why are they useful?
**Answer:**
Output values expose information about your infrastructure for:
- Display after `terraform apply`
- Use in parent modules
- Share data between modules
- Integration with other tools

**Definition:**
```hcl
output "instance_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of web instance"
}

output "db_connection_string" {
  value     = "postgresql://${aws_db_instance.main.endpoint}/${aws_db_instance.main.database_name}"
  sensitive = true
}

output "instance_ids" {
  value = [for instance in aws_instance.web : instance.id]
}
```

**Usage:**
```bash
# View all outputs
terraform output

# View specific output
terraform output instance_ip

# JSON format
terraform output -json

# Use in scripts
INSTANCE_IP=$(terraform output -raw instance_ip)
```

### Q19: How do you use validation rules for variables?
**Answer:**
```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  
  validation {
    condition     = can(regex("^t[2-3]\\.(micro|small|medium)$", var.instance_type))
    error_message = "Instance type must be t2 or t3 family: micro, small, or medium."
  }
}

variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cidr_block" {
  type = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "port" {
  type = number
  
  validation {
    condition     = var.port > 0 && var.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}
```

### Q20: What is the difference between local values and variables?
**Answer:**

**Variables:**
- Input parameters defined by users
- Can have defaults
- Can be overridden
- Used for configuration flexibility
```hcl
variable "environment" {
  type = string
}
```

**Local Values:**
- Computed values within module
- Cannot be overridden
- Simplify expressions
- Reduce repetition
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  # Complex computations
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_instance" "web" {
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-web"
    }
  )
}
```

---

## 5. Modules

### Q21: What are Terraform modules and why should you use them?
**Answer:**
Modules are containers for multiple resources that are used together. They enable:
- **Reusability:** Write once, use multiple times
- **Organization:** Group related resources
- **Abstraction:** Hide complexity
- **Encapsulation:** Clear interfaces
- **Versioning:** Track module changes
- **Sharing:** Use community modules

**Module Structure:**
```
modules/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── ec2/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Q22: How do you create and use a custom module?
**Answer:**

**Module Definition (modules/vpc/main.tf):**
```hcl
variable "cidr_block" {
  type = string
}

variable "name" {
  type = string
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  
  tags = {
    Name = var.name
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}
```

**Module Usage (root main.tf):**
```hcl
module "vpc_production" {
  source = "./modules/vpc"
  
  cidr_block = "10.0.0.0/16"
  name       = "production-vpc"
}

module "vpc_development" {
  source = "./modules/vpc"
  
  cidr_block = "10.1.0.0/16"
  name       = "development-vpc"
}

# Reference module outputs
output "prod_vpc_id" {
  value = module.vpc_production.vpc_id
}
```

### Q23: What is the difference between root modules and child modules?
**Answer:**

**Root Module:**
- Top-level directory where Terraform commands run
- Contains `terraform apply` execution
- Can call child modules
- Has no parent
- Usually represents complete infrastructure

**Child Module:**
- Called by root or other modules
- Has parent module
- Receives inputs via variables
- Returns outputs
- Can be reused multiple times

**Example:**
```
project/
├── main.tf          # Root module
├── variables.tf     # Root module
├── outputs.tf       # Root module
└── modules/
    └── vpc/         # Child module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Q24: How do you use public modules from the Terraform Registry?
**Answer:**

**Registry Modules:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

**Git Repositories:**
```hcl
module "consul" {
  source = "github.com/hashicorp/consul-terraform-module"
}

# Specific branch/tag
module "consul" {
  source = "github.com/hashicorp/consul-terraform-module?ref=v1.0.0"
}
```

**Version Constraints:**
```hcl
version = "~> 5.0"      # >= 5.0, < 6.0
version = ">= 5.0, < 6.0"
version = "5.0.0"       # Exact version
```

### Q25: How do you pass data between modules?
**Answer:**

**Module Outputs → Parent Inputs:**
```hcl
# modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.private[*].id
}

# root/main.tf
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}

module "ec2" {
  source = "./modules/ec2"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.subnet_ids
}
```

**Implicit Dependencies:**
When you reference a module's output, Terraform creates an implicit dependency.

**Explicit Dependencies:**
```hcl
module "database" {
  source = "./modules/rds"
  
  depends_on = [module.vpc]
}
```

---

## 6. Functions and Expressions

### Q26: Explain commonly used Terraform built-in functions.
**Answer:**

**String Functions:**
```hcl
# format
name = format("server-%03d", count.index)

# join
cidr_blocks = join(",", var.subnet_cidrs)

# split
parts = split("-", "web-server-01")

# lower/upper
region_lower = lower(var.region)

# replace
sanitized = replace(var.name, "_", "-")

# substr
short_id = substr(aws_instance.web.id, 0, 8)
```

**Collection Functions:**
```hcl
# length
subnet_count = length(var.subnets)

# element
az = element(data.aws_availability_zones.available.names, count.index)

# concat
all_cidrs = concat(var.public_cidrs, var.private_cidrs)

# merge
tags = merge(var.common_tags, var.specific_tags)

# contains
has_prod = contains(var.environments, "prod")

# keys/values
env_names = keys(var.environments)
```

**Numeric Functions:**
```hcl
# min/max
max_size = max(5, 10, 3)

# ceil/floor
instances = ceil(var.capacity / 10.0)
```

**Encoding Functions:**
```hcl
# base64encode/base64decode
user_data = base64encode(file("script.sh"))

# jsonencode/jsondecode
policy = jsonencode({
  Version = "2012-10-17"
  Statement = [...]
})
```

**Filesystem Functions:**
```hcl
# file
user_data = file("${path.module}/init.sh")

# templatefile
user_data = templatefile("${path.module}/init.tpl", {
  hostname = var.hostname
  port     = var.port
})
```

**Type Conversion:**
```hcl
# tostring/tonumber/tobool
port_str = tostring(var.port)
count_num = tonumber(var.count_str)

# tolist/toset/tomap
unique_ids = toset(var.instance_ids)
```

### Q27: What are Terraform expressions and how do you use them?
**Answer:**

**For Expressions:**
```hcl
# List to list
instance_ids = [for instance in aws_instance.web : instance.id]

# List to map
instance_map = {
  for instance in aws_instance.web :
  instance.id => instance.private_ip
}

# Filtering
large_instances = [
  for instance in aws_instance.web :
  instance.id
  if instance.instance_type == "t2.large"
]

# Nested
subnet_cidrs = [
  for az in data.aws_availability_zones.available.names :
  cidrsubnet(var.vpc_cidr, 8, index(data.aws_availability_zones.available.names, az))
]
```

**Conditional Expressions:**
```hcl
instance_type = var.environment == "prod" ? "t2.large" : "t2.micro"

ingress_rules = var.enable_https ? [
  {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
  }
] : []
```

**Splat Expressions:**
```hcl
# Get all IDs
instance_ids = aws_instance.web[*].id

# Attribute-only splat
private_ips = aws_instance.web[*].private_ip

# Full splat with attributes
instance_info = aws_instance.web[*].{
  id = id
  ip = private_ip
}
```

**Dynamic Blocks:**
```hcl
resource "aws_security_group" "main" {
  name = "main-sg"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

### Q28: How do you use count and for_each meta-arguments?
**Answer:**

**Count:**
Create multiple similar resources with index
```hcl
resource "aws_instance" "web" {
  count = 3
  
  ami           = var.ami_id
  instance_type = "t2.micro"
  
  tags = {
    Name = "web-${count.index}"
  }
}

# Reference specific instance
output "first_instance_ip" {
  value = aws_instance.web[0].private_ip
}

# Reference all instances
output "all_instance_ips" {
  value = aws_instance.web[*].private_ip
}
```

**For_each:**
Create resources from map or set
```hcl
variable "instances" {
  type = map(object({
    instance_type = string
    ami           = string
  }))
  default = {
    web = {
      instance_type = "t2.micro"
      ami           = "ami-12345"
    }
    db = {
      instance_type = "t2.small"
      ami           = "ami-67890"
    }
  }
}

resource "aws_instance" "servers" {
  for_each = var.instances
  
  instance_type = each.value.instance_type
  ami           = each.value.ami
  
  tags = {
    Name = each.key
  }
}

# Reference specific resource
output "web_instance_ip" {
  value = aws_instance.servers["web"].private_ip
}
```

**Count vs For_each:**
- **Count:** Use when creating identical resources (order matters)
- **For_each:** Use when creating resources with different configs (order doesn't matter)
- **For_each advantage:** Removing an item doesn't affect others
- **Count limitation:** Removing middle item causes recreation

---

## 7. Backend Configuration

### Q29: What are Terraform backends and what types are available?
**Answer:**
Backends determine where Terraform stores state and how operations are executed.

**Backend Types:**

**1. Local (Default):**
```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

**2. S3:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**3. Azure Storage:**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

**4. Google Cloud Storage:**
```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "prod"
  }
}
```

**5. Terraform Cloud:**
```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "my-workspace"
    }
  }
}
```

**6. Consul:**
```hcl
terraform {
  backend "consul" {
    address = "consul.example.com"
    path    = "terraform/state"
  }
}
```

### Q30: How do you migrate state from one backend to another?
**Answer:**

**Steps:**
1. **Update backend configuration**
2. **Run terraform init with -migrate-state flag**
3. **Verify new backend**
4. **Remove old state (optional)**

**Example: Local to S3 Migration:**

**Step 1:** Current local backend
```hcl
# No backend block or:
terraform {
  backend "local" {}
}
```

**Step 2:** Add S3 backend
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

**Step 3:** Migrate
```bash
terraform init -migrate-state
```

**Output:**
```
Initializing the backend...
Terraform detected that the backend type changed from "local" to "s3".

Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes
```

**Step 4:** Verify
```bash
terraform state list
aws s3 ls s3://my-terraform-state/prod/
```

### Q31: What is partial backend configuration and when would you use it?
**Answer:**
Partial configuration allows you to omit some backend settings from code and provide them via:
- Command line flags
- File
- Environment variables

**Use Cases:**
- Different backends per environment
- Sensitive credentials
- CI/CD pipelines
- Multi-tenant setups

**backend.tf:**
```hcl
terraform {
  backend "s3" {
    # Partial configuration - bucket and region omitted
    key     = "terraform.tfstate"
    encrypt = true
  }
}
```

**Option 1: Command Line:**
```bash
terraform init \
  -backend-config="bucket=my-state-bucket" \
  -backend-config="region=us-east-1"
```

**Option 2: Backend Config File:**
```hcl
# prod.backend.hcl
bucket = "prod-terraform-state"
region = "us-east-1"
```

```bash
terraform init -backend-config=prod.backend.hcl
```

**Option 3: Environment Variables:**
```bash
export TF_CLI_ARGS_init="-backend-config=bucket=my-state-bucket -backend-config=region=us-east-1"
terraform init
```

---

## 8. Workspaces

### Q32: What are Terraform workspaces and when should you use them?
**Answer:**
Workspaces allow multiple state files for the same configuration, useful for managing multiple environments.

**Commands:**
```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new dev

# Switch workspace
terraform workspace select prod

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete staging
```

**Usage in Code:**
```hcl
resource "aws_instance" "web" {
  instance_type = terraform.workspace == "prod" ? "t2.large" : "t2.micro"
  
  tags = {
    Name        = "web-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
```

**State File Structure:**
```
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

**When to Use:**
- **Yes:** Testing, temporary environments, simple multi-environment setups
- **No:** Complex environments (use separate directories/repos instead)

**Limitations:**
- All workspaces share same backend config
- Not suitable for completely different configurations
- Limited visibility in state file naming

### Q33: What's the difference between workspaces and separate directories?
**Answer:**

**Workspaces:**
- Same configuration
- Different state files
- Switch with commands
- Shared variable files
- Good for similar environments

**Separate Directories:**
- Different configurations possible
- Separate variable files
- Clear separation
- Easier to manage permissions
- Better for production

**Best Practice:**
```
project/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
└── modules/
    └── vpc/
```

---

## 9. Import and Data Sources

### Q34: How do you import existing infrastructure into Terraform?
**Answer:**

**Process:**
1. Write resource configuration
2. Import resource into state
3. Verify and adjust configuration

**Example:**

**Step 1:** Write configuration
```hcl
resource "aws_instance" "imported" {
  ami           = "ami-12345"
  instance_type = "t2.micro"
  # ... other required arguments
}
```

**Step 2:** Import
```bash
terraform import aws_instance.imported i-1234567890abcdef0
```

**Step 3:** Verify
```bash
terraform plan
# Should show no changes if configuration matches
```

**Bulk Import:**
```bash
# Import multiple resources
terraform import aws_instance.web[0] i-1234567890abcdef0
terraform import aws_instance.web[1] i-1234567890abcdef1
terraform import aws_vpc.main vpc-12345
```

**For_each Import:**
```bash
terraform import 'aws_instance.servers["web"]' i-1234567890abcdef0
```

**Import Block (Terraform 1.5+):**
```hcl
import {
  to = aws_instance.imported
  id = "i-1234567890abcdef0"
}
```

### Q35: What's the difference between importing and using data sources?
**Answer:**

**Import:**
- Brings existing resources under Terraform management
- Modifies Terraform state
- Resource becomes managed by Terraform
- Can update/delete resource
- One-time operation

**Data Source:**
- Reads existing resource information
- Read-only, doesn't modify state
- Resource stays unmanaged
- Cannot modify resource
- Updates on each plan/apply

**Example:**

**Import (Manage Existing VPC):**
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```
```bash
terraform import aws_vpc.main vpc-12345
```

**Data Source (Reference Existing VPC):**
```hcl
data "aws_vpc" "main" {
  id = "vpc-12345"
}

resource "aws_subnet" "public" {
  vpc_id = data.aws_vpc.main.id
  # ...
}
```

---

## 10. Advanced Topics

### Q36: What is the Terraform graph and how is it used?
**Answer:**
Terraform creates a dependency graph to determine resource creation order.

**Generate Graph:**
```bash
# DOT format
terraform graph

# Visualize with Graphviz
terraform graph | dot -Tpng > graph.png

# Only resources
terraform graph -type=plan

# After refresh
terraform graph -type=plan-refresh-only
```

**Dependencies:**
- **Implicit:** Via attribute references
- **Explicit:** Via `depends_on`

**Execution:**
- Parallel creation where possible
- Respects dependencies
- Optimizes for speed

### Q37: How does Terraform handle resource dependencies and parallel execution?
**Answer:**

**Dependency Detection:**
```hcl
# Implicit dependency (vpc_id references)
resource "aws_subnet" "main" {
  vpc_id = aws_vpc.main.id  # Depends on vpc
}

# Explicit dependency
resource "aws_instance" "web" {
  depends_on = [aws_iam_role.instance_role]
}
```

**Parallel Execution:**
- Default: 10 parallel operations
- Configurable: `terraform apply -parallelism=20`
- Independent resources created simultaneously
- Dependent resources wait

**Example:**
```
VPC → [Subnet1, Subnet2] → [Instance1, Instance2]
```
- Subnet1 and Subnet2 created in parallel
- Both instances wait for respective subnets

### Q38: What are provisioners and why should they be avoided?
**Answer:**
Provisioners run scripts on resources after creation/destruction.

**Types:**
1. **local-exec:** Runs locally
2. **remote-exec:** Runs on remote resource
3. **file:** Copies files to remote resource

**Example:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t2.micro"
  
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}
```

**Why Avoid:**
- Not declarative
- State tracking issues
- Error handling complexity
- Not idempotent
- Breaks Terraform's model

**Alternatives:**
- User data / Cloud-init
- Configuration management (Ansible, Chef)
- Custom AMIs / Container images
- AWS Systems Manager
- Packer for image building

**When to Use:**
- Last resort only
- Bootstrapping configuration management
- Temporary workarounds

### Q39: Explain Terraform's refresh behavior and the -refresh-only flag.
**Answer:**

**Refresh:**
- Compares real infrastructure to state
- Updates state with actual values
- Doesn't modify infrastructure
- Happens automatically during plan/apply

**Automatic Refresh:**
```bash
terraform plan  # Refreshes then plans
terraform apply # Refreshes then applies
```

**Disable Refresh:**
```bash
terraform plan -refresh=false
terraform apply -refresh=false
```

**Refresh-Only Mode:**
```bash
terraform apply -refresh-only
```
- Only updates state
- No infrastructure changes
- Useful for drift detection

**Manual Refresh:**
```bash
terraform refresh  # Updates state file
```

**Use Cases:**
- Detect manual changes
- Sync state with reality
- Troubleshooting
- After manual fixes

### Q40: What is the difference between terraform taint and terraform apply -replace?
**Answer:**

**terraform taint (Deprecated in 1.5+):**
```bash
terraform taint aws_instance.web
terraform apply  # Will recreate
```
- Marks resource for recreation
- Changes state file
- Next apply recreates resource

**terraform apply -replace (Preferred):**
```bash
terraform apply -replace="aws_instance.web"
```
- Doesn't modify state
- One-time operation
- Safer approach

**Differences:**
| Feature | taint | -replace |
|---------|-------|----------|
| State modification | Yes | No |
| Cancellable | No (must untaint) | Yes (don't apply) |
| Version | Deprecated in 1.5+ | Introduced in 0.15.2 |
| Safety | Less safe | Safer |

**Use Cases:**
- Rebuild corrupted resources
- Force updates
- Test disaster recovery
- Fix state issues

---

## 11. Security and Best Practices

### Q41: What are the security best practices for Terraform?
**Answer:**

**1. State File Security:**
- Enable encryption at rest
- Use remote backend with access controls
- Enable versioning
- Never commit to version control

**2. Credential Management:**
```hcl
# Bad
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

# Good - Use environment variables
provider "aws" {
  # Reads from AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
}

# Better - Use IAM roles
provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
  }
}

# Best - Use secrets manager
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "prod/db/credentials"
}
```

**3. .gitignore:**
```
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
.terraform.lock.hcl
override.tf
override.tf.json
*_override.tf
*_override.tf.json
crash.log
```

**4. Sensitive Data Handling:**
```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}

resource "aws_db_instance" "main" {
  password = var.db_password
  # Not visible in logs
}
```

**5. Least Privilege:**
```hcl
# Restrict Terraform IAM permissions
data "aws_iam_policy_document" "terraform" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc",
      "ec2:CreateSubnet"
    ]
    resources = ["*"]
  }
}
```

**6. Code Scanning:**
- tfsec
- Checkov
- Terrascan
- Sentinel (Terraform Enterprise)

**7. Review Process:**
- Peer review
- Automated testing
- Plan review before apply
- Change approval workflow

### Q42: How do you manage secrets in Terraform?
**Answer:**

**1. Environment Variables:**
```bash
export TF_VAR_db_password="secret123"
terraform apply
```

**2. External Secret Managers:**
```hcl
# AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}

# HashiCorp Vault
data "vault_generic_secret" "db_password" {
  path = "secret/database/password"
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db_password.data["password"]
}

# Azure Key Vault
data "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  key_vault_id = data.azurerm_key_vault.main.id
}
```

**3. Encrypted Files:**
```bash
# Encrypt with KMS
aws kms encrypt \
  --key-id alias/terraform \
  --plaintext fileb://secrets.txt \
  --output text \
  --query CiphertextBlob > secrets.txt.encrypted

# Use in Terraform
data "aws_kms_secrets" "secrets" {
  secret {
    name    = "db_password"
    payload = file("${path.module}/secrets.txt.encrypted")
  }
}
```

**4. SOPS (Secrets OPerationS):**
```bash
# Encrypt file
sops -e secrets.yaml > secrets.enc.yaml

# Use with Terraform
data "sops_file" "secrets" {
  source_file = "secrets.enc.yaml"
}

locals {
  db_password = data.sops_file.secrets.data["db_password"]
}
```

**Never Do:**
- Hardcode secrets
- Commit `.tfvars` with secrets
- Log sensitive values
- Store secrets in state (when avoidable)

### Q43: What is terraform fmt and terraform validate?
**Answer:**

**terraform fmt:**
Formats code to canonical style
```bash
# Format current directory
terraform fmt

# Format recursively
terraform fmt -recursive

# Check formatting without changes
terraform fmt -check

# Show diff
terraform fmt -diff
```

**Changes:**
- Indentation
- Spacing
- Alignment
- Sorting (some cases)

**terraform validate:**
Validates configuration syntax and logic
```bash
terraform validate

# With JSON output
terraform validate -json
```

**Checks:**
- Syntax errors
- Required arguments
- Type constraints
- Variable validations
- Resource configurations
- Provider requirements

**Example:**
```bash
$ terraform validate
Error: Unsupported argument

  on main.tf line 5, in resource "aws_instance" "web":
   5:   invalud_argument = "value"

An argument named "invalud_argument" is not expected here.
```

**CI/CD Integration:**
```yaml
# GitHub Actions
- name: Terraform Format
  run: terraform fmt -check -recursive

- name: Terraform Validate
  run: terraform validate
```

---

## 12. Troubleshooting and Debugging

### Q44: How do you troubleshoot Terraform errors?
**Answer:**

**1. Enable Debug Logging:**
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply
```

**Log Levels:**
- TRACE (most verbose)
- DEBUG
- INFO
- WARN
- ERROR

**2. Common Error Patterns:**

**Resource Already Exists:**
```
Error: Resource already exists
```
**Solution:** Import existing resource or remove from AWS

**State Lock:**
```
Error: Error acquiring state lock
```
**Solution:**
```bash
# Check lock info
terraform force-unlock LOCK_ID

# Or wait for lock to expire
```

**Timeout:**
```
Error: timeout while waiting for state
```
**Solution:**
```hcl
resource "aws_instance" "web" {
  # Increase timeout
  timeouts {
    create = "60m"
    delete = "60m"
  }
}
```

**Drift:**
```
Error: Resource has been modified outside Terraform
```
**Solution:**
```bash
terraform refresh
terraform plan  # Review changes
terraform apply # Reconcile
```

**3. Validation Steps:**
```bash
# Syntax
terraform validate

# Format
terraform fmt -check

# Linting
tflint

# Security
tfsec .
```

**4. State Inspection:**
```bash
terraform state show aws_instance.web
terraform state list
terraform show
```

**5. Plan Analysis:**
```bash
terraform plan -out=tfplan
terraform show tfplan
terraform show -json tfplan | jq
```

### Q45: What causes "Error: Provider configuration not present" and how do you fix it?
**Answer:**

**Cause:**
Resource references provider alias that doesn't exist or isn't configured.

**Error:**
```
Error: Provider configuration not present
│ 
│ To work with module.vpc.aws_subnet.private its original provider
│ configuration at provider["registry.terraform.io/hashicorp/aws"].us-west-2
│ is required, but it has been removed. This occurs when a provider
│ configuration is removed while objects created by that provider still exist
│ in the state.
```

**Solution 1: Add Missing Provider:**
```hcl
provider "aws" {
  region = "us-west-2"
  alias  = "us-west-2"
}
```

**Solution 2: Module Provider Passing:**
```hcl
# Parent module
provider "aws" {
  region = "us-west-2"
  alias  = "west"
}

module "vpc" {
  source = "./modules/vpc"
  
  providers = {
    aws = aws.west
  }
}
```

**Solution 3: Replace Provider:**
```bash
terraform state replace-provider \
  'provider["registry.terraform.io/hashicorp/aws"].us-west-2' \
  'provider["registry.terraform.io/hashicorp/aws"]'
```

### Q46: How do you recover from a corrupted or lost state file?
**Answer:**

**Prevention:**
- Use remote backend with versioning
- Regular backups
- State locking

**Recovery:**

**1. From Remote Backend Versions:**
```bash
# S3 with versioning
aws s3api list-object-versions \
  --bucket my-terraform-state \
  --prefix terraform.tfstate

# Restore specific version
aws s3api get-object \
  --bucket my-terraform-state \
  --key terraform.tfstate \
  --version-id VERSION_ID \
  terraform.tfstate
```

**2. From Local Backup:**
```bash
# Terraform creates backups
cp terraform.tfstate.backup terraform.tfstate
```

**3. Rebuild State:**
```bash
# Import all resources
terraform import aws_vpc.main vpc-12345
terraform import aws_subnet.public subnet-12345
# ... repeat for all resources

# Or use terraformer
terraformer import aws --resources=vpc,subnet --regions=us-east-1
```

**4. Use terraform-state-mover:**
```bash
# Automated state recovery tool
git clone https://github.com/terraform-aws-modules/terraform-state-mover
```

**5. Manual State Creation:**
```json
{
  "version": 4,
  "terraform_version": "1.0.0",
  "serial": 1,
  "lineage": "unique-id",
  "outputs": {},
  "resources": []
}
```

---

## 13. Terraform Cloud and Enterprise

### Q47: What is Terraform Cloud and how does it differ from open-source Terraform?
**Answer:**

**Terraform Cloud Features:**
- Remote state management
- Remote execution
- Private module registry
- Sentinel policy as code
- Cost estimation
- VCS integration
- Team collaboration
- Run history
- API driven workflows

**Differences:**

| Feature | Open Source | Cloud/Enterprise |
|---------|-------------|------------------|
| State storage | Local/S3/etc | Built-in |
| Execution | Local | Remote or local |
| Policies | No | Sentinel |
| Cost estimation | No | Yes |
| Team management | No | Yes |
| Private registry | No | Yes |
| Audit logs | No | Yes |
| SAML SSO | No | Enterprise only |

**Configuration:**
```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "my-workspace"
    }
  }
}
```

### Q48: What is Sentinel and how is it used for policy as code?
**Answer:**
Sentinel is a policy-as-code framework for Terraform Enterprise/Cloud.

**Policy Levels:**
- **Advisory:** Warning only
- **Soft Mandatory:** Can be overridden
- **Hard Mandatory:** Cannot be overridden

**Example Policy:**
```python
# enforce-mandatory-tags.sentinel
import "tfplan/v2" as tfplan

mandatory_tags = ["Environment", "Owner", "Project"]

# Find all EC2 instances
instances = filter tfplan.resource_changes as _, rc {
  rc.type is "aws_instance" and
  rc.mode is "managed" and
  (rc.change.actions contains "create" or
   rc.change.actions contains "update")
}

# Validate tags
validate_tags = rule {
  all instances as _, instance {
    all mandatory_tags as tag {
      instance.change.after.tags contains tag
    }
  }
}

main = rule {
  validate_tags
}
```

**sentinel.hcl:**
```hcl
policy "enforce-mandatory-tags" {
  enforcement_level = "hard-mandatory"
}

policy "restrict-instance-type" {
  enforcement_level = "soft-mandatory"
}
```

**Use Cases:**
- Tag enforcement
- Cost controls
- Security standards
- Compliance requirements
- Resource restrictions

---

## 14. Real-World Scenarios

### Q49: How would you structure a Terraform project for multiple environments?
**Answer:**

**Option 1: Workspaces (Simple)**
```
project/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```
```bash
terraform workspace new dev
terraform workspace new prod
```

**Option 2: Separate Directories (Recommended)**
```
project/
├── modules/
│   ├── vpc/
│   ├── ec2/
│   └── rds/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── backend.tf
└── global/
    └── iam/
```

**Option 3: Terragrunt**
```
project/
├── terragrunt.hcl
├── modules/
└── environments/
    ├── dev/
    │   ├── terragrunt.hcl
    │   └── vpc/terragrunt.hcl
    └── prod/
        ├── terragrunt.hcl
        └── vpc/terragrunt.hcl
```

**Best Practices:**
- Separate state per environment
- Environment-specific tfvars
- Shared modules
- Consistent naming
- Clear documentation

### Q50: Describe a blue-green deployment strategy using Terraform.
**Answer:**

**Concept:**
Run two identical environments (blue = current, green = new), switch traffic when ready.

**Implementation:**
```hcl
# variables.tf
variable "active_environment" {
  type    = string
  default = "blue"
  
  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "Active environment must be blue or green."
  }
}

# main.tf
locals {
  blue_count  = var.active_environment == "blue" ? 1 : 0
  green_count = var.active_environment == "green" ? 1 : 0
}

# Blue environment
module "blue_environment" {
  count  = local.blue_count
  source = "./modules/app"
  
  environment = "blue"
  ami_id      = var.blue_ami_id
  # ...
}

# Green environment
module "green_environment" {
  count  = local.green_count
  source = "./modules/app"
  
  environment = "green"
  ami_id      = var.green_ami_id
  # ...
}

# Load balancer targets active environment
resource "aws_lb_target_group_attachment" "app" {
  count = var.active_environment == "blue" ? length(module.blue_environment[0].instance_ids) : length(module.green_environment[0].instance_ids)
  
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = var.active_environment == "blue" ? module.blue_environment[0].instance_ids[count.index] : module.green_environment[0].instance_ids[count.index]
}
```

**Deployment Process:**
1. Deploy green environment (active = blue)
2. Test green environment
3. Switch traffic (active = green)
4. Monitor
5. Destroy blue environment or keep for rollback

**Rollback:**
```bash
terraform apply -var="active_environment=blue"
```

### Q51: How do you implement zero-downtime deployments with Terraform?
**Answer:**

**1. create_before_destroy:**
```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  
  lifecycle {
    create_before_destroy = true
  }
}
```

**2. Rolling Updates with ASG:**
```hcl
resource "aws_autoscaling_group" "web" {
  launch_configuration = aws_launch_configuration.web.id
  min_size             = 3
  max_size             = 6
  desired_capacity     = 3
  
  # Wait for instances to be healthy
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  # Update policy
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}
```

**3. ECS Blue/Green:**
```hcl
resource "aws_ecs_service" "app" {
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  
  deployment_configuration {
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }
}
```

**4. Canary Deployments:**
```hcl
resource "aws_lb_listener_rule" "canary" {
  listener_arn = aws_lb_listener.main.arn
  
  action {
    type             = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.current.arn
        weight = 90
      }
      target_group {
        arn    = aws_lb_target_group.canary.arn
        weight = 10
      }
    }
  }
}
```

### Q52: Design a disaster recovery strategy using Terraform.
**Answer:**

**Multi-Region Architecture:**
```hcl
# Primary Region
module "primary" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.us-east-1
  }
  
  region      = "us-east-1"
  environment = "prod"
}

# DR Region
module "disaster_recovery" {
  source = "./modules/infrastructure"
  
  providers = {
    aws = aws.us-west-2
  }
  
  region      = "us-west-2"
  environment = "prod-dr"
}

# Database Replication
resource "aws_db_instance" "primary" {
  provider = aws.us-east-1
  
  identifier     = "primary-db"
  backup_retention_period = 7
  
  # Enable automated backups
  apply_immediately = true
}

resource "aws_db_instance" "replica" {
  provider = aws.us-west-2
  
  replicate_source_db = aws_db_instance.primary.arn
  identifier          = "replica-db"
}

# Route 53 Failover
resource "aws_route53_health_check" "primary" {
  fqdn              = module.primary.lb_dns
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_record" "failover_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  alias {
    name                   = module.primary.lb_dns
    zone_id                = module.primary.lb_zone_id
    evaluate_target_health = true
  }
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  health_check_id = aws_route53_health_check.primary.id
  set_identifier  = "primary"
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  alias {
    name                   = module.disaster_recovery.lb_dns
    zone_id                = module.disaster_recovery.lb_zone_id
    evaluate_target_health = true
  }
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "secondary"
}
```

**Backup Strategy:**
```hcl
resource "aws_backup_plan" "main" {
  name = "terraform-backup-plan"
  
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"
    
    lifecycle {
      delete_after = 30
    }
    
    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn
      
      lifecycle {
        delete_after = 90
      }
    }
  }
}
```

---

## Bonus: Advanced Scenarios

### Q53: How do you handle circular dependencies in Terraform?
**Answer:**

**Problem:**
```hcl
# security_group.tf
resource "aws_security_group" "web" {
  ingress {
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_security_group" "app" {
  ingress {
    security_groups = [aws_security_group.web.id]
  }
}
# Error: Cycle in dependency graph
```

**Solution 1: Separate Rules:**
```hcl
resource "aws_security_group" "web" {
  name = "web"
}

resource "aws_security_group" "app" {
  name = "app"
}

resource "aws_security_group_rule" "web_to_app" {
  security_group_id        = aws_security_group.web.id
  source_security_group_id = aws_security_group.app.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "app_to_web" {
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.web.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}
```

**Solution 2: Reference by Name:**
```hcl
resource "aws_security_group" "web" {
  name = "web-sg"
  
  ingress {
    security_groups = [aws_security_group.app.name]
  }
}
```

### Q54: Explain how to use Terraform with GitOps workflows.
**Answer:**

**GitOps Principles:**
1. Git as single source of truth
2. Declarative infrastructure
3. Automated deployments
4. Continuous reconciliation

**Implementation:**

**Directory Structure:**
```
terraform-repo/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       └── terraform-destroy.yml
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── modules/
```

**GitHub Actions Workflow:**
```yaml
# .github/workflows/terraform-plan.yml
name: Terraform Plan

on:
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./environments/prod
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: Terraform Format
        run: terraform fmt -check -recursive
      
      - name: Terraform Validate
        run: terraform validate
        working-directory: ./environments/prod
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: ./environments/prod
      
      - name: Comment PR
        uses: actions/github-script@v6
        with:
          script: |
            const output = `#### Terraform Plan 📖
            \`\`\`
            ${process.env.PLAN}
            \`\`\`
            
            *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.name,
              body: output
            })
```

```yaml
# .github/workflows/terraform-apply.yml
name: Terraform Apply

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./environments/prod
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./environments/prod
```

### Q55: How do you test Terraform code?
**Answer:**

**1. Unit Testing (Terratest - Go):**
```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCCreation(t *testing.T) {
    t.Parallel()
    
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/vpc",
        Vars: map[string]interface{}{
            "cidr_block": "10.0.0.0/16",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    
    terraform.InitAndApply(t, terraformOptions)
    
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

**2. Validation Testing:**
```bash
#!/bin/bash
# validate.sh

terraform fmt -check -recursive || exit 1
terraform validate || exit 1
tflint || exit 1
tfsec . || exit 1
```

**3. Integration Testing:**
```python
# tests/test_infrastructure.py
import pytest
import subprocess

def test_terraform_plan():
    result = subprocess.run(
        ["terraform", "plan", "-detailed-exitcode"],
        cwd="./environments/test",
        capture_output=True
    )
    assert result.returncode in [0, 2]

def test_terraform_validate():
    result = subprocess.run(
        ["terraform", "validate"],
        cwd="./environments/test",
        capture_output=True
    )
    assert result.returncode == 0
```

**4. Kitchen-Terraform:**
```yaml
# .kitchen.yml
---
driver:
  name: terraform

provisioner:
  name: terraform

platforms:
  - name: aws

suites:
  - name: default
    driver:
      root_module_directory: test/fixtures/default
    verifier:
      name: terraform
      systems:
        - name: basic
          backend: ssh
```

**5. Policy Testing (Sentinel/OPA):**
```python
# test_policies.py
import unittest
import subprocess

class TestSentinelPolicies(unittest.TestCase):
    def test_tag_enforcement(self):
        result = subprocess.run(
            ["sentinel", "test", "policies/enforce-tags.sentinel"],
            capture_output=True
        )
        self.assertEqual(result.returncode, 0)
```

---

This comprehensive interview guide covers 55 high-quality Terraform questions ranging from fundamental concepts to advanced real-world scenarios, providing you with thorough preparation for Terraform-focused technical interviews.
