# account-bootstrap

This reusable Terraform module bootstraps a **new AWS account** after it is created with AWS Control Tower / AFT.  
It ensures that every new account starts with **baseline infrastructure and roles** for governance, security, and Terraform operations.

---

## Scope & Purpose

When a new AWS account is created, it is essentially empty.  
This module standardizes the bootstrap process by creating:

- **Baseline VPC** (hub/spoke ready) with public & private subnets.  
- **Internet Gateway & Routes** for public subnets.  
- **Optional VPC Flow Logs** to CloudWatch Logs.  
- **Optional S3 bucket for account-level logs**.  
- **Terraform Admin Role** — to allow CI/CD pipelines or admins to manage the account via IaC.  

This is a **pluggable module**: the parent (e.g., `5-aft`) is responsible for creating the AWS account and configuring provider assume-role access. This module is responsible for bootstrapping inside that account.

---

## How It Fits in the Landing Zone

- **0-bootstrap** → Backend & IAM roles in management account.  
- **1-control-tower** → Creates OUs in AWS Organizations.  
- **2-networking** → Transit Gateway and networking hub.  
- **3-security** → Central security services.  
- **4-eks** → EKS cluster(s) for workloads.  
- **5-aft** → Account Factory for Terraform provisions new accounts.  
- **modules/account-bootstrap** *(this module)* → Bootstraps the new accounts (VPC, IAM, logging, etc.).  

---

## AWS Resources Created

This module uses the following Terraform AWS resources:

- **Networking**  
  - `aws_vpc` – Creates baseline VPC.  
  - `aws_subnet` – Creates public & private subnets.  
  - `aws_internet_gateway` – Internet egress for public subnets.  
  - `aws_route_table`, `aws_route`, `aws_route_table_association` – Routing for VPC and subnets.  
  - `aws_flow_log`, `aws_cloudwatch_log_group` – Optional VPC Flow Logs.  

- **Logging**  
  - `aws_s3_bucket` – Optional per-account S3 log bucket.  

- **IAM**  
  - `aws_iam_role` – Terraform admin role inside the account.  
  - `aws_iam_role_policy_attachment` – Attaches AWS managed policies for Terraform operations.  

---

## Files

| File             | Purpose |
|------------------|---------|
| `versions.tf`    | Provider and Terraform version constraints. |
| `variables.tf`   | Module inputs. |
| `main.tf`        | Main resource definitions. |
| `outputs.tf`     | Exposes important values (VPC ID, subnets, IAM role, log bucket). |
| `README.md`      | Documentation (this file). |

---

## Variables

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `account_id` | string | Target AWS account ID | n/a |
| `region` | string | Region for baseline resources | `ap-south-1` |
| `create_vpc` | bool | Create a baseline VPC | `true` |
| `vpc_cidr` | string | VPC CIDR block | `10.100.0.0/16` |
| `public_subnet_suffixes` | list(number) | CIDR offsets for public subnets | `[0, 1]` |
| `private_subnet_suffixes` | list(number) | CIDR offsets for private subnets | `[10, 11]` |
| `enable_flow_logs` | bool | Enable VPC Flow Logs to CloudWatch | `false` |
| `create_log_bucket` | bool | Create an S3 bucket for logs | `false` |
| `log_bucket_name` | string | Name of S3 log bucket (if not generated) | `""` |
| `create_terraform_admin_role` | bool | Create a Terraform admin role | `true` |
| `terraform_admin_role_name` | string | Name for the Terraform admin role | `PlatformTerraformAdmin` |
| `terraform_admin_trust_account` | string | Principal (ARN) allowed to assume Terraform admin role | `""` |
| `default_tags` | map(string) | Default tags | `{}` |

---

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the baseline VPC (if created) |
| `public_subnet_ids` | IDs of public subnets |
| `private_subnet_ids` | IDs of private subnets |
| `log_bucket_name` | Name of S3 log bucket (if created) |
| `terraform_admin_role_arn` | ARN of the Terraform admin role |

---

## Usage

### 1. Backend Configuration

All accounts use the central backend from **0-bootstrap**:  

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-backend"
    key            = "account-bootstrap/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "my-tf-locks"
    encrypt        = true
  }
}

2. Example Invocation from Parent (AFT / Control Tower)

# Assume into the new account (after AFT creates it)
provider "aws" {
  alias  = "newacct"
  region = "ap-south-1"
  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.new.id}:role/PlatformBootstrapRole"
  }
}

module "bootstrap_newacct" {
  source = "../modules/account-bootstrap"
  providers = { aws = aws.newacct }

  account_id                    = aws_organizations_account.new.id
  region                        = "ap-south-1"
  create_vpc                    = true
  vpc_cidr                      = "10.50.0.0/16"
  create_log_bucket             = true
  terraform_admin_trust_account = "arn:aws:iam::123456789012:role/PlatformDeployer"
  default_tags = {
    Project = "LandingZone"
    Owner   = "PlatformTeam"
  }
}

3. Apply Flow

cd landing-zone/modules/account-bootstrap

terraform init
terraform plan \
  -var="account_id=123456789012" \
  -var="region=ap-south-1" \
  -var="terraform_admin_trust_account=arn:aws:iam::111122223333:role/PlatformDeployer"

terraform apply

4. Destroy (Optional)

terraform destroy \
  -var="account_id=123456789012" \
  -var="region=ap-south-1" \
  -var="terraform_admin_trust_account=arn:aws:iam::111122223333:role/PlatformDeployer"

  Integration Notes
	1.	Execution Context
The parent module must configure a provider with assume_role into the new account before calling this module.
	2.	IAM Trust
Set terraform_admin_trust_account to the ARN of the CI/CD pipeline role or management account role that needs to assume Terraform admin in the new account.
	3.	Centralized Logging
If your org uses a central Log Archive account, set create_log_bucket = false and configure CloudTrail/Config to deliver there.
	4.	Flow Logs
Use enable_flow_logs = true only if you want logs per-account in CloudWatch. For enterprise-scale, centralize in a Log Archive bucket.

⸻

References
	•	Terraform AWS Provider
	•	AWS Organizations
	•	Control Tower Account Factory
	•	Terraform Backend Best Practices
