# 4-eks

This module provisions **production-ready Amazon EKS clusters** (Kubernetes) for the Landing Zone.  
It focuses on secure, repeatable EKS cluster creation with best practices: IAM Roles for Service Accounts (IRSA), node groups (managed or self-managed), cluster logging, kubeconfig provisioning, and optional cluster autoscaling and cluster addons.

This module is intended to be used **after**:
- `0-bootstrap` (backend & IAM)
- `1-control-tower` (OUs / accounts)
- `2-networking` (VPCs / subnets / TGW)
- `3-security` (security guardrails & logging)

---

## Goals & Scope

- Create a highly available EKS control plane (AWS-managed).
- Provision worker node groups (managed node groups by default).
- Enable IRSA with `aws_iam_openid_connect_provider`.
- Enable cluster control-plane logging (audit, api, authenticator, etc.).
- Optionally enable cluster autoscaler, AWS LoadBalancer Controller, and other addons.
- Output kubeconfig and cluster ARNs/IDs for downstream modules (ArgoCD deployment, CI runners).

---

## Architecture (high-level)

- EKS Control Plane (managed) — Multi-AZ.
- Worker nodes as Managed Node Groups (or self-managed; configurable).
- IRSA OIDC provider for secure Kubernetes service account permissions.
- Node groups run in the **private subnets** created by `2-networking`.
- Cluster logging pushed to CloudWatch (configurable).
- Optionally connect with existing IAM roles, VPC, and security policies.

---

## Prerequisites

- `0-bootstrap` backend initialized and available.
- VPC and subnet IDs (private subnets) from `2-networking`.
- IAM permissions to create EKS clusters, roles, instance profiles, and OIDC providers.
- Terraform `>= 1.5`, AWS provider `~> 5.x`.
- `kubectl` and `aws-iam-authenticator` available locally if you plan to run `kubectl` from the machine.
- (Optional) Access to an existing keypair for SSH (if using SSH-enabled node groups).

---

## Files (recommended)

| File           | Purpose |
|----------------|---------|
| `versions.tf`  | Terraform & provider constraints |
| `provider.tf`  | AWS provider config (region/account) |
| `variables.tf` | Module inputs (cluster name, VPC/subnets, node groups) |
| `main.tf`      | EKS cluster, Node Groups, OIDC provider, addons |
| `iam.tf`       | IAM roles & policies for IRSA and node groups |
| `outputs.tf`   | Cluster ID, kubeconfig, ARNs, nodegroup IDs |
| `README.md`    | This documentation |

---

## Variables (suggested)

| Variable | Type | Default | Description |
|---|---:|---|---|
| `cluster_name` | string | n/a | Name of the EKS cluster |
| `region` | string | n/a | AWS region to deploy the cluster |
| `vpc_id` | string | n/a | VPC ID where cluster will be created |
| `private_subnet_ids` | list(string) | n/a | Private subnet IDs for worker nodes & ENIs |
| `public_subnet_ids` | list(string) | [] | Public subnet IDs (for LB if needed) |
| `kubernetes_version` | string | `"1.27"` | Kubernetes control-plane version |
| `enable_irsa` | bool | `true` | Create OIDC provider and enable IRSA |
| `managed_node_groups` | map(object) | `{}` | Map describing managed node groups (instance type, min/max, desired) |
| `enable_cluster_autoscaler` | bool | `false` | Install cluster autoscaler via helm (optional) |
| `enable_aws_lb_controller` | bool | `false` | Install AWS Load Balancer Controller via helm (optional) |
| `node_ssh_key_name` | string | `null` | Optional EC2 KeyPair name for SSH access |
| `default_tags` | map(string) | `{}` | Tags applied to resources |

**Example `variables.tf` shape for `managed_node_groups`:**
```hcl
variable "managed_node_groups" {
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    labels         = map(string)
    tags           = map(string)
  }))
  default = {
    "ng-dev" = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      disk_size      = 50
      labels         = { environment = "dev" }
      tags           = {}
    }
  }
}

Usage:
1. cd landing-zone/4-eks
2. Configure backend (use 0-bootstrap S3/DynamoDB):
terraform {
  backend "s3" {
    bucket         = "my-tf-backend"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "my-tf-locks"
    encrypt        = true
  }
}
3. Initialize:
terraform init
4. Plan
terraform plan \
  -var="cluster_name=shopease-eks" \
  -var="region=ap-south-1" \
  -var='private_subnet_ids=["subnet-0a1","subnet-0b2"]' \
  -var='managed_node_groups={ "ng-prod" = { instance_types=["m6i.large"], desired_size=3, min_size=2, max_size=6, disk_size=100 } }'
  5. terraform apply -auto-approve
  6. Post-apply (optional):
  aws eks update-kubeconfig --region ap-south-1 --name shopease-eks
  7. Destroy(if needed)
  terraform destroy -var="cluster_name=shopease-eks"

  OUTPUT:
Output                                  Description
cluster_id                              EKS cluster ID
cluster_endpoint                        EKS API server endpoint
cluster_certificate_authority           Certificate for kubeconfig
oidc_provider_arn                       ARN of OIDC provider for IRSA
node_group_arns                         Map of node group names to ARNs                                    
node_group_names                        Map of node group names                 cluster_security_group_id               Control-plane SG ID


