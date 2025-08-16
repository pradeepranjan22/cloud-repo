# 2-networking

This module provisions the **network foundation** for the AWS Landing Zone using a **Hub-and-Spoke** architecture built around **AWS Transit Gateway (TGW)**.

It can create:
- A **Hub (Shared Services) VPC**
- One or more **Spoke VPCs** (e.g., Dev, Test, Prod, Security)
- **Subnets** (public/private), **Route Tables**, **NAT Gateways**
- A central **Transit Gateway** with **VPC attachments** and routing

> Designed to work after `0-bootstrap` (backend/IAM) and `1-control-tower` (OU layout).
>
> You can start small (1 Hub + a couple of Spokes) and expand over time.

---

## How It Fits in the Landing Zone

- **0-bootstrap** → Terraform backend + IAM role
- **1-control-tower** → OU hierarchy (targets for accounts)
- **2-networking** *(this module)* → Hub-and-Spoke networking + TGW
- **3-security** → GuardDuty, Security Hub, central logging across VPCs
- **4-eks** → EKS clusters in Spoke VPCs using IRSA
- **5-aft** → Accounts provisioned into the right OUs/VPCs

---

## Reference Architecture (Conceptual)
     +---------------------+        +------------------+
     |  Shared Services    |        |   Security       |
     |  Hub VPC (10.0/16)  |        |  Spoke VPC       |
     |  Subnets + NAT      |        |  (10.4/16)       |
     +----------+----------+        +---------+--------+
                \                         /
                 \                       /
                  \                     /
                    +-----------------+
                    |   Transit GW    |
                    +-----------------+
                  /                     \
                 /                       \
     +----------+----------+        +-----+------------+
     |     Dev Spoke VPC   |        |    Prod Spoke    |
     |      (10.1/16)      |        |     (10.3/16)    |
     +---------------------+        +------------------+
     - **TGW** provides a scalable & centralized routing domain for all VPCs.
- **Hub VPC** holds shared services (bastions, AD, CI/CD runners, etc).
- **Spoke VPCs** hold application workloads per environment.

---

## Prerequisites

1. Terraform backend initialized from `0-bootstrap` (S3+DynamoDB).
2. OU hierarchy created by `1-control-tower` (optional but recommended).
3. Permissions to create: TGW, VPC, Subnets, Routes, NAT GW, RAM shares (if cross-account).
4. Terraform **v1.5+**, AWS provider **v5+**.
5. Non-overlapping **CIDR blocks** for Hub and all Spokes.

---

## Files

| File           | Purpose |
|----------------|---------|
| `versions.tf`  | Terraform & provider constraints |
| `provider.tf`  | AWS provider configuration |
| `variables.tf` | Input variables (TGW/VPCs/subnets/NAT/etc.) |
| `main.tf`      | TGW, VPCs, subnets, routes, attachments |
| `outputs.tf`   | IDs and maps for TGW, VPCs, subnets, routes |
| `README.md`    | This documentation |

---

## Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | n/a | AWS region for networking resources |
| `hub_vpc_cidr` | `string` | n/a | CIDR for the Hub (Shared Services) VPC, e.g. `10.0.0.0/16` |
| `spoke_vpc_cidrs` | `map(string)` | `{}` | Map of **name ⇒ CIDR** for Spoke VPCs, e.g. `{ Dev="10.1.0.0/16", Prod="10.3.0.0/16" }` |
| `az_count` | `number` | `2` | Number of AZs to span per VPC (2 or 3 typical) |
| `enable_nat` | `bool` | `true` | Create NAT Gateways per AZ in Hub VPC (cost trade-off) |
| `attach_spokes_to_tgw` | `bool` | `true` | Whether to attach each Spoke VPC to TGW |
| `tgw_asn` | `number` | `64512` | TGW Amazon-side ASN (BGP) for future hybrid use |
| `enable_vpc_flow_logs` | `bool` | `true` | Enable VPC Flow Logs to CloudWatch for all VPCs |
| `default_tags` | `map(string)` | `{}` | Tags applied to all resources |

**Example `terraform.tfvars`:**
```hcl
region       = "ap-south-1"
hub_vpc_cidr = "10.0.0.0/16"

spoke_vpc_cidrs = {
  Dev      = "10.1.0.0/16"
  Test     = "10.2.0.0/16"
  Prod     = "10.3.0.0/16"
  Security = "10.4.0.0/16"
}

az_count                  = 2
enable_nat                = true
attach_spokes_to_tgw      = true
tgw_asn                   = 64512
enable_vpc_flow_logs      = true
default_tags = {
  Project = "LandingZone"
  Owner   = "CloudTeam"
}
## AWS Resources Created

This module uses the following Terraform AWS resources:

- [`aws_ec2_transit_gateway`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) – Creates the central Transit Gateway.
- [`aws_ec2_transit_gateway_vpc_attachment`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) – Attaches VPCs to TGW.
- [`aws_vpc`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) – Creates Hub and Spoke VPCs.
- [`aws_subnet`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) – Creates public/private subnets across AZs.
- [`aws_internet_gateway`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) – Internet egress for public subnets.
- [`aws_eip`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) – Elastic IPs for NAT gateways.
- [`aws_nat_gateway`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) – Private subnet egress to internet.
- [`aws_route_table`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) & [`aws_route`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) – Routing for VPCs and TGW.
- [`aws_vpc_flow_log`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_flow_log) – VPC Flow Logs to CloudWatch Logs.

Optional in extended topologies:
- [`aws_ram_resource_share`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) – If sharing TGW across accounts.


## Usage

From the repo root:
```bash
cd landing-zone/2-networking

1. Initialize Terraform
terraform init
2. Plan the Deployment
terraform plan \
  -var="region=<AWS_REGION>" \
  -var="hub_vpc_cidr=<HUB_CIDR>" \
  -var='spoke_vpc_cidrs={Dev="<CIDR>",Prod="<CIDR>"}' \
  -var="enable_nat=true"
examle:
terraform plan \
  -var="region=ap-south-1" \
  -var="hub_vpc_cidr=10.0.0.0/16" \
  -var='spoke_vpc_cidrs={Dev="10.1.0.0/16",Prod="10.2.0.0/16"}' \
  -var="enable_nat=true"

This will show the creation of:
	•	A Transit Gateway
	•	Hub VPC
	•	Spoke VPCs
	•	Subnets, NAT Gateways, Route Tables
	•	Attachments to TGW

3. Apply the Deployment
terraform apply \
  -var="region=<AWS_REGION>" \
  -var="hub_vpc_cidr=<HUB_CIDR>" \
  -var='spoke_vpc_cidrs={Dev="<CIDR>",Prod="<CIDR>"}' \
  -var="enable_nat=true"
example:
terraform apply \
  -var="region=ap-south-1" \
  -var="hub_vpc_cidr=10.0.0.0/16" \
  -var='spoke_vpc_cidrs={Dev="10.1.0.0/16",Prod="10.2.0.0/16"}' \
  -var="enable_nat=true"