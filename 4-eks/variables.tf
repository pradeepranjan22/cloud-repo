variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the cluster is deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for worker nodes"
}

variable "public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Optional public subnets for load balancers"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.27"
  description = "Kubernetes version"
}

variable "enable_irsa" {
  type        = bool
  default     = true
  description = "Enable IAM Roles for Service Accounts (IRSA)"
}

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
  default     = {}
  description = "Managed Node Groups definition"
}

variable "enable_cluster_autoscaler" {
  type        = bool
  default     = false
  description = "Deploy Cluster Autoscaler"
}

variable "enable_aws_lb_controller" {
  type        = bool
  default     = false
  description = "Deploy AWS Load Balancer Controller"
}

variable "node_ssh_key_name" {
  type        = string
  default     = null
  description = "Optional EC2 KeyPair for SSH access to nodes"
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}