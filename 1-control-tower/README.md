# 1-control-tower

This module is part of the **Landing Zone Infrastructure Repository**.  
It is responsible for creating **AWS Organizations Organizational Units (OUs)** that will be later managed by **AWS Control Tower** and integrated into other landing zone modules such as **Networking**, **Security**, and **Account Factory for Terraform (AFT)**.

> **Important:**  
> As of now, AWS Control Tower does not have a fully supported Terraform resource for *initial enablement*.  
> This module focuses on **OU creation** in the AWS Management Account.  
> Later stages (SCPs, guardrails, account vending) will target these OUs.

---

## How It Fits in the Landing Zone
- **0-bootstrap** → Sets up Terraform backend (S3/DynamoDB) and IAM role.
- **1-control-tower** *(this module)* → Creates the **OU hierarchy** in AWS Organizations.
- **2-networking** → Creates VPCs, TGWs, and shared services in OUs.
- **3-security** → Enables GuardDuty, Security Hub, and centralized logging in OUs.
- **4-eks** → Creates EKS clusters in specified OUs/accounts.
- **5-aft** → Automates account provisioning in the defined OUs.

---

## Prerequisites
Before using this module, ensure:
1. You are authenticated into the **AWS Management (payer) account**.
2. **AWS Organizations** is enabled.
3. Your AWS CLI profile or IAM role has:
   - `organizations:*` permissions (for OU creation).
   - `iam:Tag*` permissions (if tagging OUs).
4. **Terraform** v1.5 or newer.
5. **AWS provider** v5.x or newer.
6. The `management_account_region` is a region supported by AWS Control Tower (e.g., `us-east-1`, `ap-south-1`).

---

## Files
| File              | Purpose |
|-------------------|---------|
| `versions.tf`     | Defines Terraform and AWS provider version constraints. |
| `provider.tf`     | Configures AWS provider for the management account. |
| `variables.tf`    | Defines input variables (region, OU list, default tags). |
| `main.tf`         | Contains the logic to create Organizational Units. |
| `outputs.tf`      | Exposes OU IDs and Root ID for other modules. |
| `README.md`       | Documentation for this module. |

---

## Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `management_account_region` | `string` | none | AWS region where Control Tower will run. Must be a Control Tower-supported region. |
| `ou_list` | `list(string)` | `["Sandbox","Dev","Test","Prod","Security","SharedServices"]` | List of OUs to create at the root level. |
| `default_tags` | `map(string)` | `{}` | Optional tags applied to all OUs. |

Example:
```hcl
management_account_region = "ap-south-1"
ou_list = ["Sandbox", "Dev", "Test", "Prod", "Security", "SharedServices"]
default_tags = {
  Project = "LandingZone"
  Owner   = "CloudTeam"
}
```

---

## Reference AWS Resources

This module uses the following Terraform resources:

- [`aws_organizations_organizational_unit`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit): Creates Organizational Units (OUs) within AWS Organizations to help organize accounts. In this module, it is used to create the specified OUs under the root of the AWS Organization to structure accounts according to the landing zone design.

- [`aws_organizations_organization`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization): Data source used to fetch information about the AWS Organization, including the Root ID. This module uses it to retrieve the root ID so that OUs can be created directly under the root.

---

## Usage

1. Change directory to this module:
```bash
cd 1-control-tower
```

2. Initialize Terraform (this downloads the necessary providers and modules):
```bash
terraform init
```

3. Plan the changes (this previews the changes Terraform will make before applying them):
```bash
terraform plan \
  -var="management_account_region=<your-region>" \
  -var='ou_list=["Sandbox","Dev","Test","Prod","Security","SharedServices"]'
```

Example with `ap-south-1` and default OU list:
```bash
terraform plan \
  -var="management_account_region=ap-south-1" \
  -var='ou_list=["Sandbox","Dev","Test","Prod","Security","SharedServices"]'
```

4. Apply the changes (this creates the OUs in your AWS Organization):
```bash
terraform apply \
  -var="management_account_region=<your-region>" \
  -var='ou_list=["Sandbox","Dev","Test","Prod","Security","SharedServices"]'
```

Example with `ap-south-1` and default OU list:
```bash
terraform apply \
  -var="management_account_region=ap-south-1" \
  -var='ou_list=["Sandbox","Dev","Test","Prod","Security","SharedServices"]'
```

---

## Outputs

- `ou_ids`: Map of OU names to their corresponding OU IDs. These IDs are used by downstream modules (such as Networking, Security, and Account Factory for Terraform) to target specific OUs for resource deployment and account provisioning.

- `root_id`: The AWS Organizations Root ID. This ID is required when creating OUs or applying policies at the root level, and it serves as the parent for the OUs created in this module.

Example output:
```hcl
ou_ids = {
  "Sandbox"        = "ou-abc1-11111111"
  "Dev"            = "ou-abc1-22222222"
  "Test"           = "ou-abc1-33333333"
  "Prod"           = "ou-abc1-44444444"
  "Security"       = "ou-abc1-55555555"
  "SharedServices" = "ou-abc1-66666666"
}

root_id = "r-abc1"
```