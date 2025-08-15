variable "region" {
  type        = string
  description = "AWS region"
}

variable "backend_bucket" {
  type        = string
  description = "S3 bucket for Terraform state"
}

variable "dynamodb_table" {
  type        = string
  description = "DynamoDB table for state locking"
}

variable "admin_principal_arn" {
  type        = string
  description = "Principal ARN allowed to assume Terraform admin role"
}