# 3-security

This module enables and centralizes **organization-wide security & compliance** for your AWS Landing Zone.  
It configures:

- **AWS CloudTrail (Organization Trail)** → writes to the **Log Archive** account S3 bucket  
- **AWS GuardDuty (Organization-wide)** → delegated admin in **Security Tooling** account, auto-enrolls all accounts  
- **AWS Security Hub (Organization-wide)** → delegated admin in **Security Tooling** account, auto-enrolls accounts & enables standards  
- **AWS Config (optional)** → aggregator in Log Archive or Security Tooling account  
- (Optional) **Macie, IAM Access Analyzer**

This module must be deployed **after** `0-bootstrap`, `1-control-tower`, and `2-networking`.

---

## How It Fits in the Landing Zone

- **0-bootstrap** → Remote state backend + IAM role  
- **1-control-tower** → OU hierarchy creation  
- **2-networking** → Hub & Spoke networking (TGW, VPCs)  
- **3-security** *(this module)* → Org-wide CloudTrail, GuardDuty, Security Hub, Config  
- **4-eks** → Kubernetes clusters for workloads and DevOps  
- **5-aft** → Account vending with AFT

---

## AWS Resources Used

This module provisions the following Terraform AWS resources:

- **CloudTrail**
  - [`aws_cloudtrail`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) (with `is_organization_trail = true`)
- **GuardDuty**
  - [`aws_guardduty_organization_admin_account`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account)
  - [`aws_guardduty_detector`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector)
  - [`aws_guardduty_organization_configuration`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_configuration)
- **Security Hub**
  - [`aws_securityhub_organization_admin_account`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account)
  - [`aws_securityhub_account`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account)
  - [`aws_securityhub_organization_configuration`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration)
  - [`aws_securityhub_standards_subscription`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription)
- **AWS Config (optional)**
  - [`aws_config_configuration_aggregator`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_aggregator)
  - [`aws_config_organization_managed_rule`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_managed_rule) (optional)
- **Supporting**
  - [`aws_s3_bucket`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) + [`aws_s3_bucket_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) (CloudTrail destination bucket in Log Archive)
  - [`aws_kms_key`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) (optional encryption)

---

## Prerequisites

1. Control Tower OUs and baseline accounts exist.  
2. **Log Archive** and **Security Tooling** accounts created.  
3. Log Archive account has or will have an S3 bucket for CloudTrail logs.  
4. Terraform `>= 1.5`, AWS provider `>= 5.x`.  
5. AWS CLI v2 installed.  
6. Permissions to assume roles into **Log Archive** and **Security Tooling** accounts.  

---

## Files

| File           | Purpose |
|----------------|---------|
| `versions.tf`  | Terraform & provider constraints |
| `provider.tf`  | AWS providers (management + delegated accounts) |
| `variables.tf` | Input variables |
| `main.tf`      | CloudTrail, GuardDuty, Security Hub, Config resources |
| `outputs.tf`   | Output values (ARNs, IDs, etc.) |
| `README.md`    | Documentation for this module |

---

## Variables

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `region` | string | ✔ | Region to deploy security services |
| `log_archive_account_id` | string | ✔ | Log Archive account ID |
| `security_tooling_account_id` | string | ✔ | Security Tooling account ID |
| `cloudtrail_s3_bucket_name` | string | ✔ | S3 bucket for CloudTrail logs |
| `cloudtrail_kms_key_arn` | string | ✖ | Optional KMS CMK for encryption |
| `enable_aws_config` | bool | ✖ (default `true`) | Enable AWS Config aggregator |
| `config_aggregator_account` | string | ✖ | Account for Config aggregator |
| `enable_macie` | bool | ✖ (default `false`) | Enable Macie org-wide |
| `securityhub_standards` | list(string) | ✖ | List of Security Hub standards ARNs |
| `assume_role_arn_security` | string | ✖ | Role to assume into Security Tooling |
| `assume_role_arn_logarchive` | string | ✖ | Role to assume into Log Archive |
| `default_tags` | map(string) | ✖ | Tags for resources |

---

## Usage

1. Change directory to module:
```bash
cd landing-zone/3-security
2.	Configure backend using 0-bootstrap resources:
terraform {
  backend "s3" {
    bucket         = "my-tf-backend"
    key            = "security/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "my-tf-locks"
    encrypt        = true
  }
}
Example terraform.tfvars
region                     = "ap-south-1"
log_archive_account_id     = "111111111111"
security_tooling_account_id= "222222222222"
cloudtrail_s3_bucket_name  = "org-cloudtrail-logs-myco"

enable_aws_config          = true
config_aggregator_account  = "log-archive"

securityhub_standards = [
  "arn:aws:securityhub:ap-south-1::standards/aws-foundational-security-best-practices/v/1.0.0",
  "arn:aws:securityhub:ap-south-1::standards/cis-aws-foundations-benchmark/v/1.2.0"
]

Outputs:

Output                              Description
cloudtrail_arn                  ARN of the org-wide CloudTrail
cloudtrail_bucket_name          S3 bucket name for CloudTrail logs
guardduty_admin_account_id      Delegated GuardDuty admin account ID
guardduty_detector_id           GuardDuty detector ID
securityhub_admin_account_id    Delegated Security Hub admin accountID
securityhub_standards_enabled   List of enabled Security Hub standards
config_aggregator_name          AWS Config aggregator name
