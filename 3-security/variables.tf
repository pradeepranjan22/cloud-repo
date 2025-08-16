variable "region" {
  description = "Region to deploy security services"
  type        = string
}

variable "log_archive_account_id" {
  description = "Log Archive account ID"
  type        = string
}

variable "security_tooling_account_id" {
  description = "Security Tooling account ID"
  type        = string
}

variable "cloudtrail_s3_bucket_name" {
  description = "S3 bucket for CloudTrail logs"
  type        = string
}

variable "cloudtrail_kms_key_arn" {
  description = "Optional KMS CMK ARN for CloudTrail encryption"
  type        = string
  default     = null
}

variable "enable_aws_config" {
  description = "Enable AWS Config aggregator"
  type        = bool
  default     = true
}

variable "config_aggregator_account" {
  description = "Account that will host AWS Config aggregator"
  type        = string
  default     = "log-archive"
}

variable "enable_macie" {
  description = "Enable Macie org-wide"
  type        = bool
  default     = false
}

variable "securityhub_standards" {
  description = "List of Security Hub standards ARNs to enable"
  type        = list(string)
  default     = []
}

variable "assume_role_arn_security" {
  description = "Role to assume into Security Tooling account"
  type        = string
  default     = null
}

variable "assume_role_arn_logarchive" {
  description = "Role to assume into Log Archive account"
  type        = string
  default     = null
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}