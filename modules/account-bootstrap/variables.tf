variable "account_id" {
  description = "Target AWS account ID"
  type        = string
}

variable "region" {
  description = "Region for baseline resources"
  type        = string
  default     = "ap-south-1"
}

variable "create_vpc" {
  description = "Whether to create a baseline VPC"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for the baseline VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "public_subnet_suffixes" {
  description = "CIDR offsets for public subnets"
  type        = list(number)
  default     = [0, 1]
}

variable "private_subnet_suffixes" {
  description = "CIDR offsets for private subnets"
  type        = list(number)
  default     = [10, 11]
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch"
  type        = bool
  default     = false
}

variable "create_log_bucket" {
  description = "Whether to create an S3 bucket for logs"
  type        = bool
  default     = false
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for logs (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "create_terraform_admin_role" {
  description = "Whether to create a Terraform admin role"
  type        = bool
  default     = true
}

variable "terraform_admin_role_name" {
  description = "Name for the Terraform admin role"
  type        = string
  default     = "PlatformTerraformAdmin"
}

variable "terraform_admin_trust_account" {
  description = "Principal ARN allowed to assume the Terraform admin role"
  type        = string
  default     = ""
}

variable "default_tags" {
  description = "Default tags to apply to resources"
  type        = map(string)
  default     = {}
}