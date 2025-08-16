# 5-aft — Account Factory for Terraform (AFT)

This module automates **account vending** using the AWS Control Tower Account Factory model adapted for Terraform (AFT).  
It provides a repeatable, auditable, and governed way to provision new AWS accounts (workload, CI, logging, sandbox, etc.) and apply baseline resources and guardrails automatically.

> Note: AWS Account Factory (Control Tower) can be integrated with Terraform using Account Factory for Terraform (AFT) patterns. This module provides the Terraform glue, definitions, and examples to manage account definitions, lifecycle, and baseline bootstrap in a landing zone.

---

## Goals & Scope

- Automate the creation and lifecycle management of AWS accounts using a Git-driven source-of-truth.
- Enforce standardized baselines (VPC, IAM roles, guardrails, logging buckets, tags).
- Integrate with AWS Control Tower Account Factory or an AFT implementation that leverages CloudFormation/Service Catalog where required.
- Provide a mechanism to approve, provision, and manage accounts via Git changes and CI pipelines.
- Output account IDs, organizational placement (OU), and bootstrap artifacts for downstream modules (networking, eks, security).

---

## How It Fits in the Landing Zone

- **0-bootstrap** → backend, admin roles (used by pipelines that create accounts)
- **1-control-tower** → OUs where new accounts are created/placed
- **2-networking** → network resources provisioned into new accounts
- **3-security** → security baselines applied to new accounts
- **4-eks** → optionally deploy platform clusters into newly created accounts
- **5-aft** *(this module)* → defines account templates, provisions accounts, applies baseline via Terraform or AFT pipelines

---

## Key Concepts

- **Account Definition**: A YAML/HCL/JSON file in Git that describes the account (email, OU, tags, baseline choices).
- **Approval Flow**: PR-based approval — a merge triggers CI to provision the account.
- **Bootstrap**: After account creation, baseline resources (S3 logging bucket, IAM roles, VPC, SCPs) are applied via Terraform or via Account Factory.
- **Lifecycle**: Supports create, update (account metadata/config), and decommission (with manual safeguards).

---

## Prerequisites

1. AWS Control Tower enabled and OUs defined in `1-control-tower`.  
2. `0-bootstrap` completed (Terraform backend set up).  
3. CI runner (GitHub Actions/GitLab CI) able to assume a deployer role to call Organizational APIs and Control Tower/AFT APIs.  
4. Service Catalog / CloudFormation permissions if using Control Tower's Account Factory.  
5. An agreed naming and tagging strategy for accounts and emails.

---

## Files & Conventions

| File / Dir | Purpose |
|------------|---------|
| `accounts/` | Store account definition files (HCL/JSON/YAML) — each file defines one account. |
| `modules/` | Reusable account bootstrap modules (vpc, iam, baseline, guardrails). |
| `main.tf` | Glue to convert account definitions into AFT requests (or Service Catalog launches). |
| `variables.tf` | Module inputs (OU ids, control tower config, email domain, default tags). |
| `outputs.tf` | Created account IDs, provisioning statuses, bootstrap outputs. |
| `README.md` | This documentation. |

**Account definition example** (`accounts/prod-app-1.hcl` or `.yaml`):
```hcl
account_name = "prod-app-1"
account_email = "prod-app-1+acct@yourdomain.com"
ou = "Prod"
contact = {
  owner = "app-team@example.com"
}
baseline = {
  apply_vpc = true
  enable_cloudtrail = true
}
tags = {
  Project = "CustomerX"
  Environment = "prod"
}

Reference AWS Resources & Patterns
	•	aws_organizations_account / Control Tower Account Factory APIs — to request/create accounts.
	•	aws_servicecatalog_* resources if leveraging Service Catalog-based Account Factory flows.
	•	aws_iam_role & aws_iam_policy — bootstrap roles in new accounts (Terraform admin, cross-account roles).
	•	aws_s3_bucket / aws_s3_bucket_policy — create logging buckets in Log Archive or the new account bootstrap.
	•	aws_cloudformation_stack & aws_cloudformation_stack_set — for blueprint/apply flows across accounts.
	•	null_resource + local-exec — for invoking CLI steps or helper scripts where Terraform provider coverage is not available.
	•	aws_sns / aws_sqs — (optional) notifications for provisioning status.

Implementation note: AFT commonly uses a mixture of Service Catalog / CloudFormation for initial account vending, with Terraform applying post-provision baseline resources into the new account (via cross-account assume-role). Plan the approach that best matches your org: pure Control Tower AFT, or custom Account Factory (CloudFormation + Terraform).

Variables:

| Variable | Type | Default | Description |
|----------|------|---------|--------------------------     
 Man




 Example terraform.tfvars:
 management_account_id = "123456789012"
email_domain = "yourdomain.com"
ou_map = {
  Prod = "ou-abc1-12345678"
  Dev  = "ou-abc1-23456789"
  Sandbox = "ou-abc1-34567890"
}
default_tags = {
  Project = "LandingZone"
  Owner   = "Platform"
}
approval_pipeline_enabled = true
account_definitions_path = "accounts"
bootstrap_module_source = "../modules/account-bootstrap"
